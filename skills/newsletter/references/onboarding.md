# Onboarding — First-Run Setup

Run when Step 0 finds a missing prerequisite (first use, or after a reset). **Idempotent**: set up only what's missing. Four setups, each verifiable — the skill drives the user through them and confirms each before moving on.

## 1. Loops API key — entered by the user, stored in the OS keychain

The key is **never** written to a repo file, passed as a CLI argument, logged, or echoed by the skill. It lives in the OS credential store (macOS Keychain).

**Enter it** — the user runs this in their own terminal (the `!` prefix in Claude Code also works), so the key is read silently from the TTY, not from args or history:

```bash
! ${CLAUDE_SKILL_DIR}/scripts/loops-key.sh set
```

`loops-key.sh set` uses `read -s` (no echo) and `security add-generic-password`. The key never appears in shell history or the process list.

**Verify** — the skill may run this; it prints only `stored` / `not stored`, never the value:

```bash
${CLAUDE_SKILL_DIR}/scripts/loops-key.sh status
```

**Do NOT validate in this session.** The key is now in the keychain, but `LOOPS_API_KEY` is not yet in the environment — and the skill must never run `loops-key.sh get` at runtime to put it there (the auto-mode classifier blocks keychain-secret extraction, and it would expose the key in the transcript). Validation against `GET /v1/api-key` runs at **Step 0 of the first real run, after the shell restart below**, once the export line has sourced the key into env. Continue to "Make it available" next.

**Make it available to the Loops API skill — required, not optional.** The Loops API skill reads `LOOPS_API_KEY` from the environment; without it, no API call can run. Onboarding adds one line to the user's **`~/.zprofile`** (login-sourced) so the key is read from the keychain into env at shell startup — no plaintext at rest:

```sh
# added by promptmetrics-newsletter onboarding — reads the macOS Keychain at shell startup
export LOOPS_API_KEY="$(security find-generic-password -s promptmetrics-lops-newsletter -a "$USER" -w 2>/dev/null)"
```

Why `~/.zprofile` and not `~/.zshrc`: Claude Code's Bash tool spawns a **login, non-interactive** zsh, which sources `~/.zprofile` (and `~/.zshenv`) but **not** `~/.zshrc` — a `~/.zshrc` export is invisible to the Bash tool, so the skill would see an empty `LOOPS_API_KEY` and fail. Why the keychain is read directly (not via `${CLAUDE_SKILL_DIR}/scripts/loops-key.sh get`): `${CLAUDE_SKILL_DIR}` is unset in the user's login shell, and the plugin's install path is version-stamped and changes on every update — a direct keychain read is path-independent and survives updates.

> Onboarding **asks for explicit confirmation** before modifying a dotfile outside the project. If the user declines, give them the line to add themselves. `.env` (gitignored, sourced from `~/.zprofile` via `set -a; source /path/to/.env; set +a`) remains a supported alternative, but stores the key in plaintext at rest — prefer the keychain line.

**Restart the shell before continuing.** Tell the user: open a new terminal (or run `exec $SHELL -l`) so `~/.zprofile` is sourced and `LOOPS_API_KEY` lands in the environment. Validation that the key actually authenticates happens at Step 0 of the next run — do not attempt `GET /v1/api-key` here.

**Security notes**
- Storage is macOS Keychain. On Linux use `secret-tool`/`pass`; on Windows use Windows Credential Manager — `loops-key.sh` reports unsupported and exits non-zero otherwise. The `~/.zprofile` line above is macOS-specific; `loops-key.sh` is macOS-only in this version, so onboarding does **not** auto-generate the Linux/Windows equivalent yet. On those hosts, store the key with your platform's tool and export `LOOPS_API_KEY` from `~/.zprofile` manually (or use the `.env` fallback) — Linux/Windows keychain-line generation is deferred.
- **The skill never runs `loops-key.sh get` at runtime, and never emits `LOOPS_API_KEY="$(.../loops-key.sh get)"` inline.** `get` is a manual escape hatch only (for the user to run in their own terminal, piped into an env var). The key enters the environment solely via the `~/.zprofile` line above, which runs at shell startup outside any Claude session.
- The skill itself only ever calls `status` (boolean) in-session. It never reads the key into the conversation.

## 2. Design system / template — the "PromptMetrics Paper" Theme

Loops Themes are **read-only via API**, so the Theme is built once in the Loops UI. Onboarding guides the user through Loops UI → Themes → New, name **"PromptMetrics Paper"**, with these exact values (canonical in `references/token-map.md`):

| Setting | Value |
|---|---|
| Background | `#f4efe7` |
| Text base | `#1c1c1c` |
| Link color | `#a1482a` |
| Button background | `#d97757` |
| Button text | `#2a160e` |
| Button radius | `999` |
| Card radius | `18` |
| Body padding | `24` |
| Headings font | `Fraunces, ui-serif, Georgia, serif` |
| Body font | `Inter, ui-sans-serif, Arial, sans-serif` |
| Labels font | `JetBrains Mono, ui-monospace, Consolas, monospace` |
| H1 / H2 / H3 / body sizes | 32 / 24 / 20 / 16 |
| Document meta | `color-scheme: light dark` |

**Verify**: `GET /v1/themes` (via the Loops API skill) returns a Theme with `name == "PromptMetrics Paper"`. Loop until present.

## 3. From address — sending domain + fromName / fromEmail

`POST /v1/campaigns` **400s** if the sending domain or `fromName`/`fromEmail` aren't configured. Onboarding guides the user through Loops Settings → Domains: verify the sending domain, set `fromName` (e.g. `"PromptMetrics Field Notes"`) and `fromEmail` (e.g. `fieldnotes@<verified-domain>`).

**Verify**: a dry `POST /v1/campaigns { name:"onboarding-check" }` returns a campaign (not 400). A 400 → domain/from unconfigured; loop back. Delete the throwaway campaign afterward.

## 4. Logo — hero_logo_url

One-time logo upload (Loops API skill) of the **dark-mode-safe** variant (reverse pinwheel in a fixed-color chip). Uploads are a **3-step flow** against base `https://app.loops.so/api`:

1. `POST /v1/uploads` → returns a `presignedUrl` and an upload `id`.
2. `PUT` the logo file bytes to the `presignedUrl`.
3. `POST /v1/uploads/{id}/complete` → returns the public hosted URL.

Store that URL as `hero_logo_url` (in the brief or project config). Step 0 fail-stops if absent.

**Verify**: the returned URL is a non-empty `https://...` string the user records for use in briefs.