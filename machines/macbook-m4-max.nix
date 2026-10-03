{ pkgs, ... }: {
  imports = [ ./darwin-common.nix ];

  environment.systemPackages = with pkgs; [
    mosh  # system-level so non-interactive SSH can find mosh-server
    tmux  # better than zellij for iOS terminals (scroll mode works with touch)
  ];
}
