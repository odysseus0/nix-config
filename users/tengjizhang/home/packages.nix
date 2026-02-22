{ pkgs, lib, inputs, ... }:

let
  isDarwin = pkgs.stdenv.isDarwin;

  tg-history-dumper = pkgs.buildGoModule {
    pname = "tg_history_dumper";
    version = "unstable-2025-12-26";
    src = pkgs.fetchFromGitHub {
      owner = "3bl3gamer";
      repo = "tg_history_dumper";
      rev = "0058ab229043fc4af6b1859e0c367b9fd9b10d93";
      hash = "sha256-boTMFMpgi0zoTwEtoW8PJ00xr7PsTikpYFW+T5f43n0=";
    };
    vendorHash = "sha256-fge5KRYaxTSsj9QhqJ6ApvrLT5Bp0R1x1/6PmQyrEcA=";
    # Patch log files to use cwd instead of binary dir (binary is in read-only Nix store)
    postPatch = ''
      substituteInPlace main.go \
        --replace-fail \
          'executablePath, _ := os.Executable()
	executableDir := filepath.Dir(executablePath)' \
          'executableDir, _ := os.Getwd()'
    '';
  };

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

  # uv tool packages (Python CLIs with heavy/ML deps)
  uvToolPackages = [
    "mlx-whisper"  # Whisper transcription optimized for Apple Silicon
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

  # Install uv tool packages (Python CLIs with heavy/ML deps)
  home.activation.updateUvTools = lib.hm.dag.entryAfter ["writeBoundary"] ''
    echo "Updating uv tool packages..."
    ${lib.concatMapStringsSep "\n    " (pkg: ''${pkgs.uv}/bin/uv tool install ${pkg} --native-tls || echo "uv tool install ${pkg} failed, continuing..."'') uvToolPackages}
  '';

  home.packages = with pkgs; [
    # Version control & GitHub
    git
    git-filter-repo  # History rewriting (remove large files, etc.)
    gh
    gh-dash     # TUI dashboard for PRs and issues
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

    # Secret management
    sops
    age
    ssh-to-age

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
    llmAgents.openclaw       # WhatsApp/Telegram/Discord AI assistant (formerly clawdbot → moltbot)
    llmAgents.pi             # Minimal extensible coding agent (badlogic)
    llmAgents.amp            # Sourcegraph's Amp coding agent CLI

    # Programming languages
    deno            # TypeScript/JavaScript runtime
    go              # Go programming language

    # Blockchain development tools
    foundry         # Foundry toolchain (forge, cast, anvil, chisel)

    # Telegram history dumper
    tg-history-dumper

    # Infrastructure tools
    terraform       # Infrastructure as code

    # Cloud CLIs (work requirements, Nix-managed)
    google-cloud-sdk  # Google Cloud Platform CLI
    awscli2          # AWS CLI (latest version)
    _1password-cli

  ];

  # Pi source symlink for easy access to docs/examples
  home.file.".pi/pi-source".source = "${llmAgents.pi}/lib/node_modules/@mariozechner/pi-coding-agent";
}
