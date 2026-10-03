# The shell both Macs share: fish (primary) and zsh, their aliases, and the
# tools config.fish calls, so a host that imports this needs nothing else
# for its shell to work.
{ pkgs, config, ... }:

let
  shellAliases = {
    ga = "git add";
    gc = "git commit";
    gco = "git checkout";
    gs = "git status";
    gp = "git push";
    gl = "git log --oneline -10";

    js = "jj st";
    jl = "jj log --limit 10";
    jd = "jj diff";

    ls = "eza";
    ll = "eza -la";
    la = "eza -la";

    t = "task";
  };
in {
  # The login shell (modules/darwin/account.nix).
  programs.fish = {
    enable = true;
    shellAliases = shellAliases;
    interactiveShellInit = builtins.readFile ./config.fish;
    plugins = [
      { name = "hydro"; src = pkgs.fishPlugins.hydro.src; }
      { name = "fzf.fish"; src = pkgs.fishPlugins.fzf-fish.src; }
    ];
  };

  # For programs that run commands through zsh, such as Claude Code.
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
