# How hosts are assembled. Inputs and facts reach every module as
# extraSpecialArgs; the overlay is applied here and nowhere else.
{ inputs }:
let
  facts = import ./facts.nix;
  overlays = [ (import ../pkgs) ];
in
rec {
  linuxSystems = [ "x86_64-linux" "aarch64-linux" ];

  pkgsFor = system: import inputs.nixpkgs { inherit system overlays; };

  # A standalone home-manager configuration: no OS layer, no root required.
  mkHome = { system, path, modules ? [ ] }:
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = pkgsFor system;
      extraSpecialArgs = { inherit inputs facts; };
      modules = [ path ../modules/home/identity.nix ] ++ modules;
    };
}
