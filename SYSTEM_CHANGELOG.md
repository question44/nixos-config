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
and service edits that a full activation would also apply. See [SYS-067](SYSTEM_TODO.md#sys-067).
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

# NixOS system change log for `erebor` (flake target `erebor`)

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
in [SYSTEM_TODO.md](SYSTEM_TODO.md); recovery knowledge lives in
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
below the scene ([SYS-028](SYSTEM_TODO.md#sys-028)). No reboot.

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

At the user's request, Ambilight now follows DP-1's content ([SYS-005](SYSTEM_TODO.md#sys-005)).
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
([SYS-008](SYSTEM_TODO.md#sys-008)). Built from a clean worktree of HEAD plus only
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

## [COMPLETED] Headless Moonshine installation — 2026-10-31

SYS-053. Installed latest upstream Moonshine commit 79554f8 (version 0.16.1)
with its NixOS module, headless Steam Big Picture, user lingering and input
permissions. Sunshine is declaratively disabled, masked and stopped; its
configuration and private credentials remain available for restoration.
Added moonshine group membership for streaming sleep inhibition.

Flake checks, dry build and full builds passed against installed package
pins in `/tmp/moonshine-system-build`, excluding the separate SYS-051 update.
Generation 230 was the recovery baseline; no failed units, expected root/ESP
UUIDs and EFI entries verified. Snapper absent; created and verified readonly
snapshot `/btrfs-top/nixos-root-pre-moonshine-20261031` before activation.
Test activation passed. With daemon stopped, a fresh user process passed all
Moonshine health checks: Vulkan RTX 4090, H.264/HEVC/AV1 including 10-bit,
DMA-BUF, WSI layer, Xwayland, sleep inhibition, ports, uinput/uhid and headless
controller permissions. Restarted daemon; pairing page returns HTTP 200.

Persistent switch succeeded as generation 231:
`/nix/store/29ip1vzh55lk6db7bxrf77f0cddy78yw-nixos-system-erebor-26.05.20261025.1f607aa`.
Moonshine active/enabled; Sunshine inactive/masked; no failed system/user
units. Root/ESP UUIDs and EFI boot order unchanged; GRUB includes 231 and
recovery 230 plus Windows. No reboot performed. Client pairing, an actual
stream and operation while logged out remain untested; service dependencies
and lingering provide the headless startup configuration. Pairing URL:
http://localhost:47989/pin; LAN host 192.168.1.106.

SYS-051 working-tree package-update edits remain untouched and uncommitted;
this implementation commit uses the installed pins plus the Moonshine input.

## [COMPLETED] qBittorrent external disk write access — 2026-10-30

SYS-052. User requested write access to all four external disks. Container
bindings are now rw; Seagate, Expansion and BigDaddy host mounts are rw,
and BigDaddy crypttab no longer requests readonly. BigDaddy filesystem root
ownership changed non-recursively from root:root to UID/GID 1000:1000 (0755).
Other containers retain readonly bindings. Download defaults are unchanged.

Flake check and full build passed using the installed package pins. Before
activation: generation 229, no failed units, correct filesystem UUIDs and
recovery boot entries verified. Snapper is absent; created and verified ro=true
Btrfs root snapshot `/btrfs-top/nixos-root-pre-qbit-write-20261030`.
It protects system configuration, not external data. BigDaddy refresh retained
readonly, so stopped qBittorrent/Jellyfin/Nextcloud briefly and reopened the
mapping through the updated crypttab. Initial activation reported Jellyfin's
startup health probe; its subsequent health check and repeated test activation
passed. No filesystem repair or recursive permission changes were performed.

Persistent activation succeeded as generation 230:
`/nix/store/m5pv1n6dkm99i5hflg8zlj6lfn8yh0wc-nixos-system-erebor-26.05.20261025.1f607aa`.
All four disks passed actual temporary-file create/read/delete inside
qBittorrent as UID/GID 1000:1000. BigDaddy mapping reports read/write; all
host mounts are rw with expected UUIDs. qBittorrent UI and Jellyfin health
return HTTP 200; Nextcloud reports installed, maintenance=false and no database
upgrade needed. No failed system/user units. EFI entries unchanged; GRUB has
230, recovery 229, Windows and systemd-boot recovery. No reboot performed;
boot persistence is configured but not reboot-tested.

The separate SYS-051 package-update edits were restored after activation and
remain uncommitted. Package cleanup still awaits authorization.

## [PREPARED] System package update — 2026-10-30

SYS-051. Refreshed flake inputs on their configured release branches, including
nixos-26.05 revision `6f06d204d8f2d8761d9da78778745974a3216381`.
Removed the obsolete Zen 1.23.3b checksum override for upstream 1.24b.
`nix flake check` and `nixos-rebuild dry-build` passed after these changes.
Full build not started: dry build needs 8.3 GiB download / 26.3 GiB unpacked,
plus local build space; only 19 GiB is free. Inspected unreferenced Nix store
paths (approximately 27 GiB NAR size, not a guarantee of reclaimable space).
Cleanup awaits user authorization. Sudo hardware authentication was unavailable
and the password prompt was cancelled. No activation or reboot occurred.

At preparation time, live and persistent system was generation 229,
`/nix/store/nq6ijf3z53fvn201nzr15as2p2l7paxm-nixos-system-erebor-26.05.20261025.1f607aa`.
No failed system or user units. Root UUID and ESP mount match configuration;
GRUB retains generation 229 and 227 entries. Snapper is not configured;
existing Btrfs recovery snapshots remain present. Before activation, recheck
state and create/verify the applicable recovery checkpoint. No boot files,
firmware settings, generations or snapshots were changed. Prepared edits remain
uncommitted pending build and activation verification.

## [COMPLETED] AI chat through Caddy — 2026-10-27

SYS-050. Add Open WebUI to the existing wildcard HTTPS reverse proxy and
configure its public URL. Prechecks: generation 228, no failed units and
unchanged root/srv/ESP UUIDs. Main AI hostname resolves to Tailscale IP
100.108.216.80. No boot, storage or firewall configuration was changed.

Flake check, dry/full builds, test activation and persistent activation passed.
Generation 229 is
`/nix/store/nq6ijf3z53fvn201nzr15as2p2l7paxm-nixos-system-erebor-26.05.20261025.1f607aa`.
The main HTTPS URL serves the UI (HTTP 200), health returns true, the browser
shows the sign-in page and WebSocket upgrade returns HTTP 101 through Caddy.
Caddy/Open WebUI/Ollama/SearXNG are active; no units failed and mount UUIDs
are unchanged. Open WebUI retains account authentication and loopback binding.
The Moria alias passes HTTPS health with a local resolve override, but its DNS
points to a different Tailscale host (100.98.112.118); no DNS changes were made.
Authenticated chat remains a user first-use check as recorded in SYS-049.

## [COMPLETED] Local GPU chat and web search — 2026-10-27

SYS-049. User requested a local model fitting the RTX 4090 with useful context,
reduced refusals and web search. Configure Ollama/CUDA, Huihui Qwen3.5 27B
abliterated Q4_K_M, Open WebUI and SearXNG, all on loopback. Start at 32768
tokens, q8_0 cache and one concurrent request. Host-generated SearXNG secret
stays outside Git and the Nix store.

Prechecks: generation 227, NVIDIA 4090 24564 MiB (205 MiB in use), 28 GiB
available RAM, 46 GiB free filesystem space and no failed system units.
Root/srv UUID is `5be9be17-20c9-4a47-ba2d-6adf1ceb4c55`; ESP UUID is
`38B5-8386`. No storage, bootloader, driver or initrd changes are planned.
Flake check, dry and full build passed. CUDA compilation is limited to Ada
SM 89. Initial inference fell back to CPU because the initrd-loaded driver
had not loaded UVM; loading `nvidia_uvm` and restarting Ollama restored CUDA.
Declare that module for stage 2 so subsequent boots also support CUDA.

Test activation succeeded. Model `e9ff39f1ea00` downloaded and ran at 32768
context entirely on GPU. Short coding response: 49.9 tokens/s, total GPU use
18212 MiB. A 28932-token prompt recalled its initial marker correctly without
truncation, with GPU use 18220 MiB. SearXNG's default engines hit rate limits
or CAPTCHAs; configure verified Bing, returning 10 live results without errors.
Open WebUI health and browser welcome/sign-in page passed; first account
creation and authenticated UI chat remain user first-use actions.

Final test and persistent activation succeeded as generation 228,
`/nix/store/iiarnjr4rmdyi35pybcx97mvxnpd98nb-nixos-system-erebor-26.05.20261025.1f607aa`.
All three services are active, Open WebUI health passes and its stored search
configuration enables SearXNG at the intended local URL. All listeners are
loopback-only. No system units failed and root/srv/ESP UUIDs are unchanged.
Generation 227 remains available for recovery. No reboot was performed;
automatic UVM loading after a future reboot is declared but not boot-tested.
Authenticated chat/search inside the UI remains untested until the user
creates their own local account. Backend inference/search and UI startup were
verified independently; this does not claim that first-use acceptance.

## [COMPLETED] Restore proprietary NVIDIA graphics and 165 Hz mode — 2026-10-26

SYS-048. Linux 7.3/Nouveau completed successfully but still exposed only
3440×1440 at 59.973/99.982 Hz. At user request, restore the known-good
proprietary NVIDIA 615.78.08 module, CUDA/NVENC Sunshine support, and the
stable kernel package (Linux 6.18.57) that previously built with this driver.

Checkpoint: generation 226 is current on Linux 7.3; Nouveau, the graphical
session, Sunshine and xremap are healthy, and no units have failed. Root is
Btrfs UUID `5be9be17-20c9-4a47-ba2d-6adf1ceb4c55`, ESP is UUID `38B5-8386`;
Snapper is not installed. No Fedora, Windows, EFI entry, partition or filesystem
change is planned. Recovery is selecting generation 226 in GRUB. Next safe
steps: flake/dry/full builds, test and switch activation, then reboot and
verify NVIDIA, the DP-1 164.9 Hz mode, Vulkan and services.

`nix flake check`, dry build and full build passed. Test activation completed
with graphical-session, Sunshine and xremap active and no failed units. Polkit
successfully switched generation 227; its GRUB entry uses Linux 6.18.57 and
`nvidia_drm.modeset=1`, while generation 226 remains available.

Reboot checkpoint read back: generation 227 targeted
`/nix/store/7qcrk2i3j37p1jhzi7l6j1l6hwh3cpm1-nixos-system-erebor-26.05.20261025.1f607aa`.
Root and ESP UUIDs are unchanged; Snapper is not installed and no units have
failed. At that checkpoint, the proprietary driver and 165 Hz mode needed
boot-time validation; recovery was selecting generation 226 in GRUB.

Reboot succeeded at 22:56 CET into generation 227 on Linux 6.18.57. The RTX
4090 uses the NVIDIA kernel driver and `nvidia-smi` reports 615.78.08.
`vulkaninfo` reports the NVIDIA proprietary Vulkan driver. DP-1 exposes and is
running at 3440×1440@164.900 Hz. Graphical-session, Sunshine and xremap are
active with no failed units. Jellyfin's initial transient health check cleared
after normal startup; the service is active and advertises CUDA/NVENC codecs.
Generation 226 remains the GRUB rollback option.

## [COMPLETED] Test Linux 7.3 for Nouveau DP-1 high refresh — 2026-10-26

SYS-047. The Dell AW3423DWF's configured 3440×1440@164.899994 mode is absent
from its active Nouveau mode list on Linux 6.18.57, which instead exposes
59.973 and 99.982 Hz and is running at 99.982 Hz. Request: test the current
mainline Linux 7.3 package already provided by the pinned Nixpkgs channel,
without moving the full system to unstable.

Checkpoint: generation 225 is current and healthy, on kernel 6.18.57; no
failed units; root is Btrfs UUID `5be9be17-20c9-4a47-ba2d-6adf1ceb4c55` and the
ESP is UUID `38B5-8386`. Snapper is not installed, so no snapshot applies.
The sole configuration change selects `pkgs.linuxPackages_latest` (Linux 7.3).
No Fedora, Windows, boot selection, EFI entry, partition, or filesystem change
is planned. Recovery: select GRUB generation 225. Next safe steps: flake/dry/
full builds, test and switch activation, then reboot and inspect DP-1 modes.

`nix flake check`, dry build and full build passed. Test activation completed
with graphical-session, Sunshine and xremap active and no failed units. The
Linux 7.3 generation was then switched persistently as generation 226; GRUB
contains its `linux-7.3` entry and preserves generation 225.

Reboot checkpoint read back: generation 226 targets
`/nix/store/ikp60smy77vgz9gq90k8q2xd60vwl9pc-nixos-system-erebor-26.05.20261025.1f607aa`
on Linux 7.3. Root and ESP UUIDs are unchanged; no failed units. Snapper is
not installed. Risk: Nouveau may still only expose 100 Hz and the graphical
session must be checked after boot. Mandatory next action: reboot into
generation 226, inspect DP-1's available/current modes and service health;
select generation 225 from GRUB if the session fails.

Reboot succeeded at 22:49 CET into Linux 7.3.0 and generation 226. The RTX
4090 remains driven by Nouveau; graphical-session, Sunshine and xremap are
active with no failed units. DP-1 still exposes only 3440×1440 at 59.973 Hz
and 99.982 Hz, with 99.982 Hz current. Therefore Linux 7.3 does not restore
the AW3423DWF's configured 164.899994 Hz mode under Nouveau/NVK. Generation
225 (Linux 6.18.57) remains available in GRUB; it has the same 100 Hz limit.

## [COMPLETED] Update NixOS pin and move the RTX 4090 to NVK/Nouveau — 2026-10-26

SYS-045. Requested change: update the NixOS channel pin and replace the
proprietary NVIDIA 615.78.08 stack with Nouveau/NVK for the Ada RTX 4090. The
new pin is `nixos-26.05` revision `1f607aa` (2026-10-25), whose selected kernel
remains Linux 6.18.57; there is no newer kernel in that channel revision.
Configuration enables Nouveau GSP (`nouveau.config=NvGspRm=1`), keeps
redistributable firmware enabled, blacklists proprietary NVIDIA modules, and
uses Sunshine's CPU encoder because NVENC/CUDA is unavailable with NVK.

Initial checkpoint before build/activation: generation 224 was current; root is Btrfs
UUID `5be9be17-20c9-4a47-ba2d-6adf1ceb4c55` and ESP is UUID `38B5-8386`; no
failed units. Snapper is not installed, so no snapshot is applicable.
`nix flake check` and `nixos-rebuild dry-build --flake .#moria` passed. Recovery
is selecting generation 224 from GRUB. Full build and `nixos-rebuild test`
passed; generation 225 was switched successfully, with Sunshine and xremap
active and no failed units.

Reboot checkpoint read back: current generation was 225
(`/nix/store/cvjqkhxlsvy49whj8ii0ldblaxnmxcf9-nixos-system-erebor-26.05.20261025.1f607aa`);
root and ESP UUIDs were unchanged. At that checkpoint, graphical output, Vulkan,
and Sunshine's non-NVENC streaming remained unverified. Recovery if the reboot
failed was selecting generation 224 from GRUB.

Reboot succeeded at 22:37 CET into generation 225. `lspci` reports the RTX 4090
kernel driver as Nouveau; kernel logs confirm AD102 GSP firmware 570.144,
24,564 MiB VRAM and the Nouveau framebuffer. `vulkaninfo --summary` reports
`NVIDIA GeForce RTX 4090 (NVK AD102)`, Mesa 26.1.8 and Vulkan API 1.4.354.
The user graphical-session target, Sunshine and xremap are active; no failed
units remain. An initial Jellyfin health-check fired before its normal startup
completed but subsequently cleared; Jellyfin remained active. Actual Sunshine
streaming and any CUDA/NVENC-based workload remain acceptance work in SYS-046.


## [COMPLETED] Confirm NixOS without waiting for NanoKVM power sampling — 2026-10-25

SYS-044. Added no-store `GET /api/control/os`, identifying NixOS from the host
OS release without device queries. The browser probes it alongside NanoKVM;
a fresh positive response immediately enables the NixOS header, controls and
service links, and prevents Wake. The tooltip distinguishes API confirmation
from the ongoing LED reading. Failed/non-NixOS responses fall back to NanoKVM;
offline/visibility changes clear confirmation and cancelled replies are ignored.
The existing four-second GPIO sampling, independent Windows detection and ATX
guards are unchanged. Submodule `6225bab` committed and pushed.

Thirty API tests, standalone/parent flake checks, dry/full builds and browser
checks passed. Measured initial live navigation-to-availability at 6562ms on
generation 223, versus 226ms after test activation and 194ms after switch;
identity endpoint round trip measured 2ms on this connection. Mocked slow-KVM
test confirmed NixOS availability in 112ms before a 6.5s independent response.
Verified failed periodic refresh removes direct confirmation, Windows/unknown
fallback and action/service gating, cancelled late responses, offline/reconnect,
confirmation/send guards, service navigation and responsive cached-PWA behavior.
Live HTTPS before and after switch verified actual OS/header/API agreement,
uncached identity, mocked Windows fallback/gating, restoration and offline PWA.

Test activation and switch passed as generation 224:
`/nix/store/j8nch6f22l79x7aj2vws2pv1cppql68c-nixos-system-erebor-26.05.20261021.da6dc0e`.
Caddy/control active, no failed units; root/ESP UUIDs unchanged. No reboot or
real host-control action issued. Recovery: generation 223. Native Windows boot
acceptance remains SYS-043; these timings describe this local connection.

## [COMPLETED] Gate service navigation by detected OS — 2026-10-25

SYS-042 extension. Service cards now share the host-action OS availability rule:
only confirmed awake NixOS enables them. Windows/unknown/checking/unavailable,
sleep and off disable Material links, remove href attributes, exclude them from
keyboard navigation and dim their appearance. Positive NixOS detection restores
links automatically. Dashboard submodule `71b9f94` committed and pushed.

Standalone/parent flake checks, dry/full builds and browser checks passed.
Verified href removal, disabled/click/keyboard behavior for unavailable states,
restoration on NixOS, existing control/confirmation guards, cached PWA with the
host unavailable, offline reload and 320–1000px layouts. Test activation and
switch passed as generation 223:
`/nix/store/0mn9klxvdrizzbfl538abc2qwkliik9r-nixos-system-erebor-26.05.20261021.da6dc0e`.
Live HTTPS before switch verified actual NixOS detection/polling plus simulated
Windows/unknown disabled links and recovery; post-switch verified actual NixOS
status, enabled links/controls, disabled wake and offline reload. Caddy/control
active; no failed units; root/ESP UUIDs unchanged. No real host control commands
or reboot issued. Native Windows acceptance remains SYS-043. Recovery: prior
verified generation 222; NanoKVM helper/config unchanged by this extension.

## [COMPLETED] Detect running OS and gate unsupported dashboard actions — 2026-10-25

SYS-042; live Windows acceptance remains SYS-043. NanoKVM verifies pinned native
NixOS/Windows Tailscale node IDs, addresses and OS metadata, then requests fresh
TSMP replies through tailscaled’s local Unix socket. Exactly one responding OS
is shown beside power; missing/conflicting replies show unknown. User confirmed
the native Windows identity and that the new display works. The separate Windows
VM identity is excluded. CLI-based probes initially exceeded device timeouts;
the deployed socket client avoids that startup overhead and passed live checks.
Helper/config source hashes match the remote files; prior copies retained at
`/opt/erebor-wake/pre-os-detection-20261025/` for recovery.

All host API actions require positively detected awake NixOS in the UI,
confirmation and send handlers. Windows/unknown/checking/unavailable/sleep/off
disable them. Wake remains independently governed by the power LED. The cached
PWA can show Windows while the NixOS web server is unavailable.
Dashboard submodule `9dae50f` committed and pushed to the existing private origin.

Standalone and parent flake checks, dry/full builds, 18 GPIO/identity/probe/HTTP
tests and browser checks passed. Browser coverage includes NixOS/Windows/unknown,
all power states, no stale OS on failed reads, disabled controls, forced click
and confirmation-time OS-change guards, a supported mocked NixOS action,
cached-shell Windows with unavailable host, offline reload and 320–1000px layout.
Test activation and switch succeeded as generation 222:
`/nix/store/y1cs4mlni31d5jqsmapn8f0xffn747zg-nixos-system-erebor-26.05.20261021.da6dc0e`.
Live HTTPS before switch verified actual NixOS detection/polling, mocked
Windows/unknown gating, NixOS controls and offline reload on both virtual hosts;
moria was mapped to this host as in SYS-039. Post-switch erebor checks verified
actual OS/API/header agreement, enabled NixOS controls, disabled wake and offline
reload. Caddy/control active, no failed units, root/ESP UUIDs unchanged, preserved
Windows/systemd-boot EFI files present. No reboot or physical ATX/control action
was issued. Real Windows boot detection remains untested (SYS-043).

## [COMPLETED] Show header power LED and gate wake by detected state — 2026-10-25

SYS-041. Moved existing NanoKVM status beside the host name as a colored LED,
readable label and detail tooltip; removed the duplicate System card. Green
awake, amber asleep, red off, gray unknown/unavailable. Wake up now enables only
for confirmed asleep/off; checking, awake, unknown and unavailable disable it.
Backend ATX checks are unchanged. Dashboard submodule `0fdb404` committed and
pushed to the existing private origin, including the previously local wake
revision so clean parent flake fetches can resolve the referenced submodule.

Standalone/parent flake checks, dry-build/full build and mocked browser checks
passed: all power states and corresponding wake availability, header placement,
absence of duplicate card, 320–1000px layouts, wake response/error handling and
offline/unreachable-host reload. Inspected the rendered LED layout. Test
activation and switch passed as generation 221:
`/nix/store/d1r8bnjf3yki6bwglcbawcdzr1944hv8-nixos-system-erebor-26.05.20261021.da6dc0e`.
Live HTTPS browser checks before and after switch verified the header state,
disabled wake while awake, NanoKVM cross-origin health, rejection of incomplete
wake requests and offline reload. Tested erebor directly and moria's virtual
host mapped to this host, as noted in SYS-039. Caddy/control active; no failed
units; root/ESP UUIDs unchanged. No physical ATX or sleep commands issued;
physical acceptance remains SYS-040.

## [COMPLETED] Add NanoKVM ATX wake and power status — 2026-10-25

SYS-039; physical acceptance SYS-040. Added direct HTTPS Wake up action and
independent LED-based awake/asleep/off status. Wake up is disabled while awake;
unreachable NanoKVM is shown as unavailable. The cached PWA falls back within
2.5s when the host is unreachable and waits for API recovery after waking.
Dashboard submodule committed locally as `978d1c3`.

On NanoKVM PCIe `kvm-37ff`, deployed the helper under `/opt/erebor-wake`,
`/etc/init.d/S99erebor-wake`, and private Tailscale Serve HTTPS on port 8443
forwarding to loopback 18091. Host-specific config source:
`modules/dashboard-control/nanokvm-wake.json`. Only the owner's Tailscale
identity may access it; wake additionally requires an exact dashboard origin,
JSON and a custom header. Fixed 200ms press, four-second steady-on LED guard,
30s cooldown, request lock, fail-closed GPIO reads, and graceful termination.
No NanoKVM passwords or tokens are stored in frontend configuration.

Standalone/parent flake checks, parent dry-build/full build and eleven mocked
GPIO/HTTP tests passed. Browser checks covered all LED states, awake button
disabling, wake request/result handling, cooldown/errors, offline reload,
cached shell with unreachable host, and 320–1000px layouts. Live test activation
and switch passed as generation 220:
`/nix/store/3paabx0ayp0gzsjc6iqmgjl9zji5vvbm-nixos-system-erebor-26.05.20261021.da6dc0e`.
Before and after switch, HTTPS browser checks verified real cross-origin
NanoKVM identity/health/status, awake button disabling, rejection of incomplete
wake requests and offline reload. `erebor.jzon.pl` was tested directly;
`moria.jzon.pl` virtual host was mapped to the current host for verification
because its normal DNS points to the old offline Tailscale address.

Caddy/control active, no failed units, root/ESP UUIDs unchanged. Remote source
hashes matched the committed helper/init script; helper restart and Serve
persistence configuration verified. No reboot, suspend or physical ATX press
was issued. Real sleep LED pattern and sleep/off wake remain untested (SYS-040).
Recovery: previous generation; disable NanoKVM proxy with
`tailscale serve --https=8443 off` and stop its init script.

## [COMPLETED] Integrate device status and actions — 2026-10-25

SYS-038. Display and Ambilight each have one card containing live state,
explanation and on/off controls, highlighting the reported on/off state.
Only configured device actions appear; system actions remain below. Preserved
polling, post-command refresh, mixed/unknown states and offline handling.
Dashboard submodule `db83588` committed and pushed.

Standalone and parent flake checks, parent dry-build and full build passed.
Mocked HTTP/browser checks verified grouping, state highlighting, command
readback, periodic refresh, partial/failing status, offline recovery and
320–1000px layouts. Test activation and switch succeeded as generation 219:
`/nix/store/v6rziw4iikandznk04lb6pdgxa1xi3k5-nixos-system-erebor-26.05.20261021.da6dc0e`.
Live HTTPS checks on both domains passed before and after switch, including
API/UI agreement, periodic polling and PWA offline reload/reconnect. Caddy and
control service active, no failed units; root/ESP UUIDs unchanged. No reboot
or real device control commands during verification.

## [COMPLETED] Show live display and Ambilight status — 2026-10-25

SYS-036. Activated the status feature preserved in SYS-037's extracted
`apps/erebor-dashboard` submodule (`86dc07f`). Read-only GET /api/control/status
returns independent display/Ambilight state and explanations, with no-store.
Display reads compositor-reported power, excluding ambilight/sunshine capture
outputs; missing/unsupported reporting yields Unknown. Ambilight combines WLED
power/brightness/realtime override with HyperHDR LED/master-output state, with
Mixed for inconsistent components and Unknown for missing readings. This reports
software/device state, not independent measurement of panel power or LED light.
Angular polls every 10 seconds while visible, refreshes after controls, and
clears stale status on failures, offline transitions and visibility changes.

Twenty-nine shared API/status tests plus nine host-helper tests passed. Browser
with real HTTP and mocked hardware checked initial state, post-command readback,
periodic refresh, mixed/partial failure, failed request clearing stale data,
offline/online recovery and 320–1000px layout. Parent flake check, dry-build and
full build passed. Test activation, live HTTPS checks, switch and repeat checks
passed as generation 218, live and selected target:
`/nix/store/mqh95gywc83lc2wypadv7mhj7v5n5gbk-nixos-system-erebor-26.05.20261021.da6dc0e`.
On both erebor/moria domains the browser UI matched the API, periodic reads were
observed, and offline PWA reload including configuration showed Offline rather
than cached live states, then recovered on reconnect. Observed Display Off (two
physical outputs), initially Ambilight Off and later On with an active live
stream. Validation issued no actual control commands.
Caddy/control service active, no failed system/user units; boot environment and
protected EFI hashes, firmware entries/order and filesystem UUIDs unchanged.
No reboot. Parent source extraction is now activated as part of this deployment.

## [COMPLETED] Extract dashboard into private submodule and Nix packages — 2026-10-25

SYS-037. Created and pushed private `question44/erebor-dashboard` at `86dc07f`;
registered it as `apps/erebor-dashboard`. Parent flake includes submodules and
uses a relative path input following its existing nixpkgs. Shared outputs expose
frontend/control packages, an overlay and an optional NixOS module. Dashboard
branding, links, allowed hosts, actions, desktop packages and WLED address are
configured by the parent. Existing Caddy network restrictions and privileged
Windows helper/Polkit rule remain in the host repository. Shared controls default
to no permitted actions. README documents private SSH access, package/module use
and submodule updates. Preserved the concurrent SYS-036 status work and tests in
the extracted source; its activation acceptance remains open.

Validation: standalone flake check built frontend and control with 29 mocked API
and status tests; 9 host Windows-helper tests passed. Direct private GitHub SSH
package build and a fresh recursive clone/parent flake check succeeded.
Parent flake check, nixos-rebuild dry-build and full
build passed, producing
`/nix/store/mqh95gywc83lc2wypadv7mhj7v5n5gbk-nixos-system-erebor-26.05.20261021.da6dc0e`.
Chromium checked eight local service links, seven mocked actions, status updates,
confirmation/cancel, 320/600/1000px layouts and offline reload including config.
No actual power, display, lighting or boot commands were issued. x86_64-linux
was built; aarch64-linux is declared but untested. Original ignored frontend
build artifacts were preserved at
`/tmp/dashboard-pre-extraction-20261025/frontend-build-artifacts`.

Source/package scope only: no activation. Live system remains generation 217,
`/nix/store/dvwf74v5i17pwi7sz0j7a38j9bkw25w8-nixos-system-erebor-26.05.20261021.da6dc0e`;
Caddy and the existing control service were active with no failed units during
inspection. A future deployment needs normal sudo authentication and live
verification; interactive sudo was not attempted for this source-only task.

## [COMPLETED] Migrate dashboard control API to FastAPI — 2026-10-25

SYS-035. Replaced stdlib HTTP server with FastAPI/Pydantic and loopback Uvicorn,
using dependencies from the locked Nixpkgs (FastAPI 0.136.3, Uvicorn 0.40.0 as
built). Retained /api/control, all action implementations, the root Windows
helper, same-origin/header checks, private-network Caddy boundary, 256-byte
request limit and no-store JSON responses. Middleware checks the boundary
before body parsing and counts streamed bytes, rejecting size mismatches.
Typed commands reject extra fields; invalid input keeps 400/error responses,
and unsupported methods now return 405. Synchronous action execution uses the
framework thread pool. Added generated schema and Swagger UI at
/api/control/openapi.json and /api/control/docs through the existing proxy.

Twenty-four backend tests passed, including all action dispatch, malformed
JSON/types, origin/header rejection, duplicate Origin, declared/streamed body
limits, response contract and Windows helper safety tests. Chromium exercised
all seven Angular controls through real Uvicorn HTTP with dispatch mocked;
no actual commands were issued. Flake check, dry-build and full build passed.
Test activation and persistent switch passed as generation 217:
`/nix/store/dvwf74v5i17pwi7sz0j7a38j9bkw25w8-nixos-system-erebor-26.05.20261021.da6dc0e`.
Before/after switch, live HTTPS on both domains returned schema/docs 200,
valid-origin invalid-action 400, cross-origin 403 and GET control 405; no
executable action sent. Browser verified dashboard links, confirmation cancel
and controlling PWA worker. Listener remains 127.0.0.1:18090; Caddy/control
service healthy, no failed system/user units. Boot environment/protected EFI
hashes, firmware entries/order and filesystem UUIDs unchanged. No reboot.

## [COMPLETED] Add Windows reboot dashboard button — 2026-10-25

SYS-034. Added Reboot to Windows quick action with save-work/next-boot-only
confirmation. A fixed root oneshot service checks root/ESP UUIDs, Windows and
recovery EFI loaders, the existing GRUB Windows entry and one-time handling,
and refuses any already-pending selection. Sets only `next_entry`, verifies and
syncs it, then calls login1 RebootWithFlags with inhibitor checking. Failed reboot
requests clear the one-time selection. Polkit permits janzon only the fixed
service start; API remains behind the existing same-origin/private-network
boundary. Service has no automatic start dependency and only grubenv writable.

Seventeen backend tests passed, including request validation, wrong filesystems,
missing loaders, pending selection, dispatch and rollback. Real grub-editenv
on a temporary file verified preservation of saved_entry and rollback after a
mocked reboot refusal. Browser checks verified seven controls, Cancel focus,
cancel sends nothing, confirm sends only mocked Windows action, responsive
320–1000px layout, and existing install/offline behavior. Flake/dry/full builds
passed. Test activation, live HTTPS browser checks, switch and repeat checks
passed as generation 215:
`/nix/store/lz7r7i05kklkapsn9rh13fj4f4x8qps3-nixos-system-erebor-26.05.20261021.da6dc0e`.
Read-only helper preconditions passed; root pkcheck verified authorization for
the actual user control-service PID without starting the reboot service.
Caddy/control service healthy, no failed system/user units. Helper never ran a
reboot; actual Windows boot is untested. Live grubenv and protected Windows/
systemd-boot EFI hashes, firmware entries/order and root/ESP UUIDs unchanged.
Snapper is not configured; no material bootloader change or reboot performed.

## [COMPLETED] Migrate service dashboard to Angular — 2026-10-24

SYS-033. Replaced React/Material UI with standalone Angular 22.2.3 and Angular
Material 22.2.4, strict TypeScript/templates and Angular CLI production build.
Retained eight service links, six quick controls, confirmations, light/dark
layout, install prompt and the existing versioned offline shell worker. Cockpit
remains a service link; embedding is outside this migration. Disabled CLI
analytics and patched the embedded Sass compiler's loader for the Nix build.

Flake check, nixos-rebuild dry-build, full system build and Caddy adapt passed.
Chromium verified rendering, links, responsive layout, dark mode, install prompt
callback, initial Cancel focus, confirmation/cancellation, mocked control API
headers/results/errors, cached offline reload and disabled offline controls.
No actual control commands were issued. Local and Nix-built JS/CSS match.
Test activation followed by live HTTPS checks on erebor/moria domains passed;
persistent switch and repeat HTTPS checks passed as generation 214:
`/nix/store/8x9jz6ny0v4nq6jyskldl2y9jwrpqfkq-nixos-system-erebor-26.05.20261021.da6dc0e`.
Live HTML/worker match built output; worker controls the page after reload.
Caddy active, no failed system/user units, root/ESP UUIDs and firmware boot order
unchanged. No reboot. Physical device installation was not performed.

## [COMPLETED] Add HyperHDR dashboard card — 2026-10-24

SYS-032. Added HyperHDR to the dashboard index with the existing lighting
icon, HTTPS subdomain link and port 8090 fallback for local/IP access.
Flake check/full build passed. Test activation and persistent switch succeeded
as generation 213, live/selected target:
`/nix/store/8xdd0crkimpr4sp42z3sr9pawk52ck4a-nixos-system-erebor-26.05.20261021.da6dc0e`.
Browser verified rendered card, correct https://hyperhdr.erebor.jzon.pl link,
and click navigation to HyperHDR Web Configuration. Card remains present after
switch/reload with the PWA worker active. Caddy active, no failed system/user
units, root/ESP UUIDs unchanged. No reboot or lighting changes performed.

## [COMPLETED] Add HyperHDR to Caddy — 2026-10-24

SYS-031. Added hyperhdr.localhost/hyperhdr HTTP aliases and
hyperhdr.{erebor,moria}.jzon.pl HTTPS routes to 127.0.0.1:8090 using
existing wildcard certificates. Flake check, dry-build, full build and Caddy
adapt passed. Upstream UI returned 200 and WebSocket handshake returned 101.
Built target: /nix/store/ffmjc84p2rmkks0ildkjh6ab729x2dsh-nixos-system-erebor-26.05.20261021.da6dc0e.

Initial unanswered authentication was cancelled. On the user's subsequent
Apply request, test activation succeeded. Local aliases return HTTP 200;
both HTTPS names return 200 with verified certificates and WebSocket 101
through loopback Caddy. Tailnet https://hyperhdr.erebor.jzon.pl returns 200.
Caddy/HyperHDR active; no failed system/user units. Subsequent persistent
switch succeeded as generation 212; live and selected store targets both match
the checked build above. HTTPS tailnet UI still returns 200 after switch.
Root/ESP UUIDs unchanged and GRUB configuration present. No reboot performed.
SYS-031 complete. Both hostname routes verified locally; remote moria DNS
resolves to another tailnet address, so end-to-end access was checked via erebor.

## [COMPLETED] Enable service dashboard PWA and Material UI — 2026-10-24

SYS-030. Added installable standalone PWA manifest, mountain icons and install
UI. Rebuilt dashboard with Material UI 9.5.0 (npm latest stable when checked),
React 19.3.1 and Vite 8.3.5, locked dependencies and a fixed-hash Nix npm build.
Caddy serves locally bundled assets. Six icon quick actions precede service
cards; Material confirmation dialogs retain sleep/power-off confirmation.
API headers/body, service links and offline disabling preserved. Generated
service worker versions its shell cache from build contents; caches the bundle,
manifest and icons, while API and linked services remain network-only.

Flake check, dry/full builds passed. Browser checks covered desktop/mobile
layout, mocked control requests and status, confirmation cancellation without
sending a request, disabled offline controls, and offline reload after stopping
the local server. No real control commands sent. Initial authentication attempts
stalled and were cancelled; a subsequent authentication check timed out. Later
live inspection found the exact validated build activated and persisted as
selected generation 211:
`/nix/store/8px1hmdb4ikr4qggwdaaxjsy1pasjsvj-nixos-system-erebor-26.05.20261021.da6dc0e`.

Post-activation checks: current and selected targets match; Caddy active, no
failed system/user units; root/ESP UUIDs unchanged. Served HTTPS HTML and worker
match the built package byte-for-byte. Browser verified Material components,
actions above services, 390px layout without overflow, correct HTTPS links,
active controlling worker, cached JS/icons/manifest and 200 icon responses.
Read-only recovery snapshot remains
`/btrfs-top/nixos-root-pre-dashboard-pwa-20261023` (ro=true verified).
No reboot or physical device installation tested. GRUB first-boot acceptance
remains tracked separately by SYS-029. SYS-030 complete.

## [COMPLETED] Install GRUB with current-wallpaper menu for next boot — 2026-10-23

SYS-029. Replaced the declarative systemd-boot selection with EFI GRUB, as
explicitly requested. Installed unmodified Pictures/redhead.png as static
menu wallpaper, matching dark plum panel/cream text/copper highlight, 20px
DejaVu Sans, five-second timeout, gfxmode=auto and explicit gfxpayload=keep.
Theme uses proportional crop to avoid stretching. Original desktop wallpaper
unchanged. No OS probing: explicit Windows and systemd-boot recovery entries
search ESP UUID 38B5-8386. Existing Plymouth BGRT/SimpleDRM retained.

Flake check and full build passed. Isolated UEFI GRUB/OVMF VM at 1920x1080
verified theme rendering/font/contrast; fixed palette PNG bit depth and layer
ordering before final build. Installed exact checked target
`/nix/store/ib34cmziqz3n7djjfmq95s4a04nzbgah-nixos-system-erebor-26.05.20261021.da6dc0e`
as selected generation 210 using profile selection and boot installation.
GRUB syntax check passed; first Linux entry points to that target and installed
kernel/initrd hashes match build. Installed theme files match repository assets.
`/boot/EFI/NixOS-boot/grubx64.efi` installed successfully. Firmware entry 0000
NixOS-boot is first in BootOrder, followed by all previous entries in unchanged
relative order; every previous firmware entry and all pre-existing EFI and
systemd-boot menu files passed preservation checks.

Snapper unavailable; verified read-only snapshot
`/btrfs-top/nixos-root-pre-grub-20261023`. Verified ESP archive, snapshot
metadata, boot-file hashes and firmware listings are under root-only
`/var/lib/system-recovery/grub-migration-20261023`. Root/ESP UUIDs match,
Secure Boot disabled, no failed system units; ESP has 4.5 GiB free after install.
Replaced deprecated pkgs.system with pkgs.stdenv.hostPlatform.system in
Darkly and Vicinae package selections after user reported evaluation warning.
Final flake check and rebuild pass without that warning and produce exactly
the installed target above; no further boot installation needed.
Live system remains generation 208 (`c7kdv0ai9w7fv9dhawd6p9b5db2i3gzw`);
no live activation, greeter restart or reboot performed.

Installation scope complete; physical GRUB boot/menu and graphics handoff
acceptance remain open in SYS-029. gfxpayload preserves mode, not guaranteed
pixels across NVIDIA takeover. Mandatory next check after user reboot: verify
BootCurrent=0000/GRUB and generation 210, wallpaper/menu readability, Linux
boot, Plymouth/login handoff and mounts/services. Recovery: GRUB systemd-boot
recovery entry or firmware Linux Boot Manager 0004; its preserved default
209 and generations 208/205 are available. Windows EFI/firmware entries retained;
chainloading is configured but not boot-tested. No automatic reboot queued.

## [COMPLETED] Remove temporary Plymouth diagnostics for next boot — 2026-10-23

SYS-027 visual acceptance passed on booted generation 208: user confirms
firmware logo visible and gap shorter or gone; greeter first-frame gap fell
from 7.60s to 1.69s. Removed only `plymouth.debug`, keeping BGRT, SimpleDRM
and greetd Type=exec. Flake check and full build passed; installed exact target
`/nix/store/c7wkmp5l6iwbir8lf6djh7ncz2c3p86q-nixos-system-erebor-26.05.20261021.da6dc0e`
as default generation 209 through profile selection and boot installation.
Verified no debug argument in the installed boot entry; kernel, initrd and
Plymouth configuration are identical to visually verified running 208.
Live system remains 208, with this boot's debug argument until next normal
reboot. No live greeter restart or reboot performed; no extra reboot required
for the completed visual acceptance. User-service duplicate startup remains
separately tracked by SYS-028; no failed system units.

Snapper unavailable; created and verified read-only root snapshot
`/btrfs-top/nixos-root-pre-plymouth-cleanup-20261023`. ESP backup and archived
generation 208 debug log, snapshot metadata, protected EFI checksums and
firmware listings are under `/var/lib/system-recovery/plymouth-cleanup-20261023`.
ESP comparison, protected EFI verification and firmware comparison passed;
root/ESP UUIDs match. Recovery entries 208 and 205 retained. Commit records
and configuration; no pending disruptive action or automatic reboot.

## [COMPLETED] Install BGRT logo and faster greeter startup for next boot — 2026-10-23

SYS-027. Switched Breeze to BGRT to reuse the valid firmware boot logo
(BGRT status=1); built theme sets UseFirmwareBackground=true. Retained
SimpleDRM and temporary debug logging. User confirmed the generation 207
splash was brief, followed by a black gap. Its journal shows Plymouth exit
at +10.97s and greeter first frame at +18.57s. Changed greetd Type=idle to
Type=exec to avoid systemd's possible five-second idle dispatch wait.
PAM, session commands and Plymouth quit ordering unchanged; a remaining
compositor/monitor transition delay is possible and unmeasured until reboot.

Flake check and nixos-rebuild build passed. Installed exact checked target
`/nix/store/c7kdv0ai9w7fv9dhawd6p9b5db2i3gzw-nixos-system-erebor-26.05.20261021.da6dc0e`
through system-profile selection and switch-to-configuration boot as default
generation 208. Verified built BGRT configuration and greetd Type=exec;
installed boot entry points to that target, with kernel/initrd bytes matching
the checked build. Live system remains generation 207
(`33pm8qsha1985gfmmkc8m1r4a1vzwa07`); no live activation, greeter restart or
reboot performed. No failed system/user units; expected root/ESP UUIDs mounted.

Snapper unavailable; created and verified read-only recovery snapshot
`/btrfs-top/nixos-root-pre-plymouth-bgrt-20261023`. ESP archive, snapshot
metadata, generation 207 debug log, protected EFI checksums and firmware
listings saved under root-only `/var/lib/system-recovery/plymouth-bgrt-20261023`.
ESP archive comparison, protected EFI hash verification and firmware
before/after comparison passed. Generations 207 and 205 remain available
for recovery; boot menu retains five-second timeout.

Installation scope complete; SYS-027 visual acceptance remains open.
Mandatory next check after user's reboot: confirm generation 208, vendor logo,
Plymouth/NVIDIA handoff, greeter startup/first-frame timing and mounts/services.
Compare against generation 207's 7.6-second gap; retain diagnostics until
acceptance, then remove the temporary debug parameter. No reboot is queued.

Post-reboot verification on 2026-10-23, boot ID
`2e850c38-ddb6-4026-ab55-86d289315a3d`: generation 208 booted/current,
BGRT/SimpleDRM active and greetd Type=exec. Plymouth quit at +11.158s;
greeter first frames at +12.848s/+12.922s. Primary-display gap decreased from
7.60s to 1.69s (about 5.9s shorter). User confirms manufacturer logo visible
and gap shorter or gone. Root/ESP UUIDs match, no failed system units. User
Noctalia service hit restart limit reporting another instance already running;
a separate Noctalia process is running. Track duplicate startup as SYS-028;
it does not invalidate the observed splash/login improvement.

## [COMPLETED] Install Plymouth SimpleDRM diagnostics for next boot — 2026-10-23

Enabled `UseSimpledrm=1` and temporary `plymouth.debug` for SYS-027 after
user reported black startup but visible shutdown splash. No ordering change.
Flake check and nixos-rebuild build passed. Installed exact checked target
`/nix/store/33pm8qsha1985gfmmkc8m1r4a1vzwa07-nixos-system-erebor-26.05.20261021.da6dc0e`
through system-profile selection and switch-to-configuration boot as default
generation 207. Built configuration contains UseSimpledrm=1; boot entry has
plymouth.debug, and installed kernel/initrd bytes match the checked build.
Live system remains generation 206 (`77kr8jfvqs5j6xsxp7dhcp3a5pbmqc3x`);
no live activation or reboot performed. No failed system/user units.

Snapper unavailable; created and verified read-only root snapshot
`/btrfs-top/nixos-root-pre-plymouth-simpledrm-20261023`. Verified ESP archive,
snapshot metadata, protected EFI hashes and before/after firmware listings
are under root-only `/var/lib/system-recovery/plymouth-simpledrm-20261023`.
Protected EFI checksums and firmware comparison passed. Root/ESP UUIDs match
expected filesystems; recovery entries 206 and 205 remain, with menu timeout
five seconds. Select 206 to undo this experiment or 205 to boot without Plymouth.

Installation scope complete; visual boot acceptance remains open in SYS-027.
Risk: SimpleDRM/NVIDIA handoff may still show black. Mandatory next check after
the user's reboot: confirm booted generation 207, splash visibility, display
handoff, mounts/services and `/var/log/plymouth-debug.log`; remove temporary
diagnostics after acceptance. No automatic reboot is queued.

Post-reboot validation on 2026-10-23 (boot ID
`48642c40-35fb-4ce2-9517-6c2d7edfac7f`): generation 207 is booted/current;
SimpleDRM and debug settings active, expected root/ESP UUIDs mounted. Debug
log confirms SimpleDRM splash scanout at +4.32s and successful NVIDIA scanout
on 1920x1080 and 3440x1440 outputs by +6.72s, after an initial no-heads retry.
Plymouth exited before greetd at +10.97s and user session started. Initrd XKB
lookup errors did not prevent renderer startup. Initial Jellyfin healthcheck
failure recovered automatically (healthy, exit 0); no failed user units.
Visual acceptance remains pending in SYS-027; debug logging retained.

## [COMPLETED] Configure Plymouth Breeze for next boot — 2026-10-23

Enabled the NixOS Breeze splash with quiet kernel/initrd and early host NVIDIA
graphics. Flake check and full build passed; built theme is Breeze and kernel
parameters include quiet, splash and loglevel=0. Installed exact checked target
`/nix/store/77kr8jfvqs5j6xsxp7dhcp3a5pbmqc3x-nixos-system-erebor-26.05.20261021.da6dc0e`
using system-profile selection and switch-to-configuration boot. Default boot
entry is generation 206; its kernel/initrd bytes match the built files. Menu
retains its five-second timeout and generation 205 recovery entry. Current
live system remains generation 205; no reboot or live Plymouth start performed.

Before installation, created and verified read-only recovery snapshot
`/btrfs-top/nixos-root-pre-plymouth-20261023` (Snapper unavailable). ESP archive,
firmware listings, snapshot metadata and protected EFI checksum evidence are
under root-only `/var/lib/system-recovery/plymouth-20261023`. Protected EFI
hash checks and before/after firmware comparison passed; root/ESP UUIDs remain
`5be9be17-20c9-4a47-ba2d-6adf1ceb4c55` and `38B5-8386`. No failed system/user units.

Configuration is installed for next boot; splash visibility, NVIDIA handoff
and boot health await a separately authorized reboot, tracked by SYS-027.
Recovery: select generation 205 in systemd-boot. Esc toggles splash details;
adding plymouth.enable=0 when editing a boot entry disables Plymouth. Recheck
live generation, mounts/services and pending operations before any reboot.

## [COMPLETED] Replace nomacs with Gwenview as default image viewer — 2026-10-23

Removed nomacs from system packages and its theme activation hook. Set
Gwenview as default for 25 image MIME types, including prior nomacs formats
and Gwenview-advertised image types. Existing personal nomacs settings remain.
Flake checks and full builds passed for both removal and final associations;
test activation and persistent switches succeeded (removal: generation 204;
final: generation 205, `sd31ngbzkdl2x6hl90c5bhda38vav2nd`). Verified every image
default using xdg-mime, absent nomacs executable/desktop entry and references
in deployed mimeapps.list, successful Home Manager and no failed system/user
units. Root/ESP UUIDs remain correct; generation 205 is the default boot entry.
No reboot performed; opening an image in the GUI was not exercised.

## [COMPLETED] Finish Windows VM relocation to Crucial — 2026-10-23

SYS-022. User authorized completing the existing copy's relocation and removal
of the live original after verification. With windows11 shut off, qemu-img
compare of both 120 GiB qcow2 images returned "Images are identical" (exit 0).
Destination qcow2 checks before boot and after shutdown found no errors.
Changed only vda source to `/srv/external/crucial/windows11.qcow2` on verified
read-write exFAT UUID `604F-A363`; validated normalized XML equality for all
other settings. Domain XML/NVRAM/TPM retained under root-only
`/var/lib/windows-vm-recovery/crucial-relocation-20261023`.

Started Windows from Crucial and verified active/persistent path, guest-ping,
Windows OS/filesystem queries, LAN 192.168.1.120, Explorer session 1 via
read-only PowerShell (exit 0), visible desktop screenshot and no block errors.
Clean guest-agent shutdown completed. Rechecked shut-off state, destination
UUID and persistent path before unlinking only the live local original
`/var/lib/libvirt/images/windows11.qcow2`. VM remains shut off as before.
No failed host units. No GPU, partition, mount configuration or host reboot
changes made. Current flake check/dry-build passed; no Nix source edits or
host activation needed for the persistent libvirt disk change.

Important read-only pre-move root snapshot ID 657, UUID
`187eeff9-5699-2e4f-bf87-8e5efccd54a5`, verified ro=true; Snapper has no
configuration, so direct Btrfs snapshot used. Its original disk copy remains
at `/btrfs-top/nixos-root-pre-vm-crucial-20261023/var/lib/libvirt/images/windows11.qcow2`.
Btrfs filesystem du reports 110.37 GiB total, 0 exclusive, 110.37 GiB shared:
other recovery snapshots also retain this image. Main filesystem remains
about 63 GiB free; live-file removal does not reclaim those shared blocks.
Snapshot deletion was not authorized by this relocation and was not performed.
WINDOWS_VM.md now documents the current disk and the stale-path pitfall in
older saved XML. No outstanding acceptance check for this relocation.

## [COMPLETED] Increase Capitaine cursor size — 2026-10-23

Raised cursor size from 24 to 32 in Home Manager and Umbriel. Isolated flake
check, full system build and compositor validation passed. Concurrent system
activation included this change: verified current/default generation 203
(`/nix/store/anf91bq1l3bvh64pj38apgqbbk4p921v-nixos-system-erebor-26.05.20261021.da6dc0e`)
matches the working configuration. Deployed GTK 3/4 and Umbriel settings use
32, compositor reload succeeded, and system/user failed-unit lists are empty.
No reboot or session restart. Visual size preference awaits user observation.

## [COMPLETED] Add YubiKey touch notification and sound — 2026-10-23

SYS-026. Added graphical-session user service yubikey-touch-notify. It watches
pam-u2f's existing authpending file open/close events, shows a critical
persistent “Touch your YubiKey” notification, plays a short freedesktop sound,
and closes the notification when the wait ends. It also cleans up on service
stop. PAM authentication rules and credential files are unchanged; notifier
runs without privileges, with NoNewPrivileges and filesystem protections.

Flake check/full build passed; test activation used target
`ymw9f4xig0saryv0hf2wgvdil1bgl3ks`. Persistent switch activated generation 203,
`anf91bq1l3bvh64pj38apgqbbk4p921v`, including the concurrent cursor-size update;
that unrelated source edit is excluded from this commit. Rechecked the final
flake successfully. Current system/profile and boot default match generation
203, and the service is enabled and running. No failed system or user units.
Simulated open/close and actual sudo touch both created and dismissed the
notification; deployed-service journal records notification 1125 opening at
20:05:11 and closing at 20:05:13 Warsaw time, with sudo returning 0. User
explicitly confirmed seeing the prompt and hearing the sound during the real
preview sudo test. No reboot or logout needed. Generation 202 remains available
for rollback; pre-retirement read-only NixOS snapshot ID 656 also remains.

## [COMPLETED] Set Capitaine cursor theme — 2026-10-23

Installed Capitaine through Home Manager and selected size 24 for GTK, X11
and Umbriel. Flake check, dry-build, full build and Umbriel config validation
passed. Test activation and persistent switch succeeded as generation 202
(`/nix/store/4rqabzx7ppni3chxjjiizsxcc0cfaz3z-nixos-system-erebor-26.05.20261021.da6dc0e`).
Verified deployed GTK settings, default-theme inheritance, cursor asset,
Home Manager success and Umbriel input reload; no failed system/user units.
Root/ESP UUIDs remain correct and generation 202 is the default boot entry.
No reboot performed. Existing applications may need restarting to pick up
the theme; visual appearance has not been confirmed by the user.

## [COMPLETED] Retire broken Fedora installation — 2026-10-23

SYS-025. User explicitly approved removing Fedora leftovers and its last
root snapshot after reviewing the targets and irreversible loss of that copy.
Removed Fedora root ID 256, nested machines ID 259 and unused Fedora containers
ID 262; Btrfs subvolume sync confirmed all three fully reclaimed. Removed
EFI/fedora, EFI/moria, Fedora menu entry and firmware entries 0000/0002/0003/0009;
emptied Fedora ext4 boot UUID `50ee1c03-3280-4973-a746-b48c675d773f` without
repartitioning or formatting, and removed empty /mnt/fedora-{root,home}.
Shared srv, active NixOS containers, Windows, active swap and partitions remain.

Flake check, build, test activation and persistent switch passed; cleanup
activated generation 201 (`wm51h9kq739558mk5zypnyvav9m195df`). The removed
Fedora extraEntries setting had been an uncommitted edit; tracked configuration
already omits it. During verification a separate cursor-theme change activated
generation 202 (`4rqabzx7ppni3chxjjiizsxcc0cfaz3z`), now current/default;
Fedora menu remains absent. Protected Windows/NixOS/fallback EFI hashes passed
(excluding the intentionally removed Fedora extra-files copy), remaining
firmware order/default preserved, mounts intact, Jellyfin/Nextcloud/libvirtd
active and no failed units. Main filesystem free space rose from about
5.2 GiB to 63.5 GiB net; ESP usage fell from 285 MiB to 167 MiB.
No reboot or post-cleanup Windows boot test performed.

Recovery: important read-only NixOS snapshot
`/btrfs-top/nixos-root-pre-fedora-retirement-20261023`, ID 656, UUID
`6836b6ee-1163-db45-83aa-7ff1fb276076`, verified ro=true. Snapper has no
configuration, so a direct Btrfs recovery snapshot was used. Root-only
`/var/lib/system-recovery/fedora-retirement-20261023` contains boot archives,
protected hashes and before/after firmware/subvolume evidence. Both archives
were compared to source before deletion. SHA-256: EFI tar
`f98c09a27157fd478b8b5c9c883a4f8b7c9dc286350ea1f108a88b7f205a46f6`;
ext4 boot tar `4e63121ba40cfcc1866a1f0ebcfa1f6ddcc3479fc6ad64f3902284609eac05f1`.
The deleted Fedora root snapshot was intentionally not backed up.

## [COMPLETED] Enable Nix commands and flakes by default — 2026-10-23

Enabled nix.settings.experimental-features system-wide with nix-command and
flakes. Previously only Home Manager's service supplied a local NIX_CONFIG;
ordinary commands and sudo repeatedly failed before evaluating the flake.
Full flake check and NixOS build passed. Activated generation 200 with YubiKey
sudo authentication; nix-daemon restarted successfully. Verified ordinary
`nix config show`, `nix eval` and flake-based evaluation succeed without extra
feature flags, system/current profile and boot default match generation 200,
root/boot mounts remain intact, and no system units failed. KDE Connect phone
remains reachable. No reboot performed.

Activation retained the existing Fedora extraEntries setting and verified its
menu entry remains present. That pre-existing configuration edit is excluded
from this focused commit. Generation 200 supersedes the generation-199
bootloader pitfall recorded below; future builds must still preserve the entry.

## [COMPLETED] Persist KDE Connect LAN firewall rules — 2026-10-23

Added TCP and UDP 1714–1764 on br0 only (configuration commit d9edff3).
Full flake check, dry-build and isolated full system build passed. Activated
`/nix/store/xkdi7nn5faf6rl89ps03qsl40rsw17fj-nixos-system-erebor-26.05.20261021.da6dc0e`
as generation 199 with YubiKey authentication and explicit Nix experimental
features. Verified deployed firewall.service, live IPv4 and IPv6 TCP/UDP range
rules, matching system profile and generation-199 boot entry/default, unchanged
root/boot mounts, no failed system units, and phone paired/reachable over LAN.
User also confirmed access. No reboot performed or needed for this change.
[SYS-024](SYSTEM_TODO.md#sys-024) is complete.

The isolated build excluded the pre-existing uncommitted Fedora extraEntries
setting. Activation consequently removed fedora.conf; restored its exact
previous content and verified /boot/EFI/fedora/shimx64.efi exists. Fedora boot
remains untested under SYS-001. Preserve the existing working-tree extraEntries
setting in future activations; do not replay generation 199's bootloader setup
without preserving that entry. Unrelated configuration edits remain uncommitted.

## [COMPLETED] Persist writable Crucial mount — 2026-10-23

Changed only the Crucial exFAT mount option from ro to rw for UUID 604F-A363,
keeping the existing automount, ownership and permission options. Verified
findmnt reports that UUID mounted read-write at /srv/external/crucial, and the
installed fstab already specifies rw. Current system remains generation 198;
no failed system units. The same configuration passed flake evaluation and
NixOS dry-build during the preceding alias change. This commit records the
existing configuration; no remount, activation or write test was performed.
VM relocation remains a separate unverified follow-up under SYS-022. Fedora
boot-entry edits are excluded from this commit.

## [COMPLETED] Add common Git shortcuts to Fish — 2026-10-23

Added 41 Oh My Zsh-style Git shell aliases through Home Manager in flake.nix,
including gst, ga, gaa, gapa, gd/gdca, gcmsg, gsw/gswc, glog, gp and stash
shortcuts. Reference: https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/git/git.plugin.zsh.

Validation: flake check --no-build, NixOS dry-build, Home Manager activation
package build and Fish syntax check passed. Compared against the system's
actually deployed Home Manager generation (the separate user profile was
older): only .config/fish/config.fish content changes, with identical package
paths. Activated /nix/store/vvp21qjk9pcpqny1hfrk88iszkfrfrww-home-manager-generation
successfully without a system rebuild. A fresh interactive Fish resolves the
aliases; gst --short, ga --dry-run and glog -1 succeed in /etc/nixos.
Existing Fish sessions can load them with source ~/.config/fish/config.fish.
System generation remains 198; unrelated kernel, Fedora-entry and mount edits
were not activated or included in this commit.

## [COMPLETED] Retire installation plan and separate installation log — 2026-10-23

Removed INSTALL_PLAN.md and INSTALLATION_LOG.md after confirming the original
installation, first-boot acceptance, snapshot reference and ESP backup checksum
are already recorded in this changelog. Removed the obsolete log requirement
from AGENTS.md. The deleted documents remain recoverable from Git history;
ongoing history, tasks and recovery knowledge use SYSTEM_CHANGELOG.md,
SYSTEM_TODO.md and SYSTEM_CONTEXT.md respectively.

Validation: checked remaining repository references and diff whitespace.
Documentation only; no system configuration or runtime state changed.

## [COMPLETED] Separate change history from unfinished work — 2026-10-23

Added SYSTEM_TODO.md with stable task IDs, concrete completion conditions,
evidence dates, and explicit review status for uncertain historical work.
Migrated all 25 old pending headings to linked historical records; consolidated
kernel/recovery and xremap follow-ups. Closed the obsolete Umbriel background
workspace check using the later scratchpad replacement record. Marked verified
Fedora-entry, kernel/driver, T3-library and dashboard deployments completed while
retaining their outstanding user-facing checks separately. Updated AGENTS.md and
SYSTEM_CONTEXT.md to define record ownership, operation checkpoints and closure.

Validation: checked migrated-task coverage, unique IDs, relative Markdown links,
historical evidence retention and git diff whitespace. Documentation-only change;
no rebuild, activation, reboot, firmware, storage or session change performed.

## [COMPLETED] Retain only five NixOS system generations — 2026-10-23

User explicitly authorized pruning NixOS system generations, retaining only
the five newest. Scope is restricted to `/nix/var/nix/profiles/system` and
its corresponding NixOS systemd-boot entries; do not prune user profiles,
Nix store paths, Fedora, Windows, the ESP itself, or UEFI firmware entries.
Pre-checks: current/default system generation is 198; root UUID is
`5be9be17-20c9-4a47-ba2d-6adf1ceb4c55`, ESP UUID is `38B5-8386`, and no
failed system units were present. Snapper is not installed/configured, so a
Snapper snapshot is not applicable. Recovery before deletion is generation
198 or another retained generation from the systemd-boot menu. Mandatory next
action: enumerate the root-owned system profile, delete only generations
older than the newest five, then verify the retained profile and boot entries.
Verification: system profile symlinks now retain exactly generations 194, 195,
196, 197, and 198, with generation 198 current/default. Fedora and Windows
entries remain available. systemd-boot still lists stale NixOS entry files for
generations 156–193; the profile deletion does not remove them itself.
The current-system activation reconciled systemd-boot. Final verification
confirms that both the system profile and NixOS menu contain only 194–198;
Fedora and Windows remain available and no failed units are present.

Validation on 2026-10-23 after reboot: system profile symlinks and bootctl
both contain exactly 194–198. Generation 198 is booted, active, and default.
Fedora and Windows boot-menu entries remain present. Root and ESP UUIDs
match the safety instructions; both system and user failed-unit lists are empty.
The earlier mandatory deletion/reconciliation steps are resolved.


<a id="record-sys-001-1"></a>

## [COMPLETED] Add Fedora to systemd-boot menu — 2026-10-23

> Historical record; current disposition: [SYS-001](SYSTEM_TODO.md#sys-001).
> Instructions and checkpoints below apply to their recorded date, not the current system.


Configured a declarative systemd-boot chainload entry for Fedora's existing
signed shim at `/EFI/fedora/shimx64.efi` on the ESP UUID `38B5-8386`. The
file and existing UEFI Fedora entry `Boot0002` were verified before the
change. No Fedora, Windows, ESP, or firmware boot-order files were modified.
The root UUID `5be9be17-20c9-4a47-ba2d-6adf1ceb4c55` and ESP mount were
verified, and no failed system units were present. Snapper is not installed,
so a Snapper snapshot is not applicable. Activation succeeded on generation
198; `bootctl` verifies the `Fedora` entry and existing Windows entry on the
ESP. Mandatory next action: reboot and confirm that the `Fedora` entry starts
Fedora successfully while NixOS and Windows entries remain available.

Validation on 2026-10-23: generation 198 is now booted. bootctl lists
fedora.conf targeting the existing /EFI/fedora/shimx64.efi, and both that
shim and Windows bootmgfw.efi exist. Clarification: activation created an ESP
loader entry file; the statement above about no ESP files being modified
applies to preparation before activation, not the resulting loader entry.
Successful Fedora chainloading remains unverified. Mandatory next action:
user-initiated Fedora boot and confirmation; no reboot was run for this audit.


<a id="record-sys-002-1"></a>

## [COMPLETED] Update kernel and NVIDIA integration — 2026-10-23

> Historical record; current disposition: [SYS-002](SYSTEM_TODO.md#sys-002).
> Instructions and checkpoints below apply to their recorded date, not the current system.


Updated only the `nixpkgs` flake lock from revision `a033e66` (2026-10-13)
to `da6dc0e` (2026-10-21), then selected NVIDIA 615.78.08, the current
new-feature Linux release, with `boot.kernelPackages.nvidiaPackages.mkDriver`.
The prepared system closure is
`/nix/store/fm1ia6jrmjbnih7s5k23wa4msglsxspq-nixos-system-erebor-26.05.20261021.da6dc0e`.
Validation passed: `nix flake check --no-build`, `nixos-rebuild dry-build`,
and `nixos-rebuild build --flake /etc/nixos#moria`. The next generation has
Linux 6.18.57 and `nvidia-kernel-modules-615.78.08-6.18.57`. Activation
succeeded on generation 198; the currently running generation is still 196
on Linux 6.18.56 / NVIDIA 595.71.05. As expected before reboot, the new
NVIDIA 615.78 userspace reports an NVML driver/library mismatch against the
old loaded kernel module. Root UUID
`5be9be17-20c9-4a47-ba2d-6adf1ceb4c55` and ESP UUID `38B5-8386` were
verified; existing generations remain available as rollback entries. Snapper
is not installed/configured, so no Snapper snapshot is applicable. Mandatory
next action: reboot, then verify the running kernel, NVIDIA module/driver,
display wake, mounts, boot entry, and failed units before marking complete.
The recent NVIDIA display-wake incident remains a specific post-reboot
validation risk.

Post-reboot validation on 2026-10-23 supersedes the pre-reboot running-state
and reboot instructions above. /run/booted-system, /run/current-system, and
the default profile all resolve to generation 198:
/nix/store/y69cmflagl0s0br6120545q27l3i0php-nixos-system-erebor-26.05.20261021.da6dc0e.
uname reports Linux 6.18.57; /proc/driver/nvidia/version and nvidia-smi both
report 615.78.08 on the RTX 4090, with no NVML mismatch. No NVIDIA Xid,
flip-timeout, plane-fence failure, or atomic modeset errors were found in
this boot's kernel journal. Root and ESP UUIDs match; bootctl marks 198
selected/default and retains 194–197. No system or user units are failed.
Umbriel reports DP-1 enabled/powered at 3440x1440, 164.9 Hz, HDR on.
Implementation and boot validation are complete. Physical display wake remains
unverified and is tracked separately in SYS-002; it does not leave the kernel
and driver deployment pending.

Commit verification on 2026-10-23: the lock diff changes only the nixpkgs
input, and the driver diff pins 615.78.08 with its source hashes. Reconfirmed
booted/current generation 198, Linux 6.18.57, loaded NVIDIA 615.78.08 and
successful nvidia-smi with no failed system units. Flake evaluation and NixOS
dry-build passed during the preceding Git-alias change with this same lock
and driver configuration. No further activation or reboot was needed.
The commit includes only flake.lock, modules/nvidia.nix and this record;
Fedora boot-entry and Crucial mount edits remain separate. SYS-002 still
tracks physical display-wake verification.

<a id="record-sys-002-2"></a>

## [RECORDED] Recover NVIDIA display wake failure — 2026-10-23

> Historical record; current disposition: [SYS-002](SYSTEM_TODO.md#sys-002).
> Instructions and checkpoints below apply to their recorded date, not the current system.


Post-reboot verification: normal login1 reboot was accepted and the host
returned on generation 196. Root and ESP UUIDs match the checkpoint;
greetd is active and the login screen session is running. No flip-timeout,
plane-fence semaphore, atomic modeset, or NVRM Xid errors were found in the
new boot's kernel journal at initial inspection. One Podman container
healthcheck transient unit is failed; this is separate from display recovery.
Physical display confirmation and post-login dashboard wake verification
remain pending. Do not treat this reboot as a confirmed long-term fix.

Display-on dashboard requests failed with Umbriel IPC exit status 1. Later
requests returned success while the physical AW3423DWF still showed No signal.
Kernel logs show NVIDIA 595.71.05 flip timeouts, plane fence semaphore failure,
and atomic modeset error -11. Monitor power cycling and a temporary 60 Hz
mode did not recover the picture; the original 164.9 Hz mode was restored.
The user approved ending/restarting the desktop session. The old Umbriel
session ended; direct service restart inherited its stale WAYLAND_DISPLAY
and failed to start. The launcher then cleaned the environment and greetd
returned to Noctalia Greeter, which also exhibits the NVIDIA modeset errors.
The user reports the virtual console is unusable. Remote commands still work.

User explicitly authorized normal reboot on 2026-10-23; requesting login1
Reboot(false) after reading back this checkpoint. Current/default system:
generation 196, /nix/store/wfimff15ahia19129widx0cmvi0s5w8x-nixos-system-erebor-26.05.20261013.a033e66,
running kernel 6.18.56. No configuration or lock updates were activated.
Verified root UUID 5be9be17-20c9-4a47-ba2d-6adf1ceb4c55 and ESP UUID
38B5-8386, both mounted read-write; no failed system units. Generation 196
boot entry and referenced kernel/initrd exist; generation 195 entry remains
available for recovery. Snapper is not installed/configured, so a Snapper
snapshot is not applicable to this runtime-only recovery. login1 CanReboot
returns yes and no shutdown inhibitors were listed. No firmware or boot
entry changes are needed. Risks: reboot interrupts all remaining workloads
and remote access; display recovery is not guaranteed. Mandatory next action:
request the authorized normal login1 reboot, then verify
boot generation, mounts, graphics logs, physical login screen and dashboard
wake behavior before marking recovery complete.

Validation on 2026-10-23: the host has subsequently booted generation 198
with Linux 6.18.57 / NVIDIA 615.78.08. Both failed-unit lists are empty and
the current boot has none of the recorded NVIDIA modeset failure signatures.
Umbriel reports DP-1 powered with the original 164.9 Hz mode and HDR enabled.
These software checks do not establish physical wake recovery. Earlier
reboot instructions in this entry are historical and have been superseded;
mandatory next action is physical display/wake confirmation, not another reboot.
Display power was not cycled during this audit because it previously caused
loss of local display access.


## [COMPLETED] Make dashboard ambilight off override WLED realtime — 2026-10-22

The dashboard successfully disabled HyperHDR LEDDEVICE, but WLED retained
UDP realtime output while reporting power off. Sending on=false, live=false
and lor=2 released realtime mode, and the user confirmed the LEDs went dark.
Update the dashboard to apply this override after disabling HyperHDR output;
the on action clears lor to 0 before enabling output. Serialize these actions
to prevent interleaving. Keep the WLED endpoint in the service environment.

Seven tests and flake check passed; dry-build passed. The actual updated
actions were tested against HyperHDR/WLED: on cleared the override; off left
on=false, lor=2, live=false. LEDs were left off. No capture restart was used.
Full build passed:
/nix/store/j5fnm81vjs3bl96360lcm316n67zhbpa-nixos-system-erebor-26.05.20261013.a033e66.
Activation pending. Mandatory next action: sudo nixos-rebuild switch --flake
/etc/nixos#moria, then verify the dashboard off/on buttons and deployed
dashboard-control environment. Current generation is 196; root/ESP UUIDs
are unchanged and no failed system units were found. Sudo needs a password.
No reboot or storage changes are required. Unrelated disk/changelog edits
must remain outside this commit.

Post-activation validation on 2026-10-23: the running generation 198
user unit deploys the updated control.py and DASHBOARD_WLED_URL. Both
Caddy and dashboard-control are active. All seven dashboard tests pass.
POSTs through https://erebor.jzon.pl/api/control return 200: off produces
on=false, lor=2, live=false; on produces on=true, lor=0, live=true and
50 fps. Cross-origin POST returns 403. SYSTEMGRABBER remains active and
visible at priority 245; LEDs were restored on. Activation instructions
above are resolved. Separately, this session found WLED left at lor=2 while
HyperHDR was enabled; clearing lor restored realtime updates. HyperHDR's
saved portal selection currently captures physical DP-1, not ambilight.


## [COMPLETED] Add password-authenticated remote desktop over Tailscale — 2026-10-22

Add XRDP with a separate XFCE X11 session for Android access before local
login. Open TCP 3389 only on tailscale0, disallow root and empty-password
logins, and give the remote session its own D-Bus bus and X11 environment.
The local Wayland login configuration is preserved. Credentials and generated
TLS keys remain outside the repository and Nix store. Existing unrelated
external-disk and changelog edits are not part of this change.

Flake check, dry-build and full build passed. The built XFCE session and its
window manager, panel, desktop and settings daemon ran successfully on an
authenticated temporary Xvfb display with a temporary home and private D-Bus.
Inspected the built PAM rules (no empty-password authentication), sesman
configuration (no root login), and firewall script (3389 only on tailscale0).
An initial process-name assertion needed adjustment for Nix wrapper names;
the corrected live session check passed. Test processes and home were removed.

Built system:
/nix/store/jgczvsnlbjlg3ia1vknj7nb5fi5gz42l-nixos-system-erebor-26.05.20261013.a033e66.
The user activated this build; generation 194 is active and persistent.
Both xrdp and xrdp-sesman are enabled and running; TCP 3389 is listening,
and there are no failed system units. RDP negotiation and TLS 1.3 handshakes
passed via loopback and the host's own Tailscale address. These local probes
do not verify the Android network path or password login. Root and ESP UUIDs
remain unchanged. No reboot was performed.

The user confirmed the XFCE desktop opens successfully from Android.
PAM logs confirm a janzon XRDP session opened at 19:05:46; loginctl shows
remote session 11 while the local seat remains at the greeter. Both services
remain active with no failed system units. Before-local-login access is
therefore verified without automatic local login. Session startup emitted
a dbus-update-activation-environment warning about the private bus lacking
systemd activation; the desktop nevertheless opened successfully.
Reconnect and a full reboot cycle were not exercised. Services are enabled
at multi-user.target for subsequent boots.

Active system before this change:
/nix/store/151cddvy8yvw1yp4x4m6lyacfjiyh6r7-nixos-system-erebor-26.05.20261013.a033e66
(persistent generation 193). No failed system units; root/ESP UUIDs match
AGENTS.md. No reboot or storage change is planned.

<a id="record-sys-003-1"></a>

## [COMPLETED] Supply T3 browser runtime libraries — 2026-10-21

> Historical record; current disposition: [SYS-003](SYSTEM_TODO.md#sys-003).
> Instructions and checkpoints below apply to their recorded date, not the current system.


Provide Chromium runtime libraries through LD_LIBRARY_PATH in the existing
t3code user service. The bundled Chrome headless shell's ldd output confirmed
the missing dependencies reported by preview_open. Keep the library search
path scoped to T3 and its children, with fontconfig/freetype for text rendering.
No browser profile or downloaded T3 executable is modified. Root activation
is currently unavailable because sudo requires a password.

Flake check, NixOS dry-build and full build passed. Using the exact declared
library path, ldd reports no missing libraries for T3's downloaded Chromium
154.0.8037.92, and that same binary launched headless and rendered a temporary
test page successfully. The temporary browser profile was removed.
Built system:
/nix/store/ndapp324yz251i8n3kdbl0n091pi8k0m-nixos-system-erebor-26.05.20261013.a033e66.
Generation 191 remains active and T3 has not been restarted. Root/ESP UUIDs
and boot entries were inspected; no boot or storage changes were made.
Mandatory next action: sudo nixos-rebuild switch --flake /etc/nixos#moria,
then systemctl --user restart t3code.service if activation does not restart it.
Restarting T3 briefly disconnects its web UI. Verify preview_open after the
server reconnects, then mark this entry completed. The preceding dashboard
controls change is also included in this build and still awaits activation.

Validation on 2026-10-23: activation is no longer pending. Generation 198
has the declared LD_LIBRARY_PATH in t3code.service, the service is active,
and its running process environment contains that path. Every listed library
directory exists. The earlier generation-191 state and activation/restart
instructions are historical. preview_open was not exercised in this audit. Runtime-library deployment is
complete; end-to-end preview verification is tracked separately in SYS-003.


<a id="record-sys-004-1"></a>

## [COMPLETED] Add Caddy display, ambilight and power controls — 2026-10-21

> Historical record; current disposition: [SYS-004](SYSTEM_TODO.md#sys-004).
> Instructions and checkpoints below apply to their recorded date, not the current system.


Add six dashboard buttons and a loopback user service behind Caddy. The API
accepts only same-origin JSON requests with an explicit control header; Caddy
limits access to local/private and tailnet source addresses. Sleep and shutdown
require browser confirmation and use the existing login1 policy/inhibitors.
Display power preserves virtual capture outputs; HyperHDR's LEDDEVICE switch
preserves its PipeWire session. No suspend or power-off operation will be run
during validation. Activation requires sudo, currently password protected.

Validation passed: flake check, NixOS dry-build and full system build; six
automated API/dispatch tests; Chromium rendering of all six controls; live
Mango DP-1 off/on with ambilight remaining on; HyperHDR LED off/on with capture
remaining active. Both display and LEDs were restored to their initial on
states. An isolated Caddy instance using the built HTTP routes and the exact
built user-service sandbox returned 200 for display-on and 403 for a
cross-origin request. Temporary services were stopped and removed. login1
CanSuspend/CanPowerOff both report yes; disruptive actions were not executed.

Built system:
/nix/store/bh3i32plfz8c2bqlc9x8cq4syxs0vs9p-nixos-system-erebor-26.05.20261013.a033e66.
Current persistent generation remains 191:
/nix/store/zrxvp3y3zi32k1d0r8p6pqi6ap8zm0s5-nixos-system-erebor-26.05.20261013.a033e66.
Caddy and HyperHDR remain active; root and ESP UUIDs are unchanged. No boot,
storage, sleep or power-off operation was performed. Browser preview could not
start because its host libraries are missing; installed Chromium supplied the
page-rendering check. Niri/Umbriel command adapters were inspected but only
Mango is currently running and was physically validated.

Mandatory next action: run sudo nixos-rebuild switch --flake /etc/nixos#moria,
verify dashboard-control.service in the janzon user manager and caddy.service,
then verify the controls through the normal dashboard URL. Mark this entry
completed after activation and user-facing verification. The sleep and power
buttons require a user-initiated test when saved work allows it.

Validation on 2026-10-23: generation 198 deploys the dashboard-control
service and Caddy routes, and both services are active. All seven current
dashboard tests pass. Normal dashboard HTTPS API ambilight off/on requests
return 200 and produce the expected WLED states; a cross-origin request
returns 403. LEDs were restored on with screen capture still active.
The activation instructions above are resolved. Current session is Umbriel;
physical display wake remains pending under the NVIDIA recovery entry.
Sleep and power-off remain untested and require a user-initiated test when
saved work allows it. Dashboard deployment is complete; remaining acceptance checks are tracked
separately in SYS-002 and SYS-004.


## [COMPLETED] Add Mango tag layout shortcuts — 2026-10-21

Super+G opens a layout key mode with a shortcut notification. S/T/G/M/D/V
select scroller/tile/grid/monocle/dwindle/vertical_scroller for the current
tag, then return to default mode; Escape cancels. Flake check, NixOS dry-build,
full build, Mango parser, shell syntax and diff checks passed. Activated through
pkexec; generation 191 is active and persistent:
/nix/store/zrxvp3y3zi32k1d0r8p6pqi6ap8zm0s5-nixos-system-erebor-26.05.20261013.a033e66.
Reloaded Mango and verified entering layouts mode, selecting tile, and automatic
return to default mode through the deployed helper. Restored scroller afterward.
Home Manager succeeded; Mango, xremap and Noctalia remain active. No failed
system units or reboot. Physical key delivery awaits user confirmation.

## [COMPLETED] Persist Mango shortcuts with Polkit activation — 2026-10-21

User requested pkexec for the previously validated system rebuild. Successfully
ran pkexec nixos-rebuild switch --flake /etc/nixos#moria. Generation 190 is now
active and persistent:
/nix/store/jfnn84flm7pgvnm3ga30zwnxqnf4dhbk-nixos-system-erebor-26.05.20261013.a033e66.
Home Manager activation exited successfully and its unit now includes NIX_CONFIG.
No system units are failed; Mango, xremap and Noctalia remain active. Verified
deployed Caps+semicolon/apostrophe tab bindings and direct spatial up/down focus;
Mango reload and config parser succeeded. Prior pending persistence instructions
below are resolved by this activation. No reboot performed.

## [COMPLETED] Assign Caps punctuation keys to Mango tabs — 2026-10-21

Map Caps+semicolon/apostrophe through the existing xremap desktop layer to
Mango groupfocus prev/next. Spatial window navigation remains direct focusdir.
Update shortcut help and README. Flake check, NixOS dry-build, Home Manager
build, Mango parser, shell syntax and diff checks passed. Activated generation
/nix/store/nivpf6msa4p8f4mdn2w6r5fr90kv6xpl-home-manager-generation, reloaded
Mango and restarted xremap successfully; xremap and Noctalia are active.
Deployed files contain both remaps and matching groupfocus bindings. Physical
key delivery awaits user confirmation. Persistent system activation still
requires the previously documented sudo rebuild.

## [COMPLETED] Separate Mango tab and spatial focus shortcuts — 2026-10-21

Restore Caps+W/S, Super+Up/Down and Super+K/J to direct focusdir up/down so
grouped windows do not trap spatial navigation. Assign Super+Alt+Up/Down to
groupfocus prev/next. Remove the contextual helper and update shortcut help
and README. Flake check, NixOS dry-build, Home Manager build, config parser
and shell syntax checks passed. Activated Home Manager generation
/nix/store/hrvag8hvpwnfnfsahrphfc02hym4j5i7-home-manager-generation and reloaded
Mango successfully. Live IPC verified spatial down from grouped client 7 to
the window below (6), and independent tab selection from 7 to 9; restored
original focus. Noctalia remains active. Physical shortcuts await user check.
Persistent system activation still requires the sudo rebuild documented below.

## [COMPLETED] Restore deployed Mango tab navigation — 2026-10-21

Live Mango still used the older Home Manager files after the boot-time
home-manager-janzon service relinked its old generation and failed during
installPackages because nix-command was disabled. The installed helper lacked
focus-vertical and all six vertical bindings still called focusdir. Source
already includes the navigation and activation-environment fixes.
Flake check, NixOS dry-build, full system build, Mango config parser and shell
syntax checks pass. Restored Home Manager generation
/nix/store/gg6vxqwd9l58rmr0bf8284hhsvjn4ncb-home-manager-generation
with NIX_CONFIG enabling nix-command/flakes, then reloaded Mango successfully.
Live helper verification selected grouped client 7, switched up to client 6,
then down back to 7; restored the original focused client afterward. Group
navigation stops at either end rather than wrapping. Noctalia remains active.
Physical shortcut delivery still awaits user confirmation.

Persistence subsequently completed with pkexec in generation 190 (entry above).
At the time of this restoration, the pending command was
sudo nixos-rebuild switch --flake /etc/nixos#moria.
The validated system is
/nix/store/ybgzvyr8pknrg0l8qxw5fby99p4ymxvd-nixos-system-erebor-26.05.20261013.a033e66;
its Home Manager unit includes the already committed NIX_CONFIG fix. The
current system still uses the older Home Manager activation and its failed
boot-time unit remains recorded. sudo -n requires authentication, so system
activation was not performed. Without it, login can restore the older files.

## [COMPLETED] Swap host and Windows GPUs — 2026-10-19

Intel UHD 770 now drives Linux and RTX 4090 is assigned to the Windows VM.
Generation 172 is booted, active and persistent:
/nix/store/207r6picj0fa2q7bhv0wb44pjl6y9yc7-nixos-system-erebor-26.05.20261013.a033e66.
Generation 171 is retained as the recovery boot entry:
/nix/store/dw9l4lk86ccckmhi7kvxwyf2baczg5v3-nixos-system-erebor-26.05.20261013.a033e66.
The user rebooted after staging and confirms the Linux monitor is connected
to a motherboard video output.

Flake checks, dry builds and full builds passed. Preserved the sudo/YubiKey
configuration already active in generation 171; its unrelated source edits
remain uncommitted. The installed target reserves 10de:2684 and 10de:22ba
for VFIO, blacklists NVIDIA host drivers and loads i915 for Linux. Both
NVIDIA PCI functions share an otherwise isolated IOMMU group. The persistent
windows11 domain assigns 0000:01:00.0 and 0000:01:00.1 with managed=no;
Intel assignment was removed. XML validates and its non-hostdev contents
were verified unchanged before libvirt assigned the new guest PCI addresses.
Existing firmware, NVRAM, TPM, disk and Looking Glass configuration are kept.
Windows was cleanly stopped for staging and is now running successfully.

The user ran the reviewed staging script with local sudo authentication.
It checks the offline qcow2, saves disk/XML/NVRAM/TPM and ESP recovery copies,
checks foreign EFI hashes and firmware entries, and retains generation 171.
Recovery directory: /var/lib/windows-vm-recovery/pre-gpu-swap-20261019
(root-only; audit contents were not independently readable by this agent).
Read-only root snapshot: /btrfs-top/nixos-root-pre-gpu-swap-20261019,
independently verified ro=true. Snapper is not configured. The correct root
and ESP UUIDs were rechecked. Boot entry 172 references the built target and
its installed initrd; entry 171 and its older initrd remain available.

Post-reboot verification: Intel 0000:00:02.0 uses i915; both NVIDIA functions
use vfio-pci. Umbriel's live log reports the Intel Mesa iris renderer, with
DP-1 at 3440x1440@99.982 Hz. Libvirtd and the guest agent work, the correct
root/ESP UUIDs remain mounted, and no system or user units have failed.
Windows initially used Microsoft Basic Display Adapter. Windows Update
automatically installed NVIDIA 32.0.16.1088 (610.88), reporting success; the
agent's narrowly targeted install attempt found it already installed and
made no additional driver changes. RTX 4090 reports device status 0.
An explicit DXGI enumeration targeting vendor 10de/device 2684 followed by
D3D11CreateDevice succeeded (HRESULT 0, feature level 0xB000). nvidia-smi
reports RTX 4090, driver 610.88 and 24564 MiB of memory.
Looking Glass and QXL are currently disabled in the guest (device code 22),
while the SudoMaker virtual display is healthy; preserved this existing
guest display setup. Looking Glass streaming was therefore not retested.
No further host reboot or Windows restart was required for acceleration.
Recovery: with Windows off, restore windows11.xml from the recovery directory
using virsh define and boot generation 171 to restore the former GPU split.

## [COMPLETED] Release Noctalia bar reservation during auto-hide — 2026-10-19

Update the declarative `noctalia-bar-autohide` utility so enabling smart or
regular auto-hide also releases the default bar's compositor reservation, and
switching back off restores it. `nix flake check` and a dry build passed.
Activated using Polkit; generation 170 is active. The live smart-to-off test
returned success from both reservation and auto-hide IPC calls, ending with
the bar visible and reservation restored.

## [COMPLETED] Add a declarative Noctalia smart-auto-hide control — 2026-10-19

Added `~/.local/bin/noctalia-bar-autohide`, a session-scoped toggle between
disabled and smart auto-hide for Noctalia's default bar, with a custom button
at the far left of that bar. `nix flake check`, Noctalia config validation,
and `nixos-rebuild dry-build --flake /etc/nixos#moria` passed. Activated with
`pkexec`; generation 168 is active. Noctalia reloaded successfully, the
deployed utility resolved from the new Home Manager generation, and its
smart-to-off runtime transition was verified via Noctalia IPC.

<a id="record-sys-005-1"></a>

## [RECORDED] Route HyperHDR through Umbriel's wallpaper-only virtual output — 2026-10-19

> Historical record; current disposition: [SYS-005](SYSTEM_TODO.md#sys-005).
> Instructions and checkpoints below apply to their recorded date, not the current system.


Activated a declarative Umbriel `ambilight` virtual output at 3440x1440@30,
placed beside DP-1 without moving the physical monitor, and configured
Noctalia to render the same wallpaper there. Live verification confirms the
output is enabled and has only `noctalia-wallpaper` and `dropwall` background
layers. Added `blur_popups = true` to Umbriel's global window blur rule so
Qt descendant XDG popups (including Dolphin menus) receive live-content blur;
validated and reloaded it in the live Umbriel session. `nix flake check`,
Umbriel configuration validation, and activated NixOS builds passed; the active system is
`/nix/store/lgvpgqlisca4qd9c85svp3an8gr289wq-nixos-system-erebor-26.05.20261013.a033e66`.

Mandatory next action: approve Umbriel's screencast target change to
`ambilight`, if its confirmation is visible, or reselect `ambilight` in
HyperHDR's PipeWire capture picker. Verify that opening or moving a window
does not change the LEDs, then replace this entry with `[COMPLETED]`.

## [COMPLETED] Match Looking Glass to the host's high refresh rate — 2026-10-18

Niri reports the Dell AW3423DWF on DP-1 already running at 3440x1440,
164.900 Hz. The Windows IDD had no explicit DefaultRefresh (60 Hz default).
Exported its settings to
C:\ProgramData\LookingGlass-Setup\idd-before-high-refresh.reg, set
HKLM\SOFTWARE\LookingGlass\IDD\DefaultRefresh to REG_SZ "164.900", and
restarted only ROOT\DISPLAY\0001. Retain ForceIndirectCopy=1, the verified
artifact workaround. No host configuration, generation, or boot change.
The retained ExtraMode still explicitly selected 1696x1368@60, so changed
only that mode's refresh to 164.900 as well and reloaded the display device.
Verified the IDD log reports ExtraMode 1696x1368@164.9000*, Windows reports
CurrentRefreshRate=164 (integer API value). Future dynamic resolutions use
the new default refresh.
This verifies display timing, not sustained application/game frame rates.

## [COMPLETED] Set up Looking Glass for the Windows VM — 2026-10-18

Use matching pinned B7-829-cdba29f2 Linux client and Windows IDD. The IDD
creates a virtual monitor and supplies direct input, avoiding dependence on
an Intel physical output and the guest's broken SPICE-agent mouse path.
Add a declarative KVMFR module (128 MiB), device permissions, libvirt access,
client configuration, and Windows launcher. Keep existing guest GPU assignment
and console configuration. Build from isolated HEAD plus the existing VFIO
module/firmware changes and this task, excluding unrelated flake edits.
Starting persistent/live host generation: 161. Root and ESP UUIDs match the
system instructions; no failed system units. Before guest changes, cleanly
stop Windows and preserve offline disk, NVRAM, TPM, and XML recovery copies.
Create a verified root snapshot and EFI backup before persistent activation.
Test-activate the built host, assign IVSHMEM at free guest PCI slot 00:05.0,
install the matching signed Windows drivers, and verify Intel rendering,
Looking Glass video and direct input before recording completion.

Validation checkpoint: flake check, dry-build and full build passed. Tested
host is /nix/store/x3zi5f12kyzcprmlxvnlzar0hq71vcnd-nixos-system-erebor-26.05.20261013.a033e66;
persistent generation remains 161 before activation. Recovery directory
/var/lib/windows-vm-recovery/pre-looking-glass-20261018 contains the clean
qcow2 reflink (qemu-img check passed), NVRAM, TPM, exact XML, EFI archive and
foreign-OS EFI hashes. Read-only root snapshot
/btrfs-top/nixos-root-pre-looking-glass-20261018 is verified ro=true.
KVMFR is loaded from the tested generation's module directory; default
modprobe searches the booted generation instead. Its ioctl reports exactly
134217728 bytes, accessible as janzon:kvm with mode 0660. Restarted libvirtd
to copy/load the new qemu.conf ACL. Existing domain changes made concurrently
were recovered from the offline XML; preserved its Intel ROM setting and
added IVSHMEM, disabled ballooning, and added loopback SPICE for audio/fallback.
Windows installer archive SHA256
bf91dbe3b69d369f8180247881739144308c2c0f6c85785ab8220d8a8e4b2665;
installer and driver catalogs have valid HostFission/Sectigo signatures.
Silent driver installation required adding the verified leaf certificate
57476AACDE410C05A63E9FEC8B97938605B9D8F5 to LocalMachine TrustedPublisher;
no root certificate or Secure Boot policy was changed. Installer exit 0;
LGIddHelper is running with Automatic startup; display/input/IVSHMEM devices
report OK. Secure Boot is still enabled. Guest IDD log selects Intel UHD 770
(8086:a780), hardware D3D12 transport, 128 MiB IVSHMEM. Linux client uses
EGL on RTX 4090, DMA buffers, LGMP video/input/clipboard; desktop screenshot
and live mouse events verified. Guest resolution follows the Niri window.
Persisted this exact target as generation 162. Generation 161 is retained;
all Microsoft/Fedora/moria EFI hashes pass and the firmware before/after
files are byte-identical. No system/user units failed; NVIDIA remains the
Linux GPU and Intel remains bound to vfio-pci. No host reboot performed.
User confirmed Looking Glass display, mouse and keyboard work. The normal
launcher was reopened without debug input tracing and reconnects successfully.
Added one persistent/live SPICE USB-redirection device for Looking Glass USB
audio: client reports USB Audio active and Windows reports its audio device
and endpoint healthy. Actual speaker output was not checked.
User then reported visible render artifacts; screenshot showed corrupted
strips in a notification. Backed up guest IDD settings to
C:\ProgramData\LookingGlass-Setup\idd-before-artifact-fix.reg and enabled
HKLM\SOFTWARE\LookingGlass\IDD\ForceFullDirectCopy=1. Restarted only the
virtual display device; driver log confirms full direct transport copies and
continued Intel rendering. Full-frame direct copies did not resolve the
corruption. Set ForceFullDirectCopy=0 and ForceIndirectCopy=1 and restarted
only the virtual display device again. The user confirmed the artifacts are
gone. Intel still renders through D3D12; the transport now uses a CPU copy
through readback memory, trading some bandwidth for correct frames. This
setting persists in the guest registry. Client video/input/clipboard remain
on LGMP; SPICE guest-agent service remains stopped. User-confirmed display,
mouse and keyboard work. No additional host rebuild or reboot was required
for the guest compatibility setting. Guest/host cold reboot with the final
IDD configuration has not been tested; current live operation is verified.
Existing CPU topology was retained; the client reports two guest logical
processors despite the domain's eight-vCPU allocation. That is a separate
performance follow-up.

## [COMPLETED] Restore Windows VM mouse input — 2026-10-18

The windows11 guest showed no pointer and ignored viewer mouse input while
its Windows spice-agent service was running. Restarting that service did not
resolve it. Direct QEMU USB-tablet movement reached Windows and changed its
cursor state from suppressed to showing. Stopping spice-agent restored mouse
input in the existing SPICE viewer; the user confirmed it works.
Set only that guest service to Manual startup and verified State=Stopped,
StartMode=Manual, preserving the working tablet input path after guest boot.
Clipboard integration and automatic display resizing are unavailable while
this service is stopped. To revert inside Windows, set spice-agent startup
to Automatic and start it. No host generation, GPU assignment, domain XML,
or Windows pointer preference changed. Guest restart persistence is configured
but has not yet been tested with another restart.

## [COMPLETED] Add Oo7 keyring password maintenance helper — 2026-10-18

Added `make keyring-change-password`, invoking `scripts/oo7-change-password.py`
as the desktop user. The helper reads hidden passwords, backs up encrypted
keyrings outside the daemon's collection directory with private permissions,
and sends Oo7 0.6's PAM password-change message over the user's socket. It
restarts the daemon only if the socket is missing and returns failure if no
persistent keyring update is detected. It does not change the account password.
Verified Makefile help and dry-run, Python syntax/help, and an isolated fake
socket exchange including message decoding, file-update detection, backup
contents/permissions, and mismatch rejection. No live password change was run.
No Nix configuration or running generation changed; no rebuild is required.

<a id="record-sys-006-1"></a>

## [RECORDED] Assign Intel UHD 770 to Windows — 2026-10-18

> Historical record; current disposition: [SYS-006](SYSTEM_TODO.md#sys-006).
> Instructions and checkpoints below apply to their recorded date, not the current system.


Post-IOMMU baseline: generation 159, Intel 8086:a780 at 0000:00:02.0 alone in
IOMMU group 0, no host processes hold /dev/dri/card0 or renderD128. NVIDIA
RTX 4090 remains the host GPU. Guest agent and QXL display are healthy.
Prepare pinned VfioIgdPkg 067328df2554c865cc0078cb922357301c4c36c6's
IgdAssignmentDxe inside OVMFFull, as recommended by QEMU IGD documentation.
Keep existing Microsoft-keyed guest NVRAM and QXL/SPICE console. Build only
isolated HEAD plus this change, excluding unrelated flake edits. Before
changing the guest, check BitLocker, shut down cleanly, and preserve offline
disk/NVRAM/TPM/domain recovery copies. Move virtual root ports away from
guest 00:02.0, assign only the isolated Intel device, and limit guest physical
address width to the host IOMMU's verified 39 bits. Start and verify Windows,
QXL console, guest agent, Intel driver status and host GPU/services. Do not
claim passthrough complete until Intel acceleration works in Windows.

Built custom OVMF successfully; flake check, dry-build, full build, and test
activation passed. Intel host device detached to vfio-pci, assigned as guest
00:02.0; guest root ports previously occupying that slot moved to slot 04.
Guest firmware CODE is
/nix/store/lfpc063w74lbwqzb6jzisx9sf211h6wa-OVMF-vfio-igd-202602-fd/FV/OVMF_CODE.fd.
Windows booted, QXL/SPICE and guest agent work. Device initially had code 28
(driver missing); Windows Update installed Intel 32.0.101.6129, now reports
Intel UHD 770 healthy with code 0. Installing Intel's current 32.0.101.7092
from official downloadmirror URL after SHA-512 and Authenticode verification.
Offline guest recovery copies are in /var/lib/windows-vm-recovery/pre-igd-20261018:
reflink-cloned disk, original XML, NVRAM and TPM state. BitLocker reports
encrypted volume but ProtectionStatus=Off; no recovery secrets were read.
Added early vfio-pci binding for only 8086:a780 to the module; validated and
test-activated system /nix/store/ly2hfh2bmp7hfgs53464rcvad9njna7b-nixos-system-erebor-26.05.20261013.a033e66.
Persistent boot profile remains generation 159 until further verification.

Intel 32.0.101.7092 is installed and reports code 0; the Intel installer log
ends with successful silent installation and internal exit code 0 (outer
self-extracting wrapper returned 1000). Secure Boot remains enabled.
An explicit DXGI enumeration and D3D11CreateDevice call targeting Intel
vendor 8086, device A780 succeeded: HRESULT 0, feature level 0xB000 (11.0).
Before persisting the host VFIO binding, cleanly stop the guest, create a
verified root snapshot and EFI recovery backup, then activate the already
built/tested /nix/store/ly2hfh2bmp7hfgs53464rcvad9njna7b-nixos-system-erebor-26.05.20261013.a033e66.
Retain generation 159 and the pre-IGD offline guest copies for recovery.
No second host reboot is needed for the current live test; early binding
must be rechecked at the next normal host boot. Verify a cold guest start
with the GPU still bound to vfio-pci before declaring guest passthrough done.

## [COMPLETED] Persist IOMMU configuration and reboot — 2026-10-18

User explicitly approved clean Windows shutdown, recovery snapshot, persistent
activation of the validated virtualization configuration, and host reboot.
Starting persistent recovery generation is 158. Before boot writes, verify
root/ESP UUIDs, shut down windows11 through its responsive guest agent, save
ESP and firmware state, and create/verify a read-only Btrfs root snapshot
(Snapper is not configured). Preserve firmware BootOrder/BootNext and other
operating systems' EFI files. Activate only the already built/tested system
at /tmp/windows-vm-system, excluding unrelated pending flake changes.
Do not reboot until the new generation, recovery entry, boot parameters,
EFI preservation and checkpoint have all been verified and recorded below.
Mandatory post-reboot checks: generation, mounts, failed units, libvirt,
intel_iommu=on, GPU IOMMU group, NVIDIA host driver, and Windows VM state.
Intel GPU remains on i915 until its isolation is verified.

Pre-boot recovery verified: Windows shut down cleanly through QEMU guest
agent. Read-only snapshot /btrfs-top/nixos-root-pre-iommu-20261018,
subvolume 646, UUID 090420ee-dd76-f04b-a8ad-8f76c1ed9f0a, ro=true.
Recovery archive /var/lib/windows-vm-recovery/pre-iommu-20261018/esp-before.tar
was listed successfully; directory also holds firmware state, generation 158
entry, Windows domain XML, and verified checksums of all Microsoft/Fedora/moria
EFI files. Recovery is selecting retained generation 158 from systemd-boot
(hold Space during boot); snapshot and ESP archive provide additional recovery.
Validated target is /nix/store/z2lfrlfggmpwd0b2nsb578lmdhyfk0b6-nixos-system-erebor-26.05.20261013.a033e66.

Final reboot checkpoint: persistent and active generation 159 is the validated
target above. Switch succeeded; nixos-generation-159.conf is the loader
default and includes intel_iommu=on iommu=pt. Generation 158 and its referenced
kernel/initrd remain available. Firmware before/after dumps are identical,
all Microsoft/Fedora/moria EFI checksums pass, and generation 158 entry is
byte-identical to its backup. Libvirt is active; no system/user units failed.
Windows remains shut down, with autostart disabled. No GPU binding changes.
Remaining risk: IOMMU enablement has not yet been tested at boot; if boot
fails, choose generation 158 by holding Space in systemd-boot. Mandatory next
action after reboot is verifying /proc/cmdline, generation 159, stable mounts,
failed units, libvirt, Intel GPU IOMMU isolation and NVIDIA driver before
resuming passthrough. Mac SSH approval forwarding may need reconnecting.

Post-reboot: booted generation 159, active/persistent store path matches the
checkpoint; /proc/cmdline includes intel_iommu=on iommu=pt. Root and ESP UUIDs
match expected values. Libvirt and default NAT network active; no system/user
units failed. Intel UHD 770 remains on i915 and is isolated in IOMMU group 0
with only 0000:00:02.0. RTX 4090 remains bound to nvidia. Windows was cleanly
shut off as expected (autostart disabled), then started for guest verification.
Firmware BootCurrent remains 0004; original BootOrder sequence preserved,
with 000B,000C,000D appended during reboot. No entries were removed or reordered
by this task; inspect the additional entries separately before changing them.
Windows guest-ping succeeded after boot; its SPICE console is again on
127.0.0.1:5900 and DHCP lease is 192.168.122.2.
IOMMU boot stage is verified; GPU binding and guest acceleration remain pending.

<a id="record-sys-007-1"></a>

## [RECORDED] Windows 11 VM with Intel GPU passthrough — 2026-10-18

> Historical record; current disposition: [SYS-007](SYSTEM_TODO.md#sys-007).
> Instructions and checkpoints below apply to their recorded date, not the current system.


User requested setup and selected a fresh Windows 11 guest in a Linux window.
Add modules/windows-vm.nix and its host import: libvirt/KVM, virt-manager,
TPM emulation, IOMMU kernel parameters, and windows-vm-create (8 vCPUs,
12 GiB RAM, sparse 120 GiB virtual disk, Secure Boot, local SPICE console).
Do not bind the Intel GPU until post-reboot IOMMU isolation and host render
usage are inspected. No physical guest disks are exposed. See WINDOWS_VM.md.

Preflight: active/persistent system generation 157,
/nix/store/hcdm0rmfk9jy24l58xvrr4r81h03hq2z-nixos-system-erebor-26.05.20261013.a033e66.
No failed system units. Root/home Btrfs UUID and ESP UUID match AGENTS.md.
Read-only firmware inspection: BootCurrent 0004, BootOrder
0004,0007,0002,0000,0008,0009,000A,0003; BootNext absent.
Btrfs currently has 35.54 GiB unallocated and metadata 2.60/6.50 GiB used.

Flake check, nixos-rebuild dry-build, and full system build passed using an
isolated copy of HEAD plus this module/import, excluding unrelated pending
Home Manager changes. Build: /tmp/windows-vm-system ->
/nix/store/4mmma92l817k0bxp8fhxnfh5pi6ky81m-nixos-system-erebor-26.05.20261013.a033e66.
Generated creation script passes the build's shell checks and usage check.
No activation, bootloader write, GPU unbinding, VM creation, or reboot yet.
sudo -n requires authentication; Mac approval socket is absent. Mandatory
next step: authenticate locally and test the built system, then verify libvirt
and NAT networking. Before any boot installation/reboot, create and verify a
recovery snapshot and update this checkpoint with the exact new generation.
Windows installation ISO is still required. Intel guest acceleration and
accelerated remote display remain unverified; SPICE is the install console.

Retry: Mac approval forwarding was restored. Rebuilt against current HEAD
to preserve the subsequently activated fish greeting; persistent recovery is
now generation 158, /nix/store/mphhdbrmlhiklpg178cjd5c7bhicmyr4-nixos-system-erebor-26.05.20261013.a033e66.
Flake check, dry-build, full build, and interactive-sudo test activation passed.
Live test system is /nix/store/z2lfrlfggmpwd0b2nsb578lmdhyfk0b6-nixos-system-erebor-26.05.20261013.a033e66.
Verified libvirtd active, KVM/device/cgroup checks pass, and default NAT network
active with autostart. No system or user units failed. Corrected creation
helper to use OVMFFull Microsoft-keyed firmware (default QEMU firmware lacks
enrolled keys), and declare /var/lib/libvirt/images via tmpfiles. The helper's
virt-install dry-run successfully generated installation and final XML with
Secure Boot firmware, SMM, TPM 2.0, and loopback SPICE; no VM or disk was created.
VirtIO ISO download completed. IOMMU still disabled in the running kernel,
as expected before reboot. No ESP/boot/profile changes or reboot performed.
Next: obtain Windows ISO, install guest, and prepare a verified recovery
snapshot/boot checkpoint before boot activation and IOMMU reboot.

Guest creation: located /home/janzon/Downloads/windows-vm/windws.is, a Polish
x64 Windows ISO. SHA-256 0eadddd47a6d6d4524df40cbd9b779c32df222f7d2000de2b82a000ca9c5470f
matches Microsoft's Polish x64 download table. Created persistent windows11
domain UUID 152dd897-6203-4cff-919c-bb38345c2dd0 using the installed helper.
Guest is running and screenshot verifies Windows Setup keyboard selection.
Only windows11.qcow2 (120 GiB virtual, initially 19 MiB allocated) and the
two installation CDs are attached. SPICE listens only at 127.0.0.1:5900.
Guest autostart remains disabled; system generation remains test-activated.
No janzon Linux GUI session is active. Open console locally with virt-viewer
or through qemu+ssh from a client with Virt Viewer. Installation, account setup,
guest drivers, persistent host activation and GPU passthrough are outstanding.

User completed Windows installation and virtio-win-guest-tools. Verified the
Windows desktop, running domain, and DHCP lease 192.168.122.2. Added missing
org.qemu.guest_agent.0 virtio Unix channel with --live --config; guest-ping
initially reported agent disconnected, then succeeded after hotplug detection
without a guest restart. Host remains on the validated test activation;
persistent IOMMU boot configuration and passthrough are still pending.

## [COMPLETED] Import Fedora fish greeting — 2026-10-18

Imported the captured Fedora moria banner, compact Fastfetch statistics, and
fortune cow into Home Manager with required packages and the slant font.
Preserved the cyan/purple gradient using a portable renderer. Replaced Fedora
DNF/nvm checks with Nix flake update guidance and the installed Node version.

Isolated flake check, full build, test activation, and persistent switch passed,
excluding unrelated pending changes. Reconnecting the Mac SSH forwarding
socket restored authentication; switch completed successfully. Verified the
deployed greeting with no stderr, no failed system/user units, expected root
and ESP UUIDs, and the generation 158 boot entry. Active and persistent system:
`/nix/store/mphhdbrmlhiklpg178cjd5c7bhicmyr4-nixos-system-erebor-26.05.20261013.a033e66`.
No reboot required.

<a id="record-sys-008-1"></a>

## [RECORDED] Bounded Btrfs data compaction — 2026-10-18

> Historical record; current disposition: [SYS-008](SYSTEM_TODO.md#sys-008).
> Instructions and checkpoints below apply to their recorded date, not the current system.


User explicitly authorized `sudo btrfs balance start -dusage=10,limit=2 /`.
Limit relocation to two data block groups at most 10% occupied; do not change
profiles, partitions, ESP, boot entries, or other filesystems. Existing verified
read-only root snapshot: /btrfs-top/nixos-root-pre-empty-block-cleanup-20261018
(subvolume 644, UUID 5def1c0f-9313-1a43-9d99-a64e893f335f).
Root filesystem UUID verified as 5be9be17-20c9-4a47-ba2d-6adf1ceb4c55.
Generation 156 remains active and available for recovery. After compaction,
inspect space and balance status, retry isolated eza checks/build, and verify
before activation. Mac authentication changes remain pending and inactive.

Both the approved 10%-usage/two-block command and a narrower 1%-usage/one-block
attempt failed with ENOSPC. No balance remains running; unallocated capacity
is still 1 MiB. No authentication/eza activation, profile conversion, file
deletion, or broader balance was performed. Further progress requires freeing
filesystem workspace before retrying. The recovery snapshot remains read-only.

## [COMPLETED] Check and reclaim empty Btrfs data blocks — 2026-10-18

User explicitly approved the proposed empty-block cleanup. Verify UUID
5be9be17-20c9-4a47-ba2d-6adf1ceb4c55 at / and /btrfs-top; create and verify
read-only snapshot /btrfs-top/nixos-root-pre-empty-block-cleanup-20261018.
Snapper is not installed. Recovery: generation 156 remains bootable and the
snapshot preserves the pre-operation NixOS root subvolume. No reboot, boot
entry, ESP, partition, profile conversion, or occupied-block relocation is
authorized. Run only btrfs balance start -dusage=0 /, inspect the result,
then retry the isolated eza build. Starting usage: metadata 6.00/6.50 GiB;
unallocated device capacity 1 MiB; estimated free data capacity 120.80 GiB.

Read-only root snapshot created and verified: subvolume 644, UUID
5def1c0f-9313-1a43-9d99-a64e893f335f, ro=true. The approved command exited 0:
"Done, had to relocate 0 out of 389 chunks". No empty data block groups were
available, so unallocated device capacity remains 1 MiB and the allocation
problem is unresolved. Root/ESP UUIDs and active system generation are
unchanged; no balance remains running. No occupied-block compaction was done.

<a id="record-sys-009-1"></a>

## [RECORDED] Install eza and Fish listing aliases — 2026-10-18

> Historical record; current disposition: [SYS-009](SYSTEM_TODO.md#sys-009).
> Instructions and checkpoints below apply to their recorded date, not the current system.


Add eza to Home Manager packages and aliases ls, ll, la, lla, and lt, with
directories first, automatic icons, and a two-level tree. Validate and activate
this change independently of the pending Mac authentication changes.

Downloaded eza 0.23.4 and verified the listing flags. The isolated source
copy excludes pending authentication changes. Flake check, system build,
and Home Manager-only build attempts failed with ENOSPC; no activation has
occurred. The retry after the approved empty-block cleanup still fails while
creating a Nix store lock file. Complete storage remediation and validation
before activation and committing the eza configuration. Nix daemon remains
active. Logrotate and a Podman healthcheck were already failed at preflight;
Nextcloud cron had also failed by the subsequent check.

## [COMPLETED] Mac Touch ID approval for sudo and Polkit — 2026-10-18

Enabled pam_rssh approval through Secretive's forwarded Mac agent for sudo
and Polkit, retaining Unix-password fallback. Removed Janzon's unrestricted
NOPASSWD rule. Public key remains locally provisioned, root:root 0644,
outside Git and the Nix store. Login/screen-lock PAM stacks are unchanged.
Polkit's sandbox hides home directories with ProtectHome=tmpfs and exposes
only OpenSSH's agent directory through a read-only bind.

The earlier Btrfs ENOSPC blocker is resolved. Isolated source excluded the
unrelated pending eza changes. Flake check, dry build, full build, test
activation, and persistent switch passed. Fresh sudo and Polkit checks
returned 0; user confirmed successful prompts required Touch ID. User also
confirmed explicitly cancelling a diagnostic Secretive prompt; the agent
rejected signing and PAM failed (exit 1). Sudo password fallback returned 0
after Mac cancellation, confirmed by the user. A disconnected agent also
fails the signature-only diagnostic. MAC_APPROVAL.md records reconnection
and the unprivileged pkttyagent workaround for upstream Polkit 127 issue
#686 (internal terminal agent fails with No session for cookie).

Active/persistent system and default boot entry are generation 157:
`/nix/store/hcdm0rmfk9jy24l58xvrr4r81h03hq2z-nixos-system-erebor-26.05.20261013.a033e66`.
Sudoers validates with no NOPASSWD; deployed sudo/Polkit PAM files match the
validated build. Polkit, Home Manager, sshd, and nix-daemon are active.
No failed system or user units at final verification. Root/ESP UUIDs retain
expected values; Windows/Fedora EFI hashes and all firmware entries are
unchanged. Generation 157's boot entry references the validated system and
existing kernel/initrd. No reboot performed or needed.

Recovery: generation 156 remains available. Verified read-only snapshot
`/btrfs-top/nixos-root-pre-mac-approval-persist-20261018`, subvolume 645,
UUID d3d11d92-73bb-1e42-a687-b45bb8345b34, ro=true. Reconnect the Mac's
forwarding session after disconnect/reboot to use Touch ID; Unix password
remains available. Pending eza configuration was neither activated nor
included in this commit.

## [COMPLETED] Install Fastfetch — 2026-10-17

Added `fastfetch` to Janzon's declarative Home Manager packages. Flake check,
build, test activation, and switch passed. Verified Fastfetch 2.63.1 runs and
reports OS, kernel, CPU, and memory. No failed system or user units; root and
ESP retain their expected UUIDs. Active system profile is generation 155:
`/nix/store/9vhh9mqpymhawqxg0g0n7d7syg54dgi6-nixos-system-erebor-26.05.20261013.a033e66`.

## [COMPLETED] Cycle every matching application window — 2026-10-16

Right Ctrl+letter traverses all windows of matching apps, with Shift reversing
the same stable order. Sort by app name then window ID, so focus changes do
not reorder the cycle. Entering from another app initially focuses the most
recently used match. Preserve Alt's installed-app chooser and centering.

Algorithm checks covered three windows, reverse, wraparound, MRU entry, and
multiple apps. Flake check, dry build, test activation, and switch passed.
Full simulated Right Ctrl+H and Shift+Right Ctrl+H through xremap traversed
Helium windows 7 and 12 and wrapped in both directions with no new windows.
Active system is
`kkvxm8ilr0h480f9rhk021ihpf7w3wc9-nixos-system-erebor-26.05.20261013.a033e66`.
xremap and Vicinae are active, no failed system/user units, and root/ESP UUIDs
and the default boot entry remain correct. Live behavior verified in Niri.

## [COMPLETED] Always show the app chooser with Right Ctrl+Alt — 2026-10-16

Add Right Ctrl+Alt+A–Z and rcmd --choose to always open the installed-app list,
even when matching applications are running. Selecting an existing app focuses
and centers it; otherwise its desktop entry launches. Regular and Shift
cycling remain available.

Flake check, dry build, test activation, and switch passed. Full simulated
Right Ctrl+Alt+D through xremap opened the chooser with Discord/Dolphin running.
Escape created no windows; Enter focused existing Discord without duplication.
Ordinary Right Ctrl+D then cycled to Dolphin. Active system is
`pkzrm34hyxsi3ns2xz58di8vq9w6jc1m-nixos-system-erebor-26.05.20261013.a033e66`.
xremap/Vicinae are active; no failed system/user units. Root/ESP UUIDs and the
default boot entry remain correct. Live behavior verified in Niri.

## [COMPLETED] Cycle apps by initial with a Vicinae launch chooser — 2026-10-16

Right Ctrl+A–Z now cycles running apps by their desktop-entry display names;
Right Ctrl+Shift+A–Z cycles backward. Group windows by app and focus its most
recently used window, then center the column. With no matching running app,
Vicinae dmenu lists matching installed apps: Enter launches the selected
desktop entry and Escape cancels. Use Gio's desktop registry for IDs/names
and gio launch for desktop-entry semantics. New apps run in a separate user
systemd scope so restarting xremap does not terminate them. Per-letter locks
and a shared chooser lock prevent repeated presses stacking menus. The Polish
layout and Caps shortcuts remain intact. Former mnemonic shortcuts T/B/F are
replaced by actual app-name initials G/H/D.

Flake check, dry build, test activation, and switch passed. Algorithm checks
covered forward/reverse order across three apps, most-recent window selection,
accent normalization, and no matches. Live full chords through xremap cycled
Discord/Dolphin with D and Shift+D, and focused Ghostty/Helium/Spotify with
G/H/S. Z opened the chooser; Escape launched nothing; Enter launched and
focused Zed, which survived an xremap restart. Vicinae close/state IPC calls
can wait during its modal menu; validation used Niri layer visibility instead.
Active generation 150 is
`86ijc3svgcaahc5b1gcbgyarp08d9dr1-nixos-system-erebor-26.05.20261013.a033e66`.
xremap and Vicinae are active; no system/user units failed. Root/ESP UUIDs and
the default boot entry remain correct. Umbriel code is provided but live
behavior is only verified in Niri.

## [COMPLETED] Run all active Right Ctrl app helpers directly — 2026-10-16

Right Ctrl+T/B/F/S/D now directly launch the shared compositor-aware helper
for Ghostty, Helium, Dolphin, Spotify, and Discord. Preserve existing-window
focus, launch-if-missing behavior, and centering. Remove inactive Right Ctrl+Y,
the custom XKB rules/symbols and deployment, the moria:launchers option, and
obsolete app launcher bindings in Niri/Umbriel. Caps navigation is preserved.

Flake check, dry build, Niri/Umbriel validation, test activation, and persistent
switch passed. Full Right Ctrl sequences through a temporary keyboard grabbed
by xremap focused all five existing apps with no extra windows and no
intermediate launcher keys. After XKB removal and Niri reload, repeated all
five focus checks successfully. Both deployed custom XKB files are absent.
Active system is
`30wm6pcwgd210yms1q82b5jf20md88hn-nixos-system-erebor-26.05.20261013.a033e66`.
xremap is active; no failed system/user units. Root and ESP UUIDs and default
boot entry remain correct. Umbriel configuration validates; live routing
awaits an Umbriel session.

## [COMPLETED] Launch Spotify's focus helper directly from xremap — 2026-10-16

Right Ctrl+S now uses xremap launch instead of F18/XF86Music. A wrapper selects
the existing Niri/Umbriel helper by the active desktop and preserves centering.
Explicitly allow launching and give the user service both system and Home
Manager command paths. Other Right Ctrl shortcuts retain their key mappings
while this direct-launch approach is tried.

Flake check, dry build, test activation, and persistent switch passed. A full
Right Ctrl+S sequence through a temporary keyboard grabbed by xremap focused
Spotify, retained exactly one Spotify window, and emitted no F18 event.
After the service path expansion, the deployed wrapper also focused Spotify
with the exact service environment; all required commands including Umbriel
resolve. Active generation 148 is
`g5xamf0l2fpzhwkvk7jp0dfqkm1z32zr-nixos-system-erebor-26.05.20261013.a033e66`.
xremap is active; no system or user units failed. Root, ESP, and the default
boot entry remain correct. Umbriel routing is implemented but not live-tested.

## [COMPLETED] Use semantic Wayland launcher keys — 2026-10-16

Right Ctrl+T/F/S/D now emit XF86Terminal, XF86Explorer, XF86Music, and
XF86Messenger for Ghostty, Dolphin, Spotify, and Discord. Deploy an XKB option
through ~/.config/xkb/rules and symbols, preserving Polish typing and applying
the F15/F18 overrides after inet(evdev). This avoids relying on environment
variables unavailable to the running Wayland compositor. All four bindings
use focus-or-launch and center the focused column.

Compiled the deployed keymap, validated Niri and Umbriel, passed flake check,
dry build, test activation, and persistent switch. Live uinput events 185,
188, 430, and 144 focused Ghostty, Spotify, Discord, and Dolphin respectively.
Niri needed its keyboard options toggled once to discard the earlier cached
keymap. Active generation 147 is
`lc8y5hgwnrjzsav89d4vklp4dl3azrix-nixos-system-erebor-26.05.20261013.a033e66`.
xremap is active; there are no failed system or user units. Root and ESP UUIDs
and the default NixOS boot entry are correct. Umbriel's configuration and XKB
map validate; its live bindings await an Umbriel session.

After the user logged in again, the new Niri process loaded the user XKB
search path. Verified full Right Ctrl+T/S/F/D sequences through a temporary
keyboard grabbed by xremap, moving focus to another app before each check:
all four focused their intended apps. The previous running Niri context had
retained its startup include paths, so reloads alone could not enable the
new directory. The earlier output-only verification was insufficient.

## [COMPLETED] Accept the Fedora key name for Right Ctrl+S — 2026-10-16

Fedora's XKB layout reports xremap's F18 output as XF86Launch9. Bind both F18
and XF86Launch9 to the Spotify focus-or-launch helper in Niri and Umbriel.
Niri and Umbriel validation, `nix flake check`, dry build, test activation, and
persistent switch passed. Active generation is
`kmbyq6l3b612kz1cbpvyyn9ryx3fm73w-nixos-system-erebor-26.05.20261013.a033e66`.
Reloaded Niri and verified both deployed configurations contain the XF86Launch9
binding. xremap is active and there are no failed system or user units.

## [COMPLETED] Center Right Ctrl focus-or-launch windows — 2026-10-16

Center the focused column after each Right Ctrl app shortcut focuses or starts
Ghostty, Helium, Dolphin, or Spotify. Shell validation, `nix flake check`, dry
build, test activation, and persistent switch passed. Active generation is
`q6ai4zk2s8r126sh3iwfd151x1xn1a4r-nixos-system-erebor-26.05.20261013.a033e66`.
The live Niri helper focused Spotify window ID 38 and completed the center
column action. The xremap service is active, with no failed system or user
units.

## [COMPLETED] Restore Fedora focus-or-launch app shortcuts — 2026-10-16

Direct Right Ctrl app bindings spawn a new process and leave an existing window
unfocused. Restore Fedora's window lookup and focus behavior for Ghostty,
Helium, Dolphin, and Spotify in Niri and Umbriel. Niri and Umbriel validation,
`nix flake check`, dry build, test activation, and persistent switch passed.
Active generation is
`83iq53rcxzaa4wfyzlr1jp4yh93n1gcm-nixos-system-erebor-26.05.20261013.a033e66`.
Reloaded Niri's configuration and invoked the helper against its existing
Spotify window. It focused window ID 4 and retained one Spotify process. The
managed helper scripts and xremap service are active. The Umbriel helper uses
the same app-ID lookup and focus path; no Umbriel session was active to verify
live behavior.

## [COMPLETED] Bind Right Ctrl+S to Spotify — 2026-10-16

Right Ctrl+S is already remapped by xremap to F18, but neither compositor bound
F18. Bound it to Spotify in Niri and Umbriel. Niri and Umbriel configuration
validation, `nix flake check`, dry build, test activation, and persistent switch
passed. Active generation is
`9z1564c736d84xhdrii0i3aimn0818w6-nixos-system-erebor-26.05.20261013.a033e66`.
The deployed Niri and Umbriel bindings and active xremap service confirm the
key sequence; launching Spotify forwarded to its existing instance. No system
or user units are failed, and the root, ESP, and default boot entry remain
healthy.

## [COMPLETED] Route HyperHDR music capture to the iFi output — 2026-10-16

HyperHDR's PipeWire ALSA input followed the default USB camera microphone,
which was muted, while Spotify played through the iFi USB output. Moving the
live stream to the iFi output monitor made HyperHDR report sound detected.
Added a PipeWire ALSA client stream rule to select that monitor when HyperHDR
starts. `nix flake check`, dry build, test activation, and persistent switch
passed. Active generation is
`28z1vlbfgj0pyx9pc49sayhn1gba9lsj-nixos-system-erebor-26.05.20261013.a033e66`.
After restarting WirePlumber and HyperHDR, the new music capture stream linked
to the iFi output monitor, HyperHDR reported sound detected, and the music
effect was visible at priority 1. The USB camera input was idle. HyperHDR and
WirePlumber are active, with no failed system or user units. Root and ESP mounts
and the NixOS boot entry remain healthy. The rule follows the iFi device; if
the playback device changes, update the selected monitor.

## [COMPLETED] Restore HyperHDR capture after graphical login — 2026-10-16

At 15:14 and 15:15, Niri session restarts caused the GNOME portal backend to
lose its Wayland connection. The portal frontend started just before the
backend, and HyperHDR then received ScreenCast version -1, fell back to X11,
and had no usable source. Order the frontend after the graphical session and
GNOME backend. Before HyperHDR starts, check the ScreenCast version; if it is
unavailable, queue a portal restart and let systemd retry HyperHDR. `nix flake
check`, `nixos-rebuild dry-build`, test activation, and persistent switch
passed. Active generation is
`1bngfw34ad4krsrjwkhn1q3zbfzl8zxp-nixos-system-erebor-26.05.20261013.a033e66`.
Verified the user-unit ordering, ScreenCast protocol v5, HyperHDR streaming a
3440x1440 display with zero service restarts, WLED on, unchanged root and ESP
mounts and boot entries, and no failed system or user units. A future Niri
login has not yet exercised the recovery path.

## [COMPLETED] Enable Ghostty background blur in Niri — 2026-10-16

Add a Ghostty-specific Niri background-effect rule. `nix flake check` and
`nixos-rebuild dry-build` passed; `nixos-rebuild switch` activated generation
`fnbjkq4kbhbg5vqv8m4j87qz16lk1kqn-nixos-system-erebor-26.05.20261013.a033e66`.
The deployed configuration includes the rule, and `niri msg action
load-config-file` succeeded. `niri msg windows` confirms Ghostty is running
with app ID `com.mitchellh.ghostty`, matching the rule.

<a id="record-sys-010-1"></a>

## [CANCELLED] Start Umbriel on the ordinary workspace — 2026-10-16

> Historical record; current disposition: [SYS-010](SYSTEM_TODO.md#sys-010).
> Instructions and checkpoints below apply to their recorded date, not the current system.


Enable Umbriel's leading empty workspace and add a startup helper that moves
the persistent `background-apps` workspace after ordinary workspaces, then
focuses workspace 1. This makes normal app launches start on the ordinary
workspace. Umbriel config validation, `nix flake check`, and dry build passed.
`nixos-rebuild switch` activated generation
`ahgjmy2v1mccrrfxs2f5alfb4bp0kbfn-nixos-system-erebor-26.05.20261013.a033e66`.
The deployed config validates. No Umbriel socket is available for live
verification; verify the startup workspace order and app launch placement in a
fresh Umbriel session.

<a id="record-sys-011-1"></a>

## [RECORDED] Start Niri on the ordinary workspace — 2026-10-16

> Historical record; current disposition: [SYS-011](SYSTEM_TODO.md#sys-011).
> Instructions and checkpoints below apply to their recorded date, not the current system.


Run the background workspace reorder helper with a startup-only option that
focuses Niri workspace 1 after placing `background-apps` last. The existing
Caps+Q invocation does not pass the option, so it retains its current focus
behavior. `niri validate`, `nix flake check`, and dry build passed. The change
is activated in generation
`rz7jf0lk7fgrsm8v81635pr5ixmvqbby-nixos-system-erebor-26.05.20261013.a033e66`;
the deployed config validates. `niri msg action load-config-file` could not
connect because no Niri socket is available. Verify the startup workspace and
app launch placement in a fresh Niri session.

<a id="record-sys-012-1"></a>

## [RECORDED] Bind Right Ctrl+D to Discord and widen Niri tab indicators — 2026-10-16

> Historical record; current disposition: [SYS-012](SYSTEM_TODO.md#sys-012).
> Instructions and checkpoints below apply to their recorded date, not the current system.


Map Right Ctrl+D to `KEY_PROG4` in xremap and bind `XF86Launch4` to spawn
Discord in Niri and Umbriel. Increase Niri's tab-indicator width to 8 logical
pixels. Niri and Umbriel config validation, `nix flake check`, and dry build
passed. Activated generation
`2grjk9jkykfqfmv81c3vcjsx7vm2xdl5-nixos-system-erebor-26.05.20261013.a033e66`;
the deployed configs validate and the Niri config reload succeeded. Directly
spawning `discord` through Niri opened its window. xremap cannot currently find
any configured keyboard device and its service is failed, so Right Ctrl+D is
not yet verified. Reconnect a configured keyboard, confirm xremap is active,
then verify the shortcut and tab indicator.

## [COMPLETED] Make KDE applications follow Noctalia theme changes — 2026-10-16

Use KDE's Qt platform integration and Noctalia's generated KColorScheme for
Dolphin, Gwenview, and other Qt applications. Removed the fixed qt6ct palette
override and Qt6ct template, and configured both Umbriel and Niri to set
`QT_QPA_PLATFORMTHEME=kde`. Umbriel and Niri config validation, `nix flake
check`, dry build, test activation, and persistent switch passed. Verified the
deployed session configuration and user manager environment select KDE's
platform integration; active generation is
`f5l2b7slrm4954w53by3inj0r6bs15is-nixos-system-erebor-26.05.20261013.a033e66`.
The already-running Umbriel process retains its previous environment; a fresh
Umbriel login and reopening Dolphin/Gwenview are required to verify their live
appearance.

## [COMPLETED] Adjust Ghostty background opacity — 2026-10-16

Change the Home Manager Ghostty setting from `background-opacity = 0.8` to
`background-opacity = 0.75`. `nix flake check` and dry build passed; test
activation and persistent switch succeeded. Verified the deployed config and
`ghostty +show-config` report opacity 0.75. Active generation is
`myh9qf2a7bji0hillyz3kjpjz36s160p-nixos-system-erebor-26.05.20261013.a033e66`.

## [COMPLETED] Set Ghostty background opacity — 2026-10-16

Manage Ghostty's existing Noctalia theme and set `background-opacity = 0.8`
through Home Manager. `nix flake check` and `nixos-rebuild dry-build` passed;
test activation and persistent switch succeeded. Verified the deployed file
is Home Manager-managed and `ghostty +show-config` reports the Noctalia theme
and opacity 0.8. Active generation is
`bn2kyy49nl5yyp82vrhcc6hnbq44gza1-nixos-system-erebor-26.05.20261013.a033e66`.

<a id="record-sys-013-1"></a>

## [RECORDED] Add Umbriel as a second Wayland session — 2026-10-16

> Historical record; current disposition: [SYS-013](SYSTEM_TODO.md#sys-013).
> Instructions and checkpoints below apply to their recorded date, not the current system.


Added the Umbriel NixOS and Home Manager modules and a tuigreet session menu
for Niri and Umbriel. Ported Niri's application shortcuts, CapsLock/xremap
navigation and window chords, workspace controls, layout and sizing shortcuts,
media controls, and screenshots to Umbriel actions. Added Umbriel-aware helpers
for the Discord/Spotify background workspace and focused-window screenshots.
Configured Umbriel's connected `DP-1` output to match Niri's native
3440×1440@164.899994 Hz mode and enabled HDR continuously on that output.
`nix flake check`, dry build, test activation, and persistent switch succeeded;
the active generation is
`h97j70h281gdfciy4wsw62v6nbrbnidd-nixos-system-erebor-26.05.20261013.a033e66`.
Both source and deployed Umbriel configs pass `umbriel config validate`. Live
Umbriel inspection reports `hdr_mode: on`, `hdr_active: true`, PQ output, and
the configured 3440×1440@164.9 Hz mode on DP-1. No system units are failed.
The locked Umbriel flake uses its own Nixpkgs revision because this system's
26.05 pin only provides wlroots 0.20.0 while Umbriel requires at least 0.20.1.
The running greetd process still has its previous config because restarting it
would end the active graphical login. Next action: restart greetd after the
user approves ending the current graphical session, verify both sessions
appear in the chooser, and complete this entry.

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

<a id="record-sys-014-1"></a>

## [RECORDED] Add encrypted Tailscale state backup workflow — 2026-10-15T09:35:00Z

> Historical record; current disposition: [SYS-014](SYSTEM_TODO.md#sys-014).
> Instructions and checkpoints below apply to their recorded date, not the current system.


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

<a id="record-sys-015-1"></a>

## [RECORDED] Install xremap with the Fedora configuration — 2026-10-15T02:22:00Z

> Historical record; current disposition: [SYS-015](SYSTEM_TODO.md#sys-015).
> Instructions and checkpoints below apply to their recorded date, not the current system.


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

<a id="record-sys-016-1"></a>

## [RECORDED] Keep the user manager alive across Niri logouts and restore Oo7 unlock — 2026-10-15T02:15:13Z

> Historical record; current disposition: [SYS-016](SYSTEM_TODO.md#sys-016).
> Instructions and checkpoints below apply to their recorded date, not the current system.


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

<a id="record-sys-015-2"></a>

## [RECORDED] Restore xremap keyboard devices — 2026-10-16

> Historical record; current disposition: [SYS-015](SYSTEM_TODO.md#sys-015).
> Instructions and checkpoints below apply to their recorded date, not the current system.


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

## [COMPLETED] Enable blur for Vicinae in Umbriel — 2026-10-16

Added an Umbriel layer rule for Vicinae's `vicinae` layer namespace. The active
configuration only applies blur to Noctalia layer surfaces and regular
windows, so it does not match the Vicinae layer surface. Umbriel config
validation, `nix flake check`, and NixOS dry-build passed. Test activation
installed `/nix/store/bslvq6cgc36skdfsfr11d7kvr8kbbkvr-nixos-system-erebor-26.05.20261013.a033e66`.
Umbriel reloaded the layer rules, reported the open `vicinae` surface, and the
user confirmed blur is visible.

## [COMPLETED] Reduce Umbriel blur strength — 2026-10-16

Set `[appearance.blur].radius` to 3, down from Umbriel's default of 5, to
reduce blur strength. Umbriel config validation, `nix flake check`, and
`nixos-rebuild dry-build` passed. `nixos-rebuild test` and `switch` installed
`/nix/store/7cj9dsfgsi9rmh7lc8h7c5f0jhji8xcj-nixos-system-erebor-26.05.20261013.a033e66`.
The deployed config validates, Umbriel reloaded the appearance and scene blur
settings, and both Umbriel and Vicinae are active. The user approved keeping
radius 3 and committing the change.

## [COMPLETED] Repair Umbriel HDR toggle script — 2026-10-16

Fix the generated `umbriel-hdr-toggle` script. Escaped newlines produced an
invalid override, and `jq -e` treated the valid `false` state as an error.
`nix flake check`, dry-build, `nixos-rebuild test`, and `switch` passed. The
deployed script passes `bash -n` and was verified in both directions: HDR
turned off, then on. DP-1 is back in HDR mode (`hdr_active=true`), and the
active NixOS system is
`/nix/store/bl81fynrhj8jhj34ca5pgzi5d7nsnkm0-nixos-system-erebor-26.05.20261013.a033e66`.

## [COMPLETED] Install Konsole — 2026-10-16

Added `kdePackages.konsole` to the system packages. `nix flake check` and
`nixos-rebuild dry-build --flake /etc/nixos#moria` passed; the switch completed
successfully. Verified `/run/current-system/sw/bin/konsole` reports version
26.04.3. Active generation:
`/nix/store/86lb0kmj0740rl5aa1fiz5ax87mmhya1-nixos-system-erebor-26.05.20261013.a033e66`.

## [COMPLETED] Apply Noctalia theme to Discord — 2026-10-17

Enable Vencord in the existing Discord package and initialize its writable
settings with Noctalia Midnight selected. Noctalia's existing community
Discord template owns the generated CSS and follows palette changes.
`nix flake check`, dry-build, test, and switch passed. Noctalia regenerated
all three Vencord theme files with resolved palette colors. Restarted Discord
from the new package; Vencord initialized its settings and retained
`noctalia.theme.css` as the enabled theme. Discord has a live Niri window and
no system units are failed. Active system profile is generation 153:
`/nix/store/bqhjrls9mp0kflpfx2dqgs72ls3c9cdk-nixos-system-erebor-26.05.20261013.a033e66`.

## [COMPLETED] Apply Noctalia theme to Spotify — 2026-10-17

Add Spicetify and a pinned Comfy theme. Launch Spotify from a versioned,
writable copy of its app files so the existing Noctalia Spicetify template
can reapply palette colors without modifying the Nix store. Route the
existing spotify-launcher through the themed package. `nix flake check`,
dry-build, test, and switch passed. Spicetify backup/apply completed;
Noctalia reapplied the template and all generated Comfy colors match
Spotify's patched colors.css. Verified Spotify runs from the writable copy
and has a live Niri window. No system units are failed. Active system
profile is generation 154:
`/nix/store/kvxqdm95lnrw1az8k7svrjhkazq6yr34-nixos-system-erebor-26.05.20261013.a033e66`.

## [COMPLETED] Apply Noctalia theme to Steam — 2026-10-17

Use Millennium's official Nix overlay and pinned Material Theme with the
Matugen color source selected. Repair the Noctalia-created ~/.steam/steam
directory, preserving it as steam.noctalia-bootstrap-backup, so Steam can
link to ~/.local/share/Steam correctly. Starting system profile is generation
155. `nix flake check`, dry-build, build, test, and switch passed.
Added a link from Millennium 3's new theme root to Noctalia's legacy output
path. Steam now starts successfully; Millennium initializes Material Theme
with Color=Matugen and repeatedly reads the generated 4.1 KB matugen.css
according to console-linux.txt. Verified the active theme configuration,
shared CSS path, a live Steam window in Niri, and no failed system units.
Active system profile is generation 156:
`/nix/store/s6cjkbx9fb3bip9znadbxgqhxypbg94n-nixos-system-erebor-26.05.20261013.a033e66`.

## [COMPLETED] Repair Noctalia Next Boot Selector authentication — 2026-10-17

The plugin defaults to pkexec, but a read-only pkexec probe failed with
"No authentication agent found". Configure its privilege_command as
`/run/wrappers/bin/sudo -n`, using the existing sudo policy. A read-only
privileged efibootmgr query succeeded. Validate the flake and dry build,
then activate with `nixos-rebuild test` and reload Noctalia. Generation 156
is the persistent recovery generation. No BootNext is set; boot order and
EFI entries must remain unchanged. Do not reboot or select an entry as a test.

Validation: flake check, dry build, and test activation passed. Noctalia
config reload succeeded and the deployed config has the sudo override.
Read-only sudo efibootmgr succeeds; BootNext remains unset and BootOrder is
unchanged. No system units failed. Test activation is active; persistent
system generation remains 156 (no bootloader activation performed). The
Home Manager config file is deployed and the source change persists for
future rebuilds. No boot selection or reboot was tested. Noctalia logs also
identify the underlying agent registration failure: the passed login session
differs from the caller session. This workaround does not repair that agent.

## [COMPLETED] Add reboot-windows command — 2026-10-17

Add a Home Manager managed ~/.local/bin/reboot-windows command. The user
selected Windows entry 0007 provisionally. Resolve its active Windows loader
by stable shared-ESP partition UUID instead of a fixed firmware entry number.
Set and verify only BootNext before requesting reboot; --dry-run is read-only.
The loader exists at /boot/EFI/Microsoft/Boot/bootmgfw.efi and dry-run resolves
Boot0007. Do not execute the reboot path during validation. Existing BootNext
0001 was already set before this task and is preserved by installation.
Validate flake, dry build, test activation, and deployed dry run. Persistent
recovery generation is 156; do not modify boot order or the ESP.

Validation passed: flake check, dry build, test activation, and installed
reboot-windows --dry-run (Boot0007). Mocked subprocess checks verified the
success sequence and refusal to reboot after failed BootNext writes or
verification. No system units failed. BootNext 0001 and BootOrder are
unchanged; no reboot was performed. Home Manager deployed the executable.
The persistent system generation remains 156; Windows boot success remains
unverified, as requested work was script installation only.

## [COMPLETED] Install Moonlight — 2026-10-18

Add moonlight-qt to the desktop system packages. Validate an isolated source
copy excluding the unrelated pending eza/Fish changes. Existing VFIO
configuration matches the active generation 160. Run flake check and dry-build
before activation; verify the executable and desktop entry afterward.

Flake check, dry-build and full build passed. Moonlight --version reports 6.1.0.
Built system: /nix/store/3ncpxykndiprl5zmxkfi88vznrbysj7h-nixos-system-erebor-26.05.20261013.a033e66.
Pre-activation recovery: generation 160 and read-only root snapshot
/btrfs-top/nixos-root-pre-moonlight-20261018 (Snapper unavailable).
Verify snapshot, test activation, then persist and verify boot entries and mounts.

Verified read-only snapshot 648, UUID 9bfc680d-3b7a-9e4c-9cf0-f85c8bbc68f1.
Test and switch activations succeeded; persistent system generation is 161.
Moonlight 6.1.0 launches graphically and detects the RTX 4090; the desktop
entry is installed. No failed system units. Root and ESP UUIDs unchanged;
UEFI entries/order unchanged, generation 160 retained. No reboot or streaming
session tested. Unrelated pending eza/Fish changes were excluded from activation.
## [COMPLETED] Mark running applications in Right Ctrl chooser — 2026-10-19

The `Ctrl_R+Alt+letter` Vicinae app chooser now shows `●` beside desktop apps
with an open matching window, including its window count; apps without a window
show `○`. The marker is computed from the active Niri or Umbriel window list
immediately before opening the chooser, so it does not rely on process names.
Flake evaluation, Python compilation, diff validation, dry build, and full
build passed. Activated through pkexec as system generation 163; xremap is
active, its deployed rcmd wrapper references the updated source, and
`rcmd --list a` succeeds. There are no failed system units. This terminal is
outside the Niri session, so opening the graphical chooser itself was not
automated; verify its visual markers with Right Ctrl+Alt+letter in Niri.

## [COMPLETED] Order running applications first in Right Ctrl chooser — 2026-10-19

Sort the `Ctrl_R+Alt+letter` Vicinae chooser by active window state before
name, keeping the existing `●` marker and window count. Flake check, Python
compilation, and dry-build passed. Activated through pkexec as generation 164;
the deployed rcmd source contains the state-first ordering and no system units
failed. Verify the graphical order in the active Niri session.

## [COMPLETED] Bypass xremap in Moonlight — 2026-10-19

Exclude the observed `com.moonlight_stream.Moonlight` app ID and `moonlight`
from all general modmap/keymap rules, including CapsLock and Right Ctrl.
Application-only terminal rules already exclude Moonlight. Forward CapsLock
press/repeat/release directly in Moonlight because virtual modifiers otherwise
remain swallowed even without a matching keymap.

Flake check, NixOS dry-build, and Home Manager build passed. Activated only
Home Manager to avoid applying unrelated pending PAM changes; the deployed
config matches the source and xremap was restarted successfully. An isolated
virtual keyboard with its output grabbed away from applications verified exact
Ctrl+A, Right Ctrl+A, Super+A, CapsLock, and held CapsLock+A event passthrough
while the actual Moonlight window was focused. Ghostty still remaps Super+A
to Ctrl+A. Original window focus restored. Streaming-host behavior was not
exercised because the test events were captured locally.

System generation remains 172; root and ESP UUIDs are unchanged. No failed
system or user units. No system/boot activation or reboot was needed.


## [COMPLETED] Enable Intel UHD 770 hardware video decoding — 2026-10-19

Moonlight reports no hardware video decoder. The live graphics driver directory
lacks iHD_drv_video.so and FFmpeg VA-API device initialization fails on
/dev/dri/renderD128. Add intel-media-driver to hardware.graphics.extraPackages.
Validate an isolated source copy excluding the unrelated pending sudo/YubiKey
policy, then test-activate and verify VA-API and an actual hardware decode.
Pre-change persistent generation: 172. Root/ESP UUIDs match the recorded system;
no failed system units. No boot, firmware, VFIO or display-setting changes.

Flake check, dry-build and full build passed. Test activation succeeded using
Polkit. /run/opengl-driver/lib/dri/iHD_drv_video.so is deployed. FFmpeg using
the normal system driver path decoded all 60 H.264 test frames via VA-API
with zero errors. No failed system units. The active system is
/nix/store/mnma7hiid1rr86b034vx58d7xf65b5h2-nixos-system-erebor-26.05.20261013.a033e66.
Persistent boot generation remains 172; no bootloader, EFI or VFIO changes.
The driver is active for this boot and declared for future system rebuilds;
perform a normal switch before rebooting to retain it in the boot generation.
Moonlight must restart to repeat decoder detection; streaming and compositor
frame delivery after this driver fix have not been verified.

<a id="record-sys-017-1"></a>

## [RECORDED] Bridge Windows VM onto the wired LAN — 2026-10-19

> Historical record; current disposition: [SYS-017](SYSTEM_TODO.md#sys-017).
> Instructions and checkpoints below apply to their recorded date, not the current system.


User authorized direct LAN networking. Define NetworkManager br0 and its
enp4s0 port, move existing LAN host firewall allowances to br0, and use br0
for newly created VMs. Existing windows11 interface will be migrated live
and persistently, retaining its MAC. Pre-change XML: /tmp/windows11-before-lan-bridge.xml.
Flake check, dry-build, and full build passed using an isolated source tree
that excludes the unrelated pending modules/mac-approval.nix changes.
Built system: /nix/store/4yqv3l0h050gjs4grclz4j22d6d378ya-nixos-system-erebor-26.05.20261013.a033e66.
Recovery: test-activated system was /nix/store/mnma7hiid1rr86b034vx58d7xf65b5h2-nixos-system-erebor-26.05.20261013.a033e66; persistent generation 172
remains available. Before activation, create and verify the read-only root
snapshot /btrfs-top/nixos-root-pre-lan-bridge-20261019.
Read-only root snapshot 651 verified, UUID f3d8aea9-7a46-2447-a944-6dabf8f4f304.
Test activation succeeded. Host retains 192.168.1.106 on br0, its default
route and DNS work, and router ping has zero packet loss after DHCP settles.
The running and persistent windows11 interfaces now use br0 and the router
assigned 192.168.1.120. Sunshine TCP ports 47984, 47989, 47990 and 48010
are reachable; /serverinfo returns status 200 and hostname gamestation.
The host HTTP service still returns 200. Windows does not answer ping;
no guest firewall changes were needed for Sunshine. Persistent pre-migration
XML backup: /home/janzon/.local/state/windows-vm/pre-lan-bridge-20261019/windows11.xml.
Root/ESP UUIDs verified; no failed units.
Next: authenticate the pending persistent switch, then verify generation,
boot entries, mounts, and services. No reboot planned. Playback from another
physical LAN device has not been exercised.

## [COMPLETED] Give Windows VM 20 GiB and performance cores — 2026-10-19

Gracefully shut down Windows through its guest agent, then persistently set
20 GiB RAM and 12 vCPUs as one socket/six cores/two threads. Pin each vCPU
0-11 to the corresponding P-core logical CPU; emulator threads use the
efficiency-core CPUs 12-19. Restarted successfully with the same LAN address,
192.168.1.120. Windows reports six cores, 12 logical processors and
21,193,420,800 usable bytes (hardware reservations account for the difference
from 20 GiB). ApolloService is Running and its serverinfo endpoint returns 200.
Live and persistent libvirt XML and vCPU/emulator affinities verified.

Updated VM creation defaults in Nix to 20 GiB and 12 threads restricted to
performance cores. Flake check, dry-build, helper package build and domain XML
schema validation passed; an isolated source copy excluded the unrelated
pending sudo/YubiKey change. Creation helper changes will deploy on the next
host rebuild; the existing VM's resource changes are already persistent.
Recovery XML: /home/janzon/.local/state/windows-vm/pre-resources-20261019/windows11.xml.
Host root/ESP UUIDs and active system are unchanged; persistent generation
remains 172. No failed system units; about 6.3 GiB host memory available
immediately after Windows boot. No host activation or reboot performed.

## [COMPLETED] Assign all host CPU threads to Windows VM — 2026-10-19

Gracefully shut down Windows via the guest agent, expanded to 20 vCPUs,
pinned each vCPU to corresponding host logical CPU 0-19, and permitted
emulator threads on 0-19. This covers all six SMT performance cores and
eight efficiency cores. RAM stays 20 GiB. Guest topology is one socket and
20 single-thread virtual cores to accommodate the host's mixed core types.
Host CPU scheduling remains shared; no exclusive CPU isolation was added.

Domain XML schema validation, flake check, NixOS dry-build and creation-helper
build passed. The checks used an isolated tree excluding pending sudo changes.
VM restarted successfully. Live/persistent XML and CPU affinities verified;
Windows reports 20 logical processors and unchanged usable memory. Apollo
service is Running, serverinfo returns 200, and LAN address is 192.168.1.120.
No failed host system units; host system/generation and root/ESP UUIDs unchanged.
No host activation or reboot performed. Nix creation defaults updated for the
next host rebuild; existing VM resources are already persistent in libvirt.
Recovery XML: /home/janzon/.local/state/windows-vm/pre-all-cpus-20261019/windows11.xml.


<a id="record-sys-018-1"></a>

## [RECORDED] User-requested reboot into UEFI settings — 2026-10-20

> Historical record; current disposition: [SYS-018](SYSTEM_TODO.md#sys-018).
> Instructions and checkpoints below apply to their recorded date, not the current system.


UEFI firmware setup supported according to bootctl. Running, booted, and
persistent system agree: generation 172, store path
/nix/store/207r6picj0fa2q7bhv0wb44pjl6y9yc7-nixos-system-erebor-26.05.20261013.a033e66.
Verified root UUID 5be9be17-20c9-4a47-ba2d-6adf1ceb4c55 and ESP UUID
38B5-8386; no failed system units. Generation 172 boot entry and Fedora
and Windows EFI loaders exist. No configuration changes made for this reboot.
Snapper is not configured (/etc/snapper/configs absent); existing recovery
snapshot nixos-root-pre-lan-bridge-20261019 is present. Recovery path:
leave firmware setup and select Linux Boot Manager / NixOS generation 172.
Earlier bridge persistence note is stale relative to current boot: running,
booted and persistent systems now agree. No pending activation for this reboot.
Next action: request systemctl reboot --firmware-setup; after returning,
verify boot, generation, mounts and services and complete this entry.


## [COMPLETED] Temporarily return RTX 4090 to Linux with a passthrough toggle — 2026-10-20

Added virtualisation.windowsGpuPassthrough.enable, explicitly false on moria.
False enables the host NVIDIA driver and removes VFIO reservation; true
reserves both NVIDIA functions for Windows. The windows-vm-gpu service backs
up and synchronizes the stopped domain's PCI assignments, refusing changes
while the guest runs. Windows disk, NVRAM, TPM, networking, CPU/RAM and guest
settings are preserved. See WINDOWS_VM.md for toggle and recovery guidance.

Flake check, dry-build, full build, and both assignment directions/idempotence
passed. Test activation removed Windows PCI hostdevs. Live rebind restored
RTX 4090 to nvidia and HDMI audio to snd_hda_intel; nvidia-smi reports the
RTX 4090 with driver 595.71.05. Windows remains shut off. Persistent switch
succeeded as generation 173, including the verified dual-auth sudo policy.
No failed system or user units; root/ESP UUIDs and firmware entries/order
unchanged. Generation 173 and recovery generation 172 boot entries exist.
No reboot or new graphical session was performed; Linux GPU availability is
verified, but compositor rendering after a new login has not been tested.

Verified read-only Btrfs root snapshot 652 (Snapper unavailable):
/btrfs-top/nixos-root-pre-host-nvidia-20261019T223836Z,
UUID e50c9d88-1af9-1a44-920d-76cbb7645316. Pre-change VM XML and firmware
entries: /var/lib/windows-vm-recovery/host-nvidia-20261019T223836Z.
Per-toggle domain XML backup is also under /var/lib/windows-vm-recovery/gpu-toggle/.
Recovery: boot generation 172; with Windows shut off, restore the saved XML
to recover its previous GPU assignments. Keep the host monitor on the
motherboard output when restoring passthrough.

## [COMPLETED] Allow Mac Touch ID or local YubiKey for sudo — 2026-10-20

Enabled sufficient pam_rssh and pam_u2f for sudo, retaining Unix password
recovery. PAM tries forwarded Mac Touch ID first; dismissing or failing that
approval falls through to the local YubiKey. Credentials remain root-owned
outside Git and the Nix store. Polkit's separate authentication path remains
unchanged.

Flake check, dry-build, full build, test and switch activations passed.
Fresh sudo commands each returned UID 0: one using Mac Touch ID alone and
one after dismissing Mac approval and touching the enrolled YubiKey. Kept an
authenticated root shell open during validation. Active persistent generation
is 173. No failed system or user units. No reboot performed.


## [COMPLETED] Blank the greeter console after 60 seconds — 2026-10-20

Configured greetd preStart to run setterm --term linux --blank 1 on tty1.
Applied the same command live; /sys/module/kernel/parameters/consoleblank
reports 60. Flake check, dry-build, test activation and persistent switch passed.
Generation 174 is active and persistent:
/nix/store/0bgmy8yl1lykmbiaf831a8n1kv9d18bg-nixos-system-erebor-26.05.20261013.a033e66.
Greetd remains active with unchanged PID 2674; no failed system units.
Root/ESP UUIDs unchanged. No reboot or greeter restart performed.
The timer and persistent startup command are verified; physical monitor
blanking/standby was not observed remotely. Keyboard input restores the console.
Existing unrelated UEFI checkpoint left untouched.


## [COMPLETED] Default greeter background to Matrix — 2026-10-20

Added --background matrix to the existing tuigreet command. Installed binary
accepts the option; --dump-config confirms background.kind=matrix.
Flake check, dry-build, test activation and persistent switch passed.
Deployed greetd TOML contains --background matrix. Greetd stays active with
unchanged PID 2674; no session interruption or reboot. The 60-second console
timer remains set. No failed system units; root/ESP UUIDs unchanged.
Active persistent generation 175:
/nix/store/7adydjvhmiyhkaj1p3nks9129bipvghk-nixos-system-erebor-26.05.20261013.a033e66.
Visual appearance awaits the next greeter launch; current session preserved.


## [COMPLETED] Restart greeter to show Matrix background — 2026-10-20

User-requested greetd restart succeeded. New greetd PID 26134 is active;
tuigreet PID 26174 runs with --background matrix. Console timer reports 60.
Generation 175 unchanged; root/ESP UUIDs verified; no failed system units.
Journal confirms a clean stop/start and greeter session opening.


## [COMPLETED] Match greeter UI to Matrix background — 2026-10-20

Added declarative tuigreet theme: black container, green text/borders/prompts,
bright green clock/title/input/key hints. Matrix animation preserved.
Installed greeter --dump-config verifies all ten theme entries; deployed
TOML verified. Flake check, dry-build, test and switch activations passed.
Restarted greetd while seat0 was at the greeter (no user session there).
New greetd PID 32722 and tuigreet PID 32727 are active with the theme config
and --background matrix. No failed system units; console timer remains 60.
Active persistent generation 176:
/nix/store/6xjnk28vm6vk9f6b8z8sbl2pm9nfvzwz-nixos-system-erebor-26.05.20261013.a033e66.
Root/ESP UUIDs verified before activation; no reboot. Physical appearance
has not been observed remotely.


## [COMPLETED] Restore Matrix animation with explicit greeter config — 2026-10-20

Installed tuigreet load_config returns the explicit file directly, ignoring
CLI overrides. Previous theme-only file therefore reset animation, clock and
remembered login settings. Moved those options and session paths into the
same declarative file; command now uses only --config.
Flake check, dry-build, test/switch passed. Effective config assertions cover
Matrix, green theme, clock, remembered username/session and both directories.
Mock PTY rendering emitted 4879 Matrix glyphs in 3 seconds.
Active persistent generation 177:
/nix/store/1m6zcm96iw6xkzw87d3ndmgf265k10js-nixos-system-erebor-26.05.20261013.a033e66.
Root/ESP UUIDs verified unchanged; no failed system units.
Retry with the configured Touch ID-first sudo path succeeded. Restarted
while seat0 was at the greeter. New greetd PID 36108 and tuigreet PID 36115
are active; running process config confirms Matrix animation and green UI.
Console timer remains 60; no failed system units. Physical display appearance
awaits user confirmation; mock rendering is verified above.


## [COMPLETED] Install bat and Fish cat aliases — 2026-10-20

Enabled Home Manager programs.bat (bat 0.26.1) and Fish aliases:
cat="bat --style=plain --paging=never" and
catn="bat --style=numbers --paging=never". command cat retains coreutils cat.
Flake check, dry-build, test activation and switch passed. Verified aliases
in a fresh interactive Fish shell, file reads and piped input. Home Manager
is active; no failed system or user units. Active persistent generation 178:
/nix/store/wk6503pn787gflb725vwchhj3m8f7msn-nixos-system-erebor-26.05.20261013.a033e66.
Root and ESP UUIDs remain correct. No reboot required; existing shells can
load the aliases with exec fish. Unrelated changelog edits preserved.


## [COMPLETED] Install btop — 2026-10-20

Added btop 1.4.7 to the Home Manager package list. Flake check, dry-build,
full build, test activation and switch passed. Verified version and live
terminal interface with clean exit. Home Manager active; no failed system
or user units. Persistent generation 179:
/nix/store/52p0blmhznl1g5r9ll8mskm1xnzvvzwh-nixos-system-erebor-26.05.20261013.a033e66.
Root and ESP UUIDs verified before activation. No reboot required.


## [COMPLETED] Replace Umbriel background workspace with scratchpad — 2026-10-20

Removed Umbriel's persistent background-apps workspace and its startup
positioning script. Caps+Q stores Spotify/Discord in the native scratchpad;
other apps still close. Caps+0 toggles scratchpad visibility and Caps+Super+0
stores any focused workspace window. Added the latter chord to xremap;
Niri configuration is unchanged.

Umbriel config validation, Caps+Q routing checks, nix flake check,
nixos-rebuild dry-build and full build passed. Built system:
/nix/store/wmqjs42ixi4ndamfqg45wj04shgxkb5x-nixos-system-erebor-26.05.20261013.a033e66.
Activated successfully after hardware-key authentication; persistent and
running generation 180 match the built system above. Deployed Umbriel config
validates, Caps+0/Caps+Super+0 and Caps+Q routing are present, and both the
background-apps declaration and obsolete deployed helper are absent.
Restarted xremap successfully to load its added chord. Home Manager is active;
no failed system or user units. After login, live IPC checks with a temporary
Ghostty window verified store-hidden, show/focus, hide, and restore to the
original workspace. The deployed Caps+Q script stored a test window with a
Spotify-matching app ID, and it could be summoned again. Test windows were
removed. Live workspace listing contains no background-apps workspace.
Actual physical key presses and the real Spotify/Discord clients were not
exercised; configured actions and deployed script behavior were verified.


## [COMPLETED] Reverse width cycling with Caps+Super+R — 2026-10-20

Added CapsLock-Super-r to the xremap desktop layer and bound its emitted
Ctrl+Alt+Shift+Super+R chord to Umbriel window-cycle-primary-extent-back.
Caps+R continues to cycle forwards. Umbriel config validation, flake checks
and dry-build passed; switch built and activated generation 181:
/nix/store/04iw12vf0ypjlrr037ygmllj2hm011il-nixos-system-erebor-26.05.20261013.a033e66.
Verified both deployed bindings, reloaded Umbriel successfully and restarted
xremap. Home Manager and xremap are active, with no failed system/user units.
Physical key presses were not simulated. No logout or reboot required.


## [COMPLETED] Noctalia Greeter with appearance sync — 2026-10-20

Replaced tuigreet with upstream Noctalia Greeter 1.7.0, pinned in flake.lock.
Kept greetd PAM/Oo7 and installed Niri/Umbriel sessions. Enabled constrained
passwordless sync for janzon's active local session and Noctalia auto-sync.
Declarative settings select Synced colors, Umbriel and janzon, with a
one-minute idle timeout. Appearance and monitor layout live in sync.toml.

Flake check, dry-build, full build, test activation and switch passed.
Active/persistent generation 182:
/nix/store/j3jnncjs5widbi21gwcn7gxck3n35b9j-nixos-system-erebor-26.05.20261013.a033e66.
Restarted only Noctalia to discover the newly installed helper; greeter-sync
IPC returned ok and its journal confirmed successful application. Verified
sync.toml has the live palette, dark mode, corner radius, font, DP-1 and
ambilight layout/scales/transforms, and copied wallpaper files. The helper
advertises secure-sync-v1; packaged Polkit policy restricts argv1 to --sync.
The greeter lists Niri and Umbriel. greetd, Polkit, AccountsService and Home
Manager are active, with no failed system/user units. Root/ESP UUIDs match;
Fedora/Microsoft EFI hashes and firmware entries are unchanged. Snapper is
not configured; created and verified read-only root snapshot
/btrfs-top/nixos-root-pre-noctalia-greeter-20261020 before switch.
Generation 181's boot entry remains available for recovery.

greetd was deliberately not restarted, preserving the active desktop. Its
running daemon retains the old tuigreet command until its next restart;
logout alone does not load the new command. New greeter rendering/login
must be checked after the next reboot or an explicitly requested greetd
restart. No reboot performed. SF Pro is absent on the host; Fontconfig
currently falls back to DejaVu Sans, as in the desktop session.


## [COMPLETED] Sunshine streaming through an Umbriel virtual output — 2026-10-20

Added the declarative Sunshine service, Virtual Desktop and Steam Big Picture
entries, and a client-resolution/FPS virtual-output helper. Added Umbriel
window rules targeting the stream while that output exists. Capture uses wlr;
encoding uses NVENC with the active NVIDIA driver library path. Router UPnP
is disabled; the module opens Sunshine's host firewall ports. The service
starts with the graphical session only when Umbriel's socket is available.
Credentials/certificates remain under ~/.config/sunshine outside Git/store;
its directory and credentials subdirectory are mode 0700, files mode 0600.

Umbriel config validation, flake check, dry/full builds, test activation and
persistent switch passed. Active/persistent generation 183:
/nix/store/gcbd8fypn26qhvpqls4js4gvj2jq2w23-nixos-system-erebor-26.05.20261013.a033e66.
Verified virtual output creation at 2560x1440@120, Sunshine wlr capture selecting
that output and successful H.264/HEVC/AV1 NVENC encoder detection. A temporary
Ghostty window was moved onto the virtual screen; cleanup returned it to
DP-1 and removed the output. Closed the temporary window. DP-1/ambilight
remain active with their original sizes. Deployed Umbriel config validates;
its streaming window rules were not exercised with an actual Steam game.
Sunshine is active; its web UI responds at https://192.168.1.106:47990.
No failed system/user units. Root/ESP UUIDs match, foreign EFI file hashes and
firmware entries are unchanged, and recovery generation 182 remains present.
Snapper is not configured; created and verified read-only root snapshot
/btrfs-top/nixos-root-pre-sunshine-20261020 before switch. No reboot needed.

Remaining user steps: create web UI credentials, pair Moonlight and test an
actual network stream, audio, input and game performance. No client is paired
by this change. The cached Sunshine package lacks CUDA zero-copy support;
NVENC works through GPU/RAM transfers. Its capability/probe warnings did not
prevent successful encoder detection. For native Wine Wayland games, use
WAYLANDDRV_PRIMARY_MONITOR=sunshine in the game's launch environment if needed.


## [COMPLETED] Allow Sunshine web requests from its LAN URL — 2026-10-20

Added the exact https://192.168.1.106:47990 origin to Sunshine's CSRF
allowlist after its log confirmed that the browser at 192.168.1.97 was
blocked. Flake check, dry/full builds, test activation and switch passed.
An empty account-setup request with that Origin now reaches input validation
(Invalid Username), whereas it previously failed with Missing CSRF token.
No credentials were set or changed by the verification request.
Active/persistent generation 184:
/nix/store/lmzgvs59aj3lnqmv8axlqds2hlb5j0cl-nixos-system-erebor-26.05.20261013.a033e66.
Sunshine is active with no failed system/user units. Root/ESP UUIDs match.
The browser can reload the LAN URL and retry account setup.


## [COMPLETED] Sunshine administration through Caddy — 2026-10-20

Added the Sunshine route to the existing wildcard Caddy site and linked it
from the services dashboard. Added exact erebor/moria HTTPS origins to
Sunshine's CSRF allowlist while retaining its direct LAN origin. The backend
is https://127.0.0.1:47990; certificate verification is skipped only for that
loopback self-signed endpoint. Browser TLS uses the existing wildcard cert.

Caddy validation, flake check, dry/full builds, test activation and switch
passed. Active/persistent generation 185:
/nix/store/9jl5y4sxpdwk5d2cf2c5l2m6qip57l9i-nixos-system-erebor-26.05.20261013.a033e66.
Verified https://sunshine.erebor.jzon.pl through normal DNS with valid TLS;
it returns Sunshine's HTTP 401 Basic login challenge. Both configured aliases
also pass via explicit loopback resolution. The moria alias's existing DNS
points to 100.98.112.118, a different tailnet address; no DNS change was made.
Use sunshine.erebor.jzon.pl for this machine. The erebor services page has
the Sunshine link. Caddy and Sunshine are active with no failed system/user
units. Root/ESP UUIDs match. Existing generation 184 remains the recovery
entry. No credentials changed; authenticated browser use requires the user's
Sunshine login. No reboot required.


## [COMPLETED] Optimize Sunshine capture and scheduling — 2026-10-20

Built the pinned Sunshine release with CUDA 12.9 for GPU-memory capture and
NVENC conversion. Added only its required CUDA compiler/runtime/CCCL packages
to the host's unfree allowlist. The existing user service starts through a
CAP_SYS_NICE wrapper restricted to the users group, enabling high-priority EGL
contexts without granting KMS/CAP_SYS_ADMIN. Enabled standard RealtimeKit so
Sunshine can request CPU-thread priority after dropping main-thread caps.
The code deliberately retains the EGL worker's capability while dropping it
from the main thread. No credentials, pairing state, streaming resolution,
codec/bitrate settings, Caddy routes or virtual-output hooks were changed.

Flake checks, dry/full builds, test activations and persistent switches passed.
Active/persistent generation 187:
/nix/store/95kh81q82xdl8y2w9f2brmias02gc90b-nixos-system-erebor-26.05.20261013.a033e66.
The CUDA build log shows CUDA compiler 12.9.86 and cuda.cu compilation. Runtime
uses the new store binary; the GPU/RAM/GPU fallback warning is absent, EGL
context priority is HIGH, and H.264/HEVC/AV1 NVENC encoders are detected.

Client reconnected with 3024x1890@90 HEVC at about 55.8 Mbps. Compared with
52–60 encoded FPS and about 190% CPU in the prior build, the CUDA session
reached 88–89 encoded FPS with a 10-second CPU sample of 9.6%. Encoder latency
was about 4 ms, so no encoder-latency reduction is claimed. This was an
observational comparison, not a fixed game benchmark or client-side latency
measurement. After enabling RTKit and the final service restart, its journal
verified Sunshine threads receiving nice -10/-15; no denied setpriority or
GPU-copy fallback messages appeared in that reconnected session. The client
disconnected at 09:52:22 before another full performance sample. Sunshine is
ready and idle; pairing survives the restart.

Caddy HTTPS still returns Sunshine's authenticated login challenge. Sunshine,
Caddy and RealtimeKit are active with no failed system/user units. Correct
root/ESP UUIDs verified. Read-only snapshot
/btrfs-top/nixos-root-pre-sunshine-cuda-20261020 was created and verified before
persistent activation; Snapper is not configured. Foreign EFI file hashes
and firmware entries matched across the CUDA switch. Generation 185 remains
available for recovery to the non-CUDA service. No reboot required.

<a id="record-sys-019-1"></a>

## [RECORDED] Install lsof — 2026-10-20

> Historical record; current disposition: [SYS-019](SYSTEM_TODO.md#sys-019).
> Instructions and checkpoints below apply to their recorded date, not the current system.


Add lsof to the declarative system packages. Previous active/persistent
system is generation 187. Flake checks and the full build passed. lsof
4.99.6 successfully queried an open working directory from its store path.
The user will run sudo nixos-rebuild switch --flake /etc/nixos#moria in a
separate terminal; activation and installed-command verification are pending.


## [COMPLETED] Fix Fish greeting column widths — 2026-10-20

Render Fastfetch's top-position output into explicit logo/info columns before
placing the fortune cow. Its default left-logo output uses cursor movements
that invalidated the greeting's per-line width calculations. Measure terminal
cell widths with Fish's string length --visible, use a compact three-space
gap, and stack the cow only when the visible sections cannot fit together.

Fish syntax, nix flake check, nixos-rebuild dry-build and the Home Manager
activation-package build passed. Activated the Home Manager package with
--driver-version 1; its home-files differ from the previous deployed package
only in shell_welcome.fish. Verified the deployed greeting at 80, 100, 120 and
160 columns with no overflow or cursor movement: narrow output stacks, while
100 columns and above keep the cow beside the information. System generation
and the pending lsof system activation are unchanged.


## [COMPLETED] Context-aware Caps A/D scratchpad navigation — 2026-10-20

Caps+A/D now dispatch through umbriel-scratchpad-navigate: when the active
window belongs to a scratchpad, show its previous/next member; otherwise use
normal window-focus-left/right. Detect keyboard focus using the IPC active
field, not the workspace-local focused tile. Pass the scratchpad name so
named pads work too. Deploy the helper through Home Manager.

Bash syntax, Umbriel config validation, mocked routing for normal/default/
named pads, nix flake check and nixos-rebuild dry-build passed. Built and
activated the Home Manager package (only the Umbriel config and new helper
differ), then reloaded the deployed config through umbriel config-replace.
Live next/previous cycling between Discord and Spotify passed; original
focus and hidden scratchpad state restored. System generation unchanged.


## [COMPLETED] Swap Meta wheel navigation axes — 2026-10-20

Meta+WheelUp/Down now focus the previous/next window in layout order;
Meta+WheelLeft/Right select the previous/next workspace. Each uses a 150 ms
cooldown. Other modified wheel bindings remain as configured.

Umbriel config validation, nix flake check, nixos-rebuild dry-build and the
Home Manager package build passed. Activated Home Manager, reloaded the
deployed Umbriel configuration successfully, and checked all four deployed
bindings. Physical wheel input was not simulated. System generation unchanged.


## [COMPLETED] Add scratchpad manipulation submap — 2026-10-20

Meta+0 enters scratchpad mode. After releasing Meta, A/Left and D/Right
show the previous/next scratchpad window; M sends the focused window, R
restores it to its saved workspace, Space toggles scratchpad visibility,
and Escape exits. M/R/Space reset the mode after their action. Existing
Caps scratchpad bindings remain available.

Umbriel config validation, nix flake check, nixos-rebuild dry-build and the
Home Manager package build passed. Activated Home Manager and reloaded the
deployed Umbriel config. Live IPC confirmed entering scratchpad mode and
returning to the default mode; deployed bindings and one-shot transitions
verified. Physical key input was not simulated. System generation unchanged.


## [COMPLETED] Show scratchpad-mode shortcut hint — 2026-10-20

Add a compositor-autostarted scratchpad-hint watcher. It subscribes to Umbriel
submap events and shows a transient, non-expiring Noctalia notification with
A/D cycling, M send, R restore, Space toggle and Escape exit shortcuts while
the scratchpad submap is active. Close only its own notification when leaving
the mode or stopping the watcher. A per-display lock prevents duplicate
watchers. libnotify and busctl paths are supplied declaratively from Nix.

Bash syntax, Umbriel config validation, nix flake check, nixos-rebuild dry-build
and the Home Manager build passed. Activated the final Home Manager package,
reloaded Umbriel and started the watcher through compositor-managed spawn.
Live D-Bus verification found the expected hint with timeout 0 on mode entry,
confirmed it persisted in the mode, and confirmed removal after mode reset.
One watcher remains active. System generation unchanged.


## [COMPLETED] Install UT2004 campaign mutator support — 2026-10-20

Installed upstream UT2k4SPMutators 1.1.0 to the user's .ut2004/System directory.
SHA256: 32be6a6bf04bac52d09d5098144a35e6745f62aa6c1d3a2b752d94ff9708593d.
Separate writable UT2004-SPMutators.ini selects its GUI controller; the normal
UT2004.ini retains the original controller. Added a local application entry
and ~/.local/bin/ut2004-campaign-mutators launcher selecting the alternate
INI and log. No system package or Nix configuration change was needed.

Backups and the install manifest are in
~/.local/state/ut2004/sp-mutators-20261020-180927/. The running game was left
alone. Bash syntax and installed INI/package checks passed. OldUnreal 3374's
UCC successfully loaded the package and exported its 13 classes with zero
errors/warnings. Interactive campaign play has not been tested. Close the
current game, launch UT2004 Campaign Mutators, and create a new profile;
upstream does not support existing normal campaign profiles.


## [COMPLETED] Install UT3 Weapons Beta 4 for UT2004 — 2026-10-20

Mounted volumes contained UT3 map packages but no weapons mutator. Downloaded
GreatEmerald/Wormbo's UT3 Weapons Beta 4 from the Unreal Archive vohzd mirror.
Archive SHA1 ef2d513958ac14fea061e03548f9dc0478faf0f7 matches archive metadata.
Installed 28 files under ~/.ut2004, including code, mutator catalog, animation,
sound, mesh and texture packages plus readme/license. Preflight found no
conflicting existing package contents. Archive, per-file SHA256 manifest and
validation logs are in ~/.local/state/ut2004/ut3-weapons-b4/.

OldUnreal 3374 UCC loaded UT3Common and UT3Style successfully and exported
their classes with zero errors/warnings. Installed files match the manifest.
No game settings or existing saves changed; interactive match behavior has
not been tested. Restart the game and select UT3 Weapons
(UT3Style.MutUT3Weapons) in the Mutators menu, including the separate campaign
mutator launcher. No system configuration change or rebuild was needed.


## [COMPLETED] Install Zen Browser in the user profile — 2026-10-20

Added pinned youwen5/zen-browser-flake input (revision
5a0d21f99706b231df9ff35ab95dbccda88414d8), following existing nixpkgs, and
Zen 1.23.3b to Home Manager packages. The flake's source checksum differed
from the current upstream asset. Verified the downloaded bytes against the
official zen-browser/desktop release API digest and pinned that SHA256:
bb2045d3e21654d40fe841250092eeadfd2c1fc831eefb509222773c8bdca149.

Flake checks, NixOS dry-build and the Home Manager package-path build passed.
Installed the exact built Zen package into the user's Nix profile for immediate
use. zen --version reports Mozilla Zen 1.23.3b; zen.desktop is available via
the profile's application directory, included in XDG_DATA_DIRS. Existing
browser defaults were not changed. No interactive browsing test performed.

<a id="record-sys-020-1"></a>

## [RECORDED] Activate declarative Zen Browser package — 2026-10-20

> Historical record; current disposition: [SYS-020](SYSTEM_TODO.md#sys-020).
> Instructions and checkpoints below apply to their recorded date, not the current system.


System activation requires sudo authentication, unavailable to this session.
Zen is already usable through the user profile. A future
sudo nixos-rebuild switch --flake /etc/nixos#moria will also install it through
the configured Home Manager user packages. The user-profile copy can then be
removed with nix profile remove zen-browser after verifying the declarative
installation. Running/persistent system store path remains
/nix/store/92n2mnai1g78z7y5nbf94qfkwacs59zg-nixos-system-erebor-26.05.20261013.a033e66.


## [COMPLETED] Correct Noctalia's Zen taskbar pin — 2026-10-20

Replaced app.zen_browser.zen with zen in the declarative widget.taskbar pins
to match the installed Nix package's zen.desktop. Flake checks, NixOS dry-build
and the Home Manager build passed. Activated Home Manager with nix-command /
flakes enabled for the activation process, then reloaded Noctalia. Verified
both deployed config and the effective merged config contain zen and no
Flatpak Zen ID. No system-generation change.

## [COMPLETED] Update T3 Code for mobile compatibility — 2026-10-20T19:42:20Z

Updated the existing native T3 Code CLI from 0.0.45 to stable 0.1.0 using
`t3 update 0.1.0 --yes` after the phone reported an older-server mismatch.
Stopped the user service and created/read back a private backup at
`/home/janzon/.t3/backups/server-before-0.1.0-20261020T194139Z.tar.gz` before
migration. Restarted the existing declarative `t3code.service`; verified its
running executable is `/home/janzon/.t3/runtime/versions/0.1.0/t3`, its listener
remains on loopback port 3773, V2 recovery completed, and 10 legacy threads
with 343 transcript messages imported. Both backend GET and
`https://code.erebor.jzon.pl/` return HTTP 200, with zero failed user units.
Nix configuration and system generation are unchanged, so no rebuild was
needed. The previous runtime and V1 data remain available, but V1 and V2
histories diverge after migration. Phone reconnection awaits user validation.
The updater was initially given the server base directory and also installed
an unused runtime under `.t3/server/runtime/versions/0.1.0`; the active launcher
was then updated through the normal default runtime location.

## [COMPLETED] Install MangoWC 0.18.2 and port Umbriel user configuration — 2026-10-21

Pinned mangowm/mango release 0.18.2 (8ab8dd6da49de0c26b8355806ed3d3684c261aca),
following the existing nixpkgs input; removed the old mangowc 0.12.8 package
from the declarative system package list. Added upstream NixOS/Home Manager
modules, a managed config, and adapters for the existing CapsLock layer,
scroller navigation, scratchpad, right-Ctrl app switching, Noctalia bar focus,
screenshots, Polish keyboard and DP-1's 3440x1440/164.9 Hz mode. A small local
patch makes targeted toggle_scratchpad IPC honor the supplied client, preserving
bidirectional navigation without turning ordinary pool members into named
scratchpads. Untargeted behavior is preserved, including the overview guard.

Added a Mango display-manager session wrapper with graphical-session cleanup,
wlr screen capture portals and Oo7 Secret Service. Noctalia's system unit gains
a Mango-only pre-start command creating the ambilight output before the shell
starts. Existing Umbriel/Niri sessions and greeter default are preserved.
Migration differences, including unavailable HDR in the scenefx build, tag/
column differences and Sunshine session integration, are documented in
home/mango/README.md. No firmware, storage, kernel or bootloader settings changed.

Validation: nix flake check, nixos-rebuild dry-build and full NixOS/Home Manager
builds passed. Mango's parser accepts the deployed config. Isolated headless
sessions with three real GTK Wayland clients verified startup/IPC, forward and
reverse scratchpad cycling, width/height adapters, edge focus, centering,
group actions, right-Ctrl window enumeration/focus, key modes, tag switching,
virtual-output creation at 3440x1440, and clean compositor exit.

Installed the built package in the user's Nix profile and activated Home
Manager; ~/.nix-profile/bin/mango -v reports mango 0.18.2(release).
Active user package: /nix/store/ax226x7ald3334g3rd41arsgiicc6q1b-mango-0.18.2.
Home Manager: /nix/store/lh5x1jvxzk54jcvlgvkqmqg8pwi6nbva-home-manager-generation.
The pre-existing xremap failure reported no matching input devices; no device
configuration was changed. Physical display/HDR, actual DM login, capture and
interactive input remain unverified.

<a id="record-sys-021-1"></a>

## [RECORDED] Complete Mango activation and verify display-manager login — 2026-10-21

> Historical record; current disposition: [SYS-021](SYSTEM_TODO.md#sys-021).
> Instructions and checkpoints below apply to their recorded date, not the current system.


User activation at 04:56 installed system generation 189 and updated
/run/current-system and the persistent system profile to:
/nix/store/7l8jm3cjx7y9y067f5yksr2vhmyh2vih-nixos-system-erebor-26.05.20261013.a033e66.
Activation reported status 4 because home-manager-janzon.service failed during
installPackages with experimental Nix feature nix-command disabled. Noctalia
also failed to connect to Wayland: earlier isolated Mango tests inherited the
real D-Bus address, and Mango's cleanup cleared the real activation environment.

Recovered the active Umbriel environment from an existing session child and
verified sockets: WAYLAND_DISPLAY=wayland-0, DISPLAY=:0,
XDG_CURRENT_DESKTOP=umbriel, XDG_SESSION_TYPE=wayland,
XDG_RUNTIME_DIR=/run/user/1000 and UMBRIEL_SOCKET pointing at its existing socket.
Imported those values into D-Bus/systemd, removed stale MANGO_INSTANCE_SIGNATURE,
and restarted Noctalia. Verified active/running with zero restart count.
Future isolated compositor tests must remove DBUS_SESSION_BUS_ADDRESS as well
as isolate XDG_RUNTIME_DIR, to prevent modifying the real activation environment.

Added NIX_CONFIG=experimental-features = nix-command flakes specifically to
home-manager-janzon.service. Flake checks, NixOS dry-build and full system build
passed, and the generated service contains the intended environment setting.
Re-ran the exact Home Manager activation as the user with that NIX_CONFIG;
it completed successfully. The user subsequently activated the fixed system
with nixos-rebuild test; verified home-manager-janzon.service Result=success,
Noctalia active/running with zero restarts, and no failed system or user units.
Running test system:
/nix/store/x6d5l1i9pysza5k4czbz3li32hri4xpj-nixos-system-erebor-26.05.20261013.a033e66.

Fixed test activation is verified. The persistent generation 189 still points
to the previous system until a successful switch. Mandatory next action is
Mango login validation, then persisting the latest configuration with switch.
Root activation remains unavailable to the agent because sudo authentication
is required.

The activated greeter config includes Mango alongside Niri/Umbriel, but greetd
has X-RestartIfChanged=false and its existing process retains the old session
directory until restarted. After saving work, sudo systemctl restart greetd
ends the graphical session; select Mango and verify display, keyboard/CapsLock,
Noctalia, scratchpad and capture. After successful validation persist the fixed
configuration with sudo nixos-rebuild switch --flake /etc/nixos#moria. Remove
the temporary user-profile mango package only after verifying the declarative
package. Actual Mango hardware login remains untested. No reboot performed.

## [COMPLETED] Use scroller tiling for Mango's scratchpad — 2026-10-21

Replaced minimized-pool scratchpad shortcuts with Mango's special workspace,
tag 0, explicitly configured with the scroller layout. Caps+0 and Super+0 toggle
it; Caps+Super+0 and Super+Shift+0 move the focused client into/out of it.
Removed the scratchpad key mode and special navigation adapter so ordinary
Caps+A/D, Super+Left/Right, movement, width and stacking shortcuts apply.
Caps+Q for Discord/Spotify now stores the client on the tiled scratchpad.
README and shortcut hint describe the new behavior and restoration of legacy
minimized windows. No existing windows were moved or closed.

Flake check, NixOS dry-build and Home Manager build passed. An isolated
headless compositor with three real Wayland clients verified that two clients
on tag 0 remain tiled, occupy separate scroller columns, and accept regular
left/right focus, width and reorder actions. Show/hide returns to tag 1, and
the move shortcut restores a client to the prior workspace. Tests removed
DBUS_SESSION_BUS_ADDRESS and used an isolated runtime/config directory; the
real Umbriel session environment remained intact.

Activated Home Manager generation
/nix/store/hhmhc2f04c9kyw32b8y8pjvzdxapxl7n-home-manager-generation.
Deployed Mango config passes its parser; Noctalia remains active. No Mango
session is currently running, so the configuration applies on the next Mango
login. A future sudo nixos-rebuild switch --flake /etc/nixos#moria is required
to persist this change in the system's Home Manager activation; sudo is still
unavailable to this agent. Physical keyboard behavior awaits user validation.

## [COMPLETED] Add contextual Mango tab navigation — 2026-10-21

Caps+W/S, Super+Up/Down and the equivalent Super+K/J now use a shared
focus-vertical adapter: previous/next tab when the focused client is grouped,
otherwise the existing focusdir up/down behavior. Horizontal column navigation
and Caps+T group join/leave remain as configured. Updated README and shortcut
hint. Changes affect Mango only.

Flake checks, NixOS dry-build, Home Manager build, shell syntax and Mango config
validation passed. Isolated headless Wayland clients verified that down selects
another group member and up returns to the original; ungrouped calls succeed.
A controlled IPC stub additionally verified exact focusdir up/down fallbacks
and invalid-direction rejection. Tests isolated runtime/config directories and
removed DBUS_SESSION_BUS_ADDRESS. Activated Home Manager successfully, validated
the deployed config and verified Noctalia plus the original Umbriel environment
remain healthy. No Mango session currently runs, so bindings take effect at the
next Mango login. Persist the latest user configuration in the system with the
previously pending sudo nixos-rebuild switch --flake /etc/nixos#moria.


<a id="record-sys-022-1"></a>

## [RECORDED] 2026-10-22 — Crucial writable mount and Windows VM relocation

> Historical record; current disposition: [SYS-022](SYSTEM_TODO.md#sys-022).
> Instructions and checkpoints below apply to their recorded date, not the current system.


Requested permanent writable access to Crucial UUID 604F-A363 and offline
relocation of windows11 if space permits. Initial check: Crucial is already
rw with about 465 GiB free; guest is shut off; source disk is
/var/lib/libvirt/images/windows11.qcow2 (128868941824 bytes logical).
Current system: /nix/store/ndapp324yz251i8n3kdbl0n091pi8k0m-nixos-system-erebor-26.05.20261013.a033e66.
Change only Crucial mount ro to rw; preserve existing exFAT data and other mounts.
Recovery: keep source disk and original domain XML until destination verification
and guest startup pass; restore original XML to revert. Existing Btrfs recovery
snapshots remain untouched. No formatting, partitioning, or snapshot deletion.
Next: validate configuration, activate, copy and verify offline disk, update
domain path, verify guest, then remove original only after successful checks.


<a id="record-sys-023-1"></a>

## [RECORDED] Sunshine support for Mango — 2026-10-22

> Historical record; current disposition: [SYS-023](SYSTEM_TODO.md#sys-023).
> Instructions and checkpoints below apply to their recorded date, not the current system.


Adapt Sunshine startup checks and virtual-output helper for Mango while keeping
Umbriel behavior. Mango prepares a named sunshine output before service startup
and adjusts its mode to the Moonlight client at connection. Keep the Mango output
alive between streams: live disable/re-enable testing triggered a compositor
ABRT in wlroots head_send_state via output_manager_apply_or_test and ended the
graphical session at 18:53:43 CEST. The greeter recovered. Removed that cleanup
path; repeated create/resize/reconnect/no-op cleanup passed in an isolated
headless Mango with a separate runtime/config directory and no session bus.
Ambilight remained enabled. No further live display tests.

System before work: /nix/store/151cddvy8yvw1yp4x4m6lyacfjiyh6r7-nixos-system-erebor-26.05.20261013.a033e66.
System/user failed-unit lists were empty; root and ESP mounted, existing boot
entries inspected without changes. Sudo requires a password. Permanent system
activation remains pending; do not claim Moonlight streaming verified.

Final validation: nix flake check, nixos-rebuild dry-build, and the generated
Sunshine user unit build passed. Isolated Mango verified the actual generated
ExecCondition and ExecStartPre, named sunshine capture selection, and NVENC
H.264/HEVC/AV1 initialization. Sunshine remained running with its HTTPS UI until
test cleanup. Test state and credentials used a temporary XDG_CONFIG_HOME;
existing Sunshine credentials were not changed. Moonlight end-to-end remains
unverified. Both isolated test compositors and Sunshine were stopped.

Loaded a temporary runtime drop-in at
/run/user/1000/systemd/user/sunshine.service.d/mango.conf, using the built unit
rooted by /run/user/1000/sunshine-mango-unit. Verified systemd uses the new
condition, preparation and config. It takes effect at next Mango login; no
graphical session is currently running. Runtime setup lasts this boot.
Next: log into Mango and verify Moonlight; persist with sudo nixos-rebuild
switch --flake /etc/nixos#moria, then unlink the runtime mango.conf drop-in
and run systemctl --user daemon-reload. User's Crucial/VM work remains separate.


## [COMPLETED] Restore HyperHDR after stale desktop portal — 2026-10-22

HyperHDR was running but screen capture failed with "Unavailable cursor mode 1".
The desktop portal advertised AvailableCursorModes=0 after starting before the
current Umbriel session. Restarted the user xdg-desktop-portal service, then
hyperhdr; the portal now advertises cursor modes=7 and uses the Umbriel backend.
Verified PipeWire STREAMING at 3440×1440 / 30 fps with DMA-BUF acceleration,
active visible SYSTEMGRABBER priority 245, LEDDEVICE enabled, WLED on and live
in UDP mode, and web UI HTTP 200. No capture errors after recovery.
Runtime recovery only: no Nix configuration or system generation change
(system-194-link); no boot or mount changes. Existing Crucial/VM and Sunshine
work remains untouched. If this recurs after changing desktop sessions, restart
the desktop portal before HyperHDR so it refreshes backend capabilities.


## [COMPLETED] Add Noctalia restart shortcut in Umbriel — 2026-10-22

Assigned unused Super+Shift+F6 to systemctl --user restart noctalia.service,
with key repeat disabled. Umbriel config validation, nix flake check and
nixos-rebuild dry-build passed. Built and activated Home Manager generation
/nix/store/7ivz4wpk8jnj2n2pihkwxicqqiix5qwr-home-manager-generation after
verifying the only changed deployed file was Umbriel config.toml; reloaded it
through config-replace. Invoked the binding's exact action through Umbriel IPC:
Noctalia restarted from PID 1266791 to 1676920 and is active/running. Physical
key delivery awaits user use. No failed user units. System generation remains
194; canonical shortcut is included in the next system rebuild. Unrelated
Crucial/VM and Sunshine changes remain untouched.


## [COMPLETED] Expose gdbus to Noctalia Phone Connect — 2026-10-22

Declared ~/.local/bin/gdbus through Home Manager using the existing glib.bin
output, making it available on Noctalia's existing PATH. nix flake check and
nixos-rebuild dry-build passed. Compared generated home files: the only
addition was gdbus; package profile unchanged. Activated Home Manager generation
/nix/store/zszh7hnbci7mr20qvvpm3zpfwa0qdcfx-home-manager-generation.
Dispatched Phone Connect refresh without restarting the shell; visually verified
the panel shows one connected Galaxy S26 Ultra and battery 82%.
System generation remains 194; no failed user units. Root and ESP remain
mounted, with no system or boot activation. Unrelated Crucial mount and
changelog edits remain untouched.


## [COMPLETED] Add KDialog for Phone Connect file selection — 2026-10-22

Declared ~/.local/bin/kdialog through Home Manager from kdePackages.kdialog.
Flake check and system dry-build passed. Compared Home Manager generations:
only new deployed file was kdialog, with the package profile unchanged.
Activated /nix/store/p7gxpjd5m4gjniwrm0jnkwd8y0lvd4z6-home-manager-generation.
Verified kdialog 26.04.3 resolves on Noctalia's existing PATH and its file
picker opens as an org.kde.kdialog window in Umbriel. The dialog was closed
without selecting or sending a file. No failed user units. System generation
194 and boot configuration unchanged. Unrelated working-tree changes preserved.


## [COMPLETED] Restore image thumbnails in KDialog — 2026-10-22

Dolphin already displayed Pictures thumbnails. KDialog lacked kio-extras in
its Qt plugin path, leaving generic image icons. Updated its Home Manager
launcher with kio-extras plugin and data paths. Flake check and system dry-build
passed. The only changed deployed file was ~/.local/bin/kdialog. Activated
/nix/store/7kb3jivbmsh68m0w13vanyzzzx4wgrnq-home-manager-generation.
Visually verified a fresh picker renders JPEG and PNG thumbnails; the test
returned a selected path without sharing it. Existing pickers need reopening.
No failed user units; system generation remains 194. No system/boot activation
or mount changes; unrelated working-tree changes remain untouched.


## [COMPLETED] Enable Flatpak and Flathub — 2026-10-22

Enabled NixOS Flatpak support and an idempotent system Flathub registration
unit, retaining existing desktop portals. Flake check and nixos-rebuild build
passed. Compared fstab with the running system: identical; unit changes were
Flatpak integration, font support and previously validated Home Manager files.
Activated system generation 195 with administrator authentication:
/nix/store/8l71p97syczs486hm2zhdf19pm8qw34q-nixos-system-erebor-26.05.20261013.a033e66.
Verified Flatpak 1.18.4, system Flathub remote at https://dl.flathub.org/repo/,
successful registration service and remote-info metadata retrieval for
org.gnome.Calculator without installing it. No failed system or user units;
Noctalia and desktop portal remain active. Root/ESP mounts unchanged, fstab
unchanged, and generation 195 boot entry present. No reboot performed.
Unrelated Crucial mount and changelog edits left uncommitted.


## [COMPLETED] Install Discover as the Flatpak GUI — 2026-10-22

Installed KDE Discover and set Home Manager MIME defaults for .flatpak,
.flatpakref and .flatpakrepo files to org.kde.discover.desktop. Verified the
package includes flatpak-backend. Flake check and nixos-rebuild build passed;
candidate fstab matched the running system. Activated generation 196:
/nix/store/wfimff15ahia19129widx0cmvi0s5w8x-nixos-system-erebor-26.05.20261013.a033e66.
Verified all three MIME handlers, backend discovery, system Flathub remote,
and a live Discover window. Installed view is empty as no Flatpak apps are
installed. No failed system/user units; Noctalia and desktop portal active.
Root/ESP mounts unchanged. No reboot. Unrelated changes left uncommitted.
