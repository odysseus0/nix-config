# nix-config

Instructions for agents working in this repository. README owns the
argument (layout, tiers, clocks, seam); this file owns commands, paths and
rules. Read README before a package-placement or structural decision.

## Common commands

```bash
make              # = make home-switch: activate the home layer only, no sudo
make switch       # sudo darwin-rebuild switch --flake .#<output>
make build        # build only: the hard gate for any structural change
make test         # activate temporarily
make dry-run      # what would be fetched vs built
make update       # nix flake update (all inputs)
make update-nixpkgs
make brew-upgrade # upgrade Homebrew apps; never part of a switch
```

`NIXNAME` defaults from LocalHostName (`macbook-m4-max`, or `sietch` on
Sietch); `make NIXNAME=sietch build` builds Sietch's output from the
MacBook. On Sietch the Makefile overrides `home-ops` with `~/home-ops`.
Every evaluation is pure except the agent bootstrap's (below).

## Layout

- `flake.nix`: inputs, and outputs as a table of contents.
- `lib/default.nix`: `mkDarwin` (a Mac: overlay, unfree, Determinate,
  home-manager, the host's modules) and `mkHome` (a standalone home).
  `inputs`, `facts` and (on Macs) `user` reach every module as
  `specialArgs`; never route them through `_module.args`.
- `lib/facts.nix`: facts more than one module needs (identity, Sietch's
  tailnet name and Beads port, the board id), declared once.
- `pkgs/`: every package this repo builds, as `pkgs.<name>` through the one
  overlay (`pkgs/default.nix`): beads, dolt, feed, herdr, nix-flake-bump,
  sherlog.
- `hosts/<output>.nix`: identity plus import lists. `macbook-m4-max.nix`
  and `sietch.nix` give `system`, `user`, a `darwin` module list and a
  `home` module; `agent.nix` is a home module for `mkHome`.
- `modules/darwin/`: `base` (Determinate, caches, shells), `account` (the
  user, login shell via `users.knownUsers`), `homebrew` (zap,
  materialize-only), `workstation`, `server`.
- `modules/home/`: `core` (fish/zsh, `config.fish`, the tools they call),
  `workstation/*` (packages, programs, dotfiles, environment, secrets),
  `sietch/*`, `beads-server`, `beads-client`, `agent/tailscaled`,
  `background`, `tailscale-forward`, `identity`, `dotfiles/` (raw files).

A host is its import list. Add a capability by writing a module and
importing it; add an option only when a shape repeats with different values
(`services.background`, `services.tailscale-forward`,
`programs.beads-client.server`). Never add enable flags to turn modules on.

Machines (README §Machines): `macbook-m4-max` (workstation), `sietch`
(headless server: Beads authority, Fleet, vault events, X jobs, agent host)
and `homeConfigurations.agent-<system>` (disposable Linux agent boxes).
Both Macs import `home-ops` modules; Sietch reads its own clone, so it
needs no GitHub token. The agent output must never import `home-ops`: it
builds without private-repo access. Every item Sietch declares needs a
reason tied to its role.

## Adding things: pick the tier first

- **Store-owned (default)**: `modules/home/workstation/packages.nix`. AI
  agent CLIs come from `llmAgents.<name>` when llm-agents.nix packages them
  (`nix eval github:numtide/llm-agents.nix#packages.aarch64-darwin --apply builtins.attrNames`).
  A tool with no Nix packaging gets a derivation in `pkgs/` that unpacks a
  pinned release archive.
- **Vendor-owned**: nothing in Nix. Its installer puts it in
  `~/.local/bin`, which is already on PATH ahead of the profile. Never
  install it store-owned as well.
- **Per-project tools** (cloud CLIs, language toolchains): the project's
  own flake `devShells`, not the global profile.
- **GUI apps**: `homebrew.casks` in `modules/darwin/workstation.nix` (or
  `server.nix` for Sietch); App Store apps in `homebrew.masApps`. Then
  `make switch`.
- **A long-running job on Sietch**: `services.background.<name>.program`;
  publish a loopback service to the tailnet with
  `services.tailscale-forward.<name> = { serve; target; }`.

## Rules

### Cache-hit discipline (hard rule)

Source compilation, especially Rust or C++, is a defect, not a cost.
Nothing enters this config (package, input, overlay, override) without a
cache story: before adding, check the substituter serves it (`nix path-info
--store https://<cache> <output>`, or whether `make build` says "copying
path" or "building"). An override changes the derivation hash and forfeits
the cache, so one exists only with an expiry:
`lib.throwIf (lib.versionAtLeast pkg.version "<fixed in>") "obsolete"`.

Substituters take effect only after a switch writes them to
`/etc/nix/nix.custom.conf`. On a fresh Mac, pre-seed that file by hand and
`launchctl kickstart -k system/systems.determinate.nix-daemon` before the
first build, or llm-agents packages compile from source.

### No network in activation

`home.activation.*` runs on every switch. It stays offline and never
soft-fails (`|| echo continuing` is banned). Anything that calls out to a
package manager or vendor installer belongs to that tool's own clock, not
to activation. The activation scripts that exist are local: seeding
herdr's config, the Beads profile's mode.

### Determinate Nix

`nix.enable = false`; Determinate manages the daemon. Cache settings go in
`determinateNix.customSettings` (`modules/darwin/base.nix`), never
`nix.settings`, which is ignored. `ids.gids.nixbld = 30000`.

### Docs and comments

A comment says why, in the present tense. What changed on which date is a
commit message. Delete dead config the day its consumer goes, with no
tombstone. Every claim in README or this file must be checkable against
the tree.

### Public repo

Nothing personal (account IDs, private automation) belongs here; it goes in
the private `home-ops` input (README §Public/private seam).

## Workflow

Commit before `make switch`: activation can change working-tree state, and
a commit is the clean rollback point.

```bash
git add -A && git commit -m "description" && make switch
```

For a restructure (moving files, renaming modules), prove the Macs did not
change: `nix eval .#darwinConfigurations.<output>.system.drvPath` before and
after must print the same path (run where `home-ops` is reachable).

## Agent boxes

`nix run .#agent` runs `apps.agent`, a pure script whose one `nix build
--impure` evaluates `homeConfigurations.agent-<system>` with the box's
`USER` and `HOME` (`modules/home/identity.nix`), then activates it. CI
(`.github/workflows/agent.yml`) runs the same command on fresh Ubuntu
runners. `checks.<system>.agent` builds it with a fixed account.
