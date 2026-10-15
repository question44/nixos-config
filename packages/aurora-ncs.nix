{ lib
, stdenv
, fetchFromGitHub
, cmake
, ninja
, qt6
, kdePackages
}:

stdenv.mkDerivation {
  pname = "aurora-ncs";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "BiparJoy";
    repo = "noctalia-ncs-visualizer";
    rev = "051fda085f941777e4f5d468b9d84ab03feeb787";
    hash = "sha256-f0KXEvBFWjMVeOJ9L9TXMS19L59ChML0wPU1Bq3oJ2M=";
  };
  sourceRoot = "source/renderer";

  nativeBuildInputs = [ cmake ninja qt6.wrapQtAppsHook ];
  buildInputs = [
    qt6.qtbase
    qt6.qtdeclarative
    qt6.qtwayland
    kdePackages.layer-shell-qt
  ];

  meta = {
    description = "GPU visualizer renderer for the Noctalia NCS plugin";
    homepage = "https://github.com/BiparJoy/noctalia-ncs-visualizer";
    license = lib.licenses.gpl3Plus;
    mainProgram = "aurora-ncs";
    platforms = lib.platforms.linux;
  };
}
