# Migration: ownership-tier restructure

One-time manual steps for the first `make switch` on this branch. Nix now
owns several tools that used to be installed by npm/pnpm/vendor installers;
the old installs don't get removed automatically (Nix only manages what it
put there), so the stale copies need clearing by hand or they'll shadow the
Nix-built ones on PATH.

All commands are fish-safe as written.

## 0. BEFORE `make switch` — while pnpm still exists

The restructure removes `pnpm` from the package set and `~/Library/pnpm`
from PATH, so pnpm-based removals must run first:

```bash
# pi — was pnpm-global @mariozechner/pi-coding-agent
pnpm remove -g @mariozechner/pi-coding-agent

# agent-browser — was pnpm-global
pnpm remove -g agent-browser

# bird — was pnpm-global; now ships via the home-ops input
# (homeManagerModules.bird). Check `pnpm list -g` for the scoped package
# name (its upstream is private and deliberately unnamed here) and remove it.
pnpm list -g
pnpm remove -g <the-bird-package>
```

(If you've already switched: the shims in `~/Library/pnpm` are off PATH and
harmless; drain them with `~/Library/pnpm/pnpm remove -g …` or just
`rm -rf ~/Library/pnpm` once nothing you need remains — see the drift note
at the bottom before deleting.)

Note: `@earendil-works/pi-coding-agent@0.75.4` is also installed globally
via pnpm, separate from the `@mariozechner/pi-coding-agent` the old config
declared — a fork/rename `pi` went through. `llm-agents.nix`'s `pi` still
tracks `@mariozechner`. **Flagged for George**: confirm which upstream you
want before removing the `@earendil-works` copy.

## 1. After `make switch` — remove now-store-owned vendor installs

These moved to `pkgs.llm-agents.<name>`. Remove the old copies so PATH
resolves to the Nix-built binary unambiguously:

```bash
# claude-code — was ~/.local/bin/claude (self-updating symlink farm)
rm -rf ~/.local/share/claude
rm -f ~/.local/bin/claude

# codex — was npm-global @openai/codex
npm uninstall -g @openai/codex
rm -rf ~/.codex/packages   # standalone install dir referenced by the old ~/.local/bin/codex symlink
rm -f ~/.local/bin/codex ~/.local/bin/codex-code-mode-host

# amp — was ~/.amp vendor installer (already absent on this machine as of
# 2026-08-04; skip if `ls ~/.amp` finds nothing)
rm -rf ~/.amp

# beads — was Homebrew formula (mainProgram `bd`)
brew uninstall beads
# dolt was a beads dependency; `brew autoremove` clears it if nothing else
# needs it — brew won't remove it automatically since
# `onActivation.cleanup = "none"`.
```

## 2. qmd

Was bun-installed from git. Find and remove whatever `bun` put on PATH for
it (check `~/.cache/.bun/bin/qmd` or wherever your bun global bin resolved
to) once you've confirmed `pkgs.llm-agents.qmd`'s `qmd` resolves correctly.

## 3. Vite+ (vp) — still vendor-owned, needs a manual (re-)install

The curl-based activation installer that used to run on every `make switch`
is gone (that was exactly the online/soft-fail activation this restructure
removes — see README §The two clocks). If `~/.vite-plus/bin/vp` doesn't
already exist, run the vendor installer once by hand (`env` prefix so the
line works in fish and bash alike):

```bash
curl -fsSL https://vite.plus -o /tmp/vite-plus-install.sh
env VP_HOME="$HOME/.vite-plus" VP_NODE_MANAGER=yes bash /tmp/vite-plus-install.sh
"$HOME/.vite-plus/bin/vp" env setup
rm -f /tmp/vite-plus-install.sh
```

PATH wiring (`${vitePlusHome}/bin`) is still declarative in
`home/environment.nix` — only the installer step became manual.

## 4. Reconcile uv tools once

The uv manifest now has a real reconciler that *uninstalls* anything not
listed (previously it only ever installed). This machine has strays —
`gam7`, `poetry`, `visidata`, and others not in
`users/tengjizhang/home/uv-tools-manifest.nix` — that will be removed the
first time this runs:

```bash
make update-tools
```

Review the manifest first if you want to keep any of those; add them to
`uv-tools-manifest.nix` before running, not after.

## Not migrated — check before relying on them

- **grok** (`~/.grok`): left vendor-owned, untouched. Confirm you still use
  it; if not, it can be dropped from PATH entirely (see the comment in
  `home/packages.nix`).
- **gccli, ghcrawl, opencli, @googleworkspace/cli, @opentabs-dev/cli, ntn**:
  installed pnpm-globally on this machine but were never actually declared
  in the old `pnpmGlobalPackages` list (that list only had `bird`, `neonctl`,
  `pi`) — pre-existing drift, not something this restructure touches. With
  `~/Library/pnpm` off PATH after the switch, they stop resolving; if any is
  still wanted, formalize it (own derivation / npx wrapper / vendor root) as
  a separate follow-up before deleting the directory.
