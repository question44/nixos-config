# Time Machine target for the Mac: a Samba share with Apple's vfs_fruit
# extensions, advertised over mDNS on the LAN and reachable over Tailscale.
# The share's filesystem must support extended attributes (ext4/btrfs; not exFAT).
{ config, lib, ... }:
let
  cfg = config.my.timeMachine;
  user = config.my.user.name;
in
{
  options.my.timeMachine = {
    enable = lib.mkEnableOption "a Samba Time Machine share for Macs";
    path = lib.mkOption {
      type = lib.types.str;
      example = "/srv/backups/TimeMachine";
      description = "Directory holding the backups; created owned by my.user.";
    };
    maxSize = lib.mkOption {
      type = lib.types.str;
      default = "1T";
      description = "Size Time Machine may use before pruning old backups.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.samba = {
      enable = true;
      nmbd.enable = false;
      winbindd.enable = false;
      settings = {
        global = {
          "server string" = config.networking.hostName;
          "server min protocol" = "SMB3";
          "interfaces" = "lo ${config.my.network.lanInterface} tailscale0";
          "bind interfaces only" = "yes";
          "security" = "user";
          "map to guest" = "never";
          "load printers" = "no";
          "printing" = "bsd";
          "printcap name" = "/dev/null";
          "disable spoolss" = "yes";
          "vfs objects" = "catia fruit streams_xattr";
          "fruit:metadata" = "stream";
          "fruit:model" = "MacSamba";
          "fruit:posix_rename" = "yes";
          "fruit:veto_appledouble" = "no";
          "fruit:nfs_aces" = "no";
          "fruit:wipe_intentionally_left_blank_rfork" = "yes";
          "fruit:delete_empty_adfiles" = "yes";
        };
        TimeMachine = {
          path = cfg.path;
          "valid users" = user;
          "force user" = user;
          "read only" = "no";
          "browseable" = "yes";
          "fruit:time machine" = "yes";
          "fruit:time machine max size" = cfg.maxSize;
        };
      };
    };

    # Advertise the share so the Mac lists it in Time Machine settings.
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      allowInterfaces = [ config.my.network.lanInterface ];
      publish = {
        enable = true;
        userServices = true;
      };
      extraServiceFiles.timemachine = ''
        <?xml version="1.0" standalone='no'?>
        <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
        <service-group>
          <name replace-wildcards="yes">%h</name>
          <service>
            <type>_smb._tcp</type>
            <port>445</port>
          </service>
          <service>
            <type>_device-info._tcp</type>
            <port>0</port>
            <txt-record>model=TimeCapsule8,119</txt-record>
          </service>
          <service>
            <type>_adisk._tcp</type>
            <txt-record>dk0=adVN=TimeMachine,adVF=0x82</txt-record>
            <txt-record>sys=waMa=0,adVF=0x100</txt-record>
          </service>
        </service-group>
      '';
    };

    networking.firewall.interfaces.${config.my.network.lanInterface} = {
      allowedTCPPorts = [ 445 ];
      allowedUDPPorts = [ 5353 ];
    };
    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 445 ];

    systemd.tmpfiles.rules = [ "d ${cfg.path} 0700 ${user} users -" ];
  };
}
