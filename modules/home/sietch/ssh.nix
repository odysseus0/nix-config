# Remote shells into Sietch are Apple's sshd (Remote Login), on port 22 over
# the tailnet and the LAN. Apple signs sshd-keygen-wrapper, the program macOS
# charges SSH sessions to, so the Full Disk Access and App Management grant in
# home-ops/infra/fleet never goes stale. Tailscale SSH stays off: its sessions
# run under Nix's unsigned tailscaled, whose identity changes per build.
{ ... }:
{
  # The MacBook's key.
  home.file.".ssh/authorized_keys".text = ''
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICxs3TzUNZN53OhwIOYDcs2fc3xdba7lgdlk9ZcZ+gsa tengjizhang@macbook-m4-max
  '';
}
