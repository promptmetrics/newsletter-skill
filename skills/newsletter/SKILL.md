---
name: newsletter
description: |
  Takes a newsletter brief, assembles a Loops.so email as LMX (not HTML), sends a
  preview to the author, runs pre-send safety checks, and — after two human
  approval gates — sends to a chosen Loops mailing list. Sits on top of Loops'
  shipped API/LMX/CLI skills. Never auto-fires.
when_to_use: |
  Use when the user wants to send or draft a newsletter, build a "Field Notes"
  issue, or send a Loops.so campaign — e.g. "send this week's newsletter",
  "draft Field Notes issue 12", "send a preview to me then to the list". Do NOT
  use for transactional email, one-off transactional sends, or non-Loops email.
---

# PromptMetrics Newsletter Skill

Generates a "Field Notes" issue in Loops.so from a brief. **LMX, not HTML.** Thin layer over the installed Loops skills (API / LMX / CLI / email) — delegate REST calls to the Loops API skill; this skill owns the opinionated workflow, the brand→LMX translation, the two human gates, the gap-fillers, and the never-auto-fire discipline.

## When this skill activates

The user wants to send/draft a newsletter, build a "Field Notes" issue, or send a Loops campaign: e.g. "send this week's newsletter", "draft Field Notes issue 12", "send a preview to me then to the list". **Do not activate** for transactional email, one-off transactional sends, or non-Loops email tasks.

## The one rule that overrides everything

> **`scheduling` stays unset through every step until Gate 2.** It is set to `method:"now"` ONLY in Step 9, ONLY after an explicit human "send" at Gate 2. No `scheduling` field appears in any earlier API call. If any step fails or the user goes silent, the campaign stays in Draft — it cannot accidentally fire.

## References (read at runtime)

- `references/brief-schema.md` — required-fields contract (Step 1 gap-collection)
- `references/lmx-master-template.md` — 12-section LMX skeleton + expansion rules (Step 3)
- `references/token-map.md` — Paper tokens → LMX hex/attrs (Step 3)
- `references/loops-endpoints.md` — exact endpoints + field contracts (Steps 0,2,4,5,6,7,9)
- `references/guardian-checklist.md` — Guardian scope + gap-fillers (Step 6)
- `references/spam-terms.md` — spam-trigger term list (Step 6b)
- `references/onboarding.md` — first-run setup: design system/Theme, from address, API key (secure keychain storage) (Step 0)
- `references/lmx-notes.md` — LMX gotchas (Steps 3,4)
- `references/senders.md` — who-can-send allowlist (Step 8)

## Procedure

### Step 0 — Onboarding & prerequisites (skill)

**First run, or any missing prerequisite → run onboarding** (`references/onboarding.md`). Onboarding walks the user through, and verifies, in order:
1. **Loops API key** — entered by the user (silently, on the TTY) and stored in the OS keychain via `${CLAUDE_SKILL_DIR}/scripts/loops-key.sh`. The skill **never** reads the key from disk, logs, or echoes it — it only checks presence (`loops-key.sh status`).
2. **Design system / template** — the "PromptMetrics Paper" Theme created in the Loops UI with the exact Paper token values (`references/token-map.md`), verified via `GET /themes`.
3. **From address** — sending domain + `fromName`/`fromEmail` configured in Loops Settings → Domains, verified by a dry `POST /campaigns` that does **not** 400.
4. **Logo** — `hero_logo_url` from a one-time `POST /uploads`.

**Every run — verify the four prerequisites (hard gate):**
1. Key present: `${CLAUDE_SKILL_DIR}/scripts/loops-key.sh status` == `stored` **or** `LOOPS_API_KEY` in env. Missing → onboarding step 1.
2. Loops skills bundled with this plugin (`loops-api`, `loops-lmx`, `loops-cli`, `loops-email-sending-best-practices`). These ship inside the plugin — no separate install step. Missing → the plugin install is broken; reinstall with `/plugin install promptmetrics-newsletter@promptmetrics` then `/reload-plugins`. (Maintainers sync them from upstream via `scripts/sync-loops-skills.sh`; users never need to.)
3. "PromptMetrics Paper" Theme exists (`GET /themes`). Missing → onboarding step 2.
4. `hero_logo_url` known. Missing → onboarding step 4.

No key, no Theme, no logo → no run. Onboarding is idempotent — re-run only what's missing.

### Step 1 — Collect the brief (skill)
Input modes, in priority order:
- *Notion DB* (Phase 1b) — read the brief from the Notion brief database.
- *Freeform paste* — user pastes a brief or partial brief.
- *Interview* (Phase 1a default when no brief) — interview the author using `references/brief-schema.md`.

Whatever the source, check the brief against the required-fields contract and **gap-collect**: ask only about what's missing. Full brief → zero questions. Partial → targeted questions. Empty → full interview (walk the 6 required fields, then offer optional fields). Output: a complete brief object with all required fields populated.

If optional fields are absent, draft them: `subject` / `preview_text` / `headline` / `emphasis_word` / `lede` from `goal` + `key_points[0]`; `read_time` from body length; `cta_headline` from `goal`; `cta_supporting` from `key_points[0].description`. These are approved at Gate 1. Split `headline` at `emphasis_word` into `headline_before_em` / `emphasis_word` / `headline_after_em` (exactly one emphasis word).

### Step 2 — Create draft campaign (delegate → Loops API skill)
`POST /campaigns { name, mailingListId? }` (see `loops-endpoints.md`).
Capture `campaignId`, `emailMessageId`, `emailMessageContentRevisionId`.
A **400** → sending domain / `fromName` / `fromEmail` unconfigured in Loops → stop; point to README one-time setup step 1.

### Step 3 — Assemble LMX (skill — the core opinionated layer)
This is what this skill owns. Read `references/lmx-master-template.md` + `references/token-map.md`.

1. Build the variable map from the brief (see the template's "Variable slots" table).
2. Expand `key_points[]`: for each element, emit the §8 card `<Section>` block with `{kp_number (zero-padded), kp_title, kp_description, kp_link_url?, kp_link_label?}`. **Default 3 cards, max 5.** Fewer than 3 → ask the author whether to pad or ship fewer (don't silently pad). More than 5 → truncate to first 5 and warn. Include the `<Text><Link>` line **only if** `link_url` is non-empty.
3. Expand `body_blocks[]`: validate each fragment (PascalCase tag, properly closed) — reject and ask the author to fix if invalid — then concatenate in array order inside the §9 `<Section>`.
4. Inject `<Style themeId="promptmetrics-paper" backgroundColor="#f4efe7" bodyPadding="24"/>` as the **first line**.
5. Strip optional blocks: §7 (hero) if `hero_image_url` empty; §10 (callout) if `prompt_quote` empty; the attribution `<Text>` if `prompt_attribution` empty.
6. Emit the italic-coral emphasis as `<H1><Text>…</Text><Em><Text color="#a1482a">{{emphasis_word}}</Text></Em><Text>…</Text></H1>` (verify in preview; fallback coral `<Text>` without italic).
7. Emit the 3px coral top-bar as a coral `<Divider thickness="3">` first child inside card `<Section>`s (card `padding="0"`; inner `<Section>` re-pads — 20 for key-point cards, 16 for hero, 24 for CTA — see template).
8. **100KB cap** — measure the final string. Over → trim body to 8 paragraphs + append `<Paragraph>Read the full issue at <Link href="{{website_url}}">{{website_url}}</Link>.</Paragraph>` → reduce cards to 3 + trim descriptions → if still over, **fail** with "Issue content exceeds 100KB even after trimming. Reduce body length or move content to a web link." Do not call the API.

### Step 4 — Set email content (delegate → Loops API skill)
`POST /email-messages/{emailMessageId}` with `expectedRevisionId, subject, previewText, fromName, fromEmail, replyToEmail, emailFormat:"styled", languageCode:"en", lmx` (the assembled string), `contactPropertiesFallbacks:{firstName:"there"}`. **`lmx` field only — no HTML.** (See `loops-endpoints.md` for 409/400 handling.)

### Step 5 — Gate 1: Preview (delegate + skill STOP)
`POST /email-messages/{id}/preview { emails:[author_email], contactProperties:{firstName:author_first_name} }`. Then **STOP**.

> **GATE 1 — STOP.** "Preview sent to {author_email}. Open it in **Apple Mail (light + dark)** and **Gmail (light + dark)**. Check: Fraunces loads on Apple / Georgia fallback on Gmail; 18px cards (square in Outlook Classic is expected); italic-coral emphasis word renders coral; coral top-bar visible; CTA button ≥44px; no Gmail clipping. Subject + preview text are approved here. Reply **approved** to continue, or **revise** with changes."
>
> Do NOT proceed until the user explicitly says "approved" / "looks good" / "send it to the list". On "revise", loop back to Step 3 with the requested changes (re-assemble → re-POST email-message with the latest `expectedRevisionId` → re-preview).

### Step 6 — Pre-send checks (delegate + skill)
After Gate 1 approval, run three checks in sequence (see `references/guardian-checklist.md`):
1. **Loops Guardian** (delegate): `GET /email-messages/{id}/guardian` — structural link/variable/fallback checks.
2. **Spam scan** (skill): lowercase subject + preview + stripped body text; match `references/spam-terms.md` + the brief's `tone.must_avoid[]`. Output flagged terms with category + context + location. Advisory.
3. **Broken-link check** (skill): extract `href`/`src` URLs from the LMX; dedupe; HEAD each (GET fallback on 405); 10s timeout; max ~3 concurrent. Flag 4xx/5xx/timeout. Advisory (harder than spam).

Collect all three. **Do not auto-proceed past failures** — present them; the author fixes (→ re-run Step 6) or explicitly acknowledges before Gate 2.

### Step 7 — List confirm (delegate → Loops API skill)
`GET /lists` → `[{ id, name, description, isPublic }]`. Present the lists. **No contact count via API** — show `name` only and tell the user to verify the count in the Loops UI.

### Step 8 — Gate 2: Confirm send (skill STOP — the irreversible step)
Resolve the current user (see `references/senders.md`): `NEWSLETTER_SENDER` env → git `user.email` → session identity. Check against the `senders:` allowlist (env `NEWSLETTER_SENDERS` overrides the file). Then **STOP**.

> **GATE 2 — STOP.** "Ready to send **'{subject}'** to list **'{list_name}'**. Verify the contact count in the Loops UI (the API doesn't return it).
> Pre-send checks:
>   Loops Guardian:  {PASS | FAIL: …}
>   Spam scan:       {PASS | N warnings: …}
>   Broken links:    {PASS | N broken: …}
> You are {authorized | NOT authorized} to send. Reply **send** to fire, or **cancel**."
>
> If not authorized: "You are NOT authorized to send. Ask {a sender} to confirm." Refuse Step 9 even on "send".
> **`scheduling` is STILL UNSET.** Do not set it yet.

### Step 9 — Send (delegate, ONLY after explicit "send" at Gate 2)
`POST /campaigns/{campaignId} { scheduling:{method:"now"} }` (see `loops-endpoints.md`). This is the **only** place `scheduling` is set. Confirm the campaign moves Draft → Sent. Log who sent (email + timestamp).

## Delegation summary

| Step | Who | Why |
|---|---|---|
| 0 Prerequisites | Skill | Orchestration (env + Theme check) |
| 1 Collect brief | Skill | Opinionated gap-collection |
| 2 Create campaign | Loops API skill | Standard REST |
| 3 Assemble LMX | **Skill** | Core brand→LMX translation |
| 4 Set email content | Loops API skill | Standard REST (`lmx` is the skill's output) |
| 5 Preview | Loops API skill | Standard REST |
| Gate 1 | Skill | Human-confirmation stop |
| 6a Guardian | Loops API skill | Standard REST |
| 6b Spam scan | **Skill** | Gap-filler Loops doesn't provide |
| 6c Link check | **Skill** | Gap-filler Loops doesn't provide |
| 7 List mailing lists | Loops API skill | Standard REST |
| Gate 2 | Skill | Human-confirmation stop + allowlist |
| 9 Send | Loops API skill | Standard REST (only after Gate 2) |

## Out of scope (Phase 1a)
- Notion brief-DB read (Phase 1b).
- Segment targeting / `audienceSegmentId` (Phase 1b, if an "engaged" segment exists).
- Cowork wrapper (Phase 2).
- Transactional email or per-recipient payloads — this skill sends **campaigns** (one-to-many). `{contact.firstName}` is the only personalization channel; `contactPropertiesFallbacks:{firstName:"there"}` is always set in Step 4 to avoid no-fallback-no-send failures.