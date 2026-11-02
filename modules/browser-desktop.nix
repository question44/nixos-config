{ config, pkgs, ... }:
{
  # Runtime file contains the password hash, never the Nix store or repository.
  systemd.tmpfiles.rules = [
    "d /var/lib/desktop-auth 0750 root caddy -"
    "f /var/lib/desktop-auth/auth.caddy 0640 root caddy - respond 503"
  ];
  environment.systemPackages = [ (pkgs.writeScriptBin "desktop-password" ''
    #!${pkgs.python3}/bin/python3
    import getpass
    import base64
    import grp
    import os
    import subprocess
    import tempfile
    import urllib.request
    from pathlib import Path

    if os.geteuid() != 0:
        raise SystemExit("Run sudo desktop-password in your local terminal.")
    password = getpass.getpass("New desktop password for janzon: ")
    if not password or password != getpass.getpass("Confirm desktop password: "):
        raise SystemExit("Passwords are empty or do not match; nothing changed.")
    if len(password.encode()) > 72:
        raise SystemExit("Use a password of at most 72 UTF-8 bytes; nothing changed.")
    result = subprocess.run(
        ["${config.services.caddy.package}/bin/caddy", "hash-password", "--algorithm", "bcrypt"],
        input=password + "\n", text=True, capture_output=True)
    if result.returncode:
        raise SystemExit("Password hashing failed; nothing changed.")
    password_hash = result.stdout.strip()
    if not password_hash.startswith("$2") or "\n" in password_hash:
        raise SystemExit("Unexpected hash format; nothing changed.")
    target = Path("/var/lib/desktop-auth/auth.caddy")
    previous = target.read_bytes()
    def save(content):
        fd, name = tempfile.mkstemp(prefix=".desktop-auth-", dir=target.parent)
        try:
            os.fchmod(fd, 0o640)
            os.fchown(fd, 0, grp.getgrnam("caddy").gr_gid)
            with os.fdopen(fd, "wb") as stream:
                stream.write(content)
            os.replace(name, target)
        finally:
            if os.path.exists(name):
                os.unlink(name)
    save(("basic_auth {\n  janzon " + password_hash + "\n}\n").encode())
    result = subprocess.run(["${pkgs.systemd}/bin/systemctl", "reload", "caddy"])
    if result.returncode:
        save(previous)
        raise SystemExit("Caddy reload failed; previous password configuration restored.")
    authorization = base64.b64encode(("janzon:" + password).encode()).decode()
    del password
    request = urllib.request.Request(
        "https://desktop.erebor.jzon.pl/vnc.html",
        headers={"Authorization": "Basic " + authorization})
    try:
        with urllib.request.urlopen(request, timeout=10) as response:
            if response.status != 200:
                raise RuntimeError("Unexpected response")
    except Exception:
        save(previous)
        subprocess.run(["${pkgs.systemd}/bin/systemctl", "reload", "caddy"])
        raise SystemExit("Password verification failed; previous configuration restored.")
    print("Desktop password saved and HTTPS login verified. Username: janzon")
  '') ];

  # The browser endpoint is authenticated by tailnet membership. Neither the
  # RFB backend nor a public/LAN HTTP route exposes the desktop.
  systemd.user.services.browser-desktop = {
    description = "Browser access to the current Umbriel desktop";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    path = [ pkgs.jq ];
    serviceConfig = {
      ExecStart = pkgs.writeShellScript "browser-desktop" ''
        export UMBRIEL_SOCKET="''${UMBRIEL_SOCKET:-$XDG_RUNTIME_DIR/umbriel-$WAYLAND_DISPLAY.sock}"
        # The focused output contains the desktop the user is operating.
        output=$(${config.programs.umbriel.package}/bin/umbriel outputs --json | jq -r '.[] | select(.focused and .enabled) | .name')
        test -n "$output"
        exec ${pkgs.wayvnc}/bin/wayvnc -C /dev/null -v -R -r -o "$output" -w 127.0.0.1 15901
      '';
      Restart = "on-failure";
      RestartSec = 5;
      UMask = "0077";
    };
  };

  services.caddy.extraConfig = ''
    (browser_desktop) {
      @desktop_host host desktop.erebor.jzon.pl desktop.moria.jzon.pl
      handle @desktop_host {
        @tailnet remote_ip 127.0.0.1 ::1 100.64.0.0/10 fd7a:115c:a1e0::/48
        handle @tailnet {
          # Keep the runtime gate ahead of every redirect, asset and WebSocket.
          route {
          import /var/lib/desktop-auth/auth.caddy
          redir / /vnc.html?autoconnect=1&resize=scale 302
          handle /websockify {
            @same_origin header_regexp Origin ^https://desktop[.](erebor|moria)[.]jzon[.]pl$
            handle @same_origin {
              reverse_proxy 127.0.0.1:15901
            }
            respond "Invalid desktop WebSocket origin." 403
          }
          handle {
            header Content-Security-Policy "frame-ancestors 'self'"
            root * ${pkgs.novnc}/share/webapps/novnc
            file_server
          }
          }
        }
        respond "Desktop access requires Tailscale." 403
      }
    }
  '';
}
