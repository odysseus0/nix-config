{ inputs, pkgs, config, ... }:

let
  shellAliases = {
    # Git shortcuts
    ga = "git add";
    gc = "git commit";
    gco = "git checkout";
    gs = "git status";
    gp = "git push";
    gl = "git log --oneline -10";

    # Jujutsu shortcuts
    js = "jj st";
    jl = "jj log --limit 10";
    jd = "jj diff";

    # Modern CLI tools
    ls = "eza";
    ll = "eza -la";
    la = "eza -la";

    # Task management
    t = "task";

    # AI CLI tools
    ccc = "claude --dangerously-skip-permissions";
    cx = "codex --yolo --search";

  };
in {
  #---------------------------------------------------------------------
  # Fish shell - Primary shell
  #---------------------------------------------------------------------

  programs.fish = {
    enable = true;
    shellAliases = shellAliases;
    interactiveShellInit = builtins.readFile ../config.fish;
    plugins = [
      { name = "hydro"; src = inputs.fish-hydro; }
      { name = "fzf.fish"; src = pkgs.fishPlugins.fzf-fish.src; }
    ];
  };

  #---------------------------------------------------------------------
  # Zsh - Secondary shell (Claude Code, macOS compatibility)
  #---------------------------------------------------------------------

  programs.zsh = {
    enable = true;
    dotDir = "${config.xdg.configHome}/zsh";
    shellAliases = shellAliases;
  };
}
