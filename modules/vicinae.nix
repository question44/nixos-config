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
    { lib, ... }:
    {
      # Vicinae's GUI rewrites settings.json, so the Nix-managed values live in
      # an import it lists ("imports": ["./nix.json"]); settings.json still wins
      # for any key it sets itself.
      xdg.configFile."vicinae/nix.json".text = builtins.toJSON {
        launcher_window.opacity = builtins.fromJSON (import ./home/_opacity.nix lib).value;
      };
      xdg.configFile."systemd/user/graphical-session.target.wants/vicinae.service".source =
        "${inputs.vicinae.packages.x86_64-linux.default}/share/systemd/user/vicinae.service";
      xdg.configFile."systemd/user/vicinae.service.d/override.conf".text = ''
        [Service]
        ExecStart=
        ExecStart=${inputs.vicinae.packages.x86_64-linux.default}/bin/vicinae server --replace
      '';
    };
}
