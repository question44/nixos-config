# macOS through nix-darwin: the system defaults, Touch ID for sudo, fonts,
# declared Homebrew apps and Home Manager. Hosts (modules/hosts/macbook) set
# the user and the Homebrew lists. Linux-only aspects never load here.
{ config, inputs, ... }:
let
  inherit (config.flake.modules) homeManager;
in
{
  flake.modules.darwin.base =
    { config, pkgs, ... }:
    let
      user = config.system.primaryUser;
    in
    {
      imports = [ inputs.home-manager.darwinModules.home-manager ];

      # Determinate Nix manages the Nix installation and its daemon; nix-darwin
      # must not. (With the official installer, remove this and configure
      # `nix.settings` here instead.)
      nix.enable = false;

      system.defaults = {
        dock.autohide = true;
        finder = {
          AppleShowAllExtensions = true;
          ShowPathbar = true;
        };
        NSGlobalDomain = {
          AppleShowAllExtensions = true;
          # Fast key repeat (units of 15 ms); hold-for-accents off so keys repeat.
          InitialKeyRepeat = 15;
          KeyRepeat = 2;
          ApplePressAndHoldEnabled = false;
        };
        trackpad.Clicking = true;
      };

      # Writes /etc/pam.d/sudo_local, which survives macOS updates.
      security.pam.services.sudo_local.touchIdAuth = true;

      # A Nerd Font for the Starship symbols outside Ghostty (which bundles one).
      fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ];

      homebrew = {
        enable = true;
        onActivation = {
          # Never remove what is installed but not listed; review with
          # `brew bundle cleanup --file=<generated Brewfile>` before tightening.
          cleanup = "none";
          autoUpdate = false;
          upgrade = false;
        };
      };

      users.users.${user}.home = "/Users/${user}";
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "backup";
        users.${user} = homeManager.mac;
      };
    };

  # The user's Home Manager profile on macOS: the cross-platform aspects.
  flake.modules.homeManager.mac = {
    imports = with homeManager; [
      shell
      nvim
      ghostty
    ];
    home.stateVersion = "26.05";
  };
}
