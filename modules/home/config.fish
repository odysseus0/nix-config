# Fish Shell Configuration
# Main configuration file - keep this clean and organized

# =============================================================================
# Utility Functions (defined early for use throughout config)
# =============================================================================

# System utilities - detect color scheme once at startup
set -g color_scheme (test "$(defaults read -g AppleInterfaceStyle 2>/dev/null)" = "Dark" && echo dark || echo light)

# Helper function for interactive use
function color_scheme -d "Get current macOS color scheme (dark/light)"
    echo $color_scheme
end

# =============================================================================
# Shell Behavior
# =============================================================================

# Disable fish greeting
set -g fish_greeting ""

# Vi key bindings for interactive shells
if status is-interactive
    fish_vi_key_bindings

    # Accept autosuggestions with Ctrl+F (community standard)
    bind -M insert \cf accept-autosuggestion
end

# =============================================================================
# Environment Variables
# =============================================================================

# Editor configuration
if test -n "$SSH_CONNECTION"
    set -gx EDITOR vim
else
    set -gx EDITOR nvim
end


# Bat (better cat) theme configuration - session-based (auto theme has issues in v0.25.0
set -gx BAT_THEME (test "$color_scheme" = "dark" && echo "Monokai Extended" || echo "GitHub")

# =============================================================================
# FZF.fish Integration
# =============================================================================

# Configure fzf.fish to work alongside Atuin
# Atuin handles Ctrl+R (history), fzf.fish provides file/git/process search
if status is-interactive
    fzf_configure_bindings --history= # Disable history binding (Atuin conflict)
end

# Minimal enhancements using tools we already have
set fzf_fd_opts --hidden # Show hidden files (useful for dotfiles)
set fzf_preview_dir_cmd eza --all --color=always # Back to eza with colors
set fzf_preview_file_cmd bat --color=always --style=numbers # Uses global BAT_THEME settings
set fzf_diff_highlighter "delta --paging=never --width=20 --$color_scheme"

# FZF options that adapt to light/dark mode
set -gx FZF_DEFAULT_OPTS "--ansi --layout=reverse --color=$color_scheme"

# Key bindings provided:
# Ctrl+Alt+F - Search files/directories  | Ctrl+Alt+P - Search processes
# Ctrl+Alt+L - Search git log            | Ctrl+V     - Search variables  
# Ctrl+Alt+S - Search git status         | Ctrl+R     - Atuin history

# =============================================================================
# Custom Functions
# =============================================================================

# AI-friendly TaskWarrior output
function taskai --description "AI-friendly flat output for TaskWarrior"
    task rc.defaultwidth=0 rc.verbose=nothing rc.color=off $argv | tr -s ' '
end


#-------------------------------------------------------------------------------
# Terminal Integration
#-------------------------------------------------------------------------------

# Ghostty shell integration (Mitchell's pattern)
# Ghostty supports auto-injection but nix-darwin overwrites XDG_DATA_DIRS
# which prevents auto-injection, so we source manually
if set -q GHOSTTY_RESOURCES_DIR
    source "$GHOSTTY_RESOURCES_DIR/shell-integration/fish/vendor_conf.d/ghostty-shell-integration.fish"
end

#-------------------------------------------------------------------------------
# Custom Aliases
#-------------------------------------------------------------------------------

# gh-dash with auto theme switching (Catppuccin Latte/Frappé)
function gh-dash -d "GitHub dashboard with auto light/dark theme"
    set -l theme (test "$(defaults read -g AppleInterfaceStyle 2>/dev/null)" = "Dark" && echo "dark" || echo "light")
    command gh-dash --config ~/.config/gh-dash/config-$theme.yml $argv
end

# Python 3.13 REPL/runner via uv, matching Coderpad's interview environment
# (system python3 is macOS-bundled 3.9.6)
abbr py313 "uv run --python 3.13 python3"

# =============================================================================
# PATH Configuration (Mitchell's approach)  
# =============================================================================

# Homebrew MANPATH/INFOPATH (need prepend semantics, can't go in sessionVariables)
# PATH, HOMEBREW_PREFIX/CELLAR/REPOSITORY managed in environment.nix
set -q MANPATH; or set MANPATH ''
set -gx MANPATH /opt/homebrew/share/man $MANPATH
set -q INFOPATH; or set INFOPATH ''
set -gx INFOPATH /opt/homebrew/share/info $INFOPATH
