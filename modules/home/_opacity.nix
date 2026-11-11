# The shared app opacity from home/appearance.nix, one value per Noctalia theme
# mode, rounded to an 8-bit alpha (Zed's format) so Ghostty, Monstar, Vicinae,
# Zen and Zed use the same value. Not a flake-parts module (the `_` keeps
# import-tree off it); import it with lib.
lib:
let
  appearance = import ../../home/appearance.nix;
  forMode =
    mode:
    let
      opacity = appearance.appOpacity.${mode};
      byte =
        assert lib.assertMsg (
          opacity >= 0 && opacity <= 1
        ) "appearance.appOpacity.${mode} must be between 0 and 1";
        builtins.floor (opacity * 255 + 0.5);
    in
    {
      # As a JSON number between 0 and 1, for Ghostty, Monstar and Vicinae.
      value = builtins.toJSON (byte / 255.0);
      # As two hex digits, for Zed.
      alpha = lib.toUpper (lib.fixedWidthString 2 "0" (lib.toHexString byte));
      # As a whole percentage, for Zen's CSS.
      percent = toString (builtins.floor (opacity * 100 + 0.5));
    };
in
{
  dark = forMode "dark";
  light = forMode "light";
  # light / dark: how the switch scales values it has not seen in a mode yet.
  ratio = appearance.appOpacity.light / appearance.appOpacity.dark;
}
