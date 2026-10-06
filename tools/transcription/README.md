# Local transcription

Nix pins FluidAudio source and the command wrapper. `transcription-setup`
builds the native Swift executable with Xcode outside activation. Executables
live under `${XDG_DATA_HOME:-~/.local/share}/local-transcription/versions`,
keyed by the pinned source and driver. A switch or rollback selects that exact
version; a missing executable fails with a setup instruction.

```sh
make build
# Commit configuration changes before activation.
make transcription-setup
make home-switch
transcribe recording.mp4 --output-dir "$HOME/Downloads"
```

`transcribe` uses Parakeet Ultra, word timestamps, two anonymous speakers and
JSON. Nix FFmpeg converts audio/video to mono 16 kHz audio. Speaker labeling
uses FluidAudio's offline Community-1/WeSpeaker/VBx pipeline. Models download
on first use into the adjacent `models` directory; no Hugging Face login or
Python environment is needed. Temporary converted audio is deleted on exit.

```sh
transcribe meeting.m4a --num-speakers 3 --output-format all
transcribe meeting.m4a --auto-speakers
transcribe recording.wav --no-diarize --output-format txt
transcription-format recording.json --output-dir "$HOME/Downloads"
```

Formats are JSON, TXT, SRT, VTT and TSV. JSON includes word timestamps in
`segments` and speaker-labeled text spans in `speaker_segments`. Text spans
split on speaker changes, pauses over one second, or 15 seconds of speech.
Labels such as `SPEAKER_00` identify voices, not people by name. Formatting
existing JSON reruns no models and adds `.speakers` to output filenames.
Decoder batching and other Qwen-specific flags no longer apply.

The Package.swift dependency is a sibling FluidAudio checkout populated by
setup from the source hash in `pkgs/local-transcription.nix`. To develop or
run `swift test`, put the pinned FluidAudio source alongside this package.
Updating FluidAudio requires reviewing that pin/hash, building, testing,
committing, running setup and activating the home layer.
