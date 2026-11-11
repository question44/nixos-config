# Zen browser: translucent chrome over Noctalia's zen-browser theme, at
# home/appearance.nix's zenOpacity (or appOpacity per theme mode when null). Noctalia's apply.sh owns the first
# @import in each profile's userChrome.css and keeps other lines; this adds a
# second @import after it. Zen reads userChrome.css only at startup.
{
  flake.modules.homeManager.zen =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      opacity = import ./_opacity.nix lib;
      zenOpacity = (import ../../home/appearance.nix).zenOpacity;
      zenPercent = toString (builtins.floor (zenOpacity * 100 + 0.5));
      css = "${config.xdg.configHome}/zen/translucent.css";
    in
    {
      xdg.configFile."zen/translucent.css".source = pkgs.replaceVars ../../home/zen/translucent.css {
        darkPercent = if zenOpacity == null then opacity.dark.percent else zenPercent;
        lightPercent = if zenOpacity == null then opacity.light.percent else zenPercent;
      };

      # Profiles are created by Zen under random names, so patch each one in
      # place: drop any old copy of the line, then put it right after the
      # leading @import lines (an @import after a rule is ignored).
      home.activation.zenTranslucentChrome = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        line='@import "${css}";'
        for prefs in "${config.xdg.configHome}"/zen/*/prefs.js; do
          [ -f "$prefs" ] || continue
          chrome="$(${pkgs.coreutils}/bin/dirname "$prefs")/chrome"
          run ${pkgs.coreutils}/bin/mkdir -p "$chrome"
          file="$chrome/userChrome.css"
          [ -e "$file" ] || run ${pkgs.coreutils}/bin/touch "$file"
          new="$(${pkgs.gawk}/bin/awk -v line="$line" '
            $0 == line { next }
            !done && !/^@import / { print line; done = 1 }
            { print }
            END { if (!done) print line }
          ' "$file")"
          if [ "$new" != "$(${pkgs.coreutils}/bin/cat "$file")" ]; then
            if [ -z "''${DRY_RUN:-}" ]; then printf '%s\n' "$new" > "$file"; fi
            verboseEcho "zen: imported translucent.css in $file"
          fi
        done
      '';
    };
}
