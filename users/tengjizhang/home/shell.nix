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

  };
in {
  #---------------------------------------------------------------------
  # Fish shell - Primary shell
  #---------------------------------------------------------------------

  programs.fish = {
    enable = true;
    shellAliases = shellAliases;
    interactiveShellInit = builtins.readFile ../config.fish;
    # Vite+ wrapper: `vp env use` prints shell code that sets VP_NODE_VERSION
    # in the calling shell, so it must be eval'd here rather than exec'd.
    functions.vp = ''
      if test (count $argv) -ge 2; and test "$argv[1]" = env; and test "$argv[2]" = use
          if contains -- -h $argv; or contains -- --help $argv
              command vp $argv; return
          end
          set -lx VP_ENV_USE_EVAL_ENABLE 1
          set -lx VP_SHELL fish
          set -l out (command vp $argv); or return $status
          eval (string join ';' $out)
      else
          command vp $argv
      end
    '';
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
}
