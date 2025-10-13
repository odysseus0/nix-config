{
  description = "tengjizhang's nix-darwin configuration - following Mitchell's structure";

  inputs = {
    # Pin nixpkgs like Mitchell does
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    
    # We use the unstable nixpkgs repo for some packages.
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    
    # nix-darwin
    darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # home-manager integration
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # Fish plugin
    fish-hydro = {
      url = "github:jorgebucaran/hydro/75ab7168a35358b3d08eeefad4ff0dd306bd80d4";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, home-manager, darwin, ... }@inputs: let
    # Overlay to expose unstable packages
    overlays = [
      (final: prev: {
        unstable = import inputs.nixpkgs-unstable {
          system = final.system;
          config.allowUnfree = true;
        };
      })
    ];

    mkSystem = import ./lib/mksystem.nix {
      inherit overlays nixpkgs inputs;
    };
  in {
    darwinConfigurations.macbook-m4-max = mkSystem "macbook-m4-max" {
      system = "aarch64-darwin";
      user = "tengjizhang";
      darwin = true;
    };
  };
}