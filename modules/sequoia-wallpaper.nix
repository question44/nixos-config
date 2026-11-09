# Live "sequoia:" wallpaper: Noctalia patched with a renderer for the macOS
# Sequoia scene (source and notes: ~/src/sequoia-re). The scene stays still on
# the desktop, eases into motion on the lock screen and coasts to a stop after
# unlock; [wallpaper.sequoia] in home/noctalia/config.toml sets the motion and
# frame rates and desktop speed. The scene data is Apple's, so it is kept out of this repository
# and the store: the patch loads ~/.local/share/sequoia/sequoia.scene (see
# SYSTEM_CONTEXT.md), and without it the wallpaper shows only the fill colour.
{
  flake.modules.nixos.sequoia-wallpaper =
    { config, lib, ... }:
    lib.mkIf config.my.sequoiaWallpaper.enable {
      programs.noctalia.patches = lib.mkAfter [ ../patches/noctalia-sequoia-live-wallpaper.patch ];
    };
}
