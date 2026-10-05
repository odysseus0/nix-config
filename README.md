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

This file holds what no single file can: the shape of the tree and the rules
that hold across it. The reason for any one line is a comment beside it.

## A host is its import list

```
pkgs/      what this repo builds: one overlay, each package as pkgs.<name>
modules/   what a machine can have (darwin/ for the OS, home/ for the user)
hosts/     what each machine has: identity plus import lists
lib/       how a host file becomes a system
```

A host gets a capability by importing its module, never by an enable flag.
Beads shows the path: [`pkgs/beads.nix`](pkgs/beads.nix) pins bd,
[`modules/home/beads-client.nix`](modules/home/beads-client.nix) points it at
Sietch's board, and [`hosts/agent.nix`](hosts/agent.nix) imports that module
and [`agent-net`](modules/home/agent/tailscaled.nix), and nothing else. An
option exists only where one shape repeats with different values, as
[`services.background`](modules/home/background.nix) does for every job
launchd keeps running.

## Everything on a machine has one owner

A tool's owner decides when it changes:

| Owner | Declared in | Changes |
|---|---|---|
| Nix | [`packages.nix`](modules/home/workstation/packages.nix), [`pkgs/`](pkgs) | at a switch, to what `flake.lock` pins; the lock moves weekly, and only if both Macs build against it ([`nix-flake-bump`](pkgs/nix-flake-bump.nix)) |
| Homebrew | [`workstation.nix`](modules/darwin/workstation.nix): apps, and formulae nixpkgs lacks | at `make brew-upgrade`; a switch installs what is declared and removes the rest |
| The vendor | nothing: its installer writes `~/.local/bin` | by its own updater (claude, amp, pi) |
| A project | that project's flake `devShells` | with the project |

`PATH` has one entry per owner
([`environment.nix`](modules/home/workstation/environment.nix)), so a tool with
two owners would be silently shadowed; none has two.

A config file's owner is whoever writes it. A file the app only reads is a
store symlink. A file the app rewrites, or that I iterate on, is linked out of
the store into a git working tree (the Neovim config, in `home-ops`). A file
the app writes at runtime is seeded once and then left to it (herdr's
`config.toml`).

A secret's owner is its one reader: sops-nix decrypts
[`secrets/secrets.yaml`](secrets/secrets.yaml) into one 0600 file per consumer
([`secrets.nix`](modules/home/workstation/secrets.nix)). Nothing is exported
into the shell, where every process, every agent included, would inherit it.

## A switch builds nothing heavy, and stays local

Packages come from caches: nixpkgs from `cache.nixos.org`, the agent CLIs from
[llm-agents.nix](https://github.com/numtide/llm-agents.nix)'s, and `pkgs/`
from upstream release archives. What is built locally is small: config
files, shell wrappers, and `feed`, a Go module. A switch that compiled Rust or C++ would take
minutes where a download takes seconds.

Activation runs on every switch, so it makes no network calls and never
swallows a failure. With the store paths built, a switch works offline, and
rolling back a generation rolls back everything Nix wrote. Homebrew is the one
exception, as its row above says.

## Public and private

Anything personal rather than structural (account IDs, private automation, the
runtime layer that watches the machines) lives in a private flake input,
`home-ops`. Nix fetches an input only when an output reads it, and the agent
output never does, so anyone can build it:
[CI](.github/workflows/agent.yml) runs `nix run .#agent` on fresh x86_64 and
aarch64 Ubuntu runners for every push to main and every pull request.

## Bringing up a machine

An agent box needs Nix and a Tailscale auth key (reusable, ephemeral, tagged
`tag:beads-client`):

```bash
curl -fsSL https://install.determinate.systems/nix | sh -s -- install --no-confirm
nix run github:odysseus0/nix-config#agent
agent-net up --auth-key=tskey-auth-...
bd ready
```

After a reboot, run `agent-net up` again; it needs no key the second time.

A Mac needs Determinate Nix, read access to `home-ops` (a GitHub token as
`access-tokens = github.com=<token>` in `nix.conf`, or on Sietch the clone the
[Makefile](Makefile) reads), and the substituters from
[`base.nix`](modules/darwin/base.nix) written into `/etc/nix/nix.custom.conf`,
followed by `sudo launchctl kickstart -k system/systems.determinate.nix-daemon`
(without them, the first build compiles the agent CLIs). The MacBook also
needs its age key, derived as [`secrets.nix`](modules/home/workstation/secrets.nix)
shows. The first switch runs the `darwin-rebuild` it just built:

```bash
git clone https://github.com/odysseus0/nix-config ~/nix-config && cd ~/nix-config
make build && sudo ./result/sw/bin/darwin-rebuild switch --flake .#macbook-m4-max
```

From then on, `make` activates the home layer without sudo, `make switch` the
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
