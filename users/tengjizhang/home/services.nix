{ config, lib, pkgs, ... }:

{
  # The third clock: flake-input freshness. `switch` applies, `update-tools`
  # reconciles manifest-owned tools, and this bumps the pins. Without it a
  # rolling channel plus a frozen lock is the worst of both — no currency, and
  # none of a release branch's tested-as-a-set coherence. It froze for five
  # months once (2026-03-23 -> 2026-08-13) and the workarounds calcified.
  #
  # Build-gated on purpose: the lock is only committed if the whole system
  # still builds against it, so a bad upstream day reverts instead of landing.
  # Green gate then activates the home layer — see the activation block below
  # for why bump-without-activate was the defect worth fixing.
  #
  # Tools that ship faster than this clock can track do not belong here at all;
  # they belong in the vendor-owned tier (claude-code, moved 2026-08-17 — see
  # home/packages.nix). This agent is for the rest of the package set.
  home.file.".local/bin/nix-flake-bump" = {
    executable = true;
    text = ''
      #!/bin/bash
      set -uo pipefail
      export PATH=/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/usr/bin:/bin

      # launchd hands a job a 256-fd soft limit (`launchctl limit maxfiles`);
      # an interactive shell gets 1048576. `nix flake update` blows through 256
      # writing the nixpkgs packfile into ~/.cache/nix/tarball-cache and dies
      # with "Too many open files", which is why this job failed silently every
      # morning 2026-08-18 -> 09-01 while the same command by hand always
      # worked. Raise the soft limit (hard limit is unlimited) — do not remove.
      ulimit -n 65536

      REPO=${config.home.homeDirectory}/nix-config
      cd "$REPO" || exit 1

      echo "=== $(date) flake bump ==="

      # Never fight a session in progress; a dirty tree means George is mid-edit.
      if [ -n "$(git status --porcelain)" ]; then
        echo "working tree dirty — skipping"; exit 0
      fi

      git fetch --quiet origin 2>/dev/null
      nix flake update || { echo "update failed"; git checkout -- flake.lock; exit 1; }

      if git diff --quiet --exit-code flake.lock; then
        echo "no input changes"; exit 0
      fi

      echo "--- build gate ---"
      system="$(nix build --no-link --print-out-paths ".#darwinConfigurations.macbook-m4-max.system")" || {
        echo "BUILD FAILED against new inputs — reverting lock"
        git checkout -- flake.lock
        exit 1
      }

      git add flake.lock
      git commit -m "flake.lock: daily input bump (build-verified)"
      git push || echo "push failed — commit is local"

      # Bumping without activating was the old defect: the lock moved daily and
      # the binaries never did, so currency lived in git and nowhere else.
      # Activate the home layer here — it is sudo-free and it is where the
      # fast-moving CLI tools live. Same evaluation as `make home-switch`, so
      # there is still no second profile.
      echo "--- activating home layer ---"
      if generation="$(nix build --no-link --print-out-paths ".#darwinConfigurations.macbook-m4-max.config.home-manager.users.${config.home.username}.home.activationPackage")" \
         && "$generation/activate"; then
        echo "home layer activated"
      else
        echo "home activation failed — the commit stands; run 'make home-switch' by hand"
      fi

      # The system layer needs sudo, so it stays a supervised boundary (see
      # README §The two clocks). Say when it has drifted rather than leaving
      # the two layers silently skewed.
      if [ "$system" != "$(readlink -f /run/current-system)" ]; then
        echo "system layer changed — run 'make switch' when convenient"
      fi
    '';
  };

  # Machine jobs are declared in home-ops/runtime/registry.toml, not here — the
  # registry generates launchd.agents.<id> (runtime.nix) AND is what the observe
  # loop diffs against, so a job declared directly in this file runs unwatched.
  # nix-flake-bump and prune-meeting-recordings moved there 2026-08-17.

  # CLIProxyAPI - proxy so Amp can use Claude/Gemini/Codex via CLI OAuth sessions
  # Binary from Homebrew until a maintained Nix package exists. When moving it,
  # replace /opt/homebrew/bin/cliproxyapi and remove "cliproxyapi" from
  # darwin.nix brews in the same change.

  launchd.agents.cliproxyapi = {
    enable = true;
    config = {
      Label = "com.cliproxyapi";
      ProgramArguments = [
        "/opt/homebrew/bin/cliproxyapi"
        "-config"
        "${config.home.homeDirectory}/.cli-proxy-api/config.yaml"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/cliproxyapi.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/cliproxyapi.error.log";
    };
  };

  # WeChat history: no launchd agent since 2026-09-18. `wx-cli` (hand-built
  # at ~/.local/bin/wx from ~/projects/wx-cli) reads the encrypted WeChat
  # DBs on demand through its own daemon; its config is app-owned in
  # ~/.wx-cli. The sops secret `chatlog-data-key` is the master key the
  # per-shard wx keys derive from — see the vault skill .agents/skills/wechat.

}
