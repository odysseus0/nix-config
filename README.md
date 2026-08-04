# nix-config

My entire computing environment, version-controlled. Declarative macOS using nix-darwin and home-manager.

## Quick Reference

```bash
make switch       # Apply configuration changes (offline, rollback-complete)
make update       # Update flake inputs
make update-tools # Reconcile manifest-owned tools (uv) to their manifest
make test         # Test without activating
```

## The kernel

Nix's actual contribution here is hermetic, declarative builds: given the
same inputs, you get the same output, every time, on any machine. Package
management, dev environments, dotfiles, and multi-machine consistency are all
corollaries of that one property, not separate problems this repo solves
piecemeal. Every structural choice below — the ownership tiers, the two
clocks, `make switch` staying offline — exists to keep that property intact
in practice, not just in theory.

## Ownership tiers

The organizing question for any tool in this repo is not "what machine is
this on" but "who updates this, and on whose clock." Every tool sits in
exactly one of three tiers:

| Tier | Who updates it | When | Example |
|---|---|---|---|
| **Store-owned** (default) | Nix | `make switch` | `pkgs.ripgrep`, the AI agent CLIs via `llm-agents.nix` |
| **Manifest-owned** | The domain's native executor, reconciling to a Nix-declared list | `make update-tools`, explicit | `uv tool install/uninstall` against `uvToolPackages` |
| **Vendor-owned** | The tool's own installer/updater | Whenever the vendor updates it | Vite+, grok — Nix only wires PATH |

Store-owned is the default and the preferred outcome: Nix pins the exact
binary, and the only way it changes is a deliberate `make switch`. The other
two tiers are opt-outs, and each opt-out carries a reason in the code
(unpackaged upstream, a runtime-manager design that assumes it owns Node,
etc.) plus, where applicable, a graduation trigger — the condition under
which the tool should move back to store-owned.

Manifest-owned is the middle tier, modeled on nix-darwin's own Homebrew
module: Nix declares desired state as data (a list of package names), and a
domain-appropriate executor — not `nix build` — reconciles reality to it,
including removing anything present but undeclared. `uv-tools-reconcile`
(`lib/uv-tools-reconcile.nix`, manifest at
`users/tengjizhang/home/uv-tools-manifest.nix`) is the current instance: nine
Python CLIs had drifted onto this machine outside the manifest before this
tier existed (gam7, poetry, visidata, ...); the reconciler now uninstalls
anything not on the list instead of accumulating strays forever.

## The two clocks

Before this restructure, `home.activation` scripts reached out to pnpm, uv,
and a vendor curl installer on every `make switch` — meaning "apply my
configuration" and "fetch whatever's newest from the network right now" were
the same button. That made switches non-reproducible (same repo state,
different result depending on what shipped upstream that hour), non-offline
(a switch on hotel wifi could hang or fail on an unrelated network call), and
non-rollback-complete (rolling back the Nix generation didn't roll back what
those scripts had already installed).

The fix is separating the clocks:

- **`make switch`** (the apply-config clock) touches only what's declared in
  the flake and its lock file. Activation now does zero network access and
  has zero `|| echo continuing` soft-fails — every activation script left is
  local cleanup (e.g. `removeInstallerPlannotatorCli`, deleting a stale
  installer-managed binary so the Nix profile is the command authority).
  Reproducible, offline, and a `darwin-rebuild rollback` actually rolls back
  everything.
- **`make update-tools`** (the update-tools clock) is the explicit,
  network-dependent step that reconciles manifest-owned tools. It's a
  deliberate action, not a side effect of applying config.

Vendor-owned tools sit outside both clocks by design — they update
themselves, on their own schedule, and Nix's only job is to make sure PATH
finds them.

## What this manages

- **CLI packages** — dev tools, modern CLI utilities, cloud SDKs, AI agent
  CLIs (see Ownership tiers above)
- **GUI apps** — Homebrew casks and Mac App Store apps declared in
  `darwin.nix` (Nix doesn't handle either well on macOS)
- **Shell** — Fish with plugins and custom config; nix-direnv for
  per-project environments (see Project-scope demotion candidates below)
- **Dotfiles** — git, terminal, tool configs
- **System settings** — Touch ID for sudo, shells, environment variables

## Public/private seam

This repo is public. Anything that's personal rather than structural —
account IDs, a WeChat/Telegram config, ritual automation, the runtime layer
that watches for state changes — lives in the private `home-ops` flake input
instead. If a change would require adding a personal identifier here, it
belongs in `home-ops`, not here.

## Project-scope demotion candidates

Cloud/infra CLIs (`terraform`, `pulumi`, `flyctl`, `google-cloud-sdk`,
`awscli2`, `wrangler`, `cloudflared`, `go`, `deno`) currently live in
machine-wide `home.packages`, but conceptually belong to specific projects.
The target state is per-project devShells picked up automatically via
`.envrc`, backed by `programs.direnv` + `nix-direnv` — enabled in
`home/programs.nix`, with the direnv binary pulled from nixpkgs-stable for
now (unstable's direnv hits nixpkgs #503298, a Go 1.26 cgo linkmode bug —
see that file's comment). Marked in `home/packages.nix` as pending George's
veto — not yet moved, because the actual per-project boundaries haven't
been drawn.

## Server-readiness

This machine (`machines/macbook-m4-max.nix`) is nix-darwin. A NixOS home
server is planned as a second machine under `machines/`; `lib/mksystem.nix`
already forks on `darwin ? false` and layers `machines/<name>.nix` +
`users/<user>/{darwin,nixos}.nix` + `users/<user>/home-manager.nix` to
support it without restructuring. When that machine lands, its config should
set `programs.nix-ld.enable = true;` — the vendor-owned tier ships prebuilt
Linux binaries that expect an FHS-ish dynamic linker, and nix-ld is the
standard NixOS fix (not needed on Darwin, which is why it isn't set here).

## Architecture

```
├── flake.nix                    # Flake inputs and outputs
├── lib/
│   ├── mksystem.nix             # System builder function (darwin/nixos fork)
│   └── uv-tools-reconcile.nix   # Manifest-owned tier executor
├── machines/macbook-m4-max.nix  # Machine-specific config, binary caches
└── users/tengjizhang/
    ├── darwin.nix                    # macOS system config (Homebrew, system settings)
    ├── home-manager.nix              # Module imports, home-ops wiring
    ├── home/
    │   ├── packages.nix               # CLI packages, tiered (see Ownership tiers)
    │   ├── uv-tools-manifest.nix      # Manifest-owned tier's source of truth
    │   ├── programs.nix, shell.nix, dotfiles.nix, environment.nix, services.nix, secrets.nix
    └── config.fish               # Fish shell config
```

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

5. **One-time manual steps** for tools that predate this repo's ownership of
   them, or that are vendor-owned by design — see `MIGRATION.md`.

## Binary caches

- `cache.nixos.org` — official
- `nix-community.cachix.org` — community packages
- `cache.numtide.com` — `llm-agents.nix` (store-owned AI agent CLIs), though
  those are consumed via that flake's own `packages.<system>` output rather
  than its overlay (see `flake.nix`'s comment on the `llm-agents` input for
  why — a nixpkgs version-skew issue on the overlay path)

**Determinate Nix:** uses the Determinate installer with its official
nix-darwin module for daemon management; `nix.enable = false`, so binary
cache config goes through `determinateNix.customSettings`
(`machines/macbook-m4-max.nix`), not `nix.settings`.

## Inspiration

- [mitchellh/nixos-config](https://github.com/mitchellh/nixos-config) — the
  three-layer machine/user-OS/user-home structure this repo still uses
- [nix-darwin](https://github.com/nix-darwin/nix-darwin)
- [home-manager](https://github.com/nix-community/home-manager)
- [numtide/llm-agents.nix](https://github.com/numtide/llm-agents.nix) — daily-built AI agent CLIs

## License

MIT
