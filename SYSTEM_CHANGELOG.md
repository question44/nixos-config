# NixOS system change log for `erebor` (flake target `erebor`)

This file holds the current month (November 2026); add new
entries directly below this header. Earlier months: [2026-10](changelog/2026-10.md).

# GRUB theme: no dark box while the kernel loads — 2026-11-06

User reported a black rectangle between choosing a GRUB entry and Plymouth.
Cause: the theme's `terminal-box` used the dark `panel_c.png` tile. GRUB
draws that box (6%/20%, 88%×65%) when it leaves the menu to run `linux` and
`initrd`, and `gfxpayload=keep` holds that frame until Plymouth. The terminal
box now uses a fully transparent `terminal_c.png`; the menu panel is
unchanged. Trade-off: the `e`/`c` editor text sits directly on the wallpaper.
`nix flake check` passes; `erebor-diff`: different (only the `grub-redhead`
theme). ACTIVATION: pending.
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

[SYS-072](SYSTEM_TODO.md#sys-072). User asked to move the whole system from
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
