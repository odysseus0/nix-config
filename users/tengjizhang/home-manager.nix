{ inputs, ... }:

{ config, lib, pkgs, ... }:

{
  imports = [
    ./home/packages.nix
    ./home/programs.nix
    ./home/shell.nix
    ./home/dotfiles.nix
    ./home/environment.nix
    ./home/services.nix
    ./home/secrets.nix
    ./home/brew.nix
    # claudecode.nix removed - ~/.claude/ now git-tracked directly
    # See: ~/.claude/ for skills, commands, output-styles, profiles
    # Personal-ops monorepo — moved out of this (public) repo to the
    # private `home-ops` flake input (was `runtime`, renamed 2026-07-20);
    # was ./runtime/runtime.nix in-tree originally.
    inputs.home-ops.homeManagerModules.default
    # bird: the private X client, packaged in home-ops with its Chrome-read
    # X session (see home-ops bird.nix).
    inputs.home-ops.homeManagerModules.bird
    # `sietch` and the forwarded `feed`: Sietch owns the X state's databases.
    inputs.home-ops.homeManagerModules.sietch-client
  ];

  runtime.host = "macbook";
  bird.enable = true;
  bird.archiveOnSietch = true;
  sietchClient.enable = true;

  # Make inputs available to all imported modules
  _module.args.inputs = inputs;

  # Home Manager configuration
  home.stateVersion = "26.05";

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;

  # Disable release check for version mismatches
  home.enableNixpkgsReleaseCheck = false;
}
