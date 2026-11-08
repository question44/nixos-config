# Home Manager for the main user (my.user.name): the integration on the
# NixOS side, and janzon's profile, which collects the homeManager aspects.
{ config, inputs, ... }:
let
  inherit (config.flake.modules) homeManager;
in
{
  flake.modules.nixos.home-manager =
    { config, ... }:
    {
      imports = [ inputs.home-manager.nixosModules.home-manager ];
      # Home Manager uses the modern profile CLI during system activation.
      systemd.services."home-manager-${config.my.user.name}".environment.NIX_CONFIG =
        "experimental-features = nix-command flakes";
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.backupFileExtension = "backup";
      home-manager.users.${config.my.user.name} = homeManager.janzon;
    };

  flake.modules.homeManager.janzon =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      sessionEditor = pkgs.writeShellScriptBin "session-editor" ''
        if [ -n "''${WAYLAND_DISPLAY:-}" ] \
          && [ -n "''${XDG_RUNTIME_DIR:-}" ] \
          && [ -S "''${XDG_RUNTIME_DIR}/''${WAYLAND_DISPLAY}" ]; then
          exec ${pkgs.zed-editor}/bin/zeditor --wait "$@"
        fi
        if [ -n "''${DISPLAY:-}" ]; then
          exec ${pkgs.zed-editor}/bin/zeditor --wait "$@"
        fi
        exec ${pkgs.neovim}/bin/nvim "$@"
      '';
    in
    {
      # Split by topic and feature so parallel changes rarely touch one file.
      imports = with homeManager; [
        umbriel
        shell
        desktop
        darkly
        apps
        noctalia
        vicinae
        xremap
        niri
        spotify
        steam-theme
      ];
      home.stateVersion = "26.05";
      home.pointerCursor = {
        enable = true;
        package = pkgs.capitaine-cursors;
        name = "capitaine-cursors";
        size = 32;
        gtk.enable = true;
        x11.enable = true;
      };
      home.sessionVariables = {
        EDITOR = "${sessionEditor}/bin/session-editor";
        VISUAL = "${sessionEditor}/bin/session-editor";
        GIT_EDITOR = "${sessionEditor}/bin/session-editor";
        STARSHIP_CONFIG = lib.mkForce "${config.home.homeDirectory}/.config/noctalia/starship.toml";
      };
    };
}
