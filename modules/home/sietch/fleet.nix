# Fleet, the self-hosted MDM server: it delivers only what Apple reserves for
# MDM (privacy permission grants, managed settings). Nix keeps packages, apps,
# dotfiles, defaults and launchd jobs. Desired state lives as Fleet GitOps YAML
# in home-ops/infra/fleet; this module only runs the server.
#
# Shape matches vault-events.nix: loopback-only services plus a
# tailnet-only Serve forward. Apple devices require HTTPS with a trusted
# certificate, so the forward is HTTPS Serve on the tailnet name (needs HTTPS
# certificates enabled for the tailnet). Dolt holds 127.0.0.1:3307, so MySQL
# takes 3308.
{ config, lib, pkgs, osConfig, ... }:

let
  mysql = pkgs.mysql84;
  stateDir = "${config.home.homeDirectory}/.local/share/fleet";
  mysqlDir = "${stateDir}/mysql";
  mysqlPort = "3308";
  redisPort = "6380";
  fleetPort = "8412";

  mysqld = pkgs.writeShellApplication {
    name = "fleet-mysql";
    runtimeInputs = [ mysql ];
    text = ''
      if [ ! -d ${lib.escapeShellArg mysqlDir}/mysql ]; then
        mkdir -p ${lib.escapeShellArg mysqlDir}
        mysqld --initialize-insecure --datadir=${lib.escapeShellArg mysqlDir}
      fi
      exec mysqld --datadir=${lib.escapeShellArg mysqlDir} \
        --bind-address=127.0.0.1 --port=${mysqlPort} \
        --socket=${lib.escapeShellArg stateDir}/mysql.sock \
        --mysqlx=OFF
    '';
  };

  # No persistence: Fleet keeps only caches and live-query state in Redis.
  redis = pkgs.writeShellApplication {
    name = "fleet-redis";
    runtimeInputs = [ pkgs.redis ];
    text = ''
      exec redis-server --bind 127.0.0.1 --port ${redisPort} --save "" --appendonly no
    '';
  };

  # First start creates the database, its password and the server private key
  # (which encrypts the Apple push certificate in MySQL). Every start applies
  # pending migrations, so a package bump needs no manual step.
  server = pkgs.writeShellApplication {
    name = "fleet-server";
    runtimeInputs = [ pkgs.fleet mysql pkgs.openssl ];
    text = ''
      umask 077
      cd ${lib.escapeShellArg stateDir}
      until mysqladmin --socket=mysql.sock -uroot ping >/dev/null 2>&1; do sleep 2; done
      if [ ! -s mysql-password ]; then
        openssl rand -hex 24 > mysql-password.new
        mysql --socket=mysql.sock -uroot <<SQL
      CREATE DATABASE IF NOT EXISTS fleet;
      CREATE USER IF NOT EXISTS 'fleet'@'127.0.0.1' IDENTIFIED BY '$(cat mysql-password.new)';
      GRANT ALL PRIVILEGES ON fleet.* TO 'fleet'@'127.0.0.1';
      SQL
        mv mysql-password.new mysql-password
      fi
      [ -s private-key ] || openssl rand -base64 32 > private-key

      export FLEET_MYSQL_ADDRESS=127.0.0.1:${mysqlPort}
      export FLEET_MYSQL_DATABASE=fleet
      export FLEET_MYSQL_USERNAME=fleet
      FLEET_MYSQL_PASSWORD="$(cat mysql-password)"
      export FLEET_MYSQL_PASSWORD
      export FLEET_REDIS_ADDRESS=127.0.0.1:${redisPort}
      FLEET_SERVER_PRIVATE_KEY="$(cat private-key)"
      export FLEET_SERVER_PRIVATE_KEY
      export FLEET_SERVER_ADDRESS=127.0.0.1:${fleetPort}
      # TLS terminates at Tailscale Serve.
      export FLEET_SERVER_TLS=false
      export FLEET_LOGGING_JSON=true

      fleet prepare db --no-prompt
      exec fleet serve
    '';
  };

  tailscale = osConfig.services.tailscale.package;

  forward = pkgs.writeShellApplication {
    name = "fleet-tailscale-forward";
    text = ''
      # Foreground Serve: no Serve config persists after this job stops.
      exec ${lib.getExe tailscale} serve --https=443 http://127.0.0.1:${fleetPort}
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
      Umask = 63; # 0077
      ThrottleInterval = 10;
    } // extra;
  };
in
{
  home.packages = [ pkgs.fleetctl ];

  launchd.agents = {
    fleet-mysql = agent "fleet-mysql" (lib.getExe mysqld) { };
    fleet-redis = agent "fleet-redis" (lib.getExe redis) { };
    fleet-server = agent "fleet-server" (lib.getExe server) { };
    fleet-tailscale-forward = agent "fleet-tailscale-forward" (lib.getExe forward) { };
  };
}
