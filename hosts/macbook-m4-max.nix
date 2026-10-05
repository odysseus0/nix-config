# The MacBook: the workstation, and where the private home-ops jobs run.
{ inputs, ... }:
{
  system = "aarch64-darwin";
  user = "tengjizhang";

  darwin = [
    ../modules/darwin/workstation.nix
    ../modules/darwin/base.nix
    ../modules/darwin/account.nix
    ../modules/darwin/homebrew.nix
  ];

  home = {
    imports = [
      ../modules/home/workstation/packages.nix
      ../modules/home/workstation/programs.nix
      ../modules/home/core.nix
      ../modules/home/workstation/dotfiles.nix
      ../modules/home/workstation/environment.nix
      ../modules/home/workstation/secrets.nix
      inputs.home-ops.homeManagerModules.default
      inputs.home-ops.homeManagerModules.bird
      # `sietch` and the forwarded `feed`: Sietch owns the X state's databases.
      inputs.home-ops.homeManagerModules.sietch-client
      inputs.home-ops.homeManagerModules.gh-dash
    ];

    runtime.host = "macbook";
    bird.enable = true;
    bird.archiveOnSietch = true;
    sietchClient.enable = true;

    home.stateVersion = "26.05";
    programs.home-manager.enable = true;
  };
}
