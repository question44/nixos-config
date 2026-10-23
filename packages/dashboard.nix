{ lib, buildNpmPackage }:

buildNpmPackage {
  pname = "erebor-dashboard";
  version = "1.0.0";
  src = lib.cleanSourceWith {
    src = ../home/services;
    filter = path: _: !(builtins.elem (baseNameOf path) [ "node_modules" "dist" ]);
  };
  npmDepsHash = "sha256-/VskW2qbMMQo4WGqZP0bB5Uq1jzvmhxdUeBNYYHH8tY=";
  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    cp -r dist/. "$out/"
    runHook postInstall
  '';
}
