# Token Map — PromptMetrics Sea Glass → LMX

Authoritative reference for the LMX assembler. Every design token maps to an **inlined six-digit hex** or LMX component attribute. **No `var()`, no shorthand hex, no `box-shadow`.** Grounded in `pm-website/app/styles/v3-tokens.css` (the `[data-theme="paper"]` block); the accessibility contract is `pm-website/scripts/contrast-check.mjs`.

Palette name: **"Sea Glass"** — mint surfaces, raspberry accent, teal ambient hue. Note that the raspberry lives in a CSS slot still named `--pm-coral` upstream (renaming it would break 57 site components); it is **not** an orange coral.

## Colors

| Token (CSS) | Hex | LMX target |
|---|---|---|
| `--pm-paper-3` | `#d2e1db` | `backgroundColor` (outer canvas, Theme) |
| `--pm-paper` | `#e9f1ee` | `bodyColor` (the email sheet, Theme) |
| `--pm-paper-2` | `#e0ebe7` | card `<Section blockColor>` |
| `--pm-ink` | `#161c1a` | `textBaseColor` + `heading1/2/3Color` (Theme) |
| `--pm-ink-2` | `#39443f` | lede / card-description `<Text textColor>` |
| `--pm-muted` | `#5e6f68` | meta, byline, sign-off `<Text textColor>` — **sheet only**, see below |
| `--pm-coral` (raspberry) | `#b8446a` | **non-text only** — card top-bar `<Divider>`, `buttonBodyColor` |
| `--pm-coral-dark` (raspberry) | `#8a2c4e` | `textLinkColor`, links, H1 emphasis word |
| `--pm-coral-ink` | `#ffffff` | `buttonTextColor` |
| `--pm-teal-dark` | `#276358` | kicker + card index/label `<Text textColor>` |
| `--pm-teal` | `#3f8f82` | masthead rule `<Divider color>` |
| `--pm-line` | `#cddcd6` | `dividerColor` (Theme default) + `borderColor` |

### Accent rationing (a brand rule, not a preference)

Upstream (`v3-tokens.css:38,45`): *"Raspberry is rationed to primary CTAs and links; teal carries kickers, tags, and ambient accents."*

- **Raspberry** → the CTA button, links, the H1 emphasis word, and card top-bars.
- **Teal** → the kicker and the masthead rule. The kicker is **not** raspberry.

### Contrast rules

- Raspberry `#b8446a` is **~3.4:1 on mint — non-text or ≥18px only.** Any raspberry that is *small text* (links, emphasis) must be `#8a2c4e`.
- **Muted `#5e6f68` is sheet-only.** It clears AA on the `#e9f1ee` sheet (4.63:1) but **fails on the `#e0ebe7` card (4.36:1)**. Upstream's contrast matrix only tests muted against `--pm-paper`, so this gap is one the email surfaces by putting 13px meta on cards. On a card, use **teal-dark `#276358`** (5.71:1) for labels and indices, and **ink-2 `#39443f`** (8.30:1) for prose.
- `#7a8d86` (`--pm-muted-soft`) fails AA as small text on every surface — never use it for the 13px meta lines.
- Pull quotes take ink `#161c1a` (matching the site's `.pm-quote`); their attribution line takes ink-2 `#39443f`, so the two stay distinguishable.
- **The CTA label is white `#ffffff` on `#b8446a` (5.2:1 AA).** This reverses the old palette's rule, which used dark ink on the button because the previous orange coral was too light for white. Raspberry is dark enough that white is correct — and is what `--pm-coral-ink` resolves to upstream.

## Depth without borders or shadow

LMX blocks accept **only** `blockColor`, `blockBorderRadius` and `paddingTop/Right/Bottom/Left`. There is no `blockBorder`, no `borderLeft`, no `box-shadow`. Do not try to fake a card border.

Depth comes from the **mint surface ladder** instead — three ascending steps, which is what the design system provides them for:

```
#d2e1db   outer canvas   (Theme backgroundColor)
  #e9f1ee   email sheet  (Theme bodyColor)
    #e0ebe7   card       (Section blockColor)
```

The card reads as raised against the sheet on its own, with no border. This is also more robust than a hairline: 1px borders are the first thing Outlook drops.

## Radii

| Token | Value | LMX target |
|---|---|---|
| `--pm-radius-xl` | `18px` | `blockBorderRadius="18"` on cards; `borderRadius: 18` (Theme) |
| pill | `999px` | `buttonBorderRadius: 999` (Theme) |

Loops emits a VML `RoundRect` fallback for Outlook Classic — border-radius degrades to square gracefully. Accept it.

## The 3px raspberry top-bar (LMX has no `::before`)

A `<Divider>` as the **first child** of the card `<Section>`. Because sections cannot nest (see `lmx-notes.md`), the card Section carries `paddingLeft="0" paddingRight="0"` so the divider runs edge-to-edge, and each **inner block** insets itself with `paddingLeft="20" paddingRight="20"`:

```xml
<Section blockColor="#e0ebe7" blockBorderRadius="18" paddingTop="0" paddingBottom="20" paddingLeft="0" paddingRight="0">
  <Divider color="#b8446a" borderWidth="3" />
  <Paragraph fontSize="13" paddingLeft="20" paddingRight="20"><Text textColor="#5e6f68">01</Text></Paragraph>
  <H3 paddingLeft="20" paddingRight="20">Card title</H3>
  <Paragraph fontSize="16" paddingLeft="20" paddingRight="20"><Text textColor="#39443f">Card body.</Text></Paragraph>
</Section>
```

`borderWidth` is the Divider's thickness attribute (1–16). There is no `thickness` attribute.

## Where color is allowed to live

`<Paragraph>`, `<H1>`, `<H2>`, `<H3>` and `<Quote>` do **not** accept `textColor` — the attribute exists only on the inline tags (`<Text>`, `<Em>`, `<Strong>`, `<Link>`, …). So:

- Body/meta color → `<Paragraph><Text textColor="#39443f">…</Text></Paragraph>`.
- Heading color → from the Theme (`heading1Color` …), never inline.

## Typography — one family

The design system collapsed to a **single family (Archivo)** on 2026-08-24; the earlier Fraunces/Inter split is retired. This matches LMX, which exposes only `bodyFontFamily` + `bodyFontCategory` — **one family for the whole email**. There is no heading-font or mono-font field.

| Theme key | Value |
|---|---|
| `bodyFontFamily` | `Archivo, system-ui, Arial, sans-serif` |
| `bodyFontCategory` | `sans-serif` |

Give `bodyFontFamily` a **full CSS stack**, not a bare family name — the account's previous theme stored `Inter, ui-sans-serif, Arial, sans-serif` and rendered correctly, so a stack is known-good and gives explicit fallback control instead of relying on `bodyFontCategory` alone. The stack mirrors the site's `--font-archivo-stack`.

Fallback reality: Archivo loads in Apple Mail / Samsung / Comcast. Gmail / Outlook / Yahoo fall back to the category default (system-ui / Arial). Mitigation: hierarchy is carried by **size, weight, tracking and color**, all of which survive a font fallback — plus the raspberry top-bar and the teal kicker rule.

**No monospace.** LMX has no per-block font attribute, so the micro-labels (masthead label, byline, card number, sign-off) cannot be monospaced. Style them the way the site's `.pm-kicker` / `.pm-label` do instead: 12–13px, uppercase, wide tracking, muted color.

Heading scale (px, **no `clamp()`** — email has no fluid type): H1 `32` / H2 `24` / H3 `20` / body `16` / lede `18` / meta `13` / kicker `12`.

### `themeId` form — resolved

**Resolved empirically (2026-08-31): `<Style themeId>` takes the opaque `data[].id`** (e.g. `cmrngnrqv…`). Passing the theme *name* returns `422 <Style> references unknown themeId`. No A/B test is outstanding.

## Italic-raspberry emphasis

`textColor` is documented directly on `<Em>`, so this needs no nesting trick:

```xml
<H1>Ship the <Em textColor="#8a2c4e">boring</Em> automation</H1>
```

## Dark mode — survive auto-inversion, don't control it

LMX supports **no custom CSS**, so `@media (prefers-color-scheme)` is unavailable. Strategy = survive inversion:

- Six-digit hex only (never shorthand) — inverts more predictably.
- Cool-not-pure values (`#161c1a` not `#000`, `#e9f1ee` not `#fff`) → the mint pair stays mint-adjacent under inversion.
- Raspberry `#b8446a` is mid-luminance → survives on both light and dark-inverted backgrounds; `#8a2c4e` stays legible for links.
- **CTA button: white `#ffffff` on raspberry `#b8446a`.** Because `bgColor` is explicit, most clients preserve the fill and the white label stays correct. **Verify this specific pair in the Gate 1 dark preview** — it is the one place this palette departs from the old dark-mode rule.
- Logo: ship a mid-tone/reverse variant inside a fixed-color chip so it never disappears.
- Set `<meta name="color-scheme" content="light dark">` at the Theme/document level in the Loops UI (not API-settable).
- Every text color must clear AA against **both** `#e9f1ee` and the dark-theme equivalent (`#141a17`, from the upstream `[data-theme="dark"]` block).

## POST /v1/themes body (ThemeStyles-aligned)

`POST /v1/themes` (201) creates it; `POST /v1/themes/{themeId}` updates it. Both are writable. The `styles` keys **must match the ThemeStyles field names exactly** — they are the attribute names accepted by the LMX `<Style />` tag. Every key below is a real field, verified against the live schema.

```json
{
  "name": "PromptMetrics Sea Glass",
  "styles": {
    "backgroundColor": "#d2e1db",
    "backgroundYPadding": 24,
    "bodyColor": "#e9f1ee",
    "bodyXPadding": 24,
    "bodyYPadding": 24,
    "bodyFontFamily": "Archivo, system-ui, Arial, sans-serif",
    "bodyFontCategory": "sans-serif",
    "borderColor": "#cddcd6",
    "borderWidth": 1,
    "borderRadius": 18,
    "textBaseColor": "#161c1a",
    "textBaseFontSize": 16,
    "textBaseLineHeight": 165,
    "textLinkColor": "#8a2c4e",
    "buttonBodyColor": "#b8446a",
    "buttonTextColor": "#ffffff",
    "buttonBorderRadius": 999,
    "buttonBodyXPadding": 32,
    "buttonBodyYPadding": 13,
    "dividerColor": "#cddcd6",
    "dividerBorderWidth": 1,
    "heading1Color": "#161c1a",
    "heading1FontSize": 32,
    "heading1LineHeight": 118,
    "heading2Color": "#161c1a",
    "heading2FontSize": 24,
    "heading2LineHeight": 124,
    "heading3Color": "#161c1a",
    "heading3FontSize": 20,
    "heading3LineHeight": 130
  }
}
```

Notes:

- **There is no `headingFontFamily`, `monoFontFamily`, `h1FontSize` or `bodyFontSize`.** Earlier versions of this file sent all four; none exist in `ThemeStyles`. The real names are `bodyFontFamily` (one family), `heading1FontSize`, and `textBaseFontSize`.
- `bodyXPadding` / `bodyYPadding` are the **only** body-padding keys — `bodyPadding` is not a field and will be rejected.
- `*LineHeight` is a **percentage** (100–300): `165` = 1.65.
- `heading*LetterSpacing` is deliberately **unset**. Archivo wants negative tracking (`-0.02em` on the site) but the schema does not document the unit, and one rejected key fails the whole call. Add it only after an empirical check.
- `fromEmail` and other email-message-level fields do **not** belong here; this body creates the Theme only.
