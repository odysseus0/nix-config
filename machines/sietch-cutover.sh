#!/bin/bash
# sietch-cutover.sh — one-time cutover of Sietch to darwinConfigurations.sietch.
#
# Run ON SIETCH, as George (not root), from a fresh checkout of this repo.
# Sietch's old ~/nix-config sits on pre-rewrite history and cannot
# fast-forward, so replace it first:
#
#   mv ~/nix-config ~/.Trash/nix-config-stale
#   git clone https://github.com/odysseus0/nix-config ~/nix-config
#   bash ~/nix-config/machines/sietch-cutover.sh
#
# It asks for the sudo password once and keeps the ticket alive. Run it inside
# a herdr session: if removing AdGuard's network filter drops the SSH
# connection, reattach and rerun. Every step is idempotent (it acts only on
# what is still present), so a rerun resumes where the last run stopped.
#
# Order, chosen to keep Beads downtime to the switch alone:
#   1. build      — realize the system closure first; nothing changes on disk.
#   2. purge      — Homebrew zap, App Store apps, AdGuard Home, launchd jobs,
#                   /Applications, /usr/local/bin, home-directory tool trees.
#                   Beads is untouched here: Dolt and the forward run from
#                   /nix/store, not from anything being purged.
#   3. switch     — the only Beads interruption: Home Manager reloads the two
#                   Beads agents because their store paths change (seconds).
#                   The purge ran first, so the switch's own zap step finds
#                   nothing left to remove and cannot stall on it.
#   4. verify     — Dolt answers on loopback, both agents run, Tailscale is up
#                   with SSH on, Homebrew holds only the declared cask.
#
# Purged items go to ~/.Trash/sietch-cutover-<timestamp>/, never rm.
# Rollback commands print on any failure (and are saved on the first run to
# ~/.local/state/sietch-cutover/rollback.env).

set -euo pipefail

REPO="$(cd -- "$(dirname -- "$0")/.." && pwd)"
TS="$(date +%Y%m%d-%H%M%S)"
STATE="$HOME/.local/state/sietch-cutover"
TRASH="$HOME/.Trash/sietch-cutover-$TS"
LOG="$HOME/Library/Logs/sietch-cutover.log"
BREW=/opt/homebrew/bin/brew
export HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_ANALYTICS=1 HOMEBREW_NO_INSTALL_CLEANUP=1

mkdir -p "$STATE" "$(dirname "$LOG")"
exec > >(tee -a "$LOG") 2>&1
step() { printf '\n=== %s ===\n' "$*"; }

# ----------------------------------------------------------------------------
# Guards
# ----------------------------------------------------------------------------
[ "$(uname -s)" = Darwin ] || { echo "not macOS"; exit 2; }
[ "$(/usr/sbin/scutil --get LocalHostName)" = Sietch ] || { echo "refusing: this is not Sietch"; exit 2; }
[ "$(id -u)" -ne 0 ] || { echo "run as your user, not root (Homebrew refuses root); the script sudoes itself"; exit 2; }

sudo -v
( while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done ) 2>/dev/null &
KEEPALIVE=$!

# ----------------------------------------------------------------------------
# Rollback anchors: recorded once, before anything changes, so reruns after a
# successful switch still point at the pre-cutover generations.
# ----------------------------------------------------------------------------
if [ ! -f "$STATE/rollback.env" ]; then
  {
    echo "PREV_SYSTEM=$(readlink -f /run/current-system)"
    echo "PREV_HM=$(readlink -f "$HOME/.local/state/nix/profiles/home-manager")"
  } > "$STATE/rollback.env"
fi
# shellcheck source=/dev/null
. "$STATE/rollback.env"

rollback_help() {
  cat <<EOF

!!! sietch-cutover failed (log: $LOG). Nothing further was changed.

Purge steps are not reversible by Nix; purged items are in ~/.Trash/sietch-cutover-*.

Beads down or wrong (restores the pre-cutover Beads agents, no sudo):
  $PREV_HM/activate

Full rollback of the system generation (tailscale, launchd daemons, shell):
  sudo darwin-rebuild --rollback
  $PREV_HM/activate
The second line is REQUIRED: the pre-cutover system generation embeds a Home
Manager generation WITHOUT the Beads agents, so the system rollback alone
stops the Beads authority. Its standalone generation above restores them.
(Pre-cutover system: $PREV_SYSTEM)

Check from the MacBook afterwards:  ~/home-ops/runtime/bin/beads-tailnet-health.sh && bd ready
EOF
}
on_exit() {
  local rc=$?
  kill "$KEEPALIVE" 2>/dev/null || true
  [ "$rc" -eq 0 ] || rollback_help
}
trap on_exit EXIT

# Move a path to this run's Trash folder (sudo when the path is not ours).
# ~/.Trash is writable but not listable over SSH (TCC), hence a fresh
# per-run subfolder and path-derived names instead of collision checks.
trash() {
  local src="$1" dest
  [ -e "$src" ] || [ -L "$src" ] || return 0
  mkdir -p "$TRASH"
  dest="$TRASH/$(printf '%s' "$src" | sed 's|^/||; s|/|__|g')"
  if [ -w "$(dirname "$src")" ] && { [ -L "$src" ] || [ -O "$src" ]; }; then
    mv "$src" "$dest"
  else
    sudo mv "$src" "$dest"
  fi
  echo "trashed: $src"
}

# Unload a launchd plist from its domain, then trash it. Allowlisted names stay.
purge_launchd_dir() {
  local dir="$1" domain="$2" keep="$3" f label
  [ -d "$dir" ] || return 0
  for f in "$dir"/*.plist; do
    [ -e "$f" ] || continue
    if printf '%s\n' "$(basename "$f")" | grep -Eq "$keep"; then continue; fi
    label="$(sudo /usr/libexec/PlistBuddy -c 'Print :Label' "$f" 2>/dev/null || basename "$f" .plist)"
    if [ "$domain" = system ]; then
      sudo launchctl bootout "system/$label" 2>/dev/null || true
    else
      launchctl bootout "$domain/$label" 2>/dev/null || true
    fi
    trash "$f"
  done
}

# ----------------------------------------------------------------------------
step "1/4 build"
# ----------------------------------------------------------------------------
cd "$REPO"
SYSTEM="$(nix build --no-link --print-out-paths ".#darwinConfigurations.sietch.system")"
BREWFILE="$(grep -o '/nix/store/[a-z0-9]*-Brewfile' "$SYSTEM/activate" | head -1)"
echo "system:   $SYSTEM"
echo "brewfile: $BREWFILE"; cat "$BREWFILE"

# Baseline: refuse to start a cutover while the authority is already down.
"$PREV_HM/home-path/bin/dolt" sql -h 127.0.0.1 -P 3307 -q 'SELECT 1' >/dev/null \
  || { echo "Beads Dolt is not answering BEFORE the cutover; fix that first"; exit 1; }
echo "Beads answering (baseline)"

# ----------------------------------------------------------------------------
step "2/4 purge (Beads keeps serving throughout)"
# ----------------------------------------------------------------------------

# App Store apps first: `mas` is itself a formula the Homebrew purge removes.
if [ -x /opt/homebrew/bin/mas ]; then
  /opt/homebrew/bin/mas list 2>/dev/null | awk '{print $1}' | while read -r id; do
    [ -n "$id" ] || continue
    sudo /opt/homebrew/bin/mas uninstall "$id" || echo "mas uninstall $id failed; the /Applications sweep below removes it"
  done
fi

# AdGuard Home is a hand-installed root service, not a cask: uninstall its
# service registration before its directory goes. (DNS moves to NextDNS via
# Tailscale; Sietch's resolvers do not point at it.)
if [ -x /Applications/AdGuardHome/AdGuardHome ]; then
  sudo /Applications/AdGuardHome/AdGuardHome -s uninstall || true
fi

# Homebrew: stop every service, make sure the declared cask is present, then
# zap everything undeclared (formulae, casks with their zap stanzas, taps).
# A failure here stops the script BEFORE the switch, so activation never runs
# a half-finished cleanup.
if [ -x "$BREW" ]; then
  "$BREW" services stop --all || true
  "$BREW" bundle install --file="$BREWFILE" --no-upgrade
  "$BREW" bundle cleanup --file="$BREWFILE" --zap --force \
    || "$BREW" bundle cleanup --file="$BREWFILE" --zap --force   # one retry: cask uninstall order
  # Service data and logs left in the prefix (mysql's 4.9 GB is error logs).
  for d in /opt/homebrew/var/*; do
    [ "$(basename "$d")" = homebrew ] || trash "$d"
  done
fi

# launchd jobs. Keep only what Nix, Determinate, Tailscale (nix-darwin) and
# the Beads agents (com.runtime.*) own; Apple's own jobs live in /System.
purge_launchd_dir "$HOME/Library/LaunchAgents" "gui/$(id -u)" '^com\.runtime\.'
purge_launchd_dir /Library/LaunchAgents "gui/$(id -u)" '^com\.apple\.'
purge_launchd_dir /Library/LaunchDaemons system \
  '^(com\.tailscale\.tailscaled(-set)?|org\.nixos\..*|systems\.determinate\..*|com\.apple\..*)\.plist$'

# /Applications: the Codex app (chatgpt cask) and system entries stay.
for a in /Applications/* /Applications/.[!.]*; do
  [ -e "$a" ] || continue
  case "$(basename "$a")" in
    ChatGPT.app|Safari.app|Utilities|"Nix Apps"|.localized|.DS_Store) ;;
    *) trash "$a" ;;
  esac
done
for a in "$HOME/Applications"/*; do
  [ -e "$a" ] || continue
  [ "$(basename "$a")" = "Home Manager Apps" ] || trash "$a"
done

# /usr/local/bin: only Determinate's daemon binary is live; the rest are stale
# shims of removed apps (docker, multipass, ollama, a Tailscale-app wrapper...).
for b in /usr/local/bin/* ; do
  [ -e "$b" ] || [ -L "$b" ] || continue
  [ "$(basename "$b")" = determinate-nixd ] || trash "$b"
done

# Home-directory tool trees outside Nix: uv tools, vendor Claude Code, rustup,
# podman, opencode, doom, zellij, nvim, direnv state. ~/.local/share/beads (the
# authority's data) and fish/zsh history are NOT listed and stay.
for b in "$HOME/.local/bin"/* "$HOME/.local/bin"/.[!.]*; do
  [ -e "$b" ] || [ -L "$b" ] || continue
  trash "$b"
done
for p in .local/share/uv .local/share/claude .local/share/containers .local/share/opencode \
         .local/share/doom .local/share/zellij .local/share/nvim .local/share/direnv \
         .cargo .rustup; do
  trash "$HOME/$p"
done

# ----------------------------------------------------------------------------
step "3/4 switch (Beads agents reload here)"
# ----------------------------------------------------------------------------
t0=$(date +%s)
sudo "$SYSTEM/sw/bin/darwin-rebuild" switch --flake "$REPO#sietch"

# ----------------------------------------------------------------------------
step "4/4 verify"
# ----------------------------------------------------------------------------
HM="$(readlink -f "$HOME/.local/state/nix/profiles/home-manager")"
DOLT="$HM/home-path/bin/dolt"
ok=""
for _ in $(seq 1 60); do
  if "$DOLT" sql -h 127.0.0.1 -P 3307 -q 'SELECT 1' >/dev/null 2>&1; then ok=1; break; fi
  sleep 1
done
[ -n "$ok" ] || { echo "Dolt is not answering on 127.0.0.1:3307"; exit 1; }
echo "Dolt answering $(( $(date +%s) - t0 ))s after the switch began (upper bound on downtime)"

for label in com.runtime.beads-dolt-server com.runtime.beads-tailscale-forward; do
  launchctl print "gui/$(id -u)/$label" | grep -q 'state = running' \
    || { echo "$label is not running"; exit 1; }
  echo "$label running"
done

TS_CLI=/run/current-system/sw/bin/tailscale
"$TS_CLI" status --json | grep -q '"BackendState": *"Running"' || { echo "tailscale not Running"; exit 1; }
sudo "$TS_CLI" debug prefs | grep -q '"RunSSH": *true' || { echo "Tailscale SSH is off"; exit 1; }
echo "tailscale Running, SSH on"

[ -z "$("$BREW" list --formula)" ] || { echo "formulae remain:"; "$BREW" list --formula; exit 1; }
[ "$("$BREW" list --cask)" = chatgpt ] || { echo "casks other than chatgpt remain:"; "$BREW" list --cask; exit 1; }
echo "homebrew: only the declared cask"

# The superseded hand-built checkouts are no longer the source of anything.
trash "$HOME/nix-config-beads-tailnet"
trash "$HOME/nix-config-sietch-beads"

cat <<EOF

Cutover complete. Finish from the MacBook:
  ~/home-ops/runtime/bin/beads-tailnet-health.sh && bd ready
Then open a fresh SSH session (login shell is now fish).
Rollback anchors stay in $STATE/rollback.env.
EOF
