{ lib, stdenvNoCC, fetchurl }:

stdenvNoCC.mkDerivation rec {
  pname = "trzsz";
  version = "1.2.0";
  src = fetchurl {
    url = "https://github.com/trzsz/trzsz-go/releases/download/v${version}/trzsz_${version}_linux_x86_64.tar.gz";
    hash = "sha256-cOPghHF31Me2gajsGfoACS5CKmxijvnYpdtt+/RhKt0=";
  };

  dontBuild = true;
  installPhase = ''
    runHook preInstall
    install -Dm755 trz "$out/bin/trz"
    install -Dm755 tsz "$out/bin/tsz"
    runHook postInstall
  '';

  meta = {
    description = "Upload and download files through supported terminals";
    homepage = "https://github.com/trzsz/trzsz-go";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
