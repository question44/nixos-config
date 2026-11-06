# Helper the patched Noctalia lock screen runs to unlock with a YubiKey touch.
{
  stdenv,
  pkg-config,
  libfido2,
  linux-pam,
}:
stdenv.mkDerivation {
  pname = "noctalia-key-auth";
  version = "1";
  src = ./noctalia-key-auth.c;
  dontUnpack = true;
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    libfido2
    linux-pam
  ];
  buildPhase = ''
    runHook preBuild
    $CC -O2 -Wall -Wextra -Werror -o noctalia-key-auth $src \
      $(pkg-config --cflags --libs libfido2) -lpam
    runHook postBuild
  '';
  installPhase = ''
    runHook preInstall
    install -Dm755 noctalia-key-auth $out/bin/noctalia-key-auth
    runHook postInstall
  '';
  meta.mainProgram = "noctalia-key-auth";
}
