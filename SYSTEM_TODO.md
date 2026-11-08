# System tasks for `erebor`

Current unfinished work belongs here. History and dated evidence belong in
[SYSTEM_CHANGELOG.md](SYSTEM_CHANGELOG.md); recovery knowledge belongs in
[SYSTEM_CONTEXT.md](SYSTEM_CONTEXT.md). Updated: 2026-11-08.

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

<a id="sys-081"></a>

### SYS-081 — Land the dendritic migration and the adoption stack

**Status:** OPEN · **Review:** 2026-11-15

Branches `agent/dendritic` (migration, equivalent to master) and `agent/adopt`
(built on it: `my.*` assertions, eval tests, pinned inputs, live desktop
configs, AGENTS.md skills, weekly update branch, sops-nix, Starship layout,
the Mac's nix-darwin config, agent shell fix). Rebase `agent/adopt` on master,
re-run `nix flake check`, `scripts/erebor-rebuild build` and `erebor-diff`,
merge, then `scripts/erebor-rebuild switch`.

Done when, after the switch: `~/.config/{umbriel,noctalia,niri}` files resolve
into `/etc/nixos`; `/run/secrets/rendered/searxng.env` exists and SearXNG
answers; `erebor-update-branch.timer` is listed; `t3code` restarted and a new
agent's shell has git on PATH; the user has logged out and in once
(CLAUDE_CODE_SHELL); the hand-added `env` in `~/.claude/settings.json` is
removed; the personal age key `~/.config/sops/age/keys.txt` is backed up
offline (user confirms). Then remove both worktrees and branches.

<a id="sys-082"></a>

### SYS-082 — Generated reference for the `my.*` options

**Status:** OPEN · **Review:** 2026-12-08

Generate `docs/my-options.md` from the option declarations with
`pkgs.nixosOptionsDoc`, filtered to `my.*`, evaluated from the template host
so defaults are not erebor's values; give computed defaults a `defaultText`;
rewrite declaration links from `/nix/store/...` to repo paths. Add
`nix run .#write-docs` and a flake check that fails when the committed file is
stale. Replace the hand-written table in `README.md` (already missing
`my.timeMachine`, `my.torrentVpn`, `my.services.*` fields, `my.flakePath`,
`my.updateBranch`) with a link. Needs [SYS-081](#sys-081).

Done when: the check fails on a stale file and passes after `write-docs`;
erebor's `erebor-diff` tier is identical.

<a id="sys-083"></a>

### SYS-083 — Make the weekly update report decision-ready

**Status:** OPEN · **Review:** 2026-12-08

`scripts/erebor-update-branch` always reports tier "different" after a
nixpkgs bump, which says nothing. Add to its report: a package version diff
between master's system and the new build (`nvd diff`, or
`nix store diff-closures`), and for every input pinned in `flake.nix` the
upstream head and how many commits it is ahead of the pin (`git ls-remote`,
no build). Consider moving the run from Sunday 03:00 to a time erebor is
usually on and idle. Needs [SYS-081](#sys-081).

Done when: one real timer run produced a branch whose report lists changed
package versions and behind-by counts for pinned inputs.

<a id="sys-084"></a>

### SYS-084 — Syncthing via the NixOS module with a fixed identity

**Status:** OPEN · **Review:** 2027-01-08

Syncthing runs as the upstream container (`modules/services/syncthing.nix`,
state in `/srv/syncthing/config/`) and is unused: no peers, one empty folder
entry (checked 2026-11-08). Do this when the first peer or folder is wanted:
replace the container with `services.syncthing`, move the existing
`cert.pem`/`key.pem` into sops so the device ID stays, declare devices and
folders with `overrideDevices`/`overrideFolders`, and keep the Caddy route
and `my.services.syncthing` registry. On the Mac use Home Manager's
`services.syncthing`. If still unused at review, disable
`my.services.syncthing.enable` instead and close this.

Done when: the device ID is unchanged after the switch and a declared folder
syncs with one peer.

<a id="sys-085"></a>

### SYS-085 — Mac: zsh login shell, Nix fish in terminals

**Status:** OPEN · **Review:** 2026-11-22

On `darwinConfigurations.macbook`: keep `/bin/zsh` as the login shell with
`programs.zsh.enable`; enable nix-darwin `programs.fish` and point Ghostty
(`command`) and other terminals at `/etc/profiles/per-user/janzon/bin/fish`;
drop the Homebrew `fish` entry (fisher stays; its plugins live in
`~/.config/fish`). Keep Secretive's `SSH_AUTH_SOCK`. Do before the Mac's
first apply ([SYS-086](#sys-086)). Needs [SYS-081](#sys-081).

Done when: the Mac config evaluates; after apply, SSH commands run in zsh,
new Ghostty windows open Nix fish with Starship, fisher and nvm working.

<a id="sys-086"></a>

### SYS-086 — Bootstrap the Mac with nix-darwin

**Status:** OPEN · **Review:** 2026-11-22

Follow `docs/mac.md`: install Determinate Nix, then the first
`sudo nix run nix-darwin -- switch --flake .#macbook` (needs the user's
password on the Mac). The first apply moves `~/.config/nvim` and
`config.fish` to `*.backup`, enables Dock autohide and Touch ID for sudo, and
removes no Homebrew app (`cleanup = "none"`). Needs [SYS-085](#sys-085).

Done when: `darwin-rebuild switch` succeeds; nvim, Ghostty, fish and the
Mac's Starship prompt work; Touch ID sudo works; no Homebrew app is gone.

<a id="sys-074"></a>

### SYS-074 — Move Caddy's OVH credentials into sops

**Status:** OPEN · **Review:** 2026-12-08

sops-nix is set up ([changelog](SYSTEM_CHANGELOG.md), `secrets` skill) and
SearXNG's key already comes from `secrets/erebor.yaml`. Caddy still reads the
OVH DNS API credentials from the root-owned `/etc/caddy/ovh.env`, which an
agent cannot read without the user's touch approval. Follow "Moving an
existing credential into sops" in `.claude/skills/secrets/SKILL.md`.

Done when: Caddy's `environmentFile` is a `sops.templates` file, a
certificate renewal or `caddy validate` authenticates with OVH after
activation, `/etc/caddy/ovh.env` is deleted with the user's approval, and
`/var/lib/searxng-secret/` is removed.

<a id="sys-088"></a>

### SYS-088 — One file per task, with a monthly archive for closed tasks

**Status:** ACTIVE · **Review:** 2026-11-15

User request 2026-11-08: replace `SYSTEM_TODO.md` with one file per task under
`tasks/`, status in a header, closed tasks shrunk to stubs and archived by
month, a `scripts/erebor-tasks` board, and a flake check for IDs and links.
In progress on branch `agent/tasks-refactor`.

<a id="sys-087"></a>

### SYS-087 — Epic: guest-safe game streaming and hub-managed guest access

**Status:** OPEN · **Review:** 2026-11-22 · **Children:** [SYS-075](#sys-075),
[SYS-076](#sys-076), [SYS-077](#sys-077), [SYS-078](#sys-078),
[SYS-079](#sys-079), [SYS-080](#sys-080)

Goal (user, 2026-11-08): the owner streams games through Moonshine as usual.
Occasional guests can stream games, and optionally install owned games, and
use the services enabled for them in the hub. Guests include all tailnet
members other than the owner, and friends who get erebor shared to them.
Guests get no file browsing, no other software, no other devices and no admin
services. The same Steam install and account serve the desktop and the stream
(never at the same time). Adding, seeing and removing guests happens in the
hub, which also documents the manual steps.

| Order | Task | Delivers | Depends on |
|---|---|---|---|
| 1 | [SYS-075](#sys-075) | Pairing only through the hub (closes the remote PIN hole) | — |
| 2 | [SYS-076](#sys-076) | Per-game tiles, sandboxed sessions, no Steam UI | — |
| 3 | [SYS-077](#sys-077) | Hub decides access to every `*.erebor` service; admin sites owner-only | — |
| 4 | [SYS-078](#sys-078) | Tailnet guest policy with tests; erebor guest firewall | 077 before guests use 443 |
| 5 | [SYS-079](#sys-079) | Hub Access page, invites, removal, timed streaming switch | 075, 078 |
| 6 | [SYS-080](#sys-080) | Hub-unlocked Steam Library tile for installs | 076, 079 |

Milestone: when SYS-075 through SYS-078 are done, it is safe to let a guest
in. SYS-079 and SYS-080 add convenience.

Done when: every child is DONE, and one end-to-end check with a real guest
account and device passes. The guest is invited from the hub, pairs, streams
a game, and opens one allowed service. They are refused an owner-only
service, SSH and another tailnet device, and see nothing outside the Steam
folders. They lose all access after Remove, and the owner's desktop and
devices are unchanged. Close the epic with that evidence; child tasks keep
their own records.

<a id="sys-075"></a>

### SYS-075 — Accept Moonshine PINs only from erebor itself

**Status:** OPEN · **Review:** 2026-11-15 · **Epic:** [SYS-087](#sys-087)

Security fix; do first. Found 2026-11-08 while reading the source of Moonshine
0.16.1 (upstream `8247857`, same version as the installed package). `GET /pin`
and `POST /submit-pin` (`src/webserver/mod.rs:408`, `submit_pin` at line 635)
are served on the public HTTP port 47989 and only check
`webserver.enable_pairing` (default `true`, unset in `modules/moonshine.nix`).
They do not check the peer address, and the port is open (`openFirewall = true`).
So any device that can reach 47989 (LAN, tailnet, shared users) can start
pairing in Moonlight and submit its own PIN. Not reproduced against erebor yet.

Plan:

1. Add a small patch to the Moonshine package (overlay or
   `services.moonshine.package`) that rejects `/pin` and `/submit-pin` unless
   the peer address is loopback or one of erebor's own addresses. The hub
   already submits from `127.0.0.1:47989` (`control.moonshineUrl`,
   [SYS-069](#sys-069)), so hub pairing keeps working. The desktop "Enter PIN"
   notification opens `http://<local address>:47989/pin`, which is a local peer.
2. Write the patch with a test, and offer it upstream (user's choice).
3. Note in SYSTEM_CONTEXT.md that unpairing is a no-op (`unpair()` returns
   200 and does nothing); paired certificates live in
   `~/.local/share/moonshine/state.toml` (`paired_certs`), and removing a
   client means editing that file and restarting `moonshine.service`.

Done when: a submission from another LAN/tailnet device gets 403 (curl to
`/submit-pin` from the MacBook), and a real Moonlight client still pairs
through the hub. Recovery: drop the patch and set `enable_pairing = false`.
Related: [SYS-069](#sys-069), [SYS-076](#sys-076).

<a id="sys-076"></a>

### SYS-076 — Guest-safe Moonshine streaming: game tiles and session sandbox

**Status:** OPEN · **Review:** 2026-11-22 · **Epic:** [SYS-087](#sys-087)

User wants streamed sessions limited to games, with no file browsing or other
software, for themselves and occasional guests. One Steam install is shared
with the desktop; the desktop and a stream are never played at the same time.
Decided 2026-11-08: one Linux user with a sandbox, not a separate streaming
user (separate users would split Proton prefixes and saves and need a moved,
group-shared library; see the discussion behind [SYS-080](#sys-080)).

Findings (Moonshine 0.16.1 source, upstream `8247857`):

- Each app runs in Moonshine's own headless compositor; the desktop is never
  visible to the client.
- Apps are started as a transient user unit, `moonshine-session.service`, in
  `user@1000` through `StartTransientUnit`. Confirm the name during a live
  stream (`systemctl --user status moonshine-session`).
- The `steam` application scanner rescans on every Moonlight app-list request
  when `libraryfolders.vdf` or any `appmanifest_*.acf` changes
  (`src/webserver/mod.rs` `app_list`, `src/app_scanner/steam.rs`
  `source_fingerprint`), so installs and uninstalls show up without a restart.
- Moonshine passes the client's resolution and frame rate to the app, but not
  which client it is. Any tile is visible to every paired client.

Plan (`modules/moonshine.nix`, Home Manager for the drop-in):

1. Replace the "Steam Big Picture" application with an `application_scanner`
   of `type = "steam"`, `library = "$HOME/.local/share/Steam"`, command
   `steam -silent steam://rungameid/{game_id}`. Check that `-silent` keeps the
   Steam window off the stream.
2. Add `pre_command = steam -shutdown` (wait until it exits), so a desktop
   Steam that was left open closes. Otherwise the launch is handed to the
   unsandboxed desktop instance and may open on the monitor.
3. Add the drop-in `~/.config/systemd/user/moonshine-session.service.d/sandbox.conf`:
   `TemporaryFileSystem=%h`, `BindPaths=%h/.local/share/Steam %h/.steam`,
   `NoExecPaths=/`, `ExecPaths=/nix/store %h/.local/share/Steam`. Add
   `BindPaths` for any game that saves outside the Steam folder (check the
   played games' save locations).
4. Turn off the Steam overlay (Steam settings → In game) so Shift+Tab gives no
   browser. Record it in SYSTEM_CONTEXT.md, as it is not declarative.

Done when: tiles list exactly the installed Steam games; a game launches over
a real Moonlight stream with nothing else visible; inside a game, a file
dialog shows only the Steam folders and nothing under `~` can be run; a
Proton game's save written during the stream is present on the desktop; the
desktop Steam works afterwards; installing a game on the desktop adds a tile
after a Moonlight refresh. Risks: in a user unit these options also put the
session in its own user namespace, and Steam's bubblewrap must work nested
inside it. Recovery: remove the drop-in and restore the Big Picture
application. Related: [SYS-053](#sys-053), [SYS-075](#sys-075).

<a id="sys-077"></a>

### SYS-077 — Hub as gatekeeper for every `*.erebor` service

**Status:** OPEN · **Review:** 2026-11-29 · **Epic:** [SYS-087](#sys-087)

Guests (tailnet members and shared friends, [SYS-078](#sys-078)) will reach
erebor's port 443, where every Caddy site lives (`modules/workstation/caddy.nix`).
The hub's per-user visibility only hides links ([SYS-068](#sys-068); README:
"hiding a service only removes its link and does not protect the service
itself"). Sites that must never reach a guest: `sys` (Cockpit, root),
`code` (T3 Code, runs commands as janzon), the browser terminal and browser
desktop, `sync` (Syncthing), `torrent` (qBittorrent).

Plan:

1. Add `my.services.<name>.access` with values `owner` / `hub` / `public`,
   defaulting to `owner`. Mark the services above `owner`; candidates for
   `hub` are `media` (Jellyfin) and `cloud` (Nextcloud).
2. Dashboard API: add a `forward_auth` check endpoint (for example
   `GET /api/control/authz?service=<id>`). Return 200 for owner devices
   (tailnet identity, see step 4) or for a signed-in user allowed that service.
   Return 401 or 403 otherwise, and never allow `owner` services for
   non-owners.
3. The session cookie is currently scoped to `/api/control` on the hub host
   (`SameSite=Strict`). Scope it to `.<domain>` so subdomains send it, or add
   a short-lived per-subdomain token handed over by the hub.
4. Owner device identity: Caddy cannot ask Tailscale directly. Either the API
   resolves the client IP with the `tailscale whois` local API, or a list of
   owner device addresses is generated from config. LAN clients
   (`private_ranges`) count as owner, as they do now for `dashboard_controls`.
5. Generate `forward_auth` into each `publicRoutes` block in `caddy.nix`. LAN
   blocks (`lanPorts`) stay LAN-only.

Done when: from a guest test account and device, an allowed service opens
after hub sign-in, a non-allowed one is refused, and every `owner` service
returns 403 even with hub permission set; owner devices and the LAN see no
change. Related: [SYS-068](#sys-068), [SYS-078](#sys-078).

<a id="sys-078"></a>

### SYS-078 — Tailnet guest policy and erebor guest firewall

**Status:** OPEN · **Review:** 2026-11-29 · **Epic:** [SYS-087](#sys-087)

User decision 2026-11-08: everyone except the owner is a guest. Guests may
only stream games and use the services enabled for them in the hub, with no
other privileges. `tailscale status` on 2026-11-08 shows a second member,
a guest login ("MacBook Pro (Zordon)"), who currently reaches
other devices (user report). No device advertises subnet routes or an exit
node, so the LAN is not reachable through Tailscale. Shared users only ever
see the machines shared with them.

Plan:

1. Keep the tailnet policy in this repo (`tailscale/policy.hujson`):
   - the owner gets `*`;
   - `autogroup:member` gets only `autogroup:self`;
   - `group:guests` and `autogroup:shared` get erebor
     (`100.108.216.80`) on `tcp:443`, `tcp:47984`, `tcp:47989`, `tcp:48010`
     and `udp:47998-48000`.
   Include `tests`: owner accepts `erebor:22` and the NanoKVM; a guest accepts
   `erebor:443` and `erebor:47989` but is denied `erebor:22`, `erebor:8384`,
   the NanoKVM and the Steam Deck. Keep the Tailscale SSH rule
   (`autogroup:member` → `autogroup:self`, `check`). Merge any sections the
   live policy already has; first read it in the admin console or through the
   API.
2. Apply the policy: the user pastes it, or a Tailscale OAuth client with the
   `policy_file` scope does it (secret via a private prompt, outside the store).
3. erebor firewall, second layer: on `tailscale0`, guest ports are open to
   all tailnet peers; every other TCP/UDP port (currently 22, 80, 443 extras,
   22000) is open only to owner devices. Generate the owner device list, or
   refresh it from `tailscale status --json` (UserID of the owner) in a small
   service.

Done when: the policy tests pass in Tailscale; from Karol's (or a test guest)
device only the guest ports on erebor answer and no other device does; owner
devices reach everything as before. Related: [SYS-077](#sys-077),
[SYS-079](#sys-079).

<a id="sys-079"></a>

### SYS-079 — Hub Access page: guests, share invites, streaming switch

**Status:** OPEN · **Review:** 2026-12-06 · **Epic:** [SYS-087](#sys-087)

Make the hub the one place to add, see and remove guests. Tailscale API
findings (OpenAPI spec, 2026-11-08):

- **Create invite:** `POST /api/v2/device/{deviceId}/device-invites` with
  `multiUse`, `allowExitNode` and `email`. It cannot use an OAuth client
  token, only a personal API access token, which expires after at most 90 days.
- **List and delete invite:** `GET /api/v2/device/{deviceId}/device-invites`
  and `DELETE /api/v2/device-invites/{id}`, with OAuth scopes
  `device_invites:read` and `device_invites`. Revoking an accepted invite
  removes the recipient's access.
- Recipients accept in their own (personal) tailnet. A revoked share needs a
  new invite.

Plan (dashboard app plus `modules/dashboard-control.nix`):

1. Admin-only "Access" page.
   - **Lists:** tailnet members, accepted share invites (`acceptedBy`) and
     `group:guests` from [SYS-078](#sys-078), matched to hub accounts.
   - **Manual steps:** a short written guide for doing the same by hand in the
     Tailscale admin console.
2. Invite: create the link manually in the admin console (once per friend), or
   through the API with a personal token stored as a secret. The hub warns
   before the token expires. Show the link as text or QR, and create the
   matching hub account with its services and actions.
3. Remove: delete the invite (OAuth client), remove the member from
   `group:guests`, and disable the hub account.
4. Friends-streaming switch ("Friends can stream for N hours", per account
   permission): erebor's firewall opens Moonshine ports to guest devices only
   while it is on, and turns it off automatically. Owner devices are always
   allowed. A paired guest who reconnects later is blocked while the switch is
   off.
5. Guest pairing: grant `moonshine-pair` to guest accounts so they pair their
   own devices ([SYS-075](#sys-075)).

Done when: a test guest is invited, accepts, signs in, pairs and streams with
the switch on, is blocked with it off, and loses all access after Remove.
Secrets: OAuth client (`device_invites`, `policy_file`) and optional personal
token, never in the store or repo. Related: [SYS-068](#sys-068),
[SYS-078](#sys-078).

<a id="sys-080"></a>

### SYS-080 — Hub-unlocked Steam Library tile for installing games

**Status:** OPEN · **Review:** 2026-12-13 · **Epic:** [SYS-087](#sys-087)

Let permitted guests install owned games from Moonlight. Moonshine lists only
installed games, and a tile cannot be hidden from some clients
([SYS-076](#sys-076) findings).

Plan:

1. Add a "Steam Library" application: Big Picture inside the
   [SYS-076](#sys-076) sandbox, started through a wrapper that exits at once
   unless an unlock flag exists and has not expired (for example
   `$XDG_RUNTIME_DIR/moonshine-library-until`).
2. Hub action "Allow installing games for 2 hours", granted per account. It
   writes the flag; the flag expires automatically.
3. Before enabling it for anyone, the owner removes the saved payment method
   from Steam and keeps Steam Guard on the phone. Inside Steam a guest still
   acts as the owner's account (store, chat, settings), and nothing on the
   Linux side can block that.
4. Considered alternative: a "Request a game" card. It lists owned games
   (needs a Steam Web API key as a secret), and the owner approves by
   installing remotely from the Steam mobile app. It is safer but slower;
   build it only if the user prefers it.

Done when: with the flag absent the tile exits immediately; after unlocking, a
test account installs an owned game, which then appears as its own tile; the
flag expires on time; file and exec limits hold in Big Picture (a "Browse"
dialog shows only the Steam folders, and a downloaded file cannot be run).
Depends on [SYS-076](#sys-076) and [SYS-079](#sys-079).

<a id="sys-073"></a>

### SYS-073 — GPU passthrough as a GRUB specialisation

**Status:** OPEN · **Review:** 2026-12-08

Planned, not started. Make the RTX 4090 passthrough mode a boot-menu choice
instead of an edit, rebuild and reboot: the erebor host gets
`specialisation.gpu-passthrough.configuration.virtualisation.windowsGpuPassthrough.enable = true;`
while its default stays `false`. GRUB then offers the default entry (NVIDIA on
Linux) and a "gpu-passthrough" entry (vfio-pci on the 4090, Linux on the Intel
UHD 770). The `windows-vm-gpu` service already reconciles the domain at each
boot in either direction ([windows-vm.md](docs/windows-vm.md)).

Plan:

1. Prerequisite: a verified pre-change root snapshot. Snapper is not
   configured, so either set it up first or use a manual read-only
   `/btrfs-top` snapshot as earlier changes did.
2. Make NVIDIA-dependent services follow the mode: Sunshine
   (`encoder = "nvenc"`, CUDA build) and Ollama (`ollama-cuda`, `sm_89`) need
   an Intel or CPU fallback, or must be off under passthrough. Check Moonshine
   and anything else that assumes NVIDIA (not yet inspected).
3. Check the Intel-only desktop: Umbriel output names (config and the HDR
   toggle hard-code `DP-1`), refresh rate and HDR on the motherboard output.
4. Add the specialisation; build both systems and confirm GRUB lists both
   under the 15-generation limit. ESP had 5.1 GB free on 2026-11-08.
5. Document the procedure in `docs/windows-vm.md`: shut down Windows, choose
   the entry at boot, and move the monitor cable to the motherboard output
   (or back). Live switching between specialisations is not supported, as the
   GPU binds early in boot.

Done when: the default entry boots unchanged; the gpu-passthrough entry boots
with both NVIDIA functions on vfio-pci, Intel on i915 and the Linux desktop
usable; `windows11` starts with the 4090 assigned; booting the default entry
again returns the GPU to Linux with no failed units. Optional follow-up:
retest Looking Glass with the 4090 in the guest. Recovery: choose the default
GRUB entry; the domain backups under `/var/lib/windows-vm-recovery/` are
unchanged. Related: [SYS-006](#sys-006).

Measured 2026-11-08 by building generation 317's config with the option
forced on (not activated): the host's explicit `false` needs `lib.mkForce true`
in the specialisation. Cost per generation: 111 MiB of extra store paths
(55 MiB initrd without NVIDIA modules, plus kernel modules, hwdb and Steam's
FHS root); unchanged paths are shared between generations. ESP: one extra
55 MiB initrd per distinct initrd (default initrd 140 MiB, 5.1 GB free).

<a id="sys-072"></a>

### SYS-072 — Move erebor to nixos-unstable

**Status:** DONE (2026-11-06) · **Review:** —

User asked to move the whole system from nixos-26.05 to nixos-unstable, mainly
to replace Qt 6.11 with Qt 6.12 everywhere. Completion: the system and Home
Manager evaluate from unstable, the generation is activated and booted with no
failed units, the desktop session, NVIDIA, Sunshine and Vicinae work, and no
Qt 6.11 remains in the system closure. Recovery: boot generation 301 (last
26.05 generation) from GRUB.
Done: generation 303 booted with no new failed units; desktop, oo7 login
unlock, NVIDIA, moonshine and Vicinae work; no Qt 6.11 in the closure. The
Windows VM firmware paths were fixed in generation 304; booting Windows on
the new firmware is untested. **Evidence:**
[Move to nixos-unstable](SYSTEM_CHANGELOG.md#move-to-nixos-unstable--2026-11-06).

<a id="sys-071"></a>

### SYS-071 — Dashboard per-user layout edit mode

**Status:** REVIEW · **Review:** 2026-11-12

Pencil edit mode with wiggle, drag/keyboard reordering of cards, action tiles and
services, 1-unit spacers (generation 274), foldable sections with a draggable
fold line (generation 275), heading-click folding with spring animations and the
terminal in in-page windows on erebor.jzon.pl (generation 276; multiple windows
with a dock in generation 277; tab mode in generation 278; translucent blurred terminal in generation 279), hiding, a Show hidden
toggle (all stored per account), and the install hint hidden in installed mode.
Activated in generation 273, with the service, DB migration and endpoint verified.
Completion: the user arranges the dashboard on a phone and on desktop and confirms
the layout follows the account. **Evidence:**
[Layout edit mode](SYSTEM_CHANGELOG.md#dashboard-per-user-layout-edit-mode--2026-11-05).

<a id="sys-070"></a>

### SYS-070 — Dashboard recent accounts and performance profiles

**Status:** REVIEW · **Review:** 2026-11-12

Per-device recent-account tiles on the sign-in screen and a Performance profile
card in quick actions. Activated in generation 270, with service, polkit and API
verified. Completion: the user signs in from a tile and switches profiles from
the dashboard. **Evidence:**
[Recent accounts and profiles](SYSTEM_CHANGELOG.md#dashboard-recent-accounts-and-performance-profiles--2026-11-05).

<a id="sys-069"></a>

### SYS-069 — Moonlight pairing from the dashboard hub

**Status:** REVIEW · **Review:** 2026-11-12

User requested Moonshine pairing in the hub. Dashboard commit `9d08128` adds the
`moonshine-pair` action: a PIN card that submits to Moonshine's local
`/submit-pin` for the newest waiting client (IDs from the moonshine journal,
fallback `0123456789ABCDEF`). Activated in generation 267 from a tree excluding
other in-progress edits. API tests (56), flake checks, and a local browser run
against live Moonshine (PIN filtering, "nothing waiting" error) passed.
Completion: pair a real Moonlight client through the hub. **Evidence:**
[Moonlight pairing](SYSTEM_CHANGELOG.md#moonlight-pairing-in-the-dashboard-hub--2026-11-05).

<a id="sys-068"></a>

### SYS-068 — Dashboard user accounts and per-user visibility

**Status:** ACTIVE · **Review:** 2026-11-06

User requested accounts: a first-run wizard creates the administrator, who chooses
the modules, services and actions each user sees. Implemented in dashboard commit
`e0d1859` (API accounts/sessions in `~/.local/state/erebor-dashboard`, filtered
config, server-side action enforcement, setup/login/user-management UI). API tests,
dashboard `nix flake check`, parent flake check and `nixos-rebuild build` passed; a
local Caddy+API browser run verified setup, user creation, restricted view and the
cached view while the API is down. Completion: activate, complete the setup wizard
on the live dashboard, verify a restricted user and the wake flow, and push the
dashboard submodule. Activated 2026-11-05 in generation 266 (`switch`); live
dashboard serves the wizard, unauthenticated API calls return 401. Setup wizard
completed by the user (session endpoint reports no setup required). Dashboard `9d08128`
and parent pushed 2026-11-05. Remaining: restricted-user and wake checks. **Evidence:** [Dashboard accounts](SYSTEM_CHANGELOG.md#dashboard-user-accounts--2026-11-05).

<a id="sys-067"></a>

### SYS-067 — Install Monstar terminal

**Status:** DONE · **Closed:** 2026-11-05

Add upstream Monstar to Home Manager. Completion: build and activate the intended
configuration, then verify the executable and graphical launch. Activated in
generation 266 (`monstar --version` 1.1.0); user launched it graphically.
Super+T tabs and terminal keymaps activated in generation 268; user confirmed
Super+T and Ctrl+D. **Evidence:** [Monstar preparation](SYSTEM_CHANGELOG.md#monstar-preparation--2026-11-05),
[Monstar activation](SYSTEM_CHANGELOG.md#monstar-activation-tab-key-and-terminal-keymaps--2026-11-05).

<a id="sys-066"></a>

### SYS-066 — Enable browser terminal file transfers

**Status:** DONE · **Closed:** 2026-11-05

Enable ttyd trzsz support and install trz/tsz declaratively. Completion:
flake/build checks, browser upload/download content verification, activation
and live tool/service/access-gate verification. Build and isolated Chromium
transfers passed with exact binary content and Unicode filename. User activated
the helper; verified live/selected generation 265, tools 1.2.0, enabled ttyd
option, preserved fonts, active services, no failed units and HTTPS auth gate.
Native picker/directory transfers untested; helper superseded.
**Evidence:** [completed file transfer deployment](SYSTEM_CHANGELOG.md#completed-ttyd-file-transfers--2026-11-05).

<a id="sys-065"></a>

### SYS-065 — Serve Nerd Fonts with the browser terminal

**Status:** DONE · **Closed:** 2026-11-05

Bundle web fonts and select them in ttyd so eza icons work without client
font installation. Completion: build/check, browser font/icon verification,
activation and live service/routing checks. Added a small legacy-block fallback
and corrected ttyd's font-family parsing. Flake/full build and Chromium logo/eza
checks passed; Touch ID test/switch succeeded as generation 264 with verified
readonly recovery snapshot. Live page, fallback list, protected fonts, matching
profiles and healthy services verified. Actual user-browser appearance after
activation remains unobserved. The activation helper is superseded.
**Evidence:** [completed logo/font deployment](SYSTEM_CHANGELOG.md#completed-ttyd-legacy-logo-glyphs--2026-11-05).

<a id="sys-064"></a>

### SYS-064 — Bound Mac approval wait for sudo and Polkit

**Status:** OPEN · **Review:** 2026-11-05

30-second timeout persistently activated; sudo Touch ID and transition to the
password prompt after timeout were verified. Completion: confirm actual password
entry and desktop Polkit approval and timeout behavior. Flake, dry-build and
system build passed; no failed system units.
**Evidence:** [activation record](SYSTEM_CHANGELOG.md#completed-mac-approval-timeout--2026-11-05).

<a id="sys-063"></a>

### SYS-063 — Add browser terminal and hub card

**Status:** DONE · **Closed:** 2026-11-05

Deploy ttyd as janzon at terminal.erebor.jzon.pl with the existing desktop
runtime password and Tailscale gates; add the dashboard link. Completion:
build/check, activation, terminal WebSocket/shell and routing verification.
Build/check and isolated authenticated WebSocket/shell/routing checks passed.
The SYS-064 switch activated ttyd in generation 262; current inspection verified
live/selected profile match, caddy/ttyd active, protected HTTPS returns 401 and
live hub config contains the exact terminal card URL. The old generation-261
activation helper is superseded and must not be replayed.
Real password setup/login remains the linked [SYS-058](#sys-058) acceptance.
**Evidence:** [prepared terminal deployment](SYSTEM_CHANGELOG.md#prepared-browser-terminal-and-hub-card--2026-11-05).

<a id="sys-062"></a>

### SYS-062 — Repair hub display power commands for Umbriel

**Status:** DONE · **Closed:** 2026-11-04

Corrected Umbriel DPMS command arguments and regression coverage. All 35 API
tests and dashboard/system build checks passed. Retry inspection verified the
fix is persistently activated in generation 258 (live/selected paths match),
Caddy display-on API returns 200, and no system/user units failed.
Physical off/wake remains the separate SYS-002 acceptance check.
**Evidence:** [implementation record](SYSTEM_CHANGELOG.md#completed-hub-display-power-command-fix--2026-11-04).

<a id="sys-061"></a>

### SYS-061 — Install AWS CLI v2 and AWS SAM CLI

**Status:** DONE · **Closed:** 2026-11-03

Tested and persistently activated through pkexec as generation 242; a fresh
shell reports aws-cli 2.34.24 and SAM CLI 1.160.0, no failed system units.
AWS credentials and profiles are out of scope (configured by the user).
**Evidence:** [completed installation](SYSTEM_CHANGELOG.md#completed-aws-cli-v2-and-aws-sam-cli--2026-11-03).

<a id="sys-060"></a>

### SYS-060 — Install Claude Desktop

**Status:** DONE · **Closed:** 2026-11-03

Tested and persistently activated through pkexec as generation 240. Home Manager,
installed command, desktop entry and visible native Wayland window verified;
no failed system units. Sign-in and application features remain untested.
**Evidence:** [completed installation](SYSTEM_CHANGELOG.md#completed-claude-desktop-installation--2026-11-03).

<a id="sys-059"></a>

### SYS-059 — Show NanoKVM outlet readings in the hub

**Status:** DONE · **Closed:** 2026-11-02

Generation 237 persistently activated after test activation. Live browser shows
watts/day/month energy through NanoKVM; 390 px layout has no overflow. A simulated
endpoint failure clears readings and recovery fetch restores them. Owner-only
access, CORS, no-store, units, cache and failure behavior verified; all checks pass.
**Evidence:** [Hub integration](SYSTEM_CHANGELOG.md#completed-nanokvm-outlet-hub-integration--2026-11-02).

<a id="sys-058"></a>

### SYS-058 — Password-protect browser desktop

**Status:** OPEN · **Review:** 2026-11-02

Generation 236 denies desktop access pending local password setup (503).
Corrected helper built after reproducing/fixing missing stdin newline; latest
activation awaits user sudo authentication. Finish prepared activation, run
sudo desktop-password locally, then verify real login and update records.
No passwords in chat/Nix; tailnet/origin restrictions retained.
**Evidence:** [prepared password gate](SYSTEM_CHANGELOG.md#prepared-desktop-password-protection--2026-11-02).

<a id="sys-057"></a>

### SYS-057 — Add browser desktop to service index

**Status:** DONE · **Closed:** 2026-11-02

Desktop card and exact target verified in browser; persisted as generation 235.
Password protection was discussed but not enabled.
**Evidence:** [index record](SYSTEM_CHANGELOG.md#completed-desktop-service-index-entry--2026-11-02).

<a id="sys-056"></a>

### SYS-056 — Match desktop access to the service subdomain convention

**Status:** DONE · **Closed:** 2026-11-02

Generation 234 persisted. New subdomain automatically connects to live desktop;
old path redirects. LAN/foreign Origin rejected; no failed system/user units.
**Evidence:** [subdomain record](SYSTEM_CHANGELOG.md#completed-desktop-browser-subdomain--2026-11-02).

<a id="sys-055"></a>

### SYS-055 — Browser control of the current Noctalia desktop

**Status:** DONE · **Closed:** 2026-11-02

Generation 233 activated; live browser framebuffer and remote keyboard input
verified. Tailnet HTTP 200, LAN/foreign Origin 403, localhost-only backend,
and no failed system/user units. No audio streaming; graphical session required.
**Evidence:** [browser desktop](SYSTEM_CHANGELOG.md#completed-browser-control-of-the-current-noctalia-desktop--2026-11-02).

<a id="sys-054"></a>

### SYS-054 — Install Proton VPN desktop

**Status:** DONE · **Closed:** 2026-11-02

Activated as generation 232; visible graphical window, version and system
health verified. Login and VPN connection remain untested.
**Evidence:** [installation record](SYSTEM_CHANGELOG.md#completed-proton-vpn-desktop-installation--2026-11-02).

<a id="sys-053"></a>

### SYS-053 — Install headless Moonshine; retain disabled Sunshine

**Status:** DONE · **Closed:** 2026-10-31

Generation 231 installs latest upstream 79554f8 (0.16.1), runs Moonshine as a
headless-capable system service, and retains disabled/masked Sunshine.
Flake/dry/full builds, test/switch activation, full GPU/input/ports healthcheck
and pairing-page HTTP 200 passed. Actual client pairing/streaming and logged-out
operation were not tested. No reboot performed.

**Evidence:** [implementation record](changelog/2026-10.md#completed-headless-moonshine-installation--2026-10-31).

<a id="sys-052"></a>

### SYS-052 — qBittorrent external disk write access

**Status:** DONE · **Closed:** 2026-10-30

Generation 230 persistently enables write access to all four disks. Actual
create/read/delete tests passed inside qBittorrent as UID 1000; services,
mount UUIDs, EFI entries and GRUB recovery verified. No reboot performed.
See the [implementation record](changelog/2026-10.md#completed-qbittorrent-external-disk-write-access--2026-10-30).

<a id="sys-051"></a>

### SYS-051 — Update system packages

**Status:** OPEN · **Review:** 2026-11-02

Full configuration build and flake checks passed, including the narrow
fpdf2 fixture-test override. Subsequently activated as generation 233 during
SYS-055; system/user failed-unit checks passed. Broader service/boot-entry
acceptance and push remain. No reboot performed. Recovery snapshot:
`/btrfs-top/nixos-root-pre-full-config-20261102`.

**Done when:** Authenticated test/switch activation passes, affected services,
desktop and boot entries verified, results committed and pushed.
**Evidence:** [build and activation attempt](SYSTEM_CHANGELOG.md#prepared-full-configuration-activation--2026-11-02).

<a id="sys-050"></a>

### SYS-050 — Expose local AI chat through Caddy

**Status:** DONE · **Closed:** 2026-10-27

Generation 229 exposes Open WebUI through existing wildcard HTTPS routes.
Builds and test/persistent activation passed. Main URL serves the UI and
health, browser sign-in renders and WebSocket upgrade returns HTTP 101.
Services are healthy. The optional Moria alias route works with local resolve;
its existing DNS points to a different host, so use the Erebor address.

**Evidence:** [implementation record](changelog/2026-10.md#completed-ai-chat-through-caddy--2026-10-27).

<a id="sys-049"></a>

### SYS-049 — Local GPU chat with reduced refusals and web search

**Status:** DONE · **Closed:** 2026-10-27

Generation 228 persistently activates Ollama/CUDA, Huihui Qwen3.5 27B
abliterated, Open WebUI and SearXNG. Flake/dry/full builds passed; 32768 context
runs 100% on GPU (~17.8 GiB total VRAM use, ~50 tokens/s). A 28932-token prompt
correctly recalled an initial marker. Search returned 10 live results, the UI
welcome page and health passed, and no units failed. User creates their own
UI account for first use; authenticated UI chat/search and UVM loading after
a future reboot were not acceptance-tested.

**Evidence:** [implementation record](changelog/2026-10.md#completed-local-gpu-chat-and-web-search--2026-10-27).

<a id="sys-045"></a>

### SYS-045 — Move RTX 4090 host graphics to NVK/Nouveau

**Status:** DONE · **Closed:** 2026-10-26

Update the `nixos-26.05` pin and replace the proprietary NVIDIA driver with
Nouveau/NVK for the Ada RTX 4090. The latest available `nixos-26.05` pin
(`1f607aa`, 2026-10-25) still selected Linux 6.18.57. Generation 225 was built,
test-activated, switched, and booted. The RTX 4090 uses Nouveau, and Vulkan
reports `NVK AD102` (Mesa 26.1.8, Vulkan 1.4.354); graphical-session, Sunshine,
and xremap targets are active with no failed units. GRUB retains generation 224
for rollback; Fedora, Windows, UUIDs, partitions and EFI entries were unchanged.
Sunshine now uses CPU encoding because NVENC/CUDA is unavailable with NVK.

<a id="sys-046"></a>

### SYS-046 — Verify workloads formerly relying on NVIDIA CUDA/NVENC

**Status:** OPEN · **Review:** 2026-10-26

Completion: exercise an actual Sunshine stream and any user-configured Jellyfin
or other CUDA/NVENC workload under NVK, then record performance and a preferred
open-driver-compatible encoder path. The host driver/Vulkan and service startup
are verified by SYS-045; this task does not authorize reverting the driver.

<a id="sys-047"></a>

### SYS-047 — Test Linux 7.3 for the RTX 4090's DP-1 165 Hz mode

**Status:** DONE · **Closed:** 2026-10-26

Build and boot a reversible Linux 7.3 generation with the existing
Nouveau/NVK userspace, then verify whether the Dell AW3423DWF exposes and uses
3440×1440 at 164.9 Hz. Current evidence: generation 225 is healthy on Linux
6.18.57 but DP-1 only exposes 59.973 and 99.982 Hz, currently 99.982 Hz.
Flake/dry/full builds and test activation passed; generation 226 was switched
with Linux 7.3 and its GRUB entry verified. Generation 226 booted successfully:
Nouveau, the graphical session, Sunshine and xremap are healthy, but the DP-1
mode list remains 59.973/99.982 Hz and 99.982 Hz remains active. The newer
kernel does not enable 165 Hz; generation 225 remains in GRUB for rollback.

<a id="sys-048"></a>

### SYS-048 — Restore proprietary NVIDIA graphics for the 165 Hz display mode

**Status:** DONE · **Closed:** 2026-10-26

Restore the previously verified NVIDIA 615.78.08 stack, NVENC Sunshine support,
and the stable 6.18.57 kernel after Linux 7.3/Nouveau did not expose DP-1's
165 Hz mode. Flake/dry/full builds and test activation passed; generation 227
booted successfully with NVIDIA 615.78.08. DP-1 is 3440×1440 at 164.9 Hz;
Vulkan uses NVIDIA, and graphical-session, Sunshine and xremap are active with
no failed units. Generation 226 remains available in GRUB for rollback.

## Open checks

<a id="sys-044"></a>

### SYS-044 — Speed up confirmed NixOS dashboard availability

**Status:** DONE · **Closed:** 2026-10-25

Direct uncached host OS confirmation runs alongside NanoKVM. Live NixOS header,
controls and services available in 194–226ms versus 6562ms before, on the tested
connection. Generation 224 activated; 30 API tests, flake/dry/full builds,
latency/fallback/cancellation/gating browser checks and live HTTPS/PWA passed.
**Evidence:** [Fast NixOS confirmation](changelog/2026-10.md#completed-confirm-nixos-without-waiting-for-nanokvm-power-sampling--2026-10-25).

<a id="sys-043"></a>

### SYS-043 — Verify dashboard OS detection during a native Windows boot

**Status:** OPEN · **Review:** 2026-10-25

Completion: during a normal user-requested Windows boot, open the previously
cached PWA and verify `Awake · Windows`, disabled NixOS actions/service links, and return
to `Awake · NixOS` after a normal NixOS boot. Do not reboot solely for this check.
Native Windows Tailscale identity confirmed by user; detection/gating and cached
shell behavior are covered by mocked tests. Live Windows boot remains untested.
**Evidence:** [SYS-042 deployment](changelog/2026-10.md#completed-detect-running-os-and-gate-unsupported-dashboard-actions--2026-10-25).

<a id="sys-042"></a>

### SYS-042 — Detect the running OS in the dashboard

**Status:** DONE · **Closed:** 2026-10-25

Pinned native OS identities probed independently through NanoKVM; header reports
NixOS/Windows/unknown. Host actions and service navigation require confirmed awake
NixOS, including confirmation/send and keyboard guards; Wake uses power state.
Generation 223 deployed with flake/dry/full builds, 18 unit tests, mocked browser
state/gating/cache checks and live NixOS HTTPS/offline verification.
Real Windows acceptance is SYS-043.
**Evidence:** [OS detection and action gating](changelog/2026-10.md#completed-detect-running-os-and-gate-unsupported-dashboard-actions--2026-10-25),
[service navigation gating](changelog/2026-10.md#completed-gate-service-navigation-by-detected-os--2026-10-25).

<a id="sys-041"></a>

### SYS-041 — Show host power LED beside the dashboard title

**Status:** DONE · **Closed:** 2026-10-25

Colored LED and readable status moved beside host name; duplicate System card
removed. Wake up enables only for confirmed asleep/off. Flake/dry/full builds,
responsive/status/offline browser checks and live HTTPS validation before and
after generation 221 activation passed. No real ATX/sleep commands issued.
**Evidence:** [Header LED and wake gating](changelog/2026-10.md#completed-show-header-power-led-and-gate-wake-by-detected-state--2026-10-25).

<a id="sys-039"></a>

### SYS-039 — Wake the dashboard host through NanoKVM ATX

**Status:** DONE · **Closed:** 2026-10-25

Direct HTTPS Wake up and independently polled power LED status deployed as
generation 220, with NanoKVM loopback helper behind owner-restricted Tailscale
Serve. Wake up is disabled while awake. Flake/dry/full builds, eleven GPIO/HTTP
tests, mocked browser checks and live HTTPS/offline checks passed before and
after switch. Real sleep/off wake acceptance is tracked separately as SYS-040.
**Evidence:** [NanoKVM wake and power status](changelog/2026-10.md#completed-add-nanokvm-atx-wake-and-power-status--2026-10-25).

<a id="sys-040"></a>

### SYS-040 — Verify NanoKVM ATX wake from real sleep

**Status:** OPEN · **Review:** 2026-10-25

Completion: with user ready for a brief interruption, suspend the host and use
the cached PWA Wake up button over Tailscale; verify the sleep LED is blinking
or off, exactly one short ATX press, and dashboard/control service recovery.
Also verify host-off start when convenient, without changing boot selection.
User confirmed ATX wiring and independent NanoKVM power. GPIO/power-on safety
is covered by SYS-039 software tests; real sleep/off wake remains untested.
**Evidence:** [Deployment and verification](changelog/2026-10.md#completed-add-nanokvm-atx-wake-and-power-status--2026-10-25).


<a id="sys-038"></a>

### SYS-038 — Integrate display and Ambilight status with their controls

**Status:** DONE · **Closed:** 2026-10-25

Grouped live status and on/off actions in device cards, with reported-state
highlighting and configured-action filtering. Deployed as generation 219.
Flake checks, dry/full builds, mocked browser interaction and live HTTPS/PWA
verification passed. No real device control commands issued for verification.
**Evidence:** [Integrated device controls](changelog/2026-10.md#completed-integrate-device-status-and-actions--2026-10-25).

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
**Evidence:** [Dashboard extraction](changelog/2026-10.md#completed-extract-dashboard-into-private-submodule-and-nix-packages--2026-10-25).

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
**Evidence:** [Live device status](changelog/2026-10.md#completed-show-live-display-and-ambilight-status--2026-10-25).

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
**Evidence:** [FastAPI migration](changelog/2026-10.md#completed-migrate-dashboard-control-api-to-fastapi--2026-10-25).

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
**Evidence:** [Windows reboot control](changelog/2026-10.md#completed-add-windows-reboot-dashboard-button--2026-10-25).

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
**Evidence:** [Angular migration](changelog/2026-10.md#completed-migrate-service-dashboard-to-angular--2026-10-24).

<a id="sys-032"></a>

### SYS-032 — Add HyperHDR to dashboard index

**Status:** DONE · **Closed:** 2026-10-24

Added and deployed HyperHDR service card in generation 213. Flake/full build,
test activation and switch passed. Browser verified card/link and click through
to HyperHDR Web Configuration, including dashboard reload after switch.
Caddy healthy, no failed units; root/ESP UUIDs unchanged. No reboot.
**Evidence:** [Dashboard card](changelog/2026-10.md#completed-add-hyperhdr-dashboard-card--2026-10-24).

<a id="sys-031"></a>

### SYS-031 — Expose HyperHDR through Caddy

**Status:** DONE · **Closed:** 2026-10-24

Activated and persisted as generation 212. Flake/dry/full builds and Caddy
adapt passed. Both HTTPS routes return UI 200 and WebSocket 101 with verified
certificates through local Caddy; local aliases and erebor tailnet URL return
200. Live/selected targets match; Caddy/HyperHDR active; no failed system/user
units. Root/ESP UUIDs unchanged; no reboot performed.
**Evidence:** [HyperHDR proxy](changelog/2026-10.md#completed-add-hyperhdr-to-caddy--2026-10-24).

<a id="sys-030"></a>

### SYS-030 — Make the service dashboard installable as a PWA

**Status:** DONE · **Closed:** 2026-10-24

Material UI 9.5.0 dashboard with top quick actions and installable PWA is
activated and persisted as generation 211. Flake/dry/full builds, mocked control
and offline checks passed. Live HTTPS HTML/worker match built assets; browser
verified responsive Material UI, manifest/icons, service links and controlling
worker with cached bundle. Caddy healthy; no failed system/user units. Physical
device installation is user-driven and was not performed. No reboot required.
**Evidence:** [PWA and Material UI deployment](changelog/2026-10.md#completed-enable-service-dashboard-pwa-and-material-ui--2026-10-24).

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
**Evidence:** [GRUB installation](changelog/2026-10.md#completed-install-grub-with-current-wallpaper-menu-for-next-boot--2026-10-23).

<a id="sys-028"></a>

### SYS-028 — Resolve duplicate Noctalia startup

**Status:** OPEN · **Reviewed:** 2026-10-23

Generation 208 post-boot check: user `noctalia.service` failed with
start-limit-hit; journal repeatedly says `noctalia is already running`.
A separate `/run/current-system/sw/bin/noctalia` process is running (PID 3970
at inspection). No shell processes restarted during Plymouth verification.
**Done when:** establish the intended single startup owner, remove competing
launch declaratively and verify shell functionality and service health.
**Evidence:** [generation 208 post-boot check](changelog/2026-10.md#completed-install-bgrt-logo-and-faster-greeter-startup-for-next-boot--2026-10-23).

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
**Evidence:** [diagnostic cleanup](changelog/2026-10.md#completed-remove-temporary-plymouth-diagnostics-for-next-boot--2026-10-23),
[BGRT/greeter installation and boot verification](changelog/2026-10.md#completed-install-bgrt-logo-and-faster-greeter-startup-for-next-boot--2026-10-23),
[SimpleDRM diagnostics](changelog/2026-10.md#completed-install-plymouth-simpledrm-diagnostics-for-next-boot--2026-10-23).

<a id="sys-026"></a>

### SYS-026 — Make YubiKey touch prompts noticeable

**Status:** DONE · **Closed:** 2026-10-23

Activated persistent generation 203; user notifier enabled/running. Simulated
and real sudo touch requests show and dismiss the notification; user confirmed
notification and sound. Authentication rules unchanged; no failed units.

**Evidence:** [completed notifier](changelog/2026-10.md#completed-add-yubikey-touch-notification-and-sound--2026-10-23).

<a id="sys-025"></a>

### SYS-025 — Retire broken Fedora installation

**Status:** DONE · **Closed:** 2026-10-23

Removed Fedora-only boot files/firmware entries, root snapshot and unused
containers; verified protected EFI hashes, shared data mounts and services.
Btrfs completed reclamation; approximately 63.5 GiB free. Boot archives and
NixOS recovery snapshot retained; partitions unchanged. No reboot performed.

**Evidence:** [retirement record](changelog/2026-10.md#completed-retire-broken-fedora-installation--2026-10-23).

<a id="sys-024"></a>

### SYS-024 — Activate KDE Connect LAN firewall rules

**Status:** DONE · **Closed:** 2026-10-23

Activated persistent generation 199. Verified deployed firewall service and live
IPv4/IPv6 TCP/UDP 1714–1764 rules on br0, boot entry/default and system profile,
no failed units, and phone paired/reachable; user confirmed access. Configuration
commit d9edff3. Fedora menu entry removed by isolated activation was restored and
verified. Fedora was later intentionally retired under SYS-025.

**Evidence:** [completed change](changelog/2026-10.md#completed-persist-kde-connect-lan-firewall-rules--2026-10-23).

<a id="sys-001"></a>

### SYS-001 — Verify Fedora chainloading

**Status:** CANCELLED · **Closed:** 2026-10-23

User reported two failed Fedora boots. Read-only inspection found root/home
subvolumes missing; historical Btrfs output confirms they existed on Oct 18
at 02:13 Warsaw time and a complete directory listing shows them absent on
Oct 22 at 17:33. Exact deletion time/cause remains unknown. User chose to
retire Fedora, including the remaining root snapshot, under SYS-025.

**Evidence:** [retirement record](changelog/2026-10.md#completed-retire-broken-fedora-installation--2026-10-23);
[historical record](changelog/2026-10.md#record-sys-001-1).

<a id="sys-002"></a>

### SYS-002 — Verify physical display wake

**Status:** OPEN · **Reviewed:** 2026-10-23

Observed 2026-10-23: generation 198 boots Linux 6.18.57 / NVIDIA 615.78.08 without NVML mismatch or recorded modeset failures.

**Done when:** With remote recovery available and work saved, exercise dashboard display off/on and confirm a usable picture on the physical AW3423DWF. Record physical confirmation and kernel-log results.

**Evidence:** [historical record](changelog/2026-10.md#record-sys-002-1). See also the [related record](changelog/2026-10.md#record-sys-002-2).

<a id="sys-003"></a>

### SYS-003 — Verify T3 browser preview

**Status:** OPEN · **Reviewed:** 2026-10-23

Observed 2026-10-23: T3 is active with the declared library path; preview was not exercised.

**Done when:** Open a browser preview through T3 and confirm it renders successfully. Record the result; deployed libraries alone do not verify preview.

**Evidence:** [historical record](changelog/2026-10.md#record-sys-003-1).

<a id="sys-004"></a>

### SYS-004 — Verify dashboard sleep and shutdown

**Status:** OPEN · **Reviewed:** 2026-10-23

Observed 2026-10-23: deployment, seven tests, HTTPS ambilight actions and cross-origin rejection pass. Display wake is SYS-002.

**Done when:** When the user is ready for interruption, confirm dashboard sleep/resume and shutdown followed by successful startup. Record each separately; leave untested actions open.

**Evidence:** [historical record](changelog/2026-10.md#record-sys-004-1).

## Historical work to reconcile

These items are not newly verified failures. Review may close them without any
system change. The archive contains later records that may supersede them.

<a id="sys-005"></a>

### SYS-005 — Review HyperHDR capture target

**Status:** OPEN · **Reviewed:** 2026-11-04

Observed 2026-10-23: saved portal selection is physical DP-1. Earlier work requested wallpaper-only ambilight; latest troubleshooting concerned reaction to display content.

Decided 2026-11-04 (user): display content. The wallpaper-only `ambilight` output was removed; after restart HyperHDR streamed 21:9 frames, which only DP-1 provides. Remaining: confirm the LEDs follow on-screen content.

**Done when:** Confirm the desired capture behavior before changing it. Verify either display-content response or wallpaper-only isolation, record the chosen behavior, and close or cancel the old request accordingly.

**Evidence:** [historical record](changelog/2026-10.md#record-sys-005-1).

<a id="sys-006"></a>

### SYS-006 — Reconcile historical Intel passthrough checkpoint

**Status:** REVIEW · **Reviewed:** 2026-10-23

Historical checkpoint describes Intel guest acceleration. Later GPU assignments changed; it is not a current activation instruction.

**Done when:** Compare current host/domain configuration with subsequent GPU changes. Close as superseded if replaced, otherwise identify and verify the specific missing acceptance check. Do not reapply old VFIO instructions.

**Evidence:** [historical record](changelog/2026-10.md#record-sys-006-1).

<a id="sys-007"></a>

### SYS-007 — Reconcile original Windows VM setup checkpoint

**Status:** REVIEW · **Reviewed:** 2026-10-23

Guest installation and later acceleration work are recorded elsewhere in the changelog.

**Done when:** Reconcile later VM setup/GPU records with the original acceptance criteria; close resolved or superseded work and retain only a specific remaining check.

**Evidence:** [historical record](changelog/2026-10.md#record-sys-007-1).

<a id="sys-008"></a>

### SYS-008 — Review failed historical Btrfs compaction

**Status:** OPEN · **Reviewed:** 2026-11-04

The recorded bounded balance attempts failed with ENOSPC; this does not show that compaction is needed now.

2026-11-04: Nix store writes failed with ENOSPC at 93 GiB free because metadata
(DUP) was full (7.49/8.00 GiB) with no unallocated space. A user-run data balance
cut data allocation from 374.58 to 331.58 GiB; metadata then grew to 8.50 GiB
(7.50 used) and builds succeeded. Data chunks remain over-allocated relative to use.

**Done when:** Inspect current space and subsequent remediation records. Close the failed attempt with its outcome if no work remains; otherwise propose a current, bounded remediation. Do not retry balance from the old checkpoint.

**Evidence:** [historical record](changelog/2026-10.md#record-sys-008-1).

<a id="sys-009"></a>

### SYS-009 — Reconcile eza activation

**Status:** REVIEW · **Reviewed:** 2026-10-23

Historical build attempts failed with ENOSPC; later package/alias changes may supersede them.

**Done when:** Check current declarative/deployed eza and aliases and later records. Close if present and verified, or state the precise missing work before implementing anything.

**Evidence:** [historical record](changelog/2026-10.md#record-sys-009-1).

<a id="sys-011"></a>

### SYS-011 — Verify Niri startup placement

**Status:** REVIEW · **Reviewed:** 2026-10-23

Historical config validation/activation passed; fresh-session behavior was not confirmed.

**Done when:** At a planned Niri login, check the initial workspace and ordinary app placement against current configuration, or close as superseded if that behavior was removed.

**Evidence:** [historical record](changelog/2026-10.md#record-sys-011-1).

<a id="sys-012"></a>

### SYS-012 — Review Discord shortcut and tab indicator checks

**Status:** REVIEW · **Reviewed:** 2026-10-23

Historical direct Discord launch passed; physical key delivery and indicator appearance were unverified.

**Done when:** Inspect current bindings, then confirm Right Ctrl+D opens Discord and the intended tab indicator is visible in the applicable session; close superseded parts explicitly.

**Evidence:** [historical record](changelog/2026-10.md#record-sys-012-1).

<a id="sys-013"></a>

### SYS-013 — Reconcile session chooser verification

**Status:** REVIEW · **Reviewed:** 2026-10-23

Umbriel is now running, but the old entry required chooser verification for both sessions.

**Done when:** Inspect current session definitions and later login evidence; confirm Niri and Umbriel are available at a planned login or close as superseded by the current chooser design.

**Evidence:** [historical record](changelog/2026-10.md#record-sys-013-1).

<a id="sys-014"></a>

### SYS-014 — Review Tailscale backup workflow status

**Status:** REVIEW · **Reviewed:** 2026-10-23

Only an old requested-work record exists here; completion is not established.

**Done when:** Inspect tracked workflow and validation evidence, then close if verified or define remaining work. Preserve the original secret-handling constraints; do not create archives or expose keys during review.

**Evidence:** [historical record](changelog/2026-10.md#record-sys-014-1).

<a id="sys-015"></a>

### SYS-015 — Reconcile xremap device and mapping checks

**Status:** REVIEW · **Reviewed:** 2026-10-23

Historical notes report missing device access/devices; later records show successful xremap use.

**Done when:** Inspect current service/device access and later shortcut results, then verify the current mappings or close superseded device-reconnect instructions. Do not reboot merely to satisfy the old checkpoint.

**Evidence:** [historical record](changelog/2026-10.md#record-sys-015-1). See also the [related record](changelog/2026-10.md#record-sys-015-2).

<a id="sys-016"></a>

### SYS-016 — Review lingering and Oo7 login verification

**Status:** REVIEW · **Reviewed:** 2026-10-23

Historical activation checks passed; deliberate logout/login and keyring unlock were still unconfirmed.

**Done when:** Compare current PAM/linger configuration and later login evidence; verify the intended login/keyring behavior during a planned session transition or close superseded requirements. Do not read keyring secrets.

**Evidence:** [historical record](changelog/2026-10.md#record-sys-016-1).

<a id="sys-017"></a>

### SYS-017 — Reconcile bridge persistence and client playback

**Status:** REVIEW · **Reviewed:** 2026-10-23

Historical host/guest LAN probes passed. A later UEFI checkpoint states bridge persistence was resolved.

**Done when:** Close the old activation step using later evidence; verify whether playback from a separate physical LAN client remains relevant and untested, and record that result separately.

**Evidence:** [historical record](changelog/2026-10.md#record-sys-017-1).

<a id="sys-018"></a>

### SYS-018 — Close historical firmware-reboot checkpoint

**Status:** REVIEW · **Reviewed:** 2026-10-23

The record contains a 2026-10-20 pre-reboot checkpoint; current NixOS has since booted generation 198.

**Done when:** Check available evidence or user confirmation of the firmware visit and close the historical operation as completed or outcome unknown. Do not schedule another firmware reboot or rely on pruned generation 172.

**Evidence:** [historical record](changelog/2026-10.md#record-sys-018-1).

<a id="sys-019"></a>

### SYS-019 — Reconcile lsof activation

**Status:** REVIEW · **Reviewed:** 2026-10-23

Historical build passed; installed-command verification was pending.

**Done when:** Check the current declared package and installed lsof command, and close with observed evidence or a specific remaining task.

**Evidence:** [historical record](changelog/2026-10.md#record-sys-019-1).

<a id="sys-020"></a>

### SYS-020 — Reconcile Zen Browser deployment

**Status:** REVIEW · **Reviewed:** 2026-10-23

Historical user-profile installation existed; declarative deployment and duplicate cleanup were pending.

**Done when:** Verify the current declarative/deployed browser and profile ownership. Close deployment with evidence; identify any redundant user-profile entry before considering removal.

**Evidence:** [historical record](changelog/2026-10.md#record-sys-020-1).

<a id="sys-021"></a>

### SYS-021 — Reconcile Mango login and persistence

**Status:** REVIEW · **Reviewed:** 2026-10-23

Later completed Mango records show activation and live use, so the old test-generation instructions may be stale.

**Done when:** Reconcile later persistent activation and hardware-login evidence. Close resolved steps and retain only any specific missing chooser or input check; do not restart greetd as a review step.

**Evidence:** [historical record](changelog/2026-10.md#record-sys-021-1).

<a id="sys-022"></a>

### SYS-022 — Finish Crucial Windows VM relocation

**Status:** DONE · **Closed:** 2026-10-23

Verified identical offline image contents and healthy qcow2 metadata, switched
only vda to Crucial UUID 604F-A363, verified Windows desktop/guest agent/network
and no disk errors, shut down cleanly and removed live local original.
VM remains off. Recovery XML/NVRAM/TPM and read-only root snapshot ID 657
retained. Other snapshots still hold 110.37 GiB of shared original disk blocks;
removing those is outside this relocation. Main filesystem has about 63 GiB free.

**Evidence:** [completed relocation](changelog/2026-10.md#completed-finish-windows-vm-relocation-to-crucial--2026-10-23);
[historical record](changelog/2026-10.md#record-sys-022-1).

<a id="sys-023"></a>

### SYS-023 — Review Mango Moonlight acceptance check

**Status:** REVIEW · **Reviewed:** 2026-10-23

Isolated compositor/NVENC tests passed; end-to-end Moonlight and persistent deployment were unverified in the old record.

**Done when:** Inspect current deployed unit and any obsolete runtime drop-in; reconcile later activation evidence and verify Moonlight in a planned Mango session. Do not end the current session during review.

**Evidence:** [historical record](changelog/2026-10.md#record-sys-023-1).

<a id="sys-089"></a>

### SYS-089 — Niri overview swaybg runs under Umbriel

**Status:** OPEN · **Reviewed:** 2026-11-04

`niri-overview-wallpaper` (swaybg, DP-1, background layer) starts with every
graphical session, including Umbriel, where it serves no purpose. It sits below
the Wallpaper Engine scene only because it maps first; a restart of swaybg could
cover the animated wallpaper.

**Done when:** The service runs only in Niri sessions (or is removed), and under
Umbriel `umbriel layers` shows no `wallpaper` swaybg surface while the Wallpaper
Engine scene stays visible after a re-login.

**Evidence:** [wallpaper plugin record](SYSTEM_CHANGELOG.md#completed-wallpaper-engine-animated-wallpaper-plugin--2026-11-04).

## Closed tasks

<a id="sys-010"></a>

### SYS-010 — Umbriel background workspace startup check

**Status:** CANCELLED · **Closed:** 2026-10-23

Superseded by the completed 2026-10-20 replacement of background-apps with native scratchpad.

**Closure:** No action. The former startup-helper verification no longer applies; do not restore the removed helper.

**Evidence:** [historical record](changelog/2026-10.md#record-sys-010-1).

## Adding or closing a task

Use the next unused SYS number (currently SYS-029). Record status, review date,
what remains, a concrete completion condition, and a link to evidence. For active
work, record the next safe step and any applicable recovery checkpoint. Required
acceptance checks block completion of that task; optional follow-ups get their
own ID. On closure, add the date and observed result, user confirmation, or
superseding change. Never infer successful activation from a build alone.
