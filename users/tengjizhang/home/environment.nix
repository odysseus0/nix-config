{ pkgs, ... }:

let
  # Bun global install location (tools already installed here)
  bunInstallDir = "$HOME/.cache/.bun";
  # pnpm global directory (macOS default)
  pnpmHome = if pkgs.stdenv.isDarwin then "$HOME/Library/pnpm" else "$HOME/.local/share/pnpm";
  # npm global directory for CLIs whose vendor updater assumes npm ownership.
  npmPrefix = "$HOME/.npm-global";
in {
  home.sessionVariables = {
    EDITOR = "nvim";
    PAGER = "less -FirSwX";
    GOPATH = "$HOME/go";
    OP_ACCOUNT = "my.1password.com";
    BUN_INSTALL = bunInstallDir;
    PNPM_HOME = pnpmHome;
    NPM_CONFIG_PREFIX = npmPrefix;

    # Amp local CLIProxyAPI override. Temporarily disabled now that Amp can use
    # the default ampcode.com API path directly.
    # AMP_URL = "http://localhost:8317";
    # AMP_API_KEY = "amp-local-proxy-key";

    # Homebrew env vars
    HOMEBREW_PREFIX = "/opt/homebrew";
    HOMEBREW_CELLAR = "/opt/homebrew/Cellar";
    HOMEBREW_REPOSITORY = "/opt/homebrew";
  };

  # Single source of truth for PATH additions (fish + zsh)
  # Only MANPATH/INFOPATH remain in config.fish (need prepend, not set)
  home.sessionPath = [
    # Homebrew
    "/opt/homebrew/bin"
    "/opt/homebrew/sbin"

    # Language toolchain bins
    "$HOME/go/bin"
    "$HOME/.cargo/bin"

    # Dev tools
    "$HOME/.cache/lm-studio/bin"

    # Package manager bins
    "${npmPrefix}/bin"
    pnpmHome
    "${bunInstallDir}/bin"
    "$HOME/.bun/bin"

    # App CLIs
    "/Applications/Hammerspoon.app/Contents/Frameworks/hs"
    "/Applications/Obsidian.app/Contents/MacOS"

    # Local scripts and vendor-managed CLI symlinks
    "$HOME/.local/bin"
  ];
}
