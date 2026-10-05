# Config files the workstation's tools read.
{ config, pkgs, lib, ... }:

let
  # One gh-dash config in two Catppuccin flavors; the gh-dash function in
  # config.fish picks one by the macOS appearance at launch.
  ghDashBase = {
    prSections = [
      { title = "Needs My Review"; filters = "is:open review-requested:@me repo:argonavis-labs/orchestrator-electron"; }
      { title = "Team PRs"; filters = "is:open repo:argonavis-labs/orchestrator-electron"; }
      { title = "My PRs"; filters = "is:open author:odysseus0"; }
      { title = "OSS"; filters = "is:open involves:@me -org:argonavis-labs -org:flashbots"; }
    ];
    issuesSections = [
      { title = "Open Issues"; filters = "is:open repo:argonavis-labs/orchestrator-electron"; }
      { title = "Assigned to Me"; filters = "is:open assignee:@me repo:argonavis-labs/orchestrator-electron"; }
    ];
    notificationsSections = [
      { title = "All"; filters = ""; }
      { title = "Review Requested"; filters = "reason:review-requested"; }
      { title = "Mentioned"; filters = "reason:mention"; }
      { title = "Participating"; filters = "reason:participating"; }
    ];
    repoPaths = {
      "odysseus0/nix-config" = "~/nix-config";
    };
    keybindings = {
      universal = [{ key = "g"; name = "lazygit"; command = "cd {{.RepoPath}} && lazygit"; }];
      prs = [
        { key = "C"; name = "checkout"; command = "cd {{.RepoPath}} && gh pr checkout {{.PrNumber}}"; }
        { key = "M"; name = "merge (squash)"; command = "gh pr merge {{.PrNumber}} --repo {{.RepoName}} --squash --delete-branch"; }
        { key = "D"; name = "diff in delta"; command = "gh pr diff {{.PrNumber}} --repo {{.RepoName}} | delta"; }
        { key = "b"; name = "open in browser"; command = "gh pr view {{.PrNumber}} --repo {{.RepoName}} --web"; }
      ];
    };
    defaults = {
      preview = { open = true; width = 60; };
      prsLimit = 25;
      prApproveComment = "LGTM";
      issuesLimit = 20;
      notificationsLimit = 20;
      view = "prs";
      refetchIntervalMinutes = 5;
    };
    pager.diff = "delta";
    confirmQuit = false;
    showAuthorIcons = true;
    smartFilteringAtLaunch = false;
  };

  # Latte and Frappé, with the text colors raised for contrast.
  catppuccinLatte = {
    text = { primary = "#4c4f69"; secondary = "#5c5f77"; inverted = "#eff1f5"; faint = "#8c8fa1"; warning = "#df8e1d"; success = "#40a02b"; actor = "#6c6f85"; };
    background.selected = "#bcc0cc";
    border = { primary = "#8839ef"; secondary = "#acb0be"; faint = "#ccd0da"; };
  };

  catppuccinFrappe = {
    text = { primary = "#c6d0f5"; secondary = "#b5bfe2"; inverted = "#303446"; faint = "#838ba7"; warning = "#e5c890"; success = "#a6d189"; actor = "#a5adce"; };
    background.selected = "#626880";
    border = { primary = "#ca9ee6"; secondary = "#737994"; faint = "#51576d"; };
  };

  mkGhDashConfig = colors: ghDashBase // {
    theme = {
      ui = { sectionsShowCount = true; table = { showSeparator = true; compact = false; }; };
      colors = colors;
    };
  };

  toYAML = lib.generators.toYAML {};
in
{
  home.file = {
    ".ssh/.keep" = {
      text = "";
      executable = false;
    };
    ".taskrc".source = ../dotfiles/taskrc;
    ".fdignore".source = ../dotfiles/fdignore;
    ".rgignore".source = ../dotfiles/rgignore;
    ".gitignore".source = ../dotfiles/gitignore;
  };

  xdg.enable = true;
  xdg.configFile = {
    "gh/config.yml".source = ../dotfiles/gh-config.yml;
    "ghostty/config".source = ../dotfiles/ghostty;

    "gh-dash/config-light.yml".text = toYAML (mkGhDashConfig catppuccinLatte);
    "gh-dash/config-dark.yml".text = toYAML (mkGhDashConfig catppuccinFrappe);
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
