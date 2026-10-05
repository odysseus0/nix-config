# The existing macOS account, its Nix-managed login shell, and the primary
# user that user-scoped nix-darwin options (homebrew, power) apply to.
{ pkgs, user, ... }:

{
  # knownUsers lets nix-darwin manage the existing account, which is what
  # makes it set the login shell. A uid that does not match makes
  # activation warn and leave the account alone.
  users.knownUsers = [ user ];
  users.users.${user} = {
    uid = 501;
    home = "/Users/${user}";
    shell = pkgs.fish;
  };

  system.primaryUser = user;
}
