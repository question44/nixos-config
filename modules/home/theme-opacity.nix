# Lower opacity in light mode. Noctalia's `started` and `theme_mode_changed`
# hooks (home/noctalia/config.toml) run `erebor-theme-opacity`, which
# - links the app configs that carry home/appearance.nix's appOpacity for that
#   mode (Ghostty's include, Monstar's config, Vicinae's nix.json) from
#   ~/.local/state/erebor-theme-opacity, then makes the running terminals reload
#   (Ghostty: SIGUSR2, Monstar: SIGUSR1; Vicinae watches its files);
# - sets the icon theme to Fluent-dark / Fluent-light (dconf for GTK,
#   kdeglobals for Qt/KDE) and tells running apps to reload their icons;
# - on a mode change, remembers Noctalia's surface opacities and Darkly's (Qt
#   apps: Dolphin...) as they were in the old mode and restores the new mode's.
#   A mode never seen before gets the old mode's values scaled by
#   appOpacity.light / appOpacity.dark. So tuning either in the settings
#   window (or darklyrc) sticks to the mode it was made in.
# Zed and Zen pick their per-mode alpha themselves (zed.json template, Zen CSS).
{
  flake.modules.homeManager.theme-opacity =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      opacity = import ./_opacity.nix lib;
      state = "${config.xdg.stateHome}/erebor-theme-opacity";
      variant =
        mode:
        let
          o = opacity.${mode};
        in
        pkgs.linkFarm "theme-opacity-${mode}" {
          ghostty = pkgs.writeText "ghostty-opacity-${mode}" "background-opacity = ${o.value}\n";
          monstar = pkgs.replaceVars ../../home/monstar/config { appOpacity = o.value; };
          "vicinae.json" = pkgs.writeText "vicinae-opacity-${mode}.json" (
            builtins.toJSON { launcher_window.opacity = builtins.fromJSON o.value; }
          );
        };
      variants = pkgs.linkFarm "theme-opacity" {
        dark = variant "dark";
        light = variant "light";
      };
      script = pkgs.writeShellApplication {
        name = "erebor-theme-opacity";
        runtimeInputs = with pkgs; [
          coreutils
          gawk
          procps
          dbus
          dconf
          kdePackages.kconfig
        ];
        text = ''
          # Usage: erebor-theme-opacity [dark|light] [--links-only]
          # Without a mode: $NOCTALIA_THEME_MODE (hooks), else Noctalia's current mode.
          export PATH="$PATH:/etc/profiles/per-user/$USER/bin"
          state=${lib.escapeShellArg state}
          variants=${variants}
          ratio=${toString opacity.ratio}
          noctalia_keys=(
            bar.default.background_opacity
            bar.default.capsule_opacity
            osd.background_opacity
            notification.background_opacity
          )
          darkly_keys=(
            DolphinSidebarOpacity
            DolphinViewOpacity
            MenuBarOpacity
            MenuOpacity
            TabBarOpacity
            ToolBarOpacity
          )
          darklyrc="''${XDG_CONFIG_HOME:-$HOME/.config}/darklyrc"

          mode="''${1:-''${NOCTALIA_THEME_MODE:-}}"
          if [ -z "$mode" ]; then
            mode="$(noctalia msg theme-mode-get 2>/dev/null || true)"
          fi
          case "$mode" in dark | light) ;; *) mode=dark ;; esac
          previous="''${NOCTALIA_THEME_MODE_PREVIOUS:-}"

          mkdir -p "$state"
          for f in ghostty monstar vicinae.json; do
            ln -sfn "$variants/$mode/$f" "$state/$f"
          done
          printf '%s\n' "$mode" > "$state/mode"

          # Icon theme follows the mode too: GTK reads dconf, Qt/KDE kdeglobals.
          icons="Fluent-$mode"
          dconf write /org/gnome/desktop/interface/icon-theme "'$icons'" || true
          kwriteconfig6 --file "''${XDG_CONFIG_HOME:-$HOME/.config}/kdeglobals" \
            --group Icons --key Theme "$icons" || true
          dbus-send --session --type=signal /KIconLoader org.kde.KIconLoader.iconChanged int32:0 || true
          dbus-send --session --type=signal /KGlobalSettings org.kde.KGlobalSettings.notifyChange int32:4 int32:0 || true
          [ "''${2:-}" = --links-only ] && exit 0

          pkill -USR2 -x 'ghostty|\.ghostty-wrappe' || true
          pkill -USR1 -x monstar || true

          case "$previous" in dark | light) ;; *) exit 0 ;; esac
          [ "$previous" != "$mode" ] || exit 0
          if [ "$mode" = light ]; then factor="$ratio"; else factor="$(awk -v r="$ratio" 'BEGIN { print 1 / r }')"; fi

          # Noctalia surfaces (its settings.toml overrides, set over IPC).
          saved="$state/noctalia-$previous"
          : > "$saved.tmp"
          for k in "''${noctalia_keys[@]}"; do
            v="$(noctalia msg config-get "$k" 2>/dev/null || true)"
            [[ "$v" =~ ^[0-9.]+$ ]] && printf '%s %s\n' "$k" "$v" >> "$saved.tmp"
          done
          mv "$saved.tmp" "$saved"
          if [ -s "$state/noctalia-$mode" ]; then
            source_file="$state/noctalia-$mode"; scale=1
          else
            source_file="$saved"; scale="$factor"
          fi
          while read -r k v; do
            new="$(awk -v v="$v" -v f="$scale" 'BEGIN { x = v * f; if (x > 1) x = 1; printf "%.3f", x }')"
            noctalia msg config-set "$k" "$new" >/dev/null 2>&1 || true
          done < "$source_file"

          # Darkly (Qt style): [Style] *Opacity keys, 0-100, then tell running apps.
          [ -f "$darklyrc" ] || exit 0
          saved="$state/darkly-$previous"
          awk -F= -v keys="''${darkly_keys[*]}" '
            BEGIN { n = split(keys, a, " "); for (i = 1; i <= n; i++) want[a[i]] = 1 }
            /^\[/ { style = ($0 == "[Style]") }
            style && ($1 in want) { print $1, $2 }
          ' "$darklyrc" > "$saved"
          if [ -s "$state/darkly-$mode" ]; then
            source_file="$state/darkly-$mode"; scale=1
          else
            source_file="$saved"; scale="$factor"
          fi
          awk -v f="$scale" -v src="$source_file" '
            BEGIN {
              while ((getline line < src) > 0) {
                split(line, p, " "); x = int(p[2] * f + 0.5); if (x > 100) x = 100; val[p[1]] = x
              }
            }
            /^\[/ { style = ($0 == "[Style]") }
            {
              split($0, kv, "=")
              if (style && (kv[1] in val)) { print kv[1] "=" val[kv[1]]; next }
              print
            }
          ' "$darklyrc" > "$darklyrc.tmp"
          mv "$darklyrc.tmp" "$darklyrc"
          dbus-send --session --type=signal /DarklyStyle org.kde.Darkly.Style.reparseConfiguration || true
        '';
      };
    in
    {
      home.packages = [ script ];
      # Keep the links valid after a rebuild (new variants), in the last mode used;
      # dark before the first switch.
      home.activation.themeOpacityLinks = lib.hm.dag.entryAfter [ "writeBoundary" "dconfSettings" ] ''
        mode="$(${pkgs.coreutils}/bin/cat ${lib.escapeShellArg state}/mode 2>/dev/null || echo dark)"
        run ${script}/bin/erebor-theme-opacity "$mode" --links-only
      '';
    };
}
