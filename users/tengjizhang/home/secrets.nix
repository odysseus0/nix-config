{ config, ... }:

{
  # sops-nix: secrets encrypted in git, decrypted at activation via age key.
  # To add/edit secrets: sops ~/nix-config/secrets/secrets.yaml
  # To re-encrypt after key rotation: sops updatekeys secrets/secrets.yaml
  #
  # Bootstrap (one-time, after restoring ~/.ssh/id_ed25519 from 1Password):
  #   mkdir -p ~/.config/sops/age
  #   ssh-to-age --private-key -i ~/.ssh/id_ed25519 -o ~/.config/sops/age/keys.txt
  #   chmod 600 ~/.config/sops/age/keys.txt

  home.sessionVariablesExtra = ''
    source ${config.sops.templates."session-secrets.sh".path}
  '';

  sops = {
    defaultSopsFile = ../../../secrets/secrets.yaml;
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

    secrets."cliproxyapi-upstream-api-key" = {};
    secrets."chatlog-data-key" = {};
    secrets."chatlog-img-key" = {};
    secrets."tg-app-id" = {};
    secrets."tg-app-hash" = {};
    secrets."discord-user-token" = {};
    secrets."discord-bot-token" = {};
    secrets."linear-api-key" = {};
    secrets."trace-archive-r2-access-key-id" = {};
    secrets."trace-archive-r2-secret-access-key" = {};
    secrets."trace-archive-r2-crypt-password" = {};
    secrets."trace-archive-r2-crypt-salt" = {};

    # Shell environment variables — sourced by all shells via home.sessionVariablesExtra.
    # home-manager runs hm-session-vars.sh through babelfish for fish, sources directly for zsh.
    templates."session-secrets.sh".content = ''
      export TG_APP_ID="${config.sops.placeholder."tg-app-id"}"
      export TG_APP_HASH="${config.sops.placeholder."tg-app-hash"}"
      export DISCORD_TOKEN="${config.sops.placeholder."discord-user-token"}"
      export DISCORD_BOT_TOKEN="${config.sops.placeholder."discord-bot-token"}"
      export LINEAR_API_KEY="${config.sops.placeholder."linear-api-key"}"
    '';

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

    # trace-archive-r2.env — machine-tier R2 credentials for the
    # trace-archive-sync launchd job (home-ops/trace-archive/bin/sync.sh).
    # Migrated 2026-07-20 from op-at-runtime per the runtime-layer design
    # doc's "same-day amendments" secrets-tiering note: an unattended
    # scheduled run must not depend on the 1Password app being unlocked.
    # No account-identifying content here (unlike chatlog-server.json), so
    # this stays entirely in the public nix-config tree — only the
    # *encrypted values* are sensitive, and sops handles that. sync.sh
    # sources this file when present and falls back to `op read` otherwise
    # (dual-path until one green scheduled run confirms the sops path,
    # then the op fallback is deleted).
    templates."trace-archive-r2.env" = {
      path = "${config.home.homeDirectory}/.config/trace-archive/r2.env";
      content = ''
        export RCLONE_CONFIG_TRACES_ACCESS_KEY_ID="${config.sops.placeholder."trace-archive-r2-access-key-id"}"
        export RCLONE_CONFIG_TRACES_SECRET_ACCESS_KEY="${config.sops.placeholder."trace-archive-r2-secret-access-key"}"
        export TRACE_ARCHIVE_CRYPT_PASSWORD="${config.sops.placeholder."trace-archive-r2-crypt-password"}"
        export TRACE_ARCHIVE_CRYPT_SALT="${config.sops.placeholder."trace-archive-r2-crypt-salt"}"
      '';
    };

    # chatlog-server.json (WeChat account id + these two secrets' placeholders)
    # is rendered by the private `home-ops` flake input's chatlog module now —
    # see users/tengjizhang/home-manager.nix and home-ops/README.md "chatlog".
    # The secret *declarations* above (chatlog-data-key, chatlog-img-key)
    # stay here: names aren't sensitive, and sops-nix's placeholder
    # substitution works across the merged config tree regardless of which
    # module declares the `sops.templates` entry that consumes them.
  };
}
