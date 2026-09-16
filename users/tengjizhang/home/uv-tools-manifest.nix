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
  "mlx-whisper"     # local bulk Whisper transcription on Apple Silicon (MLX);
                    # manifest-owned: not in nixpkgs (no python3Packages.mlx-whisper).
                    # Graduate to home.packages when it lands in nixpkgs.
]
