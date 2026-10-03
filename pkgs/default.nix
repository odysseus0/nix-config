# Every package this repo builds, as pkgs.<name>. Applied once, in lib/.
final: prev: {
  beads = final.callPackage ./beads.nix { };
}
