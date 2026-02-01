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
- **AI tools** — Claude Code, Codex, Gemini CLI via [numtide/llm-agents.nix](https://github.com/numtide/llm-agents.nix)
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

**Package sources:**
- **nixpkgs-unstable** — Dev tools, recent versions
- **Homebrew** — GUI apps and Mac App Store apps
- **numtide/llm-agents.nix** — AI CLI tools with daily builds and binary cache

**Binary caches:**
- `cache.nixos.org` — Official
- `nix-community.cachix.org` — Community packages
- `cache.numtide.com` — LLM/AI tools

**Determinate Nix:** Uses the Determinate installer with its official nix-darwin module for daemon management.

## Inspiration

- [mitchellh/nixos-config](https://github.com/mitchellh/nixos-config)
- [nix-darwin](https://github.com/nix-darwin/nix-darwin)
- [home-manager](https://github.com/nix-community/home-manager)
- [numtide/llm-agents.nix](https://github.com/numtide/llm-agents.nix)

## License

MIT
