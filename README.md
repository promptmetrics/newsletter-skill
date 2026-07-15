# PromptMetrics Newsletter Skill

A Claude Code skill that turns a newsletter brief into a Loops.so email — **assembled as LMX, not HTML** — previews it to the author, runs pre-send safety checks, and sends to a Loops mailing list after **two human approval gates**. It never auto-fires. Thin layer on top of Loops' shipped agent skills (API / LMX / CLI / email).

**Status:** Phase 1a (v0.1) — interview → brief → LMX → preview → send. No Notion dependency. Phase 1b (Notion brief backbone) and Phase 2 (Cowork wrapper) are planned.

## Install

```bash
git clone https://github.com/promptmetrics/newsletter-skill promptmetrics-newsletter-skill
cd promptmetrics-newsletter-skill
cp .env.example .env
# edit .env: set LOOPS_API_KEY  (Loops Settings -> API; never commit the real key)
./scripts/install-loops-skills.sh   # pulls in Loops API/LMX/CLI/email skills
```

Then install this plugin into Claude Code per your team's plugin flow (the `.claude-plugin/plugin.json` registers the `newsletter` skill at `skills/newsletter`).

## One-time Loops UI setup (do this before the first run)

The skill checks for these at Step 0 and will stop if missing.

1. **Sending domain + `fromName` / `fromEmail`** — Loops Settings → Domains. `POST /campaigns` **400s** if these aren't configured. e.g. fromName `"PromptMetrics Field Notes"`, fromEmail `fieldnotes@<verified-domain>`.
2. **Create the "PromptMetrics Paper" Theme** — Loops UI → Themes → New. Themes are **read-only via API**, so this is manual. Set:
   - Background `#f4efe7`, text base `#1c1c1c`, link color `#a1482a`
   - Button background `#d97757`, button text `#2a160e`, button radius `999`
   - Card radius `18`, body padding `24`
   - Fonts: headings `Fraunces, ui-serif, Georgia, serif`; body `Inter, ui-sans-serif, Arial, sans-serif`; labels `JetBrains Mono, ui-monospace, Consolas, monospace`
   - Heading sizes: H1 32 / H2 24 / H3 20 / body 16
   - Document-level `<meta name="color-scheme" content="light dark">`
3. **Upload the logo** — via `POST /uploads` (Loops API skill) or Loops UI → Uploads. Use the **dark-mode-safe variant** (reverse pinwheel in a fixed-color chip). Put the returned Loops-hosted URL into the brief's `hero_logo_url` field (the skill checks for it at Step 0 and stops if missing).
4. **Confirm mailing list(s)** — Loops UI → Lists. Note the list name(s) the skill will offer at Gate 2. (`GET /lists` returns names but the API gives **no contact count** — the skill shows names only and asks you to verify counts in the UI.)
5. **Set `LOOPS_API_KEY`** in your local `.env`.

## Who can send

Only users listed in `skills/newsletter/references/senders.md` (or the `NEWSLETTER_SENDERS` env var, comma-separated) can fire the send at **Gate 2**. To add a sender, edit that file or set the env var. The skill enforces this check — it is **not** Loops-side RBAC, and not cryptographic; it's team-discipline enforcement that makes the irreversible send a deliberate, attributed act. **Replace the placeholder emails before first send.**

The current user is resolved from `NEWSLETTER_SENDER` env → git `user.email` → Claude Code session identity.

## How it works (the loop)

1. **Collect brief** — interview (default), freeform paste, or Notion DB (1b). Gap-collect against the 6 required fields (`references/brief-schema.md`).
2. **Create draft campaign** — `POST /campaigns`.
3. **Assemble LMX** — fill the 12-section master template (`references/lmx-master-template.md`) against the Paper token map (`references/token-map.md`); expand `key_points[]`/`body_blocks[]`; enforce the 100KB cap.
4. **Set email content** — `POST /email-messages/{id}` with the `lmx` payload only.
5. **Gate 1 — preview** — send to the author; **STOP** for approval (check Apple Mail + Gmail, light + dark).
6. **Pre-send checks** — Loops Guardian + the skill's own spam scan (`references/spam-terms.md`) + live broken-link check.
7. **List confirm** — `GET /lists` (names only).
8. **Gate 2 — confirm send** — **STOP**; allowlist check; `scheduling` still unset.
9. **Send** — `POST /campaigns/{id} { scheduling:{method:"now"} }` only after an explicit "send".

Full procedure: `skills/newsletter/SKILL.md`. Endpoint contracts: `skills/newsletter/references/loops-endpoints.md`.

## Verification (end-to-end)

See the "Verification" section of `loops-api-verification-and-template-design.md`. In short: confirm the Theme exists via `GET /themes`; dry-create a campaign + set a minimal LMX (`<Style themeId/><Paragraph>test</Paragraph>`) → expect 200 not 409; preview a full mixed-issue LMX and open in Apple Mail + Gmail (light/dark); plant a spam term + a 404 link to confirm the gap-fillers fire; confirm `scheduling` is unset through both gates and the campaign moves Draft → Sent only after Gate 2; confirm a max-length issue (5 cards + 8 paragraphs) assembles under 100KB.

## Decisions baked in (change if needed)

These defaults were locked during planning (see `loops-api-verification-and-template-design.md` "Open decisions"):

- **D5** Unpersonalized body; `contactPropertiesFallbacks:{firstName:"there"}` always set for safety (no greeting block).
- **D6** Key-point cards: 3 default, 5 max; "read more" link per card (not whole-card clickable).
- **D7** Subject + preview approved at Gate 1 (the preview is the approval).
- **D8** Built-in spam-terms list with a house-override hook (`references/spam-terms.md`).
- **BF** Six required brief fields (`references/brief-schema.md`).

Still **your call** (account/team config, not code):
- **D1** Sending domain + `fromName`/`fromEmail` (Loops UI).
- **SEND** Who's on the allowlist (`references/senders.md`).
- **D2** Which mailing list(s) + any "engaged" segment (Loops UI).
- **D4** Logo variant for dark mode.
- **D9** Hero art direction (cream-backed 1.91:1 pinwheel motif vs. author-supplied per issue).

## Repo layout

```
.claude-plugin/plugin.json
skills/newsletter/
  SKILL.md
  references/
    brief-schema.md  lmx-master-template.md  token-map.md
    guardian-checklist.md  spam-terms.md  loops-endpoints.md
    lmx-notes.md  senders.md
scripts/install-loops-skills.sh
.env.example  .gitignore  README.md
```

## Phasing

- **Phase 1a (v0.1)** — this release. Interview → brief → LMX → preview → send.
- **Phase 1b (v0.2)** — Notion brief-DB read + gap-collection + Theme guide (`references/notion-brief-query.md`, `references/theme-setup-guide.md`).
- **Phase 2 (v0.3)** — Cowork wrapper so non-coders can run it.

## Notes

- The skill sends **campaigns** (one-to-many), not transactional email. `{contact.firstName}` is the only personalization channel.
- Loops auto-appends the campaign footer + unsubscribe link — the template does **not** author one.
- Web fonts (Fraunces/Inter/JetBrains Mono) render only in Apple Mail/Samsung/Comcast; Gmail/Outlook/Yahoo fall back to Georgia/Arial. Short headlines + italic-coral emphasis + coral top-bar carry the brand in fallback.
- Dark mode is **survived, not controlled** (no `@media` in LMX): warm-not-pure hex, coral-ink button text, mid-tone logo.