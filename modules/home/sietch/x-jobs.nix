# Sietch's half of the X project: it runs the jobs that read X and RSS (home-ops
# runtime/registry.toml, host = "sietch") and alone writes their SQLite state,
# streamed to R2 by Litestream. The MacBook reaches that state through
# `sietch` (home-ops sietch-client.nix).
# hosts/sietch.nix imports the home-ops modules this sets.
{ pkgs, ... }:

{
  runtime.host = "sietch";
  bird.enable = true;

  home.packages = with pkgs; [
    bun                                 # keep-up (vault .agents/skills/keep-up)
    litestream                          # the registry's litestream daemon
    feed                                # RSS candidates for keep-up
    # bird reads its X session from Chrome's cookies. George signs in to x.com
    # here over Screen Sharing; Chrome sync does not carry cookies.
    google-chrome
  ];
}
