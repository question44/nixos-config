{
  lib,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
  gnutar,
  gzip,
  stdenv,
  openssl,
  zlib,
}:

let
  # Release tarball per system; both hold the same files.
  arch = {
    x86_64-linux = {
      name = "x86_64";
      hash = "sha256-ySDWPC2tsCqWwu3VctTBrlQ3HjtrwIT9os/jJLllBw0=";
    };
    aarch64-linux = {
      name = "aarch64";
      hash = "sha256-hWvy6yEaaDkm8aQbdy9Q4Zo/fof6OWWU5sULL7XAIBI=";
    };
  };
  platform =
    arch.${stdenvNoCC.hostPlatform.system}
      or (throw "ai-usagebar: no release for ${stdenvNoCC.hostPlatform.system}");
in
stdenvNoCC.mkDerivation rec {
  pname = "ai-usagebar";
  version = "1.48.2";

  src = fetchurl {
    url = "https://github.com/akitaonrails/ai-usagebar/releases/download/v${version}/ai-usagebar-linux-${platform.name}.tar.gz";
    inherit (platform) hash;
  };

  dontUnpack = true;
  nativeBuildInputs = [
    autoPatchelfHook
    gnutar
    gzip
  ];
  buildInputs = [
    stdenv.cc.cc.lib
    openssl
    zlib
  ];

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
    platforms = builtins.attrNames arch;
  };
}
