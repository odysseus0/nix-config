{ inputs, pkgs, ... }:

{
  #---------------------------------------------------------------------
  # Git - Version control with SSH signing
  #---------------------------------------------------------------------

  programs.git = {
    enable = true;

    settings = {
      # User configuration
      user = {
        name = "tengjizhang";
        email = "odysseus0@users.noreply.github.com";
      };

      # Basic settings
      init.defaultBranch = "main";
      push.default = "simple";
      pull.rebase = false;
      branch.autosetuprebase = "always";
      color.ui = true;

      # Delta - minimal config with auto light/dark detection
      core.pager = "delta";
      interactive.diffFilter = "delta --color-only";
      delta = {
        detect-dark-light = "auto";
        navigate = true;
      };

      # SSH signing with local key
      credential.helper = "osxkeychain";
      gpg = {
        format = "ssh";
        ssh.program = "ssh-keygen";
      };
      commit.gpgsign = true;
      merge.conflictstyle = "diff3";
    };

    # SSH signing with local key
    signing = {
      signByDefault = true;
      key = "~/.ssh/id_ed25519.pub";
    };
  };

  #---------------------------------------------------------------------
  # SSH - Centralized SSH configuration
  #---------------------------------------------------------------------

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks."*" = {
      extraOptions = {
        AddKeysToAgent = "yes";
        IdentityFile = "~/.ssh/id_ed25519";
      };
    };
  };

  #---------------------------------------------------------------------
  # Zoxide - Smart directory navigation
  #---------------------------------------------------------------------

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };

  #---------------------------------------------------------------------
  # Direnv - Per-directory environment management
  #---------------------------------------------------------------------

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  #---------------------------------------------------------------------
  # FZF - Fuzzy finder
  #---------------------------------------------------------------------

  programs.fzf = {
    enable = true;
    enableFishIntegration = false;  # using fzf.fish plugin
    defaultCommand = "fd --hidden --type f";
    defaultOptions = [ "--ansi" "--layout=reverse" ];
  };

  #---------------------------------------------------------------------
  # Bat - Better cat with syntax highlighting
  #---------------------------------------------------------------------

  programs.bat = {
    enable = true;
    config.style = "numbers";
  };

  #---------------------------------------------------------------------
  # Atuin - Shell history search
  #---------------------------------------------------------------------

  programs.atuin = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      style = "compact";
      inline_height = 20;
    };
  };

  #---------------------------------------------------------------------
  # Nushell - Alternative shell (occasional use)
  #---------------------------------------------------------------------

  programs.nushell.enable = true;

  #---------------------------------------------------------------------
  # Jujutsu - Modern VCS
  #---------------------------------------------------------------------

  programs.jujutsu = {
    enable = true;
    settings = {
      user = {
        name = "tengjizhang";
        email = "odysseus0@users.noreply.github.com";
      };
    };
  };

  #---------------------------------------------------------------------
  # Neovim - Editor
  #---------------------------------------------------------------------

  programs.neovim = {
    enable = true;
    package = pkgs.neovim-unwrapped;
  };
}
