# The shell both Macs share: fish (primary) and zsh, their aliases, and the
# tools config.fish calls, so a host that imports this needs nothing else
# for its shell to work.
{ pkgs, config, ... }:

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

  };
in {
  #---------------------------------------------------------------------
  # Fish shell - Primary shell
  #---------------------------------------------------------------------

  programs.fish = {
    enable = true;
    shellAliases = shellAliases;
    interactiveShellInit = builtins.readFile ./config.fish;
    plugins = [
      { name = "hydro"; src = pkgs.fishPlugins.hydro.src; }
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
    initContent = "";
  };

  # config.fish and the aliases above run these: the `ls`/`ll` aliases,
  # fzf.fish and its preview and diff commands.
  home.packages = with pkgs; [
    eza
    bat
    fzf
    fd
    delta
  ];
}
