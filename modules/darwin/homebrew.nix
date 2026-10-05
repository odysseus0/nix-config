# Homebrew on every Mac. Zap removes every formula, cask and tap this host
# does not declare, and a removed cask's app data with it.
{ ... }:

{
  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "zap";
      autoUpdate = false;
      upgrade = false;
    };
  };
}
