# VM test of the boot transition Plymouth -> Noctalia greeter, without (node
# "baseline") and with (node "handoff") modules/plymouth-greeter-handoff.nix.
# Records the screen ~every 60 ms via QEMU screendump and writes a timeline of
# screen states plus key frames to $out (<node>-timeline.txt, <node>/fNNNN.ppm).
# Run: nix build --impure -f scripts/tests/plymouth-greeter-handoff-vm.nix \
#        --argstr flake "$PWD" -L -o /tmp/plymouth-vm
# Not a flake check (needs KVM, ~2 min). Plymouth needs
# plymouth.ignore-serial-consoles here: the harness console=ttyS0 forces its
# text "details" mode.
{ flake }:
let
  f = builtins.getFlake (toString flake);
  pkgs = f.inputs.nixpkgs.legacyPackages.x86_64-linux;
  handoff =
    (import "${flake}/modules/plymouth-greeter-handoff.nix")
    .flake.modules.nixos.plymouth-greeter-handoff;
  common =
    { config, lib, ... }:
    {
      imports = [ f.inputs.noctalia-greeter.nixosModules.default ];
      # Mirrors modules/noctalia.nix: greeter patches from feature modules.
      options.programs.noctalia.greeterPatches = lib.mkOption {
        type = lib.types.listOf lib.types.path;
        default = [ ];
      };
      config = {
        services.displayManager.noctalia-greeter.package =
          lib.mkIf (config.programs.noctalia.greeterPatches != [ ])
            (
              f.inputs.noctalia-greeter.packages.x86_64-linux.default.overrideAttrs (old: {
                patches = (old.patches or [ ]) ++ config.programs.noctalia.greeterPatches;
                buildInputs = (old.buildInputs or [ ]) ++ [ pkgs.libdrm ];
              })
            );
        virtualisation.memorySize = 2048;
        virtualisation.cores = 2;
        virtualisation.qemu.options = [
          "-vga none"
          "-device virtio-vga"
        ];
        boot.initrd.kernelModules = [ "virtio_gpu" ];
        boot.plymouth.enable = true;
        boot.plymouth.theme = "spinner";
        boot.consoleLogLevel = lib.mkForce 0;
        boot.kernelParams = [
          "quiet"
          "splash"
          "plymouth.ignore-serial-consoles"
        ];
        users.users.alice = {
          isNormalUser = true;
          password = "x";
        };
        services.displayManager.noctalia-greeter = {
          enable = true;
          settings.user.default = "alice";
        };
        systemd.services.greetd.serviceConfig.Type = lib.mkForce "exec";
        hardware.graphics.enable = true;
      };
    };
in
pkgs.testers.runNixOSTest {
  name = "plymouth-greeter-handoff";
  nodes.baseline = common;
  nodes.handoff = {
    imports = [
      common
      handoff
    ];
  };
  testScript = ''
    import os, time
    out_dir = os.environ.get("out", os.getcwd())

    def stats(path):
        with open(path, "rb") as fh:
            data = fh.read()
        # P6 header: magic, width, height, maxval
        parts = data.split(maxsplit=4)
        w, h = int(parts[1]), int(parts[2])
        px = parts[4]
        n = 0; tot = 0; colours = set()
        step = 3 * 97
        for i in range(0, len(px) - 3, step):
            r, g, b = px[i], px[i+1], px[i+2]
            tot += r + g + b; n += 1
            colours.add((r >> 5, g >> 5, b >> 5))
        return (w, h, round(tot / (3 * max(n, 1)), 1), len(colours))

    def record(m, name, seconds=45):
        d = os.path.join(out_dir, name); os.makedirs(d, exist_ok=True)
        m.start()
        t0 = time.monotonic(); prev = None; timeline = []
        i = 0
        while time.monotonic() - t0 < seconds:
            p = os.path.join(d, f"f{i:04}.ppm")
            m.send_monitor_command(f"screendump {p}")
            t = round(time.monotonic() - t0, 2)
            if os.path.exists(p) and os.path.getsize(p) > 20:
                try:
                    s = stats(p)
                except Exception:
                    s = None
                key = s and (s[0], s[1], int(s[2] // 4), min(s[3], 40) // 4)
                if key != prev:
                    timeline.append((t, i, s)); prev = key
                else:
                    os.remove(p)
            i += 1
            time.sleep(0.05)
        with open(os.path.join(out_dir, name + "-timeline.txt"), "w") as fh:
            for t, idx, s in timeline:
                fh.write(f"{t:7.2f}s  f{idx:04}  {s}\n")
        m.wait_for_unit("greetd.service")
        m.succeed("pgrep -u greeter -f '^[^ ]*/bin/noctalia-greeter( |$)'")
        jr = m.succeed("journalctl -b -o short-monotonic --no-pager -t noctalia-greeter-compositor -g 'boot splash|mapped|enable' || true; journalctl -b -o short-monotonic --no-pager -u plymouth-quit.service -u plymouth-quit-wait.service -u greetd.service -u plymouth-greeter-handoff.service | grep -v pam_ || true")
        with open(os.path.join(out_dir, name + "-journal.txt"), "w") as fh:
            fh.write(jr)
        m.shutdown()

    record(baseline, "baseline")
    record(handoff, "handoff")
    handoff.start()
    handoff.wait_for_unit("plymouth-greeter-handoff.service")
    handoff.succeed("! pgrep -x plymouthd")
    handoff.succeed("systemctl is-active greetd")
  '';
}
