{ ... }:

{
  home.sessionVariables = {
    EDITOR = "nvim";
    PAGER = "less -FirSwX";
    OP_ACCOUNT = "my.1password.com";

    HOMEBREW_PREFIX = "/opt/homebrew";
    HOMEBREW_CELLAR = "/opt/homebrew/Cellar";
    HOMEBREW_REPOSITORY = "/opt/homebrew";
  };

  # Homebrew's and the vendors' PATH entries. sessionPath prepends them, in
  # this order, ahead of the Nix profile that nix-darwin adds.
  home.sessionPath = [
    "/opt/homebrew/bin"
    "$HOME/.local/bin"
  ];
}
