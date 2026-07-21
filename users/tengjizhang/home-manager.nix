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
    # Personal-ops monorepo — moved out of this (public) repo to the
    # private `home-ops` flake input (was `runtime`, renamed 2026-07-20);
    # was ./runtime/runtime.nix in-tree originally.
    inputs.home-ops.homeManagerModules.default
    # WeChat/chatlog config — also lives in home-ops (account id + Tencent
    # container path, not fit for this public repo). See
    # home-ops/README.md "chatlog" for the sops-placeholder wiring: this
    # module reads config.sops.placeholder.* directly, so the secret
    # *declarations* in ./home/secrets.nix are what actually wire it up.
    inputs.home-ops.homeManagerModules.chatlog
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
