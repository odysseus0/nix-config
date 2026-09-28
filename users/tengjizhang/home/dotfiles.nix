{ config, pkgs, lib, ... }:

let
  # gh-dash base config (theme-agnostic)
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

  # Catppuccin Latte (light) - adjusted for better contrast
  catppuccinLatte = {
    text = { primary = "#4c4f69"; secondary = "#5c5f77"; inverted = "#eff1f5"; faint = "#8c8fa1"; warning = "#df8e1d"; success = "#40a02b"; actor = "#6c6f85"; };
    background.selected = "#bcc0cc";
    border = { primary = "#8839ef"; secondary = "#acb0be"; faint = "#ccd0da"; };
  };

  # Catppuccin Frappé (dark) - adjusted for better contrast
  catppuccinFrappe = {
    text = { primary = "#c6d0f5"; secondary = "#b5bfe2"; inverted = "#303446"; faint = "#838ba7"; warning = "#e5c890"; success = "#a6d189"; actor = "#a5adce"; };
    background.selected = "#626880";
    border = { primary = "#ca9ee6"; secondary = "#737994"; faint = "#51576d"; };
  };

  # Generate full config with theme
  mkGhDashConfig = colors: ghDashBase // {
    theme = {
      ui = { sectionsShowCount = true; table = { showSeparator = true; compact = false; }; };
      colors = colors;
    };
  };

  toYAML = lib.generators.toYAML {};
  homebrewTrust = builtins.toJSON {
    trustedformulae = [
      "openclaw/tap/gogcli"
    ];
    trustedcasks = [
      "mrkai77/cask/loop"
    ];
  };
in
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

    # sudo darwin-rebuild does not preserve XDG_CONFIG_HOME, so Homebrew falls
    # back to ~/.homebrew/trust.json during activation.
    ".homebrew/trust.json".text = homebrewTrust;

  };

  #---------------------------------------------------------------------
  # XDG Config Files
  #---------------------------------------------------------------------

  xdg.enable = true;
  xdg.configFile = {
    "gh/config.yml".source = ../gh-config.yml;
    "ghostty/config".source = ../ghostty;

    # pnpm config removed 2026-08-04 with the pnpm tier (agent CLIs are
    # store-owned via llm-agents.nix now).

    # Homebrew tap trust is required by HOMEBREW_REQUIRE_TAP_TRUST.
    # Keep approvals scoped to the third-party entries declared in darwin.nix.
    "homebrew/trust.json".text = homebrewTrust;

    # gh-dash configs - generated from single source with theme variants
    "gh-dash/config-light.yml".text = toYAML (mkGhDashConfig catppuccinLatte);
    "gh-dash/config-dark.yml".text = toYAML (mkGhDashConfig catppuccinFrappe);

    #-------------------------------------------------------------------
    # Neovim — everything except init.lua (programs.neovim owns that)
    #-------------------------------------------------------------------
    # The LazyVim tree lives in home-ops (PRIVATE — lua/plugins/obsidian.lua
    # carries vault paths, which must not land in this public repo) and is
    # linked OUT OF STORE. Two reasons, each sufficient alone:
    #
    #   1. lazy.nvim rewrites lazy-lock.json on every update, so a read-only
    #      /nix/store path makes that write fail.
    #   2. lua/** is edited iteratively; a store path would demand a
    #      `make switch` before a keymap tweak could even be tried.
    #
    # mkOutOfStoreSymlink points at the home-ops WORKING TREE, so the files
    # stay writable and git-tracked while nix still owns placement.
    # Consequence: these paths need ~/home-ops checked out — the flake input
    # alone is not enough.
    #
    # The general rule: partition config by ownership, not by application.
    # Authored-and-app-reads-only -> store symlink. App rewrites it, or you
    # iterate on it -> out of store, into a tracked repo. Regenerable or
    # secret -> neither; leave it app-owned and ignored.
  }
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
