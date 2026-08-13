{ inputs, pkgs, lib, ... }:

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

  # Backs the "project-scope demotion candidates" tier in home/packages.nix
  # (cloud/infra CLIs moving to per-project devShells loaded via .envrc).
  # CGO_ENABLED override: direnv's Makefile links with `-linkmode=external`
  # while buildGoModule defaults CGO off under Go 1.26, so the stock package
  # fails on BOTH unstable and stable pins (nixpkgs #503298; verified
  # 2026-08-04 — `-linkmode=external requires external (cgo) linking`).
  # Forcing cgo on builds clean. Drop the override once nixpkgs' direnv
  # builds stock again; `make build` is the gate.
  programs.direnv = {
    enable = true;
    package = pkgs.direnv.overrideAttrs (o: {
      env = (o.env or { }) // { CGO_ENABLED = "1"; };
    });
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

  # home-manager owns init.lua. The module generates it, so LazyVim's bootstrap
  # has to be threaded THROUGH extraLuaConfig — otherwise the generated file
  # (provider toggles only) lands on top of `require("config.lazy")` and nvim
  # silently starts as a bare editor. The rest of the LazyVim tree
  # (~/.config/nvim/lua/**) and lazy-lock.json stay app-owned: lazy.nvim writes
  # that lockfile itself and cannot be given a read-only store path.
  programs.neovim = {
    enable = true;
    package = pkgs.neovim-unwrapped;
    extraLuaConfig = ''
      require("config.lazy")
    '';
  };

  #---------------------------------------------------------------------
  # Herdr - agent multiplexer (replaces the tmux/zellij pair)
  #---------------------------------------------------------------------
  # ui.toast.delivery ships as "off", so a default install does NOT do the one
  # thing herdr was chosen for.
  #
  # "terminal" over "system": both work — "system" shells out to
  # terminal-notifier when it can find one and /usr/bin/osascript otherwise,
  # borrowing a bundled host's notification permission. "terminal" emits an
  # escape sequence and lets Ghostty raise it, which wins on three counts: the
  # notification carries Ghostty's identity instead of an anonymous script
  # icon, there is no osascript fork per notification, and it follows the
  # CLIENT rather than the server — so an SSH-driven session notifies the
  # laptop in front of you, not the box the server happens to run on. It is
  # also the same path Claude Code's own preferredNotifChannel takes.
  # config.toml is APP-OWNED, not store-owned. herdr writes it back at runtime —
  # the TUI persists ui.agent_panel_sort and custom keybindings there — so a
  # /nix/store symlink makes those writes fail with EACCES. Using
  # programs.herdr.settings did exactly that.
  #
  # Seed instead of manage: activation installs these defaults only when the
  # file is absent, so a fresh machine comes up configured and herdr still owns
  # the file afterwards. Same boundary as lazy-lock.json under nvim.
  programs.herdr.enable = true;

  home.activation.seedHerdrConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    cfg="$HOME/.config/herdr/config.toml"
    # Drop a symlink left by the earlier store-managed arrangement.
    if [ -L "$cfg" ]; then
      $DRY_RUN_CMD rm -f "$cfg"
    fi
    if [ ! -e "$cfg" ]; then
      $DRY_RUN_CMD mkdir -p "$(dirname "$cfg")"
      $DRY_RUN_CMD cat > "$cfg" <<'TOML'
[ui]
agent_panel_sort = "spaces"

[ui.sound]
enabled = true

[ui.toast]
# Ships as "off": a default install raises no desktop notification when an
# agent finishes or blocks. "terminal" asks the outer terminal to raise it, so
# it carries Ghostty's identity and follows the client over SSH.
delivery = "terminal"
delay_seconds = 1

[theme]
# auto_switch ships as false, so herdr pins one theme while Ghostty follows
# macOS appearance — the sidebar stays dark against a light transcript. Names
# track the ghostty config's Catppuccin Frappe/Latte pair.
auto_switch = true
dark_name = "catppuccin"
light_name = "catppuccin-latte"

TOML
    fi
  '';

  # Silence "generateCaches has no effect" warning on darwin
  programs.man.generateCaches = false;

  #---------------------------------------------------------------------
  # mise - polyglot version manager
  # Always use prebuilt binaries — never compile from source
  #---------------------------------------------------------------------

  home.file.".config/mise/config.toml".text = ''
    [settings]
    ruby.compile = false
  '';
}
