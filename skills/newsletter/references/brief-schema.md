# Brief Schema — Required-Fields Contract

> **This is a mirror.** The canonical schema lives in **PromptMetrics OS**. OS is the source of truth; sync on change. Do not fork the definition — copy with a pointer back.

The newsletter skill collects a brief from one of three sources (Notion DB in Phase 1b, freeform paste, or interview) and checks it against this contract. **Gap-collection:** ask only about what's missing. Full brief → zero questions. Partial → targeted questions. Empty → full interview.

## Required fields (6)

| Field | Type | Constraint | Why required |
|---|---|---|---|
| `target_list` | string | A Loops mailing list name or ID | Determines where the campaign sends (Gate 2) |
| `goal` | string | 1–2 sentences | Frames the issue; drives subject + CTA coherence |
| `key_points` | array | 3–5 items, each `{title, description, link_url?, link_label?}` | The card stack (template §8); 3 default, 5 max (LMX has no loop) |
| `cta` | object | `{label, url}` — one CTA + one link | The primary action (template §11); no CTA = no measurable outcome |
| `tone` | object | `{voice, must_avoid[]}` e.g. `{voice:"editorial", must_avoid:["jargon","hype"]}` | Guards brand voice; `must_avoid` is cross-referenced by the spam scan |
| `issue_metadata` | object | `{issue_number, author, date}` | Populates masthead, byline, sign-off |

## Optional fields

| Field | Type | Notes |
|---|---|---|
| `subject` | string | If absent, skill drafts from `goal` + `key_points[0]`; approved at Gate 1 |
| `preview_text` | string | If absent, skill drafts; 40–90 chars, sentence case, no emoji |
| `headline` | string | If absent, skill drafts from `goal`; split around `emphasis_word` |
| `emphasis_word` | string | The single italic-coral word in the H1 |
| `lede` | string | If absent, skill drafts from `goal` |
| `read_time` | number | If absent, skill estimates from body length |
| `hero_image_url` | string | If absent, template §7 omitted |
| `hero_image_alt` | string | **Required if `hero_image_url` is present** — gap-collect asks for it |
| `hero_logo_url` | string | Masthead logo URL (one-time `POST /v1/uploads` result). If absent → Step 0 stops and points to README one-time setup step 3 |
| `cta_headline` | string | If absent, skill drafts from `goal` |
| `cta_supporting` | string | If absent, skill drafts from `key_points[0].description` |
| `body_blocks` | array | LMX fragment strings (`<Paragraph>`/`<H2>`/`<UnorderedList>`/`<Quote>`); the editorial core |
| `prompt_quote` | string | The italic callout (template §10); if absent, §10 omitted |
| `prompt_attribution` | string | If absent, omitted |
| `kicker` | string | Mono uppercase label above headline |
| `masthead_label` | string | Default `"FIELD NOTES"` |
| `from_name` | string | Default from Loops/campaign config |
| `from_email` | string | Default from Loops/campaign config |
| `reply_to_email` | string | Default = `from_email` |
| `company` | string | Sign-off line |
| `website_url` | string | Used in sign-off / "read full issue" link |

## Gap-collection behavior

1. Normalize the input (Notion row / pasted text / interview answers) into the field set above.
2. For each **missing required field**, ask one targeted question.
3. Do **not** ask about optional fields unless structurally needed (e.g. `hero_image_url` present but `hero_image_alt` missing → ask for alt text).
4. In interview mode (empty input), walk through all 6 required fields in order, then offer to capture optional fields.
5. Output a complete brief object with all required fields populated before proceeding to `POST /v1/campaigns`.

## Example brief object (synthetic)

```json
{
  "target_list": "field-notes-subscribers",
  "goal": "Share three patterns we learned shipping prompt evaluations this month.",
  "key_points": [
    { "title": "Eval drift is a people problem", "description": "Rubrics rot when reviewers change. Re-calibrate monthly." },
    { "title": "Small models, big judges", "description": "A 7B judge with a rubric beats a 70B judge without one." },
    { "title": "Log the disagreement", "description": "Where judges split is where the prompt is ambiguous." }
  ],
  "cta": { "label": "Read the full breakdown", "url": "https://promptmetrics.com/blog/eval-drift" },
  "tone": { "voice": "editorial", "must_avoid": ["jargon", "hype", "act now"] },
  "issue_metadata": { "issue_number": "12", "author": "Izzy", "date": "2026-07-15" },
  "subject": "Why your eval rubric is already stale",
  "preview_text": "Three patterns from a month of shipping prompt evaluations.",
  "headline": "Your eval rubric is already stale",
  "emphasis_word": "stale",
  "lede": "We shipped 40 prompt evaluations this month. Three patterns showed up in almost all of them.",
  "read_time": 6,
  "company": "PromptMetrics",
  "website_url": "https://promptmetrics.com"
}
```