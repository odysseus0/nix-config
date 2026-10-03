{ config, lib, pkgs, ... }:

let
  cfg = config.services.tailscale;
  label = "com.tailscale.tailscaled-set";
  applySettings = pkgs.writeShellApplication {
    name = "tailscaled-set";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      # launchd cannot order this job after tailscaled. Retry its local API
      # while the daemon starts; never enroll or reset unrelated preferences.
      for attempt in {1..30}; do
        if ${lib.getExe cfg.package} set ${lib.escapeShellArgs cfg.extraSetFlags}; then
          exit 0
        fi
        if (( attempt < 30 )); then
          sleep 1
        fi
      done
      echo "tailscaled-set: could not apply preferences after 30 attempts" >&2
      exit 1
    '';
  };
in
{
  # Compatibility with NixOS and nix-darwin PR #1815:
  # https://github.com/nix-darwin/nix-darwin/pull/1815
  # Remove this module/import when the pinned nix-darwin provides this option.
  options.services.tailscale.extraSetFlags = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    example = [ "--ssh=true" ];
    description = "Extra flags to pass to tailscale set on boot and full system activation.";
  };

  config = lib.mkIf (cfg.enable && cfg.extraSetFlags != [ ]) {
    launchd.daemons.tailscaled-set = {
      command = lib.getExe applySettings;
      serviceConfig = {
        Label = label;
        RunAtLoad = true;
        StandardErrorPath = "/var/log/tailscaled-set.log";
      };
    };

    # RunAtLoad alone does not reapply settings on an unchanged switch.
    # After launchd installs the jobs, restart only this short-lived helper.
    # Activation requests local work; it does not wait for network or login.
    system.activationScripts.launchd.text = lib.mkAfter ''
      /bin/launchctl kickstart -k system/${label}
    '';
  };
}
