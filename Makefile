SHELL := /run/current-system/sw/bin/bash
.ONESHELL:

.PHONY: help setup-codex repair-noctalia-lyrics keyring-change-password tailscale-state-backup tailscale-state-check tailscale-state-restore

help:
	@printf '%s\n' \
		'Available targets:' \
		'  help                     List available maintenance actions.' \
		'  setup-codex              Install Codex with npm if it is absent.' \
		'  repair-noctalia-lyrics   Restore the Lyrics plugin cache and reload Noctalia.' \
		'  keyring-change-password Change the Oo7 keyring password (run without sudo).' \
		'  tailscale-state-backup   Save the Tailscale node identity into sops (secrets/<host>.yaml).' \
		'  tailscale-state-check    Say whether that backup matches the live state.' \
		'  tailscale-state-restore  Restore the node identity from the sops backup.'

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

# The Tailscale node identity, sops-encrypted in secrets/<host>.yaml
# (scripts/erebor-tailscale-state; needs sudo and the personal age key).
tailscale-state-backup tailscale-state-check tailscale-state-restore:
	@nix shell nixpkgs#sops -c scripts/erebor-tailscale-state $(patsubst tailscale-state-%,%,$@)
