# Sietch's half of the X project: it runs the jobs that read X and RSS (home-ops
# runtime/registry.toml, host = "sietch") and alone writes their SQLite state.
# The MacBook reaches that state through `sietch` (home-ops sietch-client.nix)
# and backs it up nightly (home-ops x-export).
# home-manager-server.nix imports the home-ops modules this sets.
{ pkgs, ... }:

{
  runtime.host = "sietch";
  bird.enable = true;

  home.packages = with pkgs; [
    bun                                 # keep-up (vault .agents/skills/keep-up)
    (callPackage ../../../lib/feed.nix { }) # RSS candidates for keep-up
    # bird reads its X session from Chrome's cookies. George signs in to x.com
    # here over Screen Sharing; Chrome sync does not carry cookies.
    google-chrome
  ];
}
