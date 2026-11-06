{
  lib,
  bash,
  coreutils,
  curl,
  cpio,
  fetchurl,
  gnutar,
  jq,
  libglvnd,
  llvmPackages,
  openal,
  p7zip,
  rpm,
  sdl3,
  stdenv,
  symlinkJoin,
  unshield,
  writeShellApplication,
}:

let
  # OldUnreal's Fedora build requests the historical libomp.so.5 filename.
  # Current Nixpkgs OpenMP exposes the ABI-compatible library as libomp.so,
  # so provide the requested loader name declaratively.
  openmpCompat = symlinkJoin {
    name = "ut2004-openmp-compat";
    paths = [ llvmPackages.openmp ];
    postBuild = ''
      ln -s libomp.so "$out/lib/libomp.so.5"
    '';
  };

  installer = fetchurl {
    url = "https://raw.githubusercontent.com/OldUnreal/FullGameInstallers/34e9dec087aa4ba4c75ce6c0a98dee7967215ee7/Linux/install-ut2004.sh";
    hash = "sha256-7F8s1tn3asEISH7IzHUd3ZEgdxuYQCUhQg/y34yxna0=";
  };

  runtimeLibraryPath = lib.makeLibraryPath [
    sdl3
    openmpCompat
    openal
    stdenv.cc.cc.lib
    libglvnd
  ];

  ut2004-setup = writeShellApplication {
    name = "ut2004-setup";
    runtimeInputs = [
      coreutils
      curl
      gnutar
      jq
      p7zip
      unshield
    ];
    text = ''
      destination="''${UT2004_DIR:-$HOME/Games/UT2004}"
      exec ${bash}/bin/bash ${installer} \
        --destination "$destination" \
        --ui-mode=none \
        --application-entry=skip \
        --desktop-shortcut=skip \
        "$@"
    '';
  };

  ut2004 = writeShellApplication {
    name = "ut2004";
    runtimeInputs = [ coreutils ];
    text = ''
      game_dir="''${UT2004_DIR:-$HOME/Games/UT2004}"
      game_binary="$game_dir/System/UT2004"

      if [ ! -x "$game_binary" ]; then
        echo "UT2004 is not installed in $game_dir." >&2
        echo "Run ut2004-setup first, or set UT2004_DIR to its install directory." >&2
        exit 1
      fi

      export LD_LIBRARY_PATH="${runtimeLibraryPath}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
      cd "$game_dir/System"
      exec "$game_binary" "$@"
    '';
  };

  ut2004-import-rpm = writeShellApplication {
    name = "ut2004-import-rpm";
    runtimeInputs = [
      coreutils
      cpio
      rpm
    ];
    text = ''
      if [ "$#" -ne 1 ]; then
        echo "Usage: ut2004-import-rpm /path/to/unreal-tournament-2004-*.rpm" >&2
        exit 64
      fi

      rpm_file="$1"
      game_dir="''${UT2004_DIR:-$HOME/Games/UT2004}"

      if [ ! -f "$rpm_file" ]; then
        echo "RPM not found: $rpm_file" >&2
        exit 66
      fi

      if [ -e "$game_dir" ]; then
        echo "Refusing to overwrite existing install: $game_dir" >&2
        exit 73
      fi

      extract_dir="$(mktemp -d)"
      trap 'rm -rf "$extract_dir"' EXIT
      rpm2cpio "$rpm_file" | (cd "$extract_dir" && cpio -idm --quiet)

      source_dir="$extract_dir/usr/lib64/ut2004"
      if [ ! -x "$source_dir/System/UT2004" ]; then
        echo "The RPM does not contain an OldUnreal UT2004 Linux installation." >&2
        exit 65
      fi

      mkdir -p "$(dirname "$game_dir")"
      cp -a "$source_dir" "$game_dir"
      echo "Imported UT2004 into $game_dir"
    '';
  };
in
{
  inherit ut2004 ut2004-import-rpm ut2004-setup;
}
