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
  home.file.".local/bin/nix-flake-bump" = {
    executable = true;
    text = ''
      #!/bin/bash
      set -uo pipefail
      export PATH=/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/usr/bin:/bin
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
      if nix build --no-link ".#darwinConfigurations.macbook-m4-max.system"; then
        git add flake.lock
        git commit -m "flake.lock: monthly input bump (build-verified)"
        git push || echo "push failed — commit is local"
        echo "bumped and committed; run 'make switch' to apply"
      else
        echo "BUILD FAILED against new inputs — reverting lock"
        git checkout -- flake.lock
        exit 1
      fi
    '';
  };

  launchd.agents.nix-flake-bump = {
    enable = true;
    config = {
      Label = "com.user.nix-flake-bump";
      ProgramArguments = [ "${config.home.homeDirectory}/.local/bin/nix-flake-bump" ];
      StartCalendarInterval = [{ Day = 1; Hour = 9; Minute = 0; }];
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/nix-flake-bump.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/nix-flake-bump.error.log";
    };
  };

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

  # Chatlog - WeChat chat history sync
  # Secrets: sops-nix → secrets/secrets.yaml (chatlog-data-key, chatlog-img-key)
  # Config + the (superseded, disabled) old launchd.agents.chatlog now live
  # in the private `home-ops` flake input's chatlog module — both embedded
  # the WeChat account id and its Tencent-app container path, which this
  # public repo must not contain. See users/tengjizhang/home-manager.nix
  # (inputs.home-ops.homeManagerModules.chatlog) and home-ops/README.md
  # "chatlog". The live agent is launchd.agents.chatlog-sync (Label
  # com.runtime.chatlog-sync), generated from that repo's
  # runtime/registry.toml [entries.chatlog-sync.exec] block — registered,
  # not hand-declared, and watched by the runtime layer.
  # Query: sqlite3 ~/.wechat/wechat.db "..."

  # Prune meeting audio files older than 30 days.
  # Audio Hijack writes two-track recordings here; transcripts land in vault inbox.
  # Audio kept as a regenerate-from-source safety net; vault keeps only text.
  launchd.agents.prune-meeting-recordings = {
    enable = true;
    config = {
      Label = "com.user.prune-meeting-recordings";
      ProgramArguments = [
        "/usr/bin/find"
        "${config.home.homeDirectory}/Recordings/meetings"
        "-mindepth"
        "1"
        "-type"
        "f"
        "-mtime"
        "+30"
        "-delete"
      ];
      StartCalendarInterval = {
        Hour = 3;
        Minute = 0;
      };
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/prune-meeting-recordings.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/prune-meeting-recordings.error.log";
    };
  };
}
