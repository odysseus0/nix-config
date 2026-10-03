# Sietch: the headless, always-on Mac mini. The shared Beads authority, the
# Fleet MDM server, the vault event store, the X project's jobs, and an agent
# host. It reads home-ops from its own clone at ~/home-ops (read-only deploy
# key; the Makefile overrides the input), so it needs no GitHub token.
{ inputs, ... }:
{
  system = "aarch64-darwin";
  user = "tengjizhang";

  darwin = [
    ../modules/darwin/server.nix
    ../modules/darwin/base.nix
    ../modules/darwin/account.nix
    ../modules/darwin/homebrew.nix
    {
      # The machine's existing spelling; the flake output is lowercase.
      networking = {
        hostName = "Sietch";
        localHostName = "Sietch";
        computerName = "Sietch";
      };
    }
  ];

  home = {
    imports = [
      ../modules/home/core.nix
      ../modules/home/sietch/packages.nix
      ../modules/home/beads-server.nix
      ../modules/home/sietch/vault-events.nix
      ../modules/home/sietch/fleet.nix
      ../modules/home/sietch/ssh.nix
      ../modules/home/sietch/x-jobs.nix
      inputs.home-ops.homeManagerModules.default
      inputs.home-ops.homeManagerModules.bird
    ];

    home.stateVersion = "26.05";
    programs.home-manager.enable = true;
  };
}
