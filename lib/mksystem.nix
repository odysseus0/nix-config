# Builds one machine's system configuration — nix-darwin today, NixOS when
# the home server lands — from the machine + user-OS + user-home layers.
{ nixpkgs, overlays, inputs }:

name:
{
  system,
  user,
  darwin ? false,
}:

let
  # The config files for this system.
  machineConfig = ../machines/${name}.nix;
  userOSConfig = ../users/${user}/${if darwin then "darwin" else "nixos" }.nix;
  userHMConfig = ../users/${user}/home-manager.nix;

  # NixOS vs nix-darwin functions
  systemFunc = if darwin then inputs.darwin.lib.darwinSystem else nixpkgs.lib.nixosSystem;
  home-manager = if darwin then inputs.home-manager.darwinModules else inputs.home-manager.nixosModules;
in systemFunc {
  inherit system;

  modules = [
    # Apply our overlays. Overlays are keyed by system type so we have
    # to go through and apply our system type. We do this first so
    # the overlays are available globally.
    { nixpkgs.overlays = overlays; }

    # Allow unfree packages.
    { nixpkgs.config.allowUnfree = true; }

    # Determinate Nix module for darwin (manages /etc/nix/nix.custom.conf)
    (if darwin then inputs.determinate.darwinModules.default else {})

    machineConfig
    userOSConfig
    home-manager.home-manager {
      home-manager.useGlobalPkgs = true;
      # false: home.packages live in the USER profile
      # (~/.local/state/nix/profiles/home-manager), so `make home-switch`
      # delivers package changes without sudo — the Makefile's declared
      # design ("routine changes remotely operable without administrator
      # authentication") was silently broken by `true`, which routes
      # packages into root-owned /etc/profiles/per-user that only a full
      # darwin-rebuild rewrites (found 2026-08-04: a home-switch "succeeded"
      # while the new package never reached PATH). `make switch` remains the
      # boundary for genuinely system-scoped surfaces only.
      home-manager.useUserPackages = false;
      home-manager.backupFileExtension = "backup";
      home-manager.sharedModules = [ inputs.sops-nix.homeManagerModules.sops ];
      home-manager.users.${user} = import userHMConfig {
        inputs = inputs;
      };
    }

    # We expose some extra arguments so that our modules can parameterize
    # better based on these values.
    {
      config._module.args = {
        currentSystem = system;
        currentSystemName = name;
        currentSystemUser = user;
        inputs = inputs;
      };
    }
  ];
}
