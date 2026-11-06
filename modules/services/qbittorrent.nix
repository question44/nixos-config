{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.services.qbittorrent;
  vpn = config.my.torrentVpn.enable;
  # Fixed container address, so the firewall and routing rules below can match it.
  ip = "10.88.255.250";
  lan = config.my.network.lanInterface;
in
{
  config = lib.mkMerge [
    {
      my.services.qbittorrent = {
        port = 18081;
        localName = "torrent";
        publicName = "torrent";
        lanPort = 8082;
        # The Web UI checks Host/Origin/Referer against its public name.
        proxy.headers = [
          "Host torrent.${config.my.network.domain}"
          "Origin https://torrent.${config.my.network.domain}"
          "Referer https://torrent.${config.my.network.domain}/"
          "-Authorization"
        ];
        proxy.lanHeaders = [ ];
      };
    }
    (lib.mkIf cfg.enable {
      virtualisation.oci-containers.containers.qbittorrent = {
        image = "docker.io/linuxserver/qbittorrent:latest";
        ports = [
          "127.0.0.1:18081:8080"
        ]
        # Peer port on the home IP, so other peers can connect to us for seeding.
        ++ lib.optionals (!vpn) [
          "6881:6881/tcp"
          "6881:6881/udp"
        ];
        # With the VPN, DNS also goes only through the tunnel (Proton's resolver).
        extraOptions = [ "--ip=${ip}" ] ++ lib.optionals vpn [ "--dns=10.2.0.1" ];
        volumes = [
          "/srv/qbittorrent/config:/config"
          "/srv/torrents:/downloads"
          "/srv/external/crucial:/downloads/crucial:rw"
          "/srv/external/seagate:/downloads/seagate:rw"
          "/srv/external/expansion:/downloads/expansion:rw"
          "/srv/external/bigdaddy:/downloads/bigdaddy:rw"
        ];
        environment = {
          PUID = "1000";
          PGID = "1000";
          TZ = "Europe/Warsaw";
          UMASK = "002";
          WEBUI_PORT = "8080";
          TORRENTING_PORT = "6881";
        };
      };
    })
    (lib.mkIf (cfg.enable && !vpn) {
      networking.firewall.interfaces.${lan} = {
        allowedTCPPorts = [ 6881 ];
        allowedUDPPorts = [ 6881 ];
      };
      # While the Proton VPN app is connected it sends everything through
      # proton0. Peers arrive on the LAN side, though, so the reverse-path
      # filter would drop them; let the peer port through.
      # Also drops the VPN-only rule left over from VPN mode.
      networking.firewall.extraCommands = ''
        iptables -w -D FORWARD -s ${ip} -j qbt-vpn-only 2>/dev/null || true
        for proto in tcp udp; do
          iptables -w -t mangle -D nixos-fw-rpfilter -i ${lan} -p "$proto" --dport 6881 -j RETURN 2>/dev/null || true
          iptables -w -t mangle -I nixos-fw-rpfilter 1 -i ${lan} -p "$proto" --dport 6881 -j RETURN
        done
      '';
      # qBittorrent always leaves through the home connection, also while the
      # VPN is up: the main table is looked up before Proton's catch-all rule.
      systemd.services.qbittorrent-direct-route = {
        description = "Route qBittorrent around the VPN";
        before = [ "podman-qbittorrent.service" ];
        wantedBy = [ "multi-user.target" ];
        path = [ pkgs.iproute2 ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          ip rule del from ${ip} lookup main priority 31000 2>/dev/null || true
          ip rule add from ${ip} lookup main priority 31000
        '';
        postStop = "ip rule del from ${ip} lookup main priority 31000 || true";
      };
    })
    (lib.mkIf (cfg.enable && vpn) {
      # qBittorrent reaches the internet only through Proton's WireGuard
      # tunnel (proton0); with the VPN down its traffic is rejected rather
      # than sent from the home IP. Private networks stay reachable. The rule
      # stays when the firewall stops, so it fails closed.
      networking.firewall.extraCommands = ''
        iptables -w -N qbt-vpn-only 2>/dev/null || iptables -w -F qbt-vpn-only
        iptables -w -A qbt-vpn-only -o proton0 -j RETURN
        for net in 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16; do
          iptables -w -A qbt-vpn-only -d "$net" -j RETURN
        done
        iptables -w -A qbt-vpn-only -j REJECT
        iptables -w -D FORWARD -s ${ip} -j qbt-vpn-only 2>/dev/null || true
        iptables -w -I FORWARD 1 -s ${ip} -j qbt-vpn-only
      '';

      # Proton hands out a random forwarded port on P2P servers (NAT-PMP via
      # 10.2.0.1, renewed every 60 s). Send that port from the tunnel to the
      # container and make qBittorrent listen and announce on it. The image
      # resets the port to TORRENTING_PORT on every start, so it is checked
      # each round. Needs WebUI\LocalHostAuth=false in qBittorrent.conf: only
      # processes inside the container connect from 127.0.0.1.
      systemd.services.qbittorrent-vpn-port = {
        description = "Keep qBittorrent on Proton VPN's forwarded port";
        after = [
          "podman-qbittorrent.service"
          "firewall.service"
        ];
        wantedBy = [ "multi-user.target" ];
        path = [
          config.networking.firewall.package
          config.virtualisation.podman.package
          pkgs.iproute2
          pkgs.libnatpmp
          pkgs.gnused
          pkgs.coreutils
        ];
        serviceConfig = {
          Restart = "always";
          RestartSec = 10;
        };
        script = ''
          # A failed NAT-PMP or API call is retried next round.
          set +e
          chain=qbt-vpn-port
          iptables -w -t nat -N "$chain" 2>/dev/null || iptables -w -t nat -F "$chain"
          iptables -w -t nat -C PREROUTING -i proton0 -j "$chain" 2>/dev/null ||
            iptables -w -t nat -I PREROUTING 1 -i proton0 -j "$chain"
          api() { podman exec qbittorrent curl -fsS "$@" 2>/dev/null; }
          mapped=
          while true; do
            port=
            if ip link show proton0 >/dev/null 2>&1; then
              natpmpc -a 1 0 udp 60 -g 10.2.0.1 >/dev/null 2>&1
              port=$(natpmpc -a 1 0 tcp 60 -g 10.2.0.1 2>/dev/null |
                sed -n 's/.*Mapped public port \([0-9]*\) protocol TCP.*/\1/p')
            fi
            if [ "$port" != "$mapped" ]; then
              iptables -w -t nat -F "$chain"
              for proto in tcp udp; do
                [ -n "$port" ] && iptables -w -t nat -A "$chain" -p "$proto" --dport "$port" \
                  -j DNAT --to-destination "${ip}:$port"
              done
              echo "Forwarded port: ''${port:-none}"
              mapped=$port
            fi
            if [ -n "$port" ]; then
              current=$(api http://127.0.0.1:8080/api/v2/app/preferences |
                sed -n 's/.*"listen_port":\([0-9]*\).*/\1/p')
              if [ -n "$current" ] && [ "$current" != "$port" ] &&
                api --data-urlencode "json={\"listen_port\":$port}" \
                  http://127.0.0.1:8080/api/v2/app/setPreferences; then
                echo "qBittorrent now listens on $port (was $current)"
              fi
            fi
            sleep 45
          done
        '';
        postStop = ''
          iptables -w -t nat -D PREROUTING -i proton0 -j qbt-vpn-port 2>/dev/null || true
          iptables -w -t nat -F qbt-vpn-port 2>/dev/null || true
        '';
      };
    })
  ];
}
