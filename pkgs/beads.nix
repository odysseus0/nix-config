# bd from the upstream release archives, at the version Sietch's board has
# been migrated to. Every client runs this one pin: a newer bd migrates the
# board's schema, after which older clients refuse it.
{ lib, stdenv, fetchurl, autoPatchelfHook }:
let
  version = "1.3.1";
  targets = {
    aarch64-darwin = { asset = "darwin_arm64"; hash = "sha256-UIuoB5luK5yZLFOKb0BfL8fS4Wz4tOWw0b+f6GA2cAc="; };
    x86_64-linux = { asset = "linux_amd64"; hash = "sha256-MhlEOpc0uJuT+xbujWWER1n6GzzTzxOcYGtzU8+wcVw="; };
    aarch64-linux = { asset = "linux_arm64"; hash = "sha256-w7MscabAzWNYoSwoJysX5oGNuZHaGS+H31IznCIuQjo="; };
  };
  system = stdenv.hostPlatform.system;
  target = targets.${system} or (throw "beads: no release archive pinned for ${system}");
in
stdenv.mkDerivation {
  pname = "beads";
  inherit version;
  src = fetchurl {
    url = "https://github.com/gastownhall/beads/releases/download/v${version}/beads_${version}_${target.asset}.tar.gz";
    inherit (target) hash;
  };
  sourceRoot = ".";
  # The Linux binary links glibc dynamically.
  nativeBuildInputs = lib.optional stdenv.hostPlatform.isLinux autoPatchelfHook;
  dontStrip = true;
  installPhase = ''
    runHook preInstall
    install -Dm755 bd $out/bin/bd
    runHook postInstall
  '';
  meta = {
    description = "Beads issue tracker CLI";
    homepage = "https://github.com/gastownhall/beads";
    license = lib.licenses.mit;
    mainProgram = "bd";
    platforms = lib.attrNames targets;
  };
}
