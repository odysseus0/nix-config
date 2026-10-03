{ pkgs, lib, facts, ... }:

{
  programs.git = {
    enable = true;
    lfs.enable = true;

    settings = {
      user = { inherit (facts.identity) name email; };

      init.defaultBranch = "main";
      # Source checkouts live at ~/src/<host>/<owner>/<repo>; `ghq get` clones there.
      ghq.root = "~/src";
      push.default = "simple";
      pull.rebase = false;
      branch.autosetuprebase = "always";
      color.ui = true;

      core.pager = "delta";
      interactive.diffFilter = "delta --color-only";
      delta = {
        detect-dark-light = "auto";
        navigate = true;
      };

      credential.helper = "osxkeychain";
      gpg = {
        format = "ssh";
        ssh.program = "ssh-keygen";
      };
      merge.conflictstyle = "diff3";
    };

    # Commits are signed with the SSH key, not GPG.
    signing = {
      signByDefault = true;
      key = "~/.ssh/id_ed25519.pub";
    };
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings."*" = {
      AddKeysToAgent = "yes";
      IdentityFile = "~/.ssh/id_ed25519";
    };
  };

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };

  # A project's toolchain: its flake devShell loads on cd.
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.fzf = {
    enable = true;
    enableFishIntegration = false;  # the fzf.fish plugin owns the bindings
    defaultCommand = "fd --hidden --type f";
    defaultOptions = [ "--ansi" "--layout=reverse" ];
    historyWidget.command = "";  # Atuin owns Ctrl-R
  };

  programs.bat = {
    enable = true;
    config.style = "numbers";
  };

  programs.atuin = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      style = "compact";
      inline_height = 20;
    };
  };

  programs.jujutsu = {
    enable = true;
    settings = {
      user = { inherit (facts.identity) name email; };
    };
  };

  # home-manager generates init.lua, so LazyVim's bootstrap goes through
  # initLua; a hand-written init.lua would be replaced by one that only
  # toggles providers, and nvim would start as a bare editor.
  programs.neovim = {
    enable = true;
    package = pkgs.neovim-unwrapped;
    initLua = ''
      require("config.lazy")
    '';
  };
  # The rest of the tree is linked out of store in dotfiles.nix.

  # herdr writes config.toml back at runtime (panel sort, keybindings), so a
  # store symlink, which programs.herdr.settings would create, fails those
  # writes. Activation seeds the defaults only when the file is absent, and
  # herdr owns it from then on. The seed's comments say why each value
  # differs from herdr's default.
  programs.herdr.enable = true;

  home.activation.seedHerdrConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    cfg="$HOME/.config/herdr/config.toml"
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

  # It has no effect on darwin, and warns unless off.
  programs.man.generateCaches = false;
}
