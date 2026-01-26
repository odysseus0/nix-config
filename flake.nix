{
  description = "tengjizhang's nix-darwin configuration - following Mitchell's structure";

  inputs = {
    # Use unstable for latest packages on personal dev machine
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    # nix-darwin (master follows unstable)
    darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # home-manager integration (master follows unstable)
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # Fish plugin
    fish-hydro = {
      url = "github:jorgebucaran/hydro/75ab7168a35358b3d08eeefad4ff0dd306bd80d4";
      flake = false;
    };

    # Determinate Nix - official nix-darwin integration module
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/3";

    # LLM/AI CLI tools - daily updated packages from Numtide
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, darwin, ... }@inputs: let
    mkSystem = import ./lib/mksystem.nix {
      inherit nixpkgs inputs;
      overlays = [];
    };
  in {
    darwinConfigurations.macbook-m4-max = mkSystem "macbook-m4-max" {
      system = "aarch64-darwin";
      user = "tengjizhang";
      darwin = true;
    };
  };
}