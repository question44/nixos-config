{
  lib,
  stdenvNoCC,
  fetchurl,
}:

let
  # Release tarball per system.
  arch = {
    x86_64-linux = {
      name = "x86_64";
      hash = "sha256-cOPghHF31Me2gajsGfoACS5CKmxijvnYpdtt+/RhKt0=";
    };
    aarch64-linux = {
      name = "aarch64";
      hash = "sha256-mnPCN7axKvJn6HhZH/IqAcl8qdHNgSX5/0/9bfT+qXw=";
    };
  };
  platform =
    arch.${stdenvNoCC.hostPlatform.system}
      or (throw "trzsz: no release for ${stdenvNoCC.hostPlatform.system}");
in
stdenvNoCC.mkDerivation rec {
  pname = "trzsz";
  version = "1.2.0";
  src = fetchurl {
    url = "https://github.com/trzsz/trzsz-go/releases/download/v${version}/trzsz_${version}_linux_${platform.name}.tar.gz";
    inherit (platform) hash;
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
    platforms = builtins.attrNames arch;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
