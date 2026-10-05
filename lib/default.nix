# How hosts are assembled. A host file (hosts/<name>.nix) is identity plus
# import lists; these functions add what every host shares. Inputs and facts
# reach every module as specialArgs, not _module.args, which a module cannot
# use in its own `imports`. The overlay is applied here and nowhere else.
{ inputs }:
let
  facts = import ./facts.nix;
  overlays = [ (import ../pkgs) ];
in
rec {
  inherit overlays;

  linuxSystems = [ "x86_64-linux" "aarch64-linux" ];

  pkgsFor = system: import inputs.nixpkgs { inherit system overlays; };

  # A nix-darwin system with the host's user under home-manager.
  mkDarwin = path:
    let
      host = import path { inherit inputs; };
      specialArgs = { inherit inputs facts; inherit (host) user; };
    in
    inputs.darwin.lib.darwinSystem {
      inherit (host) system;
      inherit specialArgs;
      modules = [
        {
          nixpkgs.overlays = overlays;
          nixpkgs.config.allowUnfree = true;
        }
        inputs.determinate.darwinModules.default
        inputs.home-manager.darwinModules.home-manager
      ] ++ host.darwin ++ [
        {
          home-manager = {
            useGlobalPkgs = true;
            # Packages go to the user profile, so `make home-switch` delivers
            # them without sudo; true would route them into root-owned
            # /etc/profiles/per-user, which only a full darwin-rebuild writes.
            useUserPackages = false;
            backupFileExtension = "backup";
            extraSpecialArgs = specialArgs;
            sharedModules = [ inputs.sops-nix.homeManagerModules.sops ];
            users.${host.user} = host.home;
          };
        }
      ];
    };

  # A standalone home-manager configuration: no OS layer, no root required.
  mkHome = { system, path, modules ? [ ] }:
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = pkgsFor system;
      extraSpecialArgs = { inherit inputs facts; };
      modules = [ path ../modules/home/identity.nix ] ++ modules;
    };
}
