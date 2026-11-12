# Phone approval for sudo

`my.phoneApproval` (module `modules/phone-approval.nix`) lets the phone
approve sudo. A passkey on the phone, unlocked with its fingerprint, signs a
one-time challenge, and erebor checks the signature. The YubiKey and the Unix
password keep working after it.

## How a request flows

1. sudo's PAM stack runs `record-auth-reason`, then the Mac step, then the
   phone step (`phone-approval-pam`, order 10800), then pam_u2f and pam_unix.
2. The phone step checks that the phone (`my.phoneApproval.device`) is
   reachable in the user's KDE Connect. If it isn't, it fails at once and sudo
   moves on to the next step.
3. It asks `phone-approval.service` for a request over the root-only socket
   `/run/phone-approval/pam.sock`, and sends the returned link,
   `https://approve.<domain>/r/<id>`, with `kdeconnect-cli --share`. Android
   shows it as a notification.
4. The page shows the reason (the sudo command line). **Approve with
   fingerprint** makes a WebAuthn assertion with user verification required.
   **Deny** ends the step at once.
5. The service checks the assertion against the stored public key and
   answers the waiting PAM step. With no answer within `my.phoneApproval.timeout`
   (30 s by default), sudo moves on.

A link is useless without the passkey. The page is served only to the tailnet
and LAN (Caddy `remote_ip`), and each request answers once and expires.
Passkeys are stored in `/var/lib/private/phone-approval/credentials.json`
(public keys only). That file is outside Git and the Nix store.

Only sudo uses this step. Polkit, login and the lock screen are unchanged.

## KDE Connect over Tailscale

KDE Connect finds devices with LAN broadcasts, which don't cross Tailscale.
For the phone to reach erebor away from home, add erebor by IP once in the
phone's KDE Connect app: ⋮ → *Add devices by IP* → erebor's tailnet address
(`tailscale ip -4`). Ports 1714–1764 are open on `tailscale0` for this. Set
KDE Connect's Android battery usage to *Unrestricted*, or Android drops the
connection and requests fall through to the next method.

## Enroll the phone

With the phone reachable (`kdeconnect-cli -a` lists it):

```sh
phone-approval-enroll        # re-runs itself with sudo; approve with the YubiKey
```

Open the link on the phone and choose **Create passkey**. The command prints
`Result: enrolled`. Run it again to add another passkey. To remove passkeys,
edit or delete `credentials.json` as root and restart `phone-approval`.

## Test

```sh
sudo -k id -u     # approve on the phone; prints 0
```

Also check the fallbacks: tap **Deny** (the YubiKey prompt follows at once),
and disconnect the phone (sudo goes straight to the YubiKey). The journal
shows each result: `journalctl -u phone-approval` and
`journalctl -t sudo -g phone-approval`.
