# The workstation's CLI tools that Nix owns (README §One owner per tool): a
# switch is the only way one changes. A tool belongs here only if it is used
# in a directory with no project; a project's toolchain lives in that
# project's flake devShell, and a one-off is `nix run nixpkgs#<tool>`. Never
# add a tool the vendor installs in ~/.local/bin: that copy would shadow
# this one.
{ pkgs, inputs, ... }:

let
  # llm-agents.nix's own packages output, built against its own nixpkgs pin
  # so cache.numtide.com serves it (see flake.nix on the llm-agents input).
  llmAgents = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
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

    # CLI tools (eza, bat, fzf, fd and delta come with core.nix)
    gum              # TUI toolkit for shell scripts
    ripgrep
    tree
    btop
    jq

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
    restic           # snapshot backups to R2 (home-ops/backup)

    # The shared board's client. Every Beads client builds bd from pkgs/,
    # so they move together: a newer bd migrates the shared schema and
    # older clients then refuse the database.
    beads            # mainProgram is `bd`

    # Runtimes for scripts outside any project
    uv
    nodejs
    bun
  ]
  ++ (with llmAgents; [
    codex
    qmd
  ]);

  home.file = {
    # The path home-ops' runtime registry schedules.
    ".local/bin/nix-flake-bump".source = "${pkgs.nix-flake-bump}/bin/nix-flake-bump";
    # Shipped inside the herdr package so agents in a herdr pane can drive it.
    # The skill self-gates on HERDR_ENV=1, so it is inert everywhere else.
    ".agents/skills/herdr".source = "${pkgs.herdr}/share/herdr/skills/herdr";
  };
}
