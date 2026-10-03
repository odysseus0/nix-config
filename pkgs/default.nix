# Every package this repo builds, as pkgs.<name>. Applied once, in lib/.
final: prev: {
  beads = final.callPackage ./beads.nix { };
  dolt = final.callPackage ./dolt.nix { };
  feed = final.callPackage ./feed.nix { };
  herdr = final.callPackage ./herdr.nix { };
  nix-flake-bump = final.callPackage ./nix-flake-bump.nix { };
  sherlog = final.callPackage ./sherlog.nix { };
}
