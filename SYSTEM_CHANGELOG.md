# NixOS system change log for `erebor` (flake target `moria`)

Record completed NixOS configuration changes and material pending operations
here. Prefix active work **[PENDING]**; change that entry to **[COMPLETED]**,
**[BLOCKED]**, or **[CANCELLED]** with its final result. Do not record
secrets, routine read-only inspections, or one-off command failures.

## [PENDING] Add Umbriel as a second Wayland session — 2026-10-16

Added the Umbriel NixOS and Home Manager modules and a tuigreet session menu
for Niri and Umbriel. Ported Niri's application shortcuts, CapsLock/xremap
navigation and window chords, workspace controls, layout and sizing shortcuts,
media controls, and screenshots to Umbriel actions. Added Umbriel-aware helpers
for the Discord/Spotify background workspace and focused-window screenshots.
Configured Umbriel's connected `DP-1` output to match Niri's native
3440×1440@164.899994 Hz mode. `nix flake check`, dry build, test activation,
and persistent switch succeeded; the active generation is
`d1fz4kmr9px167dacnbsyj1p45llrps7-nixos-system-erebor-26.05.20261013.a033e66`.
Both source and deployed Umbriel configs pass `umbriel config validate`, and
the deployed `DP-1` mode matches Niri. No system units are failed. The locked Umbriel
flake uses its own Nixpkgs revision because this system's 26.05 pin only
provides wlroots 0.20.0 while Umbriel requires at least 0.20.1. No system
units are failed. The running greetd process still has the old config because
restarting it would terminate the active graphical login. Next action: restart
greetd after the user approves ending the current graphical session, then
verify both sessions appear in the chooser and complete this entry.

## [COMPLETED] Add UT2004 runaway-loop launch option — 2026-10-16

Mirrored the Fedora per-user UT2004 desktop entry's `-norunaway` argument in
the NixOS-managed desktop entry. The OldUnreal installer workaround
`MainMenuClass=GUI2K4.UT2K4MainMenuWS` was already active in the user's UT2004
configuration. `nix flake check` and `nixos-rebuild dry-build` passed; switch
activated generation 123. Verified the deployed desktop entry contains
`Exec=ut2004 -norunaway`; Home Manager activation succeeded and no system units
are failed.

## [COMPLETED] Add Cockpit at sys.erebor.jzon.pl — 2026-10-16

Enabled the NixOS Cockpit service and proxied `sys.erebor.jzon.pl` through
Caddy. Port 9090 remains closed in the host firewall; Cockpit accepts the
configured HTTPS/WSS origin and forwarded protocol from Caddy. Added a system
link to the service index. `nix flake check`, dry build, test activation, and
switch passed; generation 122 is active. Verified `cockpit.socket` and Caddy
are active and the URL returns HTTP 200 with trusted TLS. No failed units and
no reboot needed.

## [COMPLETED] Add OVH-backed HTTPS aliases for erebor — 2026-10-16

Set the machine hostname to `erebor` and retained `moria` as an alias. Built
Caddy with the OVH DNS provider and reused Fedora's credentials from
`/etc/caddy/ovh.env` (root-only, outside the Nix store and repository). Added
`erebor` A records at `100.108.216.80`, the current Tailscale address. Restored
the `moria` and wildcard A records to Fedora's Tailscale address,
`100.98.112.118`, after initially pointing them at this host. Caddy now serves
cloud, media, sync, torrent, and code under both names with DNS-01 HTTPS; chat
and the unsupported dashboard were omitted. Added `cloud.erebor.jzon.pl` to
Nextcloud's trusted domains. The Fedora source remains mounted read-only at `/mnt/fedora-*`.
`nix flake check`, dry build, test activation, and switch passed; generation 121
is active. Verified trusted HTTPS certificates and expected responses for both
root names and all ten service aliases. No system units are failed and no reboot
was needed.

## [COMPLETED] Force Darkly Qt style in user sessions — 2026-10-16

Set Home Manager's `QT_STYLE_OVERRIDE=Darkly` so Qt applications use the
Darkly style. `nix flake check` and `nixos-rebuild dry-build` passed; the
configuration is active as generation
`4qh5pc4x4gfpvh2pb6xr67w3jv4pqsa5-nixos-system-moria-26.05.20261013.a033e66`.
Verified the generated Home Manager session environment exports the override.
After a fresh graphical login, verified Qt applications launched from Niri
use Darkly with the configured style options.

## [COMPLETED] Add local service hostnames — 2026-10-16

Added loopback host entries and Caddy host routing for `torrent`, `jellyfin`,
`nextcloud`, and `syncthing`, each with a `.localhost` form. Added both
Nextcloud aliases to the shared trusted domains. Existing LAN links and ports
remain available. `nix flake check`, dry build, and activation passed;
generation 109 is active. Verified all eight names resolve to `127.0.0.1` and
each hostname routes to its service. No system units are failed.

## [COMPLETED] Proxy local qBittorrent hostnames safely — 2026-10-16

Kept qBittorrent's existing single allowed server domain and host-header
validation. NixOS Caddy proxies local aliases with the canonical
Host/Origin/Referer and strips browser HTTP Basic Authorization, matching
Fedora's proxy. The shared profile retains its original single domain. The
pre-change recovery point is read-only snapshot
`/btrfs-top/srv-pre-shared-services-20261016`. `nix flake check`, dry build,
and switch passed; generation 111 is active. Both local aliases and the
canonical domain return HTTP 200, including a request carrying a stale Basic
Authorization header. qBittorrent remains active with its normal login, and
no system units are failed.

## [COMPLETED] Share Fedora service state with NixOS — 2026-10-16

Created and verified read-only snapshot `/btrfs-top/srv-pre-shared-services-20261016`
(UUID `29e40720-ff44-034c-8d5f-32af4482ff28`, subvolume ID 643) before changes.
The source is Fedora's `srv` Btrfs subvolume. NixOS now uses Fedora's service
state directories for Jellyfin, Nextcloud, Syncthing, and qBittorrent;
qBittorrent writes downloads to the shared `/srv/torrents` path. Media-library
and external-drive mounts remain read-only inside Jellyfin/Nextcloud, and the
NixOS-local copies remain available as rollback data. The same service must
not run on both operating systems at once. NixOS generation 108 is active;
`nix flake check` and `nixos-rebuild dry-build` passed. The switch's first
Jellyfin health check raced container startup, but Jellyfin subsequently
reported healthy and the transient failed unit was cleared; no units are now
failed. All four services are active, Nextcloud reports no DB upgrade pending,
and the local service endpoints return their expected responses. Verified
qBittorrent's shared profile and downloads are writable, while its external
drives and the Jellyfin/Nextcloud media binds remain read only. Added the
NixOS-local Nextcloud hostname to shared trusted domains and allowed the
NixOS Podman proxy range. The snapshot is retained; the previous NixOS-local
copies remain available. No reboot was performed.

## [COMPLETED] Import Fedora service mounts and local services — 2026-10-16

Checkpoint before mount/service changes: generation 100 is active on the
`nixos-root` Btrfs subvolume; `/home` is `nixos-home`; `/boot` is the NixOS
ESP. Fedora and Windows UEFI entries were present. Created and verified read-only Btrfs
snapshot `/btrfs-top/nixos-root-pre-service-import-20261016` (UUID
`be74b8ca-fe02-b440-8863-21c3890650dd`, subvolume ID 642). Kept Fedora's
`/srv` and external-drive data read-only on NixOS. Generation 107 is now the
active default; all five mounts are read-only, all imported services and Caddy are
active, service endpoints
respond as expected, and no system units have failed. Generation 100 remains
in the boot menu for recovery. Fedora and Windows boot entries remain
available. No reboot was performed.

## [COMPLETED] Mount Fedora service volumes read-only — 2026-10-16

Mounted Fedora's `srv` Btrfs subvolume at `/srv` and all four external drives
at Fedora's `/srv/external/*` paths, with read-only mounts and automounts.
BigDaddy uses its existing private unlock key and a read-only LUKS mapping.
Expansion was unmounted from its desktop mount before the managed read-only
mount was activated. The flake check, dry build, test activation, and
persistent switch passed. Generation 101 is active; all five mounts are
verified read-only, no system units are failed, and generation 100 remains in
the boot menu as recovery.

## [COMPLETED] Enable Steam — 2026-10-16

Enabled the NixOS Steam module with scoped unfree package allowances. The
flake check, dry build, test activation, and persistent switch passed. The
active system contains `steam`, 32-bit graphics support is enabled, and no
system units are failed.

## [COMPLETED] Install Stremio Linux shell — 2026-10-16

Added the current `stremio-linux-shell` package and its scoped unfree allowance.
The flake check and dry build passed. The local source build, test activation,
and persistent switch succeeded. The active system contains `stremio`, and no
system units are failed.

## [COMPLETED] Install Haruna video player — 2026-10-16

Added Haruna as a graphical video player alongside the existing mpv package.
The flake check, dry build, test activation, and persistent switch passed.
The active system contains `haruna`, and no system units are failed.

## [COMPLETED] Install Ark — 2026-10-16

Added Ark as a system package. The flake check and dry build passed, then test
activation and persistent switch succeeded. The active system contains `ark`,
and no system units are failed.

## [COMPLETED] Install Okular — 2026-10-16

Added Okular as a system package. The flake check and dry build passed, then
test activation and persistent switch succeeded. The active system contains
`okular`, and no system units are failed.

## [COMPLETED] Restore Dolphin Open With applications — 2026-10-15T18:10:29Z

Added a small freedesktop applications menu for the Niri session so KDE's
service cache can discover installed desktop entries. The flake check, dry
build, test activation, and persistent switch passed; generation 74 is active.
Rebuilt the KDE service cache and verified it lists 20 applications, including
Zed, mpv, Helium, and Chromium. The menu is deployed, mounts are unchanged,
and no system or user units are failed. The Dolphin GUI was not opened during
verification.

## [COMPLETED] Use wheel for UDisks system data mounts — 2026-10-15T18:08:04Z

Replaced the dedicated `storage` group with `wheel` for the UDisks system data
mount rule and removed `storage` from the user configuration. The flake check,
dry build, test activation, and persistent switch passed; generation 73 is
active. A `wheel` session without `storage` passed the mount authorization
check. UDisks and Polkit are active, existing mounts are unchanged, and no
units are failed. No drive was mounted or unmounted during verification.

## [COMPLETED] Scope power actions to the wheel group — 2026-10-15T18:04:57Z

Replaced the user-specific Polkit power rule with a `wheel` group check. The
flake check, dry build, test activation, and persistent switch passed;
generation 72 is active. Authorization checks against Noctalia's process
passed for all six actions after activation. Polkit and Noctalia are active,
mounts are unchanged, and no units are failed. No power action was executed.

## [COMPLETED] Allow janzon to reboot, shut down, and suspend — 2026-10-15T18:02:04Z

Added a Polkit rule for the normal logind power actions, including the
multiple-session variants used while SSH is connected. The flake check, dry
build, test activation, and persistent switch passed; generation 71 is active.
Authorization checks against Noctalia's process succeeded for all six actions.
Polkit and Noctalia are active, and no system or user units are failed. No
power action was executed during verification.

## [COMPLETED] Move the Noctalia dock to the left — 2026-10-15T17:52:58Z

Set the managed Noctalia dock position to `left`. `nix flake check`, the
NixOS dry build, test activation, and persistent switch passed. Reloaded the
Noctalia configuration and dock successfully; the deployed configuration
contains `position = "left"` and Noctalia reports its bar visible.

## [COMPLETED] Preserve Lyrics-only bar choice and add cache repair — 2026-10-15T17:50:01Z

The live Noctalia bar no longer includes `media_lyrics`; removed it from the
managed bar layout while retaining the plugin. Added `make
repair-noctalia-lyrics` to recreate the first Lyrics plugin's temporary request
directory and reload Noctalia after plugin updates. The repair action,
`nix flake check`, dry build, test activation, config validation, and persistent
switch passed. Verified the effective bar retains `lyrics_2` but not
`media_lyrics`, Noctalia is active, and no system units are failed. Existing
unrelated Noctalia validation warnings remain.

## [COMPLETED] Show both Noctalia lyrics plugins on the bar — 2026-10-15T17:43:32Z

Added the existing `h465855hgg/lyrics` widget and the enabled
`tranzem/media-lyrics` now-playing widget to the bar, with inline lyrics
enabled for Media Lyrics. Updated the live bar override while preserving its
unrelated settings. `nix flake check`, dry build, test activation, Noctalia
config validation, and persistent switch passed. Verified both widget types in
the effective configuration, Noctalia active with its bar visible, and no
failed system units. Noctalia validation still reports unrelated pre-existing
warnings for the generated Starship file and disabled `mango-displays` widget.

## [COMPLETED] Start the Noctalia Spotify lyrics daemon — 2026-10-15T19:35:00Z

The active bar entries use `goatnath/spotify-lyrics`, whose widget reads
`~/.cache/noctalia/lyrics/current.json` from a separate Python daemon. Add a
graphical-session user service for that daemon with the existing packaged
Python `syncedlyrics` environment and `playerctl`. `nix flake check` and
`nixos-rebuild dry-build --flake /etc/nixos#moria` passed; a live `test`
activation produced current-track lyrics before `switch` made the service
persistent. Verified the service is enabled and running, its state file updates
continuously with real lyric lines, and no units are failed.

## [COMPLETED] Start Vicinae with Niri and bind launcher shortcuts — 2026-10-15T17:10:00Z

Enable Vicinae's packaged user service through the graphical-session target.
Bind Caps+Space (translated by xremap), Super+Space, and Alt+Space to toggle
Vicinae from Niri. `niri validate`, `nix flake check`, and
`nixos-rebuild dry-build --flake /etc/nixos#moria` passed before activation;
the configuration was activated successfully. Verified the service is enabled
and running, and all three bindings are deployed. No failed units remain.

## [COMPLETED] Fix Vicinae user-service executable lookup — 2026-10-15T19:20:00Z

Override the packaged user service's bare `vicinae` command with the absolute
executable path from the pinned Vicinae package; the user service manager could
not resolve the command from its environment, causing repeated `203/EXEC`
restarts. `nix flake check` and `nixos-rebuild dry-build --flake
/etc/nixos#moria` passed before activation; the configuration was activated
successfully. Verified the service drop-in uses the absolute package path and
Vicinae is active and running (PID 797905); no failed user units remain.

## [COMPLETED] Bind Caps+O to Vicinae Spotify search — 2026-10-15T19:25:00Z

Use the existing xremap Caps layer chord to invoke the installed Spotify
Raycast extension's `search` command directly from Niri. `niri validate`,
`nix flake check`, and `nixos-rebuild dry-build --flake /etc/nixos#moria`
passed before activation; the configuration was activated successfully.
Verified the deployed binding targets the loaded
`@mattisssa/store.raycast.spotify-player:search` command.

## [COMPLETED] Pin Vicinae to its upstream Nix flake — 2026-10-15T17:05:00Z

Replace Nixpkgs’ Vicinae v0.23.2 with the upstream flake’s v0.29.1 package,
without changing the system-wide Nixpkgs pin. `nix flake check` and
`nixos-rebuild dry-build --flake /etc/nixos#moria` passed before activation;
the configuration was activated successfully. The upstream closure required a
771 MiB download (1.6 GiB unpacked) because it uses a newer independent
Qt/Node stack. Verified the active system runs Vicinae v0.29.1 and no units
are failed.

## [COMPLETED] Install Vicinae launcher — 2026-10-15T17:02:00Z

Add the packaged Vicinae application launcher to the declarative system
package set. No launcher binding or additional service configuration is added.
`nix flake check` and `nixos-rebuild dry-build --flake /etc/nixos#moria`
passed before activation; Vicinae v0.23.2 and its desktop entries are present
after activation, with no failed system units.

## [COMPLETED] Make Starship follow Noctalia’s active palette — 2026-10-15T17:00:00Z

Use Noctalia’s built-in Starship template to generate a runtime palette while
keeping the custom prompt as a declarative base. Export `STARSHIP_CONFIG` to
both Fish and Niri-launched programs, and maintain a writable generated
Starship configuration for Noctalia to update when its palette changes.
`niri validate`, `nix flake check`, and `nixos-rebuild dry-build --flake
/etc/nixos#moria` passed before activation; the configuration was activated
successfully with no failed units. Verified Fish and a Niri-spawned process
use the writable runtime config, which selects the `noctalia` palette and
contains the generated Flexoki palette block.

## [COMPLETED] Make Niri follow Noctalia’s active palette — 2026-10-15T16:54:07Z

Include Noctalia’s generated Niri palette after the managed compositor
configuration, allowing Noctalia to set focus-ring, border, tab-indicator,
insert-hint, and recent-window highlight colors whenever its palette changes.
`niri validate`, `nix flake check`, and `nixos-rebuild dry-build --flake
/etc/nixos#moria` passed before activation; the configuration was activated
successfully with no failed units. Niri automatically reloads changed
configuration, so no compositor restart or logout is required. Verified the
managed configuration includes the active generated palette, whose current
focus color is Noctalia’s Flexoki primary `#879a39`.

## [COMPLETED] Align Dolphin, Noctalia, and apps with shared desktop themes — 2026-10-15T18:45:00Z

Keep the Darkly Qt widget style, but make Qt6ct use Noctalia's existing
generated `noctalia.conf` palette. Keep Noctalia's `qt` and `kcolorscheme`
templates enabled: the former supplies the Qt palette and the latter supplies
the KDE color scheme used by Dolphin. Ensure applications spawned by Niri
receive `QT_QPA_PLATFORMTHEME=qt6ct`, and reset Dolphin's per-application
scheme override to follow the active KDE palette.

Install the Candy icon theme system-wide and select it through GTK and KDE's
standard preferences, making it available to Noctalia, Dolphin, and other
toolkit-native applications. `niri validate`, `nix flake check`, and
`nixos-rebuild dry-build --flake /etc/nixos#moria` passed before activation;
the configuration was activated successfully. Verified Qt6ct now selects
Noctalia's generated palette while retaining the Darkly widget style,
Dolphin follows the shared KDE color scheme, GTK and KDE select
`candy-icons`, and Noctalia's Niri-spawned process environment contains
`QT_QPA_PLATFORMTHEME=qt6ct`. No failed system units remain.

## [COMPLETED] Permit regular-user mounting of data disks — 2026-10-15T10:30:00Z

Allow members of the dedicated `storage` group to mount UDisks-classified
system data devices without a password, so access can be managed by group
membership rather than a user-specific Polkit rule. Add `janzon` to that
group. Do not grant permissions to format, partition, or otherwise administer
disks. `nix flake check` and `nixos-rebuild dry-build --flake
/etc/nixos#moria` passed, then the configuration was activated. Verified a
fresh `janzon` process has the `storage` group and can mount `/dev/sdb1` at
`/run/media/janzon/Expansion` and unmount it without sudo or a password; zero
units are failed. Existing desktop processes require a logout/login to receive
the new supplementary group.

## [COMPLETED] Import and repair OldUnreal UT2004 from GoodRam — 2026-10-15T20:20:33+02:00

Imported the OldUnreal UT2004 3374 RPM from the mounted GoodRam SSD into
`~/Games/UT2004`, leaving the source unchanged. The Fedora-built game required
the legacy `libomp.so.5` loader name plus the C++ and OpenGL GLVND runtimes.
The declarative launcher now provides these libraries. `nix flake check`,
`nixos-rebuild dry-build --flake /etc/nixos#moria`, and `nixos-rebuild switch`
passed. A 15-second windowed, soundless launch smoke test resolved the game and
renderer dependencies, began the first-run content export, and remained running
until the intentional timeout.

## [COMPLETED] Set Niri refresh rate and disable Mango Displays — 2026-10-15T14:52:48Z

Configured DP-1 declaratively for 3440x1440 at 164.899994 Hz in the managed
Niri configuration. Disabled the Mango Displays plugin, which writes MangoWM
rules and cannot apply display settings under Niri. Niri config validation,
`nix flake check`, dry build, and switch passed. Verified the active Niri
output reports 3440x1440 at 164.900 Hz and the plugin remains disabled.

## [COMPLETED] Add Noctalia Processes dependencies and wlr-randr — 2026-10-15T14:50:11Z

Added `psutil` and Pillow to the dedicated Noctalia plugin Python environment,
and added `wlr-randr` to the system packages. `nix flake check`, dry build,
and switch passed. Verified Python imports `psutil 7.2.2` and `Pillow 12.3.0`,
the Processes plugin statistics script starts successfully, `wlr-randr --help`
works, and `noctalia.service` remains active.

## [COMPLETED] Restore Fedora Noctalia layout and appearance settings — 2026-10-15T14:46:50Z

Restored the saved Fedora bar layout and sizing, taskbar and widget tuning,
Flexoki dark community theme, theme templates, launcher pin, and panel anchor
to the declarative Noctalia configuration. Retained the explicitly requested
top dock instead of Fedora's saved left dock. Kept the unavailable Mango
Displays widget and the two display plugins excluded pending compatibility
work. `nix flake check`, NixOS dry build, and switch passed; the active
Noctalia configuration reloaded and its service is active. The existing
Spotify-media validation warning remains unrelated.

## [COMPLETED] Match Noctalia bar and dock placement to Fedora — 2026-10-15T14:44:17Z

Made the managed Noctalia edges explicit: the default bar is on the bottom and
the dock is on the top, matching Fedora instead of Noctalia's implicit default
layout. `nix flake check`, `nixos-rebuild dry-build`, and
`nixos-rebuild switch --flake /etc/nixos#moria` completed successfully. Reloaded
the active Noctalia configuration; it validates and `noctalia.service` remains
active. The pre-existing Spotify media plugin validation warning remains
unrelated to these placement settings.

## [COMPLETED] Adapt Spotify Media plugin for Niri — 2026-10-15T14:05:49Z

Published the standalone Noctalia plugin fork at
`https://github.com/question44/spotify-media-niri` (commit `9eb7314`). Replaced
Hyprland window detection and focus with Niri window listing and
`focus-window`, retaining Spotify MPRIS metadata, controls, artwork, and launch
behavior. Added the Git source to Noctalia and updated the managed bar config
to use the fork; disabled the original Hyprland-specific community plugin.
Noctalia plugin lint passed with zero errors and warnings, as did `nix flake
check` and the NixOS dry build. Test activation and switch completed on
generation 48. Verified the fork is enabled, the Noctalia service is active,
Spotify's Niri `app_id` is `spotify`, the Niri focus action focuses its window,
Playerctl reads its MPRIS state, and no system units are failed.

## [COMPLETED] Install Noctalia plugin dependencies — 2026-10-15T13:20:42Z

Added the available dependencies declared by enabled Noctalia plugin manifests
to the NixOS package set, including Python plugin modules, Screen Toolkit tools,
PipeWire development metadata, and packaged `ai-usagebar` and NCS renderer
binaries. Kept Hyprland and `hyprctl` excluded as requested; Hyprland-specific
plugin actions remain unavailable. Nix flake check, dry build, test activation,
and persistent activation passed. Verified the mapped plugin commands are on
the session PATH, GTK3 and GtkLayerShell import through Python, PipeWire is
discoverable by pkg-config, Noctalia config validates and its service is active
on `system-47-link`; no system units are failed.

## [COMPLETED] Migrate Noctalia configuration from Fedora — 2026-10-15T12:37:43Z

Imported Fedora's Noctalia v5 configuration through Home Manager, copied its
29 enabled plugin repositories and two referenced wallpapers into NixOS user
state, and preserved the existing NixOS GUI overrides. Kept a backup of the
previous NixOS plugin tree; the Fedora source remains untouched. `nix flake
check`, dry build, test activation, and persistent activation passed. Noctalia
config validation passes and its user service is active on `system-46-link`.
Two migrated plugins log repeated missing-setting warnings (`ncs-visualizer`
and `pixel-shift`); the overall Noctalia config remains valid.

## [COMPLETED] Install Zed and configure LazyVim — 2026-10-15T11:55:58Z

Installed Zed 1.3.6 and Neovim 0.12.4 for `janzon` through Home Manager and
deployed the official LazyVim starter configuration. The terminal `EDITOR`,
`VISUAL`, and `GIT_EDITOR` use a managed wrapper that selects Zed when the
Wayland socket or X display is available and Neovim otherwise; both paths were
verified. Zed remains the XDG handler for `text/plain`. LazyVim stores its
generated plugin lockfile in writable Neovim state because the Nix managed
config is read only. `nix flake check`, the NixOS dry build, test activation,
and persistent activation passed. Verified the headless LazyVim startup with
plugins loaded and persisted generation `system-45-link`; no system units are
failed.

## [COMPLETED] Bootstrap Codex CLI with npm — 2026-10-15T08:16:38Z

Replace the persistent bootstrap service with an explicit `make setup-codex`
target. It uses Nix-managed Node.js to install `@openai/codex@latest` into
`/home/janzon/.local` only if Codex is absent. Add `make help` to list the
available maintenance targets. The existing standalone Codex installation must
remain untouched and T3 Code must remain active. `make help` lists the four
available actions and `make setup-codex` correctly preserved the existing
Codex executable. `nix flake check` and `nixos-rebuild dry-build --flake
/etc/nixos#moria` passed, then the configuration was activated. Verified the
bootstrap user service is removed, T3 Code remains active, and zero units are
failed.

## [COMPLETED] Restore Fedora Starship prompt — 2026-10-15T08:08:00Z

Restored the complete Fedora Starship prompt configuration for `janzon` and
enabled its Fish integration declaratively through Home Manager. `nix flake
check` and `nixos-rebuild dry-build --flake /etc/nixos#moria` passed, then the
Home Manager configuration was activated. Verified Starship 1.25.1 is present,
a fresh Fish shell loads Starship's `fish_prompt`, and its success symbol
renders as configured. Home Manager canonically rewrites the TOML, but it uses
the full recovered Fedora settings; zero system units are failed.

## [COMPLETED] Add T3 Code pairing alias — 2026-10-15T08:04:55Z

Added the managed Fish alias `t3pair`, which runs
`t3 pair --base-dir /home/janzon/.t3/server` against the native T3 Code
service. `nix flake check` and `nixos-rebuild dry-build --flake
/etc/nixos#moria` passed, then the Home Manager configuration was activated.
Verified a new interactive Fish shell defines `t3pair` with the expected
arguments and its T3 help output succeeds; zero system units are failed. The
prior unmanaged Fish configuration was preserved as `config.fish.backup`.

## [COMPLETED] Add native T3 Code and LAN Caddy index — 2026-10-15T07:56:42Z

Installed the supported T3 Code CLI 0.0.45 for `janzon` and enabled
`programs.nix-ld` because its official generic Linux binary requires NixOS's
compatibility loader. Added a persistent native `t3code.service` user service
using `/home/janzon/Projects` as its working directory, with the existing
`/home/janzon/.local/bin/codex` on its runtime `PATH`. Caddy serves the
minimal service index on LAN TCP 80 and proxies T3 Code on LAN TCP 8080; the
T3 backend itself is bound only to `127.0.0.1:3773`. No Tailscale route or
other former Fedora service was added. `nix flake check` and
`nixos-rebuild dry-build --flake /etc/nixos#moria` passed, then the
configuration was activated. Verified both services are enabled and active,
the index and proxy return HTTP 200 through the LAN address, TCP 80 and 8080
are accepted only on `enp4s0`, T3 Code is ready, Codex 0.162.1 resolves from
the T3 service environment, and zero system units are failed.

## [COMPLETED] Create XDG user directories — 2026-10-15T09:45:00Z

Enabled Home Manager's XDG user-directory management for `janzon`, creating
the standard user directories and the `Projects` directory declaratively.
`nix flake check` and `nixos-rebuild dry-build --flake /etc/nixos#moria`
passed. Activated generation
`3kd4x7rg1dab252b7hxj87ajgapcyvb5-nixos-system-moria-26.05.20261013.a033e66`.
Verified all nine directories, the managed `~/.config/user-dirs.dirs` mappings
(including `XDG_PROJECTS_DIR`), an active `home-manager-janzon.service`, and
no failed system units.

## [PENDING] Add encrypted Tailscale state backup workflow — 2026-10-15T09:35:00Z

At the user's explicit request, make a password-encrypted archive of
`/var/lib/tailscale` suitable for Git tracking, despite the repository's
usual prohibition on private-key material. Add declarative GnuPG support and
Make targets to create and restore the archive. The backup password is entered
interactively and must never be recorded in the repository or Nix store.

## [COMPLETED] Rename Tailscale node to erebor — 2026-10-15T09:28:00Z

Changed the connected Tailscale device hostname from `moria-1` to `erebor`
using its local persistent preference. Verified the control plane reports
`erebor` at `100.108.216.80` and `tailscaled` remains active. The NixOS host
name remains `moria`.

## [COMPLETED] Install and configure Tailscale — 2026-10-15T02:35:00Z

Enabled the NixOS Tailscale service declaratively, without an auth key or
special routing configuration. `nix flake check` and
`nixos-rebuild dry-build --flake /etc/nixos#moria` passed. Activated generation
`7zg9wpkl4w2n4dwrpzihyhh6bjzhcf7q-nixos-system-moria-26.05.20261013.a033e66`.
Verified `tailscaled` is enabled and active, and interactive authentication
joined this device as `moria-1` with Tailscale address `100.108.216.80`. The
root-only persistent state is held outside the Nix store at
`/var/lib/tailscale/tailscaled.state`; no secret is committed to this repository.

## [COMPLETED] Fix qt6ct Darkly palette and remove forced style override — 2026-10-15T01:15:00Z

Stopped setting Home Manager `QT_STYLE_OVERRIDE`; retained the Darkly Qt 6
plugin package and plugin-path setup. Added a qt6ct-format Darkly palette and
managed qt6ct's style/palette selection declaratively. `nix flake check` and
the full system build passed. Activated generation
`g3ba9l71qc5bf6l08id376pj4njx44ma-nixos-system-moria-26.05.20261013.a033e66`.
Verified generated `qt6ct.conf` selects Darkly and the managed palette, and the
user manager no longer exports `QT_STYLE_OVERRIDE`. The previous GUI-managed
configuration is preserved at `~/.config/qt6ct/qt6ct.conf.backup`. The running
Niri process retains its old environment; a fresh graphical login is needed
before it stops exporting the removed override to newly launched applications.

## [COMPLETED] Expose Darkly plugins to Qt applications — 2026-10-15T01:05:00Z

Configured Home Manager's Qt integration with the Darkly Qt 6 style package.
`nix flake check` and the full system build passed. Activated generation
`jdkbfl9yi8yq07cz0j3wg76ihwglf49q-nixos-system-moria-26.05.20261013.a033e66`.
Verified the user's Qt plugin path includes `darkly6.so` and the user manager
exports `QT_STYLE_OVERRIDE=Darkly` and `QT_QPA_PLATFORMTHEME=qt6ct`. The
existing Niri process predates this environment update; a fresh login is
required before Dolphin inherits the updated Qt plugin path. The current
session was left running.

## [COMPLETED] Install Darkly Qt 6 style — 2026-10-15T00:55:00Z

Added Bali10050/Darkly at locked revision
`6fc65177b22983d54aa965ea3617f8c9d658f442`, following the system's pinned
nixpkgs, and installed its Qt 6 style package for qt6ct. `nix flake check` and
the full system build passed. Activated generation
`598p2l7gxl38a3011y3dag74rxsxdyx6-nixos-system-moria-26.05.20261013.a033e66`;
verified `darkly6.so` and Darkly settings/decorations plugins are in the system
profile. The default qt6ct selection was not changed.

## [COMPLETED] Install Breeze Qt style — 2026-10-15T00:50:00Z

Added `kdePackages.breeze` alongside qt6ct. `nix flake check` and dry-build
evaluation passed. Activated generation
`fas5d9kv38rb14gyh7lcr2xsp6hll70p-nixos-system-moria-26.05.20261013.a033e66`;
verified Breeze 6.6.6 is in the system package closure. Choose Breeze as the
widget style in qt6ct if it is not already selected.

## [COMPLETED] Install qt6ct and set Qt platform theme — 2026-10-15T00:45:00Z

Added `qt6Packages.qt6ct` and set `QT_QPA_PLATFORMTHEME=qt6ct` in the
graphical session environment. `nix flake check` and dry-build evaluation
passed. Activated generation
`mmg268y6b1rp00pp1rimv2dh0aygsds6-nixos-system-moria-26.05.20261013.a033e66`;
verified `/run/current-system/sw/bin/qt6ct` is present and `/etc/set-environment`
exports the requested variable. Existing processes keep their old environment;
the variable applies to applications launched in a fresh login session.

## [COMPLETED] Enable UDisks2 for Dolphin devices — 2026-10-15T00:40:00Z

Enabled the NixOS UDisks2 service so Dolphin/Solid can enumerate and manage
removable drives. `nix flake check` and dry-build evaluation passed. Activated
generation `8ysib37piw2ijyq8dcdj0p85rv0zajai-nixos-system-moria-26.05.20261013.a033e66`.
Verified the D-Bus activated `udisks2.service` is running and `udisksctl status`
enumerates the connected internal and external drives. No drive was mounted,
unlocked, or modified.

## [COMPLETED] Install Spotify desktop client — 2026-10-15T00:38:00Z

Add the Nixpkgs Spotify package and allow only the `spotify` unfree package
through this host's existing predicate. `nix flake check` and dry-build
evaluation passed. Activated generation
`q1dwyndjp10w5pmnyfx7wxlnw1pnx12k-nixos-system-moria-26.05.20261013.a033e66`;
verified `/run/current-system/sw/bin/spotify` reports version
`1.2.90.451.gb094aab0`.

## [COMPLETED] Import Fedora Niri shortcuts — 2026-10-15T00:37:00Z

Port the Fedora xremap Caps-layer navigation and window-management shortcuts
to the declarative Niri config. Connect common launcher, settings, lock, browser,
terminal, and Dolphin shortcuts to the installed Noctalia/NixOS applications;
Fedora-only DMS, Vicinae, and custom-helper bindings remain deferred. Niri
validation, `nix flake check`, and the NixOS dry-build evaluation passed.
Activated generation
`xyzh7nz3xvam1qzqjqw90lg7yj1v3m1k-nixos-system-moria-26.05.20261013.a033e66`;
Home Manager deployed the config and its Niri validation passed. Reloaded the
running compositor with `niri msg action load-config-file`; Noctalia's user
service remains active.

## [PENDING] Install xremap with the Fedora configuration — 2026-10-15T02:22:00Z

Copy Fedora's active xremap mapping and three device filters (both IQUNIX
keyboards and the Logitech G502 X LS), grant the `janzon` account the same
`input` group access, and load/configure `uinput` with the Fedora-equivalent
udev rule. Start xremap through a user service bound to
`graphical-session.target` and restart it when the MQ80 USB receiver
(`320f:5055`) reconnects. Validate the configuration, active service, device
access, and no failed system units. `nix flake check` and
`nixos-rebuild dry-build --flake /etc/nixos#moria` passed. Activated generation
`ldv08n0975kdls9nwi0yvs76q08zknh1-nixos-system-moria-26.05.20261013.a033e66`.
The mapping is byte-for-byte identical to Fedora's active configuration, the
service and udev rules are installed, and there are zero failed system units.
The existing lingering user manager was created before `janzon` joined the
`input` group, so it cannot yet open the selected devices; a reboot is required
to recreate that manager with the declarative group membership, then verify the
active xremap service and mappings.

## [COMPLETED] Tie Noctalia to the Niri graphical session — 2026-10-15T02:20:20Z

The first logout/login after enabling lingering returned to Niri successfully,
confirming the user-manager race is resolved. However, Noctalia was previously
started by Niri as an independent transient scope; it survived logout, retained
the old Wayland connection, and prevented a visible instance in the new
session. Enable Noctalia's NixOS-provided systemd user service and attach it to
`graphical-session.target`, then remove the Niri transient startup command.
Verify that the old process is replaced by the managed service and that it is
active in the current Niri session. `nix flake check` and
`nixos-rebuild dry-build --flake /etc/nixos#moria` passed. Activated generation
`k0imq0gw4a2vrdhcx14m2v42hxmm7q4p-nixos-system-moria-26.05.20261013.a033e66`.
The previous transient Noctalia process did not exit after logout and was
terminated after confirming its exact stale scope. Verified the replacement
`noctalia.service` is active, the transient scope is absent, and zero system
units are failed.

## [PENDING] Keep the user manager alive across Niri logouts and restore Oo7 unlock — 2026-10-15T02:15:13Z

Previous boots showed a Niri/greetd login race: greetd accepted the next login
while the non-lingering `janzon` systemd user manager was still shutting down
the preceding Niri session, leaving the new graphical session without a live
manager. Fedora's installed configuration has lingering enabled for `janzon`.
Enable `users.users.janzon.linger` declaratively to preserve the user manager
between sessions. Restore Oo7's custom greetd PAM auth/session integration,
with `pam_unix` password capture before `pam_oo7`, so the login password can
unlock Oo7 without restoring GNOME Keyring. Validate the generated PAM stack,
linger state, and system services before attempting a logout/login test.
`nix flake check` and `nixos-rebuild dry-build --flake /etc/nixos#moria`
passed. Activated generation
`p2iwml8nfi3bn7yrm4amsb0qsfyn9xh6-nixos-system-moria-26.05.20261013.a033e66`.
Verified `Linger=yes`, successful `linger-users.service` activation, the
generated greetd stack's `pam_unix` → `pam_oo7` → final `pam_unix` order, an
active Oo7 daemon, and zero failed system units. A deliberate logout/login
must still verify that Niri returns normally and Oo7's keyring unlocks.

## [COMPLETED] Disable unsafe Oo7 login integration — 2026-10-15T00:09:10Z

The attempted `pam_oo7` integration for greetd did not unlock Oo7 reliably.
The initial module placement had no `PAM_AUTHTOK`; the follow-up early
`pam_unix` placement was activated in generation
`w3l7w7a5rjgkfnbhjczvzjb92q3n4107-nixos-system-moria-26.05.20261013.a033e66`,
but the next logout/login attempt produced a black screen, a systemd session
allocation failure, and required a reboot. The keyring was not verified
unlocked. Remove the experimental PAM auth/session rules and keep Oo7 as the
desktop Secret Service provider; design a safer Fedora-like unlock path before
attempting another logout test. Removed the experimental PAM module and early
password-capture rules, then passed `nix flake check` and
`nixos-rebuild dry-build --flake /etc/nixos#moria`. Activated generation
`jpy6m61da6b2l70nal37xmd4yq5zadkw-nixos-system-moria-26.05.20261013.a033e66`.
Verified the generated greetd PAM stack no longer contains `pam_oo7.so`, Oo7's
daemon remains active, and zero system units are failed. Automatic Oo7 unlock
is not configured or claimed to work; a safer design is still pending.

## [COMPLETED] Set Helium as the default browser — 2026-10-15T00:00:00Z

Configure Home Manager MIME associations so Helium handles HTTP, HTTPS, HTML,
XHTML, and XML links/documents. Validation, activation, and live verification
are handled by `helium.desktop`. `nix flake check` and
`nixos-rebuild dry-build --flake /etc/nixos#moria` passed. Activated generation
`jpy6m61da6b2l70nal37xmd4yq5zadkw-nixos-system-moria-26.05.20261013.a033e66`.
Verified the generated `~/.config/mimeapps.list`, Helium desktop entry, and
zero failed system units.

## [COMPLETED] Set timezone to Europe/Warsaw — 2026-10-14T23:55:31Z

Change `time.timeZone` from `Etc/UTC` to `Europe/Warsaw` in the declarative
host configuration. `nix flake check` and
`nixos-rebuild dry-build --flake /etc/nixos#moria` passed. Activated generation
`7gjcan9k3x5acbcg6g4gq46yfjjg8l15-nixos-system-moria-26.05.20261013.a033e66`.
Verified `Europe/Warsaw` (CEST, UTC+02:00), synchronized NTP, and zero failed
system units.

## [COMPLETED] Install Helium Browser — 2026-10-14T23:55:00Z

Added the pinned Helium Browser flake and enabled its NixOS module. Helium is
installed declaratively and configured to use Oo7 through the
`gnome-libsecret` password store. `nix flake check` and
`nixos-rebuild dry-build --flake /etc/nixos#moria` passed. Activated generation
`al09v2hn29xvjbfsv1fkf6kzgwkzzmr5-nixos-system-moria-26.05.20261013.a033e66`.
Verified `/run/current-system/sw/bin/helium`, Helium 0.19.2.1, its desktop
entry, and zero failed system units.

## [COMPLETED] Configure Chromium to use Oo7 Secret Service — 2026-10-14T23:49:00Z

Added a declarative wrapper around ungoogled Chromium that passes
`--password-store=gnome-libsecret`, routing Chromium's password storage through
the active Oo7 Secret Service provider. `nix flake check` and
`nixos-rebuild dry-build --flake /etc/nixos#moria` passed. Activated generation
`zkjqbrxl7nb5fv94gm3nl7lkib13hbrd-nixos-system-moria-26.05.20261013.a033e66`.
Verified the installed Chromium wrapper contains the flag and Oo7 owns
`org.freedesktop.secrets`. Restart Chromium before testing saved credentials.

## [COMPLETED] Set Fish as the default shell — 2026-10-14T23:23:22Z

Enabled `programs.fish` and set `janzon`'s declarative login shell to
`/run/current-system/sw/bin/fish`. `nix flake check` and
`nixos-rebuild dry-build --flake /etc/nixos#moria` passed. Activated the
configuration as generation
`zkv5b1g1v7min65agn348qkjnjqig5n7q-nixos-system-moria-26.05.20261013.a033e66`.
Verified the account entry, Fish 4.7.1, and zero failed system units.

## [COMPLETED] Set Fish as the system-wide default shell — 2026-10-14T23:24:20Z

Set `users.defaultUserShell = pkgs.fish` so new NixOS user accounts receive
Fish by default, while retaining the explicit `janzon` shell declaration.
Validated with `nix flake check`, `nixos-rebuild dry-build`, and
`nixos-option users.defaultUserShell`; activated generation
`45nbjx7rf8zsnhgpgh5kw8h8m3cxvzkm-nixos-system-moria-26.05.20261013.a033e66`.
No system units are failed.

## [COMPLETED] Install Dolphin file manager — 2026-10-14T23:25:16Z

Added `kdePackages.dolphin` to the system packages. `nix flake check` and
`nixos-rebuild dry-build --flake /etc/nixos#moria` passed. Activated generation
`1xykvpi97mwn8k0gya7w46xrz61j25z0-nixos-system-moria-26.05.20261013.a033e66`.
Verified `/run/current-system/sw/bin/dolphin`, Dolphin 26.04.3, and zero
failed system units.

## [COMPLETED] Set Polish keyboard layout — 2026-10-14T23:27:29Z

Set the system virtual console keymap to `pl` and the Niri graphical XKB
layout to `pl`. `nix flake check` and `nixos-rebuild dry-build --flake
/etc/nixos#moria` passed; the configuration was activated successfully.
Verified `KEYMAP=pl` in `/etc/vconsole.conf`, successful vconsole setup, and
zero failed system units.

## [COMPLETED] Expose user-local binaries to Fish — 2026-10-14T23:32:05Z

Enabled `environment.localBinInPath` so Fish login sessions include
`/home/janzon/.local/bin`, where the Codex executable is installed. The
configuration passed `nix flake check` and `nixos-rebuild dry-build`, then was
activated successfully. A clean Fish login now resolves Codex and reports
`codex-cli 0.162.1`; zero system units are failed.

## [COMPLETED] Apply Polish Niri keyboard layout — 2026-10-14T23:33:26Z

The active user Niri configuration at `/home/janzon/.config/niri/config.kdl`
was overriding the NixOS fallback configuration. Added `layout "pl"` and
`options "lv3:ralt_switch"` to both the active configuration and the tracked
Niri configuration. Niri validation passed, the compositor was restarted, and
`niri msg keyboard-layouts` now reports `Polish`.

## [COMPLETED] Manage Niri user configuration with Home Manager — 2026-10-14T23:37:33Z

Made the full existing Niri configuration the tracked source at
`home/niri/config.kdl`. Added the pinned Home Manager 26.05 input and deployed
the file declaratively to `~/.config/niri/config.kdl`. The previous unmanaged
file was preserved as `config.kdl.backup`. `nix flake check`, Niri validation,
and `nixos-rebuild dry-build` passed; activation started
`home-manager-janzon.service` successfully.

## [COMPLETED] Complete first-boot Secret Service configuration — 2026-10-14T23:12:14Z

The first boot passed the core desktop, NVIDIA, Wayland, browser, networking,
display, and PipeWire checks. The installed generation did not yet configure
Oo7 as the Secret Service provider: the portal selected the GNOME backend while
GNOME Keyring was disabled, and Oo7 was only installed as a client package.
The repository now adds the pinned Oo7 daemon and portal, D-Bus registration,
the daemon capability wrapper, and the `oo7` portal selection. Activated
generation `dqc84r5k9jijlk2z8y4c1s2wi5wclnpi`. Verified the Oo7 daemon is
running as `janzon`, owns `org.freedesktop.secrets`, and has `cap_ipc_lock`;
verified the generated Niri portal configuration selects `oo7` for the Secret
portal; GNOME Keyring is disabled. Core first-boot checks also pass for Niri,
Noctalia, Ghostty, Wayland Chromium, NVIDIA, display, PipeWire, networking,
and failed system units. A reboot and Fedora firmware-entry check remain.

## [COMPLETED] Final first-boot reboot acceptance — 2026-10-14T23:21:18Z

Checkpoint before reboot: active NixOS generation is
`dqc84r5k9jijlk2z8y4c1s2wi5wclnpi`; Oo7 Secret Service is running; target
filesystem remains UUID `5be9be17-20c9-4a47-ba2d-6adf1ceb4c55` with
`nixos-root` and `nixos-home`; ESP remains UUID `38B5-8386` at `/boot`.
Verified Niri on the native 3440x1440 display, NVIDIA RTX 4090, PipeWire,
network connectivity, ungoogled Chromium under Wayland, and no failed system
units. Reboot completed at 23:16 UTC and the system returned to the working
NixOS generation with the expected `nixos-root` and `nixos-home` mounts.
Completed: Fedora was selected from firmware and reported by the user as
booting normally and remaining intact.

## [COMPLETED] Initial parallel installation and pre-reboot bootability gate — 2026-10-14T22:53:30Z

- Important Snapper snapshot verified: `2`, description
  `pre-nixos-parallel-install-20261014`, userdata `important=yes`.
- Target Btrfs verified: filesystem UUID
  `5be9be17-20c9-4a47-ba2d-6adf1ceb4c55`, partition UUID
  `e8de64cc-4b7c-44cb-8250-8bcdd3186e28`; new subvolumes only
  `nixos-root` (ID 635) and `nixos-home` (ID 636).
- Target mounts verified with `subvol=nixos-root,compress=zstd:1` and
  `subvol=nixos-home,compress=zstd:1`; existing ESP UUID `38B5-8386` mounted
  at `/boot`; Fedora `root`, `home`, `containers`, and `srv` remain separate.
- ESP backup checksum verified from
  `~/.local/state/nixos-migration/esp-EFI-2026-10-14.tar`:
  `bc10532b864f1611b95daf46aacfe870c3f66518c6e894b3d3b800515c9f6b2a`.
- Installer ISO verified through `/dev/mapper/ventoy`: SHA-256
  `81ec93d823a7ad40f58b14dfcf43de5d794a3aa956564301fa5fcdbe68459f88`.
- Configuration revision installed:
  `13c832ca532efd9ac4421284733a1247ba29efcf`.
- `nixos-install --flake /mnt/etc/nixos#moria` completed successfully and set
  the root password interactively.
- The `janzon` account password was set interactively after installation; no
  password material is recorded here.
- ESP verification passed: `/boot/EFI/systemd/systemd-bootx64.efi`,
  `/boot/EFI/nixos/l94h0skn99v3fqhvzjcr7cvcz202nabd-linux-6.18.56-bzImage.efi`,
  `/boot/EFI/nixos/8da1amvb7rln1mxzhcgsz64xjhvvimf1-initrd-linux-6.18.56-initrd.efi`,
  and `loader/entries/nixos-generation-1.conf` are present.
- UEFI verification passed: separate `Boot0005* NixOS` points to
  `\\EFI\\systemd\\systemd-bootx64.efi`; BootOrder leaves Fedora first and
  NixOS last. Existing Fedora (`EFI/fedora`, `EFI/moria`) and Windows
  (`EFI/Microsoft`) files and UEFI entries remain present.
- The loader entry selects `root=fstab`; installed fstab resolves that to
  filesystem UUID `5be9be17-20c9-4a47-ba2d-6adf1ceb4c55` with
  `subvol=nixos-root` and includes `subvol=nixos-home`.
- Bootability gate passed. Mandatory next action: reboot and select the
  explicit `NixOS` UEFI entry for first-boot acceptance; do not change the
  firmware default until acceptance checks pass.

## [COMPLETED] Enable OpenSSH server — 2026-10-15T07:16:11Z

Enabled the declarative OpenSSH server and allowed inbound TCP port 22 through
the NixOS firewall. `nix flake check` (with the required `nix-command flakes`
feature flags) and `nixos-rebuild dry-build --flake /etc/nixos#moria` passed,
then the configuration was activated successfully. Verified `sshd.service` is
enabled and active, listens on IPv4 and IPv6 port 22, and the active IPv4 and
IPv6 firewall chains both accept TCP port 22. The effective SSH policy permits
password authentication for normal users and prohibits root password login;
zero system units are failed.
# [COMPLETED] Migrate HyperHDR from Fedora — 2026-10-15T13:19:46Z

Add HyperHDR v22.0.0.0 from the Fedora source revision to the NixOS
configuration, run it as a user service in the graphical session for PipeWire
capture, and migrate the Fedora HyperHDR state directory. Fedora remains the
source of record and must remain bootable. Pre-change NixOS system profile is
`system-41-link`; no failed system units were reported. Run `nix flake check`,
build the HyperHDR package, and `nixos-rebuild dry-build` before activation.
Verify the service, screen capture portal, retained database, and LED output
after activation. The v22 package build, `nix flake check`, dry build, and
NixOS test activation passed. The Fedora database copy matches its source
checksum. The old PipeWire restoration token was backed up and cleared because
Niri's portal rejected it as an invalid UUID. After the user selected the
monitor, capture exposed a missing EGL runtime library; the HyperHDR wrapper
now includes libglvnd and the active OpenGL driver path. `nixos-rebuild switch`
activated generation `system-43-link`. Verified HyperHDR entered `STREAMING`
with a 3440×1440 PipeWire source using EGL/DMA-BUF acceleration,
`hyperhdr.service` is active with zero restarts, the web UI returns HTTP 200,
and no system units are failed. Fedora remains intact and bootable.

# [COMPLETED] Restore HyperHDR ScreenCast portal routing — 2026-10-15T18:32:47Z

HyperHDR lost access to the PipeWire ScreenCast portal after the graphical
session restarted: the Niri portal configuration did not explicitly route
`org.freedesktop.impl.portal.ScreenCast` to the installed GNOME backend, whose
metadata is otherwise limited to GNOME sessions. Added that declarative route
in `hosts/moria/default.nix`. `nix flake check` and
`nixos-rebuild dry-build --flake /etc/nixos#moria` passed, then
`nixos-rebuild switch --flake /etc/nixos#moria` activated generation
`fn8ljavigzzl4kj4386f536cv5rp8wrd-nixos-system-moria-26.05.20261013.a033e66`.
After restarting the user portal and HyperHDR services, the ScreenCast portal
reported protocol v5 and HyperHDR restored its saved permission, connected to
the 3440x1440 PipeWire stream, entered `STREAMING`, and enabled DMA-BUF GPU
acceleration. `hyperhdr.service` is active with zero restarts and no user units
are failed.

# [COMPLETED] Install Discord — 2026-10-15T20:27:13Z

Added the Discord desktop package to `environment.systemPackages` and allowed
only its unfree package name through the existing restrictive unfree predicate.
`nix flake check` and `nixos-rebuild dry-build --flake /etc/nixos#moria`
passed, then `nixos-rebuild switch --flake /etc/nixos#moria` activated
generation `8gw8xqrac3fx1i4s5gf2w6k75n0hxz32`. Verified the `discord`
executable is present in the active system profile, Discord 1.0.159 starts
under Wayland, and no system units are failed.

# [COMPLETED] Add dedicated Niri Overview backdrop — 2026-10-15T20:49:50Z

Added a declarative `swaybg` user service that renders
`wallhaven-vpeq6l.jpg` as a separate background-layer surface on DP-1, plus a
Niri layer rule that places only its `wallpaper` namespace in Niri's Overview
backdrop. The normal Noctalia desktop wallpaper was restored to
`wallhaven-p8r2wj.jpg`. `niri validate`, `nix flake check`, and
`nixos-rebuild dry-build --flake /etc/nixos#moria` passed; the configuration
was activated as generation `37saps9hdwvfgdwywrhf7l6q8kglnpk0`, and
`niri-overview-wallpaper.service` is active. Niri loaded the deployed
configuration live via `niri msg action load-config-file`; a captured Overview
showed the galaxy image behind the workspace grid while the normal desktop
wallpaper remained unchanged. No user or system units are failed.

# [COMPLETED] Make Overview wallpaper Dolphin action declarative — 2026-10-15

Moved the Dolphin service menu, its wallpaper-setting helper, and the
`niri-overview-wallpaper.service` user override into the NixOS/Home Manager
configuration. The selected Overview wallpaper remains user-managed state at
`~/.config/niri/overview-wallpaper`. `nix flake check` and
`nixos-rebuild dry-build --flake /etc/nixos#moria` passed, then
`nixos-rebuild switch --flake /etc/nixos#moria` activated successfully. The
menu and helper are deployed as executable Home Manager links, the service is
active with zero restarts and exit status 0, and the current wallpaper target
is preserved. The KService cache was rebuilt for Dolphin to discover the new
menu; Niri did not need to be restarted.

# [COMPLETED] Install nomacs image viewer — 2026-10-15

Added nomacs to the declarative system package list, set it as the default
handler for its supported image MIME types, and declaratively selected its
System Theme option while preserving the rest of its user settings.
`nix flake check` and `nixos-rebuild dry-build --flake /etc/nixos#moria`
passed, then the system configuration was activated. Verified JPEG and PNG
open with the nomacs desktop entry and its config contains
`themeName312=System Theme`. The already-running nomacs instance was left
untouched; the theme change takes effect after restarting nomacs.

## [COMPLETED] Use Noctalia for rounded display corners — 2026-10-15

Use Noctalia's native screen-corner setting with an 8-pixel radius, matching
the Niri window corner radius. Remove the separate `wayland-rounded-corners`
Home Manager service and flake input. `nix flake check` and
`nixos-rebuild dry-build --flake /etc/nixos#moria` passed, then the
configuration was activated. Noctalia accepted `config-reload`; Niri reports
four `noctalia-screen-corner` surfaces on DP-1, `noctalia.service` remains
active, and `rounded-corners.service` is inactive and no longer installed.
No Niri restart was needed.

## [COMPLETED] Bind Caps+V to Vicinae clipboard history — 2026-10-15

Bind the existing Caps+V xremap chord (`Ctrl+Alt+Super+V`) to Vicinae's
clipboard-history deeplink. `niri validate`, `nix flake check`, and
`nixos-rebuild dry-build` passed before activation. Reloaded Niri's config
without restarting the compositor and invoked the Vicinae deeplink
successfully; `vicinae.service` remains active.

## [COMPLETED] Bind Caps+Cmd+V to Vicinae snippets — 2026-10-16

Map Caps+Cmd+V to a distinct Niri chord and open Vicinae's `snippets:manage`
command. `niri validate`, `nix flake check`, and
`nixos-rebuild dry-build --flake /etc/nixos#moria` passed before activation.
Restarted xremap to load the new remap and reloaded Niri without restarting
the compositor. Verified both deployed configs and successfully invoked
`vicinae cmd launch snippets:manage`; xremap and Vicinae are active.

## [COMPLETED] Thin Niri focus ring — 2026-10-16

Reduce the focus-ring width from 4 to 2 logical pixels, preserving its current
colors and 8-pixel corner radius. `niri validate`, `nix flake check`, and
`nixos-rebuild dry-build` passed before activation. Reloaded Niri's deployed
configuration successfully without restarting the compositor.

## [COMPLETED] Install ddcutil — 2026-10-16

Add `ddcutil` to the system packages and enable the NixOS I2C module so local
seat users can access `/dev/i2c-*` for monitor DDC/CI control. `nix flake
check` and `nixos-rebuild dry-build --flake /etc/nixos#moria` passed before
activation. Verified `ddcutil` 2.2.7 is installed and, as the regular user,
`ddcutil detect --brief` found the Dell AW3423DWF on DP-1 via `/dev/i2c-4`.

# [COMPLETED] Install Gwenview — 2026-10-15

Added `kdePackages.gwenview` to the declarative system package list without
changing the existing nomacs image associations. `nix flake check` and
`nixos-rebuild dry-build --flake /etc/nixos#moria` passed, then the
configuration was activated. Verified the Gwenview executable is available.

# [COMPLETED] Reduce Niri window top and bottom outer gaps — 2026-10-15

Set Niri layout top and bottom struts to `-8`, reducing only the outer
vertical space to eight logical pixels while leaving the global 16-pixel gaps
and Noctalia bar margins unchanged. `niri validate`, `nix flake check`, and
`nixos-rebuild dry-build --flake /etc/nixos#moria` passed. After activation,
the deployed Niri config was loaded live with `niri msg action
load-config-file` and validated successfully; Niri was not restarted.

# [REVERTED] Double Caps+Q quit chord — 2026-10-16

# [PENDING] Restore xremap keyboard devices — 2026-10-16

Caps+Q is restored to its original direct Niri shortcut mapping. During xremap
restart, the kernel disconnected the USB hub branch containing the configured
Telink and RDR input devices. xremap now exits with `No device was selected`,
so the hotkey cannot work until the keyboard/receiver devices reconnect.


The xremap nested sequence stopped producing a usable single Caps+Q action.
Restored the direct Caps+Q to Niri shortcut mapping so the parking action works
again. The double press quit chord is disabled pending a reliable implementation.

# [COMPLETED] Rename and place the background-apps workspace last — 2026-10-16

Rename the named workspace to `background-apps` and place it after ordinary
workspaces, before Niri's required trailing empty workspace. Reorder it at
startup and whenever Caps+Q parks Discord or Spotify. `niri validate`,
`nix flake check`, and `nixos-rebuild dry-build` passed; the change was
activated and loaded live. Verified the workspace follows ordinary workspaces
and that Caps+Q moves Spotify there while leaving focus on the original
workspace. Discord remains there as well.

# [COMPLETED] Add a background-app workspace for Discord — 2026-10-16

Declare a persistent `background-app` Niri workspace. Caps+Q moves a focused
Discord window there while retaining the existing close-window behavior for
other applications. `niri validate`, `nix flake check`, and
`nixos-rebuild dry-build` passed; the change was activated with
`nixos-rebuild switch` and loaded live. Invoking the shortcut script moved the
Discord window to the named workspace while leaving focus on the original
workspace. The window was returned to its original workspace after verification.

# [COMPLETED] Round Niri focus ring to 8 px — 2026-10-15

Enabled a global `geometry-corner-radius 8` window rule, which rounds Niri's
focus ring and borders to an 8-pixel radius. Window content is not forcibly
clipped. `niri validate`, `nix flake check`, and
`nixos-rebuild dry-build --flake /etc/nixos#moria` passed. The configuration
was activated and loaded live via Niri IPC; Niri was not restarted.

# [COMPLETED] Clip Niri windows to rounded geometry — 2026-10-15

Enabled `clip-to-geometry true` in the global 8-pixel geometry-corner rule so
window content is clipped to rounded corners, in addition to the rounded
focus ring and border. `niri validate`, `nix flake check`, and
`nixos-rebuild dry-build --flake /etc/nixos#moria` passed. The configuration
was activated and loaded live via Niri IPC without restarting Niri.

# [COMPLETED] Prefer undecorated Niri windows — 2026-10-15

Enabled Niri's top-level `prefer-no-csd` option so applications omit
client-side titlebars and decorations when they support the request. Apps
that explicitly require client-side decorations may retain them, and already
open windows need to be restarted individually. `niri validate`,
`nix flake check`, and `nixos-rebuild dry-build --flake /etc/nixos#moria`
passed; the deployed Niri config was activated and loaded live via IPC without
restarting Niri.

## [COMPLETED] Import Jellyfin with Fedora libraries read only — 2026-10-16

Copy the Fedora Jellyfin configuration and cache into NixOS-local writable
state, then run the matching Jellyfin 10.11.11 OCI image. The existing media
directory and all four external volumes are bind-mounted read only. The
container's web port is loopback-only pending the local Caddy service index.
`nix flake check`, `nixos-rebuild dry-build`, and `nixos-rebuild test` ran;
the first test reported a transient startup health-check failure, then the
container reached its ready state. Verified the Podman health check succeeds,
the HTTP endpoint responds with 302, and all data mounts are read only.

## [COMPLETED] Import Syncthing identity from Fedora — 2026-10-16

Copy the existing Syncthing identity and configuration into NixOS-local
writable state and run it with the upstream OCI image. Keep the GUI bound to
localhost for the local Caddy proxy and allow sync protocol TCP/UDP 22000 on
the LAN and Tailscale interfaces. Fedora had no configured sync folders.
`nix flake check` and `nixos-rebuild dry-build` passed before activation.
The service is active and its localhost GUI responds with HTTP 200.

## [COMPLETED] Import qBittorrent with NixOS download storage — 2026-10-16

Copy the Fedora qBittorrent profile into NixOS-local writable state, retaining
the existing torrent metadata and credentials. Mount Fedora torrent and
external volumes read only so existing torrents can seed without modifying
Fedora data. New downloads use `/var/lib/moria/torrents`. The qBittorrent web
port is loopback-only pending the local Caddy index. `nix flake check` and
`nixos-rebuild dry-build` passed before activation. After activation the
service is active, its web endpoint requires authentication, and Podman
reports the Fedora data mounts read only with the NixOS download volume
writable.

## [COMPLETED] Import Nextcloud data and PostgreSQL 17 — 2026-10-16

NixOS-local copies of the Fedora Nextcloud 34.0.2 files, data, and PostgreSQL
17 cluster are ready under `/var/lib/moria/nextcloud`; credentials are stored
outside the repository in `/etc/nextcloud/db.env`. The Fedora source mounts
remain read only. PostgreSQL 17.11 recovered the copied cluster and Nextcloud
reports version 34.0.2 with no database upgrade pending. Its local proxy
responds with the login redirect, the imported library mounts are read only,
and the first background cron pass completed. `nix flake check`, dry-build,
test, and switch passed. Recovery checkpoint remains generation 100 and the
verified snapshot `/btrfs-top/nixos-root-pre-service-import-20261016`.

## [COMPLETED] Add local service links through Caddy — 2026-10-16

Add local reverse proxies and update the Caddy index for Jellyfin, Nextcloud,
Syncthing, and qBittorrent. Links use the current hostname or LAN address;
the imported Fedora HTTPS domains are not used. Open the corresponding ports
on the LAN interface. `nix flake check`, dry-build, test, and switch passed.
Verified the index responds with HTTP 200, Jellyfin and Nextcloud redirect to
their login/setup pages, Syncthing responds with HTTP 200, and qBittorrent
requires authentication.
