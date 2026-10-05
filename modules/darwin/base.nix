# Every Mac: Determinate Nix with one cache policy, and the same shells.
{ pkgs, ... }: {
  system.stateVersion = 5;

  # The GID the Determinate installer gives the nixbld group; nix-darwin
  # refuses to activate when its expectation differs.
  ids.gids.nixbld = 30000;

  # Determinate Nix manages the nix daemon; nix-darwin should not.
  nix.enable = false;

  # Caches beyond cache.nixos.org, written to /etc/nix/nix.custom.conf.
  # cache.numtide.com serves llm-agents.nix, which numtide builds daily;
  # without it the agent CLIs compile locally. That flake's own nixConfig
  # reaches a consumer only with --accept-flake-config, so it is declared
  # here, and here rather than nix.settings, which Determinate ignores.
  determinateNix.customSettings = {
    extra-substituters = "https://nix-community.cachix.org https://cache.numtide.com";
    extra-trusted-public-keys = "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs= niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g=";
  };

  # nix-darwin owns /etc/zshrc and /etc/fish/config.fish, which replaces the
  # Nix installer's hook in them; each shell sources the daemon profile here.
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
