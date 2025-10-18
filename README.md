# nix-config

Declarative macOS development environment using nix-darwin and home-manager.

## Quick Reference

```bash
make switch    # Apply configuration changes
make update    # Update flake inputs
make test      # Test without activating
```

## What This Manages

- **~100 CLI packages** - Dev tools, modern CLI utilities, cloud SDKs
- **50+ GUI apps** - Managed declaratively via Homebrew
- **Shell environment** - Fish with plugins and custom config
- **Dotfiles** - Git, terminal, tool configs
- **System settings** - Touch ID for sudo, shells, environment variables

## Key Packages

**Development:**
- Languages: Go, Node.js (pnpm), Python (uv)
- Cloud: AWS CLI, Google Cloud SDK, Terraform
- Tools: Neovim, Zellij, direnv, Docker (OrbStack)

**Modern CLI:**
- `bat` (cat), `eza` (ls), `fd` (find), `ripgrep` (grep), `delta` (git diff)
- `zoxide` (cd), `atuin` (history), `fzf` (fuzzy finder)

**AI Tools:**
- Claude Code, Codex

## Fresh Install Setup

1. **Install Nix:**
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
   ```

2. **Clone and customize:**
   ```bash
   git clone https://github.com/odysseus0/nix-config.git ~/.config/nix-config
   cd ~/.config/nix-config
   # Edit flake.nix, machines/, and users/ to match your setup
   ```

3. **Apply:**
   ```bash
   make switch
   ```

## Structure

```
├── flake.nix                    # Flake inputs and outputs
├── machines/macbook-m4-max.nix  # Machine-specific config
└── users/tengjizhang/
    ├── darwin.nix               # macOS system config (homebrew, etc)
    ├── home-manager.nix         # User packages and programs
    └── config.fish              # Fish shell config
```

**Configuration layers:**
1. `machines/` - System-level settings, Nix configuration, binary caches
2. `users/*/darwin.nix` - OS-level config (Homebrew, activation scripts)
3. `users/*/home-manager.nix` - User packages, programs, dotfiles

## Important Notes

### Package Strategy
- **Stable** (nixpkgs 25.05): System-critical packages
- **Unstable** (nixpkgs-unstable): Dev tools where we want recent versions
- **Homebrew**: GUI apps and Mac App Store apps

### Binary Caches
Pre-configured caches for fast downloads:
- `cache.nixos.org` - Official Nix cache
- `nix-community.cachix.org` - Community packages

Most updates: ~100-500MB downloads, ~5-10 minutes.

### Neovim Decision
Switched from `neovim-nightly-overlay` to stable neovim from nixpkgs-unstable:
- **Before**: 2-3GB downloads, 30+ min builds (nightly often not cached)
- **After**: ~20MB download, always cached
- Still gets updates ~weekly from unstable channel

## Inspiration

- [mitchellh/nixos-config](https://github.com/mitchellh/nixos-config) - Structure and patterns
- [LnL7/nix-darwin](https://github.com/LnL7/nix-darwin) - macOS support
- [nix-community/home-manager](https://github.com/nix-community/home-manager) - User environment

## License

MIT
