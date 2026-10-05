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

`transcribe` defaults to Qwen3-ASR 1.7B, decoder batch size 4, word timestamps,
two speakers and JSON
(which includes speaker segments). Audio/video conversion uses the Nix
FFmpeg. Other CLI flags pass through, and later values override defaults:

```sh
transcribe meeting.m4a --num-speakers 3 --output-format all
transcribe meeting.m4a --batch-size 1 # sequential fallback
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

## Local patch and readable speaker labels

Nix fetches the exact upstream 0.4.0 wheel (the SHA-256 in `uv.lock`),
unpacks its Python files and applies `patches/asr-batching-speakers.patch`.
The patched package is a store-owned Python import path; uv continues to
own the locked native dependencies. No site-packages edits, native source
compilation, or unpublished remote fork is involved. The original Apache-2.0
license is retained, and modified files carry a local-change notice.
Upstream release source: commit `47184b8f5f2544e2337e2e9bfb3c3d9929e56da4`.
When upgrading upstream, update the wheel pin/hash in `lib/local-transcription.nix`
and rebase/revalidate the patch together with `pyproject.toml` and `uv.lock`.

The patch adds `--batch-size 1..16` for offline greedy decoding. Audio encoding
and forced alignment preserve the upstream per-chunk behavior. Variable-length
prompts share a bounded GPU decoder batch, with padding masks, independent
rotary positions, EOS/repetition stops and token budgets. Diarization still
runs over the complete recording, keeping speaker IDs consistent. Streaming,
microphone input and speculative decoding require batch size 1. Progress
reports decoder batches. `mlx-qwen3-asr` and the Python API retain batch size 1;
the workstation convenience command `transcribe` selects 4.

TXT output now has timestamped speaker turns; SRT includes speaker prefixes,
VTT uses voice tags, and TSV includes a speaker column. JSON already contained
labels upstream. Labels identify anonymous voices, not people's names.
Existing JSON can be rendered without rerunning inference:

```sh
transcription-format recording.json
```

This creates `recording.speakers.txt`, `.srt`, `.vtt` and `.tsv` alongside
its input, preserving the original files. Use `--output-dir` to choose a
separate destination.

## Validation (2026-10-05)

The 100-clip LibriSpeech test-clean check, sampled across 40 speakers, produced
identical normalized hypotheses with batch size 4; WER remained 1.9422%.
On a 149.1-second, two-voice synthetic recording with eight chunks, word
alignment and diarization enabled, three warm trials per size gave:

| Decoder batch | Median seconds | MLX peak GiB |
|---|---:|---:|
| 1 | 9.956 | 6.16 |
| 2 | 8.128 | 6.16 |
| 4 | 8.000 | 6.37 |
| 8 | 8.092 | 6.72 |

All sizes produced identical text, word timestamps and speaker labels, with
no truncation. These are local measurements, not a universal speedup promise.
The peak column measures MLX allocation, not total process/unified memory.
