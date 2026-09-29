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

    # WeChat SQLCipher master key (pre-KDF). Sole consumer since 2026-09-18
    # is the vault wechat skill's seed-keys script, which derives wx-cli's
    # per-shard keys from it. Kept in sops as the recovery source.
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
    secrets."beads-cloudflared-tunnel-token" = {};
    secrets."restic-password" = {};

    # Shell environment variables — sourced by all shells via home.sessionVariablesExtra.
    # home-manager runs hm-session-vars.sh through babelfish for fish, sources directly for zsh.
    templates."session-secrets.sh".content = ''
      export TG_APP_ID="${config.sops.placeholder."tg-app-id"}"
      export TG_APP_HASH="${config.sops.placeholder."tg-app-hash"}"
      export DISCORD_TOKEN="${config.sops.placeholder."discord-user-token"}"
      export DISCORD_BOT_TOKEN="${config.sops.placeholder."discord-bot-token"}"
      export LINEAR_API_KEY="${config.sops.placeholder."linear-api-key"}"
    '';

    # trace-archive-r2.env — machine-tier R2 credentials for the
    # trace-archive-sync launchd job (home-ops/trace-archive/bin/sync.sh).
    # Migrated 2026-07-20 from op-at-runtime per the runtime-layer design
    # doc's "same-day amendments" secrets-tiering note: an unattended
    # scheduled run must not depend on the 1Password app being unlocked.
    # No account-identifying content here, so
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

    # restic.env — the snapshot backup to R2 (home-ops/backup/bin/restic-backup.sh).
    # Same R2 key as trace-archive; its own repository password. The repository
    # URL carries the account id, so it lives in home-ops, not this public tree.
    templates."restic.env" = {
      path = "${config.home.homeDirectory}/.config/restic/restic.env";
      content = ''
        export AWS_ACCESS_KEY_ID="${config.sops.placeholder."trace-archive-r2-access-key-id"}"
        export AWS_SECRET_ACCESS_KEY="${config.sops.placeholder."trace-archive-r2-secret-access-key"}"
        export RESTIC_PASSWORD="${config.sops.placeholder."restic-password"}"
      '';
    };

    # The Cloudflare connector token belongs in the encrypted secret store,
    # never in the public runtime registry or a launchd plist. The service
    # starts only after Home Manager has rendered this 0600 file.
    templates."beads-cloudflared-tunnel.env" = {
      path = "${config.home.homeDirectory}/.config/beads/tunnel.env";
      content = ''
        export CLOUDFLARED_TUNNEL_TOKEN="${config.sops.placeholder."beads-cloudflared-tunnel-token"}"
      '';
    };

  };
}
