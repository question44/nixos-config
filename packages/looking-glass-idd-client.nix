{ looking-glass-client, fetchurl, fuse3, elfutils, libunwind, usbredir }:

# Keep this release in sync with the Windows IDD installer. B7 stable predates
# the virtual-display and direct-input drivers required by this headless VM.
looking-glass-client.overrideAttrs (old: rec {
  version = "B7-829-cdba29f2";
  src = fetchurl {
    url = "https://looking-glass.io/artifact/${version}/source";
    name = "looking-glass-${version}.tar.gz";
    hash = "sha256-YNcGe0+n9C1X/DG26FpIuqiGUvV9ZfpU3pjSBw/0eM4=";
  };
  patches = [ ];
  postUnpack = ''
    export sourceRoot="looking-glass-${version}/client"
  '';
  buildInputs = old.buildInputs ++ [ fuse3 elfutils libunwind usbredir ];
  # This release installs its desktop entry and SVG icon itself.
  postInstall = "";
})
