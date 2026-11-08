# Vicinae launcher: the package, its privileged input-server wrapper (for
# paste and snippets), and the user service started with the session.
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

  flake.modules.homeManager.vicinae = {
    xdg.configFile."systemd/user/graphical-session.target.wants/vicinae.service".source =
      "${inputs.vicinae.packages.x86_64-linux.default}/share/systemd/user/vicinae.service";
    xdg.configFile."systemd/user/vicinae.service.d/override.conf".text = ''
      [Service]
      ExecStart=
      ExecStart=${inputs.vicinae.packages.x86_64-linux.default}/bin/vicinae server --replace
    '';
  };
}
