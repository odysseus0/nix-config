{ config, ... }:

{
  # sops-nix: secrets encrypted in git, decrypted at activation using SSH key.
  # To add a new secret: sops secrets/secrets.yaml (opens $EDITOR)
  # To re-encrypt after key rotation: sops updatekeys secrets/secrets.yaml
  sops = {
    defaultSopsFile = ../../../secrets/secrets.yaml;

    # Use existing SSH key as age identity — no separate key to manage.
    age.sshKeyPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];

    secrets."cliproxyapi-upstream-api-key" = {};
    secrets."chatlog-data-key" = {};
    secrets."chatlog-img-key" = {};

    templates."cliproxyapi-config.yaml" = {
      path = "${config.home.homeDirectory}/.cli-proxy-api/config.yaml";
      content = ''
        # CLIProxyAPI config — managed by sops-nix (secrets.nix)
        # Edit users/tengjizhang/home/secrets.nix to change this file.

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
          upstream-api-key: "${config.sops.placeholder."cliproxyapi-upstream-api-key"}"
          restrict-management-to-localhost: true
      '';
    };

    templates."chatlog-server.json" = {
      path = "${config.home.homeDirectory}/.chatlog/chatlog-server.json";
      content = ''
        {
          "type": "wechat",
          "platform": "darwin",
          "version": 4,
          "full_version": "4.0.3.80",
          "data_dir": "/Users/tengjizhang/Library/Containers/com.tencent.xinWeChat/Data/Documents/xwechat_files/wxid_a04dcz671ota11_2af6",
          "data_key": "${config.sops.placeholder."chatlog-data-key"}",
          "img_key": "${config.sops.placeholder."chatlog-img-key"}",
          "work_dir": "/Users/tengjizhang/.local/share/chatlog",
          "http_addr": "127.0.0.1:5030",
          "auto_decrypt": true
        }
      '';
    };
  };
}
