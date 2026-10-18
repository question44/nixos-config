{ OVMFFull, fetchFromGitHub }:

let
  # QEMU's IGD assignment documentation references this implementation for
  # Gen11+ OpRegion and stolen-memory setup, absent from upstream OVMF.
  vfioIgdPkg = fetchFromGitHub {
    owner = "tomitamoeko";
    repo = "VfioIgdPkg";
    rev = "067328df2554c865cc0078cb922357301c4c36c6";
    sha256 = "0wyv4rm8kw9axn374004hhnxc1dbi6vjs16fpi2rq5ldmrlryj7w";
  };
in

# Keep the guest's existing Microsoft-keyed NVRAM. Only replace its CODE
# image; embedding this driver also avoids an unsigned PCI option ROM.
(OVMFFull.override { msVarsTemplate = false; }).overrideAttrs (old: {
  pname = "OVMF-vfio-igd";
  postPatch = (old.postPatch or "") + ''
    cp -r ${vfioIgdPkg} VfioIgdPkg
    chmod -R u+w VfioIgdPkg
    grep -q '# DXE Phase modules' OvmfPkg/OvmfPkgX64.dsc
    grep -q '# DXE Phase modules' OvmfPkg/OvmfPkgX64.fdf
    sed -i '/# DXE Phase modules/a\  VfioIgdPkg/IgdAssignmentDxe/IgdAssignment.inf' OvmfPkg/OvmfPkgX64.dsc
    sed -i '/# DXE Phase modules/a\INF VfioIgdPkg/IgdAssignmentDxe/IgdAssignment.inf' OvmfPkg/OvmfPkgX64.fdf
  '';
})
