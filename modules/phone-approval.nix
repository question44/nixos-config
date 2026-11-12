# Approve sudo from the phone: a one-time link goes to the phone through KDE
# Connect, and a passkey on the phone (fingerprint) signs the approval.
# docs/phone-approval.md describes enrollment and testing.
{
  flake.modules.nixos.phone-approval =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    let
      cfg = config.my.phoneApproval;
      domain = config.my.network.domain;
      port = config.my.services.phone-approval.port;
      rpId = "${config.my.services.phone-approval.publicName}.${domain}";
      python = pkgs.python3.withPackages (p: [ p.webauthn ]);
      clientPath = lib.makeBinPath [
        pkgs.util-linux # setpriv
        pkgs.kdePackages.kdeconnect-kde
      ];
      client = pkgs.writeShellScriptBin "phone-approval-client" ''
        export PATH=${clientPath}
        export PHONE_APPROVAL_DEVICE=${lib.escapeShellArg cfg.device}
        export PHONE_APPROVAL_TIMEOUT=${toString cfg.timeout}
        exec ${pkgs.python3}/bin/python3 -I ${./phone-approval-client.py} "$@"
      '';
      # Bounded like the Mac step: a stuck helper can't hold up the stack.
      pamStep = pkgs.writeShellScript "phone-approval-pam" ''
        exec ${pkgs.coreutils}/bin/timeout --kill-after=2s ${toString (cfg.timeout + 8)}s \
          ${client}/bin/phone-approval-client approve </dev/null
      '';
      enroll = pkgs.writeShellScriptBin "phone-approval-enroll" ''
        if [ "$(id -u)" != 0 ]; then
          exec /run/wrappers/bin/sudo "$0" "''${1:-''${SUDO_USER:-$USER}}"
        fi
        exec ${client}/bin/phone-approval-client enroll "''${1:?user}"
      '';
    in
    {
      config = lib.mkMerge [
        {
          my.services.phone-approval = {
            port = 18097;
            publicName = "approve";
            # The approval pages are for the tailnet and LAN only.
            extraConfig = ''
              @phone_approval_outside not remote_ip private_ranges 100.64.0.0/10 fd7a:115c:a1e0::/48
              respond @phone_approval_outside 403
            '';
          };
        }
        (lib.mkIf cfg.enable {
          my.services.phone-approval.enable = true;

          systemd.services.phone-approval = {
            description = "Phone (passkey) approval for sudo";
            wantedBy = [ "multi-user.target" ];
            after = [ "network.target" ];
            environment = {
              PHONE_APPROVAL_RP_ID = rpId;
              PHONE_APPROVAL_PORT = toString port;
            };
            serviceConfig = {
              ExecStart = "${python}/bin/python3 -u ${./phone-approval.py}";
              DynamicUser = true;
              StateDirectory = "phone-approval";
              StateDirectoryMode = "0700";
              RuntimeDirectory = "phone-approval";
              RuntimeDirectoryMode = "0700";
              Restart = "on-failure";
              NoNewPrivileges = true;
              ProtectSystem = "strict";
              ProtectHome = true;
              PrivateTmp = true;
              PrivateDevices = true;
              ProtectKernelTunables = true;
              ProtectKernelModules = true;
              ProtectControlGroups = true;
              RestrictAddressFamilies = [
                "AF_UNIX"
                "AF_INET"
                "AF_INET6"
              ];
              RestrictNamespaces = true;
              LockPersonality = true;
              MemoryDenyWriteExecute = true;
              SystemCallArchitectures = "native";
              CapabilityBoundingSet = "";
            };
          };

          # After the Mac step (10700) and before the YubiKey (10900). Sufficient:
          # a refusal, timeout or unreachable phone continues down the stack, so
          # the YubiKey and the Unix password keep working.
          security.pam.services.sudo.rules.auth.phone = {
            order = config.security.pam.services.sudo.rules.auth.rssh.order + 100;
            control = "sufficient";
            modulePath = "${pkgs.pam}/lib/security/pam_exec.so";
            args = [
              "quiet"
              "seteuid"
              (toString pamStep)
            ];
          };

          environment.systemPackages = [ enroll ];
        })
      ];
    };
}
