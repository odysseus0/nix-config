{ inputs, pkgs, ... }:

let
  shellAliases = {
    # Git shortcuts
    ga = "git add";
    gc = "git commit";
    gco = "git checkout";
    gs = "git status";
    gp = "git push";
    gl = "git log --oneline -10";

    # Modern CLI tools
    ls = "eza";
    ll = "eza -la";
    la = "eza -la";

    # Task management
    t = "task";
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
}
