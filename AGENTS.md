# nix-config

For agents changing this repository. README holds the shape of the tree and
the rules that hold across files; read it before deciding where something
goes. A comment holds the reason for the line it sits on. This file holds how
to change the tree without breaking either.

## Where a fact lives

Each fact has one home, the narrowest that covers everything it is about:

| The fact is about | Its home |
|---|---|
| one line, block or file | a comment there |
| an option | its `description` and `example` |
| the whole tree, a rule across files, or bringing up a machine | README |
| how to change the tree | this file |
| what changed, and when | the commit message |

What the code already says legibly is written nowhere else: a doc names a
file, option or package as an example or to point at a reason, never to
inventory them (`make help` prints the Makefile targets). A rejected
alternative that still constrains the code is a comment where the choice is
made, as in `modules/home/sietch/ssh.nix` on Tailscale SSH; one that no longer
constrains anything is history. Moving a fact deletes the old copy in the same
commit.

## Adding things

- Pick the owner first (README). An agent CLI comes from `llmAgents.<name>`
  when llm-agents.nix packages it
  (`nix eval github:numtide/llm-agents.nix#packages.aarch64-darwin --apply builtins.attrNames`).
  A tool with no Nix packaging gets a derivation in `pkgs/` that unpacks a
  pinned release archive.
- Before adding a package, input, overlay or override, confirm a substituter
  serves it: `nix path-info --store https://<cache> <output>`, or `make build`
  printing "copying path" rather than "building". An override changes the
  derivation hash and loses the cache, so it carries its own expiry:
  `lib.throwIf (lib.versionAtLeast pkg.version "<fixed in>") "obsolete"`.
- A long-running job on Sietch is `services.background.<name>`; a loopback
  service it publishes is `services.tailscale-forward.<name>`. Everything
  Sietch declares serves its role.
- Delete config the day its consumer goes, with no tombstone.

## Proving a change

- `make build` gates any structural change; `make NIXNAME=sietch build`
  builds Sietch's output from the MacBook.
- A change meant to alter no machine (a restructure, a comment, a doc) proves
  it: the drvPaths of `darwinConfigurations.<output>.system` and
  `checks.<system>.agent` are identical before and after. The Macs evaluate
  only where `home-ops` is reachable.
- Commit before `make switch`: activation can change working-tree state, and
  a commit is the clean rollback point.

## Writing

The repository is public so that a practitioner can learn from it, and it
shows judgment only through what a reader can check. Every public surface
(README, this file, comments, commit messages, PR descriptions) is held to
that:

- **One subject each**, and nothing in it the reader would not miss.
- **Checkable.** A claim names the file or command that makes it true, and
  changes in the same commit as the code it describes.
- **Mechanism, not labels.** "Safer", "cleaner" and "hermetic" are labels;
  say what fails without the thing.
- **One name per concept**, the same in every file: the owners (Nix,
  Homebrew, the vendor, a project), the home layer and the system layer,
  Sietch, the Beads board, agent boxes.
- **Comments say why, in the present tense.** No banners that restate the
  code, no history, no credits, no narrator naming the owner.
- **A concrete example from this tree** beside each abstract rule. Diagrams
  are ASCII, so they render wherever a diff does.
- **Commits** state the change as a fact about the tree in the subject and
  say why in the body. **PR descriptions** open with Before and After.
