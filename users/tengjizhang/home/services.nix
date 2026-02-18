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
  # Binary from Homebrew (hybrid) until Nix package lands:
  # → https://github.com/numtide/llm-agents.nix/pull/2622
  # Once merged: replace /opt/homebrew/bin/cliproxyapi with ${llmAgents.cli-proxy-api}/bin/cli-proxy-api
  # and remove "cliproxyapi" from darwin.nix brews.

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

  # Chatlog - WeChat chat history export tool
  # Secrets: sops-nix → secrets/secrets.yaml (chatlog-data-key, chatlog-img-key)
  # Config written to ~/.chatlog/chatlog-server.json via sops template in secrets.nix
  # API:     http://localhost:5030

  launchd.agents.chatlog = {
    enable = true;
    config = {
      Label = "com.chatlog.server";
      ProgramArguments = [ "${config.home.homeDirectory}/go/bin/chatlog" "server" ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/chatlog.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/chatlog.error.log";
    };
  };
}
