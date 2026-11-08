# Noctalia: the desktop shell, its greeter and lyrics daemon, and the Home
# Manager files it reads (home/noctalia: config.toml, plugins, bar scripts).
{ inputs, ... }:
{
  flake.modules.nixos.noctalia =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      user = config.my.user.name;
      noctaliaPython = pkgs.callPackage ../packages/noctalia-python.nix { };
    in
    {
      imports = [
        inputs.noctalia-greeter.nixosModules.default
        inputs.noctalia.nixosModules.default
      ];

      systemd.user.services.noctalia-lyrics = {
        description = "Noctalia Spotify lyrics daemon";
        after = [
          "graphical-session.target"
          "noctalia.service"
        ];
        partOf = [ "graphical-session.target" ];
        wantedBy = [ "graphical-session.target" ];
        path = [ pkgs.playerctl ];
        serviceConfig = {
          ExecStart = "${noctaliaPython}/bin/python3 -B /home/${user}/.local/state/noctalia/plugins/materialized/community/spotify-lyrics/spotify_lyrics_daemon.py";
          Restart = "on-failure";
          RestartSec = 5;
        };
      };

      # A graphical greeter does not need Type=idle's console-output delay.
      systemd.services.greetd.serviceConfig.Type = lib.mkForce "exec";

      services.displayManager.noctalia-greeter = {
        enable = true;
        passwordless-sync-users = [ "${user}" ];
        settings = {
          appearance.scheme = "Synced";
          user.default = "${user}";
          session.default = "umbriel";
          idle.timeout = 60;
        };
      };

      programs.noctalia = {
        enable = true;
        systemd.enable = true;
        recommendedServices.enable = true;
      };

      # Noctalia updates this policy with the current palette for Helium.
      # Preserve the rendered color across rebuilds; this must stay a writable file.
      systemd.tmpfiles.settings."10-noctalia-chromium"."/etc/chromium/policies/managed/noctalia-color.json".f =
        {
          user = "${user}";
          group = "users";
          mode = "0644";
          argument = "{}";
        };
    };

  flake.modules.homeManager.noctalia =
    {
      config,
      osConfig,
      pkgs,
      ...
    }:
    {
      # Live: a link into the checkout (my.flakePath); the settings window's
      # ~/.local/state/noctalia/settings.toml still overrides it.
      xdg.configFile."noctalia/config.toml".source =
        config.lib.file.mkOutOfStoreSymlink "${osConfig.my.flakePath}/home/noctalia/config.toml";
      # Local plugins in the data dir outrank every plugin source.
      xdg.dataFile."noctalia/plugins/wallpaper-engine".source = ../home/noctalia/plugins/wallpaper-engine;
      home.file.".local/bin/noctalia-bar-focus" = {
        source = pkgs.writeShellScript "noctalia-bar-focus" ''
          set -euo pipefail

          direction="''${1:-}"
          case "$direction" in
            left|right) ;;
            *) exit 2 ;;
          esac

          exec umbriel msg "window-focus-$direction"
        '';
        executable = true;
      };
      home.file.".local/bin/noctalia-bar-autohide" = {
        source = ../home/noctalia/bar-autohide;
        executable = true;
      };
    };
}
