{
  description = "George's declarative computing environment — hermetic builds, ownership-tiered tooling";

  inputs = {
    # Use unstable for latest packages on personal dev machine. Single nixpkgs:
    # rolling channel + lockfile + a bump cadence (make update-commit-push, on
    # the monthly clock) is the whole design — reproducible between bumps,
    # current after them. A second release-branch input is a standing liability:
    # release branches EOL every six months and silently stop moving.
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
    
    # Determinate Nix - official nix-darwin integration module
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/3";

    # Secret management - encrypted secrets in git, decrypted at activation
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Store-owned AI coding agent CLIs (claude-code, codex, amp, pi,
    # agent-browser, qmd, beads, ...), built and cached daily by numtide.
    # Consumed via its `packages.<system>` output (home/packages.nix), NOT via
    # its `overlays.shared-nixpkgs`: the overlay rebuilds against *our*
    # nixpkgs pin, which is old enough to break (hit 2026-08-04:
    # agent-browser needs `pnpm_11`, absent from our pin) and forfeits the
    # cache. Same reason `nixpkgs.follows` is intentionally NOT set here —
    # building against numtide's own pin is what guarantees the
    # cache.numtide.com hit (substituter wired in machines/).
    llm-agents.url = "github:numtide/llm-agents.nix";

    # Personal-ops monorepo (runtime layer + future life-ops
    # machinery). Private repo — was users/tengjizhang/runtime/ in-tree here,
    # moved out because it carries a WeChat account id + personal ritual
    # entries this (public) repo must not contain. Renamed runtime -> home-ops
    # 2026-07-20 (home-ops community naming; absorbs more than just the
    # runtime layer now). github: fetcher, not git+ssh — this machine auths
    # to GitHub via HTTPS + gh token only (no SSH keys); private-repo fetch
    # needs `access-tokens = github.com=<token>` in ~/.config/nix/nix.conf.
    # For local eval without network:
    #   --override-input home-ops /Users/tengjizhang/home-ops
    home-ops.url = "github:odysseus0/home-ops";

  };

  outputs = { self, nixpkgs, home-manager, darwin, ... }@inputs: let
    mkSystem = import ./lib/mksystem.nix {
      inherit nixpkgs inputs;
      overlays = [
        (final: prev: {
          herdr = final.callPackage ./lib/herdr-bin.nix { };
        })
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
        # No llm-agents overlay here — deliberate; see the `llm-agents` input.

        # MANIFEST-OWNED tier executor, exposed as pkgs.uv-tools-reconcile so
        # `make update-tools` can address it directly by flake output path.
        (final: prev: {
          uv-tools-reconcile = final.callPackage ./lib/uv-tools-reconcile.nix { };
        })
      ];
    };
  in {
    darwinConfigurations.macbook-m4-max = mkSystem "macbook-m4-max" {
      system = "aarch64-darwin";
      user = "tengjizhang";
      darwin = true;
    };

    # Headless Mac mini: the shared Beads authority and a remote-shell host.
    # role = "server" selects users/<user>/{darwin,home-manager}-server.nix.
    darwinConfigurations.sietch = mkSystem "sietch" {
      system = "aarch64-darwin";
      user = "tengjizhang";
      darwin = true;
      role = "server";
    };

    # Linux remote-worker: standalone HM (no systemd → no nixos-rebuild).
    # Shared pkgs: lib/remote-worker-packages.nix. Host-only: Tailscale + Beads→Sietch.
    # Auth out of band. Switch: make remote-worker-switch / nix run .#remote-worker-switch
    homeConfigurations.remote-worker =
      let
        system = "x86_64-linux";
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      in home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [ ./machines/remote-worker.nix ./users/box/home.nix ];
      };

    apps.x86_64-linux.remote-worker-switch =
      let
        pkgs = import nixpkgs { system = "x86_64-linux"; };
        act = self.homeConfigurations.remote-worker.activationPackage;
      in {
        type = "app";
        program = "${pkgs.writeShellApplication {
          name = "remote-worker-switch";
          text = ''exec "${act}/activate"'';
        }}/bin/remote-worker-switch";
      };
  };
}
