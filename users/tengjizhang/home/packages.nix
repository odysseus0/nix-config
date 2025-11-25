{ pkgs, lib, ... }:

let
  isDarwin = pkgs.stdenv.isDarwin;
in {
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
    sd          # modern sed replacement
    yq          # YAML processor
    clickhouse  # ClickHouse database client

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
    pnpm        # for accessing latest npm packages efficiently

    # AI CLI tools (latest via npm)
    (writeShellScriptBin "codex" ''
      exec ${pnpm}/bin/pnpm dlx @openai/codex@latest "$@"
    '')
    (writeShellScriptBin "claude" ''
      exec ${pnpm}/bin/pnpm dlx @anthropic-ai/claude-code@latest "$@"
    '')

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
