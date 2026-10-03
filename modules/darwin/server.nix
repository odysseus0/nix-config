# The headless server's system layer: always on, reachable over the tailnet,
# and the Codex app for agent threads. Everything declared serves Sietch's
# role; zap removes anything undeclared.
{ pkgs, ... }:

{
  imports = [ ./tailscale-set.nix ];

  # The Beads authority must not idle-sleep, and a power cut must bring the
  # machine back. FileVault still gates the first boot on an unlock.
  power = {
    sleep.computer = "never";
    restartAfterPowerFailure = true;
  };

  # Tailscale is the ingress: Tailscale SSH for remote shells, and the Serve
  # forwards the home layer declares (tailnet policy lives in
  # home-ops/infra/tailscale). Daemon and CLI come from one package, which
  # the forwards also use (osConfig).
  services.tailscale = {
    enable = true;
    extraSetFlags = [ "--ssh=true" ];
  };

  # Apple Remote Login: the LAN recovery path if tailscaled is down.
  services.openssh.enable = true;

  environment.systemPackages = with pkgs; [
    mosh  # system-level so non-interactive SSH can find mosh-server
  ];

  # The Codex desktop app (the `chatgpt` cask) keeps agent threads running
  # here. It self-updates (Sparkle); brew only materializes it.
  homebrew.casks = [ "chatgpt" ];
}
