# Kwi: KDE's terminal built on libghostty-vt, with a Konsole-compatible KPart.
# No release yet; tracks invent.kde.org/utilities/kwi master.
{
  lib,
  stdenv,
  callPackage,
  fetchFromGitLab,
  cmake,
  pkg-config,
  kdePackages,
}:
let
  libghostty-vt = callPackage ./libghostty-vt.nix { };
in
stdenv.mkDerivation {
  pname = "kwi";
  version = "0.1.0-unstable-2026-11-10";

  src = fetchFromGitLab {
    domain = "invent.kde.org";
    owner = "utilities";
    repo = "kwi";
    rev = "8937f41";
    hash = "sha256-z1Up8eY9nvv5plhs/qWwCKrDzsyE+mPtlkkttGIUd/U=";
  };

  nativeBuildInputs = [
    cmake
    pkg-config
    kdePackages.extra-cmake-modules
    kdePackages.wrapQtAppsHook
    kdePackages.qtshadertools
  ];

  buildInputs = with kdePackages; [
    libghostty-vt
    qtbase
    qtdeclarative
    qtsvg
    qtshadertools
    kcoreaddons
    kconfig
    kdbusaddons
    kguiaddons
    ki18n
    kirigami
    kirigami-addons
    kirigami-app-components
    kpty
    kio
    knotifications
    kwindowsystem
    kparts
    kxmlgui
    kwidgetsaddons
    kitemmodels
    qqc2-desktop-style
  ];

  cmakeFlags = [ (lib.cmakeBool "BUILD_TESTING" false) ];

  meta = {
    description = "Modern and fast terminal for KDE Plasma and other desktops";
    homepage = "https://invent.kde.org/utilities/kwi";
    license = with lib.licenses; [
      gpl2Only
      gpl3Only
      lgpl21Only
    ];
    mainProgram = "kwi";
    platforms = lib.platforms.linux;
  };
}
