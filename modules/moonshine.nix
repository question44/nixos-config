{ config, pkgs, ... }:
let
  user = config.my.user;
in
{
  users.users.${user}.extraGroups = [ "moonshine" ];
  services.moonshine = {
    enable = true;
    user = "${user}";
    uid = 1000;
    openFirewall = true;
    settings = {
      name = "Erebor Moonshine";
      application = [ {
        title = "Steam Big Picture";
        steam_integration = true;
        command = [ "${pkgs.steam}/bin/steam" "steam://open/bigpicture" ];
      } ];
    };
  };
}
