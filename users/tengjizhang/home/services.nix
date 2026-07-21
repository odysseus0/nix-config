{ config, lib, pkgs, ... }:

{
  # tmux-claude - Persistent tmux session for iOS remote Claude Code
  # Starts at GUI login with keychain access, so SSH can attach without auth issues
  # Termius startup: tmux attach -t claude || (cd ~/obsidian && tmux new-session -s claude)

  home.file.".local/bin/tmux-claude-start" = {
    executable = true;
    text = ''
      #!/bin/bash
      # Start tmux session for iOS remote Claude Code access
      # This script runs at GUI login to ensure keychain access

      TMUX=/run/current-system/sw/bin/tmux
      FISH=/etc/profiles/per-user/tengjizhang/bin/fish
      WORKDIR=${config.home.homeDirectory}/obsidian

      $TMUX new-session -d -s claude -c "$WORKDIR" "$FISH" && \
      sleep 1 && \
      $TMUX send-keys -t claude 'claude --dangerously-skip-permissions' Enter
    '';
  };

  launchd.agents.tmux-claude = {
    enable = true;
    config = {
      Label = "com.user.tmux-claude";
      ProgramArguments = [ "${config.home.homeDirectory}/.local/bin/tmux-claude-start" ];
      RunAtLoad = true;
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/tmux-claude.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/tmux-claude.error.log";
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
