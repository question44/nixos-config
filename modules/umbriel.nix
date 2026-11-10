# Umbriel, the primary compositor: the system session and its Home Manager
# configuration (home/umbriel/config.toml) with the helper scripts it binds.
{ inputs, ... }:
let
  # Upstream Umbriel plus local patches. backdrop-effect adds the "backdrop"
  # effect kind that the liquid-glass rule uses (shader drawn by the window's
  # blur node, under the window). touchpad-gestures adds
  # input.touchpad.three_finger_drag, moves workspace swipes to four fingers
  # and opens the overview with a four-finger pinch; it applies on top of
  # backdrop-effect (~/src/umbriel, branch touchpad-gestures). Both the system
  # and Home Manager install it.
  patched =
    pkgs:
    inputs.umbriel.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [
        ../patches/umbriel-backdrop-effect.patch
        ../patches/umbriel-touchpad-gestures.patch
      ];
    });
in
{
  flake.modules.nixos.umbriel =
    { pkgs, ... }:
    {
      imports = [ inputs.umbriel.nixosModules.default ];
      programs.umbriel = {
        enable = true;
        package = patched pkgs;
      };
    };

  flake.modules.homeManager.umbriel =
    {
      config,
      osConfig,
      pkgs,
      ...
    }:
    {
      imports = [ inputs.umbriel.homeModules.default ];
      programs.umbriel = {
        enable = true;
        package = patched pkgs;
        # Live: a link into the checkout (my.flakePath), which Umbriel watches
        # through the symlinks, so a saved edit applies without a rebuild.
        settings = config.lib.file.mkOutOfStoreSymlink "${osConfig.my.flakePath}/home/umbriel/config.toml";
      };
      home.file.".local/bin/umbriel-scratchpad-hint" = {
        source = pkgs.replaceVars ../home/umbriel/scratchpad-hint {
          inherit (pkgs) libnotify systemd;
        };
        executable = true;
      };
      home.file.".local/bin/umbriel-scratchpad-navigate" = {
        source = ../home/umbriel/scratchpad-navigate;
        executable = true;
      };
      home.file.".local/bin/umbriel-caps-q" = {
        source = ../home/umbriel/caps-q-window;
        executable = true;
      };
      home.file.".local/bin/umbriel-focus-or-launch" = {
        source = ../home/umbriel/focus-or-launch;
        executable = true;
      };
      home.file.".local/bin/umbriel-screenshot-window" = {
        source = ../home/umbriel/screenshot-window;
        executable = true;
      };
      home.file.".local/bin/umbriel-monstar-tab" = {
        source = ../home/umbriel/monstar-tab;
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
    };
}
