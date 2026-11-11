{
  # Shared background opacity for Ghostty, Monstar, Vicinae, Zen and Noctalia's
  # transparent Zed themes, per Noctalia theme mode. Range: 0.0 (transparent)
  # to 1.0 (opaque). The mode switch is modules/home/theme-opacity.nix.
  appOpacity = {
    dark = 0.8;
    light = 0.5;
  };
  # Zen's chrome (home/zen/translucent.css), the same in both modes; null
  # follows appOpacity instead.
  zenOpacity = 0.7;
}
