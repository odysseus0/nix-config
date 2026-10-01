{ pkgs, lib, inputs, ... }:

# Ownership is binary, three tiers. Every package below sits in exactly one:
#
#   STORE-OWNED (default) — Nix builds and pins the exact binary; `make switch`
#     is the only way it changes. Preferred tier; opt out only for a stated
#     reason.
#   MANIFEST-OWNED — Nix declares desired state; the domain's native executor
#     reconciles it, always from an explicit clock, never from activation:
#     uv from `make update-tools`, Homebrew from `make brew-apply`
#     (manifest in ./brew.nix), executor from `make update-tools`
#     (home-ops module). No exceptions remain.
#   VENDOR-OWNED — the tool's own installer/updater owns its install root; Nix
#     only wires PATH. Short exception list, each entry justified inline.
#     PATH precedence is part of this contract: vendor bin dirs must not
#     shadow Nix-built binaries of the same name (see MIGRATION.md §stale
#     copies).
#
# This tiering is the point of this file: it replaces machine-topology
# thinking (what's on this Mac) with ownership thinking (who updates this and
# on whose clock). See ../../../README.md for the full argument.

let
  # neonctl (Neon Postgres CLI) — VENDOR-OWNED (runtime resolution). NOT in
  # nixpkgs (verified 2026-08-04: `nix search nixpkgs neonctl` empty), so the
  # plain-nixpkgs route isn't available. npx wrapper rather than pnpm-global
  # (pnpm is out of the package set): the Nix side pins only the wrapper;
  # npx resolves the pinned version from the registry at first run and serves
  # its cache after. Version pinned so the resolution is at least
  # reproducible; bump deliberately. Graduation trigger: neonctl lands in
  # nixpkgs or llm-agents.nix.
  neonctl = pkgs.writeShellScriptBin "neonctl" ''
    exec ${pkgs.nodejs}/bin/npx -y neonctl@2.43.0 "$@"
  '';

  # pi — VENDOR-OWNED (runtime resolution), NOT the llm-agents.nix `pi`.
  # pi migrated orgs: @mariozechner/pi-coding-agent froze at 0.73.1
  # (2026-05-07, dead) and development continues as
  # @earendil-works/pi-coding-agent (0.83.0 as of 2026-07-29, confirmed by
  # George 2026-08-04). llm-agents.nix still tracks the dead scope, so its
  # package is three months stale — repoint requested upstream. Graduation
  # trigger: llm-agents.nix (or nixpkgs) ships @earendil-works, then move pi
  # back to the store-owned list and delete this wrapper.
  pi = pkgs.writeShellScriptBin "pi" ''
    exec ${pkgs.nodejs}/bin/npx -y @earendil-works/pi-coding-agent@0.83.0 "$@"
  '';

  # Store-owned AI agent CLIs. Consumed via llm-agents.nix's own
  # `packages.<system>` output rather than its overlay — see flake.nix's
  # comment on `inputs.llm-agents` for why (nixpkgs version skew breaks the
  # overlay path; this path builds against their pin and hits their cache).
  llmAgents = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};

  # ---------------------------------------------------------------------
  # STORE-OWNED: in-tree derivations
  # ---------------------------------------------------------------------
  # House pattern for tools with no upstream Nix packaging: pin a fetched
  # artifact/wheel/tarball, build with a plain derivation, done. No activation
  # script, no vendor updater — `make update` + a hash bump is the only way
  # these change.

  # Sherlog (`shlog`) — full-text search over local agent session transcripts
  # (Claude Code / Codex / pi JSONL) into a local SQLite FTS index.
  #
  # Runs George's fork until upstream merges the session-identity fixes
  # (catoncat/sherlog#124 and the Codex segment fix): source in
  # ~/projects/sherlog on branch `local`, built with `cargo build --release` and
  # installed at $XDG_DATA_HOME/sherlog/shlog. Same shape as bird. When a
  # release carries both fixes, return to the pinned release archive.
  sherlog = pkgs.writeShellScriptBin "shlog" ''
    case "''${XDG_DATA_HOME:-}" in /*) data=$XDG_DATA_HOME ;; *) data=$HOME/.local/share ;; esac
    exec "$data/sherlog/shlog" "$@"
  '';

  # Dolt is the Beads server engine. Pin the upstream 2.2.0 release rather
  # than nixpkgs' rolling package: Beads documents this exact release as the
  # safe standalone-server version; 2.3.x has a hard-reset regression that
  # can leave a multi-writer database unable to settle a merge.
  #
  # This is an upstream prebuilt archive, so it remains store-owned without
  # compiling Dolt's Go/Rust dependency graph. Hash verified locally against
  # the downloaded v2.2.0 aarch64-darwin archive on 2026-08-31.
  dolt =
    let
      version = "2.2.0";
      targets = {
        aarch64-darwin = {
          asset = "dolt-darwin-arm64";
          hash = "sha256-xnN9wsWAbi7u9IOa12woFnyGH4eK8wcd8SQqZYnYEmc=";
        };
      };
      system = pkgs.stdenv.hostPlatform.system;
      target = targets.${system} or (throw "dolt: no pinned release archive for ${system}");
    in
    pkgs.stdenvNoCC.mkDerivation {
      pname = "dolt";
      inherit version;

      src = pkgs.fetchurl {
        url = "https://github.com/dolthub/dolt/releases/download/v${version}/${target.asset}.tar.gz";
        inherit (target) hash;
      };

      installPhase = ''
        runHook preInstall
        install -Dm755 bin/dolt $out/bin/dolt
        install -Dm644 LICENSES $out/share/licenses/dolt/LICENSES
        runHook postInstall
      '';

      meta = {
        description = "Version-controlled SQL database for the shared Beads server";
        homepage = "https://www.dolthub.com/";
        license = lib.licenses.asl20;
        mainProgram = "dolt";
        platforms = lib.attrNames targets;
      };
    };

  # MANIFEST-OWNED (uv): the manifest is ./uv-tools-manifest.nix; the
  # executor is pkgs.uv-tools-reconcile (flake.nix overlay ->
  # lib/uv-tools-reconcile.nix), added to home.packages below and run only
  # from `make update-tools`, never from activation.

in {
  # VENDOR-OWNED exceptions deliberately absent from this list (own
  # installer/updater owns the install root; Nix wires PATH only, in
  # home/environment.nix): Vite+ (graduation triggers there). grok was
  # dropped 2026-08-04 (George: unused) — ~/.grok deleted.
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
    lefthook    # git hook runner (the vault's hooks)
    ghq         # clones to ~/src/<host>/<owner>/<repo> (programs.git ghq.root)
    pnpm        # tj-zhang-web; switches to each project's pinned packageManager version

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
    ffmpeg      # media processing
    sox         # audio recording/processing (used by Claude Code /voice)
    d2          # diagram-as-code tool
    actionlint  # GitHub Actions workflow lint
    shellcheck  # shell lint used by actionlint for run blocks


    # Additional tools (sqlite/zk/tdl/mas moved from Homebrew 2026-08-05 —
    # they were brew-by-accident; Homebrew's jurisdiction is casks + MAS)
    sqlite      # CLI with FTS5 etc. (zk)
    zk          # Zettelkasten CLI - backlinks, orphans, link analysis
    sherlog     # `shlog` - search past agent session transcripts (fork wrapper above)
    tdl         # Telegram message export/sync (was brew telegram-downloader)
    mas         # Mac App Store CLI (brew bundle shells out to it for masApps)
    taskwarrior3
    rclone
    dolt         # pinned server engine for the shared Beads authority
    restic       # snapshot backups to R2 (home-ops/backup)
    uv          # pure Python projects; also runs uv-tools-reconcile above
    pixi        # ML/heavy native deps (conda-forge)
    yt-dlp
    # herdr is NOT here — programs.herdr in programs.nix owns both the package
    # and config.toml.

    # Unfree; allowed via nixpkgs.config.allowUnfree in lib/mksystem.nix +
    # machines/macbook-m4-max.nix.
    _1password-cli

    # Essential development tools
    asciinema   # terminal recorder
    watch       # command repeater
    atuin       # shell history search

    # Node.js runtime (for editor integration / anything still npm-shaped)
    nodejs      # includes npm
    bun         # fast JS runtime & bundler

    # VENDOR-OWNED (see bindings above; runtime npm resolution, pinned)
    neonctl
    pi

    # Programming languages
    deno            # TypeScript/JavaScript runtime
    go              # Go programming language

    # -------------------------------------------------------------------
    # Project-scope demotion candidates — pending George's veto
    # -------------------------------------------------------------------
    # These are machine-wide store-owned packages today but conceptually
    # belong to specific projects, not the whole environment. Target: move
    # each to a per-project devShell (flake.nix + .envrc) picked up by
    # nix-direnv (enabled in programs.nix) instead of living here forever.
    # Left in place until George confirms which projects still need them
    # globally vs. per-shell.
    terraform       # Infrastructure as code
    pulumi          # Infrastructure as code (TypeScript)
    pulumiPackages.pulumi-nodejs  # Pulumi TypeScript/JS support
    flyctl          # Fly.io CLI
    google-cloud-sdk  # Google Cloud Platform CLI
    awscli2          # AWS CLI (latest version)
    cloudflared      # Cloudflare Tunnel client (local → public HTTPS via *.trycloudflare.com)
    wrangler         # Cloudflare Workers CLI (deploy serverless functions)
  ]
  ++ (with llmAgents; [
    # -------------------------------------------------------------------
    # STORE-OWNED: AI coding agent CLIs (github:numtide/llm-agents.nix)
    # -------------------------------------------------------------------
    # Daily-built, cached at cache.numtide.com (wired in
    # machines/macbook-m4-max.nix) since these build against llm-agents.nix's
    # own nixpkgs pin — see the `llmAgents` binding above for why. This is
    # the default tier for agent CLIs now — reach for a manifest- or
    # vendor-owned exception (below) only when a tool genuinely isn't
    # packaged here or its update model requires it.
    # claude-code deliberately absent — VENDOR-OWNED as of 2026-08-17. It ships
    # multiple times a week, and the store-owned path stacks two clocks against
    # that (llm-agents.nix must build it, then this flake must bump to their
    # build), so the pin is structurally days stale — 2.1.229 here vs 2.1.234
    # published. Pinning buys reproducibility, and nothing builds against
    # `claude`: it is an interactive tool whose version affects only the
    # session in front of you. Native install owns ~/.local/share/claude and
    # self-updates on the `latest` channel; `claude install <version>` is the
    # rollback. PATH wiring is already correct (~/.local/bin precedes
    # ~/.nix-profile/bin in home/environment.nix), and removing this entry is
    # what makes that unambiguous — with both installed the Nix binary is
    # silently shadowed (MIGRATION.md §stale copies).
    # Note the Nix wrapper was also the only thing setting DISABLE_AUTOUPDATER=1
    # and DISABLE_INSTALLATION_CHECKS=1; dropping it re-enables self-update with
    # no config edit.
    # Graduation trigger: none expected — this tier IS the right answer for a
    # daily-shipping vendor CLI. Revisit only if something starts building
    # against a pinned claude version.
    codex
    # amp deliberately absent — VENDOR-OWNED as of 2026-09-23. Same story as
    # claude-code: Amp ships a self-updating single-file binary via
    # `curl -fsSL https://ampcode.com/install.sh | bash` into ~/.amp/bin with
    # a symlink at ~/.local/bin/amp. The llm-agents.nix npm pin was weeks stale
    # (0.0.1788307300 vs latest) and silently won PATH over the vendor install.
    # `amp update` is the upgrade path; reinstall script is the rollback.
    # Graduation trigger: none expected for a daily-shipping vendor CLI.
    # pi deliberately absent: llm-agents' pi tracks the dead @mariozechner
    # scope — see the vendor-owned `pi` wrapper above for the story.
    qmd
    beads         # mainProgram is `bd`
  ])
  ++ [
    # -------------------------------------------------------------------
    # MANIFEST-OWNED: uv reconciler executable (defined via overlay, see
    # flake.nix + lib/uv-tools-reconcile.nix; manifest above)
    # -------------------------------------------------------------------
    pkgs.uv-tools-reconcile  # run via `make update-tools`, never activation
  ];

  home.file = {
    # Shipped inside the herdr package; wired here so agents running in a herdr
    # pane can actually drive it. The skill self-gates on HERDR_ENV=1, so it
    # stays inert everywhere else.
    ".agents/skills/herdr".source = "${pkgs.herdr}/share/herdr/skills/herdr";
  };
}
