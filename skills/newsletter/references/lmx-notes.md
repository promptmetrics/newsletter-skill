# LMX Notes — Gotchas

Loops Markup eXpressions: a **closed, PascalCase, case-sensitive** XML component language. Unknown tags are rejected. There is **no raw-HTML escape hatch** — the `lmx` field on `POST /v1/email-messages/{id}` accepts only LMX; Loops' engine renders it to client-safe HTML.

## No loops or conditionals
LMX has no `for`/`if`. Expand arrays yourself:
- `key_points[]` → emit N concrete card `<Section>` blocks (3 default, 5 max).
- `body_blocks[]` → concatenate the LMX fragment strings in order. Valid fragment tags are whatever the installed **Loops LMX skill** lists — validate each fragment against that skill's component reference, not against this file.
- Optional sections (hero, prompt callout) → **strip the whole block** if the variable is empty; don't emit an empty block.

## No `box-shadow`
Invisible in Gmail/Outlook/Yahoo anyway. Fake depth with a `1px #cabfac` `blockBorder` + the darker `#efe8db` card `blockColor` against the `#f4efe7` page. See `token-map.md`.

## No `@media` / no custom CSS
`@media (prefers-color-scheme)` is **not available** in the LMX editor. Dark mode = **survive auto-inversion**, don't control it:
- Six-digit hex only (never shorthand) — inverts predictably.
- Warm-not-pure values (`#1c1c1c`, `#f4efe7`) → warm pair under inversion.
- Coral `#d97757` is mid-luminance → survives both light and dark-inverted backgrounds.
- Button text `#2a160e` on coral (not white — white loses contrast under inversion).
- Set `<meta name="color-scheme" content="light dark">` at the Theme/document level in the Loops UI (not API-settable).

## 3px coral top-bar (no `::before`)
Fake with a 3px coral `<Divider>` as the **first child** inside the card `<Section>` (card `padding="0"`, inner `<Section padding="20">` re-pads). See `token-map.md`.

## Italic-coral emphasis is fragile
`<H1><Text>…</Text><Em><Text color="#a1482a">word</Text></Em><Text>…</Text></H1>`
- **Verify in a preview send** (Apple Mail + Gmail, light + dark) that LMX honors `color` on `<Text>` inside `<Em>`.
- Fallback: coral `<Text color="#a1482a">word</Text>` without italic.

## Border radius
`blockBorderRadius="18"` / `buttonBorderRadius="999"`. Loops emits a VML `RoundRect` fallback for Outlook Classic → degrades to square gracefully. Accept the degradation.

## Web fonts
Render only in Apple Mail / Samsung / Comcast. Gmail / Outlook / Yahoo fall back to Georgia (serif) / Arial (sans). Mitigation: short headlines + the italic-coral emphasis word + the coral top-bar carry brand identity even in fallback. Fonts are set in the Theme, not per-block.

## Coral is non-text only
`#d97757` is **3.0:1 — AA-fail as text**. Use it only for dividers, top-bars, button fill. Any coral that is *text* (links, kicker, emphasis) must be `#a1482a`.

## Size discipline
- Total LMX **<100KB** (API cap) and **<102KB** (Gmail clip). The assembler enforces this with a trimming cascade (`lmx-master-template.md`).
- No `clamp()` — email has no fluid type. Fixed px heading scale.
- CTA button ≥44px tall (`padding="13 32"`).
- `bodyXPadding="24" bodyYPadding="24"` on `<Style/>` (ThemeStyles has X/Y padding keys, no `bodyPadding`); rely on Loops' 600px centered responsive column (don't hand-roll `max-width`).
- `<Columns stackOnMobile="true">` only for the masthead; everything else is single-column.

## No footer authored
Loops auto-appends the campaign footer + `{system.unsubscribe_link}`. Do not author a footer or unsubscribe link — doing so duplicates them.