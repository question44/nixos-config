# Vicinae launcher: the package, its privileged input-server wrapper (for
# paste and snippets), the user service started with the session, and the
# launcher opacity from home/appearance.nix.
{ inputs, ... }:
{
  flake.modules.nixos.vicinae =
    { pkgs, ... }:
    {
      imports = [ inputs.vicinae.nixosModules.default ];
      environment.systemPackages = [
        inputs.vicinae.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];
    };

  flake.modules.homeManager.vicinae =
    { config, pkgs, ... }:
    let
      vicinae = inputs.vicinae.packages.${pkgs.stdenv.hostPlatform.system}.default;
    in
    {
      # Vicinae's GUI rewrites settings.json, so the Nix-managed values live in
      # an import it lists ("imports": ["./nix.json"]); settings.json still wins
      # for any key it sets itself. nix.json is the launcher opacity for the
      # current theme mode, picked by erebor-theme-opacity (home/theme-opacity.nix).
      xdg.configFile."vicinae/nix.json".source =
        config.lib.file.mkOutOfStoreSymlink "${config.xdg.stateHome}/erebor-theme-opacity/vicinae.json";
      xdg.configFile."systemd/user/graphical-session.target.wants/vicinae.service".source =
        "${vicinae}/share/systemd/user/vicinae.service";
      xdg.configFile."systemd/user/vicinae.service.d/override.conf".text = ''
        [Service]
        ExecStart=
        ExecStart=${vicinae}/bin/vicinae server --replace
      '';
    };
}
