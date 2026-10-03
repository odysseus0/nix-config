{ config, ... }:

# sops-nix: secrets encrypted in git, decrypted at activation with the age
# key. One secret, one reader: each consumer gets its own 0600 file, and
# nothing is exported into the shell environment, where every process
# (every agent, every npx) would inherit it.
#
#   Edit:     sops secrets/secrets.yaml
#   Re-key:   sops updatekeys secrets/secrets.yaml
#   Bootstrap (after restoring ~/.ssh/id_ed25519 from 1Password):
#     mkdir -p ~/.config/sops/age
#     ssh-to-age --private-key -i ~/.ssh/id_ed25519 -o ~/.config/sops/age/keys.txt
#     chmod 600 ~/.config/sops/age/keys.txt
let
  p = config.sops.placeholder;
  home = config.home.homeDirectory;
in
{
  sops = {
    defaultSopsFile = ../../../secrets/secrets.yaml;
    age.keyFile = "${home}/.config/sops/age/keys.txt";

    # WeChat SQLCipher master key (pre-KDF): the vault wechat skill's
    # seed-keys script derives wx-cli's per-shard keys from it.
    secrets."chatlog-data-key" = { };
    secrets."chatlog-img-key" = { };
    secrets."tg-app-id" = { };
    secrets."tg-app-hash" = { };
    secrets."discord-user-token" = { };
    secrets."discord-bot-token" = { };
    secrets."trace-archive-r2-access-key-id" = { };
    secrets."trace-archive-r2-secret-access-key" = { };
    secrets."restic-password" = { };

    templates."telegram.env" = {
      path = "${home}/.config/telegram/telegram.env";
      content = ''
        export TG_APP_ID="${p."tg-app-id"}"
        export TG_APP_HASH="${p."tg-app-hash"}"
      '';
    };

    templates."discord.env" = {
      path = "${home}/.config/discord/discord.env";
      content = ''
        export DISCORD_TOKEN="${p."discord-user-token"}"
        export DISCORD_BOT_TOKEN="${p."discord-bot-token"}"
      '';
    };

    # The snapshot backup to R2 (home-ops/backup/bin/restic-backup.sh): the
    # R2 key scoped to the trace-archive bucket and the repository password.
    # The repository URL carries the account id, so it lives in home-ops.
    templates."restic.env" = {
      path = "${home}/.config/restic/restic.env";
      content = ''
        export AWS_ACCESS_KEY_ID="${p."trace-archive-r2-access-key-id"}"
        export AWS_SECRET_ACCESS_KEY="${p."trace-archive-r2-secret-access-key"}"
        export RESTIC_PASSWORD="${p."restic-password"}"
      '';
    };
  };
}
