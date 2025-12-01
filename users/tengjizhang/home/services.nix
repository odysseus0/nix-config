{ config, lib, pkgs, ... }:

{
  # Chatlog - WeChat chat history export tool
  # Runs as a background HTTP server on localhost:5030
  launchd.agents.chatlog = {
    enable = true;
    config = {
      Label = "com.chatlog.server";
      ProgramArguments = [
        "${config.home.homeDirectory}/go/bin/chatlog"
        "server"
        "--auto-decrypt"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/chatlog.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/chatlog.error.log";
    };
  };
}
