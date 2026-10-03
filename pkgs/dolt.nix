# Dolt, the Beads server engine, pinned to the upstream 2.2.0 release
# archives: Beads documents 2.2.0 as the safe standalone-server release, and
# 2.3.x has a hard-reset regression that can leave a multi-writer database
# unable to settle a merge. nixpkgs' dolt at the pin is 2.3.5.
{ lib, stdenvNoCC, fetchurl }:
let
  version = "2.2.0";
  targets = {
    aarch64-darwin = {
      asset = "dolt-darwin-arm64";
      hash = "sha256-xnN9wsWAbi7u9IOa12woFnyGH4eK8wcd8SQqZYnYEmc=";
    };
    x86_64-linux = {
      asset = "dolt-linux-amd64";
      hash = "sha256-H3rYwmIplXiUIKP7Dy0WtKp0MAAKgl3ZHVk482SAy/Y=";
    };
    aarch64-linux = {
      asset = "dolt-linux-arm64";
      hash = "sha256-pJpWbXwe6f3/VTZEhVc3+dhwR1V8HOGVGqfnBTJ39K8=";
    };
  };
  system = stdenvNoCC.hostPlatform.system;
  target = targets.${system} or (throw "dolt: no pinned release archive for ${system}");
in
stdenvNoCC.mkDerivation {
  pname = "dolt";
  inherit version;

  src = fetchurl {
    url = "https://github.com/dolthub/dolt/releases/download/v${version}/${target.asset}.tar.gz";
    inherit (target) hash;
  };

  installPhase = ''
    runHook preInstall
    install -Dm755 bin/dolt $out/bin/dolt
    install -Dm644 LICENSES $out/share/licenses/dolt/LICENSES
    runHook postInstall
  '';

  meta = {
    description = "Version-controlled SQL database for the shared Beads server";
    homepage = "https://www.dolthub.com/";
    license = lib.licenses.asl20;
    mainProgram = "dolt";
    platforms = lib.attrNames targets;
  };
}
