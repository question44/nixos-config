{ pkgs, ... }:

let
  igdOvmf = pkgs.callPackage ../packages/ovmf-vfio-igd.nix { };
in

{
  # UHD 770 is alone in IOMMU group 0 and unused by host processes.
  # Reserve only this PCI ID; the RTX 4090 remains the host display GPU.
  boot.kernelParams = [ "intel_iommu=on" "iommu=pt" ];
  boot.initrd.kernelModules = [ "vfio_pci" ];
  boot.extraModprobeConfig = ''
    options vfio-pci ids=8086:a780
  '';

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      swtpm.enable = true;
    };
  };
  programs.virt-manager.enable = true;
  users.users.janzon.extraGroups = [ "libvirtd" "kvm" ];
  systemd.tmpfiles.rules = [ "d /var/lib/libvirt/images 0755 root root -" ];
  environment.etc."windows-vm/OVMF_CODE.fd".source = "${igdOvmf.fd}/FV/OVMF_CODE.fd";

  environment.systemPackages = with pkgs; [
    virt-viewer
    pciutils
    (writeShellApplication {
      name = "windows-vm-create";
      runtimeInputs = [ virt-manager libvirt coreutils ];
      text = ''
        if [ "$#" -ne 2 ]; then
          echo "Usage: windows-vm-create /path/to/windows11.iso /path/to/virtio-win.iso" >&2
          exit 2
        fi
        windows_iso=$(realpath -e -- "$1")
        drivers_iso=$(realpath -e -- "$2")
        connection=qemu:///system
        if virsh --connect "$connection" dominfo windows11 >/dev/null 2>&1; then
          echo "The windows11 VM already exists; open Virtual Machine Manager." >&2
          exit 1
        fi
        # Require a working connection and NAT network before creating storage.
        virsh --connect "$connection" list >/dev/null
        virsh --connect "$connection" net-info default
        if [ -e /var/lib/libvirt/images/windows11.qcow2 ]; then
          echo "Refusing to overwrite an existing Windows disk." >&2
          exit 1
        fi
        exec virt-install --connect "$connection" \
          --name windows11 --memory 12288 --vcpus 8 --cpu host-passthrough \
          --machine q35 --os-variant win11 \
          --boot loader=${pkgs.OVMFFull.fd}/FV/OVMF_CODE.ms.fd,loader.readonly=yes,loader.type=pflash,loader.secure=yes,nvram.template=${pkgs.OVMFFull.fd}/FV/OVMF_VARS.ms.fd \
          --features smm=on \
          --tpm backend.type=emulator,backend.version=2.0,model=tpm-crb \
          --disk path=/var/lib/libvirt/images/windows11.qcow2,size=120,format=qcow2,bus=virtio,discard=unmap \
          --cdrom "$windows_iso" \
          --disk "path=$drivers_iso,device=cdrom" \
          --network network=default,model=virtio \
          --graphics spice,listen=127.0.0.1 --video qxl \
          --channel spicevmc --controller type=usb,model=qemu-xhci \
          --input type=tablet,bus=usb --noautoconsole
      '';
    })
  ];
}
