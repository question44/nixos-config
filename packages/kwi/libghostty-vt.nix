# libghostty-vt 1.0.0 release (nixpkgs has a 0.1.0 snapshot; Kwi needs >= 1.0).
# Built like Kwi's Flatpak manifest: release tarball plus its vendored Zig deps.
{
  lib,
  stdenv,
  fetchurl,
  fetchzip,
  gitMinimal,
  ncurses,
  pkg-config,
  zig_0_17,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "libghostty-vt";
  version = "1.0.0";

  src = fetchurl {
    url = "https://release.files.ghostty.org/libghostty-vt/${finalAttrs.version}/libghostty-vt-${finalAttrs.version}.tar.gz";
    hash = "sha256-Sm73WL5yGSPhlp57gbRD3MktjdP7WjlgDAOogXp1NnY=";
  };

  deps = fetchzip {
    url = "https://release.files.ghostty.org/libghostty-vt/${finalAttrs.version}/libghostty-vt-${finalAttrs.version}-deps.tar.gz";
    hash = "sha256-bqi6TjqxfMtLYyStfHeqZBPsapfdJHVT3ILxL7u+kEQ=";
  };

  __structuredAttrs = true;
  strictDeps = true;

  nativeBuildInputs = [
    gitMinimal
    ncurses
    pkg-config
    zig_0_17
  ];

  dontSetZigDefaultFlags = true;
  zigBuildFlags = [
    "--system"
    "${finalAttrs.deps}"
    "-Dcpu=baseline"
    "-Doptimize=ReleaseFast"
  ];

  meta = {
    description = "Ghostty's embeddable terminal emulation library";
    homepage = "https://ghostty.org/";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
})
