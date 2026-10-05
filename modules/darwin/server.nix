# The headless server's system layer: always on, reachable over the tailnet,
# and the Codex app for agent threads.
{ pkgs, ... }:

{
  # The Beads authority must not idle-sleep, and a power cut must bring the
  # machine back. FileVault still gates the first boot on an unlock.
  power = {
    sleep.computer = "never";
    restartAfterPowerFailure = true;
  };

  # Tailscale is the ingress for services: the Serve forwards the home layer
  # declares (tailnet policy lives in home-ops/infra/tailscale). Daemon and
  # CLI come from one package, which the forwards also use (osConfig).
  services.tailscale.enable = true;

  # Apple Remote Login: the one way in for a shell, over the tailnet and the
  # LAN alike (keys and the reason in home/sietch/ssh.nix).
  services.openssh.enable = true;

  environment.systemPackages = with pkgs; [
    mosh  # system-level so non-interactive SSH can find mosh-server
  ];

  # The Codex desktop app (the `chatgpt` cask) keeps agent threads running
  # here. It self-updates (Sparkle); brew only materializes it.
  homebrew.casks = [ "chatgpt" ];
}
