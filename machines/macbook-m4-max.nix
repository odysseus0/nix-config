{ config, pkgs, ... }: {
  # Set in Sept 2025 as part of the macOS Sequoia release (following Mitchell's pattern)
  system.stateVersion = 5;

  # This makes it work with the Determinate Nix installer
  ids.gids.nixbld = 30000;

  # We use proprietary software on this machine
  nixpkgs.config.allowUnfree = true;

  # Determinate Nix manages the nix daemon; nix-darwin should not.
  nix.enable = false;

  # Binary caches for pre-built packages (written to /etc/nix/nix.custom.conf)
  # - cache.nixos.org: Official cache (included by default)
  # - nix-community.cachix.org: Community packages
  # - cache.numtide.com: LLM/AI tools from numtide/llm-agents.nix
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
  environment.systemPackages = with pkgs; [
    # Basic system utilities (Mitchell's pattern)
    cachix
    mosh  # system-level so non-interactive SSH can find mosh-server
    tmux  # better than zellij for iOS terminals (scroll mode works with touch)
  ];


}