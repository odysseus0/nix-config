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
  ];

  # Make inputs available to all imported modules
  _module.args.inputs = inputs;

  # Home Manager configuration
  home.stateVersion = "24.05";

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;

  # Disable release check for version mismatches
  home.enableNixpkgsReleaseCheck = false;
}
