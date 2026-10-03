# Shared remote-worker CLI set. Import from the Linux host home-manager module
# and from any remote-worker devShell — do not fork a second list.
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
