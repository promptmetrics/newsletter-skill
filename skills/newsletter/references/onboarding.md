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

**Make it available to the Loops API skill.** The Loops API skill reads `LOOPS_API_KEY` from the environment. Onboarding offers to add one line to the user's shell profile (`~/.zshrc`, etc.) so the key is sourced from the keychain into env at shell startup — no plaintext at rest:

```sh
export LOOPS_API_KEY="$(${CLAUDE_SKILL_DIR}/scripts/loops-key.sh get)"
```

> Onboarding **asks for explicit confirmation** before modifying a dotfile outside the project. If the user declines, give them the line to add themselves, or have them export it per session. `.env` (gitignored) remains a supported alternative.

**Security notes**
- Storage is macOS Keychain. On Linux use `secret-tool`/`pass`; on Windows use Windows Credential Manager — `loops-key.sh` reports unsupported and exits non-zero otherwise.
- `loops-key.sh get` prints the key — use it only piped into an env var (`$(... get)`) for an API call, never standalone where it would be displayed.
- The skill itself only ever calls `status` (boolean). It never calls `get` or reads the key into the conversation.

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

**Verify**: `GET /themes` (via the Loops API skill) returns a Theme with `name == "PromptMetrics Paper"`. Loop until present.

## 3. From address — sending domain + fromName / fromEmail

`POST /campaigns` **400s** if the sending domain or `fromName`/`fromEmail` aren't configured. Onboarding guides the user through Loops Settings → Domains: verify the sending domain, set `fromName` (e.g. `"PromptMetrics Field Notes"`) and `fromEmail` (e.g. `fieldnotes@<verified-domain>`).

**Verify**: a dry `POST /campaigns { name:"onboarding-check" }` returns a campaign (not 400). A 400 → domain/from unconfigured; loop back. Delete the throwaway campaign afterward.

## 4. Logo — hero_logo_url

One-time `POST /uploads` (Loops API skill) of the **dark-mode-safe** logo variant (reverse pinwheel in a fixed-color chip). Store the returned Loops-hosted URL as `hero_logo_url` (in the brief or project config). Step 0 fail-stops if absent.

**Verify**: the returned URL is a non-empty `https://...` string the user records for use in briefs.