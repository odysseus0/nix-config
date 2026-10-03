# Account layer shared by every Darwin role (workstation and server): the
# existing macOS account, its Nix-managed login shell, and the primary user
# that user-scoped nix-darwin options (homebrew, power, defaults) apply to.
{ pkgs, ... }:

{
  # knownUsers lets nix-darwin manage the existing account, which is what
  # makes it set the login shell. A uid that does not match makes
  # activation warn and leave the account alone.
  users.knownUsers = [ "tengjizhang" ];
  users.users.tengjizhang = {
    uid = 501;
    home = "/Users/tengjizhang";
    shell = pkgs.fish;
  };

  # Required for some settings like homebrew to know what user to apply to.
  system.primaryUser = "tengjizhang";

  # One Homebrew on every Mac: declared equals installed. Zap removes every
  # formula, cask (with its app data) and tap not declared for this host.
  # Activation only materializes; `make brew-upgrade` is the upgrade step.
  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "zap";
      autoUpdate = false;
      upgrade = false;
    };
  };
}
