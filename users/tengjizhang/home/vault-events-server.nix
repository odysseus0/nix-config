# The vault's event store: a loopback-only libSQL server (sqld) plus a
# tailnet-only TCP forward to it, the same shape as beads-server.nix. Sietch is
# its only host; the MacBook keeps an embedded replica and reaches it at
# <sietch>:8380 over Tailscale. Backup runs from the MacBook (home-ops runtime
# registry, vault-events-export), not from this host.
#
# sqld has been in maintenance since 2025; its data is a plain SQLite file
# (dbs/default/data), so replacing the server leaves the data where it is.
{ config, lib, pkgs, osConfig, ... }:

let
  sqld = pkgs.sqld;

  # Mutable state, outside the store.
  dataDir = "${config.home.homeDirectory}/.local/share/vault/events-server";

  server = pkgs.writeShellApplication {
    name = "vault-events-server";
    runtimeInputs = [ sqld ];
    text = ''
      mkdir -p ${lib.escapeShellArg dataDir}
      exec sqld --db-path ${lib.escapeShellArg dataDir} --http-listen-addr 127.0.0.1:8380
    '';
  };

  # Same package as the system daemon, so CLI and tailscaled never skew.
  tailscale = osConfig.services.tailscale.package;

  forward = pkgs.writeShellApplication {
    name = "vault-events-tailscale-forward";
    text = ''
      # Foreground Serve: the forward lives exactly as long as this launchd
      # job, so no Serve config persists in tailscaled after it stops.
      exec ${lib.getExe tailscale} serve --tcp=8380 tcp://127.0.0.1:8380
    '';
  };

  agent = label: program: extra: {
    enable = true;
    config = {
      Label = "com.runtime.${label}";
      ProgramArguments = [ program ];
      RunAtLoad = true;
      KeepAlive = true;
      ProcessType = "Background";
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/runtime-${label}.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/runtime-${label}.error.log";
      Umask = 63; # 0077: logs may contain private operational context.
    } // extra;
  };
in
{
  launchd.agents = {
    vault-events-server = agent "vault-events-server" (lib.getExe server) { };
    # tailscaled may not be up at login; KeepAlive retries every 10s.
    vault-events-tailscale-forward = agent "vault-events-tailscale-forward" (lib.getExe forward) { ThrottleInterval = 10; };
  };
}
