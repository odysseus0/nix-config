{ pkgs, lib, inputs, ... }:

# What every shell needs, store-owned: Nix builds and pins the exact binary,
# and a switch is the only way it changes. A tool belongs here only if you
# would use it in a directory with no project; a project's toolchain lives in
# that project's flake devShell (loaded by direnv), and a one-off is
# `nix run nixpkgs#<tool>`.
#
# The one other tier is vendor-owned: a tool whose own installer and updater
# own its install root (claude, amp, pi in ~/.local/bin). Nix only puts
# ~/.local/bin on PATH ahead of the Nix profile (environment.nix), so never
# install a vendor-owned tool here as well: one of the two copies would be
# silently shadowed.

let
  # llm-agents.nix's own packages output, built against its own nixpkgs pin
  # so cache.numtide.com serves it (see flake.nix on the llm-agents input).
  llmAgents = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};

  # Sherlog (`shlog`): full-text search over local agent session transcripts.
  # Runs George's fork until upstream merges the session-identity fixes
  # (catoncat/sherlog#124 and the Codex segment fix): built from
  # ~/src/github.com/odysseus0/sherlog (branch `local`) into
  # $XDG_DATA_HOME/sherlog/shlog. When a release carries both fixes, pin the
  # release archive instead.
  sherlog = pkgs.writeShellScriptBin "shlog" ''
    case "''${XDG_DATA_HOME:-}" in /*) data=$XDG_DATA_HOME ;; *) data=$HOME/.local/share ;; esac
    exec "$data/sherlog/shlog" "$@"
  '';

  # Dolt is the Beads server engine. Pinned to the upstream 2.2.0 release
  # archive: Beads documents 2.2.0 as the safe standalone-server release, and
  # 2.3.x has a hard-reset regression that can leave a multi-writer database
  # unable to settle a merge. A prebuilt archive, so nothing compiles.
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
in
{
  home.packages = with pkgs; [
    # Version control & GitHub
    git
    git-filter-repo  # history rewriting
    gh
    gh-dash          # TUI dashboard for PRs and issues
    lazygit          # TUI git client
    lefthook         # git hook runner (the vault's hooks)
    ghq              # clones to ~/src/<host>/<owner>/<repo> (programs.git ghq.root)

    # Modern CLI alternatives
    bat
    eza
    fd
    fzf
    gum              # TUI toolkit for shell scripts
    ripgrep
    tree
    btop
    jq
    delta

    # Secret management
    sops
    age
    ssh-to-age
    _1password-cli

    # Development utilities
    curl
    wget
    unzip
    fx               # JSON explorer
    pandoc
    typst
    just
    sd
    yq
    ffmpeg
    sox              # audio recording (Claude Code /voice)
    d2               # diagrams as code
    actionlint       # GitHub Actions workflow lint
    shellcheck       # used by actionlint for run blocks
    asciinema
    watch
    atuin

    # Data, notes, backups
    sqlite           # CLI with FTS5 (zk)
    zk               # Zettelkasten CLI
    sherlog
    tdl              # Telegram message export/sync
    taskwarrior3
    rclone
    dolt             # pinned server engine for the shared Beads authority
    restic           # snapshot backups to R2 (home-ops/backup)

    # Runtimes for scripts outside any project
    uv
    nodejs
    bun
  ]
  ++ (with llmAgents; [
    codex
    qmd
    beads            # mainProgram is `bd`
  ]);

  home.file = {
    # The path home-ops' runtime registry schedules.
    ".local/bin/nix-flake-bump".source = "${pkgs.callPackage ../../../pkgs/nix-flake-bump.nix { }}/bin/nix-flake-bump";
    # Shipped inside the herdr package so agents in a herdr pane can drive it.
    # The skill self-gates on HERDR_ENV=1, so it is inert everywhere else.
    ".agents/skills/herdr".source = "${pkgs.herdr}/share/herdr/skills/herdr";
  };
}
