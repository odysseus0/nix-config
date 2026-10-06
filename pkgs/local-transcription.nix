{ writeShellApplication, symlinkJoin, coreutils, fetchzip }:
let
  revision = "04e363c29d9a754022d602d6fe1468ab80a0f705";
  source = fetchzip {
    url = "https://github.com/FluidInference/FluidAudio/archive/${revision}.tar.gz";
    hash = "sha256-8ied4EMuTqS/yOzSOZsynfXx94VCJwKzSa2zVVoOwKk=";
  };
  # Xcode supplies CoreML; compilation stays outside activation. Each pinned
  # revision has its own executable so a rollback selects the corresponding CLI.
  state = ''
    transcription_home="''${XDG_DATA_HOME:-$HOME/.local/share}/local-transcription"
    native="$transcription_home/versions/${revision}/fluidaudiocli"
  '';
  setup = writeShellApplication {
    name = "transcription-setup";
    runtimeInputs = [ coreutils ];
    text = state + ''
      if [[ -x "$native" ]]; then
        echo "FluidAudio CLI is ready."
        exit 0
      fi
      mkdir -p "$transcription_home/versions"
      work="$(mktemp -d "$transcription_home/build.XXXXXX")"
      trap 'rm -rf "$work"' EXIT
      cp -R ${source} "$work/FluidAudio"
      chmod -R u+w "$work"
      /usr/bin/xcrun swift build --package-path "$work/FluidAudio" \
        -c release --product fluidaudiocli --disable-default-traits --jobs 4
      mkdir -p "$work/install"
      cp "$work/FluidAudio/.build/release/fluidaudiocli" "$work/install/"
      for bundle in "$work/FluidAudio/.build/release/"*.bundle; do
        [[ ! -e "$bundle" ]] || cp -R "$bundle" "$work/install/"
      done
      mv "$work/install" "$transcription_home/versions/${revision}"
      echo "FluidAudio CLI is ready."
    '';
  };
  cli = writeShellApplication {
    name = "fluidaudiocli";
    text = state + ''
      if [[ ! -x "$native" ]]; then
        echo "Run transcription-setup to build the pinned FluidAudio CLI." >&2
        exit 1
      fi
      exec "$native" "$@"
    '';
  };
in symlinkJoin {
  name = "local-transcription";
  paths = [ setup cli ];
  meta = {
    description = "Official FluidAudio CLI";
    platforms = [ "aarch64-darwin" ];
  };
}
