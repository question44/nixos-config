{
  looking-glass-client,
  fetchurl,
  fuse3,
  elfutils,
  libunwind,
  usbredir,
}:

# Keep this release in sync with the Windows IDD installer. B7 stable predates
# the virtual-display and direct-input drivers required by this headless VM.
looking-glass-client.overrideAttrs (old: rec {
  version = "B7-895-432f4a0c";
  src = fetchurl {
    url = "https://looking-glass.io/artifact/${version}/source";
    name = "looking-glass-${version}.tar.gz";
    hash = "sha256-jSmKbU+uwbPbUZX6rPJ1UZ0JqkA1IM+ukQYrx9CXbQc=";
  };
  patches = [ ];
  postUnpack = ''
    export sourceRoot="looking-glass-${version}/client"
  '';
  buildInputs = old.buildInputs ++ [
    fuse3
    elfutils
    libunwind
    usbredir
  ];
  # This release installs its desktop entry and SVG icon itself.
  postInstall = "";
})
