{ lib, ... }:

# MANIFEST-OWNED: Homebrew, demoted from nix-darwin's system-level module to
# a user-level clock (2026-08-04). Homebrew never needed root — /opt/homebrew
# is user-writable; it sat inside system activation only because nix-darwin's
# module lives there, which made every GUI-app change cost a sudo prompt and
# blocked remote (SSH) operation. Now: Nix declares the manifest below and
# renders ~/.config/homebrew/Brewfile; `make brew-apply` (sudo-free,
# explicit, materialize-only) reconciles; `make brew-upgrade` is the upgrade
# clock. This also removes the old carve-out where Homebrew was the one
# manifest-owned domain running inside activation — no tier exception left.
#
# Why Homebrew at all (unchanged): nixpkgs doesn't handle Mac App Store apps,
# and many GUI casks are unpackaged/outdated in nixpkgs on macOS.

let
  taps = [
    "mrkai77/cask"  # For Loop window manager
    "steipete/tap"  # For CodexBar
    "openclaw/tap"  # For gogcli
  ];

  # Command line tools that aren't in nixpkgs or need macOS-specific versions
  brews = [
    "mas"  # Mac App Store CLI
    "mole"  # Mac system optimization (mo command)
    "sqlite"  # SQLite with extension support (FTS5 etc.; used by zk, chatlog/wechat queries)
    "zk"  # Zettelkasten CLI - backlinks, orphans, link analysis for Obsidian vault
    "telegram-downloader"  # tdl: Telegram message export/sync with takeout API support
    "openclaw/tap/gogcli"  # Google Workspace CLI (gog); Clawdbot skill dependency
    "cliproxyapi"  # Unified proxy for AI coding CLIs (Claude, Gemini, Amp, Codex)
    # beads lives in the store-owned tier (llm-agents.nix) — do not re-add here.
  ];

  # GUI applications. `greedy` marks auto-updating casks so explicit upgrades
  # still consider them.
  casks = [
    # Browsers & Communication
    "google-chrome"
    "google-chrome@canary"
    "orion"
    "slack"
    "discord"
    "beeper"
    "element"
    "signal"
    "whatsapp"
    "telegram"
    "telegram-desktop"
    "zoom"

    # Development
    "ghostty@tip"
    "visual-studio-code@insiders"
    "orbstack"
    "tableplus"
    "zed"
    "proxyman"

    # Network & Security
    "tailscale-app"

    # AI Tools
    "chatgpt"
    "lm-studio"
    "steipete/tap/codexbar"

    # Productivity
    "1password"
    "obsidian"
    "notion"
    "notion-calendar"
    "linear"
    "raycast"
    "cleanshot"
    "claude"

    # Learning & Research
    "anki"
    "calibre"
    "zotero@beta"

    # System & Utilities
    "rectangle"
    "hammerspoon"
    "imageoptim"
    "istat-menus"
    "monodraw"
    "the-unarchiver"
    "aldente"
    "appcleaner"
    "jordanbaird-ice"
    "qlmarkdown"
    "swiftbar"  # menu-bar glance surface for the runtime layer (~/home-ops/runtime/runtime.30s.ts)
    "keymapp"
    "pika"
    "qflipper"
    "mrkai77/cask/loop"
    "stretchly"
    "macwhisper"

    # Media & Design
    "figma"
    "spotify"
    "iina"

    # Cloud & Utilities
    {
      name = "google-drive";
      # Auto-updating cask; greedy keeps it visible to explicit upgrades.
      greedy = true;
    }

    # Fonts (Mitchell's selection)
    "font-jetbrains-mono-nerd-font"
    "font-fira-code-nerd-font"
  ];

  # Mac App Store apps
  masApps = {
    # Apple's Official Apps
    "Xcode" = 497799835;
    "Keynote" = 409183694;
    "Numbers" = 409203825;
    "Pages" = 409201541;
    "iMovie" = 408981434;
    "Developer" = 640199958;
    "TestFlight" = 899247664;

    # Security & Browser Extensions
    "1Password for Safari" = 1569813296;
    "Obsidian Web Clipper" = 6720708363;
    "StopTheMadness" = 1376402589;
    "Vimari" = 1480933944;

    # Productivity & Communication
    "Amphetamine" = 937984704;
    "Drafts" = 1435957248;
    "Things" = 904280696;
    # "WeChat" = 836500024;
    # ^ Manually managed — pinned to 4.0.3.80 for chatlog compatibility.
    # Newer versions changed DB schema, breaking chatlog export.
    # Download: https://github.com/zsbai/wechat-versions/releases/download/v4.0.3.80/WeChatMac-4.0.3.80.dmg
    # Backup:   ~/Backups/WeChatMac-4.0.3.80.dmg

    # Specialized Tools
    "Flighty" = 1358823008;
    "Focus for YouTube" = 1514703160;
    "MarginNote 3" = 1423522373;
    "Portal" = 1436994560;
    "Quantumult X" = 1443988620;
  };

  caskLine = c:
    if builtins.isString c then ''cask "${c}"''
    else ''cask "${c.name}"${lib.optionalString (c.greedy or false) ", greedy: true"}'';

  brewfile = lib.concatStringsSep "\n" (
    map (t: ''tap "${t}"'') taps
    ++ map (b: ''brew "${b}"'') brews
    ++ map caskLine casks
    ++ lib.mapAttrsToList (name: id: ''mas "${name}", id: ${toString id}'') masApps
  ) + "\n";
in
{
  xdg.configFile."homebrew/Brewfile".text = brewfile;
}
