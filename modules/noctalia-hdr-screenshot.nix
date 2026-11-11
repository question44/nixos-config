# Noctalia screenshots on an HDR output. Region and full-screen screenshots
# copy the screen over wlr-screencopy, which wlroots refuses for an HDR output
# (it offers no shared-memory format for 10-bit or float buffers), so a region
# screenshot on the AW3423DWF in HDR failed with "failed to crop image". The
# patch falls back to ext-image-copy-capture for such outputs; Umbriel converts
# those frames to SDR. It applies to upstream Noctalia on its own and last after
# the other Noctalia patches.
# Source: ~/src/noctalia-hdr-shot, branch hdr-screenshot (on lockscreen-glass);
# the patch is `git diff lockscreen-glass hdr-screenshot` there.
{
  flake.modules.nixos.noctalia-hdr-screenshot =
    { lib, ... }:
    {
      programs.noctalia.patches = lib.mkOrder 2100 [ ../patches/noctalia-hdr-screenshot.patch ];
    };
}
