# NixOS system change log for `erebor` (flake target `erebor`)

This file holds the current month (November 2026); add new
entries directly below this header. Earlier months: [2026-10](changelog/2026-10.md).

# Lock screen and greeter: lens glass — 2026-11-10

At the user's request, after they kept the lens glass on the desktop: the
Noctalia lock screen (login box, status box, widgets) and the greeter's login
panel now draw the same lens optics as `liquid-glass-lens.glsl` (refracting
bevel up to 42 px, 60 px bend, colour split, white rim 0.2, kube.io coloured
rim). New commits on the `lockscreen-glass` branches of ~/src/noctalia-glass
and ~/src/noctalia-greeter (history not rewritten), so the exports are now
`git diff HEAD~3 HEAD` (lock) and `git diff HEAD~2 HEAD -- . ':!1'`
(greeter; a stray log file `1` sits in the greeter glass commit). The
fragment shader no longer reads `u_raw`, so its location may be -1; the
fatal check for it was dropped. Also fixed in all three lens shaders
(window, lock, greeter): the bend direction comes from the shape rounded to
at least the bevel, so a 42 px bevel on a smaller corner no longer shows a
seam along the corner diagonal (seen on the headless lock test). Headless
lock test (built Noctalia, copied config/state): lens bend visible on both
boxes, corner clean after the fix. Greeter not run headless (same shader
text as the lock). `erebor-diff` tier: different (the Noctalia and greeter packages and the
units and configs that reference them). Switched to generation 369; Noctalia
restarted on the patched build, and both the running Noctalia and the greeter
binary contain the new shader. Not yet seen on a real lock or at login.

# Umbriel: lens glass on Noctalia and Vicinae — 2026-11-10

At the user's request: `liquid-glass-lens-layer`
(`home/umbriel/effects/liquid-glass-lens-layer.glsl`), the window lens
optics and coloured rim on the edge search of `liquid-glass-layer.glsl`. The
bevel is at most 28 px (the search's reach); the shape's thickness along the
normal is measured so thin bar capsules get a narrower bevel and never bend
past their middle. Both layer rules in `glass.toml` now use it; set them back
to `liquid-glass-layer` to revert. Headless: compiled.

# Umbriel: lens-rim liquid glass preset — 2026-11-10

At the user's request: a second backdrop preset, `liquid-glass-lens`
(`home/umbriel/effects/liquid-glass-lens.glsl`, in `glass.toml`), porting
liquidglass.dev's optics (`<lg-lens refraction="60" bezel="0.3"
curvature="3.5" chroma="0.35" blur="4" specular="0.1">`): a rounded bevel
refracting by Snell's law (ior 1.5), so the rim shows the frost from up to
60 px inside, with a per-channel colour split and a faint rim light lit from
-120 degrees. The bezel is a fixed 42 px instead of 30% of the half-size.
Switched on the same day at the user's request: the catch-all window rule
now uses `liquid-glass-lens` (set it back to `liquid-glass-backdrop` to
revert). Later the same day, at the user's request for more specular:
the white rim glow went from 0.1 to 0.2, and a coloured rim as
kube.io/blog/liquid-glass-css-svg builds it was added: in the outer 2 px,
lit towards -60 degrees and the opposite side, the bent backdrop is
saturated x6 at opacity 0.5 with a little white over it. Headless test:
compiled; visible as a vivid edge on coloured backdrops. Live config, no rebuild. Headless
test (1600x1000, mpv image behind a clear floating Ghostty, window blur on):
`umbriel effects` reported `compiled` and the screenshot showed the bent
rim and smooth corners. Not seen on the HDR screen or on Noctalia layers.

# HyperHDR: ambilight off survives lock and unlock — 2026-11-10

At the user's request after "ambilight stopped working". The dashboard's
"ambilight off" (17:40) disables HyperHDR's LED device through the JSON API
and sets WLED `lor=2`. When the YubiKey unplug locked the session (19:25), the
screen capture went away. On unlock, HyperHDR's "New source available ->
switch LED-Device on" turned the LEDs back on, and WLED, still overridden, lit
in its own static orange. Fixed in place first (WLED `lor=0`, LEDs on, as
"ambilight on" does). `patches/hyperhdr-keep-leds-off.patch`: an API
`componentstate LEDDEVICE false` now holds the device off across source
changes until the API turns it on (the web UI, the dashboard and
`hyperhdr-restore-off` all use that path). `erebor-diff` tier: different, only
the HyperHDR package. Switched to generation 368 (HyperHDR restarted on the
patched build). Test: dashboard-style off, then `SYSTEMGRABBER` off/on through
the API; HyperHDR logged "keeping it off" and WLED stayed `on=false, lor=2`.
Ambilight was then turned back on and WLED is receiving UDP from erebor again.
Not tested with a real lock and unlock.

# Zen: translucent chrome — 2026-11-10

At the user's request ("why zen browser is not transparent"). Zen's own
switches were already on (`zen.widget.linux.transparency`,
`browser.tabs.allow_transparent_browser`), but Noctalia's community
`zen-browser` template paints the frame, sidebar and toolbars with an opaque
`--base`, and Zen's default `zen.view.grey-out-inactive-windows` fills
`#zen-main-app-wrapper` with opaque `InactiveCaption` while unfocused. New
aspect `modules/home/zen.nix` writes `~/.config/zen/translucent.css` from
`home/zen/translucent.css` (`--base` at `appOpacity`, 75%) and, at activation,
adds a second `@import` of it after Noctalia's line in each profile's
`userChrome.css` (Noctalia's apply.sh keeps other lines). Web pages stay
opaque: each site paints its own background. `erebor-diff` tier: different,
only `translucent.css` and the home-manager unit hash. Switched to generation
366; the import line and CSS are in place. The user then reported unfocused
windows still opaque: the earlier "unfocused" screenshot had only shown an
empty tab. Firefox also paints `body` with the opaque
`--toolbox-background-color-inactive` while unfocused (sampled sidebar pixel a
flat `20 20 25` unfocused against `23 22 39` focused). `translucent.css` now
clears that too. Switched to generation 367, prototype import removed and Zen
restarted on the deployed file: sidebar pixels are wallpaper-tinted both
focused (`22 21 31`, `21 29 74`) and unfocused (`27 22 64`, `21 28 73`), and a
screenshot of the unfocused window shows the wallpaper through it.

# YubiKey: lock on unplug — 2026-11-10

At the user's request (lock erebor when the YubiKey is disconnected). New
toggle `my.yubikey.lockOnRemoval` (on for erebor, off in the template) and
`modules/yubikey-unplug-lock.nix`: a udev `remove` rule for USB vendor 1050
starts the oneshot `yubikey-unplug-lock.service`, which waits 2 s, does
nothing if a YubiKey is present again (mode switch, re-enumeration), and
otherwise runs `loginctl lock-sessions`. Noctalia locks on logind's `Lock`
signal and ignores it while already locked. Password and fingerprint still
unlock; touch-unlock needs the key, so it is unavailable while unplugged.
Removal during suspend is not handled specially: Noctalia already locks
before sleep. `erebor-diff` tier: different, only the udev rule, the new unit
and the udevd override hash. The template still fails to evaluate on
`sops.defaultSopsFile`, as on master before this change. Switched to
generation 365; unplugging the key at 19:25:06 started the service, and
Noctalia logged "session is locked" at 19:25:08 (`LockedHint=yes`).

# Vicinae: liquid glass and shared opacity — 2026-11-10

At the user's request ("add liquid glass and inherit opacity"). Vicinae's
launcher opacity now comes from `home/appearance.nix` (`appOpacity`, via
`modules/home/_opacity.nix`, the same 0.749 as Ghostty): Home Manager writes
`~/.config/vicinae/nix.json`, and `~/.config/vicinae/settings.json` (GUI-owned,
not in the repo) got `"imports": ["./nix.json"]` by hand, so a key set in the
GUI still wins. Umbriel's `^vicinae$` layer rule gains `blur_ignore_alpha =
0.05` (keeps blur off Vicinae's drawn shadow) in `config.toml`, and a
`backdrop_effect = "liquid-glass-layer"` rule in `glass.toml` (the optional
glass split from 797cf56). Both configs validate, and so does `config.toml` with
no `glass.toml` beside it. `erebor-diff` tier: different, only the new
`nix.json` and the home-manager unit hash. Switched to generation 364;
`liquid-glass-layer` is compiled, and a screenshot shows the translucent glass
launcher with no glass on its shadow.

# Umbriel: `chat` workspace for communicators — 2026-11-10

At the user's request ("dedicated workspace for communicators"), Umbriel gets
a persistent named workspace `chat` on DP-1. A window rule opens Discord and
ZapZap there (`default_workspace = "chat"`); Caps+M switches to it and
Caps+Shift+M moves the focused window to it. Config-only (live reload, no
rebuild); `umbriel config validate` ok.
# Liquid glass behind `my.liquidGlass.enable` — 2026-11-10

At the user's request ("make liquid glass optional nixos config"), a new
toggle `my.liquidGlass.enable` (on for erebor, off by default and in the
template) switches all of it. Umbriel's glass presets and rules move from
`home/umbriel/config.toml` to `home/umbriel/glass.toml`, which config.toml
includes optionally; Home Manager links it as `~/.config/umbriel/glass.toml`
(live, out-of-store) only when enabled, so off leaves plain blur and the
terminals' unlit 1 px border. The lock-screen and greeter glass patches are
applied only when enabled. The Umbriel backdrop patch stays either way.
`umbriel config validate` passes with and without glass.toml; `nix flake
check` passes. `erebor-diff` tier: different — only the new `glass.toml`
link and the home-manager unit's store hash; on the template (glass off) the
link, the lock-screen patch and the greeter patch are gone (checked by
evaluation; `erebor-diff --host template` fails on master too, on
`sops.defaultSopsFile`).

# Fish `mkcd` function — 2026-11-10

At the user's request ("add mkcd alias"), the shared `shell` Home Manager
aspect adds a Fish function `mkcd DIR` (`mkdir -p` then `cd`). A function
rather than an alias, since an alias cannot `cd` into its argument; it also
reaches the Mac profile. `erebor-diff` tier: different — only the new
`mkcd.fish` and the home-manager unit's store hash.

# Glass terminal hairline restored — 2026-11-10

At the user's request ("restore hairline/border for glass windows"), the
Ghostty/Monstar rule again sets `border_width = 1` and
`border_effect = "liquid-glass-rim"`, reverting the border part of
565fd13. Focused, the 1 px ring is lit from the top-left like the glass;
unfocused, it is the native dark ring. Config-only (live reload, no rebuild).

# Umbriel: four-finger strip scroll stops at its ends — 2026-11-10

User asked that the window-scrolling gesture not bounce back. New
`patches/umbriel-strip-scroll-clamp.patch` (after scroll-accel-curve;
`~/src/umbriel` branch `strip-scroll-clamp`, export with
`git diff touchpad-scroll-accel strip-scroll-clamp -- src docs tests`) clamps
the strip to the range of its column snap points during a gesture (widened to
the start position for a centered rest) and drops travel past the ends, so
reversing moves the strip at once; the release projection is clamped the same
way. Applies to four-finger swipes and the held-button pointer strip scroll.

Unit tests 149/150 (known NVIDIA `hdr-sdr-capture`). Harness checks drag/,
overview/, input/, focus/layout_scroll, focus/scrolling and
effect/workspace_reveal_gestures: 115/116; `drag/overview_card_workspace_edge_scroll`
fails identically without this patch. The debug harness build needed
`-Dwerror=false`: the scroll-accel-curve patch trips
`-Wmissing-field-initializers` (`AccelProfile::scrollPoints`) under `-Werror`.
`erebor-diff`: different, only umbriel and `sunshine-output` (references it).
Switched to generation 360. Takes effect at the next login into Umbriel;
not yet tried on the trackpad.

# Greeter glass patch: stray debug log removed — 2026-11-10

`patches/noctalia-greeter-liquid-glass.patch` also created a file named `1`
in the greeter source: a 52-line log from a local greeter run, exported with
the patch by mistake. Removed that hunk; the other ten files are unchanged.
`erebor-diff`: different, only the noctalia-greeter package and the units and
configs that name its store path. Its binaries are byte-identical to master's
once their own store hash is normalised.
Switched to generation 359; the live system uses the new greeter build
(`289gfiwy…-noctalia-greeter-1.7.0`). The greeter itself is first seen at the
next login screen.

# Touchpad edge swipes — 2026-11-10

User asked for edge swipes on the Magic Trackpad: top edge opens the overview,
right edge the notifications. libinput has no edge gestures and passes the
compositor no touch positions, so a new Home Manager user service
`edge-swipe` (`modules/umbriel.nix`, script `home/umbriel/edge-swipe.py`,
python-evdev) reads every touchpad's raw multitouch events next to libinput
(no grab; janzon is in `input`). A finger that lands in the outer 8% of an
edge and moves 12 mm inward within 0.6 s (sideways travel at most 0.6x the
inward travel, at most two fingers down) runs that edge's command once per
touch sequence: top runs `umbriel msg overview-toggle`, right runs
`noctalia msg panel-toggle control-center notifications` (what the bar's bell
runs). Without a grab libinput still sees the touch, so the pointer moves a
little (one finger) or the page scrolls (two).

Synthetic-touch test of the detector: top and right swipes fire once; middle,
outward, diagonal, unbound-edge and three-finger touches do not. `erebor-diff`:
different, only the new service and python3-evdev.

Switched to generation 356; the service ran but matched no device
(`capabilities()` returns `(code, AbsInfo)` pairs by default, so the axis test
failed). Fixed with `capabilities(absinfo=False)`; the script then watches
both Magic Trackpad nodes (event8, event9).

User confirmed both edges work on the trackpad (generation 357), but a slide
that went on past the trigger scrolled the overview it had just opened. The
command now runs when the fingers lift (once the swipe has been recognised),
so the rest of the slide stays outside the overview; the next gesture scrolls
it normally.

User preferred opening mid-swipe. New `patches/umbriel-overview-scroll-handoff.patch`
(`~/src/umbriel`, branch `overview-scroll-handoff` on `touchpad-scroll-accel`,
`git diff touchpad-scroll-accel HEAD -- src`): a two-finger scroll stays with
what it started on; if the overview opens or closes while it is in flight, the
rest of it (through libinput's scroll stop at lift) is dropped. Also covers
opening the overview by key mid-scroll. `edge-swipe` fires mid-swipe again and
logs the finger count. Unit tests 149/150 (`hdr-sdr-capture`, known NVIDIA
failure); no harness check, as the drop needs a real finger-scroll stream.
`erebor-diff`: different, only the umbriel package and the edge-swipe script.
Switched to generation 361 (merged beside the parallel strip-scroll-clamp
patch; both apply, touching different files). edge-swipe restarted and watches
both trackpad nodes. The scroll drop is in the new Umbriel binary, so it needs
a logout/login; until then an edge swipe opens the overview mid-swipe and the
rest of a two-finger slide can still scroll it.

# Umbriel: macOS-style trackpad gestures — 2026-11-10

User asked for macOS trackpad behaviour: three-finger drag, four-finger
window/workspace navigation, five fingers for the overview. libinput (1.31)
never reports gestures with more than four fingers (`finger_count <= 4` in
`tp_gesture_post_events`), so the overview uses a four-finger pinch instead
(user chose this).

New `patches/umbriel-touchpad-gestures.patch`, applied after the backdrop
patch (`~/src/umbriel`, branch `touchpad-gestures` on `backdrop-effect`;
export with `git diff backdrop-effect HEAD -- src docs tests`). It adds
`input.touchpad.three_finger_drag` (libinput's native 3fg drag), moves the
built-in swipe navigation from three to four fingers (along the workspace
axis switches workspaces, across it scrolls the strip), and opens/closes the
overview with a four-finger pinch (log of libinput's scale; spread 0.6 = fully
open, same release physics as the old swipe). Two-finger pinches still reach
apps. `home/umbriel/config.toml` sets `three_finger_drag = true`.

Unit tests: 149/150 pass (`hdr-sdr-capture` is the known NVIDIA failure).
Harness check `effect/workspace_reveal_gestures` passes with four-finger
swipes. `erebor-diff`: different, only the umbriel package. Switched to
generation 354. The merge into master hit a conflict in `config.toml`
(parallel accel-curve commit 8aff96d) while the rebuild ran; the activated
system is identical to the checked build, and the conflict was resolved
keeping both edits within minutes. Until the next login the running compositor
(pre-patch binary) rejects reloads of `config.toml`
(unknown key `three_finger_drag`) and keeps its last good config, so the accel
curve edit also waits for that login.

Not yet verified on hardware: three-finger drag, four-finger swipes and the
pinch need a logout/login into the new Umbriel and a test with the Magic
Trackpad.

# Umbriel: scroll curve for custom acceleration profiles — 2026-11-10

Follow-up to the macOS-style trackpad curve below, at the user's request.
New `patches/umbriel-scroll-accel-curve.patch` (~/src/umbriel, branch
`touchpad-scroll-accel` on top of `touchpad-gestures`), wired in
`modules/umbriel.nix` after the gestures patch: `accel_profile` accepts
`"custom <step> <points...> scroll <step> <points...>"` and also applies the
second curve as `LIBINPUT_ACCEL_TYPE_SCROLL`. Without it a custom profile
scrolls through libinput's 1:1 fallback curve (~4.5× the adaptive speed on the
Magic Trackpad). Config parser test added; unit suite 149/150 (only the known
NVIDIA `hdr-sdr-capture` failure). `scripts/erebor-diff` against master:
different, only the Umbriel store path and units/links that reference it
(greetd, umbriel.service, home-manager); `nix store diff-closures` shows no
version changes. The config that uses `scroll` must go live only once the
patched compositor runs (an unpatched one rejects the whole accel_profile and
falls back to adaptive), so it lands separately after the next login.

Activated with `erebor-rebuild switch` as generation 355; the installed
Umbriel's derivation carries all three patches. The running compositor is still
the pre-patch build (its validator rejects `scroll` and also
`three_finger_drag`). Config on branch `agent/umbriel-scroll-config`:
`accel_profile` gains `scroll 1 0 0.2238` (flat curve equal to libinput's
adaptive touchpad scrolling, 0.9·0.2968·1000/(47·25.4)) and `scroll_factor`
returns to 0.3; validated with the patched binary. Merge after the user logs in
again.
Merged after the user logged in again: the running compositor is the
generation-355 build (`jrhjh4mr…-umbriel-0.1.0`), and it logged `config reloaded`
with no accel_profile warnings.

# Umbriel: macOS-style trackpad acceleration — 2026-11-10

At the user's request (to get the macOS trackpad feel), `home/umbriel/config.toml`
sets `[input.touchpad] accel_profile = "custom 0.75 …"` (64 points), replacing
libinput's `adaptive` profile. Stock Umbriel key (pinned rev parses
`custom <step> <points…>` and applies it as `LIBINPUT_ACCEL_TYPE_MOTION`);
libinput 1.31.3. For touchpads libinput feeds the custom curve raw device units
(not 1000-dpi normalized): the Magic Trackpad 2 (05ac:0265) reports 47 units/mm
(`evemu-describe`), output is px/ms, both outputs at scale 1. Curve from a
Mac-shaped gain model, g(v) = 1.6 + 40·x^1.8/(1+x^1.8) px/mm, x = v/250 mm/s
(about 2 px/mm slow, 18 at 200 mm/s, 37 at 800 mm/s); not measured from the
Mac's HIDAccelCurves (Mac unreachable over SSH from erebor). `sensitivity`
does not affect a custom curve. Live config, no rebuild or activation;
`umbriel config validate` passed. Rollback: revert this commit.

Same day, by feel: slow glides were too slow, so the curve was regenerated
with g(v) = 2.4 + 40·x^1.7/(1+x^1.7) (about 2.9 px/mm slow, 9 at 100 mm/s,
19 at 200 mm/s; top end unchanged). Side effect found: with a custom profile
libinput routes touchpad scrolling through its 1:1 fallback curve (Umbriel sets
only the motion curve), 47 units/mm instead of adaptive's 0.9·0.2968 per
1000-dpi unit (~10.5/mm), so scrolling got ~4.5× faster. `scroll_factor` lowered
from 0.3 to Umbriel's minimum 0.1 as a stopgap (~1.5× the old speed). A full fix
needs an Umbriel patch that also sets a LIBINPUT_ACCEL_TYPE_SCROLL curve.

# Umbriel: slower touchpad scrolling — 2026-11-10

At the user's request, `home/umbriel/config.toml` sets
`[input.touchpad] scroll_factor = 0.5` (two-finger scrolling in apps at half
speed; gestures and overview scrolling unaffected). Stock Umbriel key, so the
running compositor accepts it; live config, no rebuild or activation.
`umbriel config validate` passed. Umbriel has no per-window scroll factor.
Lowered to `scroll_factor = 0.3` the same day at the user's request (0.5
was still too fast).
# WhatsApp client: ZapZap — 2026-11-10

At the user's request, `modules/workstation/packages.nix` adds `zapzap`
(7.5.1, a PyQt6/Qt WebEngine WhatsApp Web client) to the system packages.
Chosen over `karere` (GTK4) and `whatsie` because it is Qt like the other
desktop apps and actively maintained; `whatsapp-for-linux`/`wasistlos` are
removed from nixpkgs. `scripts/erebor-diff` against master: different, only
the added zapzap closure and its desktop entry and icon links. Activated
with `erebor-rebuild switch` as generation 353; `zapzap` and its desktop entry
are in `/run/current-system/sw`. Not yet launched or signed in (needs the
user to scan the QR code).

# Spotifast: audio libraries for Soloist — 2026-11-10

Spotifast's Soloist player (Spotify's own binary, downloaded to
`~/.local/state/spotifast/soloist/builds/`, run through nix-ld) started each
track and paused it within milliseconds: its log showed `playing` → `paused …
?:??`, and its private PipeWire sink stayed suspended. It dlopens libpulse and
libpipewire, which were neither in nix-ld's library set nor on the
LD_LIBRARY_PATH it inherits from the Spotifast wrapper. The `modules/spotify.nix`
override now wraps `spotifast` again, prefixing `pipewire` and `libpulseaudio`
to LD_LIBRARY_PATH. Spotifast's built-in librespot player was unaffected (it
links PipeWire at build time).

`scripts/erebor-diff` against master: different, only the spotifast store path
(and its `bin`, desktop entry and icon links). Activated with
`erebor-rebuild switch` as generation 352. Verified live: after a relaunch,
Soloist maps `libpulse.so.0` and its log advances through a track
(0:20 → 0:50); the user confirmed audio. Not checked: whether Spotify
actually delivers lossless (Soloist does not report the format).

# Spotifast 0.17.1 — 2026-11-10

At the user's request, Spotifast (native egui Spotify client,
github.com/crmne/spotifast) is installed system-wide from `modules/spotify.nix`,
next to the Spicetify-patched Spotify. nixpkgs ships 0.14.2, so the module
overrides it to v0.17.1 (new `src` and `fetchCargoVendor` hashes; nixpkgs
rustc 1.99 meets its `rust-version = 1.98`). `doCheck = false`: the first
build compiled, but its test phase rebuilds everything with thin LTO and two
such rustc jobs were OOM-killed (kernel log 10:10). Drop the override once
nixpkgs has 0.17.1 or newer.

`scripts/erebor-diff` against master: different, only `spotifast: ∅ → 0.17.1`
(+53.6 MiB, `bin/spotifast` and its desktop entry). Activated with
`erebor-rebuild switch` as generation 350; `spotifast --version` reports
0.17.1. Not yet launched or signed in; Noctalia's `spotifast` template writes
its theme once `~/.config/spotifast` exists, then pick `noctalia.json` in
Settings → Appearance → Theme.
# Liquid glass on the Noctalia greeter — 2026-11-10

At the user's request, the greeter's login panel gets the same glass as the
lock screen. The greeter runs its own compositor, so neither Umbriel's
backdrop patch nor the Noctalia patch reaches it. New
`patches/noctalia-greeter-liquid-glass.patch` (module
`modules/greeter-glass.nix`, overriding
`services.displayManager.noctalia-greeter.package`) adds a CustomDraw node
type to the greeter's renderer and a port of `LiquidGlassNode`. The panel
keeps 25% of its SurfaceVariant fill as a tint and loses its border. Source:
`~/src/noctalia-greeter`, branch `lockscreen-glass` on the pinned input rev
(b8dd342).

Headless check at 3440x1440: the Nix-built `noctalia-greeter` ran as a plain
client in headless Umbriel. It used `NOCTALIA_GREETER_STATE_DIR` set to a copy
of the shell's staged sync files (palette, sequoia still), and showed frost,
the rim fold and the hairline. It ran without greetd and without its own
compositor. `erebor-diff`: different, only the greeter package (greetd's
command changes with it). greetd has `X-RestartIfChanged=false`, so the new
greeter appears at the next logout or boot. If it fails to start, boot the
previous generation or log in on a TTY.
Activated with switch as generation 351; greetd was not restarted, as
expected, and its config now points at `9dw31df9…-noctalia-greeter-1.7.0`. No
failed units. Not yet seen on the real greeter.

# Liquid glass on the lock-screen widgets — 2026-11-10

At the user's request, the lock-screen widgets that have a background
(weather, calendar, the sysmon chips) get the same glass as the login box.
`patches/noctalia-lockscreen-liquid-glass.patch` gains a second commit
(`~/src/noctalia-glass`, 0025739b5). `DesktopWidget` puts a
`LiquidGlassNode` under its background box. Only the lock screen turns it on,
because desktop widgets sit on their own transparent layer, where the copy
would be empty. A widget keeps 25% of its `background_color`/`opacity` as a
tint. Rotated widgets keep their plain fill, and mirrored ones are handled.

Headless check at 3440x1440 with copies of the user's config and settings
state, DP-1's widgets moved to the headless output, using the Nix-built
package: the weather, calendar and sysmon glass followed each widget's radius,
with no errors. `erebor-diff`: different, only the Noctalia package. Limit:
dark widget text reads less well over dark parts of the scene than over the
old 80% fill.
Activated with switch as generation 349; Noctalia restarted on
`r4dln1lf…-noctalia-5.4.1`; no failed system or user units.

# Spotify window at 0.98 opacity — 2026-11-10

At the user's request, a window rule in `home/umbriel/config.toml` (app_id
`^spotify$`) sets `opacity = 0.98`; the user tried 0.92 and 0.95 first. Being translucent gives the window a blur node, so the
all-windows liquid glass backdrop now shows behind it.
Live config only: no rebuild or generation change.
# Liquid glass on the Noctalia lock screen — 2026-11-10

At the user's request, the lock screen's login box and its status box ("Touch
your security key") get the liquid glass the windows have. Umbriel's backdrop
patch cannot do it: Noctalia draws the lock as one opaque surface, so there is
nothing under the box for the compositor to bend. New
`patches/noctalia-lockscreen-liquid-glass.patch` (module
`modules/lockscreen-glass.nix`, applied after the security-key and sequoia
patches, whose context it needs) adds `LiquidGlassNode`. It copies what the
lock screen has drawn under the box, frosts the copy and draws it back with the
shader from `home/umbriel/effects/liquid-glass-backdrop.glsl`. This works for
still, desktop-capture and live sequoia backgrounds. The boxes keep 25% of
their configured fill as a tint and lose their border, since the shader's rim
draws the edge. Source: `~/src/noctalia-glass`, branch `lockscreen-glass`
(f69bc8267, on `sequoia-live` plus the security-key patch).

Headless check at 3440x1440, using a copy of the user's Noctalia config and
the Nix-built package, locked through `noctalia msg session lock`: the glass
showed the frost, the rim fold and the hairline, with no errors in the log.
`erebor-diff`: different, only the Noctalia package. Limits: widgets behind
the box are not bent, since the glass is drawn before the widget layer. The
lock transition and HDR output were not checked headless.
Activated with switch as generation 348; the Noctalia user service restarted
on the patched package (`wvzvljs7…-noctalia-5.4.1`); no failed system or user
units. Not yet seen on the real lock screen.

# Noctalia layer blur cut-off 0.05 — 2026-11-10

The user tried the Noctalia layer rule's `blur_ignore_alpha` at 0.15, then
0.05, through a temporary `config-replace` profile
(`$XDG_RUNTIME_DIR/umbriel-cutoff-temp.toml`). They liked 0.05, so it replaces
0.25 in `home/umbriel/config.toml`. At that value Noctalia's soft shadows count
as part of its shapes, so blur and the glass edge reach them too. The session is
back on the normal config (`config-replace ~/.config/umbriel/config.toml`), and
the temporary profile is deleted.

# Umbriel patch: stop reallocating the glass buffers every frame — 2026-11-10

At the user's request, the liquid glass cost was measured, and the
measurement found a bug in `patches/umbriel-backdrop-effect.patch`. The patch
freed the output-sized `backdrop_source` and `backdrop_shape` buffers in
`clear_animation_buffers()`. The scene calls that on every frame that shows
no animation, so both buffers were reallocated each frame. They are now freed
with the target's other buffers (`clear_target_buffers()`). The allocator
already recreates them on a size or format change. Branch `backdrop-effect`
gains a fourth commit (`~/src/umbriel`, 70776e86).

Measured headless at 3440x1440@165 with the live config: a 60 fps video under
a floating translucent Ghostty, 20 s runs. The GPU time comes from timestamp
queries around each frame's render pass; the stock fx render timer is wrong
on NVIDIA 615. Glass frames went from 2.17 to 1.04 ms GPU mean (stock blur
0.97, no blur 0.10; p99 4.5 to 4.1 ms) and from 0.50 to 0.07 ms CPU before
rendering. Limits: SDR, no Noctalia layers, GPU mostly in P3.
Unit tests 149/150 (the known NVIDIA `hdr-sdr-capture` failure).
`nix flake check` passed. `erebor-diff`: different, only the Umbriel package
and `sunshine-output`, which references it.
Activated with switch as generation 347 (`k505hb1l…-umbriel-0.1.0`); no failed
system or user units. Headless smoke test of the installed binary with the live
config: both backdrop presets `compiled`, windows mapped, no errors. The
running session keeps the previous compositor until the user's next login.

# More transparent Noctalia bar and dock — 2026-11-09

At the user's request, the Noctalia layer rule's `blur_ignore_alpha` went from
0.5 to 0.25, and the bar's (`[bar.default]`) and dock's `background_opacity` from
0.54 / 0.51 to 0.35. The cut-off decides where blur (and the backdrop glass)
applies: below it, Noctalia's pixels count as empty. At 0.5, a bar below 50%
opacity would have lost its blur. Risk: Noctalia's soft shadows darker than 25%
may now get blurred too. Both files are linked live.

# Umbriel patch: shape input for layer glass (option B) — 2026-11-09

At the user's request, the Noctalia glass gets a rim that follows the shapes
Noctalia draws. `patches/umbriel-backdrop-effect.patch` gains a third commit
(`~/src/umbriel`, branch `backdrop-effect`, 8984c326). On a blur node with
`blur_ignore_alpha` and a backdrop effect, the renderer draws the surface's own
alpha into an output-aligned offscreen buffer, `backdrop_shape`. Backdrop
programs read it as `umbriel_shape(uv)` (coverage past the threshold, same
coordinates as `umbriel_sample`; 1 inside the box for windows). The matching
`liquid-glass-layer.glsl` searches 16 directions up to 28 px for the nearest
edge, refines it by bisection, and applies the window glass along it: fold,
fringe, graded blur, hairline. An 8-probe pre-check skips the search deep
inside panels. Activated with switch as generation 346. The shader waited on a branch
until the user's next login (the older compositor lacked `umbriel_shape`). It was
merged once `l0xgj7cb…-umbriel-0.1.0` (generation 346) was running. Live:
`liquid-glass-layer` compiled, reloaded 23:21:31, and the bar shows no halo
at the new 0.25 cut-off.
Unit tests 149/150 (the known NVIDIA failure). Headless test with copies of
the user's Noctalia config: the shader compiles, the rim follows the bar's
outline and the panel's rounded corners, and nothing renders outside the
shapes. The effect is subtle on this bar (background opacity 0.54) and the
panels (0.88).

# Umbriel patch: backdrop effects on layer surfaces — 2026-11-09

At the user's request (option A for Noctalia), `patches/umbriel-backdrop-effect.patch`
gains a second commit (`~/src/umbriel`, branch `backdrop-effect`, 04002d58).
Layer rules accept `backdrop_effect`. The layer's blur node draws the preset
through the same `blur_ignore_alpha` stencil the plain blur uses, so it stays
inside the shapes Noctalia draws. Layers rebind on effect edits when a layer
rule selects a backdrop. New shader `home/umbriel/effects/liquid-glass-layer.glsl`:
the glass body only (frost, vibrancy 1.25, lift 1.08), with no rim, because a
layer's blur node is the whole surface rectangle and its real edges are unknown.
Unit tests: 149/150, only the known NVIDIA `hdr-sdr-capture` failure. A first
version also refreshed layers on every effect edit, which a test
(`effectReloadsFlagOnlyEffectDependentState`) caught; narrowed. Headless test
with copies of the user's Noctalia config and state: the bar and a panel take the
glass, with nothing outside their shapes. The copy also opened a Chromium
terms window inside the test compositor; it ended with it, and no process stayed
attached to the test display. erebor-diff tier: different (umbriel and the
scripts naming it). Activated with switch as generation 345. Config (after the next login):
`liquid-glass-layer` preset and `backdrop_effect` on the Noctalia layer rule, merged
after the user logged in to the generation 345 build (`z4q1w3ll…-umbriel-0.1.0`
running). Umbriel reloaded the layer rules at 22:25:46, and both backdrop presets
report `compiled`. A live crop of the bar showed it drawing normally. The glass is
hard to judge over a dark app window. The config change waited for the next login; the running
compositor does not know the layer key.

# Liquid glass: narrower clear edge — 2026-11-09

The user found the edge clear over too much of the window. The blur fade now
covers 80 px instead of 160, on an ease-out curve (w = 1 − (1 − s/80)²)
instead of a smoothstep, so the frost returns quickly. 2 px of blur remain at
the edge instead of 1. In the headless text A/B, only a narrow outer strip is
noticeably clearer. Linked live. fd8dec8 failed to compile: the new local `x`
clashed with the fold's `x` (`error C1038`). Umbriel rendered the glass plainly
from 22:01:08 until the fix, which renamed it to `f`. The first A/B had hidden
this, because its output (and the log) were silenced; the re-run checked the
log for compile failures.

# Liquid glass: blur weakens towards the window edge — 2026-11-09

At the user's request, the glass blur now fades from full frost in the body
to nearly clear at the edge. The fade runs over the outer 160 px on a
smoothstep, with 1 px of blur left right at the edge. Umbriel hands the shader
only the full frost and the unblurred backdrop. So `graded()` blurs the
unblurred one itself with a 20-tap golden-angle disc, whose radius grows from
1 to 5 px, and cross-fades into the frost from w = 0.3. This replaces the
earlier SHARP/CLEAR rim blend. With 13 taps or a 10 px disc the hand-over zone
speckled; at 5 px and 20 taps it is smooth (headless A/B over a text backdrop).
The mirrored fold, fringe, colour and edge line are unchanged. Cost: up to 63
texture reads per pixel in the outer band. Linked live.

# Liquid glass on every transparent window — 2026-11-09

At the user's request, `backdrop_effect = "liquid-glass-backdrop"` moved from
the terminal rule to the all-windows rule. The patched Umbriel draws a backdrop
preset from the window's blur node, and that node exists only while the
surface is transparent (translucent pixels or opacity below 1). So every
transparent window gets the glass and opaque windows are untouched. The shader
no longer hard-codes an 18 px corner: it reads `umbriel_corner_radius` (per
corner) from the blur node, so its rim fits windows at the default 10 px too
(checked in the headless A/B). Terminals keep 18 px corners, no border and no
in-window effect. Linked live.

# Liquid glass: a little more fringe — 2026-11-09

At the user's request, the rim's colour split went from 0.06 to 0.12 of the bend
(`SPLIT` in `liquid-glass-backdrop.glsl`). The split follows the mirrored fold,
so it shows only in the outer ~11 px. Linked live.

# Liquid glass: no step between rim and body — 2026-11-09

The user found the transition from the sharp rim to the frosted body jarring.
A test over a text-filled backdrop confirmed it: the rim showed the backdrop 60%
unblurred and switched to full frost between 22 and 35 px in, a visible step.
Now the rim uses a lightly softened copy of the unblurred backdrop (5 taps,
1.25 px, like Apple's slightly soft reflection) at 45%, fading on a cubic ease
from the fold out to 7 folds (77 px). Text sharpens gradually towards the edge,
with no boundary. Linked live.

# Liquid glass: a mirrored rim like Apple's — 2026-11-09

The user pointed out that the distortion still differed from macOS ("look at
umbrella"). Zooming the Mac screenshot against the bare wallpaper showed what
Apple's rim does. It does not pull in content from beyond the edge (the widget
glyphs were already under the glass). It mirrors the strip just inside a fold
about 11 px from the edge, like total internal reflection: the weather
umbrella appears beside its mirror image, and "75%", "rain" and the clock's
"2" fold onto themselves. The rim also stays fairly sharp about 35 px in. The
backdrop shader now does exactly that: a fold at 11 px with a soft crease, a
reflection magnified 1.2×, the unblurred backdrop at 60% out to 3.2 folds, and
the colour split back at 0.06 (the user liked the fringe). Blur radius 3 → 2
(Apple's body is less blurred). The fold only reads inward, so glass windows
keep their drop shadow again (`shadow = false` removed; the A/B shows no inner
frame), and preset padding is 80 → 8. Linked live.

# Liquid glass: a quieter edge — 2026-11-09

At the user's request, the top-right corner was compared with the Mac A/B, where
the clock and weather widgets lie past the window edge. The lens and its
magnification matched. Ours had red and blue fringes on the pulled-in glyphs, a
bright cyan edge line with a glow across the corner, and a lighter band; Apple
has none of these. Shader: colour split 0.06 → 0.015, band glint off, and the
edge is now a faint dark outermost pixel (22%) with a faint light line just
inside (0.10, 0.08 extra on top). Linked live.

# Liquid glass: vibrancy instead of milk — 2026-11-09

A second A/B against the user's Mac, on a wallpaper with hard-edged beams.
Apple's glass is brighter and more saturated than the wallpaper under it,
with no grain; ours read grey and slightly milky. Backdrop shader: saturation
1.25 (new `VIBRANCY`), lift 1.08, milk 0.02; blur noise 0. The lens and the
beam softness already matched. Still open: Apple keeps a drop shadow under
glass windows, while ours are off (`shadow = false`) because the lens would
pull in the window's own shadow. Linked live.

# Liquid glass retuned against macOS — 2026-11-09

At the user's request, the backdrop glass was compared with Ghostty's
`macos-glass-regular` on the Mac (macOS 26, Ghostty 1.4.0, opacity 0.1). The
comparison used a headless test Umbriel showing the user's own Mac wallpaper
screenshot, with a glass window at the same size and position. Apple's rim pulls
in what lies *beyond* the window edge, magnified as it wraps round. The old
shader bent inward over 26 px and blended in unadjusted sharp pixels, which read
as a frame. `liquid-glass-backdrop.glsl` now has a 60 px band that samples
outward up to 24 px past the edge. A Hermite curve gives a seamless join with
the body and magnification at the edge. The shader adds a small colour split, a
5% milky lift and one thin edge line, brighter along the top. The glow band and
bottom shadow strip are gone. Config: preset padding 32 → 80; blur colour back
to natural (brightness 1.0, contrast 1.0, saturation 1.1, noise 0.02; 2 passes,
radius 3 unchanged); glass windows `shadow = false`. Umbriel draws a window's
shadow before its blur node, so the lens pulled that shadow in as a dark inner
frame (confirmed in the A/B by turning it off). Linked live; `umbriel config
validate` passes.

# Liquid glass drawn under the window — 2026-11-09

After the user logged in to the patched Umbriel (running binary
`b038rzq5…-umbriel-0.1.0`), the glass rule for Ghostty and Monstar selects
`backdrop_effect = "liquid-glass-backdrop"` and switches the in-window
`liquid-glass` shader off. The new preset (`kind = "backdrop"`, padding 32) is
drawn by each window's blur node under the window, so the lens bends the
backdrop and never the terminal's text. Linked live; `umbriel config validate`
passes with the patched CLI.

# Umbriel patched with a backdrop effect kind — 2026-11-09

At the user's request, Umbriel is built with a local patch,
`patches/umbriel-backdrop-effect.patch`, applied to the flake input's package
for both the system and Home Manager (`modules/umbriel.nix`). The patch adds an
effect kind, `backdrop`. A preset of that kind, selected per window with the
new `backdrop_effect` rule key, is drawn by the window's blur node in place of
its blur, under the window. `umbriel_sample` reads the blurred backdrop and
`umbriel_sample_raw` the unblurred one, both readable up to the preset's
`padding` past the window edge. Damage around the node grows by that padding.
This is what Hyprland's hyprglass and KWin's glass plugin get from their hooks:
glass that bends the backdrop but never the window's own pixels. Source branch
`backdrop-effect` in `~/src/umbriel` (on c6ad18d5). Umbriel's unit tests:
149/150 pass. `hdr-sdr-capture` fails because the NVIDIA GBM cannot allocate
its HDR capture format (`gbm_bo_create failed`); the patch does not touch
that. A headless test instance showed the effect working: the text was
unaffected, and the rim bent the sharp backdrop. New shader
`home/umbriel/effects/liquid-glass-backdrop.glsl`, not yet referenced by
the config: the running compositor would reject the new kind until the user
logs in to the patched build. erebor-diff tier: different (only the umbriel
package and the files that point at it). Activated with switch as generation
340: the system and user `umbriel` both resolve to the patched
`b038rzq5…-umbriel-0.1.0`. The running session keeps the old compositor until the
next login. Generation 339 was an accidental switch of master without the patch,
after a failed fast-forward: it activated only what other sessions had already
merged.

# Claude Desktop keeps GPU rendering after a switch — 2026-11-09

Claude Desktop had been drawing in software since 2026-11-08: its GPU process
ran with `--use-gl=disabled` because the app had set
`isHardwareAccelerationDisabled` and `isHardwareAccelerationAutoDisabled` in
`~/.config/Claude/claude_desktop_config.json`. Its log shows why: the
`nixos-rebuild switch` at 19:07 SIGTERMed its helper processes (Network
Service exit code 15), the GPU process then failed to relaunch about 11,000
times (`launch-failed`, exit code 1002), and the app disabled acceleration for
good. A separate instance started by hand used the NVIDIA render node without
GPU errors, so the GPU was not at fault.

At the user's request, the `claudeDesktop` override now wraps the launcher with
`makeShellWrapper` and clears both flags before every start (sed, non-fatal if
the file is missing). A real GPU failure still disables acceleration for that
run. `erebor-diff`: different, only `claude-desktop` (binary wrapper replaced by
a shell wrapper) plus /etc files differing in store hashes. The snippet was
tested on a copy of the config: both flags went to `false`, other keys kept;
a missing file exits 0.

Activated as generation 338; the desktop entry now runs the new launcher. The
running app had been started with acceleration off and rewrote the file with
the flags `true` at 20:38 (it saves its in-memory settings), which is also why
a hand edit made while it ran did not stick. Not yet seen live: GPU rendering
after the next full restart of Claude Desktop.
# [COMPLETED] Slower Sequoia wallpaper on the desktop — 2026-11-09

At the user's request ("desktop wallpaper should animate slower"), the Sequoia
patch gains `[wallpaper.sequoia] desktop_speed` (0.05–2, default 1 = Apple's
300 s loop), set to 0.5 in `home/noctalia/config.toml`. The lock screen keeps
full speed; switching between the two eases over the existing 2 s spring.
Source: `sequoia-live` in `~/src/noctalia-sequoia` (now two commits, exported
together), core synced to `~/src/sequoia-re` (scene test: 0.5 gives 1/600 per
second). Built: `/nix/store/9sqjrnpgivg7b6ryn7a4833mxq4phnbx-nixos-system-erebor-26.11.20261103.1d06008`;
`erebor-diff` tier different, only the Noctalia package (and paths naming it).
The new Noctalia validates the config; the running one warns "unknown setting"
for `desktop_speed` and otherwise loads it, so merging before activation is safe.
Live from generation 339 (activated by another rebuild of `master` at 20:40,
which included this merge; Noctalia restarted then); `scripts/erebor-rebuild
switch` made generation 340 persistent. The running Noctalia is
`zk2wmw8i…-noctalia-5.4.1` (the patched build), loaded the scene (273 trees)
and no longer warns about `desktop_speed`. The slower motion itself was not
measured; the user is to confirm it by eye.
# Glass windows without a border — 2026-11-09

At the user's request, the hairline was removed: the glass window rule sets
`border_width = 0` and no longer selects `liquid-glass-rim`. The preset and its
shader file stay defined but unused. Glass windows (Ghostty, Monstar) now have
no focus ring; the `liquid-glass` window shader's rim is their only edge.

# Liquid-glass shaders re-enabled — 2026-11-09

At the user's request ("add glass"), the glass window rule again selects
`window_effect = "liquid-glass"` and `border_effect = "liquid-glass-rim"`
(both had been switched off earlier today). Live: both presets report
`compiled`, and Monstar has both effects. Checked in a cropped DP-1 capture of
a floating test Monstar window, made with the usual temporary `in_capture`
profile and reverted afterwards. With the lighter blur (2 passes, radius 3),
the content behind shows through softened. The rim and hairline are visible,
and the padded text stays clear of the lip.

# Umbriel blur matched to KWin strength 4 — 2026-11-09

At the user's request, `[appearance.blur]` went to 2 passes at radius 3, the
Umbriel equivalent of KWin's blur strength 4. The mapping comes from the two
sources: kwin-effects-glass's strength table gives 2 iterations at offset
3.0, times the default fine-tune scale 0.89 (≈2.7). Umbriel's `passes`
counts the same halve-and-restore iterations, and `radius` scales the same
sample spread. Umbriel takes whole-number radii only. KWin keeps 2 passes
within offset 2–3, the range that avoids banding. Linked live;
`umbriel config validate` passes. Brightness, contrast, saturation and noise
are unchanged.

# Umbriel blur 3 passes, radius 6 — 2026-11-09

At the user's request, `[appearance.blur]` went to 3 passes at radius 6 (from
2 at 5). In the earlier comparison this was smooth, with no striping, and a
fuller frost than radius 5. Linked live; `umbriel config validate` passes.

# Umbriel blur radius 5 — 2026-11-09

The user reported that the blur looked strange after the change to 2 passes.
Captures of a strip behind the floating Monstar window showed vertical bands
where a window edge sits behind blurred glass: 2 passes at radius 12 leave
gaps between the blur's samples. Tested at the same spot, each setting briefly
loaded with `config-replace` and reverted: 2 passes at radius 8 still banded,
radius 4–5 barely did, and 3 passes at radius 6–8 were smooth. The user chose
to keep 2 passes, so `[appearance.blur] radius` went from 12 to 5. This is a
lighter frost: shapes behind stay recognisable. Linked live; `umbriel config
validate` passes.

# Liquid-glass rim border shader switched off — 2026-11-09

At the user's request, the glass window rule now sets `border_effect = "off"`
in place of `"liquid-glass-rim"`. As with the window shader, the preset
definition and `home/umbriel/effects/liquid-glass-rim.glsl` stay in place.
Focused glass windows now show the native 1 px accent ring
(`border_width = 1`, corner radius 18 unchanged).

# Liquid-glass window shader switched off — 2026-11-09

At the user's request, the glass window rule now sets `window_effect = "off"`
in place of `"liquid-glass"`. The shader is disabled but not removed: the
preset definition and `home/umbriel/effects/liquid-glass.glsl` stay, and
setting the value back re-enables it. The rest of the glass rule is unchanged:
the lit hairline border effect `liquid-glass-rim`, corner radius 18 and the
1 px border. Live: `umbriel effects` reports `liquid-glass` as `unreferenced`,
and Monstar has no window effect.

# Umbriel blur passes 2 — 2026-11-09

At the user's request, `[appearance.blur] passes` went from 4 to 2 in
`home/umbriel/config.toml`, for a narrower, cheaper blur. Radius stays 12.
Linked live, so no rebuild was needed. `umbriel config validate` passes. Not
checked in a screenshot.

# Shared app opacity 0.75 — 2026-11-09

At the user's request, `appOpacity` in `home/appearance.nix` went from 0.9
to 0.75. The value stays shared: Ghostty, Monstar and the Noctalia Zed theme
template follow it together, and the lower opacity lets Umbriel's
liquid-glass blur show through. erebor-diff tier: different (only those three
files: 0.902 → 0.749, Zed alpha E6 → BF). Activated with switch as
generation 335. The deployed Monstar and Ghostty configs read 0.749, and the
Zed template uses BF. Running terminals and Zed pick it up on restart or
config reload, and Zed only after Noctalia next regenerates its theme. Not
checked in a screenshot.

# Umbriel optimized blur disabled — 2026-11-09

At the user's request, `[appearance.blur] optimized = false` in
`home/umbriel/config.toml`, and the per-rule `blur_optimized` overrides were
removed: three `true` (Noctalia layers, Vicinae, all windows) and the glass
rule's `false`. Every blurred surface now blurs what is really behind it,
including windows, instead of the cached wallpaper blur. This costs GPU time
on frames where something behind a blurred surface changes. Linked live, so no
rebuild was needed. Verified: `umbriel config validate` passes, and Umbriel
logged the reload of the appearance, window rules and layer rules sections at
19:46:26 without diagnostics. The result was not checked in a screenshot.

# Closer macOS Liquid Glass in Umbriel — 2026-11-09

At the user's request, the liquid-glass effect was reworked to look more like
macOS 26. `liquid-glass.glsl` now refracts through a convex lip whose bend
climbs steeply at the rim, with a colour split there, a saturation lift on the
body, fresnel whitening and a lit ~1 px specular rim with a soft sheen. The
body's brightness gain is multiplicative: an additive lift turned the dark
body milky grey on the HDR DP-1, where the buffer appears to be linear. A new
border effect, `liquid-glass-rim`, draws the focused glass window's ring as a
light hairline lit from the top-left instead of the accent colour; unfocused
glass windows keep the dark native ring. Glass windows (Ghostty, Monstar) get
`corner_radius = 18`, `border_width = 1` and unoptimized blur, so they also
blur windows behind them. Global blur: 4 passes, radius 12, saturation 1.65,
brightness 1.08, contrast 0.82, noise 0.012. Global shadow: softness 32,
offset (0, 8). Ghostty and Monstar get 14×9 px window padding so text stays
off the lip. erebor-diff tier: different (only the Ghostty and Monstar
configs; the Umbriel files are linked live and are not in the closure).

The Umbriel part is live from the merge: both presets report `compiled`.
Verified with cropped DP-1 captures of a floating test Monstar window (a
temporary profile with `in_capture` and the worktree shaders, reverted after
each capture). The window had 14 px padding, applied through `-o`. The
captures show the hairline, the lit rim and the lip, with the edge text
undistorted. The first `erebor-rebuild switch` failed because sudo refused
("no new privileges" was set on the app's process). After an app restart
cleared the flag, 1e1524d activated with switch as generation 334
(`4n2b0csw…`); both deployed terminal configs contain the padding. Not checked: the shadow, which did not show against the dark
backdrop in the captures.

# Liquid-glass look in Umbriel — 2026-11-09

At the user's request, `home/umbriel/config.toml` gets a brighter, more
saturated blur (radius 14, brightness 1.05, contrast 0.85, saturation 1.4)
and a custom window effect, `liquid-glass`
(`home/umbriel/effects/liquid-glass.glsl`). The shader refracts the backdrop
in a 12 px band along the rounded edge, splits it slightly by colour and adds
a specular rim. A window rule applies it to Ghostty and Monstar, which are
already translucent through `appOpacity`. The preset's `shader` path is
absolute (`/etc/nixos/...`): a relative path resolved beside the
`~/.config/umbriel` link, and the preset stayed `inert`. The config is linked
live, so no rebuild was needed (no Nix change, no erebor-diff). Verified:
`umbriel config validate` passes, `umbriel effects` reports the preset
`compiled`, and the rule assigns it to Monstar. A DP-1 screenshot, taken with
a temporary `in_capture` profile that was then reverted, shows the rim and the
lens edge. The first version (22 px band) smeared the first text column of an
unpadded terminal, so the band was narrowed. The narrowed version was not
re-checked in a screenshot. Limits: layer surfaces (Noctalia bar, dock)
cannot take window effects; the effect reads only the window during
animations; `R` in the shader must track `appearance.corner_radius` by hand.

# Stateful bar toggles for Sequoia motion and bar pinning — 2026-11-09

At the user's request, a local Noctalia plugin (`home/noctalia/plugins/toggles`,
`janzon/toggles`) adds two bar widgets whose glyph follows the setting they
toggle, read with `noctalia.getSetting` so `onConfigChanged` redraws them:
`sequoia-motion` (in group g5) flips `wallpaper.sequoia.desktop_motion`
(photo = still, wave-sine = animated), and `bar-pin` replaces the static
`custom_button_2` (pinned / pinned-off). `noctalia-bar-autohide` now writes
its three keys with one `noctalia msg config-set bar.default {…}` instead of
editing `settings.toml` directly: Noctalia's own override writes (e.g. a
`config-set` right after) put the old mode back. erebor-diff tier: different
(only the plugin directory and the script in Home Manager).

9b4bdb4 activated with switch as generation 332; the script fix followed as generation 333. The plugin had to be enabled
with `noctalia msg plugins enable janzon/toggles`, and the `start` list saved
in `settings.toml` (which overrides `config.toml`) was changed from
`custom_button_2` to `bar-pin`: both are user state outside the flake. Verified
live: both glyphs change with their settings (screenshots of DP-1), and the
pin mode survives a following `config-set`. Clicks were not tested.

# Noctalia launches apps as systemd services — 2026-11-09

The cause of the Helium SIGTRAP during the d6cfd29 `test` activation (see the
Sequoia entry below) is now established ([SYS-096](tasks/SYS-096.md)).
Helium had been started from Noctalia's launcher, so its GPU process and
zygotes ran in `noctalia.service`'s cgroup. Restarting Noctalia killed them,
and Chromium aborted with "GPU process isn't usable. Goodbye." At the user's
request, `[shell] launch_apps_as_systemd_services = true` was added to
`home/noctalia/config.toml`. With it, Noctalia runs each app with `systemd-run --user
--slice=app.slice`. The file is linked live, so no rebuild or activation was
needed. `noctalia config validate` passed, and the running Noctalia reloaded
the config at 19:08:45 without errors.

Verified 2026-11-10 (no activation; generation 346 unchanged). Helium
(launched 00:05:26) and Dolphin (23:15:52) each run in their own
`app-<id>@<uuid>.service` under `app.slice`, and `noctalia.service`'s cgroup
holds only Noctalia and its helpers. Dolphin outlived Noctalia's SEGV at
23:22:31. `systemctl --user restart noctalia.service` at 00:17:52 left Helium's
unit on the same invocation, main PID and 244 tasks, with its GPU process
(868253) still running and no Chromium FATAL in the journal.

# Live Sequoia wallpaper in Noctalia — 2026-11-09

At the user's request, the macOS Sequoia live wallpaper, reverse-engineered in
`~/src/sequoia-re`, runs as a Noctalia wallpaper. A new patch
(`patches/noctalia-sequoia-live-wallpaper.patch`, from the `sequoia-live` branch
of `~/src/noctalia-sequoia`) adds the `sequoia:` wallpaper path: one shared
GLES3 scene for the wallpaper and lock surfaces. It is still on the desktop,
eases into motion on lock (2 s spring) and coasts to a stop after unlock (5 s
spring), as on macOS. Each settled frame is saved as a PNG for the theme,
backdrop and greeter. Noctalia's package is now built from
`programs.noctalia.patches`: lockscreen-yubikey adds its patch first, the new
`sequoia-wallpaper` aspect (`my.sequoiaWallpaper.enable`, on for erebor) adds
this one after it. With Sequoia off, the package drv is identical to master's.
`config.toml` gains `[wallpaper.sequoia]` (motion and frame caps). The scene
file is user data (see SYSTEM_CONTEXT.md). erebor-diff tier: different (only
the noctalia package, +136.5 KiB; /etc files differ only in store hashes).

Activated with `test` (d6cfd29's system,
`6l94dchq0c5lw9rdajhvm3illihmghyy`); the profile is still generation 330. The
wallpaper was then set with `noctalia msg wallpaper-set sequoia:` (previously
`~/Pictures/wallhaven-exy3ml.png`) and shows on DP-1 and HDMI-A-1. The user's
lock/unlock cycles in the live session logged the ramp-up (≈2.9 s) and the stop
(≈6–7 s after unlock). Headless Umbriel tests before activation: desktop
idle CPU equal to a colour wallpaper once still, 29.5 fps with
`desktop_motion = "animated"`, ≈60 fps while locked; the saved still matched
the screen exactly. Noctalia's test suite: 199 of 200 pass;
`template_undo_signal` also fails on unpatched upstream sources. Helium dumped
core (SIGTRAP) during the `test` activation, the second Noctalia restarted; the
cause is not established. `switch` of 76bb225 (also stages the greeter still per
output) at first failed for lack of approval ([SYS-095](tasks/SYS-095.md)).

Switched from 2331b1d as generation 331 (`mszqcv12znzq0iy9p31j1bbxv72bmw0y`,
same closure as the tested system) after the Mac approval went through; the
two attempts before it failed because the Mac approval timed out and then
the MacBook was unreachable. The restarted Noctalia wrote a new still and its
greeter sync staged `wallpaper-DP-1.png` and `wallpaper-HDMI-A-1.png` with no
"skip missing wallpaper" warning. Helium, not started from Noctalia this time,
survived the restart ([SYS-096](tasks/SYS-096.md)).

# Chomik drops empty placeholders after failed downloads — 2026-11-09

After the cost fix the user's paid download went through (671.4 MB charged:
23,171,247 → 22,483,739 KiB, link received) but saved as "name (1)": the
earlier failed attempt had left its empty `.part` reservation. At the user's
request `apps/chomik-qml` moves to c878fda, which removes the reservation when
a download fails before any data arrives (partial files stay for resuming);
tested offline. erebor-diff tier: different (only the Chomik package).
Activated with switch as generation 344.

# Chomik paid requests send the cost — 2026-11-09

The user's first paid download failed with "no download link": the request
named the `transfer` agreement without its cost, so the server only listed
the file again. The balance check confirmed nothing was charged (still
23,171,247 KiB). `apps/chomik-qml` moves to 7c8d3fa, which sends name and
cost like ChomikBox, compares the balance before and after, and logs the
reply when no URL comes back. erebor-diff tier: different (only the Chomik
package). Activated with switch as generation 343. A paid download with the
cost sent has not been tried yet.

# Chomik paid downloads with own transfer — 2026-11-09

At the user's request, `apps/chomik-qml` moves to 7956136: other users' files
with no free agreement (the server offers `transfer`, cost in KiB) can be
downloaded with the account's own transfer after a confirmation showing the
cost and the remaining transfer; each file is paid for at most once.
erebor-diff tier: different (only the Chomik package). Activated with switch
as generation 342. Detection and the confirmation were tested headless on a
real paid folder with paid requests blocked (nothing charged, balance
unchanged at 22.1 GB); an actual paid download has not been made yet.

# Chomik downloads dropped links — 2026-11-09

At the user's request, `apps/chomik-qml` moves to b3c52ca: dropping a
`chomik://` link or a chomikuj.pl folder or file address on Chomik offers
Download, Download as ZIP and Open. Folders are requested by path (works for
any user's folder), files by the id in their address. erebor-diff tier:
different (only the Chomik package). The user approved switching together
with another session's unactivated Sequoia speed change, but that session
activated it itself first (generation 340); master matched the running
system, so this switch changed only Chomik. Activated as generation 341. A
folder opened by its web address (107 files) and a file downloaded by its
address were tested headless against the live service; dragging from the
browser has not been tried.

# Chomik menus fit their entries — 2026-11-09

At the user's request (the ⋮ menu cut off its longer entries), `apps/chomik-qml`
moves to b4650d1: menus grow to their widest entry, capped at the window
width, and the download folder is shown with `~`. erebor-diff tier: different
(only the Chomik package). Activated with switch as generation 337 (the first
attempt got no sudo touch). Checked in offscreen renders, where the new menu
shows entries in full and the stock one cuts them off; not yet seen in the live
window.

# Chomik download notifications — 2026-11-09

At the user's request, `apps/chomik-qml` moves to 7674264: desktop
notifications (org.freedesktop.Notifications via jeepney) when a download or a
whole folder download finishes or fails, and a summary when the queue empties,
both switchable in Chomik's ⋮ menu. erebor-diff tier: different (only the
Chomik package). Merged with a merge commit because another session was
committing Umbriel config to master at the same time (its commits since the
running generation touched only the live-linked `home/umbriel/config.toml` and
this file). Activated with switch as generation 336. The rules were tested with
a stub sender, and one real test notification went through the session bus
without error; a real download's notification has not been seen yet.

# Chomik styles, including KDE's desktop style — 2026-11-09

At the user's request, the `apps/chomik-qml` submodule moves to 080a9b3:
`QT_QUICK_CONTROLS_STYLE` now really switches Qt Quick Controls styles (the
QML imported Material unqualified, which bound every control to it), and
Chomik bundles qqc2-desktop-style and Kirigami so
`QT_QUICK_CONTROLS_STYLE=org.kde.desktop` draws with the desktop's Darkly
widget style and Noctalia colour scheme. Material with Chomikuj green stays the
default. erebor-diff tier: different (only the Chomik package). Activated with
switch as generation 330; the installed wrapper carries qqc2-desktop-style and
Kirigami on its QML path. Styles were compared in offscreen renders, not yet in
the live window.

# Chomik, a native Chomikuj.pl client — 2026-11-09

At the user's request, Chomik (a PySide6/QML client built on pyChomikBox, in
the private repo question44/chomik-qml) is added as the submodule
`apps/chomik-qml` with a `path:` flake input, the same way as the dashboard.
`modules/workstation/packages.nix` installs it, and `modules/home/desktop.nix`
makes `chomik-qml.desktop` the default `x-scheme-handler/chomik` handler, so
the website's "download with ChomikBox" links open in Chomik instead of the
Wine ChomikBox (which stays installed). erebor-diff tier: different (the
Chomik package, its desktop entry and icon, and the Home Manager mimeapps
change; other /etc files differ only in store hashes). Activated with switch
as generation 329 after a first attempt failed because sudo got no touch
approval. `chomik-qml` resolves from /run/current-system, and both
`xdg-mime` and `gio mime` report `chomik-qml.desktop` as the default for
`x-scheme-handler/chomik`. A browser link click has not been tried since the
switch; the app itself was tested before (sign-in, own folders, a link
folder listing and download).

# Wine and winetricks for ChomikBox — 2026-11-08

At the user's request, to install the Windows-only ChomikBox client,
`modules/workstation/packages.nix` adds `wineWow64Packages.stable` and
`winetricks`. erebor-diff tier: different (the two packages and their fish
completions; eight /etc files differ only in store hashes). Activated with
switch as generation 328; `wine` and `winetricks` resolve from
/run/current-system. ChomikBox.msi was then installed silently into its own
prefix, `~/.local/share/wineprefixes/chomikbox` (outside the flake, not
declarative), which created the menu entry under
`~/.local/share/applications/wine/Programs/Chomikuj.pl/`. A 25 s test launch
ran `chomikbox.exe` without fatal errors (only the optional Qt SVG image
plugin failed to load). Signing in and transfers are not tested.

# Crucial MX500 dirty writeback capped at 1 GiB — 2026-11-08

At the user's request, after ~4 GB of dirty data piled up during copies, a
udev rule in `modules/hosts/erebor/storage.nix` sets `bdi/max_bytes` to
1 GiB and `bdi/strict_limit=1` on the Crucial MX500 (`/srv/external/crucial`),
matched by `ID_SERIAL` `CT500MX500SSD1_1824E143D803`. strict_limit makes the
cap apply below the global free-run threshold. erebor-diff tier: different
(only the new udev rule). Activated with switch as generation 327; after a
`udevadm trigger --action=change` on the disk, `/sys/class/bdi/8:16` reads
max_bytes 1073736261 and strict_limit 1; sda keeps the defaults. Not yet
observed under a large copy or after replugging/reboot.

# Overdue task checks — 2026-11-08

Read-only checks of the overdue OPEN tasks, plus user confirmations.

- SYS-028 DONE: after the 19:13 and 19:16 logins, one Noctalia process owned by
  `noctalia.service`, 0 restarts, no "already running".
- SYS-046 CANCELLED: the host is back on the proprietary NVIDIA driver (open
  kernel module 615.78.08 since 2026-10-26), so the NVK check no longer applies.
- SYS-051 DONE: superseded by later activations (generation 326); its commits
  are on origin/master.
- SYS-029 DONE: BootCurrent 0000 (GRUB) on every boot in the journal
  (2026-11-02 onward); the user confirmed Windows boots from the GRUB menu.
- SYS-058 DONE: the browser desktop answers 401 with Basic auth; the user
  confirmed the login works.
- SYS-064 and SYS-003 DONE on user confirmation (Polkit/sudo password after
  the Mac approval timeout; T3 browser preview).

Still open and needing a planned interruption: SYS-002, SYS-004, SYS-040,
SYS-043. No configuration change.

# Re-login after Niri removal; SYS-089 closed — 2026-11-08

The user logged out and back in through the greeter at 19:13 (Umbriel
session 26). `umbriel layers` shows no swaybg `wallpaper` surface, only
`noctalia-wallpaper` (`redhead.png`) and `dropwall` on DP-1 and HDMI-A-1; no
`swaybg` process. The Wallpaper Engine plugin loaded and its service started,
but no scene ran because its assignments had been empty since 2026-11-04
16:19. The user then assigned item 2440131566 to every output and logged in
again at 19:16:00: `noctalia-wallpaper-engine` was active at 19:16:01 on DP-1
and HDMI-A-1, and the user confirmed the animated wallpaper was showing, so
scene startup on login now works. No configuration change.

# Niri removed (SYS-094) — 2026-11-08

At the user's request Niri is gone; Umbriel is the only compositor session.
Removed: the `niri` aspect and `my.niri` toggle, `home/niri/` (config and
Caps+Q, focus-or-launch, background-apps helpers), the
`niri-overview-wallpaper` swaybg unit with its override and Dolphin service
menu (resolves the swaybg half of [SYS-089](tasks/SYS-089.md)), and the Niri
branches in `rcmd`, `xremap-focus-or-launch`, `noctalia-bar-focus`,
remote-desktop's session script and dashboard-control's `PATH`. Niri came from
nixpkgs (`programs.niri`), so there was no flake input to drop. The dashboard
submodule's generic Niri support stays, as Mango's did. Noctalia: the bar's
dead-zone left click now runs `umbriel msg overview-toggle` (it called
`niri msg` before, a no-op under Umbriel); dropped the Niri workspace-preview
plugin, `niri_overview_type_to_launch_enabled` and the `niri` theme template
(the `spotify-media-niri` bar widget stays: only its name says Niri).
`modules/flake/tests.nix` now requires exactly `[ umbriel ]` as sessions on
erebor and the template. `AGENTS.md`, README and the desktop-config skill no
longer name Niri.

`scripts/erebor-diff`: different — only Niri: the `niri` package (−35 MiB)
and its session, units, completions and docs, `/etc/xdg/niri/config.kdl`,
the Niri portals config, the swaybg unit, `niri` in dashboard-control's
`PATH`, and the resulting store-hash changes (greeter `desktops`, dbus dirs).
`nix flake check` passes. With the user's approval, activated with
`scripts/erebor-rebuild switch` as generation 326; greetd was not restarted
(`X-RestartIfChanged=false`) and the running Umbriel session was untouched.
Verified: the greeter's `wayland-sessions` holds only `umbriel.desktop`; no
`niri` on `PATH` or user units; `noctalia`, `noctalia-lyrics`, `xremap` and
`dashboard-control` active, no failed user units; `umbriel layers` shows no
swaybg `wallpaper` surface, only `noctalia-wallpaper` and `dropwall`; the
Noctalia config validates; `rcmd --focus-window` and `--list` work through
Umbriel; `xremap-focus-or-launch` routes to Umbriel; a screenshot shows the
bar and windows normal. Not observed: the greeter screen itself and the
wallpaper after a re-login (SYS-089 stays open for that). Old Home Manager
backups (`~/.config/niri/config.kdl.backup`,
`~/.local/bin/niri-overview-wallpaper.backup`, `~/.config/niri/overview-wallpaper`)
are user files and were left alone.

# Caddy's OVH credentials from sops (SYS-074) — 2026-11-08

Caddy's OVH DNS API credentials (for the `*.erebor.jzon.pl` certificates)
moved from the hand-made root file `/etc/caddy/ovh.env` into
`secrets/erebor.yaml` as `ovh_endpoint`, `ovh_application_key`,
`ovh_application_secret` and `ovh_consumer_key`.
`modules/workstation/caddy.nix` renders them with
`sops.templates."caddy-ovh.env"` (owner `caddy`, restarts `caddy.service`)
and points `services.caddy.environmentFile` at it.

`scripts/erebor-diff`: different — only Caddy's `EnvironmentFile` (now
`/run/secrets/rendered/caddy-ovh.env`) and the sops manifest. Leak check: none
of the values appear in the git diff, the built `etc`, the sops manifest or
the Caddy store paths. `nix flake check` passes. Activated with
`scripts/erebor-rebuild test`, then `switch` as generation 325. Verified: the
rendered file is `caddy:caddy 0400` and byte-identical to the old variables;
the running Caddy has all four `OVH_*` variables; a signed read-only
`GET /auth/currentCredential` with them returns HTTP 200 from OVH; Caddy is
active and serves the Let's Encrypt certificate (valid to 2027-01-14) with no
errors. The restart needed a SIGKILL after the stop timeout (old process).
Not yet observed: an actual renewal through the new file. With the user's
approval, `/etc/caddy/ovh.env` and the unused `/var/lib/searxng-secret/` were
then shredded; Caddy reloaded and `erebor.jzon.pl` answers 200, SearXNG is
active. SYS-074 closed DONE.
# Triage of overdue historical REVIEW tasks — 2026-11-08

At the user's request, reconciled the 15 REVIEW tasks overdue since
2026-11-06 against the live system (read-only checks; no rebuild).

- DONE with observed evidence: SYS-007 (Windows VM exists and is in use),
  SYS-009 (eza and aliases), SYS-015 (xremap active on its three devices),
  SYS-016 (`Linger=yes`; oo7 unlocked the Login collection at the 2026-11-06
  greetd login), SYS-019 (lsof 4.99.7). SYS-017 (br0 active, windows11 on
  br0) and SYS-018 (UEFI visit) closed on user confirmation; the journal only
  reaches back to 2026-11-02.
- SYS-020: removed the redundant `nix profile` Zen 1.23.3b with the user's
  approval; `zen` now resolves to the system package (1.24b).
- CANCELLED as superseded: SYS-006 (Intel IGD assignment replaced by the GPU
  swap and passthrough toggle), SYS-012 (Right Ctrl+D is now `rcmd d`),
  SYS-013 (Noctalia greeter replaced tuigreet), SYS-021 and SYS-023 (Mango
  removed 2026-11-03). SYS-011 cancelled because the user asked to remove
  Niri, now [SYS-094](tasks/SYS-094.md).
- SYS-014 re-scoped to OPEN: back up Tailscale state with sops instead of the
  never-run GPG archive.
- Noticed: oo7-daemon logs "Failed to lock memory pages" at start
  (`ENOMEM`), so secrets may be swappable; not investigated.

No configuration change, activation or reboot.

# Task board card in the dashboard hub (SYS-092) — 2026-11-08

Optional follow-up to SYS-090: administrators get a read-only Tasks card in
the hub; other accounts do not.

- `scripts/erebor-tasks list --json` prints counts per open status, overdue
  reviews, open epics with progress (`done` of `total`, cancelled children
  excluded) and every open task with its repository path. `--root DIR`
  selects the repository. Two new tests in `scripts/tests/`.
- Dashboard submodule (`c1c4ee1`, pushed to GitHub on user approval):
  `control.tasks.command`/`linkBase` options; `GET /api/control/tasks`
  (administrators only, 403 otherwise) runs the command with a 10 s timeout
  and returns only the documented fields; `/api/control/config` adds
  `taskBoard: true` for administrators. The card shows the counts, epic
  progress bars and active or overdue tasks (all open on request), linked to
  GitHub. It starts folded to a one-line summary (user request); unfolding is
  remembered per device. API tests in `api/test_tasks.py`.
- `my.taskBoard.enable`/`linkBase` (erebor: on, GitHub `blob/master/`). The
  API runs the store copy of `erebor-tasks` on `my.flakePath`, so counts
  follow the checkout without a rebuild.

`scripts/erebor-diff`: different — new dashboard and control packages, two
`DASHBOARD_TASKS_*` variables on `dashboard-control.service`, closure +21.4
KiB. `nix flake check` passes. Activated with `scripts/erebor-rebuild switch`
as generation 323, then 324 for the fold. Verified: the running service's
environment holds the command as valid JSON; the command under the unit's
`ProtectSystem=strict`/`ProtectHome=read-only` gives ACTIVE 2, OPEN 30,
REVIEW 18, 27 overdue, SYS-087 0 of 6; the deployed API code with that
environment and a throwaway state directory gave an administrator the same
counts and `…/blob/master/tasks/SYS-087.md` links, and a non-admin account no
`taskBoard` flag and 403; unauthenticated `/api/control/tasks` on the live
service is 401; Caddy serves the bundle with the folded card. The user
confirmed the rendered card works in the hub; SYS-092 closed DONE. After the push, a clean build of `master` fetches the submodule
from GitHub and yields the running system.

# Zed: macOS JetBrains keymap with Cmd on Super (SYS-093) — 2026-11-08

User asked for the macOS JetBrains shortcuts in Zed, with Super as Cmd. They
chose to keep Umbriel's Super+0 (scratchpad) and drop every other Umbriel Super
bind the keymap uses.

- `home/zed/keymap.json` is generated by `home/zed/generate-keymap.py 1.26.2`
  from Zed's `default-macos.json` + `macos/jetbrains.json` (cmd→super;
  `zed::Hide`/`HideOthers`/`ShowAll`/`Minimize` dropped; 160 blocks, 1094
  bindings). It is live-linked to `~/.config/zed/keymap.json` from the `apps`
  Home Manager aspect. `~/.config/zed/settings.json` (unmanaged) now has
  `"base_keymap": "None"`, so the Linux JetBrains layer no longer mixes in.
- xremap: `dev.zed.Zed` is excluded from "Mac-like shortcuts (global)",
  "Ctrl+A/E line navigation" and "Preferences (general)", so Zed receives raw
  Super. Other apps keep the Super→Ctrl layer.
- Umbriel: 56 Super binds removed (desktop-wide). Most were already shadowed
  by xremap (Super+C/V/W/Q/T/F/R/U/I/L/comma). The others now lost on Super:
  launcher Super+D (Super+Space and Caps+Space still open Vicinae), Ghostty on
  Super+Return/T, lock Super+Alt+L (Caps+X), Orca Super+Alt+S, focus/move on
  Super+arrows/J/K/L and Super+Ctrl+arrows (Caps+WASD, Caps+Super+WASD), first/
  last column (Caps+Home/End), workspaces 1/5/6/7 and next/previous (Caps+1…9,
  Caps+PgUp/PgDn), consume/expel (Caps+[ ]), overview (Caps+`), Super+Ctrl+F/C
  (Caps+E/C), Super+= (none), Super+Ctrl+I (Super+Ctrl+PgUp), monitor focus
  Super+Shift+arrows/H/J/K/L (none; one output), log out Super+Shift+E
  (Ctrl+Alt+Delete). Kept: Super+0, H, M, Space, 2/3/4/8/9, Shift+/, Shift+Esc,
  Minus, Shift+Minus/Equal and the Super+Ctrl / Super+Shift+Ctrl moves that
  the keymap does not use.

`scripts/erebor-diff`: different — only `hm_keymap.json` added (the xremap
config is a same-size content change). `nix flake check` passes. Activated
with `scripts/erebor-rebuild switch` as generation 322. Verified:
`~/.config/zed/keymap.json` resolves to `/etc/nixos/home/zed/keymap.json`;
Umbriel logged `config reloaded (sections: keybinds)` at 18:44 when the
merge landed; `xremap` restarted and is active; all 596 action names in the
keymap exist in Zed 1.26.2 (`--dump-all-actions`; three are accepted
deprecated aliases). The user confirmed the shortcuts work in Zed with the
real keyboard; SYS-093 closed DONE.

# rcmd app menu moved to a Vicinae extension — 2026-11-08

User asked to simplify the Right Ctrl app chooser: plain app list, actions in
Vicinae's Ctrl+B panel, running apps first. `vicinae dmenu` is replaced by a
local extension (`home/rcmd/vicinae/`, command `@janzon/rcmd:menu`, built with
the vicinae flake's `mkVicinaeExtension`, `@vicinae/api` 0.29.2, linked to
`~/.local/share/vicinae/extensions/rcmd`). `rcmd` writes
`$XDG_RUNTIME_DIR/rcmd-menu.json` and opens it by deeplink. Section "Running"
(Enter focuses the latest window) and "Launch" (every visible app for the
letter; Enter opens a new instance, using the new-window desktop action when
the app runs). Ctrl+B holds Focus, New Window, the other windows by title and
the desktop actions. Picks call back `rcmd --focus-window ID` /
`rcmd --open DESKTOP_ID [--action X]` (wrapper exports `RCMD_SELF`).

`erebor-diff` tier: different (adds the `rcmd` extension; HM service hash).
Activated with `erebor-rebuild switch` → generation 320. Verified: the
extension links the store build and is listed by `vicinae cmd ls`; `rcmd c
--choose` showed both sections with icons and the Ctrl+B hint (screenshot,
deleted); deployed `rcmd --focus-window` focused Claude; no failed units,
xremap active. Not tested live: picking items with Enter/Ctrl+B and `--open`.

# Umbriel: drop cmd+Shift+P screen-off bind — 2026-11-08

Removes `Mod+Shift+P` (`dpms-off`) from `home/umbriel/config.toml` at the
user's request: system-wide actions should come from the CapsLock layer, not
cmd. Screen-off intentionally gets no replacement chord. The other `Mod+…`
binds are unchanged. Live config only (out-of-store link); no rebuild.
# Noctalia pin button: persistent mode, reserve in step — 2026-11-08

The bar's pin button (`noctalia-bar-autohide`) drifted: it flipped between
"auto-hide but reserving space" and "always shown without reserving space".
It used runtime IPC (`bar-auto-hide-set` plus the toggle-only
`bar-reserve-toggle`) and a mode file in `$XDG_RUNTIME_DIR`; since the
Noctalia config is linked live, any config reload reset the runtime reserve
and auto-hide while the mode file kept the old value, inverting the reserve
on every later press. The script now writes `auto_hide`, `smart_auto_hide`
and `reserve_space` into `[bar.default]` of Noctalia's settings override
(`~/.local/state/noctalia/settings.toml`), which Noctalia reloads live and
keeps across reloads and logins. Pinned: reserve on, no auto-hide; toggled:
smart auto-hide without reserve (the stats bar's combination).
`docs/noctalia-settings.md` lists these keys as staying out of the repo.

Validation: tested live from the worktree; `umbriel layers --json` shows the
bar's exclusive zone at 52 when pinned and 0 when auto-hidden, and
screenshots show the bar hidden over windows in smart mode and windows ending
above it when pinned. Override backup:
`settings.toml.bak-pin-persist`. `erebor-diff` against `master`: different,
only the `noctalia-bar-autohide` file and the Home Manager unit that links it.
Activated as generation 321 with `scripts/erebor-rebuild switch`; no failed
units; the deployed button toggles the exclusive zone 0 ↔ 52.

# Dolphin admin mode (kio-admin) — 2026-11-08

Adds `kdePackages.kio-admin` to the system packages and to
`services.dbus.packages` (its privileged helper `org.kde.kio.admin` is a D-Bus
system service; its polkit action comes in through `/share/polkit-1`). Dolphin
gains "Open as Administrator" and the `admin:/` location, approved through
polkit, so Dolphin itself keeps running as janzon.

Validation: `nix fmt`, `nix flake check` and `scripts/erebor-rebuild build`
pass. `erebor-diff` against `master`: different, as intended: only the
`kio-admin` package and the system bus configuration that lists it.
Activated as generation 319 with `scripts/erebor-rebuild switch`; no failed
units. `org.kde.kio.admin` is activatable on the system bus, polkit lists
`org.kde.kio.admin.commands`, and the `admin` KIO worker is installed. The
polkit prompt comes from Noctalia's agent (`polkit_agent = true`). Not
tested: opening an `admin:/` path in Dolphin and approving the prompt.

# Activated: dendritic, sops, live-config and gpu-passthrough merge — 2026-11-08

`master` fast-forwarded from `7faf39a` to `4c7904c` (`agent/gpu-specialisation`,
which contains `agent/adopt` and `agent/dendritic`). Live generation before
activation: 317 (`/nix/store/3a8fdy7qj0rv424l6rcs39yfv58786n6-…`).
Prechecks: no failed system or user units; ESP 5.1 GB free; `nix flake check`
passes; `scripts/erebor-rebuild build` gives
`/nix/store/3mdy522pkn7017kyj9pashrwlhcq9ghr-…` on the same nixpkgs
(`26.11.20261103.1d06008`). `nix store diff-closures` shows only the expected
changes: sops-install-secrets and `searxng.env`, the update-branch timer,
removal of `searxng-secret.service` and the copied desktop configs, and the
new `gpu-passthrough` specialisation (its own initrd and kernel modules).
Snapshot: read-only `/btrfs-top/nixos-root-pre-dendritic-merge-20261108`.
Risks: a new GRUB entry is added (boot-affecting); SearXNG's key changes
(sessions invalidated); the desktop configs become out-of-store links.
Recovery: boot generation 317 from GRUB, or `nixos-rebuild switch --rollback`.
Do not boot the gpu-passthrough entry until the Intel iGPU is re-enabled in
firmware ([SYS-073](tasks/SYS-073.md)).

Outcome: `scripts/erebor-rebuild switch` activated generation 318
(`3mdy522p…`, the built path). This activates the eleven entries below that
say "Not activated". Verified: no failed system or user units;
`/run/secrets/rendered/searxng.env` exists (root, 0400), `searx` is active
and answers HTTP 200 on 127.0.0.1:8888; `~/.config/{umbriel/config.toml,
noctalia/config.toml,niri/config.kdl}` resolve into `/etc/nixos/home/`;
`erebor-update-branch.timer` is scheduled (next Sun 2026-11-15 03:21);
`t3code` restarted with `CLAUDE_CODE_SHELL` and the wrappers first on PATH;
GRUB lists Default, gpu-passthrough and Windows Boot Manager; `/`, `/home`
and `/boot` are mounted as before. Not tested: Umbriel reloading on save of
the linked file, a new t3code agent running git, booting either new GRUB
entry, and the Mac config (evaluated only). Build warnings: the avahi options
in `modules/timemachine.nix` are renamed/obsolete upstream (still working).

# Agents get bash and the full PATH; SSH rule for fish hosts — 2026-11-08

T3 Code runs as a systemd user unit, so agents it started inherited
systemd's minimal PATH (no git, nix or setuid wrappers) and, with fish as
the login shell and no bash on that PATH, Claude Code refused to run any
command ("No suitable shell found"). `t3code-start` now exports the user's
full PATH (wrappers first) and `CLAUDE_CODE_SHELL`, and
`environment.sessionVariables.CLAUDE_CODE_SHELL` sets it for every session
(terminals, Claude Desktop, CLI). Codex already falls back to bash on its
own (checked: `codex exec` ran its command in bash), so it needs nothing.
The login shell stays fish. AGENTS.md gains an always-on rule: commands run
in bash, and scripts sent to hosts whose login shell is fish (the Mac) go
through `bash -s` or `bash -c`. The hand-added `env.CLAUDE_CODE_SHELL` in
`~/.claude/settings.json` becomes redundant after activation.

Validation: `nix fmt`, `nix flake check` and `scripts/erebor-rebuild
build` pass. `erebor-diff HEAD .`: different, only the new variable in
`set-environment` and the changed `t3code` unit/start script. Not yet
activated; after activation, restart `t3code` and confirm a new agent's
shell has git on PATH.

# The Mac under nix-darwin, sharing Home Manager aspects — 2026-11-08

Adds the `nix-darwin` input (pinned, follows nixpkgs) and
`darwinConfigurations.macbook` (`modules/hosts/macbook/`, aarch64-darwin,
user janzon; facts checked over SSH today). `flake.modules.darwin.base`
(`modules/darwin/base.nix`) sets `nix.enable = false` for Determinate Nix,
Dock autohide, Finder extensions and path bar, fast key repeat, tap to
click, Touch ID for `sudo` (`sudo_local`), JetBrains Mono Nerd Font, and
declares the Mac's current Homebrew casks and formulae with
`cleanup = "none"` and no auto-update or upgrade. Its Home Manager profile
`homeManager.mac` reuses the cross-platform aspects: `shell` (now split by
platform: the welcome banner and Noctalia palette are Linux-only; the Mac
gets `home/starship-mac.toml`, its own powerline prompt, Secretive's
`SSH_AUTH_SOCK`, and `eza`/`chafa`), and the new `nvim` and `ghostty`
aspects split out of `apps` (Ghostty uses `home/ghostty/config-macos.ghostty`
on macOS). The opacity calculation moved to `modules/home/_opacity.nix`.
The hostname is deliberately not set. `docs/mac.md` covers install, what the
first apply changes, and later steps. The KDE Connect conversion was not
done: `programs.kdeconnect` would open 1714–1764 on every interface instead
of only `br0` and enable uinput, so it is not equivalent.

Validation: `nix fmt`, `nix flake check` (new `eval-darwin-macbook`: the
Mac's drvPath evaluates and no Linux-only file is deployed there) and
`scripts/erebor-rebuild build` pass. `erebor-diff` against the previous
commit: identical for erebor and template. The Mac config is evaluated
only; it has not been built or applied.

# Starship: the Mac's powerline layout on erebor, in Noctalia colours — 2026-11-08

`home/starship.toml` (deployed as `noctalia/starship-base.toml`, with the
Noctalia palette appended at activation) now uses the layout of the Mac's
powerline preset: its segments, separators, Nerd Font symbols, directory
substitutions and language modules. `palette = "noctalia"` stays; each fixed
colour became a palette name (mapping in the commit message), with segment
text in `base` on the light accents and `text` on the dark time segment.
Kept from the previous prompt: `nix_shell` and `container` (in the docker
segment), `git_metrics` (in the git segment), `hostname`/`localip` over SSH
(in the user segment), and `cmd_duration`, `jobs`, `env_var.VIMSHELL`,
`sudo` and the vi-mode `character` symbols after the segments.

Validation: with today's Noctalia palette appended, `starship print-config`
and `starship prompt` run without warnings and render every segment.
`nix flake check` and `scripts/erebor-rebuild build` pass. `erebor-diff`
against the previous commit: different for erebor and template, as intended:
only `hm_starship.toml` changes (and the Home Manager generation and its
unit with it). Not activated.

# Encrypted secrets with sops-nix; SearXNG's key moved into sops — 2026-11-08

Adds the `sops-nix` input (pinned, follows nixpkgs) and the `secrets` aspect
(`modules/secrets.nix`, in `workstation`): each host's
`secrets/<hostname>.yaml` is its default sops file, decrypted at activation
with the SSH host key into `/run/secrets`. `.sops.yaml` names two
recipients: janzon's new personal age key (`~/.config/sops/age/keys.txt`,
mode 600, generated today; needs an offline backup) and erebor's host key
(`ssh-to-age` of `/etc/ssh/ssh_host_ed25519_key.pub`). SearXNG now reads
`/run/secrets/rendered/searxng.env`, rendered from a newly generated
`searxng_secret_key`; the `searxng-secret` generator unit is gone (the new key
only invalidates SearXNG sessions). The eval test `secrets-encrypted` fails
if any `secrets/*.yaml` value is not `ENC[…]` (confirmed with a planted
plaintext line). AGENTS.md now allows secrets in the repo only
sops-encrypted; the `secrets` skill documents the workflow. Caddy's OVH
credentials stay in `/etc/caddy/ovh.env` for now: reading them needs sudo
(SYS-074).

Validation: `nix fmt`, `nix flake check` and `scripts/erebor-rebuild build`
pass. Leak check: the decrypted value is in no tracked file, no git object,
and none of the closure's top-level files nor the changed paths
(`/etc`, `searxng.env`, `manifest.json`, `erebor.yaml`). `erebor-diff`
against the previous commit: different for erebor, as intended: adds
`sops-install-secrets`, the encrypted `erebor.yaml`, the manifest and the
`searxng.env` template; drops `searxng-secret.service` and its `requires`
link; `searx.service` and `searx-init.service` change `EnvironmentFile` to
the rendered path. Template: identical (no secrets declared). Not activated;
after activation check `/run/secrets/rendered/searxng.env` exists (root,
0400) and that SearXNG answers on 127.0.0.1:8888.

# Weekly tested flake update branch — 2026-11-08

New `scripts/erebor-update-branch [--pinned]` and the `update-branch` aspect
(`my.updateBranch.enable`, on for erebor). A user timer
(`erebor-update-branch.timer`, Sundays 03:00 with up to 30 min random delay,
`Persistent=true`) runs the script at idle CPU and I/O priority. It recreates
`~/nixos-wt/flake-update` on `agent/flake-update` from `master`, runs `nix
flake update nixpkgs home-manager` (with `--pinned`, by hand, it also moves
each commit-pinned github input to its default branch's head), builds erebor
with `erebor-rebuild build`, runs `erebor-diff` against `master`, commits the
lock with the report (changed inputs old → new, build result, tier) as the
message, writes the report to `~/.local/state/erebor-update/report.md`, and
sends a desktop notification. It never activates. Documented in the
`parallel-agents` skill. Not run yet: the first real run is the first timer
firing after activation (or `systemctl --user start erebor-update-branch`).

Validation: `nix fmt`, `nix flake check` and `scripts/erebor-rebuild build`
pass; shellcheck passed through `writeShellApplication`; the report's jq
filter was tested on a modified lock file. `erebor-diff` against the previous
commit: different for erebor, as intended (only the new user service, timer
and its `timers.target.wants` link, plus the script); identical for template.
Not activated.

# AGENTS.md procedures moved into skills — 2026-11-08

`AGENTS.md` now holds the rules that always apply, the repository layout,
the design boundaries, source control, and an index of skills. The
procedures moved, reworded but complete, into `.claude/skills/*/SKILL.md`:
`parallel-agents` (worktrees, erebor-diff, landing, SYS-NNN claims, union
merges), `activation-and-checkpoints` (prechecks, test vs switch, reboot
checkpoint, storage and boot safety with the UUIDs), `system-records`
(changelog, month rollover, TODO statuses, CONTEXT, completion,
`[PENDING]`/`[RECORDED]`) and `desktop-config` (the live Umbriel, Noctalia
and Niri workflow). Every rule of the old file was checked to live in
AGENTS.md or one of the skills.

Validation: docs only. `nix flake check` and `scripts/erebor-rebuild build`
pass; `erebor-diff` against the previous commit: identical for erebor and
template.

# Live desktop configs: Umbriel, Noctalia and Niri link into /etc/nixos — 2026-11-08

`~/.config/umbriel/config.toml`, `~/.config/noctalia/config.toml` and
`~/.config/niri/config.kdl` are now out-of-store symlinks to the files in
the new `my.flakePath` (default `/etc/nixos`), set through
`config.lib.file.mkOutOfStoreSymlink` (Umbriel's Home Manager module accepts
the link as `programs.umbriel.settings` unchanged). Saving the file in
`/etc/nixos` applies it without a rebuild; rollback for these files is git,
not a previous generation. Umbriel's watcher resolves every symlink component
and watches the canonical directory, so edits in `/etc/nixos/home/umbriel/`
trigger its reload. `/etc/xdg/niri/config.kdl` stays a store copy as
fallback. AGENTS.md's three workflow sections became one "Desktop
configuration (live)" section; `docs/noctalia-settings.md` no longer asks for
activation after a sync.

Validation: `nix fmt`, `nix flake check` and `scripts/erebor-rebuild build`
pass; the built Home Manager generation's three links resolve to
`/etc/nixos/home/…`. `erebor-diff` against the previous commit: different
for erebor and template, as intended: the closure loses the copied
`hm_config.toml` (Umbriel), `hm_config.toml` (Noctalia) and `hm_config.kdl`
(Niri, erebor only) store files, and `home-manager-janzon.service` points at
the new generation. Nothing else changed. Not activated; after activation
check `readlink -f ~/.config/umbriel/config.toml` and that Umbriel reloads on
save.

# Third-party flake inputs pinned to commits — 2026-11-08

`noctalia`, `noctalia-greeter`, `umbriel`, `zen-browser`, `helium`,
`darkly`, `vicinae`, `claude-desktop-nix`, `millennium`, `flake-parts` and
`import-tree` now name the revision already in `flake.lock` (`moonshine` and
`monstar` already did). `nix flake update` therefore moves only nixpkgs and
home-manager; a pin moves only by editing its revision (or with
`scripts/erebor-update-branch --pinned`, added later). The lock's locked
revisions and hashes are unchanged; only the recorded originals changed.

Validation: `nix fmt`, `nix flake check` and `scripts/erebor-rebuild build`
pass. `erebor-diff` against the previous commit: identical for erebor and
template. Not activated.

# Eval tests for the design rules — 2026-11-08

`modules/flake/tests.nix` adds `checks.x86_64-linux.eval-*`, run by `nix
flake check`: `secret-service` (Oo7 on, GNOME Keyring and KWallet PAM off on
both hosts), `sessions` (Umbriel everywhere, Niri only with `my.niri`),
`features-off` (the template has none of the optional feature units; erebor
has all of them, which keeps the unit names honest), `firewall` (erebor's
open ports frozen; changing exposure means updating the list in the same
commit), `home-manager` (the main user is managed) and `my-assertions` (the
template extended with a bad `my.*` value fails with a message naming the
setting, and the plain template fails none). A deliberately wrong expected
port was confirmed to fail the check. `dashboard-control.nix` now also checks
`my.nanokvm.url != null`, so the assertion is reported instead of a null
coercion error.

Validation: `nix fmt`, `nix flake check` and `scripts/erebor-rebuild build`
pass. `erebor-diff` against the previous commit: identical for erebor and
template. Not activated.

# Assertions and stricter types for `my.*` settings — 2026-11-08

`modules/my.nix` now fails evaluation with a message naming the `my.*`
setting to change: ambilight without `musicSink`, Mac approval without
`addresses`, NanoKVM without `url`, and two enabled `my.services` sharing a
loopback port, LAN port or public name. `modules/timemachine.nix` asserts
`my.timeMachine.path` when enabled. Values now have checked shapes:
`user.name`, `network.domain`, `network.lanInterface` (≤ 15 characters),
`ambilight.wledUrl`/`nanokvm.url` (http(s) URLs), `timeMachine.maxSize`
(`<n>K|M|G|T`); `musicSink`, `nanokvm.url` and `timeMachine.path` default to
null so the assertion, not a missing-option error, reports them.

Validation: `nix fmt`, `nix flake check` and `scripts/erebor-rebuild build`
pass. `erebor-diff` against the previous commit: identical for erebor and
template. Not activated.

# Dendritic flake layout (flake-parts + import-tree) — 2026-11-08

Pure refactor. `flake.nix` now only declares inputs (adds `flake-parts`, with
`nixpkgs-lib` following nixpkgs, and `import-tree`) and loads every `.nix`
file under `modules/` as a flake-parts module. Files contribute
`flake.modules.nixos.<aspect>` and `flake.modules.homeManager.<aspect>`;
`specialArgs`/`extraSpecialArgs` are gone, inputs arrive by closure.
- Hosts moved to `modules/hosts/{erebor,template}/`; each `default.nix`
  builds its `nixosConfigurations` entry. Hardware configs are
  `_hardware-configuration.nix` (the `_` keeps import-tree off them).
- `home/janzon/*.nix` moved to `modules/home/` (`janzon.nix` holds the Home
  Manager integration and the user profile). `compositor.nix` and parts of
  `workstation/session.nix`, `workstation/packages.nix`, `desktop.nix`,
  `home/janzon/{apps,desktop}.nix` became the two-sided aspects
  `modules/{umbriel,noctalia,niri,vicinae,darkly}.nix`; `xremap`, `spotify`
  and `steam-theme` gained their Home Manager halves. The upstream NixOS
  modules and the millennium overlay moved from `flake.nix` into the aspects
  that use them. Dotfiles stay in `home/<app>/`. `my.*` toggles unchanged.
- `formatter` and `checks.format` moved to `modules/flake/formatter.nix`.

Validation: `nix fmt` and `nix flake check` pass; `scripts/erebor-rebuild
build` succeeds. `erebor-diff`: equivalent for erebor and for `--host
template` (same closure, identical system-path tree; only `dbus-1` and the
polkit rules differ, in line order). The reordered polkit blocks return YES
for disjoint actions and the dbus service dirs have no shared names. Two
order changes that did alter derivations were pinned back: the millennium
overlay is `mkAfter` (it was last when `flake.nix` added it) and
`intel-media-driver` is `mkBefore` in `hardware.graphics.extraPackages`
(Steam's FHS env follows that order). Not activated.
# Task tools: ID reservations, anchor and archive checks, tests — 2026-11-08

User asked to harden `scripts/erebor-tasks` ([SYS-090](tasks/SYS-090.md)).

- **IDs:** `new` reserves the ID under `flock` in the shared git directory
  (`.git/erebor-tasks.lock`, `.git/erebor-tasks-reserved`). `next` and `new`
  also count uncommitted task files in every worktree. Without the lock, 8
  simultaneous runs gave a duplicate SYS-003; with it, all IDs are distinct
  (also a test).
- **Check:**
  - fails when a closed task outside `tasks/archive/` was closed before the
    month named in this changelog's header;
  - verifies `#anchor` parts of links from and into `tasks/`, using GitHub's
    heading slugs and `<a id>` tags;
  - warns about closed tasks longer than 15 lines or without a changelog link.
  `archive` uses the same month.
- **`reviewed:` dates:** the 23 open tasks that had only `reviewed:` now have
  `review:` set 14 days later, so overdue reviews show on the board.
  `reviewed:` is no longer accepted.
- **Removed:** `migrate` and scanning for the old `SYSTEM_TODO.md`. The user
  chose to convert the remaining branches directly.
- **Tests:** 16 unit tests in `scripts/tests/`, run by
  `checks.x86_64-linux.tasks`.

`nix flake check` passes. No system change or activation.

# Tasks: one file per task, with a monthly archive — 2026-11-08

User asked to split the task list ([SYS-088](tasks/SYS-088.md)), because several
agents editing one `SYSTEM_TODO.md` led to ID clashes (SYS-074 used by two
branches, SYS-081 claimed mid-edit) and `merge=union` duplicates.

- `SYSTEM_TODO.md` is replaced by 89 files under `tasks/`: open work and tasks
  closed this month in `tasks/`, the 27 tasks closed in October in
  `tasks/archive/2026-10/`. Status, dates, epic and children are in a small
  header; bodies are unchanged (word-for-word check against the old file).
  The "Open checks" section became `kind: check`.
- The old file had two tasks numbered SYS-028. The newer one (swaybg under
  Umbriel) is now SYS-089, and the 2026-11-04 wallpaper entry links to it.
- `scripts/erebor-tasks`: board (`list`, `--all`), `show`, `next` (scans every
  branch, including legacy files), `new`, `close`, `archive` (monthly move plus
  link rewrite), `check`, and `migrate` for branches that still edit the old
  file.
- `nix flake check` gains `checks.x86_64-linux.tasks`. It rejects duplicate
  IDs, bad headers, unknown statuses, open tasks in the archive, epics and
  children that disagree, links to `SYSTEM_TODO.md`, and broken links from or
  into `tasks/` (files only; anchors are not checked).
- AGENTS.md, README.md, SYSTEM_CONTEXT.md and `.gitattributes` follow:
  closing shrinks a task to a stub, and the first task closed in a month first
  runs `erebor-tasks archive`. The 31 links into the old file now point to the
  task files.

`nix flake check` passes. A copy with a planted duplicate ID, an epic
mismatch and a broken link fails with those errors. No system change or
activation. `agent/gpu-specialisation` still edits the old file (SYS-073,
SYS-074). It conflicts when it merges `master`; [tasks/README.md](tasks/README.md)
describes how to carry the edits over.

# Ambilight remembers "off" across HyperHDR restarts — 2026-11-07

User reported the LEDs lit with WLED's own effect after HyperHDR restarted
although the ambilight was switched off. Cause: the dashboard's
`ambilight-off` disables HyperHDR's LEDDEVICE component only at runtime (not
saved) and sets WLED `lor=2`; on restart HyperHDR re-enables LEDDEVICE and its
WLED driver (`brightnessMax`) powers the strip on, while `lor=2` still blocks
the live data. `modules/ambilight.nix` adds `ExecStartPost`
(`hyperhdr-restore-off`): if WLED reports `lor != 0` it disables LEDDEVICE and
sets WLED `on=false, live=false, lor=2` again; with `lor=0` it does nothing.
`nix flake check` passes; `erebor-diff`: different (only the hyperhdr unit).
Outcome: activated as generation 317. Test with the dashboard's off state
(LEDDEVICE off, WLED `lor=2`) then `systemctl --user restart hyperhdr`: WLED
stayed off (`on=false, lor=2`), LEDDEVICE stayed disabled, journal logged the
restore. With the on state (`lor=0`) a restart left LEDDEVICE enabled and WLED
receiving live UDP data from erebor. Limit: WLED forgets `lor` when it
reboots or loses power, so "off" is not remembered across a WLED power cycle.

# `desktop-password` also sets the Time Machine password — 2026-11-07

User asked to set the Samba password with `desktop-password`, one password
for the browser desktop, browser terminal (same Caddy auth file) and the Time
Machine share. When `services.samba` is enabled the script now runs
`smbpasswd -s -a` for the user after the HTTPS login check passes; if that
fails it restores the previous desktop password. `nix flake check` passes;
`erebor-diff`: different (only `desktop-password`). Activated as generation
316; the deployed script contains the Samba step and parses; no failed
units. Untested: a real run (needs the user's password) and a Mac login.
# Avahi keeps erebor.local: NanoKVM USB gadget unmanaged — 2026-11-06

The Mac listed the Time Machine disk as `erebor-2`: avahi-daemon logged "Host
name conflict, retrying with erebor-2" on every start. Cause (from mDNS
queries on `br0`): NetworkManager's automatic "Wired connection 1" gave the
NanoKVM's USB Ethernet gadget (`enp0s20f0u11u3`, rndis, 3346:1009) the
address 10.55.254.100. HyperHDR then answered `erebor.local` A with
10.55.254.100, and KDE Connect answered AAAA with that link's fe80 address.
Moonshine was not involved. `hosts/erebor/default.nix` adds a udev rule
setting `NM_UNMANAGED=1` for that USB device; the KVM is still reached over
Tailscale (`my.nanokvm.url`), but the 10.55.254.0/24 USB path is gone.
`nix flake check` passes. Outcome: activated as generation 315; after
`udevadm trigger` and an Avahi restart the journal shows "Host name is
erebor.local", `avahi-browse -rt _adisk._tcp` lists host `erebor.local`
(192.168.1.106), and only correct addresses answer for `erebor.local`.
HyperHDR (`_hyperhdr-http`, web 200), KDE Connect (phone reachable),
Moonshine (`/serverinfo` 200) and the NanoKVM URL still work. Limits:
Moonshine advertises no `_nvstream` service over mDNS; whether it did before
was not checked. NetworkManager shows the link as disconnected rather than
unmanaged until it is replugged or NetworkManager restarts. The Mac's view
of the name was not checked.

# Discord: Vencord 1.15.16 override — 2026-11-06

User reported Discord hanging on "Starting...". Cause: Discord's Nov 4
rspack update broke Vencord 1.15.13 (nixpkgs' version); its webpack patcher
threw `TypeError: i.A is not a constructor` and the client never loaded.
Plain Discord 1.0.168 without Vencord loaded fine. Vencord v1.15.16 ("Fix
all plugins for new rspack update") is not yet in nixpkgs, so
`modules/workstation/packages.nix` overrides `vencord` to 1.15.16 for the
Discord package. The nixpkgs `fix-deps.patch`/`postPatch` (pin
`@types/react` 19) are dropped: upstream now pins 19.2.3 and the patch no
longer applies. Remove the override once nixpkgs ships >= 1.15.16.
`nix flake check` passes; `erebor-diff`: different (Discord/Vencord only
expected). Verified before activation: the built Discord ran with Vencord
1.15.16 through all plugin stages, gateway READY, messages loaded.
Outcome: activated as generation 314, no failed units. Discord launched
from `discord.desktop` loads `vencord-1.15.16/patcher.js`, runs all plugin
stages and reaches gateway READY with no `i.A` error.
# Time Machine share on an ext4 Expansion disk — 2026-11-06

User asked to back up the MacBook with Time Machine to the Expansion disk and
chose to reformat it (was exFAT, label `Expansion`, UUID `7FF9-F492`, 45G of
`Projects`) as ext4, since Samba's `vfs_fruit` needs xattrs. New
`modules/timemachine.nix` (`my.timeMachine`): Samba share `TimeMachine`
(SMB3, `fruit:time machine`, max 2T, user `janzon`, LAN + Tailscale only),
Avahi `_adisk`/`_smb` advertisement on the LAN. Expansion now mounts ext4
UUID `26efec95-f0a4-48ac-a696-5b71b21bdb48`; Windows can no longer read it.
`nix flake check` passes. Prechecks: data copied with rsync to
`/srv/external/bigdaddy/expansion-backup` and verified by sha256. Recovery:
that copy stays until the restored data is checked; the previous generation
mounts the old exFAT UUID (data gone after mkfs, so restore from bigdaddy).
Outcome: mkfs ran at 22:50 (outside the agent session, whose sudo was
blocked by no-new-privileges); the share went live with generation 312.
smbd skipped `tailscale0` under `bind interfaces only` (point-to-point /32,
no peer address), so that is now off and the firewall (445 only on `br0` and
`tailscale0`) does the limiting: generation 313, `erebor-diff`: different
(`smb.conf` only). Verified: `/srv/external/expansion` is ext4 (5.5T),
`TimeMachine/` is `janzon:users` 0700, smbd listens on `*:445` and answers on
the Tailscale address, `testparm -s` shows the share with `fruit:time
machine = yes` and max 2T, `avahi-browse` shows `_adisk._tcp` with
`adVN=TimeMachine`; the 45G (2545 files) were restored from bigdaddy and all
pass `sha256sum -c`; qbittorrent, jellyfin and nextcloud are running; no
failed units. The bigdaddy copy is kept until the user deletes it. Limit:
Avahi names itself `erebor-2` (host name conflict; Moonshine and HyperHDR run
their own mDNS responders), so the Mac lists the disk as `erebor-2`; both
names resolve to 192.168.1.106. Untested: a Mac backup (user still sets
`smbpasswd -a janzon`).
# GRUB theme: no dark box while the kernel loads — 2026-11-06

User reported a black rectangle between choosing a GRUB entry and Plymouth.
Cause: the theme's `terminal-box` used the dark `panel_c.png` tile. GRUB
draws that box (6%/20%, 88%×65%) when it leaves the menu to run `linux` and
`initrd`, and `gfxpayload=keep` holds that frame until Plymouth. The terminal
box now uses a fully transparent `terminal_c.png`; the menu panel is
unchanged. Trade-off: the `e`/`c` editor text sits directly on the wallpaper.
`nix flake check` passes; `erebor-diff`: different (only the `grub-redhead`
theme). Activated as generation 308: `/boot/theme` holds `terminal_c.png`
(matches the repo) and `terminal-box: "terminal_*.png"`; GRUB lists
generation 308, Windows and systemd-boot recovery entries and their EFI files
are intact; no failed units. Untested: the visual result needs a reboot.
# Key icon on the lock screen while the YubiKey waits — 2026-11-06

User asked for a visible cue that the lock screen awaits a key touch. The
Noctalia patch now shows a `key` glyph (primary colour) in front of the status
line, and replaces pam_u2f's cue text with "Touch your security key", while
the helper reports a pending touch; it hides on password typing, errors, stop
and unlock. `nix flake check` passes. Activated as generation 312 (run by the
user outside the agent session, whose sudo was blocked by no-new-privileges);
the restarted `noctalia` is the patched build with the helper path set.
Untested: the icon on a real lock.
# Noctalia lock screen unlocks on a YubiKey touch — 2026-11-06

User wanted the key to unlock the lock screen without the empty-password
submit. Noctalia is now built from its flake input with
`patches/noctalia-security-key-unlock.patch`: while locked it runs
`packages/noctalia-key-auth` (path in `NOCTALIA_SECURITY_KEY_HELPER` on the
`noctalia` user service), started and stopped alongside fingerprint
verification; a password submit kills it, a failed one restarts it. The helper
exits 3 without touching PAM when no FIDO device is present (retried every
2 s), otherwise runs the new `noctalia-key` PAM stack, which holds only
pam_u2f with sudo's key file. The `login` stack is back to password only (the
U2F rule, the lock-screen guard and `use_first_pass` from the entry below are
removed) and Noctalia `lockscreen.allow_empty_password` is unset again, so the
greeter, console and lock-screen password paths are as before. `noctalia`
joined the flake `specialArgs`. Upstream changes to the lock screen may stop
the patch applying; the build then fails rather than dropping the feature.
`nix flake check` passes; `erebor-diff`: different. Activated as generation
311: the restarted `noctalia` service carries the helper path, `/etc/pam.d/login`
has no U2F rule, and `noctalia-key-auth` run by hand cued a touch and exited 0.
Untested: a real lock/unlock cycle and cancelling via password submit.
# YubiKey touch unlocks only the lock screen — 2026-11-06

User asked to unlock the session with the YubiKey, then narrowed it to
unlocking an existing session only. The Noctalia lock screen hard-codes the
`login` stack, which greetd (substack) and console login share, so U2F moved
from greetd to `login`, after the password rule (a typed password no longer
waits for a touch), behind a `pam_succeed_if service = login tty !~ ?*` guard:
the lock screen sets no PAM_TTY, the greeter runs as `greetd`, console login
has a TTY. Fresh logins need the password again, which also unlocks Oo7, so
the earlier touch-only greeter login is withdrawn. The `login` unix rule uses
`use_first_pass`: unix-early stores no empty token, so `try_first_pass`
prompted twice, which the lock screen rejects (seen on generation 309, which
had the U2F move without the guard). Set Noctalia
`lockscreen.allow_empty_password` so an empty submit reaches PAM.
`nix flake check` passes. Activated as generation 310. pamtester with an empty
password: service `login` without a TTY (lock screen path) asked once, cued and
succeeded on a touch; `greetd` and `login` with `tty=tty3` failed without a
touch prompt. Untested: the Noctalia lock screen UI itself.
# YubiKey touch login at the greeter — 2026-11-06

User asked to log in from noctalia-greeter with the YubiKey alone. Added a
`sufficient` pam_u2f rule (same key file and `cue` as sudo) to greetd's auth
stack before `substack login`; greetd sets `useDefaultRules = false`, so the
rule is spelled out in `modules/mac-approval.nix` rather than via `.u2f.enable`.
The typed password still works without the key. Trade-off accepted: a touch
login passes no password to `pam_oo7`, so the Oo7 keyring stays locked until
first unlocked. `nix flake check` passes; `erebor-diff`: different (only
`/etc/pam.d/greetd`; sudo PAM unchanged). Activated as generation 307;
`pamtester greetd janzon authenticate` showed the touch cue and succeeded on a
touch with no password. Untested: the greeter UI itself (next login).
# Noctalia started once under Umbriel — 2026-11-06

Umbriel's `autostart` and `noctalia.service` both launched Noctalia, so the
unit always failed with "already running" (seen on 2026-11-05 too) and the
`Super+Shift+F6` restart bind could not take over the bar. Removed `noctalia`
from Umbriel's autostart so the systemd unit starts it, as under Niri
(`erebor-diff`: different, only the deployed Umbriel config). Activated as
generation 305, then stopped the autostarted instance and started the unit:
`noctalia.service` is active and owns the process, `umbriel layers` shows the
bar, dock and wallpaper on DP-1 and HDMI-A-1, and no system or user units are
failed. Untested: a fresh login, where the unit alone must bring the bar up.
# Update flake inputs and pinned packages — 2026-11-06

User asked to update everything with a newer upstream. `nix flake update`
moved claude-desktop-nix, darkly, helium, noctalia, noctalia-greeter, umbriel,
xdg-desktop-portal-umbriel and vicinae; the system nixpkgs (`1d060086`) was
already current. Pinned sources bumped: ai-usagebar 1.38.0 → 1.48.2, Looking
Glass client and kvmfr B7-829-cdba29f2 → B7-895-432f4a0c (Windows IDD link in
`docs/windows-vm.md` updated to match), UT2004 installer script
`de3635ef` → `34e9dec0` (installer 1.2.2 → 1.3.2). HyperHDR stays on the
v22.0.0.0 release; trzsz, aurora-ncs and VfioIgdPkg were current.

`nix flake check` passes; `scripts/erebor-diff` tier: different. Closure
changes: claude-desktop 4.4212.0 → 4.23118.0, helium 0.20.2.1 → 0.21.1.1,
darkly 0.5.42 → 0.5.43, plus the above. Limits: the Windows VM needs the
matching B7-895 IDD installed inside Windows before Looking Glass works
again; the new kvmfr module loads at the next boot.

Activated with `switch` as generation 306. No failed system or user units;
noctalia, umbriel, xdg-desktop-portal-umbriel, browser-desktop and
dashboard-control active. Verified ai-usagebar 1.48.2 and Looking Glass client
B7-895-432f4a0c installed. Windows IDD and Looking Glass session untested.

# Move to nixos-unstable — 2026-11-06

[SYS-072](tasks/SYS-072.md). User asked to move the whole system from
nixos-26.05 to nixos-unstable (`1d060086`, 2026-11-03), mainly to replace Qt
6.11 with 6.12 everywhere. Home Manager now follows its master branch and
Vicinae follows the system nixpkgs (it had its own copy of Qt 6.11).

Changes needed on unstable:
- `boot.initrd.verbose` removed: scripted stage 1 is gone, so the initrd is
  now systemd-based. Only `initrd.kernelModules` lists are set, which work
  unchanged.
- Unfree allowlist: CUDA is split further (`cccl`, `cuda_compat`,
  `cuda_crt`, `cuda_nvrtc`, `libnvvm`) and Discord adds `discord-unwrapped`.
- `keyring.nix` uses the new `services.oo7` module. greetd's PAM now only
  substacks `login`, so the old greetd rules (positioned after `unix`) had no
  anchor; the module puts pam_oo7 (with an early pam_unix) on `login`. The
  daemon still runs through the `cap_ipc_lock` wrapper.
- `OVMFFull` is now a fixed wrapper around `OVMF`; `ovmf-vfio-igd.nix` passes
  OVMFFull's options to `OVMF` itself, still without the MS vars template.
- Caddy plugin source hash updated.
- The fooyin Qt wrapper and the `nixpkgs-unstable` input are removed.

Built (`nix flake check` passes). Open WebUI's frontend was killed once while
building alongside Ollama/CUDA and built on its own. The new closure has no
Qt 6.11 (Qt 6.12, plus Qt 5 for zbar). Versions: kernel 6.18.59 → 6.18.60,
NVIDIA unchanged at 615.78.08, systemd 262, glibc 2.44, GRUB 2.12 → 2.14,
Mesa 26.2.6, libvirt 12.8.0.

Checkpoint before activation: live generation 301 (26.05). Risks: the new
GRUB and the systemd initrd take effect only at the next boot; oo7 unlock at
greetd login and the Windows VM firmware are untested until used. Recovery:
pick generation 301 in GRUB; the "systemd-boot recovery" entry and firmware
boot menu remain. Next: activate with `switch`, check units, then reboot with
the user's agreement and verify boot, login unlock, NVIDIA, Sunshine and the
Windows VM.

Activated generation 302 with `switch`; GRUB 2.14 installed without errors.
No failed system or user units; caddy, ollama, open-webui, moonshine, the
podman containers, libvirtd, greetd, Noctalia, PipeWire, portals and HyperHDR
are active; `nvidia-smi` reports 615.78.08. `/etc/pam.d/login` has
unix-early, pam_oo7 (auth, password, session `auto_start`) and greetd
substacks it; oo7-daemon owns `org.freedesktop.secrets` with `cap_ipc_lock`.
Still running kernel 6.18.59 and the 26.05 initrd until reboot. Next: reboot
with the user's agreement, then verify boot, login unlock, Sunshine and the
Windows VM.

Rebooted into generation 303 (unstable plus the build limits below): kernel
6.18.60, the systemd initrd and GRUB 2.14 boot normally, and `/`, `/home` and
`/boot` mount from the expected Btrfs subvolumes and ESP. oo7 unlocked the
`Login` collection through the PAM listener at greetd login. NVIDIA
615.78.08, moonshine (port 47989), Vicinae, libvirtd, caddy, ollama and the
Nextcloud containers are running; the system closure has no Qt 6.11. The only
failed unit is `noctalia.service`, which exits with "already running" because
Umbriel's autostart launches Noctalia first; this predates the upgrade.

The `windows11` domain still referenced the 26.05 OVMF store paths, which are
no longer in the system closure and would disappear on garbage collection.
`windows-vm-gpu` now also sets the loader and NVRAM template to
`/etc/windows-vm/OVMF_CODE.fd` and `OVMF_VARS.ms.fd` (`erebor-diff`:
different, only that unit and the new `/etc` file). Activated as generation
304; the domain now uses the 202608 firmware, and the previous XML is in
`/var/lib/windows-vm-recovery/gpu-toggle/20261106T200135129191Z/`. Untested:
booting Windows on the new firmware (its NVRAM and TPM are unchanged).
# Build limits and systemd-oomd — 2026-11-06

erebor froze around 20:00: a full-system `nix build` ran with `max-jobs = 20`
and `cores = 0` (up to ~400 compile processes on 20 CPUs), filled RAM and zram,
and pushed memory PSI full avg300 to ~30% and I/O to ~40%. systemd-oomd watched
no cgroups, so the kernel OOM killer fired three times (20:06-20:16) and killed
claude-desktop and steamwebhelper (oom_score_adj 300) instead of compilers.

- Nix: `max-jobs = 4`, `cores = 6`, batch CPU / idle IO scheduling;
  nix-daemon `MemoryHigh=60%`, `MemoryMax=75%`, `OOMScoreAdjust=500`
  (inherited by builders). On erebor, `AllowedCPUs=2-19` keeps P-core 0
  (CPUs 0-1) free of builds, as the user asked.
- oomd: system.slice and `user@.service` monitored at 80% memory pressure.
  Root-owned `user.slice`/`-.slice` are deliberately not monitored, because
  oomd ignores a user unit's `ManagedOOMPreference` there. Session core
  (umbriel, xremap, pipewire, wireplumber, dbus-broker) is `omit`; noctalia,
  portals, oo7 and yubikey-touch-notify are `avoid`.
- New `essential [--omit] <cmd>` launches a command in a transient user scope
  with that preference until it exits (tested on the built path: scope gets
  `user.oomd_avoid`).

Not changed: the 2 GB NVMe swap partition (storage; left for the user to decide).
`scripts/erebor-diff` tier: different (intended unit changes only).

Activated generation 303 (on top of the nixos-unstable switch, gen 302); no
failed system or user units. Live: nix `max-jobs 4`/`cores 6`, nix-daemon
cpuset `2-19`, MemoryHigh/Max 20.1/25.1 GB, OOMScoreAdjust 500, batch/idle
scheduling; session units carry `user.oomd_omit`/`user.oomd_avoid`. user@1000
was not restarted, so systemd-oomd was restarted to pick it up; `oomctl` then
lists `/system.slice` and `user@1000.service` at 80%. Not exercised under real
memory pressure.

# fooyin file dialog fix — 2026-11-06

User could not browse for files to add to fooyin's library. The unstable KDE
platform theme in the fooyin wrapper opens KDE's file dialog with unstable
KIO 6.31, but no KIO worker plugins were in fooyin's `QT_PLUGIN_PATH`;
unwrapped `kioclient` from the same KIO reproduced it ("Unknown protocol
'file'"). Added unstable `kdePackages.kio` to the wrapper; with its plugin
directory the same command lists `/srv`.

Activated generation 300 with no failed system or user units;
`nix store diff-closures` against generation 299 shows no version changes
(only the fooyin wrapper changed). The dialog itself was not tried in fooyin
after activation.

# fooyin from nixos-unstable — 2026-11-06

User asked to install fooyin from nixos-unstable: 26.05 ships 0.9.2, unstable
and upstream are at 0.14.1. Added a `nixpkgs-unstable` flake input and a
`pkgs.unstable` overlay (it reuses the system's `nixpkgs.config`), so single
packages can come from unstable; the base system stays on 26.05.

Unstable fooyin is built with Qt 6.12, the system with Qt 6.11. Launched with
the session's environment it ran, but the session's Darkly failed to load
(undefined `QtPrivate_6_11_2` private-API symbol). The wrapper in
`modules/workstation/packages.nix` puts unstable Darkly and
plasma-integration first in `QT_PLUGIN_PATH`; with it, an isolated test
launch in the Umbriel session loaded both. `erebor-diff` tier: different
(fooyin added).

Activated generation 299 with no failed system or user units;
`/run/current-system/sw/bin/fooyin` is the wrapped 0.14.1 and
`org.fooyin.fooyin.desktop` is in the application menu. Not yet launched
from the menu after activation.
# Noctalia settings moved into the flake — 2026-11-06

User asked to put their current Noctalia settings into the NixOS config.
Settings changed in Noctalia's settings window go to
`~/.local/state/noctalia/settings.toml`, which overrides the Nix-managed
`config.toml`, so the repo copy had fallen behind. `home/noctalia/config.toml`
is now Noctalia's merged export of both (`noctalia config export` with only
`config.toml` in the config dir, so the Starship TOMLs there were left out),
with floats rounded, 9 keys that equal built-in defaults and 8 settings blocks
for widgets on no bar removed. The full effective export differs from the live
one only in those widgets and float rounding below 1e-7.

Kept out of the repo, in a trimmed `settings.toml` (old copy saved as
`settings.toml.bak-nix-import`): the Wallhaven API key, the last wallpaper and
the wallpaper favorites. Plugins still download from the sources in the
config; their code is not pinned.

Activated generation 301 with no failed user units; after `noctalia msg
config-reload` the live export differs from before only in the dropped
default keys and float rounding.

# Tauon music player — 2026-11-06

User asked to install Tauon after trying several players; they need CUE
sheet support for single-file album rips. Added `tauon` to
`modules/workstation/packages.nix`.

The nixpkgs build works unmodified. It crashed when launched from the Claude
desktop app's shell only because that shell exports an `LD_LIBRARY_PATH`
with other glib/pango/GTK builds; without it, Tauon read a CUE sheet and
played the album.

User also asked for pypresence (Discord Rich Presence). nixpkgs builds Tauon
with lynxpresence, but 9.1.3 imports `pypresence` and its
`StatusDisplayType`, which nixpkgs' pypresence 4.3.0-unstable lacks, so the
override adds pypresence 4.6.2 from PyPI to Tauon's Python path. The wrapper
imports it; Rich Presence itself was not tried against Discord.

Activated generation 298 with no failed system or user units;
`/run/current-system/sw/bin/tauon` is the overridden build and
`tauonmb.desktop` is in the application menu.

# janzon's packages installed system-wide — 2026-11-06

User asked to install the packages from `home/janzon/default.nix` for every
user instead of only janzon, so root and any future user get them too.
- `modules/workstation/packages.nix` now holds everything that was in
  `home.packages` (zen, monstar, claude-desktop with its libsecret flag,
  claude-code, editors, CLI tools, Dolphin thumbnailer plugins and helpers,
  umbriel-display-mode).
- The `~/.local/bin` wrappers became system packages: `gdbus` (only that
  binary from `glib.bin`) and the `kdialog` wrapper with kio-extras.
  Noctalia's PATH already includes `/run/current-system/sw/bin`.
- `flake.nix` passes monstar, claude-desktop-nix and zen-browser to the NixOS
  modules instead of Home Manager. Cursor, session variables and
  `sessionEditor` stay in Home Manager.

`nix flake check` passed; `erebor-diff`: different (packages move from the
per-user profile to system-path; their MIME cache entries move with them).

Activated generation 297 with no failed system or user units. All moved
binaries resolve from `/run/current-system/sw/bin`, the old `~/.local/bin`
links are gone, `gdbus introspect` on the session bus works and `kdialog`
reports 26.04.3. Phone Connect itself was not exercised.

# qBittorrent around the VPN — 2026-11-06

User asked to route qBittorrent without the VPN. On the PL#56 Proton server
upload was 4.5 Mbit/s against 103 Mbit/s on the bare line.
- `hosts/erebor`: `my.torrentVpn.enable = false`. The peer port is back to
  6881 on br0 and the Proton port-forward service is gone.
- `modules/services/qbittorrent.nix`: the container keeps its fixed IP
  10.88.255.250 in both modes. In direct mode, `qbittorrent-direct-route` adds
  `ip rule from 10.88.255.250 lookup main` (priority 31000, before Proton's
  catch-all), so the container leaves through br0 even while Proton is
  connected. The firewall lets 6881 on br0 past the reverse-path filter, which
  would otherwise drop peers while Proton holds the route, and removes the
  leftover VPN-only FORWARD rule.

`nix flake check` passed; `erebor-diff`: different (new service, vpn-port
service and libnatpmp removed, firewall and container unit changed).

Activated generation 295: the rule was in place but qBittorrent could not
reach the internet. Replies on br0 to the masqueraded container are checked
by the reverse-path filter before de-NAT (destination 192.168.1.106, route
back via proton0) and dropped. Fix: the rpfilter also lets through br0
packets whose conntrack original source is 10.88.255.250.

Activated generation 296 with Proton still connected: qBittorrent's exit IP
is 83.10.5.5 (Orange), DNS works, `listen_port` 6881, and portchecker.io
sees 83.10.5.5:6881 open.

# Proton VPN WireGuard on the br0 bridge — 2026-11-06

Proton VPN (WireGuard) failed to connect: while connecting, the app always
adds a route to the VPN server on each ethernet/Wi-Fi device, whatever the kill
switch setting, and crashed on `enp4s0` (a br0 port without IPv4 settings);
it never considered br0, which has the gateway.
- `modules/proton-vpn-bridge.nix` + `.patch`: patches
  `proton-vpn-api-core` 5.0.1 `get_physical_devices` to skip devices whose
  connection has no IPv4 settings and to include bridges that have a gateway
  (so not podman0 or virbr0).
- OpenVPN also fails ("Support for given configuration is not implemented"):
  the NetworkManager OpenVPN plugin is not installed. Not changed.

`nix flake check` passed; the built package contains the patch.
Activated generation 294. After restarting the app, WireGuard connected to a
P2P server (host exit IP 146.70.161.186); no crash in the app log.

# zram swap and swappiness — 2026-11-06

User asked to enable zram and retune swappiness after the 2 GiB swap
partition filled with idle pages (open-webui, jellyfin, Xwayland servers
leaked by Moonshine sessions) while 22 GiB RAM was still available.
- Shared workstation module: `zramSwap` (zstd, 50 % of RAM), plus
  `vm.swappiness=180` and `vm.page-cluster=0`, the usual settings for
  swap held in RAM.
- The NVMe swap partition is not declared in Nix (`swapDevices = [ ]`); systemd-gpt-auto-generator
  activates it automatically and it stays as lower-priority overflow (−2 vs. zram 5).

`scripts/erebor-diff`: different (zram generator unit, sysctl). `nix flake check` passed.
Activated as generation 293: `/dev/zram0` swap active (zstd, 15.6 GiB, prio 5),
`vm.swappiness=180`, `vm.page-cluster=0`; no failed units.

# qBittorrent through Proton VPN — 2026-11-06

User asked to route qBittorrent through Proton VPN with Proton's port
forwarding, replacing the home-IP port 6881 set up earlier today.
- `my.torrentVpn.enable` (on for erebor): the container gets the fixed address
  10.88.255.250. Firewall chain `qbt-vpn-only` (FORWARD) lets it reach only
  `proton0` and private networks; with the VPN down its internet traffic is
  rejected. The chain is not removed when the firewall stops (fails closed).
- `qbittorrent-vpn-port.service`: every 45 s asks Proton for the forwarded
  port (NAT-PMP via 10.2.0.1), DNATs it from `proton0` to the container
  (nat chain `qbt-vpn-port`) and sets qBittorrent's listen port through the
  API from inside the container (`WebUI\LocalHostAuth=false` in
  qBittorrent.conf, set by hand; requests via the proxy come from 10.88.0.1).
- The container uses Proton's DNS (10.2.0.1, `--dns`), reachable only through
  the tunnel. It had inherited Tailscale's 100.100.100.100, which the chain
  rejects.
- Port 6881 is no longer published or opened; the router's 6881 forward is
  unused. WireGuard only (`proton0`); Proton's own kill switch crashes on
  the br0 bridge and must stay off.

`scripts/erebor-diff`: different (new service, firewall and container unit).
`nix flake check` passed.
Activated generations 292 (VPN routing) and 293 (DNS). VPN off: the container's
internet traffic is refused, LAN reachable, API works, Web UI still needs a
login. VPN on (generation 294): the service mapped Proton's port 44832 (same
as the app reports), qBittorrent switched from 6881, and portchecker.io found
146.70.161.186:44832 open. From inside the container: exit IP 146.70.161.186,
DNS resolves through 10.2.0.1, listen_port 44832, connection_status
"connected".

# `erebor-diff` compares rebuilt store paths — 2026-11-06

User asked to fix a gap in `scripts/erebor-diff`: "equivalent" masked store
hashes in `/etc`, so content changes behind a hash were invisible. Changing
one Umbriel blur value was reported as equivalent; so was the
[qBittorrent port change](#qbittorrent-peer-port-reachable--2026-11-06),
whose firewall rules live in a referenced store path.
- When nothing else differs, every store path in only one closure is now
  compared with its same-named counterpart, store hashes masked (line order
  ignored as a fallback). Content changes print a diff and make the result
  "different".

Tested: the Umbriel edit is now "different" with the `hm_config.toml` diff;
two commits whose probe `runCommand` differed only in its script (same output)
remain "equivalent". `shellcheck` clean. Script only; no activation needed.

# 8 MiB readahead on spinning disks — 2026-11-06

User asked for disk caching for seeding from HDDs. qBittorrent 5.x relies on
the page cache, so larger readahead is the lever.
- `hosts/erebor/storage.nix`: a udev rule sets `bdi/read_ahead_kb` to 8192 on
  rotational `sd*` and `dm-*` disks. The SATA Seagates already reported
  8192; the USB Expansion drive and `bigdaddy` on it were at 1024.

`scripts/erebor-diff`: different (only the new udev rule). `nix flake check`
passed.
Activated generation 291; no failed units. After `udevadm trigger --action=change`
on sda and dm-0, `read_ahead_kb` is 8192 on sda, sdc, sdd and dm-0. Effect on
upload speed is not measured.

# qBittorrent peer port reachable — 2026-11-06

User asked to open the qBittorrent peer port so other peers can connect for
seeding. The container published only the Web UI, and the LAN firewall did not
allow 6881.
- `modules/services/qbittorrent.nix`: publish `6881/tcp` and `6881/udp` and
  allow both on the LAN interface (only when qBittorrent is enabled).
- The router still needs a manual 6881 TCP/UDP forward to 192.168.1.106;
  UPnP cannot work from the podman bridge.

`scripts/erebor-diff`: equivalent (only firewall and container unit store
paths differ). `nix flake check` passed.
Activated generation 290; no failed units. Verified: host listens on
6881 TCP/UDP, `nixos-fw` accepts 6881 TCP/UDP on br0, Web UI answers. The router
forward and an external reachability check are not done.

# Approval reason for sudo/Polkit; Oxygen YubiKey sound — 2026-11-06

User asked to know why a Touch ID / YubiKey approval was triggered, and for
Oxygen's `dialog-question` as the YubiKey sound.
- `modules/approval-reason.nix`: an optional `pam_exec` step (order 10600,
  before pam_rssh 10700 and pam_u2f 10900) in sudo and polkit-1 writes
  `/run/auth-reason/<user>` (0600, owned by the user): a timestamp plus
  `sudo <command>` or a generic Polkit line. It always exits 0, so it can't
  block authentication. `auth-reason-stream` prints new reasons for the Mac
  tunnel. MAC_APPROVAL.md shows the Mac-side `osascript` pipe; the Mac's
  launchd tunnel is unchanged until the user updates it.
- The YubiKey notification shows the reason if it is under 2 minutes old.
- `my.yubikey.sound` (default: the previous freedesktop sound); erebor uses
  Oxygen `dialog-question.ogg`.

Activated generation 288; no failed units. The first live sudo wrote no reason:
pam_exec runs as the calling user unless given `seteuid`, so the step now
uses it (same as the Mac step).
Activated generation 289. Verified: `sudo -k; sudo id -u` wrote
`/run/auth-reason/janzon` (0600, janzon) with `sudo id -u`, and the notifier
showed its prompt at the same moment. The user confirmed the notification
showed `sudo id -u`. The Mac-side tunnel change is not done.

Validation: `nix flake check` passed (format check included; template
evaluates). PAM stacks inspected for both features and for YubiKey only.
`scripts/erebor-diff`: different, as intended; the only real changes are the two
PAM lines, the notifier unit (new script and sound), the `/run/auth-reason`
tmpfiles line and the `auth-reason-stream` package.

# nixfmt formatting: `nix fmt` and a format check — 2026-11-06

- `flake.nix` adds `formatter.x86_64-linux` (`nix fmt` runs nixfmt 1.5.0, RFC
  166 style, on every tracked `.nix` file outside `apps/`, or on the files
  given) and `checks.x86_64-linux.format`, which runs `nixfmt --check` on a
  source filtered to `.nix` files, so it rebuilds only when one changes.
- One reformat-only commit covers 44 files; AGENTS.md asks for `nix fmt`
  before committing.

Validation: `scripts/erebor-diff` against master reports **identical** (same
drvPath) for both erebor and template. The check fails on an unformatted file
(tested) and passes on the reformatted tree; `nix flake check` passes. No
activation needed.

# Service registry generates Caddy routes, hosts and LAN ports; workstation parts switchable — 2026-11-06

- `my.services.<name>` (`modules/my.nix`) describes each web service:
  `enable`, `port`, `localName`, `publicName`, `lanPort`,
  `proxy.{headers,lanHeaders,https,tlsInsecure}` and `extraConfig`. Each
  `modules/services/*.nix` declares its entry and only configures the service
  when enabled. `caddy.nix` generates the `:80` local routes, LAN port blocks
  and `*.<domain>` routes; `base.nix` generates the `networking.hosts` names
  and the LAN TCP ports. Dashboard, `dashboard_controls`, browser imports,
  hyperhdr and the final `abort` stay hand-written.
- New toggles: `my.services.{jellyfin,nextcloud,syncthing,qbittorrent,ollama,
  t3code,cockpit}.enable`, `my.niri.enable` (system and Home Manager Niri
  parts), `my.streaming.{sunshine,moonshine}.enable` (`sunshine` also enables
  its route). Cockpit moved to `modules/services/cockpit.nix`, T3 Code to
  `modules/services/t3code.nix`. Erebor enables all of them; the template
  lists them commented out.
- Verification (before activation): `nix store diff-closures` master →
  branch is empty; only Caddyfile, hosts, caddy unit/reload trigger, etc,
  system-units and toplevel paths differ. Generated Caddyfile vs master as
  sorted, whitespace-normalized lines: identical except the Sunshine
  self-signed comment (now a Nix comment). `/etc/hosts`: same names, different
  order on the 127.0.0.1 line. `caddy.service` identical after masking hashes.
  `scripts/erebor-diff` reports "different" for exactly those two
  order/comment changes. `nix flake check` passes (template evaluates with
  everything off). Variant with `my.services.syncthing.enable = mkForce false`:
  no syncthing route, hosts names, port 8384 or container.
- Activated 2026-11-06 with `scripts/erebor-rebuild switch` as generation
  287; only `caddy.service` reloaded. No failed system or user units.
  `curl -sI`: media 302, cloud carddav 301, sync/torrent/sys/code/ai 200,
  unknown subdomain aborted, sunshine 502 (service disabled, as before);
  jellyfin/nextcloud.localhost 302, syncthing/torrent.localhost 200,
  hyperhdr.localhost 405, :8096 302, :8384 200.

# `scripts/erebor-diff`: compare a branch's built system with master — 2026-11-06

Automates the per-step check used during the host/module refactor.
`scripts/erebor-diff [--host NAME] [base-ref] [target]` builds the toplevel of
both (base from a temporary detached worktree with submodules) and reports
identical (same drvPath, exit 0), equivalent (empty diff-closures, same
system-path tree, /etc equal after masking store hashes and sorting lines;
exit 1), different (exit 2) or error (exit 3). AGENTS.md asks for it before
merging a refactor.

Validation: master vs master → identical; a commit reordering erebor's
imports → equivalent; a commit adding `hello` → different (closure and
system-path diff shown); an evaluation error → exit 3 with worktrees removed.
`bash -n` and shellcheck pass. Nothing deployed; no activation.

# Noctalia theme colours reach Umbriel; read-only config no longer breaks the hook — 2026-11-06

- Noctalia's Umbriel template hook (`templates/umbriel/apply.sh`) tried to
  `cp` an `[include.optional] files = ["noctalia.toml"]` entry into
  `~/.config/umbriel/config.toml`, which Home Manager deploys read-only, so it
  failed on every theme change and Umbriel never loaded Noctalia's colours.
- `home/umbriel/config.toml` now ends with that include itself. Noctalia keeps
  writing the colours to the writable `~/.config/umbriel/noctalia.toml`, and
  `apply.sh` finds nothing to change (it only copies when its rewrite differs).
  The canonical config has no `[colors]`, so nothing is overridden.
- Activated as generation 286. Check: `apply.sh` against a read-only copy exits
  0 and leaves it byte-identical; `umbriel config validate` ok; two
  `noctalia msg theme-mode-toggle` runs each logged Umbriel `config reloaded
  (sections: colors, window rules ...)` and no Umbriel hook failure. Theme mode
  ends where it started.
- Not fixed: Noctalia's cava and fastfetch template hooks still fail because
  `~/.config/cava/config` and `~/.config/fastfetch/config.jsonc` do not exist.

# Monthly change log files; config split activated — 2026-11-06

- `SYSTEM_CHANGELOG.md` now holds only the current month. October 2026 (248
  entries) moved unchanged to `changelog/2026-10.md`. 106 links in
  `SYSTEM_TODO.md` now point there. AGENTS.md describes the monthly rotation.
  Check: the non-blank lines of both files equal the old file plus the new
  headers; all 116 links in the records resolve.
- The portable config refactor (entry below) merged into master together with
  the MacBook sshd keepalive (now `my.macApproval.addresses`), and was activated
  as generation 285 through `scripts/erebor-rebuild switch`. Before activation,
  the merged build had the same closure as master's and the same `/etc`
  content apart from store hashes and order. After it: no failed units, sshd
  has the MacBook `Match Address` block, and xremap's PATH starts with
  `/run/wrappers/bin`.
# Portable configuration: per-host my.* options and a template host — 2026-11-06

User wants to set up similar machines without erebor's ambilight, YubiKey or
NanoKVM, and with different addresses.
- `modules/my.nix`: every setting is a group (`my.user.*`, `my.network.*`,
  `my.ambilight.*`, ...) so new options can be added without renaming. It holds
  user, domain, LAN interface, xremap devices, and toggles for
  ambilight (with its WLED URL and music sink), YubiKey, Mac approval and
  NanoKVM (the dashboard's wake/outlet URLs and buttons follow these).
- Shared parts moved to `modules/workstation/` (base, session, keyring, ssh,
  caddy, packages, t3code) and `modules/services/`; `hosts/erebor/` keeps
  hardware, boot, storage and its settings. `flake.nix` builds hosts with
  `mkHost`.
- `hosts/template/` evaluates as `nixosConfigurations.template` with every
  optional feature off.

Validation: each step compared erebor's build with the previous commit. The
toggles and the user/domain options left the system derivation byte-identical.
Moving modules changed only merge order: same closure (diff-closures empty),
identical system-path tree, and every differing /etc file has the same content
after normalizing store hashes and ordering (dbus service dirs, polkit rules,
tmpfiles). The template evaluates. Not activated.

# Split flake.nix and the erebor host file into topic modules — 2026-11-06

Pure refactor so parallel agents rarely edit the same file.
- janzon's Home Manager config moved from `flake.nix` to `home/janzon/`
  (default, shell, desktop, apps, compositor); flake inputs reach it through
  `home-manager.extraSpecialArgs`.
- `hosts/erebor/default.nix` (816 lines) split into boot, storage, input,
  session, hyperhdr, t3code, keyring, ssh, caddy and packages modules. They are
  imported first to keep the original merge order. Noctalia's Python moved to
  `packages/noctalia-python.nix`.

Validation: the Home Manager step left the system derivation byte-identical.
After the host split, the only change was the position of moonshine and helium
in the package list; the built system-path trees are identical (12198 entries).
Caddyfile, udev rules and units otherwise match. Not activated.

# Umbriel optimized blur — 2026-11-06

User asked to enable optimized blur. `blur_optimized` set to true on the
Noctalia, Vicinae and window rules in `home/umbriel/config.toml`, so blur uses
the cached wallpaper instead of live content behind each surface. Activated
generation 283 (`gn5xfw3p…`); no failed units; deployed config has the change.
User confirmed the result looks good.

# Parallel-agent workflow: worktrees, locked rebuilds, union merges — 2026-11-06

User runs several agents on this repo at once and asked for fewer conflicts.
- `scripts/erebor-worktree <task>` gives each agent `~/nixos-wt/<task>` on
  branch `agent/<task>`, with the dashboard submodule initialized.
- `scripts/erebor-rebuild` builds from any checkout, but activates only from
  `/etc/nixos` on master. It holds a flock in `$XDG_RUNTIME_DIR`, uses
  `/run/wrappers/bin/sudo`, and lists uncommitted changes before activating.
- `.gitattributes`: `merge=union` for SYSTEM_CHANGELOG.md and SYSTEM_TODO.md.
- AGENTS.md: new Parallel agents and Umbriel workflow sections.

Validation: created a test worktree; switch from it was refused; dry-build
from it passed; a second rebuild waited on the held lock; test worktree
removed. Nothing activated (the scripts are not deployed).

# MacBook approval tunnel: sleep hooks and Tailscale — 2026-11-06

Mac-side only (no erebor generation). User asked for both follow-ups to the
keepalive change. Installed Homebrew sleepwatcher; `~/.sleep` boots out
`com.janzon.erebor-ssh` and `~/.wakeup` bootstraps it. The Mac's ssh config now
uses erebor's Tailscale IP (100.108.216.80) when its utun has 100.127.94.102,
else the LAN IP; backup at `~/.ssh/config.bak-2026-11-06`.

Verified: tunnel connects from 100.127.94.102 and refreshes agent.sock; running
the sleep hook removed erebor's tunnel session at once, and the wake hook
restored it within 5 s. User confirmed a real lid-close: sudo's YubiKey
prompt came without delay. The
erebor Match keeps the LAN IP for the fallback path.

# SSH keepalives for the MacBook — 2026-11-06

sudo's YubiKey prompt was delayed because pam_rssh first asked a forwarded
agent in a MacBook SSH session that had been half-open since 2026-11-05 21:17.
The Mac was asleep (macOS answers TCP keepalives while asleep), so the request
waited for the 30 s timeout. sshd now sets `ClientAliveInterval 60` and
`ClientAliveCountMax 3` in a `Match Address` block for the MacBook's Tailscale
(100.127.94.102) and LAN (192.168.1.97) addresses. sshd can't match on keys.

Activated generation 282 (`vbq1lhc1…`). Verified: no failed units, sshd
active, generated sshd_config ends with the Match block. Limits: sessions
opened before the reload keep the old settings; the LAN IP comes from DHCP
(private Wi-Fi address) and may change.

# Setuid sudo first in xremap and ttyd PATH — 2026-11-06

User often hit "sudo … must be owned by uid 0 and have the setuid bit set".
Cause: xremap (user service, `--allow-launch`) and ttyd set `path` to
`system.path` + Home Manager path. That PATH starts with the store system-path
(non-setuid sudo), omits `/run/wrappers/bin`, and is inherited by everything
xremap launches. A monstar terminal had `SYSTEMD_EXEC_PID` = xremap's PID and
the same PATH. Both services now force a PATH of `/run/wrappers/bin` followed
by profile links (no store paths, so it doesn't go stale after rebuilds).

Activated generation 281 (`iarx1yjm…`). Verified: no failed system or user
units; xremap and ttyd active; xremap's PATH starts with `/run/wrappers/bin`
and resolves `sudo` to the setuid wrapper; ttyd's unit has the same PATH.
Limits: terminals that were already open keep the old PATH until reopened.


SYS-071 follow-up. User asked for 0.8 instead of 0.95. Dashboard `eb1bf67`
changes the `--term-opacity` default. The first activation attempt failed at
sudo (no touch approval) and stayed on generation 279; the retry activated
generation 280 (`ih69qc4d…`). Verified: no failed units, served CSS has
`--term-opacity, .8`. ttyd was not restarted.

# Translucent browser terminal in the dashboard — 2026-11-05

SYS-071 follow-up. User reported a black bar at the bottom of the tabbed
terminal window and asked for a 95% translucent, blurred background.
- The bar was the tab-mode resize strip (solid #000); it now uses the
  terminal tint.
- ttyd draws a transparent xterm background (`allowTransparency`, transparent
  `theme` in `modules/browser-terminal.nix`).
- `packages/ttyd-web-assets.nix` paints #2b2b2b on the page, unless the page is
  framed (`html.embedded`).
- Dashboard `4bf2fd3`: windows and the tab frame blur the page behind them and
  tint the terminal area with #2b2b2b at 95%. Title and tab bars are frosted.
  The iframe uses `color-scheme: normal` so browsers don't paint an opaque
  backdrop.

Validation: a Playwright pixel test against a real local ttyd 1.7.7 (read-only,
test pattern, same client options and assets) passed 8/8:
- Light page: the terminal area is (54,53,54) vs solid (43,43,43), i.e.
  translucent.
- Dark page: it stays dark (42,42,43), with no opaque backdrop.
- The tab-mode footer matches the terminal in both schemes.
- Opened directly, the terminal is still exactly #2b2b2b.

`nix flake check` passed. Activated → generation 279 (`23j4xnjm…`). Verified:
ttyd active with the new client options and page, dashboard-control active, no
failed units, served CSS contains the tint. The ttyd restart ended open browser
terminal sessions.

# Dashboard tabbed terminal window — 2026-11-05

SYS-071 follow-up. User asked for an option to merge all windows and use tabs.
Dashboard `0c9670f`:
- "Merge into tabs" in any title bar puts every window into one tabbed window:
  switch, close, + new tab, arrow keys, open in a new browser tab, minimise to
  one dock chip, maximise.
- "Split into windows" reverses it. Iframes never move in the DOM (that would
  reload them and end their shells): in tab mode they are laid over the tab
  frame's content area.
- The mode is remembered per device.

Validation:
- The window suite passed 31/31, including: merge and split keep each
  terminal's in-page marker (no reload), only the active tab is visible and
  aligned to the content area (also after dragging), tab switch/close/new,
  minimise/restore, mode remembered.
- The main suite passed 38/38.
- `nix flake check` passed.

Activated → generation 278 (`00sl0hvg…`). Verified: dashboard-control active,
no failed units, served bundle contains tabs.

# Dashboard multiple terminal windows — 2026-11-05

SYS-071 follow-up. User asked to open multiple terminals. Dashboard `f3b2b5a`:
- Each Terminal click, or the title-bar +, opens another window, up to 8. Each
  window is its own iframe, so ttyd starts a separate shell for it.
- Windows are numbered, cascade, and come forward on click (including clicks
  inside the iframe), and can be minimised.
- A dock restores, focuses or minimises windows. On phones each window is
  full-width above the dock.

Validation:
- The Playwright window suite (fake HTTPS terminal) passed: three windows with
  their own frames, cascade, raise by title bar and by iframe click,
  minimise/dock restore/dock minimise, + reuses a freed number, drag, maximise,
  close all, ctrl-click tab, a non-listed host keeps the link, phone layout.
- The main suite passed 38/38.
- `nix flake check` passed.

Activated → generation 277 (`9d73mqai…`). Verified: dashboard-control active,
no failed units, served bundle contains the dock.

# Dashboard terminal window, heading-click folding, animations — 2026-11-05

SYS-071 follow-up. The user asked for:
- ttyd in a draggable in-page window — only the terminal, and only on
  erebor.jzon.pl.
- Folding by clicking a section's heading row.
- Animated reordering, and a springy fold/unfold that snaps into place.

Dashboard `bb08c04`:
- The terminal service has `embedOn: ["erebor.jzon.pl"]` and opens in a
  draggable, resizable window with open-in-tab, maximise and close (full screen
  on phones). Ctrl-click and other hosts keep the link.
- The `modules/browser-terminal.nix` CSP is now
  `frame-ancestors 'self' https://erebor.jzon.pl`. Tailscale, password and Origin
  checks are unchanged.
- FLIP animation of other items while dragging. Sliding items ignore the pointer
  during a drag so CDK hit-testing doesn't swap them back.
- Spring max-height fold, staggered row reveal.

Validation:
- API tests passed.
- The main Playwright suite passed 38/38 three runs in a row: peak 3 items
  sliding mid-drag, no replay on drop, heading click folds and unfolds, revealed
  rows animate.
- The window suite passed 10/10 against a fake HTTPS terminal: loads, drag,
  maximise/restore, close, ctrl-click, non-listed host keeps link, phone full
  screen.
- `nix flake check` passed.

Activated → generation 276 (`ifgwkpmd…`). Verified: dashboard-control active,
no failed units, served bundle contains the window, running Caddy config has the
new terminal CSP, terminal still returns 401 Basic auth. Untested live: the
terminal in the window with the real password prompt (browsers may not show Basic
auth inside a frame; the window offers "open in new tab").

# Dashboard foldable sections and PIN autofill opt-out — 2026-11-05

SYS-071 follow-up. User asked to fold sections to N rows, with N set by
dragging (One UI style), and to keep the Moonlight PIN out of password managers.
Dashboard `2a203fe`:
- A heading chevron folds Quick actions or Services to their first N rows, with
  a "Show all" pill. Rows below the fold are inert.
- In edit mode a dashed fold line with a grip sets N: drag it (snaps between
  rows, live label) or use the arrow keys.
- `layout.folded` and `layout.foldRows` are stored per account.
- The PIN field uses `autocomplete=off` plus the 1Password, LastPass, Bitwarden
  and Dashlane ignore attributes.

Validation:
- API tests passed.
- A local Playwright run passed all 33 checks: fold to 1 row (2 of 10 services
  reachable), drag to 3 rows, arrow keys, persistence across reload, Show all,
  and the PIN attributes.
- `nix flake check` passed.

Activated → generation 275 (`s4v39p6h…`). Verified: dashboard-control active,
no failed units, served bundle contains folding.

# Dashboard movable action tiles and spacers — 2026-11-05

SYS-071 follow-up. User asked that Wake up and the other action buttons move
freely, and for empty 1-unit spacer cards (1 unit = one button tile). Dashboard
`2f8371f`:
- Quick actions are one grid: 4 units wide, 2 on phones.
- Status cards span 2 units. Action buttons are 1-unit tiles that drag and hide
  like the cards.
- In edit mode, "Add spacer" inserts an empty 1-unit cell, in Quick actions and
  Services. Spacers are stored in the per-user order and removed with ✕.

Validation:
- API tests passed.
- A local Playwright run passed all 25 checks, including Wake up dragged first,
  spacer width = button tile (205 px), and spacer add/remove/persist, blank
  outside edit mode.
- `nix flake check` passed.

Activated → generation 274 (`3a69i49r…`). Verified: dashboard-control active,
no failed units, served bundle contains spacers.

# Dashboard per-user layout edit mode — 2026-11-05

SYS-071. User asked to drag and drop quick-action cards and services, to hide
items, to have a "show hidden" toggle, and to remember all of this per user. They
also asked for an Android-style pencil edit mode with iPhone-style wiggle, and to
hide the install hint when the dashboard runs as an installed app. Dashboard
`dd8ec74`:
- New `users.layout` column, migrated in place, and `PUT /api/control/layout`.
- Pencil button (top right) toggles edit mode. In edit mode, items wiggle,
  whole cards drag (arrow keys work on the move button), and an eye button hides
  each item. A "Show hidden (N)" header toggle appears otherwise.
- Install footer hidden in standalone/iOS home-screen mode.

Validation:
- API tests (62) passed.
- A local Caddy+API Playwright run passed all 17 checks: no drag outside edit
  mode, wiggle, hide, mouse drag, keyboard move, persistence across reload,
  show-hidden, separate guest layout, footer hidden when standalone, no page errors.
- `nix flake check` and the build passed.

Pitfall: Nix builds the submodule at the parent HEAD's gitlink (`self.submodules`),
so a staged bump was not enough. Committed the bump (`28ab07b`) and built via
`insteadOf` the local checkout. Activated → generation 273
(`hpks00m0…-nixos-system-erebor`). Verified: dashboard-control active, no failed
units, live DB has the `layout` column (janzon, karol default), endpoint 401
unauthenticated, served bundle contains edit mode. Untested live: the user's own
devices.

# Fish image preview aliases — 2026-11-05

User asked for aliases for the ttyd sixel previews. Added fish alias `img`
(`chafa --format=sixel`) and function `imgs` (previews given files, or all
images in the current directory, with filenames) in `flake.nix`. Flake check and
dry-build passed; activated → generation 272 (`y22imy6c…`), no failed units.
Verified `img` resolves in an interactive fish and `imgs` emits sixel output for
a test PNG. Untested live: rendering in a browser session.

# Browser terminal sixel image previews — 2026-11-05

User asked to configure image previews in the ttyd browser terminal. Enabled the
ttyd 1.7.7 `enableSixel` client option and added `chafa` to system packages in
`modules/browser-terminal.nix`. `nix flake check` and `dry-build` passed.
Activated → generation 271 (`fc8hqkg1…-nixos-system-erebor`); ttyd restarted
active with `--client-option enableSixel true`, served page contains the sixel
addon, `chafa` on PATH, no failed units. Untested live: rendering an image in a
browser session (`chafa -f sixel image.png`).

# Dashboard recent accounts and performance profiles — 2026-11-05

SYS-070. User asked for the dashboard sign-in screen to list recently signed-in
users, and to switch performance profiles. Chosen design (user): per device —
the browser keeps up to 5 usernames with sign-in times in `localStorage`; tiles
prefill the username and can be removed. Nothing is exposed by the server. New
quick-action card "Performance" (`profile-power-saver`/`-balanced`/`-performance`)
sets power-profiles-daemon `ActiveProfile` via `busctl`. The status shows the
active profile and any `PerformanceDegraded` reason. A polkit rule grants janzon
`org.freedesktop.UPower.PowerProfiles.switch-profile`, because the user service
has no active session. API tests (60), `nix flake check` and `nixos-rebuild build`
passed. Activated → generation 270 (`hhh4xcnw…-nixos-system-erebor`). FIDO touch
approved sudo; the job's PATH lacked `/run/wrappers/bin`. Verified:
dashboard-control active, no failed units; `busctl` profile set from the user
manager succeeded (polkit rule effective); live OpenAPI lists the actions and
`profile` status; served bundle contains the new UI. Untested live: the sign-in
tiles and profile card in a real browser session.

# rcmd chooser: new window and desktop actions — 2026-11-05

User asked that the Right Ctrl+Alt+<letter> app chooser (`home/rcmd/rcmd.py`)
can open a new instance, then for more actions. Running apps now get a
`＋ New window — <App>` row (desktop action `new-window`/`NewWindow`/
`new-instance`/`NewWorkspace` when present, else a plain relaunch), and every
other desktop action of each matching app is listed as `↳ <Action> — <App>`
(e.g. Zen/Chrome private window, Konsole new tab, Claude new chat). Actions run
in their own `systemd-run --user --scope`; rcmd focuses the newly appeared window
(falls back to the app's latest window after 8 s). `nix flake check` and
`dry-build` passed; offline test of chooser rows/launch commands passed.
Activated → generation 269 (`xdyfrlp6…-nixos-system-erebor`), sudo approved by
FIDO touch. Built as janzon with a one-shot git `insteadOf` pointing the
`erebor-dashboard` submodule URL at the local checkout (its pinned 9d08128 is 2
commits ahead of origin/main, unpushed). Verified deployed rcmd contains the
change, xremap active, no failed units. Untested live: chooser UI (job had no
Niri socket).

# NanoKVM Tailscale update to 1.104.5 — 2026-11-05

User asked to update Tailscale on NanoKVM `kvm-37ff` (manual remote state, not
flake-managed). Static riscv64 1.104.5 (current stable) binaries were already in
`/usr/bin/tailscale` and `/usr/sbin/tailscaled` while the 1.80.2 daemon kept
running. Ran `/etc/init.d/S98tailscaled restart` over LAN SSH
(`root@192.168.1.122`). Its stop step reported OK, but the old daemon kept running
alongside the new one on the same state/socket, and the new daemon stalled in
disk sleep at 3 MiB free RAM. SIGKILL of the old PID let 1.104.5 start. Verified:
one tailscaled at 1.104.5, node `100.114.21.112` online with direct 1 ms ping from
erebor, `CorpDNS` false, Serve 8443 → 127.0.0.1:18091 intact, wake helper
`/health` ready and `/status` returning LED and Tailscale OS-probe state over Serve.

# Monstar activation, tab key and terminal keymaps — 2026-11-05

SYS-067. User launched Monstar and asked for a Super+T tab key and a working
Ctrl+D. Monstar 1.1.0 has no tabs, so xremap launches
`~/.local/bin/umbriel-monstar-tab` (`home/umbriel/monstar-tab`) for
`dev.rockorager.monstar`; it spawns a window in the focused shell's directory and
stacks it into the focused column as an Umbriel tab. Monstar was missing from the
xremap terminal lists, so Ctrl+D/A/E/K were rewritten as Delete/Home/End
and Super+C/V as Ctrl+C/V; it is now in the terminal clipboard keymap and excluded from the
non-terminal line-navigation keymap. `home/monstar/config` shares Ghostty's opacity.
Flake check and build passed; user ran `nixos-rebuild test`, then `switch` →
generation 268 (`7cxr0a9z8ras…-nixos-system-erebor`). xremap kept its old config
after each activation until `systemctl --user restart xremap`. Verified: script
run produced a tabbed column, user confirmed Super+T tabs and Ctrl+D closing a
Monstar window. Super+W has no Monstar close action (unchanged).

# Moonlight pairing in the dashboard hub — 2026-11-05

SYS-069. Added the `moonshine-pair` dashboard action (submodule `9d08128`), enabled
it for the control API and hub settings. The API reads pending Moonlight client IDs
from `moonshine.service`'s journal (verified readable inside the user-unit
sandbox) and posts the PIN to `http://127.0.0.1:47989/submit-pin` for the newest
waiting client only. Built from a copy of the committed tree plus these changes
so another session's uncommitted Monstar/xremap/flake edits were not activated.
`nixos-rebuild test`, then `switch` → generation 267
(`ih2ahfa3flpy…-nixos-system-erebor`). Live: `dashboard-control` active with
`DASHBOARD_MOONSHINE_URL`, pairing endpoint 401 without a session, no failed
units. Real client pairing through the hub is untested.

# Dashboard user accounts — 2026-11-05

SYS-068. Added accounts to the erebor dashboard (submodule commit `e0d1859`): first-run
administrator wizard, admin-managed users with per-user modules/services/actions,
API-enforced action permissions, and a cached last view for Wake while the host
sleeps. Public `config.json` now carries only branding. Validation: API unit tests
(47), dashboard and parent `nix flake check`, `nixos-rebuild build`, and a local
browser run of setup → add restricted user → restricted sign-in → API-down cached
view. This also resolved the missing `auth` module build failure under SYS-067.
Activated at user request together with SYS-067 and the t3code `ConditionUser`
edit: `nixos-rebuild test`, then `switch` → generation 266
(`gkim8yinpc1j…-nixos-system-erebor`). Live checks: `dashboard-control` active,
`users.sqlite3` mode 0600, public `config.json` branding-only, session endpoint
reports setup required, unauthenticated `/api/control/status` 401, Caddy and ttyd
active, no failed system/user units (noctalia's earlier failed state cleared),
`monstar --version` 1.1.0. Pending: user completes the setup wizard (SYS-068).

# Monstar preparation — 2026-11-05

Added upstream Monstar 1.1.0 at revision 406c48e to Home Manager, retaining
its separately pinned Nixpkgs because the system's Nixpkgs lacks Zig 0.17.
`nix flake check` and `nixos-rebuild dry-build --flake /etc/nixos#erebor`
passed. Activation and graphical behavior remain unverified; administrator
authentication is required, and the current tree contains unrelated dashboard
and service edits that a full activation would also apply. See [SYS-067](tasks/SYS-067.md).
The upstream package built successfully and `monstar --version` returned 1.1.0.
On retry, administrator authentication succeeded, but the full system build
failed: the separately modified dashboard control package imports `auth`, which
is untracked and absent from its flake source. No activation was attempted.

## [COMPLETED] ttyd file transfers — 2026-11-05

SYS-066. User requested uploads/downloads. Enabled ttyd's existing trzsz client
and packaged upstream trz/tsz 1.2.0 as system tools, using its x86_64 Linux
release archive pinned to the SHA-256 verified against release asset metadata.
Pinned Nixpkgs has no standalone trzsz package. No new listener or upload API;
transfers use the authenticated terminal WebSocket as janzon.

Flake check and full system build passed. Isolated Chromium transferred a
65,536-byte binary fixture with a Unicode filename in both directions, exact
content verified, no page errors. Browser file/directory pickers were mocked
for automation; actual native dialogs and directory transfer are untested.
Test artifacts remain only under /tmp/ttyd-transfer-*.

Before activation: live/selected generation 264,
`/nix/store/ajdns1k3kjlmhnv50mykwcnsvxmp8y34-nixos-system-erebor-26.05.20261029.6f06d20`.
Target: `/nix/store/fzixw0fivvs62clcm6w643mwnqnd0jws-nixos-system-erebor-26.05.20261029.6f06d20`.
Root/ESP/btrfs-top UUIDs, Windows EFI entries and firmware order checked.
No failed system units; user GTK portal failed again during browser testing,
unrelated to terminal services. Uncommitted host ConditionUser edit is already
live and remains untouched. Initial agent activation attempts stopped at sudo
authentication without changes. User subsequently ran the helper and reported
completion. Inspection verified generation 265 persistently selected/live at
the target above; caddy/ttyd active and no failed system/user units. Live trz/tsz
report 1.2.0, ttyd startup enables trzsz and preserves the font fallback, and
unauthenticated HTTPS returns 401. Root/ESP UUIDs remain correct.
Recovery snapshot is `/btrfs-top/nixos-root-pre-ttyd-transfers-20261105`;
generation 264 remains available. The helper is superseded; do not replay it.
Actual native browser picker/directory-transfer behavior remains untested;
isolated file transfers passed as above. No reboot performed. Unrelated
dashboard submodule and host edits were left untouched.

## [COMPLETED] ttyd legacy logo glyphs — 2026-11-05

SYS-065 follow-up. User confirmed the font deployment but fastfetch's small
NixOS logo still had missing characters. JetBrains Mono lacks its eight distinct
U+1FBxx legacy-computing shapes. Added a 2,892-byte WOFF2 subset of Unifont Upper,
preloaded only for that Unicode range; ordinary text and Nerd icons keep their
existing font. Fixed ttyd's JSON parsing of the leading quoted font-family,
which silently discarded the fallback list. FontTools' Unicode-range pruning
fails on reserved bits in this Unifont source; disabled pruning for the subset.

Flake check and full build passed. Chromium verified five font downloads, all eight glyphs
rendered by the downloaded fallback (CDP), the actual terminal canvas using the
complete fallback list, eza icons and no browser errors. Fixed-logo screenshot
`/tmp/ttyd-font-browser/fastfetch-fixed.png` visually inspected (no missing boxes).
Live/selected generation 263 before activation:
`/nix/store/0lykybvg965qq3icy844f79ylim2hsbv-nixos-system-erebor-26.05.20261029.6f06d20`.
Target: `/nix/store/ajdns1k3kjlmhnv50mykwcnsvxmp8y34-nixos-system-erebor-26.05.20261029.6f06d20`.
Root/ESP/btrfs-top UUIDs verified, no failed units; caddy and ttyd active.
After earlier authentication timeouts, user-requested Touch ID retry succeeded
through the refreshed agent socket. Helper created and verified readonly snapshot
`/btrfs-top/nixos-root-pre-ttyd-logo-20261105` (Snapper absent), test-activated,
verified live page/protected fonts, then persistently switched to generation 264.
Live/selected profile both match the target above; caddy/ttyd active, no failed
system/user units. Verified deployed fallback list, range-specific face, Caddy
asset path and WOFF2 signature; unauthenticated HTTPS font request returns 401.
Root/ESP UUIDs and Windows EFI entries/firmware boot order remain unchanged.
Real authenticated user-browser appearance after activation is not observed;
the exact built assets were browser-tested as above. No reboot performed;
unrelated host source edit remains untouched. Generation 263 remains recovery.
Activation helper is now superseded and must not be replayed.

## [COMPLETED] ttyd bundled Nerd Fonts — 2026-11-05

SYS-065. User requested web-served fonts for eza icons. Generate ttyd's custom
index from its packaged HTML, add @font-face rules and wait for regular/bold/
italic/bold-italic JetBrains Mono Nerd Font Mono WOFF2 files before startup.
Caddy serves /fonts under the existing password, tailnet and origin gates.
No ttyd source/executable patch or per-device font install.

Flake check and full system build passed. Isolated Chromium verified all four
font requests return 200, loaded font faces, selected xterm font, eza icon
output and no page errors; screenshot /tmp/ttyd-font-browser/eza.png inspected.
Live/selected generation 262 before activation:
`/nix/store/rwr7pf2nwb92dv0wzdycav1clhq8k4f4-nixos-system-erebor-26.05.20261029.6f06d20`.
Target: `/nix/store/0lykybvg965qq3icy844f79ylim2hsbv-nixos-system-erebor-26.05.20261029.6f06d20`.
Root/ESP UUIDs and Windows EFI directory/entries verified; no failed units.
The pre-existing uncommitted t3code ConditionUser change is already live;
its service path matches the build and its source edit will remain untouched.
Built Caddy routes also verified all four WOFF2 signatures and font/woff2 MIME,
unauthenticated 401, foreign origin 403, and missing font 404 with fixture auth.
Initial agent activation was blocked at sudo. Later user activation verified
live/selected generation 263 at the target above, active caddy/ttyd and the
user's reloaded browser. Legacy-computing logo glyphs are the SYS-065 follow-up
above. The generation-262 activation helper is superseded; do not replay it.
No reboot performed.

## [COMPLETED] Mac approval timeout — 2026-11-05

SYS-064: activated and persisted a 30-second Mac approval timeout for sudo and Polkit. Flake check, dry-build and build passed. Test activation verified successful sudo Touch ID and the password prompt after an unanswered request. Live and selected system match; no failed units. Password entry and desktop Polkit behavior remain untested (SYS-064). The switch also activated previously configured ttyd; GRUB was updated by nixos-rebuild. Previous system: /nix/store/c2cpk55chl58br224w0bx4xy5s00nk4v-nixos-system-erebor-26.05.20261029.6f06d20.

## [COMPLETED] Claude CLI latest auto-update channel — 2026-11-05

User requested the most recent Claude CLI and automatic future updates.
Installed Anthropic's native user CLI using the official installer with
`latest`; user settings select `autoUpdatesChannel = latest`. Existing
nix-ld supports the upstream binary, and ~/.local/bin precedes the Nix
profile in PATH. The declarative Nix package remains as an inactive fallback;
it does not control the native CLI's updates.

Verified upstream latest release and local version 2.1.318, including a fresh
fish login shell. `claude doctor` reports native installation, auto-updates
enabled, latest channel, working bundled search, and no installation issues.
Updates install in the background and take effect on the next launch;
future update delivery has not yet been observed. Authentication remains for
the user. No Nix configuration, system generation or services changed; no
system rebuild or administrator approval was needed.

## [PREPARED] Browser terminal and hub card — 2026-11-05

SYS-063. User requested ttyd on terminal.erebor.jzon.pl and a hub card.
Loopback backend runs the user's login fish shell as janzon; Caddy shares
the existing desktop runtime password gate, tailnet restriction and origin
checks. DNS resolves to 100.108.216.80. The existing gate returns 503 until
the user sets a password (SYS-058); no credentials changed.

Flake check and full build passed. Before activation: live/selected generation
261, `/nix/store/c2cpk55chl58br224w0bx4xy5s00nk4v-nixos-system-erebor-26.05.20261029.6f06d20`.
Root UUID 5be9be17-20c9-4a47-ba2d-6adf1ceb4c55 and ESP UUID 38B5-8386
confirmed mounted at / and /boot; Windows EFI entries remain present.
No failed system units; user xdg-desktop-portal-gtk.service already failed.
Activation did not start: sudo requires a password; pkexec without a TTY has
no authentication agent and its TTY attempt requested a password (cancelled).
Live/selected generation remains 261. No system configuration was activated.

An isolated transient ttyd process and the built Caddy terminal snippet verified
HTTP 200, missing/wrong fixture credentials 401, valid fixture credentials 200,
foreign origin 403, and an authenticated WebSocket executing a fish command as
janzon. Test services were stopped; the real runtime auth file was untouched.
Built dashboard config contains the exact terminal URL. No live hub/card or
terminal HTTPS activation verification is claimed.

Prepared `/tmp/activate-browser-terminal.sh` (bash syntax checked) for the user:
it checks the unchanged generation and filesystem UUIDs, creates/verifies a
readonly recovery snapshot, test-activates the already built closure, checks
service/HTTP/gate/hub configuration, then persists and verifies the profile.
Target: `/nix/store/4672i2lxb56rw2f9xm0v6n1s4a660vl7-nixos-system-erebor-26.05.20261029.6f06d20`.
Next: run `sudo bash /tmp/activate-browser-terminal.sh`, then
`sudo desktop-password` locally; verify real login and update SYS-063/SYS-058.
Snapshot has not yet been created; Snapper is absent.
Recovery: restore generation 261 using its switch-to-configuration and system
profile if needed. Risks: brief Caddy reload; terminal stays locked until
local password setup. No reboot performed.

## [COMPLETED] plasma-disks and vicinae fixes — 2026-11-04

Requested by the user. Added `kdePackages.plasma-disks` and `kdePackages.kded`
so kinfocenter's Storage Device Health page works under Niri: kded6 is started
on demand over D-Bus and loads the `smart` module.

Fixed two vicinae startup errors:
- Imported `vicinae.nixosModules.default`, which creates the
  `/run/wrappers/bin/vicinae-input-server` capability wrapper that the package
  expects. Without it, the input server (paste and snippets) failed with `execve`
  ENOENT.
- Added the system and user profiles to `xdg-desktop-portal`'s PATH. Its host
  app registry could not resolve `Exec=vicinae` and rejected the app ID with
  "App info not found".

`nix flake check` and `nixos-rebuild build` passed; activated with
`pkexec nixos-rebuild switch` as generation 261. After restarting the portal and
vicinae, the input server is running with no errors in the log. kded6 exposes
SMART data for nvme0n1, sda, sdb and sdc, all reporting `failed=false`.
Seeing the page in the kinfocenter GUI is not yet confirmed by the user.
No reboot.

## [COMPLETED] smartd disk monitoring — 2026-11-04

Enabled `services.smartd` with default notifications (wall), at the user's
request. `nix flake check` and `nixos-rebuild build` passed; activated with
`pkexec nixos-rebuild switch` as generation 260. `smartd.service` is active and
monitors 3 ATA/SATA disks and 1 NVMe disk with no startup warnings. The USB
"Expansion SW" disk (`sdd`) is skipped because its bridge does not pass through
SMART. No failed system or user units. No reboot.

## [COMPLETED] kinfocenter and smartmontools — 2026-11-04

Added `kdePackages.kinfocenter` (6.6.6) and `smartmontools` (7.5) to the erebor
system packages, at the user's request. `nix flake check` and `nixos-rebuild build`
passed; activated with `pkexec nixos-rebuild switch` as generation 259. Both
`kinfocenter` and `smartctl` resolve under `/run/current-system/sw/bin`; no failed
system or user units. The `smartd` daemon was not enabled. No reboot.

## [COMPLETED] Claude Code CLI — 2026-11-04

Added `claude-code` to the Home Manager packages and the unfree allow-list
(`ebb1e67`), at the user's request. Builds had been failing because the dashboard
submodule pointed at commits not on GitHub; the user approved pushing them
(`6225bab..cad8818`). `nix flake check` and `nixos-rebuild build` passed; activated
with `pkexec nixos-rebuild switch` as generation 258 (the same generation recorded
in the hub fix entry below). `claude --version` reports `2.1.223 (Claude Code)`;
no failed system or user units. No reboot.

## [COMPLETED] Hub display power command fix — 2026-11-04

SYS-062. Fixed obsolete Umbriel `dpms-off:OUTPUT` / `dpms-on:OUTPUT`
commands to pass the output as a separate argument. Dashboard flake check,
all 35 API tests, system flake check, dry-build and full build passed.
Dashboard fix committed as `35f526b`. Initial isolated test activation
succeeded; the initial persistent attempts failed on a NIX_PATH re-exec
lookup and then dismissed administrator authentication.

On retry, live inspection found a subsequent persistent activation already
included the fix in generation 258:
`/nix/store/3cg44yxvgzcqvj848vd3av7cpsm4blhx-nixos-system-erebor-26.05.20261029.6f06d20`.
Live and selected system paths match. Verified the running service's packaged
code passes the output separately; display-on POST through Caddy returned
HTTP 200 and `Command sent`. Caddy/control active, no failed system/user
units. Root/ESP UUIDs and EFI boot order match prechecks. No further activation
or reboot was needed on retry. Unrelated working-tree edits remain untouched.
Physical display off/wake remains untested under separate SYS-002.


This file records dated changes and their evidence. Current unfinished work lives
in [SYSTEM_TODO.md](tasks/README.md); recovery knowledge lives in
[SYSTEM_CONTEXT.md](SYSTEM_CONTEXT.md). Nix files define intended configuration.

**Reading historical records:** versions, generations, permissions, recovery paths,
and “next action” commands describe their recorded date. Recheck live state before
acting. A historical checkpoint is not an instruction or fresh authorization.
`[COMPLETED]` means the stated change was implemented and verified to the scope
recorded; explicit limitations still apply. `[RECORDED]` preserves an older attempt
whose final outcome is uncertain; its linked task holds the current disposition.
New active operations use `[PENDING]` only while work is actually in progress.

## [COMPLETED] Google Chrome — 2026-11-04

At the user's request, added `google-chrome` to system packages and to the
unfree allowlist, launched with `--password-store=gnome-libsecret` so it uses
the Oo7 Secret Service like Helium.

Validation: `nix flake check` and `nixos-rebuild build` passed; switched (via
`pkexec`) to generation 257 (`f1zfmgr7…-nixos-system-erebor-26.05.20261029.6f06d20`).
`google-chrome-stable --version` reports 156.0.8078.73 and no system units
failed. After restarting Vicinae, the user confirmed Chrome appears in the
launcher; sign-in was not checked.

## [COMPLETED] Plasma System Monitor — 2026-11-04

At the user's request, added `kdePackages.plasma-systemmonitor` and its sensor
daemon `kdePackages.ksystemstats` (D-Bus activated, needed outside Plasma) to
system packages.

Validation: `nix flake check` and `nixos-rebuild build` passed; switched (via
`pkexec`) to generation 256 (`ppyzvygn…-nixos-system-erebor-26.05.20261029.6f06d20`).
Both binaries are on PATH and no system units failed. The app's UI was not
checked by the user.

## [COMPLETED] Noctalia config validation warnings — 2026-11-04

`noctalia config validate` (Noctalia v5.4.1) reported 9 warnings on
`home/noctalia/config.toml`. Replaced the renamed palette role
`surface_variant` with `surface_container` (bar border, capsule group fills,
lockscreen login box) and dropped the unknown key
`shell.screen_corners.telemetry_enabled` (`shell.telemetry_enabled` stays true).
The remaining warning for `question44/spotify-media-niri:bar` is a false positive
of path-mode validation: `noctalia msg plugins list` shows that plugin installed
and enabled.

Validation: config validates with 1 warning; `nix flake check` and
`nixos-rebuild build` passed; switched (via `pkexec`) to generation 255
(`vwf4018f…-nixos-system-erebor-26.05.20261029.6f06d20`). The deployed config
matches the repository, the running shell's exported config has no
`surface_variant`, and no system units failed. The visual appearance was not
checked by the user.

## [COMPLETED] Wallpaper Engine animated wallpaper plugin — 2026-11-04

At the user's request, added a local Noctalia plugin `janzon/wallpaper-engine`
(`home/noctalia/plugins/wallpaper-engine/`, deployed to
`~/.local/share/noctalia/plugins/`) that plays Wallpaper Engine Workshop scenes
and videos with `linux-wallpaperengine` (added to system packages). A service
runs the renderer as the transient user unit `noctalia-wallpaper-engine` and
disables Noctalia's wallpaper on the outputs it covers; a picker panel, bar
widget and control-center shortcut select items. Wallpaper Engine itself is
installed in Steam (Proton) for its assets; web wallpapers and presets are not
listed because linux-wallpaperengine cannot render them.

Before this, the Btrfs filesystem had no unallocated space and writes failed
with ENOSPC; the user ran `nix-collect-garbage --delete-older-than 14d` (root
and user), leaving 42 GiB unallocated and metadata at 77%.

Flake check and build passed; a first `test` activation was overwritten by
another session's switch, then re-run once that work was committed. Switched via
pkexec to generation 254. Plugin enabled (the live config reload raced the new
plugin directory, so it was enabled once with `noctalia msg plugins enable`).
Applying item 2925330428 through the service IPC started the unit on DP-1 and
HDMI-A-1, Noctalia logged both as externally managed, and the user confirmed the
animated wallpaper looks correct with HDR on. Not tested: the picker panel UI,
the "Match Theme Colors" option, pause/stop, and startup on the next login.
The Niri-only `niri-overview-wallpaper` swaybg still runs under Umbriel on DP-1
below the scene ([SYS-089](tasks/SYS-089.md)). No reboot.

## [COMPLETED] Umbriel action arguments in rcmd and helpers — 2026-11-04

The current Umbriel rejects `action:argument` messages ("unknown action") and
takes arguments as separate words. rcmd therefore failed at its focus step, so
an app chosen in vicinae launched but was never focused, and cycling running
windows failed too. Switched to the word form in `home/rcmd/rcmd.py`,
`home/umbriel/focus-or-launch`, `home/umbriel/scratchpad-navigate` and
`home/sunshine/output.sh` (`window-move-to-workspace-silent --name … --output …`).

Flake check and build passed; switch via pkexec to generation 253, built from
HEAD plus only these files (uncommitted wallpaper-engine work excluded). No
failed units; xremap active. Verified deployed scripts use the new form and
live `rcmd g`/`rcmd c` focused Ghostty/Claude. Not tested: the vicinae
chooser-then-launch path, scratchpad navigation and Sunshine output removal.
No reboot.

## [COMPLETED] Removed the wallpaper-only `ambilight` virtual output — 2026-11-04

At the user's request, Ambilight now follows DP-1's content ([SYS-005](tasks/SYS-005.md)).
Removed `[output.ambilight]` and the `umbriel-ambilight-session` wrapper
(`33bfbf3`); Umbriel now autostarts `noctalia` directly. Umbriel validation,
flake check and build passed; test-activated, not switched, because another
session had unfinished wallpaper-engine edits in the tree. Destroyed the live
output; DP-1 and HDMI-A-1 remain. After a HyperHDR restart it streamed 21:9
frames (DP-1) with no picker. Not verified: LEDs following on-screen content,
and the next login's autostart. Stale `ambilight` wallpaper and lockscreen
entries remain in Noctalia's UI state (`~/.local/state/noctalia/settings.toml`).

## [COMPLETED] Shared application background opacity — 2026-11-04

Added `home/appearance.nix` with `appOpacity = 0.9` as the shared setting for
Ghostty and both Noctalia transparent Zed/Gram variants. Home Manager validates
the range, rounds to an 8-bit alpha and substitutes that alpha into the Zed
template and the equivalent decimal into Ghostty. Noctalia's dynamic palette
placeholders remain intact. Existing Umbriel blur settings are unchanged.

Flake check and build passed; test activation and switch succeeded, generation
252. Reloaded Noctalia and Ghostty and reapplied templates. Verified Ghostty's
parsed opacity equals the generated alpha on all six main background surfaces
in each transparent theme; no unresolved substitution tokens. Noctalia,
Umbriel and dashboard-control remained active; no failed system units. Visual
appearance was not independently inspected. Future changes use a NixOS rebuild
and Noctalia template application/Ghostty reload. No reboot.

## [COMPLETED] One-at-a-time screen switch (DP-1 / HDMI-A-1) — 2026-11-04

At the user's request: added `umbriel-display-mode dp|hdmi|toggle|status`
(`packages/umbriel-display-mode.nix`), which keeps only one physical Umbriel
output enabled. It enables the target before disabling the other and stops if
the target is missing. It is a Noctalia bar button (`display-switch`,
left-click toggles) and backs new hub actions `screen-dp` / `screen-hdmi`
(dashboard `cad8818`). The hub reports the active screen, and display power
and DPMS now ignore the switched-away output. Virtual outputs are untouched.

Live checks first: Umbriel `output-disable`/`output-enable` of HDMI-A-1
restores its position and survives `config-replace`. Dashboard tests (35),
flake check and build passed. Test activation, then switch, to generation 251.
No failed units; `dashboard-control` active. Hub `screen-dp` POST disabled
HDMI-A-1 and status read `dp`. The served hub has the new actions, and Noctalia
loaded the widget. Not tested: clicking the bar button, and switching to HDMI
(which turns DP-1 off). Runtime state resets at login (both outputs enabled).
No reboot.

## [COMPLETED] Dolphin thumbnailers for all available formats — 2026-11-04

At the user's request: added `ffmpegthumbs` (video), `kdegraphics-thumbnailers`
(PDF/PS/DVI/EPS, RAW, Blender, mobi), `kdesdk-thumbnailers` (gettext `.po`) and
`qtsvg` to Home Manager packages, plus `unrar` (allowlisted unfree) and
`djvulibre` because kio-extras' comic and DjVu thumbnailers execute them. Dolphin
already bundles kio-extras; a Home Manager activation now writes all 22
installed plugin IDs to `dolphinrc` `[PreviewSettings] Plugins`. Not included:
font thumbnails (plasma-workspace) and Calligra.

The first build hit Btrfs metadata ENOSPC; the user ran a data balance first
([SYS-008](tasks/SYS-008.md)). Built from a clean worktree of HEAD plus only
this change so unrelated uncommitted work was not activated; the closure diff
showed only the new packages and Home Manager files. Flake check and build
passed; pkexec test then switch succeeded, generation 250 (GRUB default). No
failed system or user units. Dolphin generated cached thumbnails for MP4 (real
frame), SVG, PDF and PostScript test files in a home folder (test files and
thumbnails removed). The `.po` thumbnail was not observed: the plugin opts out of
the disk cache and the screen was not inspected. No reboot.

## [COMPLETED] Remove leftover Fedora firmware entry and Btrfs label — 2026-11-04

User requested removing firmware entry Boot0009 "Fedora"
(`\EFI\fedora\shimx64.efi` on the Windows ESP, PARTUUID
`8c2ce2ef-72ab-4bc5-bcab-b66ae52987fe`) and renaming root Btrfs UUID
`5be9be17-20c9-4a47-ba2d-6adf1ceb4c55` from label `fedora-unencrypted` to
`erebor`. Live generation 249; BootCurrent 0000 (NixOS-boot); BootOrder
0000,0004,0007,0008,0009,000A,000B,000C. No fstab/GRUB use of the label.
No snapshot (no filesystem data changes). Recovery: recreate the entry with
`efibootmgr -c -d <disk holding that PARTUUID> -p 1 -L Fedora -l
'\EFI\fedora\shimx64.efi'`; restore label with `btrfs
filesystem label`.

Ran `efibootmgr -b 0009 -B` and `btrfs filesystem label / erebor` via pkexec,
both exit 0. Before/after `efibootmgr -v` diff shows only Boot0009 removed;
BootCurrent 0000 and the remaining order are unchanged. Label reads `erebor`;
root, `/nix/store`, `/btrfs-top` and ESP `/boot` stay mounted; no failed
system or user units. The udev `by-label/fedora-unencrypted` link persists
until the next boot (unused). `\EFI\fedora` files on the Windows ESP were not
inspected or removed. No reboot.

## [COMPLETED] Re-enable HyperHDR LEDs at startup — 2026-11-04

Ambilight stayed dark after login: HyperHDR's non-declarative `general`
setting `disableLedsStartup` had been set to `true` (database timestamp
2026-10-24T23:27Z, no matching record), so each start disabled the whole
instance (`ALL`). The dashboard On action only enables `LEDDEVICE`, so it could
not recover this state. Backed up the database to
`~/.hyperhdr/backups/hyperhdr-before-leds-startup-enable-20261104.db`, then
with the user service stopped set `disableLedsStartup` to `false` (JSON
`setconfig` requires admin authorization) and started the service. Verified
`ALL`, `SYSTEMGRABBER` and `LEDDEVICE` enabled with the system grabber active
at priority 245, and WLED on with `lor` 0 and live UDP from 192.168.1.106. No
Nix configuration change or rebuild. Lights were not visually confirmed.

Recording this initially failed with ENOSPC: the root Btrfs filesystem had no
unallocated space (data chunks 374.58 GiB holding 281.8 GiB; metadata 7.49 of
8 GiB DUP). With user approval ran `btrfs balance start -dusage=10 /` via
pkexec (44 of 389 chunks relocated, exit 0). Afterwards: 43 GiB unallocated,
data 330.58 GiB total, metadata 8.50 GiB total / 7.48 GiB used; this write
succeeded. No snapshot was taken first (balance only relocates chunks).

## [COMPLETED] Umbriel blur radius increased to 5 — 2026-11-04

Changed `appearance.blur.radius` from 3 to 5 in the declarative Umbriel
configuration. Umbriel validation, flake check and NixOS build passed; test
activation and switch succeeded, generation 249. Verified the deployed radius
is 5 and reloaded the running compositor; its journal confirmed the appearance
change applied to scene blur, view chrome and layer effects. Umbriel remained
active and there were no failed system units. Visual strength was not
independently inspected. No logout or reboot.

## [COMPLETED] Zed background opacity at 90% with dynamic Noctalia colors — 2026-11-04

Added a Home Manager managed custom Noctalia Zed template, preserving all
community color placeholders and changing only the six background alpha values
in each transparent variant from B6 to E6 (about 90%). Replaced the community
Zed selection with the custom template; existing Zed and Gram output paths stay
in place, so palette changes continue generating colors without resetting alpha.

Noctalia config validation, flake check, dry build and build passed. Test
activation and switch succeeded, generation 248. Reloaded Noctalia and applied
templates; verified all six surfaces in both generated transparent variants have
E6 alpha and no unresolved placeholders. Home Manager and Noctalia are active;
no failed system units. Visual appearance inside Zed was not independently
inspected. No reboot.

## [COMPLETED] Qt image decoders for Dolphin WebP thumbnails — 2026-11-03

At the user's request: added `kdePackages.qtimageformats` (WebP, TIFF, TGA,
ICNS, JP2) and `kdePackages.kimageformats` (AVIF, HEIF, JXL, PSD, XCF, EXR, ...)
to Home Manager packages. Dolphin's wrapper bundles kio-extras' image
thumbnailer but only qtbase's decoders; the session's `QT_PLUGIN_PATH` covers
the per-user profile only, so the decoders belong there, not in systemPackages.
Flake check and build passed; pkexec test then switch succeeded, generation
247. Verified `libqwebp.so` and `kimg_*` in the per-user Qt plugin path and
that Dolphin generated a 128×128 thumbnail for a WebP test image in a home
folder (test file and thumbnail removed). KIO does not cache thumbnails for
files under /tmp, so that location gave no result. No reboot.

## [COMPLETED] SSH TOTP second factor and LAN/tailnet-only port 22 — 2026-11-03

At the user's request: SSH now accepts a key alone, or keyboard-interactive PAM
requiring a Unix password plus a Google Authenticator TOTP code
(`AuthenticationMethods publickey keyboard-interactive`, plain
`PasswordAuthentication` off). The openssh module ties `unixAuth` to
`PasswordAuthentication`, which left sshd's auth stack as `pam_deny` only and
omitted the TOTP rule; `unixAuth` is forced on so the built stack is
unix-early → google_authenticator (required, no nullok) → unix → deny.
`services.openssh.openFirewall` defaulted to a global port 22 accept;
disabled, and 22 is now allowed only on `br0` and `tailscale0`.
`google-authenticator` installed system-wide.

Flake check and build passed; pkexec test then switch succeeded, generation
246. Verified: generated firewall accepts dport 22 only on br0/tailscale0;
live sshd_config has the methods above; sshd offers
`publickey,keyboard-interactive`; sshd and firewall active, no failed units.
Limits: `~/.google_authenticator` not yet provisioned, so password+TOTP login
is refused until janzon runs `google-authenticator`; an end-to-end password+code
login and a remote key login were not tested.

## [COMPLETED] Remove Mango, rename flake target to erebor, review fixes — 2026-11-03

At the user's request: removed MangoWM (flake input, NixOS/HM modules, patched
package, session entry, `home/mango/`, Mango branches in Sunshine, rcmd,
noctalia-bar-focus); removed every `moria` name from configuration and current
docs — flake target is now `#erebor`, `hosts/moria` → `hosts/erebor`, and
`*.moria.jzon.pl`/`moria` host aliases are no longer served (dated history and the
dashboard submodule's test fixtures unchanged). Review fixes: NVIDIA open kernel
modules and power management (VRAM preserved across suspend); T3 Code LAN
listener `:8080` and its br0 port removed (Tailscale `code.*` only); weekly
`nix.gc` (30 days), `auto-optimise-store`, GRUB `configurationLimit = 15`;
dropped duplicate `nodejs`/`jq` HM packages and default `wheelNeedsPassword`;
HM activation uses `run` and Starship merge skips dry runs; `.gitignore` covers
`result` and `__pycache__`. `programs.nix-ld` kept: the `t3` CLI needs it.

Prechecks: live generation 244, booted 244, kernel 6.18.59, no failed units, no
Mango session running (current session Umbriel). `nix flake check` and
`nixos-rebuild build/dry-build --flake path:/etc/nixos#erebor` passed.
Recovery: GRUB keeps prior generations (now ≤15 entries) and the systemd-boot
recovery chainload; generation 244 boots the proprietary NVIDIA module.
Outcome: pkexec test reported exit 4 only from Jellyfin's transient podman
healthcheck while the container restarted (new published URL); Jellyfin then
returned 200 and the unit cleared. Pkexec switch succeeded as generation 245.
Verified: no failed system/user units; Caddy, Jellyfin, Nextcloud, Syncthing,
qBittorrent, Ollama, Open WebUI and t3code active; `erebor.jzon.pl` 200,
`moria.jzon.pl` and `:8080` no longer served; GRUB lists 15 NixOS
configurations plus Windows and systemd-boot recovery; firmware BootOrder
unchanged; `/boot` 75% → 24%; `nix-gc.timer` scheduled; closure contains
`nvidia-open-615.78.08`. Also removed the imperative `mango` user-profile
install (`nix profile`); `~/.config/mango/monitors.conf` left in place.
Limits: no reboot performed. Open NVIDIA modules, suspend/resume and the
`erebor` login banner are untested until the next boot. Old `moria`
trusted domain may remain in Nextcloud's live `config.php`.

## [COMPLETED] Noctalia Chromium-based theme for Helium — 2026-11-03

Enabled community template `chromium-based`, replacing the old Brave selections
as recommended upstream. Declared the mutable Chromium policy file through
systemd tmpfiles (`f`, owned by janzon) so rebuilds preserve the rendered color.
Noctalia config validation passed with nine existing warnings; flake checks and
system build passed. Pkexec test and switch succeeded, generation 244.
Reloaded Noctalia and applied templates: detected Helium's policy directory,
rendered `BrowserThemeColor` as `#181216`, and refresh hook returned success.
Installed Helium binary contains `/etc/chromium/policies` and BrowserThemeColor.
Policy survived switch; Home Manager active, no failed system units. Actual
browser toolbar appearance is not visually verified; `helium://policy` supports
manual policy reload if needed. Existing GTK4 and Neovim template warnings are
unrelated. No reboot.

## [COMPLETED] Uninstall ungoogled Chromium — 2026-11-03

Removed the system package and its Secret Service wrapper at the user's explicit
request, superseding the Chromium preservation preference in AGENTS.md.
`nix flake check path:/etc/nixos` and `nixos-rebuild build --flake
path:/etc/nixos#moria --no-link` passed. Pkexec test and switch activation
succeeded; persisted as generation 243. Chromium commands and desktop launcher
are absent from the active system; Home Manager active, no failed system units.
Helium remains the default browser. Browser profiles and saved data preserved.
No reboot.

## [COMPLETED] AWS CLI v2 and AWS SAM CLI — 2026-11-03

SYS-061. Added nixpkgs `awscli2` and `aws-sam-cli` to system packages beside
other developer CLIs, for the user's serverless (AWS SAM) project.
`nix flake check path:/etc/nixos` and `nixos-rebuild build --flake
path:/etc/nixos#moria` passed. Pkexec test then switch activation succeeded,
persisted as generation 242; Home Manager active, no failed system units.
A fresh fish login shell resolves both from `/run/current-system/sw/bin` and
reported aws-cli/2.34.24 and SAM CLI 1.160.0. No AWS credentials or profiles
configured (user scope); `sam` features needing Docker remain untested. No reboot.

## [COMPLETED] Claude Secret Service backend — 2026-11-03

Added `--password-store=gnome-libsecret` declaratively to Claude's package
wrapper, covering CLI and desktop actions. Flake checks and system build passed;
pkexec test and switch activation passed, persisted as generation 241.
Home Manager active, no failed system units. Restarted Claude: live process
arguments include the flag and Umbriel confirms a visible native Wayland window.
Oo7 owns org.freedesktop.secrets (verified daemon process); actual credential
round-trip and sign-in remain untested. Old Claude needed systemd's 90-second
stop timeout before the queued restart completed. Existing mimeapps.list
read-only warning persists without preventing launch. No reboot.

## [COMPLETED] Claude Desktop installation — 2026-11-03

SYS-060. Added the requested tomsch/claude-desktop-nix flake input and
Home Manager package, pinned at b94e2b0. Existing input revisions preserved.
`nix flake check path:/etc/nixos` and `nixos-rebuild build --flake
path:/etc/nixos#moria` passed. Built Claude Desktop 4.4212.0 and launched
it directly: active process and visible native Wayland Claude window verified
through Umbriel IPC. Sign-in and application features remain untested.
Electron logged a failed attempt to update the store-backed mimeapps.list;
the window still opened.

Pkexec test activation succeeded on 2026-11-03. Home Manager is active;
installed command and desktop entry verified, with no failed system units.
Current live system is `/nix/store/81zs30l3laqvb67lwbiw2qa6m0dqyi7w-nixos-system-erebor-26.05.20261029.6f06d20`.
Persistent switch through pkexec succeeded as generation 240. Home Manager
remains active, no failed system units, and Claude's native Wayland window is
still visible. The first store-path switch attempt failed before activation
because nixos-rebuild tried legacy configuration lookup; the explicit-flake
retry succeeded. Pre-existing failed Noctalia user unit left untouched.
Sign-in and application features remain user acceptance checks. No reboot.

## [COMPLETED] Umbriel keybinding syntax repair — 2026-11-02

Migrated parameterized keybinding actions from colon to space syntax required by
installed Umbriel revision a37ae93. Restored Caps+A/D as native left/right focus
actions. Configuration validation reports zero diagnostics (previously 68
warnings); loaded live using `umbriel config-replace`. Direct focus IPC verified.
Physical shortcut confirmation remains with the user. Source configuration is
active live; Home Manager deployment remains pending sudo authentication, so
the deployed store symlink still contains the old syntax until rebuild activation.

## [COMPLETED] Five-second outlet refresh — 2026-11-02

Outlet telemetry now has its own five-second frontend timer; other hub checks
retain their existing cadence. NanoKVM cache expires four seconds after query
start, so it does not stretch five-second polling into repeated cached readings.
Helper redeployed and restarted; source submodule commit `54d8bf2`.

Package/root flake checks, all 22 helper tests, NixOS dry-build and build passed.
Test activation verified in the actual hub browser: five requests with four
consecutive intervals of exactly 5 s and valid live readings. Persistently
activated generation 238; no failed system units. Prechecks: generation 237,
root/ESP mounts and failed units checked. No reboot or outlet switching.
Builds used `path:/etc/nixos` to include the local submodule revision without
requiring it to be published remotely. Recovery: generation 237 and NanoKVM
`/opt/erebor-wake/wake.py.before-five-second`.

## [COMPLETED] NanoKVM outlet hub integration — 2026-11-02

SYS-059. NanoKVM helper now serves owner-authenticated `/outlet` telemetry,
enabled in its private config. Live HTTPS/origin/no-store checks pass; credentials
stay on NanoKVM. Prior helper/config backed up as
`/opt/erebor-wake/*.before-outlet-20261102`. Read-only panel built with ten-second
visible-page refresh, unavailable states, and watts/day/month kWh conversion.
22 helper tests, submodule/root flake checks and NixOS dry-build pass.

Test activation and browser verification passed, then persistently switched to
generation 237. Caddy active, no failed system units. The actual hub displayed
fresh NanoKVM watts/day/month readings, refreshed repeatedly, and fit a 390 px
viewport without overflow. A browser-only simulated HTTP failure removed old
readings and showed unavailable; restoring transport restored live readings.
Unauthenticated live NanoKVM requests return 403. Helper changes committed in
dashboard submodule `0b14cf4`. Root/ESP mounts checked before activation; no reboot
or physical outlet/ATX operation performed. Readings while physically asleep were
not exercised; the browser endpoint is independent of the desktop host.
Recovery: generation 236; restore NanoKVM helper/config backups and restart it.

## [COMPLETED] Query the Tapo outlet directly from NanoKVM — 2026-11-02

Installed a standalone read-only `tapo-query` on NanoKVM `kvm-37ff`
(`192.168.1.122`), querying P110M `192.168.1.100` directly over LAN with TPAP.
Source and locked Nix/Rust packaging are in `/home/janzon/Projects/tapo-query`,
commit `cd2b4d1`; its README documents rebuild/deployment. Binary resides in
`/opt/tapo-query`, linked at `/usr/bin/tapo-query`. Existing desktop keyring
credentials were transferred privately over SSH to root-owned
`/etc/tapo-query/credentials.json` (0600, directory 0700), outside source and
the Nix store. NanoKVM stores this file as plaintext protected by permissions.

Verified two authenticated NanoKVM readings (outlet on, about 90 W), CLI help,
credential permissions and rejection of an unsafe permissions fixture. A reading
took 0.85 s with 6940 KiB peak RSS. Nix flake checks and the cross-build passed;
the binary has no dynamic loader. Binary SHA256:
`46d1c572986f7e4cb8b6e34f575ad6afc68a494df84a6f4f7924306c605d284f`.
The first build required a Nix loader; static linkage corrected that before
successful verification. No NixOS activation, reboot or NanoKVM service change.
The existing wake helper remains separate. Normal reboot persistence follows
the installed filesystem layout; no reboot was performed. Firmware recovery
may require redeployment. Removal: delete the command/link and its dedicated
credentials file/directory on NanoKVM.

## [PREPARED] Desktop password protection — 2026-11-02

SYS-058. Password gate and local setup helper activated persistently as
 generation 236. Runtime credentials live under root-owned `/var/lib/desktop-auth`,
outside the repository/Nix store. Before setup, desktop returns 503; LAN returns
403. No failed system/user units; backend/Caddy active. Recovery snapshots
`/btrfs-top/nixos-root-pre-desktop-password-20261102` and generation 235 retained.

The first helper failed before saving because Caddy stdin requires a newline.
Corrected helper adds it, handles hashing failures without traceback, and checks
HTTPS login before reporting success (restoring prior config on failure).
Flake check, dry/full build and Python syntax passed. Isolated auth integration:
missing/wrong credentials 401, correct fixture 200. Prepared closure:
`/nix/store/lk2pv5dxfq5lphrar1gxfyryb0b2r9km-nixos-system-erebor-26.05.20261029.6f06d20`.
Corrected helper activation did not start because sudo authentication remained
pending; cancelled that wait. Current persistent/live generation remains 236,
with desktop locked (503). Local GUI setup was inaccessible; user must finish
from their own terminal. `/tmp/desktop-password-fix-activate.sh` is prepared for
test, gate verification, readonly snapshot and persistent switch; then run
`sudo desktop-password`. Real password entry/login acceptance remain pending.
No reboot; no password/hash was included in chat, repository or Nix store.

## [COMPLETED] Desktop service index entry — 2026-11-02

SYS-057. Added Desktop to the dashboard, linking to desktop.erebor.jzon.pl.
Flake check, dry/full build, test and persistent switch passed as generation 235.
Browser verified the card label, description and exact target. No failed
system/user units after activation. Readonly snapshot
`/btrfs-top/nixos-root-pre-desktop-index-20261102` verified ro=true; generation
234 retained. No reboot. Password protection was discussed as a capability;
no credentials were requested or configured, and tailnet restrictions remain.

## [COMPLETED] Desktop browser subdomain — 2026-11-02

SYS-056. Browser control now uses `https://desktop.erebor.jzon.pl/`, matching
the other service subdomains. Root redirects to noVNC with automatic connection
and scaling; the old dashboard `/desktop/` entry redirects to the new host.
Tailnet-only access, same-origin WebSockets and localhost backend retained.

Flake check, dry/full build, Caddy parsing, test and persistent switch passed.
Activated generation 234; browser connected with a live 3440x1440 framebuffer.
Old path returns 308, LAN and foreign Origin return 403. After switch, Caddy
and browser-desktop active; no failed system/user units. Readonly recovery
snapshot `/btrfs-top/nixos-root-pre-desktop-subdomain-20261102` verified ro=true;
generation 233 retained. No reboot.

## [COMPLETED] Browser control of the current Noctalia desktop — 2026-11-02

SYS-055. Activated persistently as generation 233:
`/nix/store/mqxcg18swj1f1gf60vac7blija1cdnvd-nixos-system-erebor-26.05.20261029.6f06d20`.
WayVNC captures the focused Umbriel output at service startup and accepts input;
noVNC is served at `https://erebor.jzon.pl/desktop/?autoconnect=1&resize=scale&path=websockify`.
Access requires Tailscale (or localhost), with same-origin WebSocket enforcement.
Backend listens only on localhost. Service follows the graphical session.

Flake check, dry/full build, Caddy parsing, test and switch passed. Browser showed
the live 3440x1440 desktop; remote Escape closed the shortcut overlay. LAN source
returned 403, tailnet returned 200, foreign Origin returned 403. After switch,
Caddy/Moonshine/networking and browser-desktop were active; no failed system/user
units. Initial activation was interrupted by service restarts; activation was
completed using an independent system service. Caddy matcher syntax/routing
errors were fixed before final successful activation.

Readonly recovery snapshot `/btrfs-top/nixos-root-pre-browser-desktop-20261102`
(ID 645, ro=true) verified before persistent switch; generation 232 retained.
This also activates the previously prepared full package configuration (SYS-051).
No reboot; kernel boot acceptance and SYS-051's broader checks remain separate.
Browser access requires a running graphical session. Audio is not streamed.

## [PREPARED] Full configuration activation — 2026-11-02

SYS-051. Full build and flake checks passed for the complete configuration:
`/nix/store/xd9rg2a792sgpaywa0q9d6llfnphwbhd-nixos-system-erebor-26.05.20261029.6f06d20`.
Added a narrow fpdf2 2.8.9 override excluding its failing
`test_image_with_explicit_dimensions` PDF checksum fixture; all other checks
remain enabled (1780 passed in the original build). The resulting package
was available from cache.nixos.org. Initial unrestricted build exhausted
memory and interrupted T3/Noctalia; both recovered. Retry with
`--max-jobs 1 --cores 2` completed successfully.

Test activation was attempted but sudo authentication did not complete;
cancelled the waiting sudo process before activation. No switch or reboot.
At that earlier attempt, generation 232 remained active and persistent:
`/nix/store/0053clayvfhj5sy8qnlc8qhwh708l3n4-nixos-system-erebor-26.05.20261025.1f607aa`.
No failed system units. Networking, Moonshine, Ollama, Open WebUI, containers,
audio, Noctalia, Vicinae and Oo7 active; Open WebUI/Ollama HTTP 200.
Root/ESP UUIDs verified; EFI boot order and other OS entries unchanged.
Verified readonly recovery snapshot
`/btrfs-top/nixos-root-pre-full-config-20261102` (ID 644); generation 232 and
systemd-boot EFI loader remain available. Closure comparison reviewed:
new kernel 6.18.59, NVIDIA stays 615.78.08. Subsequently activated as generation
233 during SYS-055 (see browser-desktop entry above). Broader SYS-051 acceptance
and record closure remain; kernel boot acceptance requires a separately authorized reboot.

## [COMPLETED] Proton VPN desktop installation — 2026-11-02

SYS-054. Added the Proton VPN desktop package. Flake check, dry build and
full build passed in `/tmp/moonshine-system-build`, retaining installed pins
and Zen override to leave SYS-051 separate. Closure comparison adds Proton
VPN 4.15.3 and dependencies without upgrading existing packages.
Baseline: generation 231, `/nix/store/29ip1vzh55lk6db7bxrf77f0cddy78yw-nixos-system-erebor-26.05.20261025.1f607aa`.
Root/ESP UUIDs match instructions; no failed system units. Verified readonly
snapshot `/btrfs-top/nixos-root-pre-protonvpn-20261102` (ID 643).
Recovery: generation 231 remains available, plus systemd-boot EFI recovery.
Test and persistent switch succeeded as generation 232:
`/nix/store/0053clayvfhj5sy8qnlc8qhwh708l3n4-nixos-system-erebor-26.05.20261025.1f607aa`.
App reports 4.15.3; launched in the graphical session with a visible Proton
VPN window and tray. NetworkManager active, no failed system/user units;
root/ESP UUIDs and EFI boot order unchanged. GRUB retains 231, Windows and
systemd-boot recovery. No reboot. Login and VPN connection untested; app
reports split-tunneling backend unavailable. SYS-051 remains separate.
