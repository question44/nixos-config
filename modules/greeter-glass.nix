# Liquid glass under the Noctalia greeter's login panel: the same glass as the
# lock screen (modules/lockscreen-glass.nix) and Umbriel's window backdrop. The
# greeter runs its own compositor, so Umbriel's backdrop patch cannot reach it;
# the patch adds a custom-draw node to the greeter's renderer that copies what
# is drawn under the panel, frosts it and bends it at the rim.
# Source: ~/src/noctalia-greeter, branch lockscreen-glass on the pinned input
# rev; the patch is `git diff HEAD~1 HEAD` there. Re-export on an input bump.
{ inputs, ... }:
{
  flake.modules.nixos.greeter-glass =
    { pkgs, ... }:
    {
      services.displayManager.noctalia-greeter.package =
        inputs.noctalia-greeter.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs
          (old: {
            patches = (old.patches or [ ]) ++ [ ../patches/noctalia-greeter-liquid-glass.patch ];
          });
    };
}
