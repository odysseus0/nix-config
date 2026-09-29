# User OS layer for the headless server role. No fonts, Touch ID or desktop
# defaults: the account layer is all a server shares with the workstation.
{ ... }:

{
  imports = [ ./darwin-common.nix ];

  # Homebrew, declared EMPTY with zap cleanup: a server has no GUI apps and
  # every CLI it needs is store-owned, so activation removes every formula,
  # cask (including its zap stanza's app data) and tap that is not declared
  # here. This is nix-darwin's stock module, not the workstation's user-level
  # Brewfile clock (home/brew.nix): that deviation exists only so cask changes
  # ship without sudo, and a server switch is a supervised sudo boundary anyway.
  # Adding a formula here needs a reason tied to Sietch's role; if the list
  # stays empty, Homebrew itself is the next thing to uninstall.
  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "zap";
      # Materialize only; never fetch or upgrade as a side effect of a switch.
      autoUpdate = false;
      upgrade = false;
    };
  };
}
