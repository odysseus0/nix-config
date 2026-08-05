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
#
# REMOVAL TEST for this deviation (priced 2026-08-04): the whole gain over
# nix-darwin's stock homebrew module is that cask changes ship remotely
# (remote sudo is impossible, not merely inconvenient). When the NixOS home
# server takes over remote-agent duty and this Mac is desk-operated again,
# fold this back into darwin.nix's homebrew module — the divergence tax
# (custom arrangement future readers must learn) then outweighs a gain that
# has dropped to one Touch ID tap.

let
  # Taps are DELIBERATE vendor-owned inputs, not an unpinned gap (ruled
  # 2026-08-05 after investigating nix-homebrew + brew-nix; verdicts and
  # revisit triggers in the Beads issue "nix-config: evaluate nix-homebrew").
  # They follow HEAD, but exposure is bounded by architecture: brew-apply is
  # materialize-only, so a tap's HEAD moving can only reach this machine at
  # an explicit `make brew-upgrade` — vendor-owned tier semantics exactly.
  # Graduation triggers: a tap-HEAD change burns us once, the tap count
  # grows past a handful, or the ecosystem consolidates on nix-homebrew.
  taps = [
    "mrkai77/cask"  # For Loop window manager (running daily driver)
    "openclaw/tap"  # For gogcli — NOT OpenClaw-project tooling: gog is the
                    # Google Workspace CLI the /calendar skill runs on
    # steipete/tap dropped 2026-08-05 with CodexBar (unused, replaced by the
    # SwiftBar runtime glance surface direction; bird ships via home-ops).
  ];

  # Command line tools genuinely outside nixpkgs. Surface-area rule
  # (2026-08-05): a formula lives here ONLY if nixpkgs can't supply it —
  # mas, sqlite, zk, tdl moved to store-owned home.packages that day.
  # CAUTION: nixpkgs has a DIFFERENT project named `mole` (SSH tunnels);
  # this mole is mole.fit (Mac cleaner) — name collision, do not "migrate".
  brews = [
    "mole"  # Mac system optimization (mo command) — mole.fit, NOT nixpkgs mole
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
  ];
  # Fonts moved to nix-darwin fonts.packages (nerd-fonts in nixpkgs) —
  # store-owned, pinned, cached; font casks were Homebrew-by-accident.

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
