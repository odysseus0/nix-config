# User OS layer for the headless server role. No fonts, Touch ID or desktop
# defaults: the account layer is all a server shares with the workstation.
{ ... }:

{
  imports = [ ./darwin-common.nix ];

  # Homebrew exists on this host for one cask: the Codex desktop app, which
  # ships as the `chatgpt` cask (the old `codex-app` cask is deprecated in its
  # favour) and keeps agent threads running on Sietch. Zap cleanup: activation
  # removes every formula, cask (with its zap stanza's app data) and tap not
  # declared here. This is nix-darwin's stock module, not the workstation's
  # user-level Brewfile clock (home/brew.nix): that deviation exists only so
  # cask changes ship without sudo, and a server switch is a supervised sudo
  # boundary anyway. Anything added here needs a reason tied to Sietch's role;
  # if the cask goes, Homebrew itself goes with it.
  homebrew = {
    enable = true;
    # Self-updating app (Sparkle); brew only materializes it.
    casks = [ "chatgpt" ];
    onActivation = {
      cleanup = "zap";
      # Materialize only; never fetch or upgrade as a side effect of a switch.
      autoUpdate = false;
      upgrade = false;
    };
  };
}
