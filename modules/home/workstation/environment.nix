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

  # PATH is the tier list: the Nix profile (added by nix-darwin), Homebrew,
  # and ~/.local/bin for vendor-owned tools and local scripts. Nothing else,
  # so no install channel outside the tiers can win or lose against the
  # profile. Prepended in this order.
  home.sessionPath = [
    "/opt/homebrew/bin"
    "$HOME/.local/bin"
  ];
}
