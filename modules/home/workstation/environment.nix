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

  # One PATH entry per owner of tools (README): sessionPath prepends these,
  # in this order, ahead of the Nix profile that nix-darwin adds. A tool
  # installed by two owners is shadowed by the earlier one, so none is.
  home.sessionPath = [
    "/opt/homebrew/bin"
    "$HOME/.local/bin"
  ];
}
