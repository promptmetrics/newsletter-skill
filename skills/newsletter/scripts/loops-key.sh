#!/usr/bin/env bash
# loops-key.sh — secure Loops API key storage for the newsletter skill.
#
# Stores the key in the OS credential store (macOS Keychain). The key is never
# written to a repo file, never passed as a CLI argument, never printed by this
# script except by `get` (which is meant to be piped into an env var for an API
# call, not displayed). The skill only ever calls `status` (boolean).
#
# macOS: Keychain via `security`. (Linux: secret-tool/pass. Windows: Credential
# Manager.) Only macOS is implemented; others exit non-zero with guidance.

set -euo pipefail
SERVICE="promptmetrics-lops-newsletter"
ACCOUNT="${USER:-$(id -un)}"

if [ "$(uname -s)" != "Darwin" ]; then
  echo "loops-key.sh: macOS Keychain only. On Linux use 'secret-tool'/'pass'; on Windows use Windows Credential Manager." >&2
  exit 3
fi

usage() { echo "usage: loops-key.sh {set|get|status}" >&2; }

cmd="${1:-}"
case "$cmd" in
  set)
    # Read the key silently from the TTY so it never enters shell history,
    # process args, or `ps`. Must be run in the user's own terminal.
    if [ ! -t 0 ]; then
      echo "loops-key.sh set: run in your own terminal (reads the TTY). In Claude Code use the ! prefix, e.g. ! \${CLAUDE_SKILL_DIR}/scripts/loops-key.sh set" >&2
      exit 2
    fi
    read -s -r -p "Loops API key: " KEY; echo
    [ -n "$KEY" ] || { echo "empty key, aborting" >&2; exit 1; }
    security add-generic-password -U -s "$SERVICE" -a "$ACCOUNT" -w "$KEY" >/dev/null
    KEY=""
    echo "stored in macOS Keychain (service: $SERVICE, account: $ACCOUNT)"
    ;;
  get)
    # Prints the key to stdout. ONLY use as:  VAR="$(loops-key.sh get)"  piped
    # into an env var for an API call. Never run standalone where it is displayed.
    security find-generic-password -s "$SERVICE" -a "$ACCOUNT" -w 2>/dev/null
    ;;
  status)
    if security find-generic-password -s "$SERVICE" -a "$ACCOUNT" >/dev/null 2>&1; then
      echo "stored"
    else
      echo "not stored"
    fi
    ;;
  *)
    usage; exit 1
    ;;
esac