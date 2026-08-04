{ pkgs, ... }:

let
  # Bun global install location (tools already installed here)
  bunInstallDir = "$HOME/.cache/.bun";
  # npm global directory for CLIs whose vendor updater assumes npm ownership.
  npmPrefix = "$HOME/.npm-global";
  # Vite+ (vp) — VENDOR-OWNED. Vite+ is beta and its runtime-manager design
  # currently assumes it owns Node itself (upstream voidzero-dev/vite-plus
  # issues #977 "system Node support", #943 "distro packaging" are both
  # open), so it can't yet be a Nix-built package without fighting that
  # assumption. Graduates to store-owned when either issue lands, or when it
  # reaches nixpkgs/llm-agents.nix directly. Nix owns PATH only (below); the
  # one-time vendor installer run lives in MIGRATION.md, not in activation —
  # see home/packages.nix's note on why activation stays offline.
  vitePlusHome = "$HOME/.vite-plus";
in {
  home.sessionVariables = {
    EDITOR = "nvim";
    PAGER = "less -FirSwX";
    GOPATH = "$HOME/go";
    OP_ACCOUNT = "my.1password.com";
    BUN_INSTALL = bunInstallDir;
    NPM_CONFIG_PREFIX = npmPrefix;
    VP_HOME = vitePlusHome;

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
    "${vitePlusHome}/bin"

    # Package manager bins (pnpm wiring removed with the pnpm tier,
    # 2026-08-04 — ~/Library/pnpm is drained by MIGRATION.md)
    "${npmPrefix}/bin"
    "${bunInstallDir}/bin"
    "$HOME/.bun/bin"

    # App CLIs
    "/Applications/Hammerspoon.app/Contents/Frameworks/hs"
    "/Applications/Obsidian.app/Contents/MacOS"

    # Local scripts and vendor-managed CLI symlinks
    "$HOME/.local/bin"
  ];
}
