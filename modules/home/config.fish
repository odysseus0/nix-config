# Interactive fish on both Macs (core.nix). The aliases and plugins are
# declared there; this file holds what Nix options cannot express.

# The macOS appearance, read once per shell; the theme choices below follow it.
set -g color_scheme (test "$(defaults read -g AppleInterfaceStyle 2>/dev/null)" = "Dark" && echo dark || echo light)

function color_scheme -d "Get current macOS color scheme (dark/light)"
    echo $color_scheme
end

set -g fish_greeting ""

if status is-interactive
    fish_vi_key_bindings
    # Ctrl-F accepts an autosuggestion in insert mode, as in emacs mode.
    bind -M insert \cf accept-autosuggestion
end

# Sietch, reached over SSH, has no Neovim.
if test -n "$SSH_CONNECTION"
    set -gx EDITOR vim
else
    set -gx EDITOR nvim
end

# bat's auto theme is unreliable here, so the theme follows color_scheme.
set -gx BAT_THEME (test "$color_scheme" = "dark" && echo "Monokai Extended" || echo "GitHub")

# fzf.fish searches files, git and processes; Atuin owns Ctrl-R, so fzf.fish
# leaves history unbound.
if status is-interactive
    fzf_configure_bindings --history=
end

set fzf_fd_opts --hidden
set fzf_preview_dir_cmd eza --all --color=always
set fzf_preview_file_cmd bat --color=always --style=numbers
set fzf_diff_highlighter "delta --paging=never --width=20 --$color_scheme"

set -gx FZF_DEFAULT_OPTS "--ansi --layout=reverse --color=$color_scheme"

# Taskwarrior output an agent can parse: no colors, no padding.
function taskai --description "AI-friendly flat output for TaskWarrior"
    task rc.defaultwidth=0 rc.verbose=nothing rc.color=off $argv | tr -s ' '
end

# Ghostty injects its shell integration through XDG_DATA_DIRS, which
# nix-darwin overwrites, so it is sourced by hand.
if set -q GHOSTTY_RESOURCES_DIR
    source "$GHOSTTY_RESOURCES_DIR/shell-integration/fish/vendor_conf.d/ghostty-shell-integration.fish"
end

# Python 3.13 through uv; the system python3 is macOS's 3.9.
abbr py313 "uv run --python 3.13 python3"

# Homebrew's manuals, prepended; PATH and the HOMEBREW_* variables are set in
# environment.nix.
set -q MANPATH; or set MANPATH ''
set -gx MANPATH /opt/homebrew/share/man $MANPATH
set -q INFOPATH; or set INFOPATH ''
set -gx INFOPATH /opt/homebrew/share/info $INFOPATH
