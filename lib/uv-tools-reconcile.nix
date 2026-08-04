# Builds pkgs.uv-tools-reconcile: the executor for the MANIFEST-OWNED tier.
# Manifest lives at ../users/tengjizhang/home/uv-tools-manifest.nix (single
# source of truth). This derivation only wires the manifest into a
# writeShellApplication; it does not run at build time — see
# Makefile's `update-tools` for the only place this executes.
{ lib, pkgs }:

let
  manifest = import ./../users/tengjizhang/home/uv-tools-manifest.nix;
in
pkgs.writeShellApplication {
  name = "uv-tools-reconcile";
  runtimeInputs = [ pkgs.uv ];
  text = ''
    set -euo pipefail

    manifest=(${lib.concatStringsSep " " manifest})

    echo "Reconciling uv tools against manifest: ''${manifest[*]}"

    for pkg in "''${manifest[@]}"; do
      echo "  install/upgrade: $pkg"
      uv tool install --upgrade "$pkg" --native-tls
    done

    # Anything uv currently has that isn't in the manifest gets uninstalled.
    # `uv tool list` prints one "name version" header line per tool, then
    # indented "- binary" lines for each entry point — only the header
    # lines carry the package name.
    installed=$(uv tool list | awk '!/^[[:space:]]/ {print $1}')
    for pkg in $installed; do
      keep=0
      for wanted in "''${manifest[@]}"; do
        if [ "$pkg" = "$wanted" ]; then
          keep=1
          break
        fi
      done
      if [ "$keep" -eq 0 ]; then
        echo "  uninstall (not in manifest): $pkg"
        uv tool uninstall "$pkg"
      fi
    done

    echo "uv tools reconciled."
  '';
}
