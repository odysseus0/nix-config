# Sietch: headless, always-on Mac mini. Its only jobs are hosting the shared
# Beads Dolt authority over the tailnet (users/tengjizhang/home/beads-server.nix)
# and accepting remote shells. Everything declared here serves one of those two
# roles; anything else found on the machine is purged, not adopted.
{ pkgs, ... }: {
  imports = [
    ./darwin-common.nix
    ../lib/darwin-tailscale-set.nix
  ];

  # Preserve the machine's existing identity spelling (scutil reports
  # "Sietch" for all three). The flake output is lowercase `sietch`, so
  # rebuilds name it explicitly: `darwin-rebuild switch --flake .#sietch`.
  networking = {
    hostName = "Sietch";
    localHostName = "Sietch";
    computerName = "Sietch";
  };

  # Always-on: the Beads authority must not idle-sleep, and a power cut must
  # bring the machine back. FileVault still gates the first boot on an unlock;
  # these options do not bypass it.
  power = {
    sleep.computer = "never";
    restartAfterPowerFailure = true;
  };

  # Tailscale is the ingress for both roles: Tailscale SSH for remote shells,
  # and the Serve TCP forward the Beads clients reach (tailnet policy lives in
  # home-ops/infra/tailscale). The daemon and CLI come from the same package,
  # which the Beads forward also uses (osConfig in beads-server.nix).
  services.tailscale = {
    enable = true;
    extraSetFlags = [ "--ssh=true" ];
  };

  # Apple Remote Login: the LAN recovery path if tailscaled is down.
  services.openssh.enable = true;

  environment.systemPackages = with pkgs; [
    mosh  # system-level so non-interactive SSH can find mosh-server
  ];
}
