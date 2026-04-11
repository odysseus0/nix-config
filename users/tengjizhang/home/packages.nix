{ pkgs, lib, inputs, ... }:

let
  isDarwin = pkgs.stdenv.isDarwin;
  pkgs-stable = inputs.nixpkgs-stable.legacyPackages.${pkgs.system};

  # DiscordChatExporter CLI — prebuilt binary (nixpkgs version is 2 years stale)
  discordchatexporter-cli = pkgs.stdenv.mkDerivation rec {
    pname = "discordchatexporter-cli";
    version = "2.47";
    src = pkgs.fetchzip {
      url = "https://github.com/Tyrrrz/DiscordChatExporter/releases/download/${version}/DiscordChatExporter.Cli.osx-arm64.zip";
      hash = "sha256-Lq/c7WTV8abxlxZ9LjK8dfN1fGGx8xkduuLBUoSKLSs=";
      stripRoot = false;
    };
    installPhase = ''
      mkdir -p $out/bin
      cp -r $src/* $out/bin/
      chmod +x $out/bin/DiscordChatExporter.Cli
    '';
    meta.mainProgram = "DiscordChatExporter.Cli";
  };


  # LLM/AI tools from numtide/llm-agents.nix (daily updates, binary cache)
  llmAgents = inputs.llm-agents.packages.${pkgs.system};

  # npm packages NOT covered by numtide - still use pnpm for these
  npmGlobalPackages = [
    { pkg = "@steipete/bird"; bin = "bird"; }
    { pkg = "@mariozechner/gccli"; bin = "gccli"; }
    { pkg = "agent-browser"; bin = "agent-browser"; }
    { pkg = "neonctl"; bin = "neonctl"; }
    { pkg = "@googleworkspace/cli"; bin = "gws"; }
    { pkg = "ghcrawl"; bin = "ghcrawl"; }
    { pkg = "@mariozechner/pi-coding-agent"; bin = "pi"; }
    { pkg = "@jackwener/opencli"; bin = "opencli"; }
    { pkg = "@opentabs-dev/cli"; bin = "opentabs"; }
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
    "gam7"         # Google Workspace admin CLI (GAM)
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
    (ast-grep.overrideAttrs { doCheck = false; })  # test_scan_invalid_rule_id fails in sandbox
    fx          # JSON explorer
    pandoc      # document converter
    typst       # modern typesetting system
    just        # command runner (Makefile alternative)
    sd          # modern sed replacement
    yq          # YAML processor
    clickhouse  # ClickHouse database client
    ffmpeg      # media processing
    sox         # audio recording/processing (used by Claude Code /voice)
    d2          # diagram-as-code tool
    actionlint  # GitHub Actions workflow lint
    shellcheck  # shell lint used by actionlint for run blocks

    # Discord archival
    discordchatexporter-cli

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
    # FIXME: gemini-cli 0.30.0 broken — node-pty fails to compile against Node.js 24
    # Upstream: numtide/llm-agents.nix. Re-enable when fixed.
    # llmAgents.gemini-cli     # Google Gemini CLI
    # agent-browser: removed from Nix — no binary cache, compiles Rust from source.
    # npm ships precompiled binaries. Installed via pnpm below instead.
    # llmAgents.agent-browser
    llmAgents.amp            # Sourcegraph's Amp coding agent CLI

    # Programming languages
    deno            # TypeScript/JavaScript runtime
    go              # Go programming language

    # Blockchain development tools
    foundry         # Foundry toolchain (forge, cast, anvil, chisel)

    # Infrastructure tools
    terraform       # Infrastructure as code
    pulumi          # Infrastructure as code (TypeScript)
    pulumiPackages.pulumi-nodejs  # Pulumi TypeScript/JS support
    flyctl          # Fly.io CLI
    # FIXME: mise depends on direnv — broken by Go 1.26 cgo bug (nixpkgs #503298)
    # mise            # Polyglot version manager (Ruby, Node, etc.)

    # Cloud CLIs (work requirements, Nix-managed)
    google-cloud-sdk  # Google Cloud Platform CLI
    awscli2          # AWS CLI (latest version)
    pkgs-stable._1password-cli  # Stable: unstable ships beta that breaks Pulumi 1Password provider
    cloudflared      # Cloudflare Tunnel client (local → public HTTPS via *.trycloudflare.com)
    wrangler         # Cloudflare Workers CLI (deploy serverless functions)

  ];
}
