# nix-config

Every machine I run, declared in one flake: a MacBook (the workstation), a
headless Mac mini called Sietch (the server), and disposable Linux boxes that
come with a coding agent. What ties them together is a shared
[Beads](https://github.com/gastownhall/beads) board, the issue tracker that I
and every agent read and write:

```
MacBook                                    Sietch
nix-darwin + home-manager                  nix-darwin + home-manager

  bd ──────────── tailnet ──────────▶ tailscale serve :3307
                                              │
                                              ▼
agent box (any Linux)                 dolt sql-server 127.0.0.1:3307
standalone home-manager                       (the Beads board)
                                              ▲
  bd ─▶ 127.0.0.1:3307 ─▶ agent-net ──────────┘
                          (userspace tailscaled + tailscale nc)
```

The rest of this file is the handful of rules that keep the flake honest, each
with the file that enforces it.

## A host is its import list

Four directories, each answering one question:

```
pkgs/      what this repo builds: one overlay, each package as pkgs.<name>
modules/   what a machine can have (darwin/ for the OS, home/ for the user)
hosts/     what each machine has: identity plus import lists
lib/       how a host file becomes a system (mkDarwin, mkHome)
```

Follow Beads through it:

1. [`pkgs/beads.nix`](pkgs/beads.nix) pins bd 1.3.1 from upstream's release
   archives for the three platforms. There is one pin because a newer bd
   migrates the board's schema, after which older clients refuse it; every
   client therefore moves at once.
2. [`modules/home/beads-client.nix`](modules/home/beads-client.nix) wraps that
   bd with a profile pointing at Sietch's board.
3. [`hosts/agent.nix`](hosts/agent.nix) imports it, plus
   [`agent-net`](modules/home/agent/tailscaled.nix) to reach Sietch, and
   nothing else. [`hosts/sietch.nix`](hosts/sietch.nix) imports
   [`beads-server.nix`](modules/home/beads-server.nix) instead.

A host gets a capability by importing its module; there are no enable flags.
An option exists only where one shape repeats with different values:
`services.background` (a job launchd keeps running), `services.tailscale-forward`
(a loopback service published to the tailnet), and
`programs.beads-client.server` (an agent box points bd at its local forward).

## One owner per tool, and the owner sets the clock

The question for any tool is who updates it, and when:

| Owner | What it owns | When it changes |
|---|---|---|
| Nix (the default) | CLI tools: [`packages.nix`](modules/home/workstation/packages.nix), [`pkgs/`](pkgs) | at a switch, against the lock |
| Homebrew | GUI and App Store apps, and formulae nixpkgs lacks: [`workstation.nix`](modules/darwin/workstation.nix) | at `make brew-upgrade` |
| The vendor | tools that ship daily and that nothing builds against (claude, amp, pi) | by their own updater, in `~/.local/bin` |

The lock itself moves weekly: [`nix-flake-bump`](pkgs/nix-flake-bump.nix)
commits a new `flake.lock` only if both Macs still build against it.
A project's toolchain is none of these; it lives in that project's flake
`devShells`, loaded by direnv.

`PATH` has one entry per owner, in this order: `/opt/homebrew/bin`,
`~/.local/bin`, then the Nix profile
([`environment.nix`](modules/home/workstation/environment.nix)). A tool
installed by two owners would be silently shadowed by the earlier one, so no
tool has two. Homebrew runs with `cleanup = "zap"`
([`homebrew.nix`](modules/darwin/homebrew.nix)), so an app that is not declared
is uninstalled, and declared equals installed.

## Nothing compiles

A package enters only with a cache story: nixpkgs from `cache.nixos.org`, the
agent CLIs from [llm-agents.nix](https://github.com/numtide/llm-agents.nix)'s
cache, and `pkgs/` from upstream release archives (the exception is `feed`, a
small Go build). llm-agents.nix is consumed without `inputs.nixpkgs.follows`:
building it against my nixpkgs would change every derivation hash and miss its
cache. Determinate Nix owns the daemon, so the substituters are declared in
`determinateNix.customSettings` ([`base.nix`](modules/darwin/base.nix)); a
`nix.settings` block would be ignored.

## Activation stays local

Activation runs on every switch, so the steps this repo adds to it make no
network calls and never swallow a failure: seeding herdr's `config.toml`, and
setting the Beads profile's mode. A switch whose store paths are already built
works offline, and rolling back a generation rolls back everything Nix wrote.
Homebrew is the one networked step: activation installs a declared app that is
missing, but never upgrades one.

## Who writes a file decides where it lives

Nix owns every binary; a config file falls into one of three classes. Intent
the app only reads is a store symlink. A file the app rewrites, or that I
iterate on, lives in a git working tree and is linked there with
`mkOutOfStoreSymlink` (the Neovim tree in `home-ops`). A file the app writes at
runtime is seeded once and then left to the app (herdr's `config.toml`).

## One secret, one reader

sops-nix decrypts [`secrets/secrets.yaml`](secrets/secrets.yaml) at activation
into one 0600 file per consumer (`restic.env`, `telegram.env`, `discord.env`;
[`secrets.nix`](modules/home/workstation/secrets.nix)). Nothing is exported into
the shell, where every process, every agent included, would inherit it. Agent
boxes decrypt nothing; their one credential is the Tailscale node key they
enroll with.

## Public and private

Anything personal rather than structural (account IDs, private automation, the
runtime layer that watches the machines) lives in a private flake input,
`home-ops`. Nix fetches an input only when an output reads it, and the agent
output never does, so anyone can build it;
[CI](.github/workflows/agent.yml) runs `nix run .#agent` on fresh x86_64 and
aarch64 Ubuntu runners on every push. Sietch's tailnet name and port are public
on purpose ([`lib/facts.nix`](lib/facts.nix)): the tailnet's access policy, not
obscurity, decides who reaches them.

## Bringing up a machine

An agent box needs Nix and a Tailscale auth key (reusable, ephemeral, tagged
`tag:beads-client`):

```bash
curl -fsSL https://install.determinate.systems/nix | sh -s -- install --no-confirm
nix run github:odysseus0/nix-config#agent
agent-net up --auth-key=tskey-auth-...
bd ready
```

`agent-net up` is idempotent: with state left from an earlier run, the node
resumes without a key. Nothing supervises `tailscaled`, so rerun it after a
restart.

A Mac needs Determinate Nix, a GitHub token for `home-ops`
(`access-tokens = github.com=<token>` in `nix.conf`), and the caches above
seeded into `/etc/nix/nix.custom.conf` before the first build. The first
switch runs the darwin-rebuild it just built:

```bash
git clone https://github.com/odysseus0/nix-config ~/nix-config && cd ~/nix-config
make build && sudo ./result/sw/bin/darwin-rebuild switch --flake .#macbook-m4-max
```

After that, `make` activates the home layer without sudo, `make switch` the
whole system, and `make help` lists the rest.

## Credits

[mitchellh/nixos-config](https://github.com/mitchellh/nixos-config) is where
this started; its split between the machine and the user survives as
`modules/darwin` and `modules/home`. Built on
[nix-darwin](https://github.com/nix-darwin/nix-darwin),
[home-manager](https://github.com/nix-community/home-manager) and
[sops-nix](https://github.com/Mic92/sops-nix).

## License

[MIT](LICENSE).
