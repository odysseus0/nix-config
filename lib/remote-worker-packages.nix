# Shared remote-worker tool profile (Linux). Imported by:
#   - homeConfigurations.remote-worker  (users/box/home.nix)
#   - devShells.x86_64-linux.remote-worker
# Do not fork a second list. Host-only extras (Tailscale, Beads coords) stay
# in users/box/home.nix — never pull Mac/Fish/brew/home-ops into this set.
{ pkgs }:
with pkgs; [
  git
  gh
  bun
  nodejs
  dolt
  syncthing
  tmux
  rsync
  rclone
  jq
  ripgrep
]
