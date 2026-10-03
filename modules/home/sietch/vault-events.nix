# The vault's event store: a loopback-only libSQL server (sqld), published to
# the tailnet on 8380. The MacBook keeps an embedded replica and runs the
# backup (home-ops runtime registry, vault-events-export).
#
# sqld is in maintenance; its data is a plain SQLite file
# (dbs/default/data), so replacing the server leaves the data where it is.
{ config, lib, pkgs, ... }:
let
  dataDir = "${config.home.homeDirectory}/.local/share/vault/events-server";
in
{
  imports = [ ../tailscale-forward.nix ];

  services.background.vault-events-server.program = lib.getExe (pkgs.writeShellApplication {
    name = "vault-events-server";
    runtimeInputs = [ pkgs.sqld ];
    text = ''
      mkdir -p ${lib.escapeShellArg dataDir}
      exec sqld --db-path ${lib.escapeShellArg dataDir} --http-listen-addr 127.0.0.1:8380
    '';
  });

  services.tailscale-forward.vault-events = {
    serve = "--tcp=8380";
    target = "tcp://127.0.0.1:8380";
  };
}
