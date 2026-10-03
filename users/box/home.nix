# Linux remote-worker home (user box). Standalone HM — no NixOS/systemd.
# Packages come from lib/remote-worker-packages.nix; machine-specific bits below.
{ pkgs, ... }:

{
  home.username = "box";
  home.homeDirectory = "/home/box";
  home.stateVersion = "26.05";
  programs.home-manager.enable = true;
  home.enableNixpkgsReleaseCheck = false;

  # Shared toolchain + Tailscale CLI/daemon (ready for a human `tailscale up`).
  # Beads binary stays at ~/.local/bin/bd — not installed here.
  home.packages =
    (import ../../lib/remote-worker-packages.nix { inherit pkgs; })
    ++ [ pkgs.tailscale ];

  # Beads client → Sietch Dolt over Tailscale (not cloudflared / beads.tj-zhang.com).
  home.file.".local/share/beads/sietch-client/.beads/config.yaml".text = ''
    no-git-ops: true
    dolt:
      mode: server
      host: sietch.tail99865c.ts.net
      port: 3307
      user: root
  '';
  home.file.".local/share/beads/sietch-client/.beads/metadata.json".text = builtins.toJSON {
    database = "dolt";
    backend = "dolt";
    dolt_mode = "server";
    dolt_server_host = "sietch.tail99865c.ts.net";
    dolt_server_port = 3307;
    dolt_database = "beads";
    project_id = "3e01e0a5-1e41-43d6-b5e9-babe08cd9736";
  };
  xdg.configFile."beads/README.md".text = ''
    Beads → Sietch over Tailscale (`sietch.tail99865c.ts.net:3307`).
    Login/auth is out of band: start tailscaled, then `sudo tailscale up`. No auth keys in Nix.
  '';
}
