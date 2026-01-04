---
name: nix-config
description: Declarative macOS environment management via Nix. Use when user wants to install packages, add CLI tools, configure programs, manage dotfiles, or modify their development environment. Covers adding packages, the pnpm dlx wrapper pattern for npm tools, and rebuilding the system.
---

# Nix Config

Declarative macOS environment at `~/nix-config`. See the repo's CLAUDE.md for full architecture.

## Adding Packages

**CLI tools** → `users/tengjizhang/home/packages.nix`
```nix
home.packages = with pkgs; [
  ripgrep
  jq
  # ...
];
```

**GUI apps** → `users/tengjizhang/darwin.nix`
```nix
homebrew.casks = [ "raycast" "obsidian" ];
```

**Mac App Store** → `users/tengjizhang/darwin.nix`
```nix
homebrew.masApps = { "Things" = 904280696; };
```

## npm Package Pattern

For latest npm packages, use `pnpm dlx` wrapper:

```nix
(writeShellScriptBin "toolname" ''
  exec ${pnpm}/bin/pnpm dlx @scope/package@latest "$@"
'')
```

Examples in packages.nix: `claude`, `codex`, `gemini`, `gccli`

## Rebuild

```bash
cd ~/nix-config && make switch
# or: sudo darwin-rebuild switch --flake .#macbook-m4-max
```

## Workflow

1. Edit the appropriate .nix file
2. `make switch` to rebuild and activate
3. Commit and push changes

## Key Files

- `flake.nix` - Inputs/outputs, system definition
- `users/tengjizhang/home/packages.nix` - CLI packages
- `users/tengjizhang/home/programs.nix` - Program configs (git, neovim, etc.)
- `users/tengjizhang/darwin.nix` - Homebrew, macOS settings
