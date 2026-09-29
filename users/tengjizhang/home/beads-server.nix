# The shared Beads authority: a loopback-only Dolt sql-server plus a
# tailnet-only TCP forward to it. Sietch is its only host; the MacBook and
# enrolled clients reach it at <sietch>:3307 over Tailscale (grants in
# home-ops/infra/tailscale). The home-ops runtime registry carries the health
# checks for both labels (beads-dolt-server, beads-tailscale-forward); the
# services themselves are declared here, so they exist only on this host.
{ config, lib, pkgs, osConfig, ... }:

let
  # Beads documents Dolt 2.2.0 as the safe standalone-server release. Pinned
  # to the upstream prebuilt binary: the authority's server version changes
  # only by editing this pin, and nothing compiles.
  dolt = pkgs.stdenvNoCC.mkDerivation {
    pname = "dolt";
    version = "2.2.0";
    src = pkgs.fetchurl {
      url = "https://github.com/dolthub/dolt/releases/download/v2.2.0/dolt-darwin-arm64.tar.gz";
      hash = "sha256-xnN9wsWAbi7u9IOa12woFnyGH4eK8wcd8SQqZYnYEmc=";
    };
    installPhase = ''
      runHook preInstall
      install -Dm755 bin/dolt $out/bin/dolt
      install -Dm644 LICENSES $out/share/licenses/dolt/LICENSES
      runHook postInstall
    '';
  };

  # Mutable state, outside the store. Back it up through the MacBook's daily
  # beads-export (home-ops runtime registry), not by snapshotting this path.
  dataDir = "${config.home.homeDirectory}/.local/share/beads/shared-server";

  doltServer = pkgs.writeShellApplication {
    name = "beads-dolt-server";
    runtimeInputs = [ dolt ];
    text = ''
      mkdir -p ${lib.escapeShellArg dataDir}
      exec dolt sql-server --host 127.0.0.1 --port 3307 --data-dir ${lib.escapeShellArg dataDir}
    '';
  };

  # Same package as the system daemon, so CLI and tailscaled never skew.
  tailscale = osConfig.services.tailscale.package;

  forward = pkgs.writeShellApplication {
    name = "beads-tailscale-forward";
    text = ''
      # Foreground Serve: the forward lives exactly as long as this launchd
      # job, so no Serve config persists in tailscaled after it stops.
      exec ${lib.getExe tailscale} serve --tcp=3307 tcp://127.0.0.1:3307
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
  # dolt on PATH for supervised maintenance (dolt sql, backups) on this host.
  home.packages = [ dolt ];

  # User agents, so they start at login. FileVault's pre-boot unlock logs the
  # account in, which is what brings the authority back after a reboot.
  launchd.agents = {
    beads-dolt-server = agent "beads-dolt-server" (lib.getExe doltServer) { };
    # tailscaled may not be up at login; KeepAlive retries every 10s.
    beads-tailscale-forward = agent "beads-tailscale-forward" (lib.getExe forward) { ThrottleInterval = 10; };
  };
}
