{
  description = "Two Macs and disposable Linux agent boxes, from one flake";

  inputs = {
    # One rolling nixpkgs: the lock makes it reproducible between bumps, and
    # the weekly build-gated bump (pkgs/nix-flake-bump.nix) keeps it current.
    # A release-branch input would EOL every six months and stop moving.
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Determinate Nix's nix-darwin module (manages /etc/nix/nix.custom.conf).
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/3";

    # Secrets encrypted in git, decrypted at activation.
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # AI agent CLIs built and cached daily by numtide. Consumed through its
    # packages.<system> output, not its overlay, and without
    # nixpkgs.follows: building against numtide's own pin is what makes
    # cache.numtide.com hit (our pin can lack what they need, e.g. pnpm_11).
    llm-agents.url = "github:numtide/llm-agents.nix";

    # Private: everything personal rather than structural (README
    # §Public and private). Only the darwin outputs read it.
    home-ops.url = "github:odysseus0/home-ops";
  };

  outputs = { self, nixpkgs, home-manager, darwin, ... }@inputs: let
    hosts = import ./lib { inherit inputs; };
    forLinux = nixpkgs.lib.genAttrs hosts.linuxSystems;

    # `nix run .#agent`: build this box's agent configuration and activate it.
    # The app itself is pure; the build it runs is the flake's only --impure
    # evaluation, so modules/home/identity.nix can read USER and HOME.
    agentBootstrap = system: (hosts.pkgsFor system).writeShellApplication {
      name = "agent-bootstrap";
      text = ''
        USER="''${USER:-$(id -un)}"
        export USER HOME
        generation="$(nix --extra-experimental-features 'nix-command flakes' build \
          --no-link --print-out-paths --impure \
          '${self}#homeConfigurations.agent-${system}.activationPackage')"
        exec "$generation/activate"
      '';
    };
  in {
    homeConfigurations = nixpkgs.lib.listToAttrs (map (system: {
      name = "agent-${system}";
      value = hosts.mkHome { inherit system; path = ./hosts/agent.nix; };
    }) hosts.linuxSystems);

    apps = forLinux (system: {
      agent = {
        type = "app";
        program = nixpkgs.lib.getExe (agentBootstrap system);
      };
    });

    # CI builds every public output; a fixed account stands in for the box's.
    checks = forLinux (system: {
      agent = (hosts.mkHome {
        inherit system;
        path = ./hosts/agent.nix;
        modules = [ { home.username = "agent"; home.homeDirectory = "/home/agent"; } ];
      }).activationPackage;
    });

    darwinConfigurations = {
      macbook-m4-max = hosts.mkDarwin ./hosts/macbook-m4-max.nix;
      sietch = hosts.mkDarwin ./hosts/sietch.nix;
    };
  };
}
