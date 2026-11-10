# Liquid glass under the Noctalia lock screen's login box, its status box and
# the lock-screen widgets that have a background (the same shader as Umbriel's
# window backdrop, home/umbriel/effects/liquid-glass-backdrop.glsl). Noctalia
# draws the lock as one opaque surface, so the compositor cannot do this: the
# patch copies what the lock screen has drawn under each box, frosts it and
# bends it at the rim in Noctalia itself. Desktop widgets are left alone.
# Source: ~/src/noctalia-glass, branch lockscreen-glass (on sequoia-live plus
# the security-key patch); the patch is `git diff HEAD~2 HEAD` there. Its
# context includes both of those patches, so it needs them and applies last.
{
  flake.modules.nixos.lockscreen-glass =
    { config, lib, ... }:
    lib.mkIf (config.my.yubikey.enable && config.my.sequoiaWallpaper.enable) {
      programs.noctalia.patches = lib.mkOrder 2000 [ ../patches/noctalia-lockscreen-liquid-glass.patch ];
    };
}
