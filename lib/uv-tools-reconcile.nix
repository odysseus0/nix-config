# Builds pkgs.uv-tools-reconcile: the executor for the MANIFEST-OWNED tier.
# Manifest lives at ../users/tengjizhang/home/uv-tools-manifest.nix (single
# source of truth). This derivation only wires the manifest into a
# writeShellApplication; it does not run at build time — see
# Makefile's `update-tools` for the only place this executes.
{ pkgs, lib ? pkgs.lib }:

let
  manifest = import ./../users/tengjizhang/home/uv-tools-manifest.nix;
in
pkgs.writeShellApplication {
  name = "uv-tools-reconcile";
  runtimeInputs = [ pkgs.uv ];
  text = ''
    manifest=(${lib.escapeShellArgs manifest})

    echo "Reconciling uv tools against manifest: ''${manifest[*]}"

    failures=0
    for pkg in "''${manifest[@]}"; do
      echo "  install/upgrade: $pkg"
      uv tool install --upgrade "$pkg" --native-tls || failures=$((failures + 1))
    done

    # Anything uv currently has that isn't in the manifest gets uninstalled.
    # `uv tool list` stdout has "name version" header lines at column 0 AND
    # un-indented "- binary" entry-point lines — anchor on an identifier
    # character, not on indentation (a bare `-` token fed to uninstall exits 2
    # and would kill the run mid-destruction). Malformed installs never appear
    # on stdout; uv reports them on STDERR (verified 2026-08-04) as
    #   warning: Ignoring malformed tool `X` (run `uv tool uninstall X` ...)
    # (backticks) — parse the streams separately and reconcile those too,
    # else the run reports success while reality diverges from the manifest.
    stderr_file=$(mktemp)
    installed=$(uv tool list 2>"$stderr_file" | awk '/^[A-Za-z0-9_]/ {print $1}')
    # shellcheck disable=SC2016  # the backticks are literal text in uv's warning, not expansion
    malformed=$(sed -n 's/.*Ignoring malformed tool `\([^`]*\)`.*/\1/p' "$stderr_file")
    cat "$stderr_file" >&2
    rm -f "$stderr_file"

    for pkg in $installed $malformed; do
      if ! printf '%s\n' "''${manifest[@]}" | grep -qxF "$pkg"; then
        echo "  uninstall (not in manifest): $pkg"
        uv tool uninstall "$pkg" || failures=$((failures + 1))
      fi
    done

    if [ "$failures" -gt 0 ]; then
      echo "uv tools reconcile finished with $failures failure(s)." >&2
      exit 1
    fi
    echo "uv tools reconciled."
  '';
}
