# One Homebrew on every Mac: declared equals installed. Zap removes every
# formula, cask (with its app data) and tap not declared for this host.
# Activation only materializes; `make brew-upgrade` is the upgrade step.
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
