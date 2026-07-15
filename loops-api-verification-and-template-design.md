# PromptMetrics Newsletter Skill — Loops API Verification + Email Template Design

*Companion to `newsletter-skill-plan.md`. Researched against the live Loops.so docs (July 2026) via a 3-agent ultracode workflow: API-surface verification, LMX/email-constraint research, and template-design synthesis.*

*Product decisions locked with the user: **mixed-issue** shape, **one master template** with conditionals, **Notion DB** as the brief backbone (Phase 1b).*

---

## Context

Two questions: (1) can the **current** Loops.so API support the skill in `newsletter-skill-plan.md`, and (2) how do we create the email newsletter template in Loops.so to match the PromptMetrics Paper design system (`pm-website/designs/promptmetrics-design-system`), mobile-first.

**Bottom line: the API supports the skill — with gaps.** One assumption in the plan is wrong and changes the build.

---

## Verdict: Loops API = **supported-with-gaps**

Every step in the skill plan maps to a real, live endpoint. The single material correction:

> **The skill must generate LMX, not HTML.** `POST /email-messages/{id}` accepts only the `lmx` field (Loops Markup eXpressions — a closed, PascalCase, case-sensitive XML component language: `Section`, `Columns`, `Paragraph`, `Button`, `Image`, `H1–H3`, `Style`, `Quote`, `Divider`…). Unknown tags are rejected; there is **no raw-HTML escape hatch**. The plan's "build a mobile-friendly HTML body" is not how Loops works — content is stored as LMX and rendered to client-safe HTML by Loops' engine. Themes carry the brand styling; the email body is semantic LMX.

### Capability map (skill-plan step → live endpoint)

| Skill-plan step | Verdict | Endpoint(s) |
|---|---|---|
| 1. Create draft campaign | ✅ supported | `POST /campaigns` → returns `id`, `emailMessageId`, `emailMessageContentRevisionId` |
| 2. Set email body | ⚠️ partial | `POST /email-messages/{emailMessageId}` — **`lmx` field only, not HTML**; `expectedRevisionId` for optimistic concurrency; ≤100KB; 409 if MJML/legacy |
| 3. Build brand-matched mobile newsletter | ⚠️ partial | LMX structural components + embedded `<Style/>`; brand via **Themes** + reusable **Components** (read-only via API — pre-build in UI) + `POST /uploads` for images |
| 4. Preview / test send to author | ✅ supported | `POST /email-messages/{id}/preview` — `{ emails:[…], contactProperties? }`; 100/team/24h |
| 5. Human gate: approve preview | ✅ | Claude Code interaction layer (no endpoint) |
| 6. List mailing lists | ✅ supported | `GET /lists` → `id, name, description, isPublic` |
| 6b. Show **contact count** per list | ❌ **not supported** | `GET /lists` returns no count; `GET /audience-segments/{id}` schema has no `contactCount` despite docs hinting |
| 7. Pre-send guardian (spam / broken links) | ⚠️ partial | `GET /email-messages/{id}/guardian` covers **structural** link/variable/fallback checks only — **NOT** spam-trigger words or live HTTP broken-link verification |
| 8. Send to chosen list (never auto-fire) | ✅ supported | `POST /campaigns/{id}` with `scheduling.method="now"`; keep `scheduling` unset through the gates, set only after final confirm |
| Contacts create/upsert/find | ⚠️ partial | No upsert — `GET /contacts/find` then `POST /contacts/create` or `PUT /contacts/update` |
| Segment targeting | ✅ supported | `audienceSegmentId` / inline `audienceFilter`; segments read-only via API |

### The three gaps the skill must bridge itself
1. **No contact count** at the list-confirm gate → show list **name** only and ask the user to verify count in the Loops UI (or omit).
2. **Guardian ≠ spam + broken-link check** → skill layers its own (a) spam-trigger-word scan and (b) live HTTP link-check on top of `GET /guardian`.
3. **No HTML** → skill is an **LMX generator** that translates the brand design system into LMX components + a `<Style themeId/>`.

### Loops ships an official agent surface — build a THIN layer on top
Loops publishes official **"Loops Skills"** for Claude Code/Codex/Cursor (no MCP): an **API** skill, a **CLI** skill, an **LMX** skill, and an **Email best-practices** skill (`curl -fsSL https://install.loops.so/skills | sh`). Auth = Bearer API key, base `https://app.loops.so/api`, 10 req/s, OpenAPI at `app.loops.so/openapi.yaml`.

**Recommendation:** install the Loops API + LMX + CLI skills into the project and have the PromptMetrics skill add **only** what they lack: newsletter orchestration, brand→LMX translation against the pre-built Theme, the two human gates, the never-auto-fire discipline, and the spam/link gap-fillers. Do **not** hand-roll raw REST.

---

## Corrected skill flow (mapped to real endpoints)

1. **Brief in** (interview / freeform / Notion DB in Phase 1b) → gap-collect against the required-fields contract.
2. `POST /campaigns { name, mailingListId? }` → capture `campaignId`, `emailMessageId`, `emailMessageContentRevisionId`.
3. **Assemble LMX** from the variable slots (master template, below) — one `<Style themeId="promptmetrics-paper"/>` + ordered section blocks; **no footer** (Loops auto-appends campaign footer).
4. `POST /email-messages/{id} { expectedRevisionId, subject, previewText, fromName, fromEmail, replyToEmail, emailFormat:"styled", languageCode:"en", lmx, contactPropertiesFallbacks:{firstName:"there"} }`.
5. **Gate 1 — preview:** `POST /email-messages/{id}/preview { emails:[author], contactProperties:{firstName:"Izzy"} }`; author approves in Claude Code.
6. **Pre-send checks:** `GET /email-messages/{id}/guardian` (structural) **then** skill's own spam-word scan + live HTTP link-check.
7. **List confirm:** `GET /lists` → show names (no count — ask user to verify in UI). **Gate 2** — explicit "send".
8. **Send (never auto-fire):** `POST /campaigns/{id} { scheduling:{method:"now"} }` only after Gate 2.

---

## Newsletter template design (the brainstorm output)

**One master template**, mixed-issue shape, authored in **LMX**, driven by skill-generated variables. Campaign (one-to-many) — not transactional — so `{contact.firstName}` is the *only* personalization channel; there is no per-recipient payload.

### Section structure (top to bottom)
1. **Preheader** — `preview_text` (40–90 chars, sentence case, no emoji) → doubles as Loops `previewText`.
2. **Outer canvas** — `<Style/>` `backgroundColor="#f4efe7"` (Paper); 600px centered column (Loops default), `body*Padding=24`.
3. **Masthead** — `<Columns widths="28,72" stackOnMobile="true">`: pinwheel mark (dark-mode-safe variant) + `FIELD NOTES · ISSUE {issue_number}` mono kicker; 1px coral `<Divider/>`.
4. **Kicker + Headline** — mono uppercase kicker w/ leading coral rule, then `<H1>` Fraunces 500 with **exactly one** `<Em>` italic-coral emphasis word (`emphasis_word`).
5. **Lede** — `<Paragraph>` 18px Inter, ink-2, frames the issue.
6. **Byline** — mono meta `{author_name} · {issue_date} · {read_time} min`, muted.
7. **Hero image (optional)** — full-width `<Image>` in a paper-2 card, 18px radius, 3px coral top-bar.
8. **Key-points card stack** — N (default 3, max 5) Paper cards: mono `01/02/03`, `<H3>` serif title, ink-2 description, optional coral "read more" link. **Emitted as repeated `<Section>` blocks** (LMX has no loop).
9. **Editorial body** — concatenated `Paragraph`/`H2`/`UnorderedList`/`Quote` LMX blocks (the flexible core).
10. **Italic "prompt" callout** — `<Quote>` 3px coral left border, paper-2 fill, Fraunces italic — the signature `.pm-prompt` voice.
11. **Primary CTA card** — paper-2, 18px radius, 3px coral top-bar; `<H3>` + supporting line + coral pill `<Button>` (`#d97757` fill, `#2a160e` text, radius 999).
12. **Sign-off** — small mono `— {author_name}, {company}`. **Footer + unsubscribe auto-appended by Loops — do not author.**

### Token → email mapping (LMX-native, all hex inlined, no `var()`)
- Paper `#f4efe7` → `<Style/> backgroundColor` + page Sections
- Card `#efe8db` → `blockColor` on card Sections
- Ink `#1c1c1c` / ink-2 `#43403a` / muted `#6f665a` → `textBaseColor` / per-`Paragraph color` / mono meta
- Coral `#d97757` → **non-text only**: card top-bars, `<Divider>`, `buttonBackgroundColor`
- Coral-dark `#a1482a` → `textLinkColor`, links, kicker (the AA-safe coral for text)
- Coral-ink `#2a160e` → `buttonTextColor`
- Line `#ddd3c4` / line-2 `#cabfac` → `<Divider>` / borders
- **18px radius** → `blockBorderRadius="18"`, `buttonBorderRadius="999"` (Loops emits VML RoundRect fallback for Outlook Classic → degrades to square gracefully)
- **3px coral top-bar** → fake with a 3px coral `<Divider>` as first child inside the card `<Section>` (card top padding 0, inner Section re-pads) — LMX has no `::before`
- **Soft shadow** → ❌ drop it. No `box-shadow` in LMX; invisible in Gmail/Outlook/Yahoo anyway. Fake depth with 1px `#cabfac` border + slightly darker wrapper `blockColor`.

### Typography
Fonts are a **Theme** concern (Loops emits the Google Fonts `<link>` + fallback chain) — set in the pre-built Theme, not per-email:
- Headings `Fraunces, ui-serif, Georgia, serif` · Body `Inter, ui-sans-serif, Arial, sans-serif` · Mono labels `JetBrains Mono, ui-monospace, Consolas, monospace`
- **Web fonts render only in Apple Mail/Samsung/Comcast** — Gmail/Outlook/Yahoo fall back to Georgia/Arial. Mitigation: short headlines + italic-coral emphasis + coral top-bar carry brand identity even in fallback.
- Heading scale (px, **no `clamp()`**): H1 32 / H2 24 / H3 20 / body 16 / lede 18 / meta+mono 13 / kicker 12.
- **Italic-coral emphasis:** `<H1><Text>…</Text><Em><Text color="#a1482a">word</Text></Em><Text>…</Text></H1>` — must verify in a preview send that LMX honors `color` on `<Text>` inside `<Em>`; fallback is coral `<Text>` without italic.

### Color + dark mode
LMX/editor supports **no custom CSS**, so `@media (prefers-color-scheme)` is **not available** (only via MJML, which we're not using). Strategy = **survive auto-inversion**, not control it:
- Six-digit hex only (never shorthand) — inverts more predictably.
- Warm-not-pure (`#1c1c1c` not `#000`, `#f4efe7` not `#fff`) → warm dark/light pair under inversion.
- Coral `#d97757` is mid-luminance → survives on both light and dark-inverted backgrounds; coral-dark `#a1482a` stays legible for links on dark.
- Button: coral-ink `#2a160e` text on coral (not white-on-coral — white loses contrast under inversion).
- Logo: ship a **mid-tone/reverse variant inside a fixed-color chip** so it never disappears; the four single-color silhouettes in `assets/` today are risky on inversion.
- Set `<meta name="color-scheme" content="light dark">` at the Theme/document level in the Loops UI (not API-settable).
- Every text color must clear AA against **both** `#f4efe7` and a dark inverse (~`#2a2620`).

### Mobile-first
- Single column by default; `<Columns stackOnMobile="true">` only for the masthead.
- Rely on Loops' 600px centered responsive column (don't hand-roll `max-width`); `body*Padding=24`.
- Fluid images (`width="100%"`, no fixed height); CTA button ≥44px tall (13px vertical padding to clear); clickable whole-card `<Section href>` for large tap targets.
- LMX has no `@media` → use conservative fixed vertical spacers (32px safe at both widths).
- Keep total LMX **<100KB** (API cap) and **<102KB** (Gmail clip) → cap body ~6–8 paragraphs, push long prose to a "read full issue" link, lean on the Theme for shared styles.

### LMX variable slots the skill populates per send
Message fields: `subject`, `preview_text`, `from_name`, `from_email`.
Body vars (inline `{contact.*}` only for greeting): `issue_number`, `issue_date`, `masthead_label`, `kicker`, `headline`, `emphasis_word`, `lede`, `author_name`, `read_time`, `hero_image_url`?, `hero_image_alt`?, `key_points[]` (array of `{number,title,description,link_url?,link_label?}` — **emitted as N repeated card blocks, not an LMX loop**), `body_blocks[]` (array of LMX block strings the skill concatenates), `prompt_quote`, `prompt_attribution`?, `cta_headline`, `cta_supporting`, `cta_label`, `cta_url`, `company`, `website_url`, `recipient_first_name?` (`{contact.firstName}`, fallback configured in editor).
**Not authored:** `{system.unsubscribe_link}` + footer (auto-appended).

### Build path in Loops
**One-time, manual in UI** (Themes/Components are read-only via API as of July 2026):
1. Create Theme **"PromptMetrics Paper"** with the token values + font stacks + heading sizes + `buttonBorderRadius=999` + `body*Padding=24`.
2. (Optional) Create reusable `<Component>` blocks for the Paper card + prompt callout.
3. Upload the logo mark via `POST /uploads` → Loops-hosted static URL.
Then **per-issue** the skill runs the flow above, assembling LMX against `themeId="promptmetrics-paper"`.

### Accessibility
`languageCode="en"`; one `<H1>`, `<H2>` per section, `<H3>` per card; alt text on every image; preheader 40–90 chars; AA contrast verified (coral `#d97757` is **3.0:1 — text-FAIL**, used only as non-text accent); CTA ≥44px; message survives images-off (all text core).

### Key rendering risks
- Fraunces/Inter web fonts lost on Gmail/Outlook/Yahoo → Georgia/Arial fallback (mitigate with short headlines + coral emphasis/top-bar).
- Outlook Classic drops border-radius → square cards (Loops VML fallback handles gracefully).
- No box-shadow in LMX / invisible in major clients → flatter than web brand; accept it.
- Dark-mode inversion uncontrolled in LMX → cream inverts; warm-not-pure hex + coral-ink button + mid-tone logo mitigate.
- Coral `#d97757` fails AA as text → non-text accent only.
- Gmail clip ~102KB / API cap 100KB → cap body, lean on Theme.
- LMX has no loops/conditionals → skill emits concrete repeated card/body blocks (enforce 3-card default, 5 max).
- Italic-coral emphasis is fragile (`<Em><Text color>`) → verify in preview; fallback to coral `<Text>` without italic.

---

## Open decisions to lock (Phase 1a gates in bold)

1. **Sending domain + `fromName`/`fromEmail` configured in Loops?** (`POST /campaigns` 400s if not.) e.g. "PromptMetrics Field Notes" / "fieldnotes".
2. **Which mailing list(s)** + is there an "engaged" segment? (`GET /lists` returns names only — confirm the list ID in the UI.)
3. **"PromptMetrics Paper" Theme:** pre-create in UI now, or include step-by-step UI instructions in the build?
4. **Logo variant for dark-mode safety:** reverse mark in a fixed-color chip (recommended) vs. a new mid-tone pinwheel?
5. `{contact.firstName}` greeting + "there" fallback, or unpersonalized body (avoids the no-fallback-no-send failure)?
6. Key-point cards: default 3, max 5; whole-card clickable vs. "read more" link only?
7. Subject + preview approved at the preview gate specifically, or as part of the brief?
8. Spam-word scan: built-in governance-friendly list vs. a house suppressed-terms list?
9. Hero art direction (cream-backed, 1.91:1, pinwheel motif) vs. author-supplied per issue?

Plus the plan's own open items: the ~6 required brief fields, and the who-can-approve/send policy.

---

## Verification (how to test end-to-end)

1. **Theme exists:** `GET /themes` lists "PromptMetrics Paper"; `GET /themes/{id}` returns the token map.
2. **Dry create + content:** `POST /campaigns` (Draft) → `POST /email-messages/{id}` with a minimal LMX (`<Style themeId/><Paragraph>test</Paragraph>`) → 200, not 409.
3. **LMX brand proof:** assemble a full mixed-issue LMX, set it, then `POST /email-messages/{id}/preview` to the author — **open in Apple Mail (light + dark) and Gmail (light + dark)** to confirm: Fraunces loads on Apple, Georgia fallback on Gmail, 18px cards (square in Outlook Classic), italic-coral emphasis word renders coral, coral top-bar visible, button ≥44px, no clipping.
4. **Guardian + gap-fillers:** `GET /email-messages/{id}/guardian` returns clean; skill's spam scan flags a planted "free"/"act now" term; skill's HTTP check flags a planted 404 link.
5. **List confirm:** `GET /lists` renders names; gate shows name + "verify count in Loops UI".
6. **Send discipline:** confirm `scheduling` is unset through both gates and only set to `method:"now"` after Gate 2 — campaign moves Draft → Sent.
7. **Regression guard:** keep the assembled LMX under 100KB for a max-length issue (5 cards + 8 paragraphs).

---

## Next steps (once approved)

1. Scaffold `promptmetrics/newsletter-skill` repo per the plan's layout; install Loops skills (`curl -fsSL https://install.loops.so/skills | sh`).
2. Draft `SKILL.md` for Phase 1a as an **LMX-generator** workflow (interview → brief → LMX → preview → send) on top of the shipped Loops API/LMX skills — **not** an HTML workflow.
3. Lock decisions 1–9 above + the 6 required brief fields + who-can-send policy.
4. (Manual, one-time) create the "PromptMetrics Paper" Theme + Components in the Loops UI; upload the dark-mode-safe logo.
5. Build the master-template LMX assembler + the spam/link gap-fillers; run the verification sequence.

---

## Sources

- https://loops.so/docs · https://loops.so/docs/api-reference/intro · https://loops.so/docs/skills
- https://loops.so/docs/api-reference/create-campaign · /update-campaign · /update-email-message · /preview-email-message · /run-guardian-checks · /list-mailing-lists · /get-audience-segment · /send-transactional-email · /create-transactional-email · /publish-transactional-email · /create-theme · /changelog
- https://loops.so/docs/creating-emails/lmx · /personalizing-emails · /uploading-custom-email · /editor/arrays · /styles · /font-support · /using-templates · /guardian
- https://loops.so/docs/guides/email-dark-mode · /html-emails · https://loops.so/docs/transactional · https://loops.so/agents/api · https://loops.so/docs/llms.txt
- https://www.caniemail.com/features/css-border-radius/ · /css-box-shadow/ · /css-variables/
- https://emailens.dev/blog/outlook-css-guide · https://emailens.dev/email-css/clients/outlook-windows-legacy
- https://www.emailonacid.com/blog/article/email-development/how-to-code-emails-for-outlook/