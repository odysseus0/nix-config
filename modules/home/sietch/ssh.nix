# Remote shells into Sietch go through Apple's sshd, published to the tailnet
# on 2222 (Tailscale SSH keeps tailnet port 22). Apple signs
# sshd-keygen-wrapper, the program macOS charges SSH sessions to, so the Full
# Disk Access and App Management grant in home-ops/infra/fleet never goes
# stale; Nix's unsigned tailscaled would change identity per build.
{ ... }:
{
  imports = [ ../tailscale-forward.nix ];

  # The MacBook's key.
  home.file.".ssh/authorized_keys".text = ''
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICxs3TzUNZN53OhwIOYDcs2fc3xdba7lgdlk9ZcZ+gsa tengjizhang@macbook-m4-max
  '';

  services.tailscale-forward.sshd = {
    serve = "--tcp=2222";
    target = "tcp://127.0.0.1:22";
  };
}
