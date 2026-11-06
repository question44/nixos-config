# Bootloader (GRUB with Windows chainload), Plymouth and kernel parameters.
{ pkgs, ... }:
{
  boot.loader.systemd-boot.enable = false;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";
  boot.loader.timeout = 5;
  boot.loader.grub = {
    enable = true;
    device = "nodev";
    efiSupport = true;
    efiInstallAsRemovable = false;
    gfxmodeEfi = "auto";
    gfxpayloadEfi = "keep";
    splashImage = null;
    theme = ../../assets/grub-redhead;
    font = "${pkgs.dejavu_fonts.minimal}/share/fonts/truetype/DejaVuSans.ttf";
    fontSize = 20;
    useOSProber = false;
    # Bound the NixOS kernels kept on the shared 6 GB ESP.
    configurationLimit = 15;
    extraEntries = ''
      menuentry "Windows Boot Manager" {
        insmod part_gpt
        insmod fat
        insmod chain
        search --no-floppy --fs-uuid --set=root 38B5-8386
        chainloader /EFI/Microsoft/Boot/bootmgfw.efi
      }
      menuentry "systemd-boot recovery" {
        insmod part_gpt
        insmod fat
        insmod chain
        search --no-floppy --fs-uuid --set=root 38B5-8386
        chainloader /EFI/systemd/systemd-bootx64.efi
      }
    '';
  };
  boot.kernelModules = [ "uinput" ];
  boot.plymouth = {
    enable = true;
    theme = "bgrt";
    extraConfig = "UseSimpledrm=1";
  };
  boot.consoleLogLevel = 0;
  boot.kernelParams = [ "quiet" ];
}
