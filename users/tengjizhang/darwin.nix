{ pkgs, ... }:

{
  # Homebrew for GUI apps - Why not Nix?
  # 1. Nix doesn't support Mac App Store apps well
  # 2. Many GUI apps aren't packaged in nixpkgs or are outdated/broken on macOS
  # 3. Homebrew casks work great and we still manage them declaratively here
  # Trade-off: Not pure Nix, but pragmatic for macOS GUI apps
  homebrew = {
    enable = true;

    # Additional taps for specialized apps
    taps = [
      "mrkai77/cask"  # For Loop window manager
      "steipete/tap"  # For CodexBar, bird, gogcli
      "yakitrak/yakitrak"  # For obsidian-cli
      # lbjlaq/antigravity-manager: managed via activation script below
      # (nix-darwin's clone_target generates wrong Brewfile syntax)
    ];

    # GUI Applications via Homebrew casks
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
      "telegram"
      "telegram-desktop"
      "zoom"
      
      # Development
      "cursor"
      "ghostty@tip" 
      "visual-studio-code@insiders"
      "orbstack"
      "tableplus"
      "transmit"
      "zed"
      "chromedriver"
      "proxyman"
      "sublime-merge"
      "rapidapi"

      # Network & Security
      "tailscale-app"
      
      # AI Tools
      "chatgpt"
      "lm-studio"
      "steipete/tap/codexbar"
      "antigravity-tools"  # AI account proxy (tap manually managed)
      
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
      "keymapp"
      "pika"
      "qflipper"
      "loop"
      "stretchly"
      "macwhisper"
      
      # Media & Design
      "figma"
      "spotify"
      "iina"
      
      # Cloud & Utilities
      "google-drive"
      
      # Fonts (Mitchell's selection)
      "font-jetbrains-mono-nerd-font"
      "font-fira-code-nerd-font"
    ];

    # Command line tools that aren't in nixpkgs or need macOS-specific versions
    brews = [
      "mas"  # Mac App Store CLI
      "mole"  # Mac system optimization (mo command)
      "sqlite"  # SQLite with extension support (required by qmd)
      # bird: installed from personal fork via activation script below

      # Clawdbot skill dependencies
      "steipete/tap/gogcli"  # Google Workspace CLI (gog)
      "yakitrak/yakitrak/obsidian-cli"  # Obsidian vault CLI
    ];

    onActivation = {
      cleanup = "zap";
      autoUpdate = true;
      upgrade = true;
    };

    # Mac App Store apps (modern syntax)
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
      # ^ Manually managed - pinned to 4.0.3.80 for chatlog compatibility
      # Newer versions changed DB schema, breaking chatlog export tool
      # Download: https://github.com/zsbai/wechat-versions/releases/download/v4.0.3.80/WeChatMac-4.0.3.80.dmg
      # Backup:   ~/Backups/WeChatMac-4.0.3.80.dmg
      
      # Specialized Tools
      "Flighty" = 1358823008;
      "Focus for YouTube" = 1514703160;
      "MarginNote 3" = 1423522373;
      "Portal" = 1436994560;
      "Quantumult X" = 1443988620;
    };
  };


  # bird CLI: installed via pnpm dlx alias in shell.nix
  # Using alias instead of global install - auto-updates on new commits

  # Custom taps requiring non-standard URLs (run before homebrew bundle)
  # Using preActivation because nix-darwin's clone_target generates incorrect Brewfile syntax
  # Uses same sudo pattern as nix-darwin's homebrew module: --user + --set-home
  system.activationScripts.preActivation.text = ''
    # Antigravity Tools - AI account proxy
    if [ -x /opt/homebrew/bin/brew ]; then
      if ! sudo --user=tengjizhang --set-home /opt/homebrew/bin/brew tap 2>/dev/null | grep -q "lbjlaq/antigravity-manager"; then
        echo "Tapping lbjlaq/antigravity-manager (custom URL)..."
        sudo --user=tengjizhang --set-home /opt/homebrew/bin/brew tap lbjlaq/antigravity-manager https://github.com/lbjlaq/Antigravity-Manager || true
      fi
    fi
  '';

  # Go packages not in Homebrew - install/update on activation
  system.activationScripts.goPackages.text = ''
    echo "Updating Go packages..."
    GOBIN="$HOME/.bun/bin" ${pkgs.go}/bin/go install github.com/ossianhempel/things3-cli/cmd/things@latest 2>/dev/null || true
  '';

  # Helpful warning if not signed into App Store
  system.activationScripts.masLoginCheck.text = ''
    if ! ${pkgs.mas}/bin/mas account >/dev/null 2>&1; then
      echo "⚠️  Not signed into the Mac App Store. Open App Store, sign in, then rerun: darwin-rebuild switch"
    fi
  '';

  # Ensure the login shell for the primary user is the nix-managed path.
  # Darwin intentionally does NOT change shells for existing accounts via users.users.*,
  # so we do it declaratively here during activation. Safe and idempotent.
  system.activationScripts.fixUserShell.text = ''
    set -e
    USERNAME="tengjizhang"
    DESIRED="/run/current-system/sw/bin/fish"

    # Read current login shell from Directory Services (returns: "UserShell: <path>")
    CURRENT=$(/usr/bin/dscl . -read /Users/"$USERNAME" UserShell 2>/dev/null | /usr/bin/awk '{print $2}')

    if [ "$CURRENT" != "$DESIRED" ]; then
      echo "Updating login shell for $USERNAME: ${CURRENT:-<unset>} -> $DESIRED"
      # chsh requires the shell to be present in /etc/shells; nix-darwin's environment.shells ensures this.
      /usr/bin/chsh -s "$DESIRED" "$USERNAME" \
        || /usr/bin/dscl . -create "/Users/$USERNAME" UserShell "$DESIRED"
    fi
  '';

  # The user should already exist, but we need to set this up so Nix knows
  # what our home directory is (https://github.com/LnL7/nix-darwin/issues/423).
  users.users.tengjizhang = {
    home = "/Users/tengjizhang";
    shell = pkgs.fish;
  };

  # Touch ID for sudo - no more password prompts!
  security.pam.services.sudo_local = {
    enable = true;
    touchIdAuth = true;
    reattach = true;  # Enables Touch ID in tmux/screen sessions
  };

  # Required for some settings like homebrew to know what user to apply to.
  system.primaryUser = "tengjizhang";
}
