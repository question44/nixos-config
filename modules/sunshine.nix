{ config, lib, pkgs, ... }:

let
  output = pkgs.writeShellApplication {
    name = "sunshine-output";
    runtimeInputs = [ config.programs.umbriel.package pkgs.jq ];
    text = builtins.readFile ../home/sunshine/output.sh;
  };
in
{
  environment.systemPackages = [ output ];

  services.sunshine = {
    enable = true;
    openFirewall = true;
    # Compositor capture does not require the privileged KMS wrapper.
    capSysAdmin = false;
    settings = {
      sunshine_name = "erebor";
      capture = "wlr";
      encoder = "nvenc";
      output_name = "sunshine";
      upnp = "disabled";
      origin_web_ui_allowed = "lan";
      global_prep_cmd = builtins.toJSON [ {
        do = "${output}/bin/sunshine-output create";
        undo = "${output}/bin/sunshine-output remove";
      } ];
    };
    applications.apps = [
      { name = "Virtual Desktop"; }
      {
        name = "Steam Big Picture";
        detached = [ "${pkgs.steam}/bin/steam steam://open/bigpicture" ];
        prep-cmd = [ {
          do = "";
          undo = "${pkgs.steam}/bin/steam steam://close/bigpicture";
        } ];
        image-path = "steam.png";
      }
    ];
  };

  # This capture configuration needs an Umbriel session and its Wayland socket.
  # FFmpeg loads CUDA/NVENC at runtime from the active host driver.
  systemd.user.services.sunshine.environment.LD_LIBRARY_PATH = "/run/opengl-driver/lib";
  systemd.user.services.sunshine.serviceConfig = {
    ExecCondition = "${pkgs.bash}/bin/bash -c 'test -S \"$UMBRIEL_SOCKET\"'";
    UMask = "0077";
  };
}
