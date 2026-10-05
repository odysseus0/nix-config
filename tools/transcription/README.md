# Local transcription

Workstation-only, project-isolated Python 3.12 environment. Nix owns the
commands and manifests; uv installs the exact `uv.lock` into
`${XDG_DATA_HOME:-~/.local/share}/local-transcription/.venv`. MLX/PyTorch
come from prebuilt Apple Silicon wheels. Setup fails instead of compiling
an unavailable wheel.

```sh
make build
# Commit configuration changes before activation.
make home-switch
make transcription-setup
mlx-qwen3-asr --doctor
transcribe recording.mp4 --output-dir "$HOME/Downloads"
```

`transcribe` defaults to Qwen3-ASR 1.7B, word timestamps, two speakers and JSON
(which includes speaker segments). Audio/video conversion uses the Nix
FFmpeg. Other CLI flags pass through, and later values override defaults:

```sh
transcribe meeting.m4a --num-speakers 3 --output-format all
mlx-qwen3-asr recording.wav --timestamps --output-format txt
```

The second command omits diarization. Speaker IDs are anonymous labels,
not identification of people by name. For unknown speaker counts, use
`mlx-qwen3-asr --diarize --timestamps` without `--num-speakers`.

## Models and access

Qwen3-ASR 1.7B and the forced aligner download on their first use into the
normal Hugging Face cache. The default local speaker model is
[pyannote/speaker-diarization-community-1](https://huggingface.co/pyannote/speaker-diarization-community-1).
Its gated terms must be accepted by the user on Hugging Face. Log in locally
with `~/.local/share/local-transcription/.venv/bin/hf auth login` and approve
the browser login yourself. The command automatically uses that cached login;
explicit `PYANNOTE_AUTH_TOKEN` / `HF_TOKEN` / `HUGGINGFACE_TOKEN` overrides
take precedence. Credentials stay in Hugging Face's local credential storage,
never Nix, this repo, or the lock file.
No setup command accepts model terms or creates credentials. Setting
`PYANNOTE_MODEL_ID` to an already downloaded local pipeline is also supported
by upstream. `PYANNOTE_METRICS_ENABLED=0` disables pyannote usage telemetry.

`--doctor` checks installed dependencies and token presence, not gated model
access. Diarization preflight verifies actual access before ASR starts.

## Ownership and updates

`make transcription-setup` installs this project alone. `make update-tools`
also reconciles it on the workstation, outside activation. Changes to Python
dependencies require an explicit `uv lock --project tools/transcription`,
review of the lock diff, `make build`, commit, home activation and setup.
Runtime commands use `--locked --no-sync` and require the active lock's
installation stamp, so a Nix rollback cannot silently run newer dependencies.
The environment is separate from `uv tool`; the old global Qwen installation
is intentionally absent from the global tool manifest.
