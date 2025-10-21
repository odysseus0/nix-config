{ inputs, ... }:

{ config, lib, pkgs, ... }:

let
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;
  # Shell aliases - Mitchell's pattern: simple string replacements in Nix
  shellAliases = {
    # Git shortcuts (from your aliases, but simplified)
    ga = "git add";
    gc = "git commit";
    gco = "git checkout";
    gs = "git status";
    gp = "git push";
    gl = "git log --oneline -10";
    
    # Modern CLI tools (move from fish aliases)
    ls = "eza";
    ll = "eza -la";
    la = "eza -la";
    
    # Keep your existing simple aliases
    t = "task";
  };
in {
  # Home Manager configuration
  home.stateVersion = "24.05";
  
  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;
  
  # Disable release check for version mismatches
  home.enableNixpkgsReleaseCheck = false;

  #---------------------------------------------------------------------
  # Packages - Core development tools
  #---------------------------------------------------------------------
  
  home.packages = with pkgs; [
    # Version control & GitHub
    git
    gh
    
    # Modern CLI alternatives
    bat         # better cat
    eza         # better ls  
    fd          # better find
    fzf         # fuzzy finder
    ripgrep     # better grep
    tree        # directory tree
    btop        # system monitor (better than htop)
    jq          # JSON processor
    delta       # better git diff
    
    # Development utilities
    curl
    wget
    unzip
    ast-grep    # code searching tool
    fx          # JSON explorer
    pandoc      # document converter
    sd          # modern sed replacement
    yq          # YAML processor
    
    # Your additional tools  
    taskwarrior3 # task management (CLI)
    zoxide      # smart cd
    direnv      # environment management
    rclone      # cloud storage sync
    uv          # modern Python package manager
    yt-dlp      # YouTube downloader
    zellij      # terminal multiplexer
    
    # Essential development tools
    asciinema   # terminal recorder
    watch       # command repeater
    atuin       # shell history search
    
    # Node.js runtime (for editor integration)
    nodejs      # for editor integration and basic needs
    pnpm        # for accessing latest npm packages efficiently
    
    # AI CLI tools (from nixpkgs cache)
    codex

    # Latest AI tools (cutting-edge via npm)
    (writeShellScriptBin "codex-latest" ''
      exec ${pnpm}/bin/pnpm dlx @openai/codex@latest "$@"
    '')
    (writeShellScriptBin "claude" ''
      exec ${pnpm}/bin/pnpm dlx @anthropic-ai/claude-code@latest "$@"
    '')
    
    # Programming languages
    go              # Go programming language
    
    # Infrastructure tools
    terraform       # Infrastructure as code
    
    # Cloud CLIs (work requirements, Nix-managed)
    google-cloud-sdk  # Google Cloud Platform CLI
    awscli2          # AWS CLI (latest version)
    _1password-cli   # 1Password CLI tool
  ] ++ (lib.optionals isDarwin [
    # macOS-specific packages that don't exist or work differently on Linux
    # (Most CLI tools above work identically on both platforms)
  ]);

  #---------------------------------------------------------------------
  # Environment Variables - Mitchell's pattern
  #---------------------------------------------------------------------
  
  home.sessionVariables = {
    EDITOR = "nvim";
    PAGER = "less -FirSwX";
    GOPATH = "$HOME/go";

    # 1Password configuration for general use
    OP_ACCOUNT = "my.1password.com";
  };

  #---------------------------------------------------------------------
  # Dotfiles - Direct file management (Mitchell's pattern)
  #---------------------------------------------------------------------
  
  home.file = {
    # SSH directory setup
    ".ssh/.keep" = {
      text = "";
      executable = false;
    };
    
    # Tier 1 dotfiles - simple, high-impact configurations
    ".taskrc".source = ./taskrc;
    ".fdignore".source = ./fdignore;
    ".rgignore".source = ./rgignore;
    ".gitignore".source = ./gitignore;  # Global gitignore
  };
  
  #---------------------------------------------------------------------
  # XDG Base Directory Specification Support
  #---------------------------------------------------------------------

  # Enable XDG environment variables (XDG_CONFIG_HOME, XDG_DATA_HOME, etc.)
  xdg.enable = true;

  xdg.configFile = {
    # GitHub CLI configuration - Git workflow and aliases
    "gh/config.yml".source = ./gh-config.yml;

    # Ghostty terminal configuration
    "ghostty/config".source = ./ghostty;
  };

  # Work configs (AWS SSO) managed by employer scripts - see README
  # Runtime configs (shell history, cloud SDK, etc.) auto-configure on first use

  # NOTE: PATH is now managed in config.fish like Mitchell's approach
  # nix-darwin handles Nix paths automatically, personal paths go in fish config

  #---------------------------------------------------------------------
  # Programs - Mitchell's hybrid approach
  #---------------------------------------------------------------------
  
  programs.git = {
    enable = true;

    settings = {
      # User configuration
      user = {
        name = "tengjizhang";
        email = "georgezhangtj97@gmail.com";
      };

      # Basic settings
      init.defaultBranch = "main";
      push.default = "simple";             # Keep your preference
      pull.rebase = false;
      branch.autosetuprebase = "always";   # Linear history from Mitchell
      color.ui = true;                     # Colorized output

      # Delta - minimal config with auto light/dark detection
      core.pager = "delta";
      interactive.diffFilter = "delta --color-only";
      delta = {
        detect-dark-light = "auto";  # automatically detect light/dark mode
        navigate = true;
      };

      # SSH signing with local key
      credential.helper = "osxkeychain";
      gpg = {
        format = "ssh";
        ssh.program = "ssh-keygen";
      };
      commit.gpgsign = true;
      merge.conflictstyle = "diff3";
    };

    # SSH signing with local key
    signing = {
      signByDefault = true;
      key = "~/.ssh/id_ed25519.pub";
    };
  };
  
  # Fish shell - Mitchell's pattern: simple aliases in Nix, complex config in Fish
  programs.fish = {
    enable = true;
    shellAliases = shellAliases;
    
    # The key Mitchell pattern: load our manual Fish config
    interactiveShellInit = builtins.readFile ./config.fish;
    
    # Fish plugins (Mitchell-style with explicit commits)
    plugins = [
      {
        name = "hydro";
        src = inputs.fish-hydro;
      }
      {
        name = "fzf.fish";
        src = pkgs.fishPlugins.fzf-fish.src;
      }
    ];
    
    # NOTE: No shellInit here - nix-darwin handles Nix daemon integration
  };
  
  # Mitchell's additional programs
  programs.atuin.enable = true;
  programs.nushell.enable = true;
  programs.jujutsu = {
    enable = true;
    settings = {
      user = {
        name = "tengjizhang";
        email = "georgezhangtj97@gmail.com";
      };
    };
  };
  
  # Neovim - using stable neovim from unstable channel
  # Why unstable instead of nightly: Switched from neovim-nightly-overlay (Oct 2025)
  # because nightly builds caused 2-3GB downloads and 30+ min build times when the
  # cache didn't have fresh builds yet. Unstable updates ~weekly and is always cached.
  # Trade-off: Lost bleeding-edge features, gained reliability and 100x faster updates.
  programs.neovim = {
    enable = true;
    package = pkgs.unstable.neovim-unwrapped;
  };
}
