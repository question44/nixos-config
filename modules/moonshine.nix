{ pkgs, ... }:
{
  users.users.janzon.extraGroups = [ "moonshine" ];
  services.moonshine = {
    enable = true;
    user = "janzon";
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
