{ pkgs, lib, inputs, ... }:

let
  isDarwin = pkgs.stdenv.isDarwin;

  # LLM/AI tools from numtide/llm-agents.nix (daily updates, binary cache)
  llmAgents = inputs.llm-agents.packages.${pkgs.system};

  # npm packages NOT covered by numtide - still use pnpm for these
  npmGlobalPackages = [
    { pkg = "@steipete/bird"; bin = "bird"; }
    { pkg = "@mariozechner/gccli"; bin = "gccli"; }
  ];

  # Only append @latest if package doesn't already have a version specifier
  # Scoped packages start with @, so check for @ after first char
  hasVersion = pkg: let
    afterFirst = builtins.substring 1 (builtins.stringLength pkg) pkg;
  in lib.hasInfix "@" afterFirst;
  addLatest = pkg: if hasVersion pkg then pkg else pkg + "@latest";
  npmInstallArgs = lib.concatStringsSep " " (map (p: addLatest p.pkg) npmGlobalPackages);

  # pnpm global directory (relative to $HOME, expanded at runtime)
  pnpmSubdir = if isDarwin then "Library/pnpm" else ".local/share/pnpm";

  # Bun global packages (installed from git repos)
  bunGlobalPackages = [
    "https://github.com/tobi/qmd"  # Quick Markdown search for Obsidian
  ];

in {
  # Install remaining npm packages not in numtide (bird, gccli)
  home.activation.updateAiTools = lib.hm.dag.entryAfter ["writeBoundary"] ''
    echo "Updating remaining npm packages via pnpm (bird, gccli)..."
    export PNPM_HOME="$HOME/${pnpmSubdir}"
    export PATH="$PNPM_HOME:$PATH"
    mkdir -p "$PNPM_HOME"
    ${pkgs.pnpm}/bin/pnpm add -g ${npmInstallArgs} || echo "pnpm install failed, continuing..."
  '';

  # Install bun global packages (from git repos)
  home.activation.updateBunTools = lib.hm.dag.entryAfter ["writeBoundary"] ''
    echo "Updating bun global packages..."
    ${lib.concatMapStringsSep "\n    " (pkg: ''${pkgs.bun}/bin/bun install -g ${pkg} || echo "bun install ${pkg} failed, continuing..."'') bunGlobalPackages}
  '';

  home.packages = with pkgs; [
    # Version control & GitHub
    git
    gh
    lazygit     # TUI git client

    # Modern CLI alternatives
    bat
    eza
    fd
    fzf
    gum         # TUI toolkit for shell scripts (Charm)
    ripgrep
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
    typst       # modern typesetting system
    sd          # modern sed replacement
    yq          # YAML processor
    clickhouse  # ClickHouse database client
    ffmpeg      # media processing
    d2          # diagram-as-code tool

    # Additional tools
    taskwarrior3
    rclone
    uv          # pure Python projects
    pixi        # ML/heavy native deps (conda-forge)
    yt-dlp
    zellij

    # Essential development tools
    asciinema   # terminal recorder
    watch       # command repeater
    atuin       # shell history search

    # Node.js runtime (for editor integration)
    nodejs      # for editor integration and basic needs
    pnpm        # for remaining npm packages (bird, gccli)
    bun         # fast JS runtime & bundler

    # AI CLI tools from numtide/llm-agents.nix (daily updates, binary cache)
    llmAgents.claude-code    # Anthropic's Claude Code CLI
    llmAgents.codex          # OpenAI Codex CLI
    llmAgents.gemini-cli     # Google Gemini CLI
    llmAgents.agent-browser  # Browser automation
    llmAgents.moltbot        # WhatsApp/Telegram/Discord AI assistant (clawdbot → moltbot → openclaw)

    # Programming languages
    go              # Go programming language

    # Blockchain development tools
    foundry         # Foundry toolchain (forge, cast, anvil, chisel)

    # Infrastructure tools
    terraform       # Infrastructure as code

    # Cloud CLIs (work requirements, Nix-managed)
    google-cloud-sdk  # Google Cloud Platform CLI
    awscli2          # AWS CLI (latest version)
    _1password-cli
  ];
}
