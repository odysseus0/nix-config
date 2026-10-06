{ writeShellApplication, symlinkJoin, ffmpeg, coreutils, fetchzip }:
let
  project = ../tools/transcription;
  source = fetchzip {
    url = "https://github.com/FluidInference/FluidAudio/archive/04e363c29d9a754022d602d6fe1468ab80a0f705.tar.gz";
    hash = "sha256-8ied4EMuTqS/yOzSOZsynfXx94VCJwKzSa2zVVoOwKk=";
  };
  # Xcode supplies CoreML and the native Swift toolchain; build only at explicit
  # setup, so activation and rollback select an already-built version offline.
  version = builtins.substring 0 16 (builtins.hashString "sha256" (
    toString source + builtins.readFile (project + "/Package.swift")
    + builtins.readFile (project + "/Sources/Transcribe/Transcribe.swift")
    + builtins.readFile (project + "/Sources/Transcribe/Output.swift")
  ));
  state = ''
    transcription_home="''${XDG_DATA_HOME:-$HOME/.local/share}/local-transcription"
    native="$transcription_home/versions/${version}/Transcribe"
  '';
  setup = writeShellApplication {
    name = "transcription-setup";
    runtimeInputs = [ coreutils ];
    text = state + ''
      if [[ -x "$native" ]]; then
        echo "FluidAudio transcription is ready."
        exit 0
      fi
      /usr/bin/xcrun --find swift >/dev/null
      mkdir -p "$transcription_home/versions"
      work="$(mktemp -d "$transcription_home/build.XXXXXX")"
      trap 'rm -rf "$work"' EXIT
      cp -R ${source} "$work/FluidAudio"
      cp -R ${project} "$work/LocalTranscription"
      chmod -R u+w "$work"
      /usr/bin/xcrun swift build --package-path "$work/LocalTranscription" \
        -c release --jobs 4
      install_dir="$work/install"
      mkdir -p "$install_dir"
      cp "$work/LocalTranscription/.build/release/Transcribe" "$install_dir/Transcribe"
      for bundle in "$work/LocalTranscription/.build/release/"*.bundle; do
        [[ ! -e "$bundle" ]] || cp -R "$bundle" "$install_dir/"
      done
      mv "$install_dir" "$transcription_home/versions/${version}"
      echo "FluidAudio transcription is ready."
    '';
  };
  transcribe = writeShellApplication {
    name = "transcribe";
    runtimeInputs = [ ffmpeg ];
    text = state + ''
      if [[ ! -x "$native" ]]; then
        echo "Run transcription-setup to build the pinned FluidAudio command." >&2
        exit 1
      fi
      export FLUID_TRANSCRIPTION_MODELS="$transcription_home/models"
      exec "$native" "$@"
    '';
  };
  formatter = writeShellApplication {
    name = "transcription-format";
    text = ''
      exec ${transcribe}/bin/transcribe --format-json --output-format all "$@"
    '';
  };
in symlinkJoin {
  name = "local-transcription";
  paths = [ setup transcribe formatter ];
  meta = {
    description = "Native FluidAudio transcription with timestamps and speaker labels";
    platforms = [ "aarch64-darwin" ];
  };
}
