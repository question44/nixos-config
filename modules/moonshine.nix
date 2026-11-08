# The Moonshine game-streaming server (my.streaming.moonshine).
{ inputs, ... }:
{
  flake.modules.nixos.moonshine = {
    imports = [
      inputs.moonshine.nixosModules.default
      (
        {
          config,
          lib,
          pkgs,
          ...
        }:
        let
          user = config.my.user.name;
        in
        {
          config = lib.mkIf config.my.streaming.moonshine.enable {
            users.users.${user}.extraGroups = [ "moonshine" ];
            services.moonshine = {
              enable = true;
              user = "${user}";
              uid = 1000;
              openFirewall = true;
              settings = {
                name = "Erebor Moonshine";
                application = [
                  {
                    title = "Steam Big Picture";
                    steam_integration = true;
                    command = [
                      "${pkgs.steam}/bin/steam"
                      "steam://open/bigpicture"
                    ];
                  }
                ];
              };
            };
          };
        }
      )
    ];
  };
}
