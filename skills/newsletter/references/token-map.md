# Token Map — PromptMetrics Paper → LMX

Authoritative reference for the LMX assembler. Every Paper design token maps to an **inlined six-digit hex** or LMX component attribute. **No `var()`, no shorthand hex, no `box-shadow`.** Grounded in `pm-website/designs/promptmetrics-design-system/project/tokens/{colors,typography,layout,components,base}.css`.

## Colors

| Token (CSS) | Hex | LMX target |
|---|---|---|
| `--pm-paper` | `#f4efe7` | `<Style backgroundColor>` + page `<Section blockColor>` |
| `--pm-paper-2` | `#efe8db` | card `<Section blockColor>` |
| `--pm-ink` | `#1c1c1c` | `textBaseColor` (Theme) |
| `--pm-ink-2` | `#43403a` | `<Paragraph color>` for lede / descriptions |
| `--pm-muted` | `#6f665a` | mono meta `<Text color>` |
| `--pm-coral` | `#d97757` | **non-text only** — `<Divider>`, card top-bar, `buttonBackgroundColor` |
| `--pm-coral-dark` | `#a1482a` | `textLinkColor`, links, kicker (AA-safe coral for text) |
| `--pm-coral-ink` | `#2a160e` | `buttonTextColor` |
| `--pm-line` | `#ddd3c4` | `<Divider>` default |
| `--pm-line-2` | `#cabfac` | 1px card border (fakes shadow) |

**Coral `#d97757` fails AA as text (3.0:1). Use it only for non-text accent** (dividers, top-bars, button fill). Any coral that is *text* (links, kicker, emphasis) must be `#a1482a`.

## Radii

| Token | Value | LMX target |
|---|---|---|
| `--pm-radius-xl` | `18px` | `blockBorderRadius="18"` on cards |
| pill | `999px` | `buttonBorderRadius="999"` on the CTA |

Loops emits a VML `RoundRect` fallback for Outlook Classic — border-radius degrades to square gracefully. Accept it.

## The 3px coral top-bar (LMX has no `::before`)

Fake it: make a 3px coral `<Divider>` the **first child** inside the card `<Section>` (card top padding `0`, inner `<Section>` re-pads to `20`):

```
<Section blockColor="#efe8db" blockBorderRadius="18" blockBorder="1px #cabfac" padding="0">
  <Divider color="#d97757" thickness="3"/>
  <Section padding="20"> …card content… </Section>
</Section>
```

## Depth without shadow

**Drop `box-shadow` entirely.** LMX has no `box-shadow`, and it's invisible in Gmail/Outlook/Yahoo anyway. Fake depth with a `1px #cabfac` border (`blockBorder`) on cards + the slightly-darker `#efe8db` card `blockColor` against the `#f4efe7` page.

## Typography (Theme-level, not per-email)

Fonts are set once in the "PromptMetrics Paper" **Theme** (Loops emits the Google Fonts `<link>` + fallback chain). The assembler does not set fonts per-block.

| Role | Stack | Fallback reality |
|---|---|---|
| Headings | `Fraunces, ui-serif, Georgia, serif` | Renders on Apple Mail/Samsung/Comcast; **Gmail/Outlook/Yahoo → Georgia** |
| Body | `Inter, ui-sans-serif, Arial, sans-serif` | → Arial on non-Apple clients |
| Mono labels | `JetBrains Mono, ui-monospace, Consolas, monospace` | → Consolas/monospace |

**Mitigation when web fonts fall back:** short headlines + the one italic-coral emphasis word + the coral top-bar carry brand identity even in Georgia/Arial.

Heading scale (px, **no `clamp()`** — email has no fluid type): H1 `32` / H2 `24` / H3 `20` / body `16` / lede `18` / meta+mono `13` / kicker `12`.

## Italic-coral emphasis (fragile — verify in preview)

```
<H1><Text>…</Text><Em><Text color="#a1482a">word</Text></Em><Text>…</Text></H1>
```

LMX honoring `color` on `<Text>` inside `<Em>` must be **verified in a preview send** (Apple Mail + Gmail). If it doesn't render coral, fall back to coral `<Text color="#a1482a">word</Text>` without italic.

## Dark mode — survive auto-inversion, don't control it

LMX/editor supports **no custom CSS**, so `@media (prefers-color-scheme)` is not available. Strategy = survive inversion:
- Six-digit hex only (never shorthand) — inverts more predictably.
- Warm-not-pure (`#1c1c1c` not `#000`, `#f4efe7` not `#fff`) → warm pair under inversion.
- Coral `#d97757` is mid-luminance → survives on both light and dark-inverted backgrounds; `#a1482a` stays legible for links on dark.
- Button: `#2a160e` text on coral (**not white-on-coral** — white loses contrast under inversion).
- Logo: ship a mid-tone/reverse variant inside a fixed-color chip so it never disappears.
- Set `<meta name="color-scheme" content="light dark">` at the Theme/document level in the Loops UI (not API-settable).
- Every text color must clear AA against **both** `#f4efe7` and a dark inverse (~`#2a2620`).