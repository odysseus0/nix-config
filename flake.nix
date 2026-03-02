{
  description = "tengjizhang's nix-darwin configuration - following Mitchell's structure";

  inputs = {
    # Use unstable for latest packages on personal dev machine
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    # Stable channel — cherry-pick packages that break on unstable
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.11";

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

    # Secret management - encrypted secrets in git, decrypted at activation
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, darwin, ... }@inputs: let
    mkSystem = import ./lib/mksystem.nix {
      inherit nixpkgs inputs;
      overlays = [
      # Workaround: jeepney check phase fails with exit code 127 (missing test runner)
      # on nixpkgs-unstable. This breaks yt-dlp -> secretstorage -> jeepney chain.
      # Remove once upstream nixpkgs fixes python313Packages.jeepney.
      (final: prev: {
        pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
          (pyFinal: pyPrev: {
            jeepney = pyPrev.jeepney.overridePythonAttrs {
              doCheck = false;
              # jeepney.io.trio imports 'outcome' which isn't a runtime dep
              pythonImportsCheck = [ "jeepney" "jeepney.auth" "jeepney.io" ];
            };
          })
        ];
      })
    ];
    };
  in {
    darwinConfigurations.macbook-m4-max = mkSystem "macbook-m4-max" {
      system = "aarch64-darwin";
      user = "tengjizhang";
      darwin = true;
    };
  };
}