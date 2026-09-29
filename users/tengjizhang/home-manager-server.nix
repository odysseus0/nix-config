# Home layer for the server role (Sietch: Beads authority and agent host).
# Shares only the shell with the workstation (home-manager.nix); packages,
# services and secrets are the server's own. Imports nothing from the private
# home-ops input, so building this output needs no private-repo credentials.
{ inputs, ... }:

{ ... }:

{
  imports = [
    ./home/shell.nix
    ./home/server-packages.nix
    ./home/beads-server.nix
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
