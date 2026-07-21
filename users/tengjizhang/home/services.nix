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
  # Config written to ~/.chatlog/chatlog-server.json via sops template in secrets.nix
  # WatchPaths triggers decrypt + normalize into ~/.wechat/wechat.db when WeChat writes new data.
  # Query: sqlite3 ~/.wechat/wechat.db "..."

  # SUPERSEDED by the runtime layer (private `runtime` flake input, see
  # flake.nix + home-manager.nix): this agent is now generated as
  # launchd.agents.chatlog-sync (Label com.runtime.chatlog-sync) from that
  # repo's registry.toml [entries.chatlog-sync.exec] block, so the job is
  # registered (not hand-declared) and watched. Disabled here rather than
  # deleted — its WatchPaths (below) shares the runtime layer's registry
  # entry verbatim, and keeping both enabled would double-run chatlog sync
  # on every WeChat write.
  launchd.agents.chatlog = {
    enable = false;
    config = {
      Label = "com.chatlog.sync";
      ProgramArguments = [ "${config.home.homeDirectory}/projects/chatlog/bin/chatlog" "sync" ];
      WatchPaths = [ "/Users/tengjizhang/Library/Containers/com.tencent.xinWeChat/Data/Documents/xwechat_files/WXID_REDACTED/db_storage/message" ];
      ThrottleInterval = 30;
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/chatlog.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/chatlog.error.log";
    };
  };

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
