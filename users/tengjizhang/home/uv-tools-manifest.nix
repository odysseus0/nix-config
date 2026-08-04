# MANIFEST-OWNED tier: uv tool packages (Python CLIs with heavy/ML deps).
# Single source of truth, read by both home/packages.nix (so `home.packages`
# documents what's declared) and lib/uv-tools-reconcile.nix (the executor
# exposed as pkgs.uv-tools-reconcile via the overlay in flake.nix, run by
# `make update-tools`). Nix declares this list; uv reconciles reality to it,
# including uninstalling anything present but unlisted.
# Entries must be bare, normalized PyPI names (hyphens, no extras, no version
# specs) — they are compared verbatim against `uv tool list`'s normalized
# output, so anything else would be installed and immediately uninstalled in
# the same run.
[
  "mlx-qwen3-asr"   # Qwen3-ASR speech recognition for Apple Silicon
]
