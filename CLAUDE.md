# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a nix-darwin configuration repository that declaratively manages a macOS development environment using Nix flakes, nix-darwin, and home-manager. It follows Mitchell Hashimoto's configuration patterns.

## Common Commands

```bash
# Apply configuration changes (requires sudo for system-level changes)
make switch
# or: sudo NIXPKGS_ALLOW_UNFREE=1 darwin-rebuild switch --impure --flake ".#macbook-m4-max"

# Test configuration without activating
make test

# Build configuration only (no activation)
make build

# Update flake inputs to latest versions
make update
# or: nix flake update

# Update flake inputs and auto-commit changes
make update-commit

# Update, commit, and push to remote
make update-commit-push

# Clean build artifacts
make clean
```

## Architecture

### Three-Layer Configuration System

1. **Machine Layer** (`machines/<name>.nix`)
   - System-level Nix settings (experimental features, binary caches)
   - Shell program enablement (zsh, fish)
   - System packages (minimal - just cachix)
   - Sets system.stateVersion

2. **User OS Layer** (`users/<user>/darwin.nix`)
   - Homebrew configuration (GUI apps, Mac App Store apps)
   - macOS-specific system settings (Touch ID for sudo)
   - User shell setup and activation scripts

3. **User Home Layer** (`users/<user>/home-manager.nix`)
   - CLI packages (~100 packages)
   - Program configurations (git, neovim, fish)
   - Dotfiles management
   - Environment variables

### Key Files

- `flake.nix` - Flake inputs/outputs, defines system configurations
- `lib/mksystem.nix` - System builder function that composes all layers
- `machines/macbook-m4-max.nix` - Machine-specific config
- `users/tengjizhang/darwin.nix` - macOS system config
- `users/tengjizhang/home-manager.nix` - User environment config
- `users/tengjizhang/config.fish` - Fish shell configuration

### Package Strategy

- **Stable (nixpkgs 25.05)**: System-critical packages
- **Unstable (nixpkgs-unstable)**: Dev tools (accessed via `pkgs.unstable.*`)
- **Homebrew**: GUI apps and Mac App Store apps

The overlay in flake.nix exposes unstable packages as `pkgs.unstable.*` to get recent versions while maintaining cached builds.

### Binary Caches

Pre-configured for fast downloads (managed via `determinateNix.customSettings` in `machines/*.nix`):
- `cache.nixos.org` - Official Nix cache (included by default)
- `nix-community.cachix.org` - Community packages
- `cache.numtide.com` - LLM/AI tools from numtide/llm-agents.nix (daily builds)

**Important**: Avoid adding overlays without verifying they have active caches. The neovim-nightly-overlay was removed in Oct 2025 because it caused 2-3GB downloads and 30+ min builds when caches were stale. Switched to stable neovim from nixpkgs-unstable instead.

## Configuration Patterns

### Adding Packages

**CLI tools** → `users/tengjizhang/home-manager.nix` in `home.packages`
**GUI apps** → `users/tengjizhang/darwin.nix` in `homebrew.casks`
**Mac App Store apps** → `users/tengjizhang/darwin.nix` in `homebrew.masApps`

### Program Configuration (Mitchell's Pattern)

- Simple shell aliases: Define in Nix (`programs.fish.shellAliases`)
- Complex shell config: Separate file (`config.fish`) loaded via `interactiveShellInit`
- Program settings: Use home-manager's `programs.*` modules when available
- Dotfiles: Simple files in `home.file.*`, XDG-aware configs in `xdg.configFile.*`

### AI CLI Tools Pattern

AI CLI tools come from `numtide/llm-agents.nix` flake input (daily automated updates with binary cache):
- `claude-code` - Anthropic's Claude Code CLI
- `codex` - OpenAI Codex CLI
- `gemini-cli` - Google Gemini CLI
- `agent-browser` - Browser automation
- `clawdbot` - Claude bot utility

Tools not covered by numtide are installed via pnpm activation script:
- `bird` - Twitter/X CLI (@steipete/bird)
- `gccli` - Google Calendar CLI (@mariozechner/gccli)

See `users/tengjizhang/home/packages.nix` for the full configuration.

## Important Implementation Details

### Shell Integration

- nix-darwin handles Nix daemon integration automatically
- Fish/zsh init scripts are in machine config (`machines/*.nix`)
- Personal PATH additions go in `users/*/config.fish`, not home-manager

### Git Configuration

Uses structured `settings` attribute (new format as of home-manager updates):
- `programs.git.settings.*` instead of `programs.git.extraConfig`
- SSH signing with local key configured
- Delta pager with auto light/dark detection

### Homebrew Integration

- `onActivation.cleanup = "uninstall"` removes old formulas automatically
- Requires Mac App Store login for MAS apps
- Activation script warns if not signed in

### Determinate Nix Installer

This config uses the Determinate Nix installer with its official nix-darwin module:
- `determinate` flake input from FlakeHub
- `inputs.determinate.darwinModules.default` added in `lib/mksystem.nix`
- `nix.enable = false` in machine config (Determinate manages Nix daemon)
- `determinateNix.customSettings` for cache configuration (writes to `/etc/nix/nix.custom.conf`)
- `ids.gids.nixbld = 30000` for compatibility

**Note**: Do NOT use `nix.settings` for caches when `nix.enable = false` - those settings are ignored. Use `determinateNix.customSettings` instead.

## Testing Changes

1. Build first: `make build` (validates syntax, doesn't activate)
2. Test: `make test` (activates temporarily)
3. Apply: `make switch` (activates and makes default)

Typical update cycle: ~100-500MB downloads, ~5-10 minutes (varies by cache freshness).

## Claude Skills

Claude Code skills are managed declaratively in this repo and symlinked to `~/.claude/skills/` via home-manager.

**Location:** `users/tengjizhang/claude/skills/{skill-name}/SKILL.md`

To edit a skill, modify the source here and rebuild. The `~/.claude/skills/` directory is read-only (Nix-managed).

## Development Notes

- **NIXPKGS_ALLOW_UNFREE=1** is required because many packages (VSCode, Chrome, etc.) are unfree
- The `--impure` flag is used with darwin-rebuild for environment variable access
- All configurations are managed in git - no manual file editing outside this repo
- Fish is the primary shell; zsh is enabled for macOS compatibility
