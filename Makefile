SHELL := /run/current-system/sw/bin/bash
.ONESHELL:

TAILSCALE_STATE_ARCHIVE := secrets/tailscale-state.tar.gpg

.PHONY: help setup-codex repair-noctalia-lyrics keyring-change-password tailscale-state-backup tailscale-state-restore

help:
	@printf '%s\n' \
		'Available targets:' \
		'  help                     List available maintenance actions.' \
		'  setup-codex              Install Codex with npm if it is absent.' \
		'  repair-noctalia-lyrics   Restore the Lyrics plugin cache and reload Noctalia.' \
		'  keyring-change-password Change the Oo7 keyring password (run without sudo).' \
		'  tailscale-state-backup   Create an encrypted Tailscale state backup.' \
		'  tailscale-state-restore  Restore an encrypted Tailscale state backup.'

# Match the keyring password to the current login password after changing it.
keyring-change-password:
	@python3 scripts/oo7-change-password.py

# The community Lyrics plugin writes temporary requests beneath its materialized
# runtime directory. Plugin updates can remove that directory.
repair-noctalia-lyrics:
	@set -euo pipefail
	@plugin_dir="$(HOME)/.local/state/noctalia/plugins/materialized/community/lyrics"
	@[[ "$$(id -un)" == "janzon" ]] || { echo "Run this target as janzon, without sudo." >&2; exit 1; }
	@[[ -f "$$plugin_dir/plugin.toml" && -O "$$plugin_dir" ]] || { echo "Writable Lyrics plugin directory not found: $$plugin_dir" >&2; exit 1; }
	@install -d -m 0700 "$$plugin_dir/.cache/requests"
	@noctalia msg config-reload
	@echo "Lyrics plugin cache restored; Noctalia reloaded."

# Install Codex into ~/.local only when no Codex executable is already present.
setup-codex:
	@set -euo pipefail
	@if [[ -x "$(HOME)/.local/bin/codex" ]]; then \
		echo "Codex is already available at $(HOME)/.local/bin/codex."; \
		exit 0; \
	fi
	@NPM_CONFIG_PREFIX="$(HOME)/.local" npm install --global @openai/codex@latest
	@"$(HOME)/.local/bin/codex" --version

# Create the Git-trackable, password-encrypted Tailscale identity backup.
tailscale-state-backup:
	@set -euo pipefail
	@umask 077
	@mkdir -p "$$(dirname "$(TAILSCALE_STATE_ARCHIVE)")"
	@read -r -s -p "New backup password: " password; echo
	@read -r -s -p "Confirm backup password: " confirmation; echo
	@[[ "$$password" == "$$confirmation" ]] || { echo "Passwords do not match." >&2; exit 1; }
	@temporary="$$(mktemp "$(TAILSCALE_STATE_ARCHIVE).tmp.XXXXXX")"
	@trap 'rm -f "$$temporary"; sudo systemctl start tailscaled >/dev/null 2>&1 || true' EXIT
	@sudo systemctl stop tailscaled
	@exec 3<<<"$$password"
	@unset password confirmation
	@sudo tar --numeric-owner -C /var/lib -cpf - tailscale | \
		gpg --batch --yes --pinentry-mode loopback --passphrase-fd 3 \
			--symmetric --cipher-algo AES256 --output "$$temporary"
	@mv "$$temporary" "$(TAILSCALE_STATE_ARCHIVE)"
	@echo "Encrypted Tailscale state written to $(TAILSCALE_STATE_ARCHIVE)."

# Restore the saved identity. This overwrites the current Tailscale state.
tailscale-state-restore:
	@set -euo pipefail
	@test -f "$(TAILSCALE_STATE_ARCHIVE)" || { echo "Missing $(TAILSCALE_STATE_ARCHIVE)." >&2; exit 1; }
	@umask 077
	@temporary_directory="$$(mktemp -d)"
	@trap 'rm -rf "$$temporary_directory"; sudo systemctl start tailscaled >/dev/null 2>&1 || true' EXIT
	@read -r -s -p "Backup password: " password; echo
	@exec 3<<<"$$password"
	@unset password
	@gpg --batch --pinentry-mode loopback --passphrase-fd 3 --decrypt \
		--output "$$temporary_directory/tailscale.tar" "$(TAILSCALE_STATE_ARCHIVE)"
	@tar -tf "$$temporary_directory/tailscale.tar" | grep -Eq '^tailscale(/|$$)' || { echo "Archive is not a Tailscale backup." >&2; exit 1; }
	@read -r -p "Replace this machine's Tailscale state and restart tailscaled? [y/N] " answer
	@[[ "$$answer" == "y" || "$$answer" == "Y" ]] || { echo "Restore cancelled."; exit 1; }
	@sudo systemctl stop tailscaled
	@sudo install -d -o root -g root -m 0700 /var/lib/tailscale
	@sudo tar --numeric-owner -C /var/lib -xpf "$$temporary_directory/tailscale.tar"
	@sudo chown -R root:root /var/lib/tailscale
	@sudo chmod 0700 /var/lib/tailscale
	@sudo find /var/lib/tailscale -type f -exec chmod 0600 {} +
	@echo "Tailscale state restored."
