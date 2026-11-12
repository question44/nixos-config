# Settings every workstation shares: Nix, networking, locale, the main user,
# polkit and desktop plumbing. Host-specific values come from my.* options.
{
  flake.modules.nixos.base =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      user = config.my.user.name;
      lan = config.my.network.lanInterface;
      services = lib.filter (s: s.enable) (lib.attrValues config.my.services);
      localNames = lib.concatMap (s: [
        s.localName
        "${s.localName}.localhost"
      ]) (lib.filter (s: s.localName != null) services);
      lanPorts = lib.concatMap (s: lib.optional (s.lanPort != null) s.lanPort) services;
    in
    {
      nix.settings.experimental-features = [
        "nix-command"
        "flakes"
      ];
      nix.settings.auto-optimise-store = true;
      # Bound build parallelism (at most max-jobs × cores compile threads) and let
      # builds yield to the desktop. Unbounded builds froze erebor on 2026-11-06.
      nix.settings.max-jobs = 4;
      nix.settings.cores = 6;
      nix.daemonCPUSchedPolicy = "batch";
      nix.daemonIOSchedClass = "idle";
      # Builders run in the daemon's cgroup: throttle them before RAM runs out,
      # and make them the kernel OOM killer's first choice over desktop apps.
      systemd.services.nix-daemon.serviceConfig = {
        MemoryHigh = "60%";
        MemoryMax = "75%";
        OOMScoreAdjust = 500;
      };
      # Kill the worst cgroup under sustained memory pressure instead of thrashing.
      # User sessions are monitored at user@.service, not at the root-owned
      # user.slice or -.slice: oomd honours a user unit's ManagedOOMPreference only
      # when the monitored ancestor has the same owner.
      systemd.oomd.enableSystemSlice = true;
      systemd.services."user@".serviceConfig = {
        ManagedOOMMemoryPressure = "kill";
        ManagedOOMMemoryPressureLimit = "80%";
        # Unprivileged processes cannot lower oom_score_adj below what their root
        # parent set, so the user manager starts at -200 (upstream 100) to let
        # session-core user units go below the default...
        OOMScoreAdjust = -200;
      };
      # ...while ordinary user units keep the usual 200 (upstream: manager + 100).
      systemd.user.settings.Manager.DefaultOOMScoreAdjust = 200;
      nix.gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 30d";
      };

      networking.networkmanager.enable = true;
      networking.hosts = {
        "127.0.0.1" = [
          config.networking.hostName
        ]
        ++ localNames;
      };
      # SSH is reachable from the LAN and the tailnet only.
      networking.firewall.interfaces.${lan} = {
        allowedTCPPorts = [
          22
          80
        ]
        ++ lanPorts
        ++ [ 22000 ];
        allowedUDPPorts = [ 22000 ];
        allowedTCPPortRanges = [
          {
            from = 1714;
            to = 1764;
          }
        ];
        allowedUDPPortRanges = [
          {
            from = 1714;
            to = 1764;
          }
        ];
      };
      # KDE Connect over the tailnet (devices added by IP; discovery is LAN-only).
      networking.firewall.interfaces.tailscale0.allowedTCPPortRanges = [
        {
          from = 1714;
          to = 1764;
        }
      ];
      networking.firewall.interfaces.tailscale0.allowedUDPPortRanges = [
        {
          from = 1714;
          to = 1764;
        }
      ];
      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
        22
        80
        443
        22000
      ];
      networking.firewall.interfaces.tailscale0.allowedUDPPorts = [ 22000 ];
      services.tailscale.enable = true;
      hardware.i2c.enable = true;
      time.timeZone = "Europe/Warsaw";
      i18n.defaultLocale = "en_US.UTF-8";
      console.keyMap = "pl";

      users.defaultUserShell = pkgs.fish;
      users.users.${user} = {
        isNormalUser = true;
        description = config.my.user.description;
        shell = pkgs.fish;
        linger = true;
        extraGroups = [
          "networkmanager"
          "wheel"
          "video"
          "audio"
          "input"
        ];
      };

      programs.fish.enable = true;
      programs.steam.enable = true;
      programs.nix-ld.enable = true;

      security.polkit.enable = true;
      security.polkit.extraConfig = ''
        polkit.addRule(function(action, subject) {
          if (subject.isInGroup("wheel") &&
              [
                "org.freedesktop.login1.reboot",
                "org.freedesktop.login1.reboot-multiple-sessions",
                "org.freedesktop.login1.power-off",
                "org.freedesktop.login1.power-off-multiple-sessions",
                "org.freedesktop.login1.suspend",
                "org.freedesktop.login1.suspend-multiple-sessions"
              ].indexOf(action.id) >= 0) {
            return polkit.Result.YES;
          }
        });
        polkit.addRule(function(action, subject) {
          if (subject.isInGroup("wheel") &&
              action.id == "org.freedesktop.udisks2.filesystem-mount-system") {
            return polkit.Result.YES;
          }
        });
      '';

      services.dbus.enable = true;

      services.udisks2.enable = true;
      # GVfs: network shares (SMB, SFTP), phones over MTP and other gio
      # locations for GTK apps such as Strata (its Network entry needs it).
      services.gvfs.enable = true;
      # SMART disk health monitoring; warnings go to logged-in terminals (wall).
      services.smartd.enable = true;

      # Compressed swap in RAM, used before any disk swap (priority 5 vs. -2).
      # Swapping to zram is cheap, so swappiness is raised and readahead disabled.
      zramSwap = {
        enable = true;
        algorithm = "zstd";
        memoryPercent = 50;
      };
      boot.kernel.sysctl = {
        "vm.swappiness" = 180;
        "vm.page-cluster" = 0;
        # On 2026-11-11 a 32 KiB (order-3) nvidia_drm allocation failed with 5 GB
        # free, all in 4-8 KiB pieces, and the OOM killer ended the session.
        # Wake kswapd/kcompactd earlier (2% of RAM between watermarks) and keep a
        # larger reserve, so contiguous blocks stay available.
        "vm.watermark_scale_factor" = 200;
        "vm.min_free_kbytes" = 262144;
        # Cap dirty page cache (default 20% of RAM, ~6 GB) so writeback to slow
        # USB disks cannot pin gigabytes that reclaim and compaction cannot move.
        "vm.dirty_background_bytes" = 268435456;
        "vm.dirty_bytes" = 1073741824;
      };

      programs.dconf.enable = true;

      services.xserver.enable = false;

    };
}
