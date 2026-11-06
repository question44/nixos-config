# Umbriel and Niri, xremap, Vicinae, and the helper scripts they call.
{
  lib,
  pkgs,
  osConfig,
  umbriel,
  vicinae,
  ...
}:
let
  rcmdPython = pkgs.python3.withPackages (ps: [ ps.pygobject3 ]);
  rcmd = pkgs.writeShellScript "rcmd" ''
    export GI_TYPELIB_PATH="${pkgs.glib.out}/lib/girepository-1.0"
    export RCMD_GIO="${pkgs.glib.bin}/bin/gio"
    exec ${rcmdPython}/bin/python3 ${../rcmd/rcmd.py} "$@"
  '';
in
lib.mkMerge [
  {
    programs.umbriel = {
      enable = true;
      settings = ../umbriel/config.toml;
    };
    xdg.configFile."systemd/user/graphical-session.target.wants/vicinae.service".source =
      "${vicinae.packages.x86_64-linux.default}/share/systemd/user/vicinae.service";
    xdg.configFile."systemd/user/vicinae.service.d/override.conf".text = ''
      [Service]
      ExecStart=
      ExecStart=${vicinae.packages.x86_64-linux.default}/bin/vicinae server --replace
    '';
    xdg.configFile."xremap/config.yml".source = ../xremap/config.yml;
    home.file.".local/bin/reboot-windows" = {
      source = ../reboot-windows.py;
      executable = true;
    };
    home.file.".local/bin/rcmd" = {
      source = rcmd;
      executable = true;
    };
    home.file.".local/bin/xremap-focus-or-launch" = {
      source = ../xremap/focus-or-launch;
      executable = true;
    };
    home.file.".local/bin/umbriel-scratchpad-hint" = {
      source = pkgs.replaceVars ../umbriel/scratchpad-hint {
        inherit (pkgs) libnotify systemd;
      };
      executable = true;
    };
    home.file.".local/bin/umbriel-scratchpad-navigate" = {
      source = ../umbriel/scratchpad-navigate;
      executable = true;
    };
    home.file.".local/bin/umbriel-caps-q" = {
      source = ../umbriel/caps-q-window;
      executable = true;
    };
    home.file.".local/bin/umbriel-focus-or-launch" = {
      source = ../umbriel/focus-or-launch;
      executable = true;
    };
    home.file.".local/bin/umbriel-screenshot-window" = {
      source = ../umbriel/screenshot-window;
      executable = true;
    };
    home.file.".local/bin/umbriel-monstar-tab" = {
      source = ../umbriel/monstar-tab;
      executable = true;
    };
    home.file.".local/bin/umbriel-hdr-toggle" = {
      source = pkgs.writeShellScript "umbriel-hdr-toggle" ''
        set -euo pipefail

        output="DP-1"
        hdr_active="$(umbriel outputs --json | jq -r --arg name "$output" '.[] | select(.name == $name) | .hdr_active')"
        case "$hdr_active" in
          true) hdr="off" ;;
          false) hdr="on" ;;
          *) exit 1 ;;
        esac

        runtime_dir="''${XDG_RUNTIME_DIR:?}"
        display="''${WAYLAND_DISPLAY:-wayland-0}"
        display="''${display//[^a-zA-Z0-9_.-]/_}"
        profile="$runtime_dir/umbriel-hdr-$display.toml"
        temporary="$profile.tmp.$$"
        umask 077
        trap 'rm -f "$temporary"' EXIT
        cat > "$temporary" <<EOF
        [include]
        files = ["$HOME/.config/umbriel/config.toml"]

        [output."$output"]
        hdr = "$hdr"
        EOF
        mv "$temporary" "$profile"
        trap - EXIT
        exec umbriel config-replace "$profile"
      '';
      executable = true;
    };
    home.file.".local/bin/noctalia-bar-focus" = {
      source = pkgs.writeShellScript "noctalia-bar-focus" ''
        set -euo pipefail

        direction="''${1:-}"
        case "$direction" in
          left|right) ;;
          *) exit 2 ;;
        esac

        if umbriel windows --json >/dev/null 2>&1; then
          exec umbriel msg "window-focus-$direction"
        else
          exec niri msg action "focus-column-$direction"
        fi
      '';
      executable = true;
    };
    home.file.".local/bin/noctalia-bar-autohide" = {
      source = ../noctalia/bar-autohide;
      executable = true;
    };
  }
  # Niri's config and helper scripts, when Niri is installed.
  (lib.mkIf osConfig.my.niri.enable {
    xdg.configFile."systemd/user/niri-overview-wallpaper.service.d/override.conf".source =
      ../systemd/niri-overview-wallpaper-override.conf;
    xdg.configFile."niri/config.kdl".source = ../niri/config.kdl;
    home.file.".local/bin/niri-overview-wallpaper" = {
      source = ../dolphin/niri-overview-wallpaper;
      executable = true;
    };
    home.file.".local/bin/niri-caps-q" = {
      source = ../niri/caps-q-window;
      executable = true;
    };
    home.file.".local/bin/niri-focus-or-launch" = {
      source = ../niri/focus-or-launch;
      executable = true;
    };
    home.file.".local/bin/niri-background-apps-last" = {
      source = ../niri/background-apps-last;
      executable = true;
    };
    home.file.".local/bin/niri-caps-q-quit" = {
      source = ../niri/caps-q-quit;
      executable = true;
    };
    home.file.".local/share/kio/servicemenus/set-niri-overview-wallpaper.desktop" = {
      source = ../dolphin/set-niri-overview-wallpaper.desktop;
      executable = true;
    };
  })
]
