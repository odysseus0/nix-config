{ pkgs, lib, ... }:

let
  isDarwin = pkgs.stdenv.isDarwin;

  # Declarative list of npm packages to install globally via bun
  # Auto-updated on every `make switch`
  npmGlobalPackages = [
    { pkg = "@anthropic-ai/claude-code"; bin = "claude"; }
    { pkg = "@openai/codex"; bin = "codex"; }
    { pkg = "@google/gemini-cli"; bin = "gemini"; }
    { pkg = "agent-browser"; bin = "agent-browser"; }
    { pkg = "@steipete/bird"; bin = "bird"; }
    { pkg = "@mariozechner/gccli"; bin = "gccli"; }
  ];

  npmInstallArgs = lib.concatStringsSep " " (map (p: p.pkg + "@latest") npmGlobalPackages);
in {
  # Auto-update AI CLI tools on every activation (make switch)
  home.activation.updateAiTools = lib.hm.dag.entryAfter ["writeBoundary"] ''
    echo "Updating AI CLI tools via bun..."
    ${pkgs.bun}/bin/bun install -g ${npmInstallArgs} 2>/dev/null || true
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
    bun         # fast JS runtime & bundler

    # AI CLI tools - installed globally via bun (see npmGlobalPackages list above)
    # Auto-updated on `make switch` via home.activation.updateAiTools
    # Binaries: ~/.bun/bin

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
