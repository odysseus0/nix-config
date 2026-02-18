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

  # Write cliproxyapi config with ampcode token from 1Password.
  # Secret: 1Password → "cliproxyapi" (Password item, password = ampcode Access Token)
  home.activation.cliproxyapiConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if command -v op &> /dev/null; then
      mkdir -p ~/.cli-proxy-api
      AMPCODE_TOKEN=$(op read "op://Personal/cliproxyapi/password" --account=my.1password.com 2>/dev/null)
      if [ -n "$AMPCODE_TOKEN" ]; then
        cat > ~/.cli-proxy-api/config.yaml << 'YAMLEOF'
# CLIProxyAPI config - managed by Nix activation script
# Edit users/tengjizhang/home/services.nix to change this file.

host: ""
port: 8317
auth-dir: "~/.cli-proxy-api"
api-keys:
  - "amp-local-proxy-key"

routing:
  strategy: "round-robin"

quota-exceeded:
  switch-project: true
  switch-preview-model: true

request-retry: 3
max-retry-interval: 30

ampcode:
  upstream-url: "https://ampcode.com"
  upstream-api-key: "AMPCODE_TOKEN_PLACEHOLDER"
  restrict-management-to-localhost: true
YAMLEOF
        /usr/bin/sed -i "" "s|AMPCODE_TOKEN_PLACEHOLDER|$AMPCODE_TOKEN|" ~/.cli-proxy-api/config.yaml
        echo "✓ cliproxyapi: config written from 1Password"
      else
        echo "⚠ cliproxyapi: could not read token from 1Password (auth needed?)"
      fi
    fi
  '';

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
  # Secrets: 1Password → "chatlog-server.json" (Secure Note)
  # API:     http://localhost:5030

  home.activation.chatlog-config = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if command -v op &> /dev/null; then
      mkdir -p ~/.chatlog
      op read "op://Personal/chatlog-server.json/notesPlain" --account=my.1password.com > ~/.chatlog/chatlog-server.json 2>/dev/null \
        && echo "✓ chatlog config synced from 1Password" \
        || echo "⚠ chatlog config sync failed (1Password auth needed?)"
    fi
  '';

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
