# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A Claude Code **plugin** (`promptmetrics-newsletter`, v0.6.1) that bundles five skills to turn a newsletter brief into a sent Loops.so campaign. There is **no build system, test suite, linter, or package manager** — it is prose, shell scripts, and JSON manifests. Do not run `make`/`npm test`/`pytest` here; there is nothing to build or run headlessly. The skill's behavior is defined in `plugins/newsletter/skills/newsletter/SKILL.md` and its `references/`; the only executable code is `plugins/newsletter/skills/newsletter/scripts/`.

## Architecture (the big picture that spans files)

**Two tiers of skills:**

- `plugins/newsletter/skills/newsletter/` — the **opinionated workflow layer this repo owns**. It does *not* make REST calls of its own for standard operations; it delegates those to the vendored Loops API skill. What it owns: the brief→LMX assembly (Step 3), the gap-fillers Loops doesn't provide (spam scan, broken-link check), the two human approval gates, and the never-auto-fire discipline.
- `plugins/newsletter/skills/loops-api/`, `plugins/newsletter/skills/loops-cli/`, `plugins/newsletter/skills/loops-lmx/`, `plugins/newsletter/skills/loops-email-sending-best-practices/` — **vendored copies of Loops' official MIT skills**, synced from `github.com/Loops-so/skills` at a pinned ref (currently v0.2.0, recorded in `NOTICE`). Each carries an attribution header + upstream `LICENSE`. **Do not hand-edit these** — re-sync from upstream via `plugins/newsletter/skills/newsletter/scripts/sync-loops-skills.sh` so attribution stays accurate. The dependency alternative is documented in README but intentionally not used (vendoring is the only zero-step install path).

**Plugin wiring:** `plugins/newsletter/.claude-plugin/plugin.json` is the manifest; `.claude-plugin/marketplace.json` is a self-hosted marketplace whose `skills` array declares **all five** skill dirs — that array is what makes `/plugin install promptmetrics-newsletter@promptmetrics` bring the Loops skills along with no separate command. Adding/removing a skill means editing that array.

**The one rule that overrides everything:** `scheduling` stays **unset** through every step until Gate 2. It is set to `method:"now"` *only* in Step 9, *only* after an explicit human "send". No `scheduling` field may appear in any earlier API call. If anything fails or the user goes silent, the campaign stays Draft and cannot fire.

**Workflow = 9 steps + 2 hard STOP gates** (full procedure in `SKILL.md`): collect brief → create draft campaign → assemble LMX → set email content (LMX, never HTML) → **Gate 1 preview STOP** → Guardian + spam + broken-link checks → list confirm → **Gate 2 send STOP** → send. The delegation table in `SKILL.md` ("Delegation summary") states which step is owned by the newsletter skill vs. delegated to the Loops API skill — consult it before adding logic to a step.

**Reference files are loaded at runtime, not at skill-read time.** Each step of `SKILL.md` names the `references/*.md` it depends on (`brief-schema`, `lmx-master-template`, `token-map`, `loops-endpoints`, `guardian-checklist`, `spam-terms`, `onboarding`, `lmx-notes`, `senders`). Changing a step's behavior usually means editing both `SKILL.md` and the relevant reference, not inventing new contract.

## Secrets discipline (critical)

The Loops API key lives in the **OS keychain**, never on disk in a tracked file. Keychain service name: `promptmetrics-lops-newsletter` (account = `$USER`). On Linux it uses `secret-tool`/libsecret with a `pass` fallback. See `plugins/newsletter/skills/newsletter/scripts/loops-key.sh`.

- The skill checks **presence** (`loops-key.sh status`) and validates via `GET /v1/api-key`; it never reads/echoes/logs the key value at runtime.
- `loops-key.sh install-line` writes a **static** keychain-read `export` line to **both `~/.zprofile` and `~/.zshrc`** so login non-interactive zsh (the Bash tool) *and* interactive terminals source it. The key enters env only at shell startup, after a restart.
- **Forbidden pattern:** never emit `LOOPS_API_KEY="$(.../loops-key.sh get)" ...` inline at runtime — a classifier blocks keychain-secret extraction and it leaks the key into the transcript. `install-line` is allowed (it writes a read command, not the value); `get` at runtime is not.
- `.env` (gitignored, sourced from `~/.zprofile`) is a documented plaintext-at-rest alternative — still never tracked.

## Commands (dev / maintainer)

Load the plugin into a session from a clone (no install):
```bash
claude --plugin-dir ./plugins/newsletter
```

Per-machine API key setup (run once per machine; the `!` prefix in Claude Code works too):
```bash
./plugins/newsletter/skills/newsletter/scripts/loops-key.sh set           # type key silently → stored in keychain
./plugins/newsletter/skills/newsletter/scripts/loops-key.sh status        # → stored | missing
./plugins/newsletter/skills/newsletter/scripts/loops-key.sh install-line  # write guarded read line to ~/.zprofile + ~/.zshrc
# then: exec $SHELL -l   (restart shell so LOOPS_API_KEY is sourced)
```

Re-sync the vendored Loops skills from upstream (maintainers only):
```bash
./plugins/newsletter/skills/newsletter/scripts/sync-loops-skills.sh          # default ref pinned in script/NOTICE
./plugins/newsletter/skills/newsletter/scripts/sync-loops-skills.sh v0.2.1   # any tag/branch
# review the diff, commit, and — if the ref changed — update the pinned ref in NOTICE + the script default
```

`scripts/install-loops-skills.sh` is a **deprecated no-op stub** kept so old docs don't break — don't resurrect it.

## Verification

There is no automated test. End-to-end verification is manual and documented in the "Verification" section of `loops-api-verification-and-template-design.md`: validate the key (`GET /v1/api-key` → `{success, teamName}`), confirm the Theme exists (`GET /v1/themes`), dry-create a campaign + set minimal LMX (`<Style themeId/><Paragraph>test</Paragraph>` → expect 200 not 409), preview a full mixed-issue LMX in Apple Mail + Gmail (light/dark), plant a spam term + a 404 link to confirm the gap-fillers fire, confirm `scheduling` stays unset through both gates and the campaign only moves Draft → Sent after Gate 2, and confirm a max-length issue (5 cards + 8 paragraphs) assembles under the 100KB cap.

## One-time Loops UI setup (prerequisites the code cannot provide)

Step 0 hard-gates on these; the skill stops if any are missing. They are configured in the Loops UI, not in this repo:
- Sending domain + `fromName`/`fromEmail` (Loops Settings → Domains) — `POST /v1/campaigns` 400s without them.
- The "ProNova" Theme with the exact token values in `references/token-map.md`. Themes are **writable** via the API (`POST /v1/themes` to create, `POST /v1/themes/{themeId}` to update), so onboarding creates it automatically; the Loops UI (→ Themes) is the fallback when the team's Content API is not enabled.
- The ProNova logo (tile and wordmark, dark ink on an opaque light ground) uploaded via the Loops API 3-step upload flow → its URL goes in the brief's `hero_logo_url`.
- Mailing list(s) exist (Loops UI → Lists; `GET /v1/lists` returns names but **no contact count** — the skill shows names only and asks the user to verify counts in the UI).

## Who can send

Gate 2 enforces an allowlist (team discipline, not cryptographic RBAC): only emails in `plugins/newsletter/skills/newsletter/references/senders.md` or the `NEWSLETTER_SENDERS` env var (comma-separated) may fire the send. Current user resolves from `NEWSLETTER_SENDER` env → git `user.email` → Claude Code session identity. **The placeholder emails in `senders.md` must be replaced before the first real send.**

## Decisions baked in

Defaults locked during planning (full rationale in `loops-api-verification-and-template-design.md` "Open decisions"): unpersonalized body with `contactPropertiesFallbacks:{firstName:"there"}` always set (D5); 3 default / 5 max key-point cards with per-card "read more" link (D6); subject + preview approved at Gate 1 (D7); built-in spam-terms list with house-override hook (D8); five required brief fields (BF; `cta` became optional in v0.4.0 when §11 became the standing Operator Stack community card). Account/team config that remains the user's call (sending domain, allowlist, list, logo variant, hero art direction) is listed in README's "Decisions baked in".

## Notes specific to editing this repo

- LMX (not HTML) is the only content format the skill sets — `POST /v1/email-messages/{id}` takes the `lmx` field only. The 100KB cap is enforced in Step 3 *before* any API call; over-cap fails rather than sends.
- The skill sends **campaigns** (one-to-many), never transactional email. `{contact.firstName}` is the only personalization channel.
- Loops auto-appends the footer + unsubscribe; the template does not author one.
- The email wears the **ProNova design system** (source: `pronova-website/src/styles/tokens.css`; mapping: `references/token-map.md`). The brand is written "ProNova", capital N. The plugin, marketplace, slash command and keychain service still carry their `promptmetrics-*` names. White `#ffffff` sheet on a `#f6f7fa` canvas, ink `#15181d` text and button, accent `#3b4bc8` for links and the kicker's ◆ only, one 6px radius, no pills, no italic or colored word in a heading, no emoji. The type is **one family, Sora**, with Arial as the fallback — LMX exposes only `bodyFontFamily`/`bodyFontCategory`, so there is no heading or mono font, and no weight or tracking control either. Gmail/Outlook/Yahoo show Arial, so hierarchy rests on size and color. Cards are `#f6f7fa` Sections, only 1.07:1 against the sheet, so the fill alone does not carry them: a 1px `#e6e9ef` border (`blockBorderWidth` + `blockBorderColor` on `<Section>`, undocumented upstream but confirmed in the 2026-11-27 Loops dry run), a 6px `<Divider>` in one of the four topic tints, the radius and the padding do. LMX has no shadow. Dark mode is **survived, not controlled** (no `@media` in LMX, and ProNova has no dark theme): explicit ink-and-white button, logo on an opaque light ground.
- Several `.md` files in the repo root (`bug-report-*`, `linux-zshrc-support-plan.md`, `loops-deps-auto-install-plan.md`, `loops-api-verification-and-template-design.md`) are working/planning notes, not shipped skill content.