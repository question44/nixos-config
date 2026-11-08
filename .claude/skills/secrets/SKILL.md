---
name: secrets
description: Use when a service needs a password, token, API key or private key, when adding or rotating a secret in secrets/*.yaml, changing .sops.yaml recipients, adding a host, or moving an existing on-disk credential (e.g. /etc/caddy/ovh.env) into sops.
---

# Secrets with sops-nix

Secrets live in the repo only as sops-encrypted YAML. Plaintext never enters
git, the Nix store, the changelog or a chat transcript.

## How it fits together

- `.sops.yaml`: the recipients. `janzon` is the personal age key at
  `~/.config/sops/age/keys.txt` (back it up offline; losing it and the host
  key loses every secret). Each host is its SSH host key converted with
  `ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub`.
- `secrets/<hostname>.yaml`: that host's secrets. The `secrets` aspect
  (`modules/secrets.nix`) makes it the host's `sops.defaultSopsFile` and
  decrypts with the SSH host key at activation into `/run/secrets` (tmpfs).
- A module that needs a secret declares it next to the code that uses it:
  `sops.secrets.<name> = { owner = …; restartUnits = [ … ]; };` and passes
  `config.sops.secrets.<name>.path`, or renders a file with
  `sops.templates."<file>".content` using `config.sops.placeholder.<name>`
  (an env file, for example). Never interpolate a decrypted value into Nix.
- Tools: `nix shell nixpkgs#sops nixpkgs#age nixpkgs#ssh-to-age`.

## Adding or changing a secret

1. In your worktree: `sops secrets/erebor.yaml` opens the decrypted YAML in
   `$EDITOR` and re-encrypts on save. To add a value without an editor, write
   it to a file under a `mktemp -d` directory (umask 077) and use
   `sops set secrets/erebor.yaml '["name"]' "\"$(cat file)\""`, then delete
   the file.
2. Declare `sops.secrets.<name>` in the module that uses it.
3. Build, then check for leaks: the value must not appear in `git diff`, in
   the tree, or in the files of the built closure that changed
   (`erebor-diff` lists them).
4. Commit the encrypted file with the module change. Show values to nobody;
   check shape instead (`sops decrypt --extract '["name"]' … | wc -c`).

## Recipients

- New host: add its `ssh-to-age` key to `.sops.yaml`, create
  `secrets/<hostname>.yaml` with a creation rule, and run
  `sops updatekeys secrets/<file>.yaml` for files it must read.
- Rotating the personal key: add the new key, `sops updatekeys` every file,
  then remove the old key and `updatekeys` again.

## Moving an existing credential into sops (needs sudo)

Root-owned credentials can only be read with the user's touch approval, so
this is done with the user present. Caddy's OVH DNS credentials went this way
(SYS-074); the steps below use them as the example.

1. `sudo cat /etc/caddy/ovh.env` piped into a `mktemp -d` file (umask 077);
   never print it. The touch prompt can land in that file: take only the
   expected variables.
2. Add each variable to `secrets/erebor.yaml` (e.g. `ovh_endpoint`,
   `ovh_application_key`, `ovh_application_secret`, `ovh_consumer_key`).
3. In `modules/workstation/caddy.nix`: `sops.templates."caddy-ovh.env"` with
   `OVH_…=${config.sops.placeholder.…}` lines, `owner = "caddy"`,
   `restartUnits = [ "caddy.service" ]`, and set
   `services.caddy.environmentFile` to its `.path`.
4. Build, leak-check, land, activate; confirm Caddy reloads and a
   certificate renewal (or `caddy validate`) still authenticates with OVH.
5. Only after that works, delete `/etc/caddy/ovh.env` (with the user's
   approval) and shred the temporary file.
