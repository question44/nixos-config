{ config, lib, pkgs, ... }:

let
  passthrough = config.virtualisation.windowsGpuPassthrough.enable;
  igdOvmf = pkgs.callPackage ../packages/ovmf-vfio-igd.nix { };
in

{
  options.virtualisation.windowsGpuPassthrough.enable = lib.mkEnableOption
    "RTX 4090 and HDMI audio passthrough to windows11 instead of host NVIDIA graphics";

  config = lib.mkMerge [ {
    boot.kernelParams = [ "intel_iommu=on" "iommu=pt" ];

    # Reconcile the existing domain without touching its disk, NVRAM or TPM.
    # Refuse to change GPU ownership while the guest is running.
    systemd.services.windows-vm-gpu = {
      description = "Synchronize Windows VM GPU assignment";
      wantedBy = [ "multi-user.target" ];
      requires = [ "libvirtd.service" ];
      after = [ "libvirtd.service" ];
      path = [ pkgs.libvirt ];
      serviceConfig.Type = "oneshot";
      serviceConfig.RemainAfterExit = true;
      script = "${pkgs.python3}/bin/python3 ${../scripts/windows-vm-gpu.py} ${if passthrough then "on" else "off"}";
    };

    # Put the host and guests on the wired LAN. Keep the physical MAC and
    # DHCP client identity so the host retains its router lease.
    networking.networkmanager.ensureProfiles.profiles = {
      lan-bridge = {
        connection = {
          id = "lan-bridge";
          uuid = "c2a542c7-917d-4d2e-8a93-6462112f38b7";
          type = "bridge";
          interface-name = "br0";
          autoconnect = true;
          autoconnect-ports = 1;
          autoconnect-priority = 100;
        };
        bridge = {
          stp = false;
          mac-address = "D8:5E:D3:E2:35:0A";
        };
        ipv4 = {
          method = "auto";
          dhcp-client-id = "mac";
        };
        ipv6.method = "auto";
      };
      lan-bridge-port = {
        connection = {
          id = "lan-bridge-port";
          uuid = "3c0196fc-b358-452f-9930-8944b2fcc131";
          type = "ethernet";
          interface-name = "enp4s0";
          controller = "c2a542c7-917d-4d2e-8a93-6462112f38b7";
          port-type = "bridge";
          autoconnect = true;
          autoconnect-priority = 100;
        };
      };
    };

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
    # Retain the existing guest firmware and NVRAM during the GPU migration.
    environment.etc."windows-vm/OVMF_CODE.fd".source = "${igdOvmf.fd}/FV/OVMF_CODE.fd";

    environment.systemPackages = with pkgs; [
      virt-viewer
      pciutils
      (writeShellApplication {
        name = "windows-vm-create";
        runtimeInputs = [ virt-manager libvirt coreutils iproute2 ];
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
          # Require a working connection and LAN bridge before creating storage.
          virsh --connect "$connection" list >/dev/null
          ip link show br0 >/dev/null
          if [ -e /var/lib/libvirt/images/windows11.qcow2 ]; then
            echo "Refusing to overwrite an existing Windows disk." >&2
            exit 1
          fi
          exec virt-install --connect "$connection" \
            --name windows11 --memory 20480 \
            --vcpus 20,sockets=1,cores=20,threads=1 --cpuset 0-19 --cpu host-passthrough \
            --machine q35 --os-variant win11 \
            --boot loader=${pkgs.OVMFFull.fd}/FV/OVMF_CODE.ms.fd,loader.readonly=yes,loader.type=pflash,loader.secure=yes,nvram.template=${pkgs.OVMFFull.fd}/FV/OVMF_VARS.ms.fd \
            --features smm=on \
            --tpm backend.type=emulator,backend.version=2.0,model=tpm-crb \
            --disk path=/var/lib/libvirt/images/windows11.qcow2,size=120,format=qcow2,bus=virtio,discard=unmap \
            --cdrom "$windows_iso" \
            --disk "path=$drivers_iso,device=cdrom" \
            --network bridge=br0,model=virtio \
            --graphics spice,listen=127.0.0.1 --video qxl \
            --channel spicevmc --controller type=usb,model=qemu-xhci \
            --input type=tablet,bus=usb --noautoconsole
        '';
      })
    ];
  } (lib.mkIf passthrough {
    boot.initrd.kernelModules = [ "vfio_pci" ];
    boot.extraModprobeConfig = "options vfio-pci ids=10de:2684,10de:22ba";
    boot.blacklistedKernelModules = [ "nouveau" "nvidia" "nvidia_drm" "nvidia_modeset" "nvidia_uvm" ];
  }) ];
}
