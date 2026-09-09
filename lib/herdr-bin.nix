# Pin the upstream release binary: updating Herdr must not compile Rust.
# Keep the package and its bundled agent skill on the same version.
{ lib, stdenvNoCC, fetchurl }:
stdenvNoCC.mkDerivation {
  pname = "herdr";
  version = "0.9.0";
  src = fetchurl {
    url = "https://github.com/herdrdev/herdr/releases/download/v0.9.0/herdr-macos-aarch64";
    hash = "sha256-MrU98JhyYoBZx4mmnwKmuOKeFN3yZxFCHzRj9wwa7xc=";
  };
  dontUnpack = true;
  dontStrip = true;
  installPhase = ''
    runHook preInstall
    install -Dm755 "$src" "$out/bin/herdr"
    mkdir -p "$out/share/herdr/skills/herdr"
    "$out/bin/herdr" --skill > "$out/share/herdr/skills/herdr/SKILL.md"
    runHook postInstall
  '';
  meta = {
    description = "Terminal workspace manager for AI coding agents";
    homepage = "https://herdr.dev";
    license = lib.licenses.asl20;
    platforms = [ "aarch64-darwin" ];
    mainProgram = "herdr";
  };
}
