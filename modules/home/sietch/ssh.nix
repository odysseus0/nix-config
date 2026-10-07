# Remote shells into Sietch are Apple's sshd (Remote Login), on port 22 over
# the tailnet and the LAN. Apple signs sshd-keygen-wrapper, the program macOS
# charges SSH sessions to, so the Full Disk Access and App Management grant in
# home-ops/infra/fleet never goes stale. Tailscale SSH stays off: its sessions
# run under Nix's unsigned tailscaled, whose identity changes per build.
#
# Also: macOS Tailscale SSH drops remote exit status (always reports 0) through
# at least 1.102.x — same bug as upstream
# https://github.com/tailscale/tailscale/issues/18256 (closed early; still
# reproduces). Fix in flight:
# https://github.com/tailscale/tailscale/pull/20626 (open as of 2026-10-06).
# home-ops briefly wrapped `tailscale ssh` with a stderr exit marker
# (lib/on-sietch.nix at 27e0263); removed with X jobs returning to the MacBook
# (34c1f72). Restore that wrapper only if Tailscale SSH is turned back on
# before #20626 ships. Beads: vault-bmdi.24.
{ ... }:
{
  # The MacBook's key.
  home.file.".ssh/authorized_keys".text = ''
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICxs3TzUNZN53OhwIOYDcs2fc3xdba7lgdlk9ZcZ+gsa tengjizhang@macbook-m4-max
  '';
}
