{ lib, buildNpmPackage, autoPatchelfHook, stdenv }:

buildNpmPackage {
  pname = "erebor-dashboard";
  version = "2.0.0";
  src = lib.cleanSourceWith {
    src = ../home/services;
    filter = path: _: !(builtins.elem (baseNameOf path) [ "node_modules" "dist" ".angular" ]);
  };
  npmDepsHash = "sha256-ZSDdaAGB7CU8hHVvXC9+zxORO5EABR9S872LPQKjr2w=";
  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [ stdenv.cc.cc.lib ];
  # Angular's embedded Sass compiler ships a binary that needs the Nix loader.
  postConfigure = ''
    autoPatchelf node_modules/sass-embedded-linux-x64/dart-sass/src/dart
  '';
  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    cp -r dist/. "$out/"
    runHook postInstall
  '';
}
