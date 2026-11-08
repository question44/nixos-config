{
  flake.modules.nixos.looking-glass =
    { config, pkgs, ... }:

    let
      user = config.my.user.name;
      client = pkgs.callPackage ../packages/looking-glass-idd-client.nix { };
      kvmfr =
        (config.boot.kernelPackages.kvmfr.override {
          looking-glass-client = client;
        }).overrideAttrs
          {
            sourceRoot = "looking-glass-${client.version}/module";
          };
      launcher = pkgs.writeShellApplication {
        name = "windows-looking-glass";
        runtimeInputs = [
          pkgs.libvirt
          client
        ];
        text = ''
          if [ ! -c /dev/kvmfr0 ]; then
            echo "Looking Glass shared-memory device /dev/kvmfr0 is unavailable." >&2
            exit 1
          fi
          state=$(LC_ALL=C virsh --connect qemu:///system domstate windows11)
          if [ "$state" = "shut off" ]; then
            virsh --connect qemu:///system start windows11
          fi
          exec looking-glass-client "$@"
        '';
      };
    in
    {
      boot.extraModulePackages = [ kvmfr ];
      boot.kernelModules = [ "kvmfr" ];
      # 128 MiB accommodates the IDD's three frame buffers at up to 4K.
      boot.extraModprobeConfig = ''
        options kvmfr static_size_mb=128
      '';
      services.udev.extraRules = ''
        SUBSYSTEM=="kvmfr", OWNER="${user}", GROUP="kvm", MODE="0660"
      '';
      virtualisation.libvirtd.qemu.verbatimConfig = ''
        namespaces = []
        cgroup_device_acl = [
          "/dev/null", "/dev/full", "/dev/zero", "/dev/random", "/dev/urandom",
          "/dev/ptmx", "/dev/kvm", "/dev/userfaultfd", "/dev/kvmfr0"
        ]
      '';
      environment.etc."looking-glass-client.ini".text = ''
        [app]
        renderer=EGL
        [lgmp]
        shmDevice=/dev/kvmfr0
        [win]
        size=1920x1080
        autoResize=no
        setGuestRes=yes
        [spice]
        enable=yes
        input=no
        clipboard=no
        audio=yes
        host=127.0.0.1
        port=5900
      '';
      environment.systemPackages = [
        client
        launcher
        (pkgs.makeDesktopItem {
          name = "windows-looking-glass";
          desktopName = "Windows (Looking Glass)";
          comment = "Open the Windows VM with NVIDIA graphics acceleration";
          exec = "windows-looking-glass";
          icon = "looking-glass";
          categories = [
            "System"
            "Emulator"
          ];
        })
      ];
    };
}
