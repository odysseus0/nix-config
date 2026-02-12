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

    # RSS — CLI wrapper for Miniflux API (runs via Docker at localhost:8070)
    (writeShellScriptBin "rss" ''
      set -euo pipefail
      MINIFLUX_URL="''${MINIFLUX_URL:-http://localhost:8070}"
      MINIFLUX_USER="''${MINIFLUX_USER:-admin}"
      MINIFLUX_PASS="''${MINIFLUX_PASS:-miniflux}"
      AUTH="-u $MINIFLUX_USER:$MINIFLUX_PASS"

      api() { ${curl}/bin/curl -s $AUTH "$MINIFLUX_URL/v1/$1" "''${@:2}"; }

      case "''${1:-help}" in
        unread)
          # List unread entries (default 50, override with rss unread 100)
          LIMIT="''${2:-50}"
          api "entries?status=unread&limit=$LIMIT&direction=desc&order=published_at" \
            | ${jq}/bin/jq -r '.entries[] | "\(.id)\t\(.feed.title)\t\(.title)\t\(.published_at[:10])"' \
            | column -t -s$'\t'
          ;;
        read)
          # Get full content of an entry: rss read <id>
          [ -z "''${2:-}" ] && echo "Usage: rss read <entry_id>" && exit 1
          api "entries/$2" | ${jq}/bin/jq -r '
            "# \(.title)\n\(.feed.title) — \(.published_at[:10])\n\(.url)\n\n\(.content)"
          ' | ${pandoc}/bin/pandoc -f html -t plain --wrap=auto --columns=80
          ;;
        mark-read)
          # Mark entry as read: rss mark-read <id>
          [ -z "''${2:-}" ] && echo "Usage: rss mark-read <entry_id>" && exit 1
          api "entries" -X PUT -H "Content-Type: application/json" \
            -d "{\"entry_ids\":[$2],\"status\":\"read\"}"
          echo "Marked $2 as read"
          ;;
        star)
          # Toggle star on entry: rss star <id>
          [ -z "''${2:-}" ] && echo "Usage: rss star <entry_id>" && exit 1
          api "entries/$2/bookmark" -X PUT
          echo "Toggled star on $2"
          ;;
        feeds)
          # List all feeds with unread counts
          api "feeds" | ${jq}/bin/jq -r 'sort_by(.title) | .[]
            | select(.parsing_error_count == 0)
            | "\(.id)\t\(.title)\t\(.category.title)"' \
            | column -t -s$'\t'
          ;;
        add)
          # Add a feed: rss add <url>
          [ -z "''${2:-}" ] && echo "Usage: rss add <feed_url>" && exit 1
          api "feeds" -X POST -H "Content-Type: application/json" \
            -d "{\"feed_url\":\"$2\",\"category_id\":1}" \
            | ${jq}/bin/jq -r '"Added feed ID: \(.feed_id)"'
          ;;
        refresh)
          # Refresh all feeds
          api "feeds/refresh" -X PUT
          echo "Refresh triggered"
          ;;
        search)
          # Search entries: rss search <query>
          [ -z "''${2:-}" ] && echo "Usage: rss search <query>" && exit 1
          QUERY=$(printf '%s' "$2" | ${jq}/bin/jq -sRr @uri)
          api "entries?search=$QUERY&limit=20" \
            | ${jq}/bin/jq -r '.entries[] | "\(.id)\t\(.feed.title)\t\(.title)\t\(.status)"' \
            | column -t -s$'\t'
          ;;
        json)
          # Raw JSON for an entry: rss json <id> (pipe to jq, fx, etc.)
          [ -z "''${2:-}" ] && echo "Usage: rss json <entry_id>" && exit 1
          api "entries/$2"
          ;;
        stats)
          # Show counts
          UNREAD=$(api "entries?status=unread&limit=1" | ${jq}/bin/jq '.total')
          READ=$(api "entries?status=read&limit=1" | ${jq}/bin/jq '.total')
          FEEDS=$(api "feeds" | ${jq}/bin/jq 'length')
          echo "Feeds: $FEEDS | Unread: $UNREAD | Read: $READ"
          ;;
        up)
          cd "$HOME/services/miniflux" && docker compose up -d
          ;;
        down)
          cd "$HOME/services/miniflux" && docker compose down
          ;;
        *)
          echo "rss — Miniflux CLI"
          echo ""
          echo "  unread [n]       List unread entries (default 50)"
          echo "  read <id>        Read entry as plain text"
          echo "  mark-read <id>   Mark entry as read"
          echo "  star <id>        Toggle star"
          echo "  feeds            List all feeds"
          echo "  add <url>        Add a feed"
          echo "  refresh          Refresh all feeds"
          echo "  search <query>   Search entries"
          echo "  json <id>        Raw JSON for an entry"
          echo "  stats            Show counts"
          echo "  up / down        Start/stop miniflux"
          ;;
      esac
    '')
  ];

  # Pi source symlink for easy access to docs/examples
  home.file.".pi/pi-source".source = "${llmAgents.pi}/lib/node_modules/@mariozechner/pi-coding-agent";
}
