{ pkgs, lib, inputs, ... }:

# Ownership is binary, three tiers. Every package below sits in exactly one:
#
#   STORE-OWNED (default) — Nix builds and pins the exact binary; `make switch`
#     is the only way it changes. Preferred tier; opt out only for a stated
#     reason.
#   MANIFEST-OWNED — Nix declares desired state; the domain's native executor
#     (uv, Homebrew) reconciles it. Runs from `make update-tools`, never from
#     activation — see uv-tools-reconcile below.
#   VENDOR-OWNED — the tool's own installer/updater owns its install root; Nix
#     only wires PATH. Short exception list, each entry justified inline.
#
# This tiering is the point of this file: it replaces machine-topology
# thinking (what's on this Mac) with ownership thinking (who updates this and
# on whose clock). See ../../../README.md for the full argument.

let
  # neonctl (Neon Postgres CLI) is NOT in nixpkgs — verified 2026-08-04
  # (`nix search nixpkgs neonctl` empty), so "plain nixpkgs home.packages
  # entry" isn't available as stated. Wrapped via npx instead of reintroducing
  # pnpm (which this restructure removes entirely): not truly pinned/
  # store-owned in the strict sense, but it's the documented house pattern
  # for a fast-moving npm CLI with no Nix packaging (see nix-config skill,
  # "npm Package Pattern"). Revisit if neonctl lands in nixpkgs or
  # llm-agents.nix.
  neonctl = pkgs.writeShellScriptBin "neonctl" ''
    exec ${pkgs.nodejs}/bin/npx -y neonctl@latest "$@"
  '';

  # Store-owned AI agent CLIs. Consumed via llm-agents.nix's own
  # `packages.<system>` output rather than its overlay — see flake.nix's
  # comment on `inputs.llm-agents` for why (nixpkgs version skew breaks the
  # overlay path; this path builds against their pin and hits their cache).
  llmAgents = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};

  # NOT inputs.nixpkgs-stable.legacyPackages.${system} — that flake output is
  # pre-instantiated with the default nixpkgs config (allowUnfree = false)
  # regardless of this system's `nixpkgs.config.allowUnfree = true` module
  # option (machines/macbook-m4-max.nix + lib/mksystem.nix), since it never
  # goes through the module system. That mismatch was the one thing forcing
  # `--impure`/`NIXPKGS_ALLOW_UNFREE=1` on every build (2026-07-20 audit F5:
  # _1password-cli below is unfree and comes from pkgs-stable) — re-importing
  # explicitly with the same allowUnfree here makes evaluation pure again.
  pkgs-stable = import inputs.nixpkgs-stable {
    system = pkgs.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };

  # ---------------------------------------------------------------------
  # STORE-OWNED: in-tree derivations
  # ---------------------------------------------------------------------
  # House pattern for tools with no upstream Nix packaging: pin a fetched
  # artifact/wheel/tarball, build with a plain derivation, done. No activation
  # script, no vendor updater — `make update` + a hash bump is the only way
  # these change.

  # Paperclip — biomedical paper search CLI + Python SDK.
  # Wheel served from upstream (no PyPI).
  #
  # Upstream ships a self-update mechanism (cli/updater.py), but it's gated on
  # is_managed_install() — only fires when the package lives in ~/.paperclip/lib.
  # Under Nix the package lives in /nix/store, so auto-update silently no-ops.
  # No env var needed to disable it; the Nix install path is the disable.
  #
  # Bump recipe:
  #   curl -fsSL https://paperclip.gxl.ai/paperclip.whl -o /tmp/paperclip.whl
  #   unzip -p /tmp/paperclip.whl '*.dist-info/METADATA' | grep -E '^(Version|Requires-Dist):'
  #   nix hash file --sri /tmp/paperclip.whl
  paperclipPkg = pkgs.python3.pkgs.buildPythonPackage rec {
    pname = "gxl-paperclip";
    version = "0.3.0";
    format = "wheel";  # prebuilt wheel — no pyproject hooks needed
    src = pkgs.fetchurl {
      url = "https://paperclip.gxl.ai/paperclip.whl";
      # Rename so pip/nixpkgs wheel handler sees a canonical wheel filename.
      name = "gxl_paperclip-${version}-py3-none-any.whl";
      hash = "sha256-qr0CMs6D07/mg68wgdDTc3moT3xXDfV1ao9MJT0B9rk=";
    };
    dependencies = with pkgs.python3.pkgs; [ click requests ];
    doCheck = false;
  };
  paperclip = pkgs.python3.pkgs.toPythonApplication paperclipPkg;
  # Python interpreter with the gxl_paperclip SDK importable. Use:
  #   paperclip-python -c 'from gxl_paperclip import client; ...'
  paperclipPython =
    let env = pkgs.python3.withPackages (_: [ paperclipPkg ]);
    in pkgs.writeShellScriptBin "paperclip-python" ''
      exec ${env}/bin/python "$@"
    '';

  # Plannotator — browser-based review/annotation UI for generated specs and diffs.
  #
  # Upstream's installer also mutates agent hook state. Keep that out of
  # activation: Nix owns the CLI and user-invoked shared skills; Codex Stop
  # hooks remain opt-in/manual.
  plannotatorVersion = "0.22.0";
  plannotatorSrc = pkgs.fetchFromGitHub {
    owner = "backnotprop";
    repo = "plannotator";
    rev = "v${plannotatorVersion}";
    hash = "sha256-CbKxru0bNgCvkoQr973GnNWvcspar2MkNG4AsJBEYUk=";
  };
  plannotator = pkgs.stdenvNoCC.mkDerivation {
    pname = "plannotator";
    version = plannotatorVersion;
    src = pkgs.fetchurl {
      url = "https://github.com/backnotprop/plannotator/releases/download/v${plannotatorVersion}/plannotator-darwin-arm64";
      hash = "sha256-e6utZ5avj36jGYvZYzqm8szmq5fF7GjC/eDnTkwqBlI=";
    };
    dontUnpack = true;
    installPhase = ''
      mkdir -p "$out/bin"
      cp "$src" "$out/bin/plannotator"
      chmod +x "$out/bin/plannotator"
    '';
    meta.mainProgram = "plannotator";
  };

  # ---------------------------------------------------------------------
  # MANIFEST-OWNED: uv tool reconciler
  # ---------------------------------------------------------------------
  # The manifest (single source of truth) lives in ./uv-tools-manifest.nix so
  # the flake-level overlay (flake.nix -> lib/uv-tools-reconcile.nix) can read
  # the same list without importing this whole module. The executor itself is
  # pkgs.uv-tools-reconcile (from that overlay), added to home.packages below
  # — Nix declares the manifest, uv reconciles reality to it, and it only
  # ever runs from `make update-tools`, never from activation.
  uvToolPackages = import ./uv-tools-manifest.nix;

in {
  # ---------------------------------------------------------------------
  # VENDOR-OWNED activation: local cleanup only, never network
  # ---------------------------------------------------------------------
  # Remove the installer-managed binary so the Nix profile is the command
  # authority. The shared skills stay declarative below. This is local
  # (rm, not curl) so it's safe inside the activation phase, which must stay
  # offline — see README §The two clocks.
  home.activation.removeInstallerPlannotatorCli = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [ -e "$HOME/.local/bin/plannotator" ]; then
      echo "Removing installer-managed Plannotator CLI; Nix profile owns plannotator."
      rm -f "$HOME/.local/bin/plannotator"
    fi
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
    ffmpeg      # media processing
    sox         # audio recording/processing (used by Claude Code /voice)
    d2          # diagram-as-code tool
    actionlint  # GitHub Actions workflow lint
    shellcheck  # shell lint used by actionlint for run blocks

    # Review / annotation tooling
    plannotator

    # Biomedical / arxiv paper search (CLI + Python SDK wrapper)
    paperclip
    paperclipPython

    # Additional tools
    taskwarrior3
    rclone
    uv          # pure Python projects; also runs uv-tools-reconcile above
    pixi        # ML/heavy native deps (conda-forge)
    yt-dlp
    zellij

    # Essential development tools
    asciinema   # terminal recorder
    watch       # command repeater
    atuin       # shell history search

    # Node.js runtime (for editor integration / anything still npm-shaped)
    nodejs      # includes npm
    bun         # fast JS runtime & bundler

    # neonctl: was pnpm-global; see `neonctl` binding above for why this is
    # an npx wrapper rather than a plain nixpkgs entry.
    neonctl

    # grok (xAI Grok CLI) — VENDOR-OWNED, deliberately absent from this list.
    # llm-agents.nix doesn't package it; it stays under ~/.grok via its own
    # installer/updater, symlinked into ~/.local/bin (already on PATH via
    # home/environment.nix). Graduates to store-owned if/when numtide picks
    # it up. Flagged for George: confirm this is still in active use before
    # carrying the exception forward — unverified as of this restructure.

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
  ++ (with pkgs-stable; [
    _1password-cli  # Stable: unstable ships beta that breaks Pulumi 1Password provider
  ])
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
    claude-code   # was ~/.local/bin/claude, self-updated via `claude update`
    codex         # was npm-global @openai/codex
    amp           # was ~/.amp vendor installer
    pi            # was pnpm-global @mariozechner/pi-coding-agent
    agent-browser # was pnpm-global agent-browser
    qmd           # was bun-installed from git
    beads         # was Homebrew `beads` (darwin.nix) — mainProgram is `bd`
  ])
  ++ [
    # -------------------------------------------------------------------
    # MANIFEST-OWNED: uv reconciler executable (defined via overlay, see
    # flake.nix + lib/uv-tools-reconcile.nix; manifest above)
    # -------------------------------------------------------------------
    pkgs.uv-tools-reconcile  # run via `make update-tools`, never activation
  ];

  home.file = {
    ".agents/skills/plannotator-annotate".source = "${plannotatorSrc}/apps/skills/core/plannotator-annotate";
    ".agents/skills/plannotator-last".source = "${plannotatorSrc}/apps/skills/core/plannotator-last";
    ".agents/skills/plannotator-review".source = "${plannotatorSrc}/apps/skills/core/plannotator-review";
  };
}
