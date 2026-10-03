# nix-config

Instructions for agents working in this repository. README owns the argument
(the machines, the rules and why); this file owns commands, paths and the
rules for changing the tree. Read README before deciding where a package or
module goes.

## Commands

`make help` lists the Makefile targets. The ones that gate a change:

```bash
make build        # build the whole system: the gate for any structural change
make home-build   # build the home layer only
make switch       # sudo darwin-rebuild switch
make              # activate the home layer only, no sudo
```

`NIXNAME` defaults from LocalHostName (`macbook-m4-max`, or `sietch` on
Sietch); `make NIXNAME=sietch build` builds Sietch's output from the MacBook.
On Sietch the Makefile overrides `home-ops` with `~/home-ops`. Every
evaluation is pure except the agent bootstrap's (below).

## Paths

- `flake.nix`: inputs, and outputs as a table of contents.
- `lib/default.nix`: `mkDarwin` (a Mac: overlay, unfree, Determinate,
  home-manager, the host's modules) and `mkHome` (a standalone home).
  `inputs`, `facts` and (on Macs) `user` reach every module as `specialArgs`;
  never route them through `_module.args`.
- `lib/facts.nix`: facts more than one module needs (identity, Sietch's
  tailnet name and Beads port, the board id), declared once.
- `pkgs/`: every package this repo builds, as `pkgs.<name>` through the one
  overlay (`pkgs/default.nix`).
- `hosts/<output>.nix`: identity plus import lists. `macbook-m4-max.nix` and
  `sietch.nix` give `system`, `user`, a `darwin` module list and a `home`
  module; `agent.nix` is a home module for `mkHome`.
- `modules/darwin/`: the system layer of a Mac.
- `modules/home/`: the home layer. `core` is the shell both Macs share,
  `workstation/` and `sietch/` are one host's, the rest are capabilities any
  host can import; `dotfiles/` holds raw files.

A host is its import list. Add a capability by writing a module and importing
it; add an option only when a shape repeats with different values
(`services.background`, `services.tailscale-forward`,
`programs.beads-client.server`). Never add enable flags to turn modules on.

Machines: `macbook-m4-max` (the workstation), `sietch` (headless server: the
Beads board, Fleet, the vault event store, the X jobs, an agent host) and
`homeConfigurations.agent-<system>` (disposable Linux agent boxes). Both Macs
import `home-ops` modules; Sietch reads its own clone, so it needs no GitHub
token. The agent output must never import `home-ops`: it builds without
private-repo access. Every item Sietch declares needs a reason tied to its
role.

## Adding things: pick the owner first

- **Nix (the default)**: `modules/home/workstation/packages.nix`. AI agent
  CLIs come from `llmAgents.<name>` when llm-agents.nix packages them
  (`nix eval github:numtide/llm-agents.nix#packages.aarch64-darwin --apply builtins.attrNames`).
  A tool with no Nix packaging gets a derivation in `pkgs/` that unpacks a
  pinned release archive.
- **The vendor**: nothing in Nix. Its installer puts it in `~/.local/bin`,
  which precedes the Nix profile on PATH. Never install it through Nix as
  well.
- **A project's toolchain** (cloud CLIs, language toolchains): the project's
  own flake `devShells`, not the global profile.
- **Homebrew**: GUI apps in `homebrew.casks` in `modules/darwin/workstation.nix`
  (or `server.nix` for Sietch); App Store apps in `homebrew.masApps`. Then
  `make switch`.
- **A long-running job on Sietch**: `services.background.<name>.program`;
  publish a loopback service to the tailnet with
  `services.tailscale-forward.<name> = { serve; target; }`.

## Rules

### Every package has a cache story

Compiling from source, especially Rust or C++, is a defect, not a cost.
Nothing enters this config (package, input, overlay, override) unless a
substituter serves it: check with `nix path-info --store https://<cache>
<output>`, or whether `make build` says "copying path" or "building". An
override changes the derivation hash and forfeits the cache, so one exists
only with an expiry:
`lib.throwIf (lib.versionAtLeast pkg.version "<fixed in>") "obsolete"`.

Substituters take effect only after a switch writes them to
`/etc/nix/nix.custom.conf`. On a fresh Mac, write that file by hand and
`launchctl kickstart -k system/systems.determinate.nix-daemon` before the
first build, or llm-agents packages compile from source.

### No network in activation

`home.activation.*` runs on every switch. It stays offline and never
swallows a failure (`|| echo continuing` is banned). Anything that calls a
package manager or vendor installer runs on that tool's own clock, not in
activation. The activation steps that exist are local: seeding herdr's
config, setting the Beads profile's mode.

### Determinate Nix

`nix.enable = false`; Determinate manages the daemon. Cache settings go in
`determinateNix.customSettings` (`modules/darwin/base.nix`), never
`nix.settings`, which is ignored. `ids.gids.nixbld = 30000`.

### Public repo

Nothing personal (account IDs, private automation, employer details) belongs
here; it goes in the private `home-ops` input (README §Public and private).

## Writing

This repository is public so that a practitioner can learn from it: how to run
a workstation, a server and agent boxes from one flake, and the rules that keep
it reproducible and safe for agents to change. It shows judgment only through
what a reader can check. Every public surface (README, this file, comments,
the Makefile's help, commit messages, PR descriptions) is held to that:

- **One subject each.** README explains the machines and the rules; a section,
  table row or comment stays only if a reader would understand or do something
  differently without it. An inventory the tree already shows is cut.
- **Checkable.** Every claim names the file or command that makes it true, and
  stays true: change the claim in the same commit as the code. Nothing
  aspirational, and nothing about running state that the tree cannot show.
- **Mechanism, not labels.** "Safer", "cleaner" and "hermetic" are labels.
  Say what fails without the thing, as in "building it against our nixpkgs
  would change every hash and miss the cache".
- **One name per concept**, the same in every file: the three owners (Nix,
  Homebrew, the vendor), the home layer and the system layer, Sietch, the
  Beads board, agent boxes.
- **Comments say why, in the present tense.** No banners that restate the
  code, no history (that is the commit message), no credit to a person or
  setup ("Mitchell's pattern"), no narrator naming the owner. Delete dead
  config the day its consumer goes, with no tombstone.
- **A concrete example beside each abstract step**, a real one from this tree.
  Diagrams are ASCII, so they render everywhere a diff does.
- **Commits** state the change as a fact about the tree in the subject; the
  body says why. **PR descriptions** open with Before and After.

## Workflow

Commit before `make switch`: activation can change working-tree state, and a
commit is the clean rollback point.

```bash
git add -A && git commit -m "description" && make switch
```

For a change that should not alter any machine (a restructure, a comment, a
doc), prove it: `nix eval .#darwinConfigurations.<output>.system.drvPath` and
`nix eval .#checks.<system>.agent.drvPath` before and after must print the
same paths (run where `home-ops` is reachable).

## Agent boxes

`nix run .#agent` runs `apps.agent`, a pure script whose one `nix build
--impure` evaluates `homeConfigurations.agent-<system>` with the box's `USER`
and `HOME` (`modules/home/identity.nix`), then activates it. CI
(`.github/workflows/agent.yml`) runs the same command on fresh Ubuntu runners.
`checks.<system>.agent` builds it with a fixed account.
