# The workstation's system layer: terminal tools for remote shells, fonts,
# Touch ID, and the GUI and App Store apps.
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    mosh  # system-level so non-interactive SSH can find mosh-server
    tmux  # scroll mode works with touch in iOS terminals
  ];

  # Fonts install to /Library/Fonts/Nix Fonts, so they are system-scoped.
  fonts.packages = [
    pkgs.nerd-fonts.jetbrains-mono
    pkgs.nerd-fonts.fira-code
  ];

  # Touch ID for sudo, also inside tmux.
  security.pam.services.sudo_local = {
    enable = true;
    touchIdAuth = true;
    reattach = true;
  };

  # GUI apps and Mac App Store apps: nixpkgs handles neither well on macOS.
  homebrew = {
    # Taps follow HEAD, but activation only materializes, so a tap's HEAD
    # reaches this machine only at an explicit `make brew-upgrade`.
    taps = [
      "mrkai77/cask"   # Loop
      "openclaw/tap"   # gogcli
    ];

    # Formulae only when nixpkgs cannot supply them.
    brews = [
      "mole"                 # mole.fit, the Mac cleaner (nixpkgs' mole is an unrelated SSH tool)
      "openclaw/tap/gogcli"  # gog, a Google Workspace CLI
    ];

    casks = [
      # Browsers & communication
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
      "zoom"

      # Development
      "ghostty@tip"
      "orbstack"
      "tableplus"
      "zed"
      "proxyman"
      "chromedriver"

      # Network
      "tailscale-app"

      # AI
      "chatgpt"
      "lm-studio"
      "macwhisper"
      "t3-code"

      # Productivity
      "1password"
      "obsidian"
      "notion"
      "notion-calendar"
      "linear"
      "raycast"
      "cleanshot"
      "fantastical"  # Flexibits website build; license entered in-app
      "claude"
      "anarlog"  # meeting recorder with local transcription

      # Learning & research
      "anki"
      "calibre"
      "zotero@beta"

      # System & utilities
      "hammerspoon"
      "imageoptim"
      "istat-menus"
      "monodraw"
      "the-unarchiver"
      "aldente"
      "appcleaner"
      "qlmarkdown"
      "swiftbar"  # menu-bar status for home-ops' runtime layer
      "keymapp"
      "pika"
      "qflipper"
      "mrkai77/cask/loop"
      "stretchly"

      # Media & design
      "figma"
      "spotify"
      "iina"

      # brew upgrade skips a self-updating cask unless it is greedy.
      { name = "google-drive"; greedy = true; }
    ];

    masApps = {
      "Xcode" = 497799835;
      "Keynote" = 409183694;
      "Numbers" = 409203825;
      "Pages" = 409201541;
      "iMovie" = 408981434;
      "Developer" = 640199958;
      "TestFlight" = 899247664;

      "1Password for Safari" = 1569813296;
      "Obsidian Web Clipper" = 6720708363;
      "StopTheMadness" = 1376402589;
      "Vimari" = 1480933944;

      "Amphetamine" = 937984704;
      "Drafts" = 1435957248;
      "Things" = 904280696;
      # WeChat is installed by hand (wx-cli reads its databases directly).

      "Flighty" = 1358823008;
      "Focus for YouTube" = 1514703160;
      "Portal" = 1436994560;
      "Quantumult X" = 1443988620;
    };
  };
}
