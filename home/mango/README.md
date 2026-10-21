# Umbriel to Mango 0.18.2

Select **Mango** from the Noctalia greeter session selector. Umbriel remains the
default. The session wrapper imports the Mango environment through the upstream
Home Manager autostart, starts the graphical session and Noctalia, and stops
session services on exit. Config is managed by Home Manager; edit config.conf in
this directory, rebuild, then use Super+Shift+F5 to reload it.

The port retains the Polish keyboard, right Alt third level, DP-1 at
3440×1440 / 164.9 Hz / scale 1, blur, launchers, CapsLock layer, window navigation,
tags 1–9, screenshots, audio and brightness controls, scratchpad, and right Ctrl
app switching. Existing xremap application shortcuts still apply. The stale
~/.config/mango/monitors.conf is deliberately not sourced.

Behavioral differences:

- Mango has nine tags rather than Umbriel's dynamically inserted workspaces.
  Workspace reorder keys show a notification; previous/next selects adjacent tags.
- Scroller stacks and groups replace columns and tabbed columns. Column move/tag
  actions move the focused client. Consume/expel uses scroller_stack; tab toggling
  joins the right-hand neighbor's group or leaves the current group. Caps+W/S,
  Super+Up/Down and Super+K/J select the previous/next tab when grouped; outside
  a group they retain normal up/down window focus. Caps+A/D and Super+Left/Right
  continue to move between columns.
- Width presets are 1/3, 1/2, 2/3 and full width. Secondary extent uses 100-pixel
  height increments. Focus floating toggles to the last window.
- Scratchpad uses the special workspace (tag 0) with the normal scroller layout.
  Caps+0 or Super+0 shows/hides it and returns to the previous workspace.
  Caps+Super+0 or Super+Shift+0 moves the focused window into it; the same
  shortcut inside restores that window to the previous workspace. Regular
  Caps+A/D, Super+Left/Right, window movement, sizing and stacking shortcuts
  work there. Caps+Q sends Discord/Spotify to this tiled scratchpad.
  The old dedicated scratchpad key mode is removed. Previously minimized
  windows remain in the legacy pool; restore them with
  `mmsg dispatch restore_minimized` before moving them to the tiled scratchpad.
- Super+Shift+Escape enters shortcut passthrough mode; the same chord exits.
  This replaces Umbriel's application shortcut inhibition toggle.
- The cheatsheet keys show a concise notification rather than an overlay.
- HDR is supported upstream only by the separate wl-only renderer branch. The
  standard release used here provides scenefx blur; Caps+F1 explains the HDR
  limitation instead of running Umbriel commands in Mango.
- The wallpaper-only ambilight output is created at 3440×1440 / 30 Hz before
  Noctalia starts. Steam routing rules target sunshine when that output exists.
  HyperHDR's capture selection may need to be chosen again for Mango's wlr
  portal. Sunshine's existing Umbriel-specific scripts require separate session
  integration; this port does not change that service. Oo7 remains Secret Service.
- The package retains its targeted legacy scratchpad IPC patch; the tiled
  scratchpad uses upstream special-workspace dispatchers directly.

No interactive hardware session has been verified until a user logs into Mango.
