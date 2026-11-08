# Steam through Millennium with the Material theme, recoloured by Noctalia.
{ inputs, ... }:
let
  themeFor =
    pkgs:
    let
      material = pkgs.fetchFromGitHub {
        owner = "kuska1";
        repo = "Material-Theme";
        rev = "7a2852552eaf3cbadadb623e6e7703956854e730";
        sha256 = "1a0p5rlncf7mld6vklcrsacjwbaxz3scgymgqyza8zmhhaxnviqj";
      };
    in
    pkgs.runCommand "steam-material-noctalia" { } ''
      cp -r ${material} "$out"
      chmod -R u+w "$out"
      # Leave this generated file writable for Noctalia.
      rm -f "$out/css/main/colors/matugen.css"
    '';
in
{
  flake.modules.nixos.steam-theme =
    { lib, pkgs, ... }:
    {
      # Last, as when flake.nix added it: it must see the other overlays' changes.
      nixpkgs.overlays = lib.mkAfter [ inputs.millennium.overlays.default ];
      programs.steam.package = pkgs.millennium-steam;
    };

  flake.modules.homeManager.steam-theme =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      home.file.".local/share/Steam/steamui/skins/Material-Theme" = {
        source = themeFor pkgs;
        recursive = true;
      };
      # Millennium 3 uses a new theme root; Noctalia still writes the legacy path.
      home.file.".local/share/Steam/millennium/themes/Material-Theme".source =
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.local/share/Steam/steamui/skins/Material-Theme";
      home.activation.steamNoctaliaTheme = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        settings="$HOME/.config/millennium/config.json"
        run ${pkgs.coreutils}/bin/mkdir -p "$(dirname "$settings")"
        if [ ! -e "$settings" ]; then
          run ${pkgs.coreutils}/bin/install -m 600 ${
            pkgs.writeText "millennium-noctalia-config.json" (
              builtins.toJSON {
                themes = {
                  activeTheme = "Material-Theme";
                  conditions.Material-Theme.Color = "Matugen";
                };
              }
            )
          } "$settings"
        fi
      '';
    };
}
