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
  };

  #---------------------------------------------------------------------
  # XDG Config Files
  #---------------------------------------------------------------------

  xdg.enable = true;
  xdg.configFile = {
    "gh/config.yml".source = ../gh-config.yml;
    "ghostty/config".source = ../ghostty;
  };
}
