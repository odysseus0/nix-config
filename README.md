# nix-config

My machines, version-controlled: two Macs under nix-darwin and home-manager,
and disposable Linux agent boxes under standalone home-manager, all from one
flake.

## Quick reference

```bash
make              # = make home-switch: activate the home layer, no sudo
make switch       # build and activate the whole system (offline, rollback-complete)
make build        # build only: the gate for any structural change
make update       # bump every flake input
make brew-upgrade # upgrade Homebrew apps (never part of a switch)

nix run github:odysseus0/nix-config#agent   # on an agent box
```

## The kernel

A build is a pure function of its inputs, stored under a hash of those
inputs. Same lock, same result, on any machine. Everything below exists to
keep that property true in practice: pinned inputs, no network in
activation, nothing that compiles for minutes when a cache could serve it.

## Layout

Four directories, each answering one question:

```
pkgs/      what this repo builds: one overlay, every package as pkgs.<name>
modules/   what a machine can have
  darwin/    base, account, homebrew, workstation, server
  home/      core (shell), workstation/*, sietch/*, beads-server,
             beads-client, agent/, background, tailscale-forward, identity
hosts/     what each machine has: identity plus import lists
lib/       how hosts are assembled (mkDarwin, mkHome) and facts declared once
```

A host is a list of modules. Importing a module is how a host gets it;
there are no role suffixes and no enable flags. Options exist only where a
shape repeats with different values: `services.background` (a kept-alive
user job), `services.tailscale-forward` (a loopback service published to the
tailnet), `programs.beads-client.server`. Inputs and `lib/facts.nix` reach
every module as `specialArgs`.

## Machines

| Output | Machine | Job |
|---|---|---|
| `darwinConfigurations.macbook-m4-max` | MacBook Pro | the workstation: shell, editor, CLI tools, GUI apps, secrets, the private home-ops jobs |
| `darwinConfigurations.sietch` | Mac mini, headless | the shared Beads Dolt authority, Fleet MDM, the vault event store, the X jobs, an agent host |
| `homeConfigurations.agent-<system>` | disposable Linux | a pinned `bd` pointed at Sietch's board, and Tailscale to reach it |

The Makefile picks the darwin output from the host's LocalHostName; override
with `make NIXNAME=<output> ...`. Sietch reads `home-ops` from its own clone
(`~/home-ops`, read-only deploy key), so it needs no GitHub token.

### Agent boxes

`hosts/agent.nix` imports two modules: `modules/home/beads-client.nix` (bd
from the upstream release archive, with the shared-board profile) and
`modules/home/agent/tailscaled.nix` (`agent-net`: `tailscaled` in userspace
mode plus a local forward to Sietch's Dolt). It reads nothing from
`home-ops`, so it builds without private-repo access.

```bash
# Nix first, if the image lacks it:
curl -fsSL https://install.determinate.systems/nix | sh -s -- install --no-confirm
nix run github:odysseus0/nix-config#agent
agent-net up --auth-key=tskey-auth-...   # reusable, ephemeral, tag:beads-client
bd ready
```

`agent-net up` is idempotent: with Tailscale state left from an earlier run
the node resumes and needs no key. Nothing supervises `tailscaled`; rerun
`agent-net up` after a restart. CI (`.github/workflows/agent.yml`) runs the
same `nix run .#agent` on fresh Ubuntu runners for both architectures.

## Two tiers

The question for any tool is who updates it, and on whose clock.

| Tier | Who updates it | Where |
|---|---|---|
| **Store-owned** (default) | Nix, at a switch | `modules/home/workstation/packages.nix`, `pkgs/` |
| **Vendor-owned** | the tool's own installer and updater | `~/.local/bin` (claude, amp, pi) |

Store-owned is the default; a vendor-owned tool carries its reason (it ships
daily and nothing builds against it). The global profile holds only what
you would use in a directory with no project. A project's toolchain lives in
its own flake `devShells`, entered by direnv + nix-direnv; a one-off is
`nix run nixpkgs#<tool>`. GUI and App Store apps go through nix-darwin's
Homebrew module with `cleanup = "zap"`, so declared equals installed.

PATH is the tier list: `/opt/homebrew/bin`, `~/.local/bin`, then the Nix
profile, and nothing else (`modules/home/workstation/environment.nix`).
`~/.local/bin` precedes the profile, so never install a tool in both
tiers: the Nix copy would be silently shadowed.

## The clocks

- **`make switch` / `make home-switch`** apply what the flake and its lock
  declare. Activation makes no network calls and has no `|| true`
  soft-fails, so a switch works offline and a rollback rolls back
  everything.
- **The weekly bump** (`pkgs/nix-flake-bump.nix`, scheduled from home-ops'
  runtime registry) updates the lock, commits it only if both Macs still
  build, then activates the MacBook's home layer.
- **`make brew-upgrade`** is the only thing that upgrades Homebrew apps.
- Vendor-owned tools update themselves.

## Config ownership

Nix owns a tool's binary; its config is one of three classes. Authored
intent the app only reads is a store symlink. A file the app rewrites, or
that you iterate on, lives in a repo and is linked with
`mkOutOfStoreSymlink` to the working tree (the Neovim tree in home-ops). A
file the app writes at runtime is seeded once and then left to the app
(herdr's `config.toml`). Derived or secret state is app-owned and ignored.

## Secrets

sops-nix decrypts `secrets/secrets.yaml` at activation. One secret, one
reader: each consumer gets its own 0600 file (`restic.env`, `telegram.env`,
`discord.env`), and nothing is exported into the shell environment, where
every process would inherit it. Agent boxes hold no secrets.

## Public/private seam

This repo is public. Anything personal rather than structural (account IDs,
personal automation, the runtime layer that watches the machines) lives in
the private `home-ops` flake input. Nix fetches an input only when something
reads it, so the agent output evaluates without `home-ops`.

## Binary caches

`cache.nixos.org`, `nix-community.cachix.org` and `cache.numtide.com`
(llm-agents.nix), declared through `determinateNix.customSettings` in
`modules/darwin/base.nix`. Determinate Nix manages the daemon
(`nix.enable = false`), so `nix.settings` would be ignored. Packages this
repo builds itself (`pkgs/`) unpack upstream release archives rather than
compile.

## Fresh install (Mac)

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
git clone https://github.com/odysseus0/nix-config.git ~/nix-config
cd ~/nix-config && make switch
```

## Inspiration

- [mitchellh/nixos-config](https://github.com/mitchellh/nixos-config): where
  this started; its machine/user split survives as `modules/darwin` versus
  `modules/home`
- [nix-darwin](https://github.com/nix-darwin/nix-darwin),
  [home-manager](https://github.com/nix-community/home-manager)
- [numtide/llm-agents.nix](https://github.com/numtide/llm-agents.nix)

## License

MIT
