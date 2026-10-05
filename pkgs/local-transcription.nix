{ writeShellApplication, symlinkJoin, uv, python312, ffmpeg, coreutils, fetchurl, runCommand, unzip, patch }:
let
  # Nix owns the entry points and the lock; uv owns the environment it
  # materializes from that lock, at `make transcription-setup`, never at a
  # switch. MLX and PyTorch come as upstream Apple Silicon wheels, so nothing
  # compiles. Nix takes the environment too once nixpkgs caches Darwin MLX,
  # pyannote and torchcodec with working Metal support.
  project = ../tools/transcription;
  # Patch the exact locked upstream wheel; only Python text is unpacked/patched.
  # Native MLX/PyTorch dependencies remain uv-owned prebuilt wheels.
  upstreamWheel = fetchurl {
    url = "https://files.pythonhosted.org/packages/81/1b/49c8bd4ccb9dd32b248b42df0b53c77f5637642e1114aa34da95dc30f477/mlx_qwen3_asr-0.4.0-py3-none-any.whl";
    hash = "sha256-pbpL/8h2FrnB46phaDfzur+bua/tgSbDNcCI6L+s5J0=";
  };
  patchedASR = runCommand "mlx-qwen3-asr-0.4.0-local" {
    nativeBuildInputs = [ unzip patch ];
  } ''
    mkdir -p "$out"
    cd "$out"
    unzip -q ${upstreamWheel}
    patch -p1 < ${project}/patches/asr-batching-speakers.patch
  '';
  state = ''
    transcription_home="''${XDG_DATA_HOME:-$HOME/.local/share}/local-transcription"
    export PYTHONPATH="${patchedASR}''${PYTHONPATH:+:$PYTHONPATH}"
    export PYANNOTE_METRICS_ENABLED=0
    export UV_PROJECT_ENVIRONMENT="$transcription_home/.venv"
    export DYLD_FALLBACK_LIBRARY_PATH="${ffmpeg.lib}/lib:''${DYLD_FALLBACK_LIBRARY_PATH:-/usr/local/lib:/usr/lib}"
    expected_lock="$(sha256sum ${project}/uv.lock | cut -d ' ' -f 1)"
  '';
  setup = writeShellApplication {
    name = "transcription-setup";
    runtimeInputs = [ uv python312 coreutils ];
    text = state + ''
      mkdir -p "$transcription_home"
      uv sync --project ${project} --locked --no-build \
        --python ${python312}/bin/python3.12 --no-python-downloads "$@"
      printf '%s\n' "$expected_lock" > "$UV_PROJECT_ENVIRONMENT/.nix-lock-sha256"
      echo "Transcription environment ready. Check it with: mlx-qwen3-asr --doctor"
    '';
  };
  asr = writeShellApplication {
    name = "mlx-qwen3-asr";
    runtimeInputs = [ uv ffmpeg coreutils ];
    text = state + ''
      if [[ ! -x "$UV_PROJECT_ENVIRONMENT/bin/mlx-qwen3-asr" ]] || \
         [[ ! -f "$UV_PROJECT_ENVIRONMENT/.nix-lock-sha256" ]] || \
         [[ "$(cat "$UV_PROJECT_ENVIRONMENT/.nix-lock-sha256")" != "$expected_lock" ]]; then
        echo "Transcription environment missing or changed; run transcription-setup." >&2
        exit 1
      fi
      exec uv run --project ${project} --locked --no-sync \
        python ${project}/run.py --model Qwen/Qwen3-ASR-1.7B "$@"
    '';
  };
  formatter = writeShellApplication {
    name = "transcription-format";
    runtimeInputs = [ uv coreutils ];
    text = state + ''
      if [[ ! -x "$UV_PROJECT_ENVIRONMENT/bin/python" ]] || \
         [[ ! -f "$UV_PROJECT_ENVIRONMENT/.nix-lock-sha256" ]] || \
         [[ "$(cat "$UV_PROJECT_ENVIRONMENT/.nix-lock-sha256")" != "$expected_lock" ]]; then
        echo "Transcription environment missing or changed; run transcription-setup." >&2
        exit 1
      fi
      exec uv run --project ${project} --locked --no-sync python ${project}/format.py "$@"
    '';
  };
  transcribe = writeShellApplication {
    name = "transcribe";
    text = ''
      exec ${asr}/bin/mlx-qwen3-asr --diarize --num-speakers 2 \
        --timestamps --batch-size 8 --output-format json "$@"
    '';
  };
in symlinkJoin {
  name = "local-transcription";
  paths = [ setup asr transcribe formatter ];
  meta = {
    description = "Locked local MLX transcription with speaker diarization";
    platforms = [ "aarch64-darwin" ];
  };
}
