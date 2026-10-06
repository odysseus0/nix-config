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

`transcribe` defaults to Qwen3-ASR 1.7B, decoder batch size 8, word timestamps,
two speakers and JSON
(which includes speaker segments). Audio/video conversion uses the Nix
FFmpeg. Other CLI flags pass through, and later values override defaults:

```sh
transcribe meeting.m4a --num-speakers 3 --output-format all
transcribe meeting.m4a --batch-size 1 # sequential fallback
mlx-qwen3-asr recording.wav --timestamps --output-format txt
```

The `mlx-qwen3-asr` example omits diarization. Speaker IDs are anonymous labels,
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

`make transcription-setup` installs this project, outside activation. Changes to Python
dependencies require an explicit `uv lock --project tools/transcription`,
review of the lock diff, `make build`, commit, home activation and setup.
Runtime commands use `--locked --no-sync` and require the active lock's
installation stamp, so a Nix rollback cannot silently run newer dependencies.

## Local patch and readable speaker labels

Nix fetches the exact upstream 0.4.0 wheel (the SHA-256 in `uv.lock`),
unpacks its Python files and applies `patches/asr-batching-speakers.patch`.
The patched package is a store-owned Python import path; uv continues to
own the locked native dependencies. No site-packages edits, native source
compilation, or unpublished remote fork is involved. The original Apache-2.0
license is retained, and modified files carry a local-change notice.
Upstream release source: commit `47184b8f5f2544e2337e2e9bfb3c3d9929e56da4`.
When upgrading upstream, update the wheel pin/hash in `pkgs/local-transcription.nix`
and rebase/revalidate the patch together with `pyproject.toml` and `uv.lock`.

The patch adds `--batch-size 1..16` for offline greedy decoding. Audio encoding
retains its per-chunk behavior. Similar-duration
chunks share a bounded GPU decoder batch, with padding masks, independent
rotary positions, EOS/repetition stops and token budgets. Text, timestamps and
chunk metadata are restored to chronological order. Only CPU token results
survive each GPU batch. Word alignment uses the same bounded, duration-grouped
batches in the native decoder; causal right padding preserves each prompt.
Empty rows and unknown languages retain the upstream exclusion behavior.
GPU caches are released between actual batches and sequential chunks; CPU
assembly restores chronological offsets.

Diarization runs over the complete recording, keeping speaker IDs consistent.
For pyannote's supported native WeSpeaker backend, the expensive audio network
is evaluated once per window and reused for all speaker masks at pooling.
The adapter belongs to that pipeline instance; training and other embedding
backends use the original implementation. No global patching or concurrent
GPU workers are added. The native dependency interfaces are pinned by `uv.lock`.

Streaming, microphone input and speculative decoding require batch size 1.
Progress distinguishes ASR, word alignment and speaker labeling.
`mlx-qwen3-asr` and the Python API retain batch size 1; the workstation
convenience command `transcribe` selects 8.

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
identical normalized hypotheses with grouped batch size 8; WER remained
1.9422%. That independent quality check completed in 10.6 seconds. The fast
gate passes 685 tests with 2 optional skips, using MLX 0.32.3.

For iteration, 16 short clips total just 42.9 seconds. Two complete batches
with mixed lengths test padding and grouping without a long recording. Models
stay resident; warm comparisons use bracketed controls, with two trials each:

| Decoder setting | Median seconds | MLX peak GiB |
|---|---:|---:|
| Batch 4, chronological | 0.894 | 4.28 |
| Batch 8, chronological | 0.688 | 4.41 |
| Batch 8, duration grouped | 0.654 | 4.41 |

All fixture outputs match with no truncation. The peak column measures MLX
allocation, not total process/unified memory. Local timings do not imply a
fixed speedup for other recordings.

Sharing speaker features preserves the native speaker turns on six fixtures:
single, two and three voices, overlapping speech, silence and synthetic speech.
Mask selection, short/empty speaker masks, tail batches and training fallback
are also checked against pyannote's original implementation.

Larger speaker batches, concurrent ASR/diarization, active decoder-row
compaction and changing cache-cleanup frequency did not provide repeatable
benefits; none are included. Increase fixture size only for a specific missing
signal such as sustained memory behavior, rather than routinely rerunning a
full recording.

## Remaining-stage audit (2026-10-05)

Native word alignment batches preserve every original timestamp on all 100
LibriSpeech clips (2,317 aligned words). The isolated probe took 3.98 seconds
at batch 8 versus 5.12 seconds sequentially, about 22% less. On the 42.9-second
fixture, the corresponding warm medians were 0.273 and 0.430 seconds.
The implemented method independently reproduces the saved original hash.
Tests cover right padding, empty rows, unknown-language exclusion, chronological
offsets and stage progress. Single-row alignment retains its original path.

The follow-up also measured async decoder lookahead, compiled MLPs, selective
timestamp projection and speculative decoding. None earned a production change;
speculative decoding was over three times slower than batch 8 on the short
fixture. Q8 retained all 100 normalized hypotheses, but its longer-context
gain was only about 3%, so fp16 remains the default. A GPU speaker FFT probe
was faster, but its feature error exceeded the 1e-5 absolute/relative parity
tolerance; the native frontend's CPU FFT workaround remains intact.
