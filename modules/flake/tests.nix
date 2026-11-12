# Eval tests: the design rules from AGENTS.md, checked against the evaluated
# hosts by `nix flake check` (checks.x86_64-linux.eval-<name>). Each test is a
# list of failure messages; an empty list passes. Nothing here is built into a
# system, so the tests cost evaluation time only.
{ config, lib, ... }:
let
  hosts = config.flake.nixosConfigurations;
  erebor = hosts.erebor.config;
  template = hosts.template.config;

  check = cond: message: lib.optional (!cond) message;
  unitNames = cfg: lib.attrNames cfg.systemd.services ++ lib.attrNames cfg.systemd.user.services;
  sessionNames = cfg: map (p: lib.getName p) cfg.services.displayManager.sessionPackages;

  # Optional features: unit names that exist only when the feature is on.
  # erebor enables them all, which proves the names are still right.
  featureUnits = [
    "hyperhdr"
    "moonshine"
    "sunshine"
    "ollama"
    "open-webui"
    "searx"
    "samba-smbd"
    "t3code"
    "podman-jellyfin"
    "podman-nextcloud"
    "podman-qbittorrent"
    "podman-syncthing"
  ];

  # A config whose `my.*` is wrong in one way must fail with a message naming
  # the setting. Built on the template so erebor's hardware is not involved.
  failedWith =
    module:
    let
      cfg = (hosts.template.extendModules { modules = [ module ]; }).config;
    in
    map (a: a.message) (lib.filter (a: !a.assertion) cfg.assertions);
  mentions = needle: messages: lib.any (lib.hasInfix needle) messages;

  tests = {
    # Oo7 is the desktop Secret Service; GNOME Keyring and KWallet stay off.
    secret-service =
      lib.concatMap
        (
          { name, cfg }:
          check cfg.services.oo7.enable "${name}: services.oo7.enable is off"
          ++ check (!cfg.services.gnome.gnome-keyring.enable) "${name}: GNOME Keyring is enabled"
          ++ check (lib.all (s: !(s.kwallet.enable or false)) (
            lib.attrValues cfg.security.pam.services
          )) "${name}: a PAM service unlocks KWallet"
        )
        [
          {
            name = "erebor";
            cfg = erebor;
          }
          {
            name = "template";
            cfg = template;
          }
        ];

    # Umbriel is the only session.
    sessions =
      check (sessionNames erebor == [ "umbriel" ]) "erebor: sessions are not exactly [ umbriel ]"
      ++ check (sessionNames template == [ "umbriel" ]) "template: sessions are not exactly [ umbriel ]";

    # Optional features switch off: the template enables none of them.
    features-off =
      map (u: "erebor: expected unit ${u} is gone; update featureUnits in modules/flake/tests.nix") (
        lib.subtractLists (unitNames erebor) featureUnits
      )
      ++ map (u: "template: unit ${u} exists although its feature is off") (
        lib.intersectLists (unitNames template) featureUnits
      )
      ++ check (!template.my.ambilight.enable) "template: my.ambilight is on"
      ++ map (n: "template: my.services.${n} is enabled") (
        lib.attrNames (lib.filterAttrs (_: s: s.enable) template.my.services)
      );

    # The firewall opens exactly these ports. A change here is a deliberate
    # exposure decision: update the list in the same commit.
    firewall =
      let
        fw = erebor.networking.firewall;
        actual = {
          tcp = fw.allowedTCPPorts;
          udp = fw.allowedUDPPorts;
          tcpRanges = fw.allowedTCPPortRanges;
          udpRanges = fw.allowedUDPPortRanges;
          interfaces = lib.mapAttrs (_: i: {
            tcp = i.allowedTCPPorts;
            udp = i.allowedUDPPorts;
            tcpRanges = i.allowedTCPPortRanges;
            udpRanges = i.allowedUDPPortRanges;
          }) fw.interfaces;
        };
        kdeconnect = [
          {
            from = 1714;
            to = 1764;
          }
        ];
        expected = {
          # Sunshine/Moonshine streaming and mDNS.
          tcp = [
            47984
            47989
            48010
          ];
          udp = [
            5353
            47998
            47999
            48000
          ];
          tcpRanges = [ ];
          udpRanges = [ ];
          interfaces = {
            br0 = {
              tcp = [
                22
                80
                445
                6881
                8082
                8095
                8096
                8384
                22000
              ];
              udp = [
                5353
                6881
                22000
              ];
              tcpRanges = kdeconnect;
              udpRanges = kdeconnect;
            };
            "podman+" = {
              tcp = [ 53 ];
              udp = [ 53 ];
              tcpRanges = [ ];
              udpRanges = [ ];
            };
            tailscale0 = {
              tcp = [
                22
                80
                443
                445
                3389
                22000
              ];
              udp = [ 22000 ];
              # KDE Connect from devices added by tailnet IP.
              tcpRanges = kdeconnect;
              udpRanges = kdeconnect;
            };
          };
        };
        sorted =
          v:
          v
          // {
            tcp = lib.sort lib.lessThan v.tcp;
            udp = lib.sort lib.lessThan v.udp;
            interfaces = lib.mapAttrs (
              _: i:
              i
              // {
                tcp = lib.sort lib.lessThan i.tcp;
                udp = lib.sort lib.lessThan i.udp;
              }
            ) v.interfaces;
          };
      in
      check (builtins.toJSON (sorted actual) == builtins.toJSON (sorted expected)) ''
        erebor: open firewall ports changed.
          expected: ${builtins.toJSON (sorted expected)}
          actual:   ${builtins.toJSON (sorted actual)}'';

    # Home Manager manages the main user on every host.
    home-manager =
      check (lib.elem erebor.my.user.name (lib.attrNames erebor.home-manager.users)) "erebor: no Home Manager config for my.user.name"
      ++ check (lib.elem template.my.user.name (lib.attrNames template.home-manager.users)) "template: no Home Manager config for my.user.name";

    # The Mac's nix-darwin config evaluates (it can only be built on the Mac):
    # forcing its drvPath evaluates every option, and the shared Home Manager
    # aspects must keep Linux-only files off it.
    darwin-macbook =
      let
        mac = config.flake.darwinConfigurations.macbook.config;
        files = lib.attrNames mac.home-manager.users.janzon.xdg.configFile;
      in
      check (lib.hasPrefix "/nix/store/" mac.system.build.toplevel.drvPath) "macbook: no system derivation"
      ++ map (f: "macbook: Linux-only file ${f} is deployed") (
        lib.intersectLists files [
          "fish/functions/shell_welcome.fish"
          "noctalia/starship-base.toml"
          "monstar/config"
        ]
      );

    # Every secrets/*.yaml is sops-encrypted: each top-level value is ENC[…]
    # and the file carries sops metadata.
    secrets-encrypted = lib.concatMap (
      name:
      let
        text = builtins.readFile (../../secrets + "/${name}");
        lines = lib.splitString "\n" text;
        topLevel = lib.filter (
          l: builtins.match "[A-Za-z0-9_-]+:.*" l != null && !lib.hasPrefix "sops:" l
        ) lines;
      in
      check (lib.hasInfix "\nsops:" text) "secrets/${name}: no sops metadata"
      ++ map (l: "secrets/${name}: plaintext value: ${lib.head (lib.splitString ":" l)}") (
        lib.filter (l: !lib.hasInfix "ENC[" l) topLevel
      )
    ) (lib.filter (lib.hasSuffix ".yaml") (lib.attrNames (builtins.readDir ../../secrets)));

    # The my.* assertions fire, naming the setting to fix.
    my-assertions =
      check (mentions "my.ambilight.musicSink" (failedWith {
        my.ambilight.enable = true;
      })) "ambilight without musicSink is not reported"
      ++ check (mentions "my.nanokvm.url" (failedWith {
        my.nanokvm.enable = true;
      })) "nanokvm without url is not reported"
      ++ check (mentions "loopback port" (failedWith {
        my.services.jellyfin.enable = true;
        my.services.syncthing = {
          enable = true;
          port = lib.mkForce erebor.my.services.jellyfin.port;
        };
      })) "two services on one port are not reported"
      ++ check (failedWith { } == [ ]) "the template itself fails an assertion";

    # The template's system derivation instantiates: a shared module that needs
    # something only erebor has (a secrets file, hardware) fails here, which
    # evaluating the template's options alone does not show.
    template-instantiates = check (builtins.tryEval hosts.template.config.system.build.toplevel.drvPath).success "template: system.build.toplevel does not evaluate (run nix eval .#nixosConfigurations.template.config.system.build.toplevel.drvPath)";
  };
in
{
  perSystem =
    { pkgs, ... }:
    {
      checks = lib.mapAttrs' (
        name: failures:
        lib.nameValuePair "eval-${name}" (
          pkgs.runCommand "eval-${name}" { } (
            if failures == [ ] then
              "touch $out"
            else
              ''
                cat >&2 <<'EOF'
                eval test ${name} failed:
                ${lib.concatMapStringsSep "\n" (f: "  - ${f}") failures}
                EOF
                exit 1
              ''
          )
        )
      ) tests;
    };
}
