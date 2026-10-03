# Every Mac: Determinate Nix with one cache policy, and the same shells.
{ pkgs, ... }: {
  system.stateVersion = 5;

  # This makes it work with the Determinate Nix installer
  ids.gids.nixbld = 30000;

  # Determinate Nix manages the nix daemon; nix-darwin should not.
  nix.enable = false;

  # Binary caches for pre-built packages (written to /etc/nix/nix.custom.conf)
  # - cache.nixos.org: Official cache (included by default)
  # - nix-community.cachix.org: Community packages
  # - cache.numtide.com: llm-agents.nix (store-owned AI agent CLIs), built and
  #   pushed daily by numtide CI. Without this, `pi`/`agent-browser`/`qmd`/etc.
  #   build from source locally instead of fetching the prebuilt binary — see
  #   llm-agents.nix's own README §Binary Cache. `nixConfig` in that flake's
  #   flake.nix does NOT propagate automatically to a consumer without
  #   `--accept-flake-config`, so it must be declared explicitly here too;
  #   Determinate Nix ignores `nix.settings` (`nix.enable = false` below), so
  #   this goes through `determinateNix.customSettings` like nix-community.
  determinateNix.customSettings = {
    extra-substituters = "https://nix-community.cachix.org https://cache.numtide.com";
    extra-trusted-public-keys = "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs= niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g=";
  };

  # zsh is the default shell on Mac and we want to make sure that we're
  # configuring the rc correctly with nix-darwin paths.
  programs.zsh.enable = true;
  programs.zsh.shellInit = ''
    # Nix
    if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
      . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
    fi
    # End Nix
    '';

  programs.fish.enable = true;
  programs.fish.shellInit = ''
    # Nix
    if test -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish'
      source '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish'
    end
    # End Nix
    '';

  environment.shells = with pkgs; [ bashInteractive zsh fish ];
}
