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

**Make it available to the Loops API skill — required, not optional.** The Loops API skill reads `LOOPS_API_KEY` from the environment; without it, no API call can run. Onboarding runs `install-line`, which appends a guarded keychain-read line to **both `~/.zprofile` and `~/.zshrc`** so the key is read from the keychain into env at shell startup — no plaintext at rest:

```bash
! ${CLAUDE_SKILL_DIR}/scripts/loops-key.sh install-line
```

It writes (macOS form — on Linux `install-line` emits the matching `secret-tool lookup …` or `pass show …` shape automatically):

```sh
# added by promptmetrics-newsletter onboarding — reads the OS keychain at shell startup
[ -z "$LOOPS_API_KEY" ] && export LOOPS_API_KEY="$(security find-generic-password -s promptmetrics-lops-newsletter -a "$USER" -w 2>/dev/null)"
```

Why **both** `~/.zprofile` and `~/.zshrc`: Claude Code's Bash tool spawns a **login, non-interactive** zsh, which sources `~/.zprofile` (and `~/.zshenv`) but **not** `~/.zshrc` — a `~/.zshrc`-only line is invisible to the Bash tool, so the skill would see an empty `LOOPS_API_KEY` and fail. The user's everyday **interactive, non-login** terminals source `~/.zshrc` and **not** `~/.zprofile`, so a `~/.zprofile`-only line is invisible there and the user can't run the workflow by hand from a normal terminal. Writing **both** gives full coverage, and the `[ -z "$LOOPS_API_KEY" ]` guard means a login interactive zsh (which sources both files) reads the keychain at most once. Why the keychain is read directly (not via `${CLAUDE_SKILL_DIR}/scripts/loops-key.sh get`): `${CLAUDE_SKILL_DIR}` is unset in the user's login shell, and the plugin's install path is version-stamped and changes on every update — a direct keychain read is path-independent and survives updates.

Why **not** `~/.zshenv`: it runs on **every** zsh, including non-interactive scripts, so a keychain read there would fire on every shell spawn — too heavy. `~/.zprofile` + `~/.zshrc` is the right surface. (bash users on `.bash_profile`/`.bashrc`: `install-line` targets zsh dotfiles only — add the emitted line to your bash profile yourself for now.)

> Onboarding **asks for explicit confirmation** before `install-line` modifies a dotfile outside the project. If the user declines, give them the line to add themselves. `.env` (gitignored, sourced from `~/.zprofile` via `set -a; source /path/to/.env; set +a`) remains a supported alternative, but stores the key in plaintext at rest — prefer the keychain line.

**Restart the shell before continuing.** Tell the user: open a new terminal (or run `exec $SHELL -l`) so `~/.zprofile` (and `~/.zshrc` for interactive shells) is sourced and `LOOPS_API_KEY` lands in the environment. Validation that the key actually authenticates happens at Step 0 of the next run — do not attempt `GET /v1/api-key` here.

**Security notes**
- Storage is the OS credential store — macOS `security` (Keychain); Linux `libsecret`/`secret-tool` with a `pass` (GPG) fallback; Windows Credential Manager still deferred (`loops-key.sh` reports unsupported and exits non-zero there). `install-line` emits the platform-correct keychain-read line for macOS and Linux; on Windows, store the key with your platform's tool and export `LOOPS_API_KEY` from `~/.zprofile` manually (or use the `.env` fallback).
- **The skill never runs `loops-key.sh get` at runtime, and never emits `LOOPS_API_KEY="$(.../loops-key.sh get)"` inline.** `get` is a manual escape hatch only (for the user to run in their own terminal, piped into an env var). The key enters the environment solely via the keychain-read line `install-line` writes, which runs at shell startup outside any Claude session.
- The skill itself only ever calls `status` (boolean) in-session. It never reads the key into the conversation.

## 2. Design system / template — the "ProNova" Theme

The Theme is created/verified **via the Loops API** (Themes are writable in OpenAPI v1.19.0: `POST /v1/themes` and `POST /v1/themes/{themeId}`). The Loops UI path remains a **fallback** when the API path fails. Canonical token values live in `references/token-map.md`, which takes them from the ProNova design system (`pronova-website/src/styles/tokens.css`).

**Upgrading from v0.5.x.** The skill no longer looks for the "PromptMetrics Sea Glass" Theme and never modifies or deletes it. The first run after the upgrade finds no Theme named "ProNova" and creates one in 2c. The old Theme stays in the Loops account until someone removes it there by hand.

### 2a. Look for an existing Theme — `GET /v1/themes`

`GET /v1/themes` is **paginated**: it returns `{ pagination, data: [...] }` where `data[].id` is an **opaque** value (e.g. `cm_...`), not a slug. Paginate with `perPage` (10–50) and `pagination.nextCursor` — loop pages until a Theme with `name == "ProNova"` is found **or** pages are exhausted. Only after exhausting pages may you conclude the Theme is missing.

```http
GET /v1/themes?perPage=50
# if pagination.nextCursor is non-null, repeat:
GET /v1/themes?perPage=50&cursor={nextCursor}
```

### 2b. If found — capture its id (M2)

Store the matched Theme's `data[].id` (the opaque `cm_...` value). This id is used by:

- `POST /v1/themes/{themeId}` — to reconcile the Theme's styles to the exact `token-map.md` values below (optional; run if the stored styles have drifted), and
- `<Style themeId="...">` — as a **candidate** value for the LMX `<Style />` tag's `themeId` attribute.

> **Resolved empirically (2026-08-31): `<Style themeId>` takes the opaque `data[].id`** (e.g. `cmrngnrqv…`). Passing the theme *name* returns `422 <Style> references unknown themeId`. No A/B test is outstanding. Capture `data[].id` and pass exactly that into `<Style themeId>`.

### 2c. If missing — create it via `POST /v1/themes`

`POST /v1/themes` with the ProNova token values from `token-map.md` (name `"ProNova"` + the `ThemeStyles` keys, which match the LMX `<Style />` attribute names):

| ThemeStyles key | Value |
|---|---|
| `backgroundColor` | `#f6f7fa` (outer canvas) |
| `backgroundYPadding` | `24` |
| `bodyColor` | `#ffffff` (email sheet) |
| `bodyXPadding` | `24` |
| `bodyYPadding` | `24` |
| `bodyFontFamily` | `Sora` |
| `bodyFontCategory` | `sans-serif` |
| `borderColor` | `#e6e9ef` |
| `borderWidth` | `1` |
| `borderRadius` | `6` |
| `textBaseColor` | `#15181d` |
| `textBaseFontSize` | `16` |
| `textBaseLineHeight` | `165` |
| `textLinkColor` | `#3b4bc8` |
| `buttonBodyColor` | `#15181d` |
| `buttonTextColor` | `#ffffff` |
| `buttonBorderRadius` | `6` |
| `buttonBodyXPadding` | `32` |
| `buttonBodyYPadding` | `13` |
| `dividerColor` | `#e6e9ef` |
| `dividerBorderWidth` | `1` |
| `heading1/2/3Color` | `#15181d` |
| `heading1/2/3FontSize` | 34 / 28 / 22 |
| `heading1/2/3LineHeight` | 118 / 124 / 130 |
| Document meta (Loops UI only, not an API key) | `color-scheme: light dark` |

**One font family only.** ThemeStyles has no `headingFontFamily` and no `monoFontFamily` — `bodyFontFamily` sets the whole email. Do not send `h1FontSize` or `bodyFontSize` either; the real keys are `heading1FontSize` and `textBaseFontSize`. The table above lists every key in the body; the body itself, as JSON, is in `token-map.md`. The two must match value for value.

**What the Theme cannot hold.** ProNova sets body copy at weight 300 and headings at 600 with tight tracking. `ThemeStyles` has no weight key, and the unit of `heading*LetterSpacing` is undocumented, so the Theme sets neither. The four topic tints (`#d6dcf8`, `#d3ecf2`, `#cdebdd`, `#f3efc6`) are not Theme values either: the assembler inlines them on each card's top bar (`token-map.md`).

Note: ThemeStyles has **`bodyXPadding` / `bodyYPadding`** (and `backgroundXPadding` / `backgroundYPadding`) — there is no `bodyPadding` key. On success (`201`) capture the returned Theme `id` (feeds M2). A `401` here with an otherwise-valid key means the team's **Content API is not enabled** (distinct from the Step 0 `GET /v1/api-key` 401) — point the user to Loops Settings to enable it.

### 2d. Fallback — Loops UI

If `POST /v1/themes` returns `400` / `403` / `401` (or the team has not enabled the Content API), fall back to the **manual** path: Loops UI → Themes → New, name **"ProNova"**, with the exact values in the table in 2c (plus the manual `Body padding: 24` mapping used by the UI). After the user creates it, **re-run 2a** — `GET /v1/themes` again, paginate, and capture the new Theme's `id` so M2 is satisfied either way.

**Verify**: `GET /v1/themes` (via the Loops API skill) returns a Theme with `name == "ProNova"`, and its `id` is captured for use by `POST /v1/themes/{id}` and as a `<Style themeId>` candidate.

## 3. From address — sending domain + fromName / fromEmail

Two **distinct** from-address concepts:

- **Sending address (Loops UI only)** — Loops Settings → Domains: verify the sending domain, set `fromName` (e.g. `"ProNova Field Notes"`) and the full sending address `fieldnotes@<verified-domain>`. This is configured in the UI, never via the API.
- **API `fromEmail` (Step 4, `POST /v1/email-messages`)** — **USERNAME ONLY, no `@`, no domain.** For example `"fieldnotes"`, not `"fieldnotes@<verified-domain>"`. Loops appends the verified sending domain automatically; sending a full `user@domain` here is an error.

`POST /v1/campaigns` **400s** if the sending domain or `fromName`/`fromEmail` aren't configured in the UI. Onboarding guides the user through Loops Settings → Domains to set both before any API send.

Loops appends the campaign footer, and the template authors none. Whatever company details that footer shows come from the Loops account settings, not from this repo. Where a company line is shown, it reads `ProNova AI Labs UG, Berlin`.

**Verify**: a dry `POST /v1/campaigns { name:"onboarding-check" }` returns a campaign (not 400). A 400 → domain/from unconfigured; loop back. Delete the throwaway campaign afterward.

## 4. Logo — hero_logo_url

One-time logo upload (Loops API skill) of the **ProNova logo tile and wordmark**: dark ink on a light ground. Export it on an **opaque white ground**, not a transparent one, so the ink wordmark keeps its ground if a client darkens the sheet. The template renders it 120px wide (`lmx-master-template.md`). This skill does not create the image file; upload the one the brand already has. Uploads are a **3-step flow** against base `https://app.loops.so/api`:

1. `POST /v1/uploads` → returns a `presignedUrl` and an upload `id`.
2. `PUT` the logo file bytes to the `presignedUrl`.
3. `POST /v1/uploads/{id}/complete` → returns the public hosted URL.

Store that URL as `hero_logo_url` (in the brief or project config). Step 0 fail-stops if absent.

**Current asset (uploaded 2026-11-27):** `https://images.vialoops.com/cmqdtcbc82mqp0jxso24o1qbf/cmwyzm0by3odo0k068suw14bt.png` — the ProNova tile and wordmark on a white ground, 528 × 136 px (3.88:1), drawn from the site's `Logo.astro` at four times its size. At the template's `width="120"` it is about 31px tall. It rendered correctly in the Loops dry run of that day at 760 and 390 px wide.

**Verify**: the returned URL is a non-empty `https://...` string the user records for use in briefs.