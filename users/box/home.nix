# Linux remote-worker (user box): standalone HM, no NixOS/systemd.
# Tool profile: lib/remote-worker-packages.nix. Below is machine-specific only.
# Auth/login (tailscale up, …) is out of band — no keys in this flake.
{ pkgs, ... }:

{
  home.username = "box";
  home.homeDirectory = "/home/box";
  home.stateVersion = "26.05";
  programs.home-manager.enable = true;
  home.enableNixpkgsReleaseCheck = false;

  # Shared tools + Tailscale (installed, not authenticated). No beads package —
  # ~/.local/bin/bd stays the client binary.
  home.packages =
    (import ../../lib/remote-worker-packages.nix { inherit pkgs; })
    ++ [ pkgs.tailscale ];

  # Beads → Sietch Dolt over Tailscale (not Cloudflare).
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
}
