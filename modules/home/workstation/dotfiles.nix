# Config files the workstation's tools read.
{ config, lib, ... }:

{
  home.file = {
    ".ssh/.keep" = {
      text = "";
      executable = false;
    };
    ".taskrc".source = ../dotfiles/taskrc;
    ".fdignore".source = ../dotfiles/fdignore;
    ".rgignore".source = ../dotfiles/rgignore;
  };

  xdg.enable = true;
  xdg.configFile = {
    "gh/config.yml".source = ../dotfiles/gh-config.yml;
    "ghostty/config".source = ../dotfiles/ghostty;
    # git's global excludes file when core.excludesFile is unset.
    "git/ignore".source = ../dotfiles/gitignore;
  }
  # Neovim's tree except init.lua (programs.nix), linked out of store into
  # the ~/home-ops working tree: lazy.nvim rewrites lazy-lock.json, and lua/
  # is edited and tried without a switch. It lives in home-ops because
  # lua/plugins/obsidian.lua carries private vault paths. The links need
  # ~/home-ops checked out; the flake input alone is not enough.
  // lib.genAttrs [
    "nvim/lua"
    "nvim/lazy-lock.json"
    "nvim/lazyvim.json"
    "nvim/stylua.toml"
    "nvim/.neoconf.json"
  ] (path: {
    source = config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/home-ops/${path}";
  });
}
