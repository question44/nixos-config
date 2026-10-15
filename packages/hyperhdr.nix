{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  makeWrapper,
  pkg-config,
  alsa-lib,
  flatbuffers,
  libglvnd,
  libjpeg_turbo,
  mbedtls,
  mdns,
  nanopb,
  pipewire,
  qt6Packages,
  qmqtt,
  xz,
  sdbus-cpp_2,
  plutovg,
  lunasvg,
  linalg,
  stb,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "hyperhdr";
  version = "22.0.0.0";
  src = fetchFromGitHub {
    owner = "awawa-dev";
    repo = "HyperHDR";
    rev = "e5bda285227cbd38bce60da6a442dde936fd9e7a";
    hash = "sha256-si39Q5XaZHGAFEU2sqU60+5kPYVPnTAoPaiyWD1Dlvs=";
  };

  nativeBuildInputs = [
    cmake
    makeWrapper
    pkg-config
    qt6Packages.wrapQtAppsHook
  ];

  postPatch = ''
    substituteInPlace sources/sound-capture/linux/SoundCaptureLinux.cpp \
      --replace-fail "libasound.so.2" "${lib.getLib alsa-lib}/lib/libasound.so.2"
    substituteInPlace cmake/installer_linux.cmake \
      --replace-fail 'install(FILES ''${CMAKE_SOURCE_DIR}/cmake/linux/service/hyperhdr@.service DESTINATION "/usr/lib/systemd/system" COMPONENT "HyperHDR")' \
      '# NixOS manages HyperHDR through a user-session unit.'
  '';

  postFixup = ''
    wrapProgram "$out/bin/hyperhdr" \
      --prefix LD_LIBRARY_PATH : "${libglvnd}/lib:/run/opengl-driver/lib:$out/lib/hyperhdr"
  '';

  cmakeFlags = [
    "-DPLATFORM=linux"
    (lib.cmakeBool "ENABLE_PIPEWIRE" true)
    (lib.cmakeBool "ENABLE_PIPEWIRE_EGL" true)
    (lib.cmakeBool "USE_SYSTEM_FLATBUFFERS_LIBS" true)
    (lib.cmakeBool "USE_SYSTEM_LUNASVG_LIBS" true)
    (lib.cmakeBool "USE_SYSTEM_MQTT_LIBS" true)
    (lib.cmakeBool "USE_SYSTEM_NANOPB_LIBS" true)
    (lib.cmakeBool "USE_SYSTEM_SDBUS_CPP_LIBS" true)
    (lib.cmakeBool "USE_SYSTEM_STB_LIBS" true)
  ];

  buildInputs = [
    alsa-lib
    flatbuffers
    libglvnd
    libjpeg_turbo
    linalg
    lunasvg
    mbedtls
    mdns
    nanopb
    pipewire
    plutovg
    qmqtt
    qt6Packages.qtbase
    qt6Packages.qtserialport
    sdbus-cpp_2
    stb
    xz
  ];

  meta = {
    description = "Ambient lighting system with software screen capture";
    homepage = "https://github.com/awawa-dev/HyperHDR";
    license = lib.licenses.mit;
    mainProgram = "hyperhdr";
    platforms = lib.platforms.linux;
  };
})
