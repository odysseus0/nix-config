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

    # Secret management - encrypted secrets in git, decrypted at activation
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Personal-ops monorepo (runtime layer + chatlog config + future life-ops
    # machinery). Private repo — was users/tengjizhang/runtime/ in-tree here,
    # moved out because it carries a WeChat account id + personal ritual
    # entries this (public) repo must not contain. Renamed runtime -> home-ops
    # 2026-07-20 (home-ops community naming; absorbs more than just the
    # runtime layer now). Not yet pushed to GitHub; for local eval before
    # that, override with:
    #   --override-input home-ops /Users/tengjizhang/home-ops
    home-ops.url = "git+ssh://git@github.com/odysseus0/home-ops";

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
