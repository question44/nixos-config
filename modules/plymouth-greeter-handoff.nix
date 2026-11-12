# Plymouth hands the screen straight to the Noctalia greeter, the way GDM does,
# instead of quitting first and leaving a black or console gap.
# - plymouth-quit.service conflicts with greetd, so the splash stays up while
#   greetd starts; greetd no longer waits for plymouth-quit-wait (which only
#   finishes once Plymouth has exited).
# - Before greetd starts the greeter, `plymouth deactivate` stops Plymouth
#   drawing and drops DRM master; its last frame stays on screen until the
#   greeter's compositor takes over the display.
# - Once the greeter client is running, `plymouth quit --retain-splash` ends
#   Plymouth without clearing the screen. If greetd fails, plymouth-quit runs.
# - patches/noctalia-greeter-keep-splash.patch: the greeter's compositor copies
#   the splash frame still on screen before its first modeset and shows it
#   instead of black until the greeter has drawn a full-size frame. Source:
#   ~/src/noctalia-greeter-splash, branch keep-plymouth-splash on the pinned
#   input rev; the patch is `git format-patch -1` there.
# - patches/greetd-keep-plymouth-splash.patch: greetd leaves the VT in graphics
#   mode (no text mode, no clear) while /run/plymouth/pid exists.
# plymouthd accepts commands only from root, so this runs in system units, not
# in the greeter (which runs as the greeter user).
{
  flake.modules.nixos.plymouth-greeter-handoff =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      plymouth = "${config.boot.plymouth.package}/bin/plymouth";
      greeterUser = config.services.greetd.settings.default_session.user;
    in
    lib.mkMerge [
      # Kept apart from the greetd condition: the greeter package feeds greetd's config.
      (lib.mkIf config.boot.plymouth.enable {
        programs.noctalia.greeterPatches = lib.mkOrder 2000 [
          ../patches/noctalia-greeter-keep-splash.patch
        ];
      })
      (lib.mkIf (config.boot.plymouth.enable && config.services.greetd.enable) {
        # Drops greetd's After=plymouth-quit-wait.service (nixpkgs option).
        services.greetd.greeterManagesPlymouth = true;

        # greetd switches the VT to text mode and clears it before every session,
        # which lets the console repaint over the splash; skip that while
        # Plymouth is still running (only the greeter's start at boot).
        services.greetd.package = pkgs.greetd.overrideAttrs (old: {
          patches = (old.patches or [ ]) ++ [ ../patches/greetd-keep-plymouth-splash.patch ];
        });

        systemd.services.greetd = {
          after = [
            "plymouth-start.service"
            "plymouth-quit.service"
          ];
          conflicts = [ "plymouth-quit.service" ];
          onFailure = [ "plymouth-quit.service" ];
          serviceConfig.ExecStartPre = [ "-${plymouth} deactivate" ];
        };

        systemd.services.plymouth-greeter-handoff = {
          description = "Hand the Plymouth splash over to the greeter";
          after = [ "greetd.service" ];
          wantedBy = [ "greetd.service" ];
          path = [ pkgs.procps ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
          script = ''
            ${plymouth} --ping || exit 0
            # Wait (up to 15 s) for the greeter client, then give it a moment to
            # draw its first frame before Plymouth exits.
            for _ in $(seq 150); do
              if pgrep -u ${greeterUser} -f '^[^ ]*/bin/noctalia-greeter( |$)' >/dev/null; then
                sleep 1.5
                break
              fi
              sleep 0.1
            done
            ${plymouth} quit --retain-splash
          '';
        };
      })
    ];
}
