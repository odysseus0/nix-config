# Remote shells into Sietch go through Apple's sshd, reached over the tailnet
# on port 2222 (Tailscale SSH keeps tailnet port 22 as the fallback path).
# Apple signs sshd-keygen-wrapper, the program macOS charges SSH sessions to,
# so the Full Disk Access and App Management grant in home-ops/infra/fleet
# never goes stale; Nix's unsigned tailscaled would change identity per build.
{ config, lib, pkgs, osConfig, ... }:

let
  tailscale = osConfig.services.tailscale.package;

  forward = pkgs.writeShellApplication {
    name = "sshd-tailscale-forward";
    text = ''
      # Foreground Serve: no Serve config persists after this job stops.
      exec ${lib.getExe tailscale} serve --tcp=2222 tcp://127.0.0.1:22
    '';
  };
in
{
  # The MacBook's key (George, 2026-10-02).
  home.file.".ssh/authorized_keys".text = ''
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICxs3TzUNZN53OhwIOYDcs2fc3xdba7lgdlk9ZcZ+gsa tengjizhang@macbook-m4-max
  '';

  launchd.agents.sshd-tailscale-forward = {
    enable = true;
    config = {
      Label = "com.runtime.sshd-tailscale-forward";
      ProgramArguments = [ (lib.getExe forward) ];
      RunAtLoad = true;
      KeepAlive = true;
      ThrottleInterval = 10;
      ProcessType = "Background";
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/runtime-sshd-tailscale-forward.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/runtime-sshd-tailscale-forward.error.log";
    };
  };
}
