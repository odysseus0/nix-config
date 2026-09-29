{ pkgs, ... }:

{
  imports = [ ./darwin-common.nix ];

  # Homebrew moved to the user level (2026-08-04): the manifest lives in
  # home/brew.nix (rendered to ~/.config/homebrew/Brewfile) and is applied by
  # the sudo-free `make brew-apply` clock. Homebrew never needed root, and
  # keeping it in system activation made every GUI-app change cost a sudo
  # prompt — hostile to remote (SSH) operation. darwin.nix now carries only
  # genuinely system-scoped surfaces.

  # Fonts — store-owned via nixpkgs (moved from Homebrew font casks
  # 2026-08-05). System layer because nix-darwin installs to
  # /Library/Fonts/Nix Fonts; font changes are machine-config cadence.
  fonts.packages = [
    pkgs.nerd-fonts.jetbrains-mono
    pkgs.nerd-fonts.fira-code
  ];

  # Touch ID for sudo - no more password prompts!
  security.pam.services.sudo_local = {
    enable = true;
    touchIdAuth = true;
    reattach = true;  # Enables Touch ID in tmux/screen sessions
  };
}
