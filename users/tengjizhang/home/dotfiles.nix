{ pkgs, lib, ... }:

let
  # gh-dash base config (theme-agnostic)
  ghDashBase = {
    prSections = [
      { title = "My PRs"; filters = "is:open author:@me"; }
      { title = "Needs Review"; filters = "is:open review-requested:@me"; }
      { title = "My Repos"; filters = "is:open -author:@me repo:flashbots/mev-share-node-pareto repo:flashbots/protect-rpc repo:flashbots/devops repo:flashbots/go-utils repo:flashbots/protect-of-api repo:steipete/bird"; }
    ];
    issuesSections = [
      { title = "Assigned"; filters = "is:open assignee:@me"; }
      { title = "Involved"; filters = "is:open involves:@me -assignee:@me"; }
    ];
    notificationsSections = [
      { title = "All"; filters = ""; }
      { title = "Review Requested"; filters = "reason:review-requested"; }
      { title = "Mentioned"; filters = "reason:mention"; }
      { title = "Participating"; filters = "reason:participating"; }
    ];
    repoPaths = {
      "odysseus0/nix-config" = "~/nix-config";
      "flashbots/mev-share-node-pareto" = "~/projects/mev-share-node-pareto";
      "flashbots/protect-rpc" = "~/projects/protect-rpc";
      "flashbots/devops" = "~/projects/devops";
      "flashbots/go-utils" = "~/projects/go-utils";
      "flashbots/protect-of-api" = "~/projects/protect-of-api";
      "steipete/bird" = "~/projects/bird";
      "openclaw/openclaw" = "~/projects/openclaw";
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
    smartFilteringAtLaunch = true;
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
      onlyBuiltDependencies[]=keytar
      onlyBuiltDependencies[]=node-pty
      onlyBuiltDependencies[]=protobufjs
      onlyBuiltDependencies[]=sharp
      onlyBuiltDependencies[]=tree-sitter-bash
    '';

    # gh-dash configs - generated from single source with theme variants
    "gh-dash/config-light.yml".text = toYAML (mkGhDashConfig catppuccinLatte);
    "gh-dash/config-dark.yml".text = toYAML (mkGhDashConfig catppuccinFrappe);

    # Amp - point to local CLIProxyAPI instead of ampcode.com
    "amp/settings.json".text = builtins.toJSON {
      "amp.url" = "http://localhost:8317";
    };
  };

  # Amp secrets - API key matching CLIProxyAPI's api-keys list
  # amp login is not needed when using local proxy
  xdg.dataFile."amp/secrets.json".text = builtins.toJSON {
    "apiKey@http://localhost:8317" = "amp-local-proxy-key";
  };
}
