{ lib
, stdenvNoCC
, fetchurl
, autoPatchelfHook
, gnutar
, gzip
, stdenv
, openssl
, zlib
}:

stdenvNoCC.mkDerivation rec {
  pname = "ai-usagebar";
  version = "1.38.0";

  src = fetchurl {
    url = "https://github.com/akitaonrails/ai-usagebar/releases/download/v${version}/ai-usagebar-linux-x86_64.tar.gz";
    hash = "sha256-dODRAPaY6/UalNCC56Q4+WZFsYoIrQ3C6NQZbjU+3hQ=";
  };

  dontUnpack = true;
  nativeBuildInputs = [ autoPatchelfHook gnutar gzip ];
  buildInputs = [ stdenv.cc.cc.lib openssl zlib ];

  installPhase = ''
    runHook preInstall
    mkdir -p "$TMPDIR/ai-usagebar" "$out/bin"
    tar -xzf "$src" -C "$TMPDIR/ai-usagebar"
    install -m755 "$TMPDIR/ai-usagebar/ai-usagebar" "$out/bin/ai-usagebar"
    if [ -f "$TMPDIR/ai-usagebar/ai-usagebar-tui" ]; then
      install -m755 "$TMPDIR/ai-usagebar/ai-usagebar-tui" "$out/bin/ai-usagebar-tui"
    fi
    runHook postInstall
  '';

  meta = {
    description = "CLI for monitoring AI provider plan usage";
    homepage = "https://github.com/akitaonrails/ai-usagebar";
    license = lib.licenses.mit;
    mainProgram = "ai-usagebar";
    platforms = [ "x86_64-linux" ];
  };
}
