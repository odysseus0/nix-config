# FluidAudio CLI

Nix pins the unmodified upstream `fluidaudiocli`. `make transcription-setup`
compiles it with Xcode outside activation. A switch selects the executable
for that source revision; a missing build fails with a setup instruction.

```sh
make build
# Commit configuration changes before activation.
make transcription-setup
make home-switch
fluidaudiocli --help
```

Use upstream commands directly. Transcription and speaker detection write
separate JSON files; upstream does not combine them into a labeled transcript.

```sh
fluidaudiocli transcribe recording.wav --model-version ultra \
  --word-timestamps --output-json words.json
fluidaudiocli process recording.wav --mode offline \
  --num-speakers 2 --output speakers.json
```

For video, convert audio with the workstation's FFmpeg first:

```sh
ffmpeg -i recording.mp4 -vn -ac 1 -ar 16000 recording.wav
```

Models use FluidAudio's upstream cache at
`~/Library/Application Support/FluidAudio/Models`. Update the revision and
source hash in `pkgs/local-transcription.nix`, build, commit, run setup and
activate. There is no custom Swift driver or transcript formatter.
