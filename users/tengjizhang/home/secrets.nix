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
  };
}
