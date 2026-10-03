# Loopback services published to the tailnet only, one entry each:
#
#   services.tailscale-forward.beads = { serve = "--tcp=3307"; target = "tcp://127.0.0.1:3307"; };
#
# Each entry is a foreground `tailscale serve` kept alive as a background
# job (<name>-tailscale-forward), so the forward lives exactly as long as
# the job and no Serve config persists in tailscaled after it stops. The
# CLI is the system tailscaled's own package, so the two never skew.
{ config, lib, pkgs, osConfig, ... }:
let
  tailscale = lib.getExe osConfig.services.tailscale.package;
in
{
  imports = [ ./background.nix ];

  options.services.tailscale-forward = lib.mkOption {
    default = { };
    description = "Tailnet-only forwards to loopback services.";
    type = lib.types.attrsOf (lib.types.submodule {
      options = {
        serve = lib.mkOption {
          type = lib.types.str;
          example = "--https=443";
          description = "The tailnet side, as a `tailscale serve` flag.";
        };
        target = lib.mkOption {
          type = lib.types.str;
          example = "http://127.0.0.1:8412";
          description = "The loopback service it forwards to.";
        };
      };
    });
  };

  config.services.background = lib.mapAttrs' (name: f:
    lib.nameValuePair "${name}-tailscale-forward" {
      program = lib.getExe (pkgs.writeShellApplication {
        name = "${name}-tailscale-forward";
        text = "exec ${tailscale} serve ${f.serve} ${f.target}";
      });
    }) config.services.tailscale-forward;
}
