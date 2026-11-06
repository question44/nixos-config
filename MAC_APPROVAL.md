# Mac approval for sudo and Polkit

Secretive signs a fresh PAM challenge using the Mac's Secure Enclave key.
`pam_rssh` verifies the signature on Linux. Password authentication remains
available when the Mac is disconnected or an approval is rejected.

The public key is provisioned locally at
`/etc/security/mac-approval/janzon.keys` (root-owned, mode 0644). Its contents
are intentionally outside Git and the Nix store. Reprovision this file on a
new installation before enabling the module.

## Connect the Mac

In Secretive, create a dedicated secret with Protection Level set to
Require Authentication. Configure its signing agent through Secretive's
Integrations menu. Keep approval persistence disabled for this key if each
authentication should require interaction.

Run in the Mac's Terminal while on the same LAN as Linux:

```bash
SSH_AUTH_SOCK="$HOME/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh" \
  ssh -A -o ServerAliveInterval=30 -o ServerAliveCountMax=3 \
  janzon@192.168.1.106 \
  'test -S "$SSH_AUTH_SOCK" && ln -sfn "$SSH_AUTH_SOCK" /run/mac-approval/janzon/agent.sock && echo "Mac approval connected; leave this terminal open." && exec sleep infinity'
```

Leave this connection open. Re-run it after disconnecting, rebooting Linux,
or resuming the Mac if the connection was lost. The runtime directory is
created by NixOS tmpfiles. The fixed symlink lets the local desktop use the
forwarded agent without inheriting the SSH session's environment.

Agent forwarding is scoped to this connection. Only authorize prompts you
expect; a signing prompt does not necessarily identify the exact sudo command.
The configured public key is authorized for privilege approval, not SSH login.
The initial SSH connection uses the account's existing login method.

## Show why approval was requested

Before the Mac and YubiKey steps, sudo and Polkit record a one-line reason in
`/run/auth-reason/janzon` (readable only by janzon), for example
`sudo nixos-rebuild switch …`. The YubiKey notification on erebor shows it.
Polkit's reason is generic: PAM doesn't see the Polkit action, but the Polkit
dialog on erebor names it.

To see the reason on the Mac, replace `exec sleep infinity` in the tunnel's
remote command with `exec auth-reason-stream`, and pipe the connection's
output into macOS notifications:

```bash
ssh … 'test -S "$SSH_AUTH_SOCK" && ln -sfn "$SSH_AUTH_SOCK" /run/mac-approval/janzon/agent.sock && exec auth-reason-stream' |
  while IFS= read -r reason; do
    osascript -e 'on run argv' -e 'display notification (item 1 of argv) with title "erebor approval"' -e 'end run' "$reason"
  done
```

`auth-reason-stream` prints one line per new request and keeps the session
open, so it stands in for `sleep infinity`. The reason includes the sudo
command line, so it reaches the Mac through the existing SSH connection only.

## Validate

Signature-only test, without granting privileges or using a password:

```sh
pamtester mac-approval-check janzon authenticate
```

Actual privilege checks (these run only `id`):

```sh
sudo -k id -u
pkexec /run/current-system/sw/bin/id -u
```

Run the Polkit check from a desktop with its normal authentication agent.
Polkit 127's built-in terminal agent can fail with `No session for cookie`
after valid PAM authentication (upstream issue:
https://github.com/polkit-org/polkit/issues/686). For a headless check, register
a separate unprivileged `pkttyagent` for the invoking process and use
`pkexec --disable-internal-agent`. This path was verified successfully here.
The socket-activated Polkit PAM helper exposes only
`/home/janzon/.ssh/agent` through its otherwise hidden home directories, so
it can reach OpenSSH's forwarded socket.

Approve on the Mac; the privilege checks should print `0`. The normal sudo
and Polkit authorization caches still apply. Use `sudo -k` to force a fresh
sudo authentication. Existing Polkit rules for power and disk operations
continue to apply independently.

For fallback testing, close the Mac connection and run `sudo -k id -u` from
the Linux terminal. Enter the Linux account password locally. Reconnect the
Mac afterward. Rejection or missing-agent tests against mac-approval-check
must fail, because that diagnostic service deliberately has no password
fallback.

## Scope and recovery

Only sudo, polkit-1, and the diagnostic PAM service use this module. Login,
screen locking, and disk encryption use their existing authentication.
Do not replace Unix password fallback with a required phone/Mac factor.
For maintenance, keep a privileged recovery shell open through activation.
The preceding system generation remains available for rollback.
