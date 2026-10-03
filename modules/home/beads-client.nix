# bd against Sietch's shared board, from any directory. The profile is the
# layout home-ops' enroll-client.ts proved: a BEADS_DIR holding metadata.json
# and config.yaml in server mode. An explicit BEADS_DIR still wins.
{ config, lib, pkgs, facts, ... }:
let
  cfg = config.programs.beads-client;
  profile = "beads/sietch-client/.beads";
  bd = pkgs.writeShellScriptBin "bd" ''
    export BEADS_DIR="''${BEADS_DIR:-${config.xdg.dataHome}/${profile}}"
    exec ${lib.getExe pkgs.beads} "$@"
  '';
in
{
  options.programs.beads-client.server = {
    host = lib.mkOption {
      type = lib.types.str;
      default = facts.sietch.host;
      description = "Host where Sietch's Dolt server answers.";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = facts.sietch.beadsPort;
      description = "Port where Sietch's Dolt server answers.";
    };
  };

  config = {
    home.packages = [ bd ];
    # bd warns unless the profile is private to the user.
    home.activation.beadsProfileMode = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      run chmod 700 ${lib.escapeShellArg "${config.xdg.dataHome}/${profile}"}
    '';
    xdg.dataFile = {
      "${profile}/metadata.json".text = builtins.toJSON {
        database = "dolt";
        backend = "dolt";
        dolt_mode = "server";
        dolt_server_host = cfg.server.host;
        dolt_server_port = cfg.server.port;
        dolt_database = facts.beads.database;
        project_id = facts.beads.projectId;
      };
      "${profile}/config.yaml".text = ''
        no-git-ops: true
        dolt:
          mode: server
          host: ${cfg.server.host}
          port: ${toString cfg.server.port}
          user: root
      '';
    };
  };
}
