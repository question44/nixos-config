# Spotify themed by Noctalia through Spicetify (Comfy theme): the patched
# launcher system-wide, and the theme files and first-run setup for the user.
let
  comfyFor =
    pkgs:
    pkgs.fetchFromGitHub {
      owner = "Comfy-Themes";
      repo = "Spicetify";
      rev = "32ff101e27cfd33d85b7cc587f7f95db6b2df8b0";
      sha256 = "0zc1cf17a0k1fmfs8g7lj0kpiyqk169g20gpkyi4sb2cf94ydaxj";
    };
  prepareFor =
    pkgs:
    pkgs.writeShellApplication {
      name = "spotify-noctalia-prepare";
      runtimeInputs = [
        pkgs.coreutils
        pkgs.gnused
        pkgs.util-linux
        pkgs.spicetify-cli
      ];
      text = ''
        config_dir="''${XDG_CONFIG_HOME:-$HOME/.config}"
        data_dir="''${XDG_DATA_HOME:-$HOME/.local/share}/spotify-noctalia"
        app_dir="$data_dir/${builtins.baseNameOf (toString pkgs.spotify)}"
        mkdir -p "$data_dir" "$config_dir/spicetify"
        exec 9>"$data_dir/prepare.lock"
        flock 9
        if [ ! -d "$app_dir" ]; then
          staging="$(mktemp -d "$data_dir/.prepare.XXXXXX")"
          cp -a --reflink=auto ${pkgs.spotify}/share/spotify/. "$staging/"
          chmod -R u+w "$staging"
          # Spotify's Nix wrapper otherwise starts the original store binary.
          sed -i "s|${pkgs.spotify}/share/spotify/|$app_dir/|g" "$staging/spotify"
          mv "$staging" "$app_dir"
        fi
        spicetify config spotify_path "$app_dir" \
          prefs_path "$config_dir/spotify/prefs" \
          current_theme Comfy color_scheme Comfy \
          inject_css 1 replace_colors 1 overwrite_assets 1 inject_theme_js 1 \
          check_spicetify_update 0
        if [ ! -e "$app_dir/.noctalia-initialized" ]; then
          spicetify --no-restart backup apply
          touch "$app_dir/.noctalia-initialized"
        fi
        ln -sfn "$app_dir" "$data_dir/current"
      '';
    };
in
{
  flake.modules.nixos.spotify =
    { pkgs, ... }:
    let
      prepare = prepareFor pkgs;
      launcher = pkgs.writeShellApplication {
        name = "spotify";
        text = ''
          ${prepare}/bin/spotify-noctalia-prepare
          exec "''${XDG_DATA_HOME:-$HOME/.local/share}/spotify-noctalia/current/spotify" "$@"
        '';
      };
      spotify = pkgs.symlinkJoin {
        name = "spotify-noctalia-${pkgs.spotify.version}";
        paths = [
          launcher
          pkgs.spotify
          prepare
        ];
        postBuild = ''
          # Use our launcher even when the desktop entry specifies an absolute path.
          rm "$out/share/applications/spotify.desktop"
          substitute ${pkgs.spotify}/share/applications/spotify.desktop \
            "$out/share/applications/spotify.desktop" \
            --replace-fail 'Exec=spotify' "Exec=$out/bin/spotify"
        '';
      };
    in
    {
      environment.systemPackages = [
        spotify
        pkgs.spicetify-cli
        # Native Spotify client (egui); Noctalia's spotifast template themes it.
        # nixpkgs ships 0.14.2; drop this override once it has 0.17.1 or newer.
        (pkgs.spotifast.overrideAttrs (
          finalAttrs: old: {
            version = "0.17.1";
            src = old.src.override {
              tag = "v${finalAttrs.version}";
              hash = "sha256-6BJpFjv0xSSQnk9/xRtsShsKUHup7uRDACPQLSKdwgg=";
            };
            cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
              inherit (finalAttrs) src;
              hash = "sha256-4ozZxNRENy6qd9+l46dQQIx3bw0Ig/A1G4TXIYq0kMI=";
            };
            # The test phase recompiles everything with thin LTO; two of those
            # rustc jobs at once were OOM-killed here (2026-11-10).
            doCheck = false;
            # Soloist, the Spotify player Spotifast downloads, runs through nix-ld
            # and inherits this wrapper's environment. It dlopens its audio
            # libraries, which are neither here nor in nix-ld's set, so it played
            # nothing and paused every track at once.
            postFixup = old.postFixup + ''
              wrapProgram $out/bin/spotifast \
                --prefix LD_LIBRARY_PATH : ${
                  pkgs.lib.makeLibraryPath [
                    pkgs.pipewire
                    pkgs.libpulseaudio
                  ]
                }
            '';
          }
        ))
      ];
    };

  flake.modules.homeManager.spotify =
    { lib, pkgs, ... }:
    let
      comfy = comfyFor pkgs;
    in
    {
      xdg.configFile."spicetify/Themes/Comfy/user.css".source = "${comfy}/Comfy/app.css";
      xdg.configFile."spicetify/Themes/Comfy/theme.js".source = "${comfy}/Comfy/theme.script.js";
      xdg.configFile."spicetify/Themes/Comfy/assets".source = "${comfy}/Comfy/assets";
      home.activation.spotifyNoctaliaTheme = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        run ${prepareFor pkgs}/bin/spotify-noctalia-prepare
      '';
    };
}
