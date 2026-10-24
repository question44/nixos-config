# System tasks for `erebor`

Current unfinished work belongs here. History and dated evidence belong in
[SYSTEM_CHANGELOG.md](SYSTEM_CHANGELOG.md); recovery knowledge belongs in
[SYSTEM_CONTEXT.md](SYSTEM_CONTEXT.md). Updated: 2026-10-23.

- **OPEN:** a specific remaining task or unverified result is known.
- **ACTIVE:** work is underway; include the current checkpoint, recovery path
  and next safe step for disruptive operations.
- **REVIEW:** migrated historical work; reconcile later evidence and current
  intent before treating it as something to execute.
- **DONE / CANCELLED:** closed with dated evidence or a reason; retain the ID.

Each item has one stable ID. Do not renumber or reuse IDs. Link related records
instead of copying their instructions. No review task authorizes a reboot,
activation, storage change, secret archive or graphical-session interruption.
Earlier approvals remain bounded by their original scope and safety preconditions.

## Open checks

<a id="sys-037"></a>

### SYS-037 — Extract dashboard into a reusable private Git submodule

**Status:** DONE · **Closed:** 2026-10-25

Published private `question44/erebor-dashboard`, pinned at `86dc07f` under
`apps/erebor-dashboard`. Shared flake exports static frontend/control packages,
an overlay and an opt-in NixOS module. Host settings and privileged Windows
helper remain here. Standalone/parent checks, remote package build, 29 API tests,
9 host-helper tests, browser checks and full NixOS build passed. This task covers
source/package extraction; no activation was requested or performed. Subsequent
status feature deployment is recorded separately under SYS-036.
**Evidence:** [Dashboard extraction](SYSTEM_CHANGELOG.md#completed-extract-dashboard-into-private-submodule-and-nix-packages--2026-10-25).

<a id="sys-036"></a>

### SYS-036 — Show live display and Ambilight status

**Status:** DONE · **Closed:** 2026-10-25

Live Display/Ambilight status deployed as generation 218 from extracted dashboard
submodule `86dc07f`. Read-only API uses desktop power and WLED/HyperHDR readings;
UI polls every 10 seconds and after controls, distinguishes mixed/unknown,
and clears stale offline data. Twenty-nine shared API/status tests plus nine
host-helper tests, mocked HTTP/browser state transitions, flake/dry/full builds,
test activation and switch passed. Live browser verified both domains, matching
API/UI states, periodic refresh, offline reload/config and reconnect before and
after switch. Readings included Display Off and Ambilight Off, then On with a
live stream. Validation issued no real control commands.
**Evidence:** [Live device status](SYSTEM_CHANGELOG.md#completed-show-live-display-and-ambilight-status--2026-10-25).

<a id="sys-035"></a>

### SYS-035 — Migrate control API to FastAPI

**Status:** DONE · **Closed:** 2026-10-25

FastAPI/Uvicorn backend activated and persisted as generation 217. Preserved
/api/control, all seven actions, loopback binding, same-origin/header checks,
256-byte body limit, no-store responses and JSON success/error contract. Typed
requests reject extra fields; unsupported methods now return 405. Added schema
and docs under /api/control/. Twenty-four backend tests and real HTTP/browser
integration with mocked dispatch passed, as did flake/dry/full builds and live
HTTPS read-only/rejection checks before and after switch. No real control
commands issued; Caddy/control service healthy, no failed units.
**Evidence:** [FastAPI migration](SYSTEM_CHANGELOG.md#completed-migrate-dashboard-control-api-to-fastapi--2026-10-25).

<a id="sys-034"></a>

### SYS-034 — Add Reboot to Windows dashboard control

**Status:** DONE · **Closed:** 2026-10-25

Confirmed Reboot to Windows button deployed as generation 215. Uses the existing
Windows GRUB entry for one boot, honours inhibitors, and clears selection if
reboot fails. Seventeen backend tests, real GRUB temp-file rollback check,
browser mock/cancel checks at 320–1000px, flake/dry/full builds and live UI checks
passed. Helper prerequisites and control-service Polkit permission verified
read-only. No reboot or real boot selection was executed; actual Windows boot
remains untested. GRUB environment, protected EFI files and firmware unchanged.
**Evidence:** [Windows reboot control](SYSTEM_CHANGELOG.md#completed-add-windows-reboot-dashboard-button--2026-10-25).

<a id="sys-033"></a>

### SYS-033 — Migrate service dashboard to Angular

**Status:** DONE · **Closed:** 2026-10-24

Angular/Angular Material dashboard activated and persisted in generation 214.
Flake/dry/full builds, Caddy adapt and Chromium checks passed: eight service
links, six controls with mocked API requests/results, destructive confirmations,
Cancel focus, install callback, responsive layout, dark mode and offline reload.
Live HTTPS on both domains verified before and after switch, including worker
control after reload; no actual power/lighting commands sent. Caddy healthy,
no failed units. Physical installation remains user-driven and was not tested.
**Evidence:** [Angular migration](SYSTEM_CHANGELOG.md#completed-migrate-service-dashboard-to-angular--2026-10-24).

<a id="sys-032"></a>

### SYS-032 — Add HyperHDR to dashboard index

**Status:** DONE · **Closed:** 2026-10-24

Added and deployed HyperHDR service card in generation 213. Flake/full build,
test activation and switch passed. Browser verified card/link and click through
to HyperHDR Web Configuration, including dashboard reload after switch.
Caddy healthy, no failed units; root/ESP UUIDs unchanged. No reboot.
**Evidence:** [Dashboard card](SYSTEM_CHANGELOG.md#completed-add-hyperhdr-dashboard-card--2026-10-24).

<a id="sys-031"></a>

### SYS-031 — Expose HyperHDR through Caddy

**Status:** DONE · **Closed:** 2026-10-24

Activated and persisted as generation 212. Flake/dry/full builds and Caddy
adapt passed. Both HTTPS routes return UI 200 and WebSocket 101 with verified
certificates through local Caddy; local aliases and erebor tailnet URL return
200. Live/selected targets match; Caddy/HyperHDR active; no failed system/user
units. Root/ESP UUIDs unchanged; no reboot performed.
**Evidence:** [HyperHDR proxy](SYSTEM_CHANGELOG.md#completed-add-hyperhdr-to-caddy--2026-10-24).

<a id="sys-030"></a>

### SYS-030 — Make the service dashboard installable as a PWA

**Status:** DONE · **Closed:** 2026-10-24

Material UI 9.5.0 dashboard with top quick actions and installable PWA is
activated and persisted as generation 211. Flake/dry/full builds, mocked control
and offline checks passed. Live HTTPS HTML/worker match built assets; browser
verified responsive Material UI, manifest/icons, service links and controlling
worker with cached bundle. Caddy healthy; no failed system/user units. Physical
device installation is user-driven and was not performed. No reboot required.
**Evidence:** [PWA and Material UI deployment](SYSTEM_CHANGELOG.md#completed-enable-service-dashboard-pwa-and-material-ui--2026-10-24).

<a id="sys-029"></a>

### SYS-029 — Migrate to GRUB with wallpaper menu

**Status:** OPEN · **Reviewed:** 2026-10-23

Installed GRUB generation 210 as firmware default NixOS-boot (0000), with
current wallpaper, matching plum/cream/copper menu, five-second timeout and
EFI gfxpayload=keep. Flake/build/syntax/kernel/initrd/theme checks passed;
UEFI VM preview verified rendering at 1920x1080. Existing EFI files, systemd-boot
menu and prior firmware entries preserved; root snapshot/ESP archive verified.
Live remains 208; no reboot performed. Next check after user reboot:
BootCurrent=0000/GRUB, generation 210, physical menu readability, Linux boot,
Plymouth/login handoff and mounts/services. Windows/recovery chainloads not
boot-tested. Recovery: firmware Linux Boot Manager 0004 or GRUB recovery menu.
**Done when:** user confirms physical GRUB menu and Linux boot/handoff, with
post-boot generation/mount/service checks recorded.
**Evidence:** [GRUB installation](SYSTEM_CHANGELOG.md#completed-install-grub-with-current-wallpaper-menu-for-next-boot--2026-10-23).

<a id="sys-028"></a>

### SYS-028 — Resolve duplicate Noctalia startup

**Status:** OPEN · **Reviewed:** 2026-10-23

Generation 208 post-boot check: user `noctalia.service` failed with
start-limit-hit; journal repeatedly says `noctalia is already running`.
A separate `/run/current-system/sw/bin/noctalia` process is running (PID 3970
at inspection). No shell processes restarted during Plymouth verification.
**Done when:** establish the intended single startup owner, remove competing
launch declaratively and verify shell functionality and service health.
**Evidence:** [generation 208 post-boot check](SYSTEM_CHANGELOG.md#completed-install-bgrt-logo-and-faster-greeter-startup-for-next-boot--2026-10-23).

<a id="sys-027"></a>

### SYS-027 — Verify Plymouth boot splash

**Status:** DONE · **Closed:** 2026-10-23

Generation 208 booted/current verified with BGRT/SimpleDRM and greetd
Type=exec. User confirms firmware logo visible and gap shorter or gone.
Plymouth exit +11.158s to greeter first frame +12.848s: 1.69s gap, compared
with 7.60s on generation 207. Root/ESP UUIDs match and no failed system units.
Separate Noctalia duplicate startup tracked by SYS-028.
Temporary debug flag removed and installed as default generation 209; boot
entry checked, same kernel/initrd/theme as visually verified 208. Current
boot remains 208 with diagnostics until next normal reboot. No extra reboot
or live greeter restart performed. Recovery: 208 (BGRT with debug) or 205
(no Plymouth), plus verified recovery snapshots in the records below.
**Evidence:** [diagnostic cleanup](SYSTEM_CHANGELOG.md#completed-remove-temporary-plymouth-diagnostics-for-next-boot--2026-10-23),
[BGRT/greeter installation and boot verification](SYSTEM_CHANGELOG.md#completed-install-bgrt-logo-and-faster-greeter-startup-for-next-boot--2026-10-23),
[SimpleDRM diagnostics](SYSTEM_CHANGELOG.md#completed-install-plymouth-simpledrm-diagnostics-for-next-boot--2026-10-23).

<a id="sys-026"></a>

### SYS-026 — Make YubiKey touch prompts noticeable

**Status:** DONE · **Closed:** 2026-10-23

Activated persistent generation 203; user notifier enabled/running. Simulated
and real sudo touch requests show and dismiss the notification; user confirmed
notification and sound. Authentication rules unchanged; no failed units.

**Evidence:** [completed notifier](SYSTEM_CHANGELOG.md#completed-add-yubikey-touch-notification-and-sound--2026-10-23).

<a id="sys-025"></a>

### SYS-025 — Retire broken Fedora installation

**Status:** DONE · **Closed:** 2026-10-23

Removed Fedora-only boot files/firmware entries, root snapshot and unused
containers; verified protected EFI hashes, shared data mounts and services.
Btrfs completed reclamation; approximately 63.5 GiB free. Boot archives and
NixOS recovery snapshot retained; partitions unchanged. No reboot performed.

**Evidence:** [retirement record](SYSTEM_CHANGELOG.md#completed-retire-broken-fedora-installation--2026-10-23).

<a id="sys-024"></a>

### SYS-024 — Activate KDE Connect LAN firewall rules

**Status:** DONE · **Closed:** 2026-10-23

Activated persistent generation 199. Verified deployed firewall service and live
IPv4/IPv6 TCP/UDP 1714–1764 rules on br0, boot entry/default and system profile,
no failed units, and phone paired/reachable; user confirmed access. Configuration
commit d9edff3. Fedora menu entry removed by isolated activation was restored and
verified. Fedora was later intentionally retired under SYS-025.

**Evidence:** [completed change](SYSTEM_CHANGELOG.md#completed-persist-kde-connect-lan-firewall-rules--2026-10-23).

<a id="sys-001"></a>

### SYS-001 — Verify Fedora chainloading

**Status:** CANCELLED · **Closed:** 2026-10-23

User reported two failed Fedora boots. Read-only inspection found root/home
subvolumes missing; historical Btrfs output confirms they existed on Oct 18
at 02:13 Warsaw time and a complete directory listing shows them absent on
Oct 22 at 17:33. Exact deletion time/cause remains unknown. User chose to
retire Fedora, including the remaining root snapshot, under SYS-025.

**Evidence:** [retirement record](SYSTEM_CHANGELOG.md#completed-retire-broken-fedora-installation--2026-10-23);
[historical record](SYSTEM_CHANGELOG.md#record-sys-001-1).

<a id="sys-002"></a>

### SYS-002 — Verify physical display wake

**Status:** OPEN · **Reviewed:** 2026-10-23

Observed 2026-10-23: generation 198 boots Linux 6.18.57 / NVIDIA 615.78.08 without NVML mismatch or recorded modeset failures.

**Done when:** With remote recovery available and work saved, exercise dashboard display off/on and confirm a usable picture on the physical AW3423DWF. Record physical confirmation and kernel-log results.

**Evidence:** [historical record](SYSTEM_CHANGELOG.md#record-sys-002-1). See also the [related record](SYSTEM_CHANGELOG.md#record-sys-002-2).

<a id="sys-003"></a>

### SYS-003 — Verify T3 browser preview

**Status:** OPEN · **Reviewed:** 2026-10-23

Observed 2026-10-23: T3 is active with the declared library path; preview was not exercised.

**Done when:** Open a browser preview through T3 and confirm it renders successfully. Record the result; deployed libraries alone do not verify preview.

**Evidence:** [historical record](SYSTEM_CHANGELOG.md#record-sys-003-1).

<a id="sys-004"></a>

### SYS-004 — Verify dashboard sleep and shutdown

**Status:** OPEN · **Reviewed:** 2026-10-23

Observed 2026-10-23: deployment, seven tests, HTTPS ambilight actions and cross-origin rejection pass. Display wake is SYS-002.

**Done when:** When the user is ready for interruption, confirm dashboard sleep/resume and shutdown followed by successful startup. Record each separately; leave untested actions open.

**Evidence:** [historical record](SYSTEM_CHANGELOG.md#record-sys-004-1).

## Historical work to reconcile

These items are not newly verified failures. Review may close them without any
system change. The archive contains later records that may supersede them.

<a id="sys-005"></a>

### SYS-005 — Review HyperHDR capture target

**Status:** REVIEW · **Reviewed:** 2026-10-23

Observed 2026-10-23: saved portal selection is physical DP-1. Earlier work requested wallpaper-only ambilight; latest troubleshooting concerned reaction to display content.

**Done when:** Confirm the desired capture behavior before changing it. Verify either display-content response or wallpaper-only isolation, record the chosen behavior, and close or cancel the old request accordingly.

**Evidence:** [historical record](SYSTEM_CHANGELOG.md#record-sys-005-1).

<a id="sys-006"></a>

### SYS-006 — Reconcile historical Intel passthrough checkpoint

**Status:** REVIEW · **Reviewed:** 2026-10-23

Historical checkpoint describes Intel guest acceleration. Later GPU assignments changed; it is not a current activation instruction.

**Done when:** Compare current host/domain configuration with subsequent GPU changes. Close as superseded if replaced, otherwise identify and verify the specific missing acceptance check. Do not reapply old VFIO instructions.

**Evidence:** [historical record](SYSTEM_CHANGELOG.md#record-sys-006-1).

<a id="sys-007"></a>

### SYS-007 — Reconcile original Windows VM setup checkpoint

**Status:** REVIEW · **Reviewed:** 2026-10-23

Guest installation and later acceleration work are recorded elsewhere in the changelog.

**Done when:** Reconcile later VM setup/GPU records with the original acceptance criteria; close resolved or superseded work and retain only a specific remaining check.

**Evidence:** [historical record](SYSTEM_CHANGELOG.md#record-sys-007-1).

<a id="sys-008"></a>

### SYS-008 — Review failed historical Btrfs compaction

**Status:** REVIEW · **Reviewed:** 2026-10-23

The recorded bounded balance attempts failed with ENOSPC; this does not show that compaction is needed now.

**Done when:** Inspect current space and subsequent remediation records. Close the failed attempt with its outcome if no work remains; otherwise propose a current, bounded remediation. Do not retry balance from the old checkpoint.

**Evidence:** [historical record](SYSTEM_CHANGELOG.md#record-sys-008-1).

<a id="sys-009"></a>

### SYS-009 — Reconcile eza activation

**Status:** REVIEW · **Reviewed:** 2026-10-23

Historical build attempts failed with ENOSPC; later package/alias changes may supersede them.

**Done when:** Check current declarative/deployed eza and aliases and later records. Close if present and verified, or state the precise missing work before implementing anything.

**Evidence:** [historical record](SYSTEM_CHANGELOG.md#record-sys-009-1).

<a id="sys-011"></a>

### SYS-011 — Verify Niri startup placement

**Status:** REVIEW · **Reviewed:** 2026-10-23

Historical config validation/activation passed; fresh-session behavior was not confirmed.

**Done when:** At a planned Niri login, check the initial workspace and ordinary app placement against current configuration, or close as superseded if that behavior was removed.

**Evidence:** [historical record](SYSTEM_CHANGELOG.md#record-sys-011-1).

<a id="sys-012"></a>

### SYS-012 — Review Discord shortcut and tab indicator checks

**Status:** REVIEW · **Reviewed:** 2026-10-23

Historical direct Discord launch passed; physical key delivery and indicator appearance were unverified.

**Done when:** Inspect current bindings, then confirm Right Ctrl+D opens Discord and the intended tab indicator is visible in the applicable session; close superseded parts explicitly.

**Evidence:** [historical record](SYSTEM_CHANGELOG.md#record-sys-012-1).

<a id="sys-013"></a>

### SYS-013 — Reconcile session chooser verification

**Status:** REVIEW · **Reviewed:** 2026-10-23

Umbriel is now running, but the old entry required chooser verification for both sessions.

**Done when:** Inspect current session definitions and later login evidence; confirm Niri and Umbriel are available at a planned login or close as superseded by the current chooser design.

**Evidence:** [historical record](SYSTEM_CHANGELOG.md#record-sys-013-1).

<a id="sys-014"></a>

### SYS-014 — Review Tailscale backup workflow status

**Status:** REVIEW · **Reviewed:** 2026-10-23

Only an old requested-work record exists here; completion is not established.

**Done when:** Inspect tracked workflow and validation evidence, then close if verified or define remaining work. Preserve the original secret-handling constraints; do not create archives or expose keys during review.

**Evidence:** [historical record](SYSTEM_CHANGELOG.md#record-sys-014-1).

<a id="sys-015"></a>

### SYS-015 — Reconcile xremap device and mapping checks

**Status:** REVIEW · **Reviewed:** 2026-10-23

Historical notes report missing device access/devices; later records show successful xremap use.

**Done when:** Inspect current service/device access and later shortcut results, then verify the current mappings or close superseded device-reconnect instructions. Do not reboot merely to satisfy the old checkpoint.

**Evidence:** [historical record](SYSTEM_CHANGELOG.md#record-sys-015-1). See also the [related record](SYSTEM_CHANGELOG.md#record-sys-015-2).

<a id="sys-016"></a>

### SYS-016 — Review lingering and Oo7 login verification

**Status:** REVIEW · **Reviewed:** 2026-10-23

Historical activation checks passed; deliberate logout/login and keyring unlock were still unconfirmed.

**Done when:** Compare current PAM/linger configuration and later login evidence; verify the intended login/keyring behavior during a planned session transition or close superseded requirements. Do not read keyring secrets.

**Evidence:** [historical record](SYSTEM_CHANGELOG.md#record-sys-016-1).

<a id="sys-017"></a>

### SYS-017 — Reconcile bridge persistence and client playback

**Status:** REVIEW · **Reviewed:** 2026-10-23

Historical host/guest LAN probes passed. A later UEFI checkpoint states bridge persistence was resolved.

**Done when:** Close the old activation step using later evidence; verify whether playback from a separate physical LAN client remains relevant and untested, and record that result separately.

**Evidence:** [historical record](SYSTEM_CHANGELOG.md#record-sys-017-1).

<a id="sys-018"></a>

### SYS-018 — Close historical firmware-reboot checkpoint

**Status:** REVIEW · **Reviewed:** 2026-10-23

The record contains a 2026-10-20 pre-reboot checkpoint; current NixOS has since booted generation 198.

**Done when:** Check available evidence or user confirmation of the firmware visit and close the historical operation as completed or outcome unknown. Do not schedule another firmware reboot or rely on pruned generation 172.

**Evidence:** [historical record](SYSTEM_CHANGELOG.md#record-sys-018-1).

<a id="sys-019"></a>

### SYS-019 — Reconcile lsof activation

**Status:** REVIEW · **Reviewed:** 2026-10-23

Historical build passed; installed-command verification was pending.

**Done when:** Check the current declared package and installed lsof command, and close with observed evidence or a specific remaining task.

**Evidence:** [historical record](SYSTEM_CHANGELOG.md#record-sys-019-1).

<a id="sys-020"></a>

### SYS-020 — Reconcile Zen Browser deployment

**Status:** REVIEW · **Reviewed:** 2026-10-23

Historical user-profile installation existed; declarative deployment and duplicate cleanup were pending.

**Done when:** Verify the current declarative/deployed browser and profile ownership. Close deployment with evidence; identify any redundant user-profile entry before considering removal.

**Evidence:** [historical record](SYSTEM_CHANGELOG.md#record-sys-020-1).

<a id="sys-021"></a>

### SYS-021 — Reconcile Mango login and persistence

**Status:** REVIEW · **Reviewed:** 2026-10-23

Later completed Mango records show activation and live use, so the old test-generation instructions may be stale.

**Done when:** Reconcile later persistent activation and hardware-login evidence. Close resolved steps and retain only any specific missing chooser or input check; do not restart greetd as a review step.

**Evidence:** [historical record](SYSTEM_CHANGELOG.md#record-sys-021-1).

<a id="sys-022"></a>

### SYS-022 — Finish Crucial Windows VM relocation

**Status:** DONE · **Closed:** 2026-10-23

Verified identical offline image contents and healthy qcow2 metadata, switched
only vda to Crucial UUID 604F-A363, verified Windows desktop/guest agent/network
and no disk errors, shut down cleanly and removed live local original.
VM remains off. Recovery XML/NVRAM/TPM and read-only root snapshot ID 657
retained. Other snapshots still hold 110.37 GiB of shared original disk blocks;
removing those is outside this relocation. Main filesystem has about 63 GiB free.

**Evidence:** [completed relocation](SYSTEM_CHANGELOG.md#completed-finish-windows-vm-relocation-to-crucial--2026-10-23);
[historical record](SYSTEM_CHANGELOG.md#record-sys-022-1).

<a id="sys-023"></a>

### SYS-023 — Review Mango Moonlight acceptance check

**Status:** REVIEW · **Reviewed:** 2026-10-23

Isolated compositor/NVENC tests passed; end-to-end Moonlight and persistent deployment were unverified in the old record.

**Done when:** Inspect current deployed unit and any obsolete runtime drop-in; reconcile later activation evidence and verify Moonlight in a planned Mango session. Do not end the current session during review.

**Evidence:** [historical record](SYSTEM_CHANGELOG.md#record-sys-023-1).

## Closed tasks

<a id="sys-010"></a>

### SYS-010 — Umbriel background workspace startup check

**Status:** CANCELLED · **Closed:** 2026-10-23

Superseded by the completed 2026-10-20 replacement of background-apps with native scratchpad.

**Closure:** No action. The former startup-helper verification no longer applies; do not restore the removed helper.

**Evidence:** [historical record](SYSTEM_CHANGELOG.md#record-sys-010-1).

## Adding or closing a task

Use the next unused SYS number (currently SYS-028). Record status, review date,
what remains, a concrete completion condition, and a link to evidence. For active
work, record the next safe step and any applicable recovery checkpoint. Required
acceptance checks block completion of that task; optional follow-ups get their
own ID. On closure, add the date and observed result, user confirmation, or
superseding change. Never infer successful activation from a build alone.
