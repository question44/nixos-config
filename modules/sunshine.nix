{ config, lib, pkgs, ... }:

let
  sunshine = pkgs.sunshine.override {
    cudaSupport = true;
    cudaPackages = pkgs.cudaPackages;
  };
  sunshineConfig = (pkgs.formats.keyValue { }).generate "sunshine.conf" config.services.sunshine.settings;
  output = pkgs.writeShellApplication {
    name = "sunshine-output";
    runtimeInputs = [ config.programs.umbriel.package config.programs.mango.package pkgs.wlr-randr pkgs.jq ];
    text = builtins.readFile ../home/sunshine/output.sh;
  };
in
{
  environment.systemPackages = [ output ];

  services.sunshine = {
    enable = false; # Temporarily replaced by Moonshine; configuration retained.
    package = sunshine;
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
      csrf_allowed_origins = lib.concatStringsSep "," [
        "https://192.168.1.106:47990"
        "https://sunshine.erebor.jzon.pl"
        "https://sunshine.moria.jzon.pl"
      ];
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

  # Sunshine requests CPU thread priority through RealtimeKit after dropping caps.
  security.rtkit.enable = true;

  # Grant scheduling priority to Sunshine without granting KMS/admin access.
  security.wrappers.sunshine = {
    owner = "root";
    group = "users";
    permissions = "u+rx,g+rx,o-rwx";
    capabilities = "cap_sys_nice+ep";
    source = "${sunshine}/bin/sunshine";
  };

  # Capture needs a live supported compositor and its Wayland socket.
  # FFmpeg loads CUDA/NVENC at runtime from the active host driver.
  systemd.user.services.sunshine.enable = config.services.sunshine.enable;
  systemd.user.services.sunshine.environment.LD_LIBRARY_PATH = "/run/opengl-driver/lib";
  systemd.user.services.sunshine.serviceConfig = {
    ExecCondition = pkgs.writeShellScript "sunshine-session-ready" ''
      test -S "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" || exit 1
      if [ "''${XDG_CURRENT_DESKTOP:-}" = mango ]; then
        ${config.programs.mango.package}/bin/mmsg get version >/dev/null
      else
        test -S "''${UMBRIEL_SOCKET:-$XDG_RUNTIME_DIR/umbriel-$WAYLAND_DISPLAY.sock}"
      fi
    '';
    ExecStartPre = pkgs.writeShellScript "sunshine-prepare-output" ''
      if [ "''${XDG_CURRENT_DESKTOP:-}" = mango ]; then
        exec ${output}/bin/sunshine-output create
      fi
    '';
    ExecStart = lib.mkForce "${config.security.wrapperDir}/sunshine ${sunshineConfig}";
    UMask = "0077";
  };
}
