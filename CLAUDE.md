# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a nix-darwin configuration repository that declaratively manages a macOS development environment using Nix flakes, nix-darwin, and home-manager. Structural layering follows Mitchell Hashimoto's pattern (see README §Inspiration); tool management follows this repo's own ownership-tier model (see README §Ownership tiers) — read the README before making a package-placement decision, it has the full argument.

## Common Commands

```bash
# Apply configuration changes (requires sudo for system-level changes)
make switch
# or: sudo darwin-rebuild switch --flake ".#macbook-m4-max"
# Pure — no --impure, no NIXPKGS_ALLOW_UNFREE needed (removed 2026-07-20,
# audit F5: nixpkgs.config.allowUnfree = true is declared in the module
# system and pkgs-stable is re-imported with the same config; see
# users/tengjizhang/home/packages.nix's comment on pkgs-stable).

# Test configuration without activating
make test

# Build configuration only (no activation) — the CI-equivalent gate
make build

# Reconcile MANIFEST-OWNED tools (currently just uv) to their manifest.
# Network-dependent, explicit — never runs from switch/activation.
make update-tools

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
   - System-level Nix settings (experimental features, binary caches via `determinateNix.customSettings`)
   - Shell program enablement (zsh, fish)
   - System packages (minimal — cachix, mosh, tmux)
   - Sets `system.stateVersion`

2. **User OS Layer** (`users/<user>/darwin.nix`)
   - Homebrew configuration (GUI apps, Mac App Store apps)
   - macOS-specific system settings (Touch ID for sudo)
   - User shell setup and activation scripts

3. **User Home Layer** (`users/<user>/home-manager.nix` + `users/<user>/home/*.nix`)
   - CLI packages, tiered by ownership (see below)
   - Program configurations (git, neovim, fish)
   - Dotfiles management
   - Environment variables

`lib/mksystem.nix` forks on `darwin ? false` between this Darwin machine and
a future NixOS machine (see README §Server-readiness) — keep that fork and
the `machines/`/`users/` layering intact even though only one machine exists
today.

### Key Files

- `flake.nix` — flake inputs/outputs, defines system configurations
- `lib/mksystem.nix` — system builder function that composes all layers
- `lib/uv-tools-reconcile.nix` — MANIFEST-OWNED tier executor, exposed via overlay as `pkgs.uv-tools-reconcile`
- `machines/macbook-m4-max.nix` — machine-specific config, binary caches
- `users/tengjizhang/darwin.nix` — macOS system config
- `users/tengjizhang/home-manager.nix` — module imports, home-ops wiring
- `users/tengjizhang/home/packages.nix` — CLI packages, tiered (see below)
- `users/tengjizhang/home/uv-tools-manifest.nix` — MANIFEST-OWNED tier's source of truth
- `users/tengjizhang/config.fish` — Fish shell configuration

### Package Strategy

- **nixpkgs-unstable**: default for CLI tools, recent versions
- **nixpkgs-stable (25.11)**: cherry-picked for packages that break on unstable (currently just `_1password-cli`, via the `pkgs-stable` binding in `home/packages.nix` — read its comment before reaching for `pkgs.unstable.*`-style overlays, which this repo does NOT use)
- **llm-agents.nix** (`github:numtide/llm-agents.nix`): store-owned AI agent CLIs, consumed via its `packages.<system>` output (NOT its overlay — see `flake.nix`'s comment on the `llm-agents` input for the nixpkgs version-skew reason)
- **Homebrew**: GUI apps and Mac App Store apps

### Binary Caches

Pre-configured via `determinateNix.customSettings` in `machines/*.nix` (NOT `nix.settings` — Determinate Nix manages the daemon, `nix.enable = false`):
- `cache.nixos.org` — official Nix cache (included by default)
- `nix-community.cachix.org` — community packages
- `cache.numtide.com` — `llm-agents.nix` packages

**Cache-hit discipline (hard rule)**: source compilation — especially Rust/C++ — is treated as a defect, not a cost. Nothing enters this config (package, input, overlay, override) without a cache story: before adding, verify the substituter actually serves it (`nix path-info --store https://<cache> <drv-output>`, or just watch whether `make build` says "copying path" vs "building"). Two scars back this rule: the neovim-nightly-overlay (removed Oct 2025 — stale cache meant 2-3GB downloads and 30+ min builds) and the 2026-08-04 llm-agents bootstrap (codex compiled Rust from scratch because `cache.numtide.com` was declared in the new config but not yet trusted by the *running* daemon — substituters take effect only after a switch writes them to `/etc/nix/nix.custom.conf`; on a fresh machine, pre-seed that file by hand and `launchctl kickstart -k system/systems.determinate.nix-daemon` before the first build). Small Go/shell builds (e.g. the direnv CGO override while nixpkgs #503298 is open) are tolerated; anything that would compile for minutes is not — pin to a cached rev or don't ship it.

## Configuration Patterns

### Adding Packages — pick the ownership tier first

See README §Ownership tiers for the full argument. In short:

**STORE-OWNED (default)** → `users/tengjizhang/home/packages.nix`, `home.packages`. AI agent CLIs specifically go through `llmAgents.<name>` (the `inputs.llm-agents.packages.${system}` binding at the top of that file) if `llm-agents.nix` packages them — check `nix eval github:numtide/llm-agents.nix#packages.aarch64-darwin --apply builtins.attrNames` or its README before assuming a tool isn't covered.

**MANIFEST-OWNED** → add to the list in `users/tengjizhang/home/uv-tools-manifest.nix` (currently the only manifest-owned domain is uv). Never add an activation script for this — the executor runs from `make update-tools` only.

**VENDOR-OWNED** → PATH wiring only, in `users/tengjizhang/home/environment.nix` (`home.sessionPath`). Every vendor-owned exception needs a code comment stating why it can't be store-owned and what would let it graduate — see the `vitePlusHome` comment in that file for the template.

**GUI apps** → `users/tengjizhang/darwin.nix`, `homebrew.casks`
**Mac App Store apps** → `users/tengjizhang/darwin.nix`, `homebrew.masApps`

### Program Configuration (Mitchell's Pattern)

- Simple shell aliases: Define in Nix (`programs.fish.shellAliases`)
- Complex shell config: Separate file (`config.fish`) loaded via `interactiveShellInit`
- Program settings: Use home-manager's `programs.*` modules when available
- Dotfiles: Simple files in `home.file.*`, XDG-aware configs in `xdg.configFile.*`

## Important Implementation Details

### The two clocks — do not put network calls in activation

`home.activation.*` scripts run on every `make switch`. That phase must stay
offline and must not soft-fail (`|| echo continuing` is banned there) — see
README §The two clocks for why. If you're tempted to add an activation
script that calls out to pnpm/uv/curl/a vendor installer, it belongs in the
manifest-owned tier (`make update-tools`) or the vendor-owned tier (no Nix
activation at all) instead. The only activation scripts that should exist are
local cleanup, like `removeInstallerPlannotatorCli`.

### Shell Integration

- nix-darwin handles Nix daemon integration automatically
- Fish/zsh init scripts are in machine config (`machines/*.nix`)
- Personal PATH additions go in `users/*/home/environment.nix` via `home.sessionPath`; `config.fish` only keeps MANPATH/INFOPATH setup that needs prepend semantics

### Git Configuration

Uses structured `settings` attribute (new format as of home-manager updates):
- `programs.git.settings.*` instead of `programs.git.extraConfig`
- SSH signing with local key configured
- Delta pager with auto light/dark detection

### Homebrew Integration

- `onActivation.cleanup = "none"` avoids destructive Homebrew cleanup during every activation
- Run `brew bundle cleanup --force` manually when you intentionally want to remove unmanaged formulae/casks/apps
- Requires Mac App Store login for MAS apps
- Activation script warns if not signed in
- `onActivation.autoUpdate = false; upgrade = false;` — switch materializes declarations only, never upgrades; `make brew-upgrade` is the explicit, separate step

### Determinate Nix Installer

This config uses the Determinate Nix installer with its official nix-darwin module:
- `determinate` flake input from FlakeHub
- `inputs.determinate.darwinModules.default` added in `lib/mksystem.nix`
- `nix.enable = false` in machine config (Determinate manages Nix daemon)
- `determinateNix.customSettings` for cache configuration (writes to `/etc/nix/nix.custom.conf`)
- `ids.gids.nixbld = 30000` for compatibility

**Note**: Do NOT use `nix.settings` for caches when `nix.enable = false` — those settings are ignored. Use `determinateNix.customSettings` instead.

### Known nixpkgs breakage

- `direnv` currently fails to build under this repo's pinned nixpkgs-unstable
  (nixpkgs #503298, Go 1.26 cgo linkmode bug) — `programs.direnv` is
  commented out in `home/programs.nix` for this reason, not by oversight.
  Verify `make build` passes before re-enabling.

## Workflow

**Always commit before `make switch`.** The switch can modify working tree state (Homebrew cleanup, activation scripts), making it hard to separate your intended changes from switch side effects. Commit first so you have a clean rollback point.

```bash
git add -A && git commit -m "description" && make switch
```

## Testing Changes

1. Build first: `make build` (validates syntax, doesn't activate — this is the hard gate for any structural change)
2. Test: `make test` (activates temporarily)
3. Apply: commit, then `make switch` (activates and makes default)

`make switch` is offline and rollback-complete (see README §The two clocks)
— it should never need retrying for network reasons. If it does, something
regressed back into activation.

## Development Notes

- All configurations are managed in git — no manual file editing outside this repo
- Fish is the primary shell; zsh is enabled for macOS compatibility
- Public repo: nothing personal (account IDs, private automation) belongs
  here — see README §Public/private seam. That goes in the private `home-ops`
  flake input instead.
