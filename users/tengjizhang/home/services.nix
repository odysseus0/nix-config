{ config, lib, pkgs, ... }:

{
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
