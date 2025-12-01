{ config, lib, pkgs, ... }:

{
  # Chatlog - WeChat chat history export tool
  # https://github.com/sjzar/chatlog (original, taken down by Tencent)
  # https://github.com/imldy/chatlog (active fork)
  #
  # Requires WeChat 4.0.3.80 - newer versions have incompatible DB schema
  # See darwin.nix masApps section for WeChat version pinning details
  #
  # Runs as a background HTTP server on localhost:5030
  # Config file: ~/.chatlog/chatlog-server.json (not managed by nix - contains keys)
  launchd.agents.chatlog = {
    enable = true;
    config = {
      Label = "com.chatlog.server";
      ProgramArguments = [
        "${config.home.homeDirectory}/go/bin/chatlog"
        "server"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/chatlog.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/chatlog.error.log";
    };
  };
}
