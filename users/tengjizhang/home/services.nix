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
  # Secrets stored in 1Password: "Chatlog WeChat Keys"

  # Generate config from 1Password on activation
  home.activation.chatlog-config = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if command -v op &> /dev/null && op account list &> /dev/null; then
      $DRY_RUN_CMD mkdir -p "${config.home.homeDirectory}/.chatlog"

      DATA_KEY=$(op item get "Chatlog WeChat Keys" --account=my.1password.com --fields data_key 2>/dev/null || echo "")
      IMG_KEY=$(op item get "Chatlog WeChat Keys" --account=my.1password.com --fields img_key 2>/dev/null || echo "")
      DATA_DIR=$(op item get "Chatlog WeChat Keys" --account=my.1password.com --fields data_dir 2>/dev/null || echo "")
      WORK_DIR=$(op item get "Chatlog WeChat Keys" --account=my.1password.com --fields work_dir 2>/dev/null || echo "")

      if [ -n "$DATA_KEY" ] && [ -n "$WORK_DIR" ]; then
        $DRY_RUN_CMD cat > "${config.home.homeDirectory}/.chatlog/chatlog-server.json" << EOF
{
  "type": "wechat",
  "platform": "darwin",
  "version": 4,
  "full_version": "4.0.3.80",
  "data_dir": "$DATA_DIR",
  "data_key": "$DATA_KEY",
  "img_key": "$IMG_KEY",
  "work_dir": "$WORK_DIR",
  "http_addr": "127.0.0.1:5030",
  "auto_decrypt": true
}
EOF
        echo "✓ Generated chatlog-server.json from 1Password"
      else
        echo "⚠ Could not fetch chatlog keys from 1Password (may need to authenticate)"
      fi
    else
      echo "⚠ 1Password CLI not available, skipping chatlog config generation"
    fi
  '';

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
