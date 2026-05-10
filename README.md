# nix-config

My entire computing environment, version-controlled. Declarative macOS using nix-darwin and home-manager.

## Quick Reference

```bash
make switch    # Apply configuration changes
make update    # Update flake inputs
make test      # Test without activating
```

## What This Manages

- **CLI packages** — Dev tools, modern CLI utilities, cloud SDKs
- **GUI apps** — Managed declaratively via Homebrew
- **AI tools** — Split by ownership: activation-managed vendor packages for fast-moving CLIs, vendor self-managed tools when they ship their own updater
- **Shell** — Fish with plugins and custom config
- **Dotfiles** — Git, terminal, tool configs
- **System settings** — Touch ID for sudo, shells, environment variables

## Architecture

Three-layer configuration system following [mitchellh's patterns](https://github.com/mitchellh/nixos-config):

```
├── flake.nix                    # Flake inputs and outputs
├── lib/mksystem.nix             # System builder function
├── machines/macbook-m4-max.nix  # Machine-specific config
└── users/tengjizhang/
    ├── darwin.nix               # macOS system config (Homebrew, system settings)
    ├── home-manager.nix         # User packages and programs
    ├── home/                    # Modular home-manager configs
    └── config.fish              # Fish shell config
```

**Layers:**
1. **Machine** (`machines/`) — Nix settings, binary caches, shell enablement
2. **User OS** (`users/*/darwin.nix`) — Homebrew, macOS settings, activation scripts
3. **User Home** (`users/*/home-manager.nix`) — Packages, programs, dotfiles

## Fresh Install

1. **Install Nix** (using Determinate installer):
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
   ```

2. **Clone:**
   ```bash
   git clone https://github.com/odysseus0/nix-config.git ~/nix-config
   cd ~/nix-config
   ```

3. **Customize** `flake.nix`, `machines/`, and `users/` to match your setup

4. **Apply:**
   ```bash
   make switch
   ```

## Key Details

**Package sources and ownership:**
- **nixpkgs-unstable** — Dev tools, recent versions
- **Homebrew** — GUI apps and Mac App Store apps
- **Home Manager activation + pnpm/bun/uv** — Fast-moving vendor CLIs that should update without routine `flake.lock` churn
- **Vendor self-managed** — Tools like Codex, Amp, and Claude Code that install into user-owned roots and expose commands through PATH

**Binary caches:**
- `cache.nixos.org` — Official
- `nix-community.cachix.org` — Community packages
**Determinate Nix:** Uses the Determinate installer with its official nix-darwin module for daemon management.

## Inspiration

- [mitchellh/nixos-config](https://github.com/mitchellh/nixos-config)
- [nix-darwin](https://github.com/nix-darwin/nix-darwin)
- [home-manager](https://github.com/nix-community/home-manager)

## License

MIT
