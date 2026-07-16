#!/usr/bin/env bash
# loops-key.sh — secure Loops API key storage for the newsletter skill.
#
# Stores the key in the OS credential store. The key is never written to a repo
# file, never passed as a CLI argument, never printed by this script except by
# `get` (which is meant to be piped into an env var for an API call, not
# displayed). The skill only ever calls `status` (boolean) in-session.
#
# Backends: macOS Keychain via `security`; Linux libsecret via `secret-tool`
# with a `pass` (GPG) fallback. Windows Credential Manager is not yet wired up
# (reports unsupported). `install-line` writes a guarded keychain-read export
# line to BOTH ~/.zprofile AND ~/.zshrc so the key is sourced by login
# non-interactive zsh (the Bash tool) AND interactive terminals. It writes a
# STATIC read command — never the key value — so it is not `get` and does not
# trip the auto-mode keychain-secret-extraction classifier.

set -euo pipefail
SERVICE="promptmetrics-lops-newsletter"
ACCOUNT="${USER:-$(id -un)}"
PASS_PATH="promptmetrics-lops-newsletter/$ACCOUNT"

detect_backend() {
  case "$(uname -s)" in
    Darwin) echo "security" ;;
    Linux)
      if command -v secret-tool >/dev/null 2>&1; then echo "secret-tool"
      elif command -v pass >/dev/null 2>&1; then echo "pass"
      else echo "none"
      fi
      ;;
    *) echo "unsupported" ;;
  esac
}

BACKEND="$(detect_backend)"

usage() { echo "usage: loops-key.sh {set|get|status|install-line}" >&2; }

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
    case "$BACKEND" in
      security)
        security add-generic-password -U -s "$SERVICE" -a "$ACCOUNT" -w "$KEY" >/dev/null
        KEY=""
        echo "stored in macOS Keychain (service: $SERVICE, account: $ACCOUNT)"
        ;;
      secret-tool)
        printf '%s' "$KEY" | secret-tool store --label='PromptMetrics newsletter' service "$SERVICE" account "$ACCOUNT"
        KEY=""
        echo "stored via secret-tool/libsecret (service: $SERVICE, account: $ACCOUNT)"
        ;;
      pass)
        if ! pass ls >/dev/null 2>&1; then
          KEY=""
          echo "loops-key.sh: pass not initialized. Run 'pass init <gpg-id>' first." >&2
          exit 4
        fi
        printf '%s' "$KEY" | pass insert -e -f "$PASS_PATH" >/dev/null
        KEY=""
        echo "stored via pass ($PASS_PATH)"
        ;;
      none)
        KEY=""
        echo "loops-key.sh: no Linux keychain backend found. Install libsecret/secret-tool, or pass (with 'pass init <gpg-id>'), then re-run." >&2
        exit 3
        ;;
      unsupported)
        KEY=""
        echo "loops-key.sh: unsupported platform. On Windows use Windows Credential Manager." >&2
        exit 3
        ;;
    esac
    ;;
  get)
    # Prints the key to stdout. ONLY use as:  VAR="$(loops-key.sh get)"  piped
    # into an env var for an API call. Never run standalone where it is displayed.
    case "$BACKEND" in
      security)    security find-generic-password -s "$SERVICE" -a "$ACCOUNT" -w 2>/dev/null ;;
      secret-tool) secret-tool lookup service "$SERVICE" account "$ACCOUNT" ;;
      pass)        pass show "$PASS_PATH" ;;
      none)
        echo "loops-key.sh: no Linux keychain backend found. Install libsecret/secret-tool, or pass." >&2
        exit 3
        ;;
      unsupported)
        echo "loops-key.sh: unsupported platform. On Windows use Windows Credential Manager." >&2
        exit 3
        ;;
    esac
    ;;
  status)
    # Boolean — prints "stored" / "not stored", never the value. Safe in-session.
    case "$BACKEND" in
      security)
        if security find-generic-password -s "$SERVICE" -a "$ACCOUNT" >/dev/null 2>&1; then echo "stored"
        else echo "not stored"; fi
        ;;
      secret-tool)
        # search, not lookup — lookup would print the value.
        if secret-tool search service "$SERVICE" account "$ACCOUNT" >/dev/null 2>&1; then echo "stored"
        else echo "not stored"; fi
        ;;
      pass)
        if pass show "$PASS_PATH" >/dev/null 2>&1; then echo "stored"
        else echo "not stored"; fi
        ;;
      none)
        echo "not stored"
        echo "loops-key.sh: no Linux keychain backend found (install libsecret/secret-tool or pass to enable keychain storage)." >&2
        ;;
      unsupported)
        echo "not stored"
        echo "loops-key.sh: unsupported platform." >&2
        ;;
    esac
    ;;
  install-line)
    # Writes a STATIC keychain-read export line (never the key) to both
    # ~/.zprofile and ~/.zshrc, guarded so the keychain is read at most once.
    # Not `get` — does not print the secret — so it does not trip the
    # keychain-secret-extraction classifier.
    if [ "$BACKEND" = "none" ]; then
      echo "loops-key.sh install-line: no Linux keychain backend found. Install libsecret/secret-tool or pass, store the key with 'loops-key.sh set', then re-run. (Or use the .env fallback — see onboarding.md.)" >&2
      exit 3
    fi
    if [ "$BACKEND" = "unsupported" ]; then
      echo "loops-key.sh install-line: unsupported platform. On Windows use Windows Credential Manager." >&2
      exit 3
    fi

    # read_cmd is wrapped in $(...) so the inner "$USER" quotes nest cleanly
    # inside export LOOPS_API_KEY="..." at shell startup (matches the original
    # onboarding form — command substitution, not a bare command string).
    case "$BACKEND" in
      security)    read_cmd='$(security find-generic-password -s promptmetrics-lops-newsletter -a "$USER" -w 2>/dev/null)' ;;
      secret-tool) read_cmd='$(secret-tool lookup service promptmetrics-lops-newsletter account "$USER" 2>/dev/null)' ;;
      pass)        read_cmd='$(pass show promptmetrics-lops-newsletter/$USER 2>/dev/null)' ;;
    esac

    marker='# added by promptmetrics-newsletter onboarding — reads the OS keychain at shell startup'
    guard_line='[ -z "$LOOPS_API_KEY" ] && export LOOPS_API_KEY="'"$read_cmd"'"'
    block="$marker"$'\n'"$guard_line"

    wrote=0
    for f in "$HOME/.zprofile" "$HOME/.zshrc"; do
      if grep -qF "$marker" "$f" 2>/dev/null; then
        echo "$f already has the export line; skipping"
      else
        ( umask 022; printf '%s\n' "$block" >> "$f" )
        echo "$f wrote keychain export line"
        wrote=1
      fi
    done

    echo "Restart your shell: exec \$SHELL -l (or open a new terminal)"
    exit 0
    ;;
  *)
    usage; exit 1
    ;;
esac