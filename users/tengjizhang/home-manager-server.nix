# Home layer for the server role (Sietch: Beads authority, agent host, and the
# X project's jobs). Shares only the shell with the workstation
# (home-manager.nix); packages, services and secrets are the server's own.
# sietch-x.nix imports the private home-ops input, which Sietch reads from its
# own clone at ~/home-ops (read-only deploy key; the Makefile overrides the
# input), so it needs no GitHub token.
{ inputs, ... }:

{ ... }:

{
  imports = [
    ./home/shell.nix
    ./home/server-packages.nix
    ./home/beads-server.nix
    ./home/vault-events-server.nix
    ./home/fleet-server.nix
    ./home/sietch-x.nix
    inputs.home-ops.homeManagerModules.default
    inputs.home-ops.homeManagerModules.bird
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
