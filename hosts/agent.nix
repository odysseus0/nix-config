# Agent boxes: disposable Linux machines that come with a personal agent. The
# job is to connect them to Beads on Sietch and nothing else; the vendor's
# image is already tuned for its own agent.
{ ... }:
{
  imports = [
    ../modules/home/beads-client.nix
    ../modules/home/agent/tailscaled.nix
  ];

  # The forward agent-net opens.
  programs.beads-client.server.host = "127.0.0.1";

  # The options manual drags a documentation toolchain onto a box that only
  # needs bd and Tailscale.
  manual.manpages.enable = false;
  programs.man.enable = false;
  xdg.mime.enable = false;

  home.stateVersion = "26.05";
}
