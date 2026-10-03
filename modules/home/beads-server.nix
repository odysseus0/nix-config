# The shared Beads authority: a loopback-only Dolt sql-server, published to
# the tailnet on 3307 (grants in home-ops/infra/tailscale). home-ops' runtime
# registry health-checks both jobs (beads-dolt-server,
# beads-tailscale-forward).
{ config, lib, pkgs, facts, ... }:
let
  port = toString facts.sietch.beadsPort;
  # Mutable state, outside the store. Backed up by the MacBook's daily
  # beads-export (home-ops runtime registry), not by snapshotting this path.
  dataDir = "${config.home.homeDirectory}/.local/share/beads/shared-server";
in
{
  imports = [ ./tailscale-forward.nix ];

  # dolt on PATH for supervised maintenance (dolt sql, backups).
  home.packages = [ pkgs.dolt ];

  # A user job, so it starts at login: FileVault's pre-boot unlock logs the
  # account in, which is what brings the authority back after a reboot.
  services.background.beads-dolt-server.program = lib.getExe (pkgs.writeShellApplication {
    name = "beads-dolt-server";
    runtimeInputs = [ pkgs.dolt ];
    text = ''
      mkdir -p ${lib.escapeShellArg dataDir}
      exec dolt sql-server --host 127.0.0.1 --port ${port} --data-dir ${lib.escapeShellArg dataDir}
    '';
  });

  services.tailscale-forward.beads = {
    serve = "--tcp=${port}";
    target = "tcp://127.0.0.1:${port}";
  };
}
