# User OS layer for the headless server role. No fonts, Touch ID or desktop
# defaults: the account layer is all a server shares with the workstation.
{ ... }:

{
  imports = [ ./darwin-common.nix ];

  # The Codex desktop app (the `chatgpt` cask) keeps agent threads running
  # here. It self-updates (Sparkle); brew only materializes it.
  homebrew.casks = [ "chatgpt" ];
}
