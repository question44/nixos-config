# The shared app opacity from home/appearance.nix, rounded to an 8-bit alpha
# (Zed's format) so Ghostty, Monstar and Zed use the same value. Not a
# flake-parts module (the `_` keeps import-tree off it); import it with lib.
lib:
let
  appearance = import ../../home/appearance.nix;
  byte =
    assert lib.assertMsg (
      appearance.appOpacity >= 0 && appearance.appOpacity <= 1
    ) "appearance.appOpacity must be between 0 and 1";
    builtins.floor (appearance.appOpacity * 255 + 0.5);
in
{
  # As a JSON number between 0 and 1, for Ghostty and Monstar.
  value = builtins.toJSON (byte / 255.0);
  # As two hex digits, for Zed.
  alpha = lib.toUpper (lib.fixedWidthString 2 "0" (lib.toHexString byte));
}
