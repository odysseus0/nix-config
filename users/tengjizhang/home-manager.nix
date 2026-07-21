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
    # claudecode.nix removed - ~/.claude/ now git-tracked directly
    # See: ~/.claude/ for skills, commands, output-styles, profiles
    # Personal runtime layer — moved out of this (public) repo to the
    # private `runtime` flake input; was ./runtime/runtime.nix in-tree.
    inputs.runtime.homeManagerModules.default
  ];

  # Make inputs available to all imported modules
  _module.args.inputs = inputs;

  # Home Manager configuration
  home.stateVersion = "26.05";

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;

  # Disable release check for version mismatches
  home.enableNixpkgsReleaseCheck = false;
}
