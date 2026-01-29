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

# Application-specific paths
set -gx GOPATH $HOME/go

# Claude Code settings
set -gx ENABLE_BACKGROUND_TASKS 1
set -gx FORCE_AUTO_BACKGROUND_TASKS 1

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

# Package manager overview (Nix pro style)
function managed -d "List packages managed by various package managers (Nix pro style)"
    # Output format: category:manager:package for better organization

    # === CORE INFRASTRUCTURE (Nix-managed) ===
    if command -q nix-env
        echo "# Core Infrastructure (Nix)"
        nix-env -q 2>/dev/null | sed 's/^/core:nix:/'
        echo
    end

    # === PLATFORM INTEGRATION (Homebrew) ===
    echo "# Platform Integration (Homebrew)"
    brew list --formula 2>/dev/null | sed 's/^/platform:brew:/'
    brew list --cask 2>/dev/null | sed 's/^/platform:cask:/'
    echo

    # === LANGUAGE ECOSYSTEMS ===
    echo "# Language Ecosystems"
    # UV tools (Python)
    uv tool list 2>/dev/null | grep '^[a-zA-Z]' | awk '{print "lang:uv:" $1}'

    # Cargo (Rust)
    ls ~/.cargo/bin 2>/dev/null | grep -v rustup | sed 's/^/lang:cargo:/'

    # NPM global (Node.js)
    npm list -g --depth=0 2>/dev/null | grep '^[├└]' | sed 's/^[├└]── //' | awk '{print "lang:npm:" $1}'

    # PNPM global (Node.js)
    pnpm list -g --json 2>/dev/null | jq -r '.[0].dependencies // {} | keys[]' 2>/dev/null | sed 's/^/lang:pnpm:/'

    # Go binaries
    if test -d ~/go/bin
        ls ~/go/bin 2>/dev/null | sed 's/^/lang:go:/'
    end

    # Conda (Python/Data Science)
    if command -q conda
        conda list 2>/dev/null | grep -v '^#' | awk '{print "lang:conda:" $1}'
    end
    echo

    # === EDITOR EXTENSIONS ===
    echo "# Editor Extensions"
    if command -q code-insiders
        code-insiders --list-extensions 2>/dev/null | sed 's/^/editor:vscode:/'
    end
    echo

    # === MANUAL INSTALLS (Moving targets) ===
    echo "# Manual Installs (Nightly/Beta/Auto-updating)"
    ls /Applications 2>/dev/null | grep -iE "(nightly|beta|canary|discord)" | sed 's/^/manual:app:/' | sed 's/\.app$//'
end

# AI-friendly TaskWarrior output
function taskai --description "AI-friendly flat output for TaskWarrior"
    task rc.defaultwidth=0 rc.verbose=nothing rc.color=off $argv | tr -s ' '
end

# Claude Code profile helpers
function _claude_profile_path
    set -l profiles_dir "$HOME/.claude/profiles"

    test -d "$profiles_dir"; or echo "No profiles directory at $profiles_dir" >&2 && return 1

    set -l profile $argv[1]

    if test -z "$profile"
        if command -q gum
            set profile (ls "$profiles_dir"/*.json | xargs -n1 basename -s .json | gum choose --header "Select Claude profile:")
        else if command -q fzf
            set profile (ls "$profiles_dir"/*.json | xargs -n1 basename -s .json | fzf --prompt="Profile: ")
        else
            echo "Usage: claude-profile <profile-name>" >&2
            ls "$profiles_dir"/*.json | xargs -n1 basename -s .json | sed 's/^/  /' >&2
            return 1
        end
    end

    test -z "$profile"; and return 1

    set -l profile_path "$profiles_dir/$profile.json"
    test -f "$profile_path"; or echo "Profile not found: $profile_path" >&2 && return 1

    echo $profile_path
end

function claude-profile --description "Launch Claude Code with a profile"
    set -l p (_claude_profile_path $argv[1]); or return
    claude --settings "$p" $argv[2..-1]
end

function ccc-profile --description "Launch Claude Code with profile, skip permissions"
    set -l p (_claude_profile_path $argv[1]); or return
    claude --settings "$p" --dangerously-skip-permissions $argv[2..-1]
end

# SSH keys are now managed locally at ~/.ssh/id_ed25519
# No need for 1Password integration - keys are loaded automatically

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

# Custom complex aliases that need shell logic
alias code cursor

# =============================================================================
# PATH Configuration (Mitchell's approach)  
# =============================================================================

# Homebrew integration (critical for Homebrew/Nix coexistence)
if test -d /opt/homebrew
    set -gx HOMEBREW_PREFIX /opt/homebrew
    set -gx HOMEBREW_CELLAR /opt/homebrew/Cellar
    set -gx HOMEBREW_REPOSITORY /opt/homebrew
    set -q PATH; or set PATH ''
    set -gx PATH /opt/homebrew/bin /opt/homebrew/sbin $PATH
    set -q MANPATH; or set MANPATH ''
    set -gx MANPATH /opt/homebrew/share/man $MANPATH
    set -q INFOPATH; or set INFOPATH ''
    set -gx INFOPATH /opt/homebrew/share/info $INFOPATH
end

# Hammerspoon CLI integration (you have it installed via darwin.nix)
if test -d "/Applications/Hammerspoon.app"
    set -q PATH; or set PATH ''
    set -gx PATH "/Applications/Hammerspoon.app/Contents/Frameworks/hs" $PATH
end

# Personal scripts directory (matches Mitchell's pattern)
set -q PATH; or set PATH ''
set -gx PATH "$HOME/.local/bin" $PATH

# Go binaries (go install'd tools)
set -gx PATH "$HOME/go/bin" $PATH

# =============================================================================
# Auto-Generated Tool Configuration
# =============================================================================
# Tools like conda, pnpm, LM Studio, etc. will automatically add their 
# initialization code below. You can periodically clean this up by moving
# their sections to conf.d/paths.fish if they get too messy.
