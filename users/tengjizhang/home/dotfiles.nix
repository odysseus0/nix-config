{ ... }:

{
  #---------------------------------------------------------------------
  # Home directory dotfiles
  #---------------------------------------------------------------------

  home.file = {
    # SSH directory setup
    ".ssh/.keep" = {
      text = "";
      executable = false;
    };

    # Tier 1 dotfiles - simple, high-impact configurations
    ".taskrc".source = ../taskrc;
    ".fdignore".source = ../fdignore;
    ".rgignore".source = ../rgignore;
    ".gitignore".source = ../gitignore;  # Global gitignore
    ".tmux.conf".source = ../tmux.conf;  # iOS-optimized (see comments in file)
  };

  #---------------------------------------------------------------------
  # XDG Config Files
  #---------------------------------------------------------------------

  xdg.enable = true;
  xdg.configFile = {
    "gh/config.yml".source = ../gh-config.yml;
    "ghostty/config".source = ../ghostty;

    # pnpm config - allow build scripts only for specific packages
    # These are native modules needed for AI CLI tools functionality
    "pnpm/rc".text = ''
      onlyBuiltDependencies[]=agent-browser
      onlyBuiltDependencies[]=clawdbot
      onlyBuiltDependencies[]=keytar
      onlyBuiltDependencies[]=node-pty
      onlyBuiltDependencies[]=protobufjs
      onlyBuiltDependencies[]=sharp
      onlyBuiltDependencies[]=tree-sitter-bash
    '';
  };
}
