# Token Map — ProNova → LMX

Authoritative reference for the LMX assembler. Every design token maps to an **inlined six-digit hex** or LMX component attribute. **No `var()`, no shorthand hex, no `box-shadow`.** Grounded in `pronova-website/src/styles/tokens.css`, the ProNova design system's token file. That file writes hex in uppercase; this plugin writes it in lowercase, the form its API-verified templates have always sent. The colors are the same.

The Loops Theme is named **"ProNova"**. ProNova has one light theme and no dark theme.

## Colors

| Token (CSS) | Hex | LMX target |
|---|---|---|
| `--paper-2` | `#f6f7fa` | outer canvas (`backgroundColor`, Theme) **and** card `<Section blockColor>` |
| `--paper` | `#ffffff` | `bodyColor` (the email sheet, Theme); `buttonTextColor` and `<Button textColor>` |
| `--ink` | `#15181d` | `textBaseColor` + `heading1/2/3Color` (Theme); `buttonBodyColor` and `<Button bgColor>`; masthead rule `<Divider color>`; pull-quote `<Text textColor>` |
| `--text-body` | `#2a2f37` | lede, card prose and long body copy `<Text textColor>` |
| `--muted` | `#5a6170` | masthead label, byline, sign-off, kicker label, card number, quote attribution `<Text textColor>` |
| `--accent` | `#3b4bc8` | `textLinkColor` (Theme) and the kicker's ◆ `<Text textColor>` |
| `--line` | `#e6e9ef` | `dividerColor` (Theme default) + `borderColor` |
| `--tint-agents` (periwinkle) | `#d6dcf8` | card top bar `<Divider color>` — the default |
| `--tint-eng` (ice) | `#d3ecf2` | card top bar, topic `engineering` |
| `--tint-mcp` (mint) | `#cdebdd` | card top bar, topic `mcp` |
| `--tint-flow` (butter) | `#f3efc6` | card top bar, topic `workflows` |

Not used by the template: `--text-2` `#3a404b` (secondary UI text) and the on-ink tokens (`--off-white`, `--body-dark`, `--muted-dark`). The email has no ink band.

### Accent: links and the diamond, nothing else

`--accent` `#3b4bc8` colors links and the ◆ that leads the kicker. It does not color buttons, bars, rules, headings or body text. The button is ink with a white label; emphasis lines are a 1px ink rule; ordinary hairlines are `--line`.

### Tints: one per topic

A tint is a pale ground that names a topic. In the email a tint appears only as a card's top bar, so no text ever sits on one. (On the site a tint always carries ink text: 13.09:1 to 15.22:1.)

| `topic` | Token | Hex |
|---|---|---|
| `agents` (default) | `--tint-agents` | `#d6dcf8` |
| `engineering` | `--tint-eng` | `#d3ecf2` |
| `mcp` | `--tint-mcp` | `#cdebdd` |
| `workflows` | `--tint-flow` | `#f3efc6` |

The brief's optional `topic` sets the bar for every card in the issue; a key point's optional `topic` overrides it for that card (`brief-schema.md`). With neither set, every bar is periwinkle. An unrecognized value falls back to periwinkle, and the assembler tells the author.

### Contrast (computed, WCAG 2 relative luminance)

Every ratio below was computed from the hex values with the WCAG relative-luminance formula and truncated to two decimals. Body and meta text at 12–16px needs 4.5:1 on the surface it sits on.

| Text | On the sheet `#ffffff` | On a card `#f6f7fa` |
|---|---|---|
| Ink `#15181d` — base text, H1–H3, pull quote | 17.79:1 | 16.60:1 |
| Text-body `#2a2f37` — lede, card prose | 13.45:1 | 12.56:1 |
| Muted `#5a6170` — meta, byline, sign-off, kicker, card number | 6.21:1 | 5.80:1 |
| Accent `#3b4bc8` — links, kicker ◆ | 6.93:1 | 6.47:1 |
| Button label `#ffffff` on the button fill `#15181d` | 17.79:1 | 17.79:1 |

Every pairing passes on both surfaces, so no color is restricted to the sheet. Muted is safe for the 13px card number, and a card's "read more" link is safe in accent.

## Depth: a hairline border, no shadow

The vendored LMX spec documents only `blockColor`, `blockBorderRadius` and `paddingTop/Right/Bottom/Left` on blocks. Loops also accepts **`blockBorderWidth` and `blockBorderColor` on `<Section>`**, undocumented upstream: the Loops dry run of 2026-11-27 drew a 1px border only when both were set. There is no `borderLeft` and no `box-shadow`. Every card `<Section>` carries `blockBorderWidth="1" blockBorderColor="#e6e9ef"` (`--line`, the site's hairline).

```
#f6f7fa   outer canvas   (Theme backgroundColor)
  #ffffff   email sheet  (Theme bodyColor)
    #f6f7fa   card       (Section blockColor)
```

**The fill does not carry the card by itself.** `#f6f7fa` reads at only **1.07:1** against the white sheet, for the canvas and for the card alike. Four other cues carry the card:

1. **The 1px `#e6e9ef` border** — 1.21:1 against the sheet, 1.13:1 against the card fill. It gives the card its edge. Outlook may drop it; the cues below still hold there.
2. **The 6px tinted top bar.** Against the sheet above it: periwinkle 1.35:1, mint 1.27:1, ice 1.23:1, butter 1.16:1. Against the card fill below it: 1.26:1, 1.18:1, 1.14:1, 1.09:1. These are faint by luminance; the bar reads through hue. Periwinkle is the default because it separates most. Butter separates least, so check a `workflows` issue with extra care at Gate 1.
3. **The 6px radius** on the card's corners.
4. **Padding and the spacer**: 20px inside the card and a blank line between cards (`lmx-notes.md`).

No pairing here reaches 3:1, and none needs to: the card boundary is decoration, and every word inside a card passes 4.5:1 whether or not the reader sees the boundary. If a Gate 1 preview shows the cards dissolving into the sheet, do not reach for a color outside the system.

On the site, the cards that carry a 6px tinted bar are white on a `--paper-2` band and take the system's one shadow. Email has no shadow, so this template inverts the grounds: white sheet, `--paper-2` card.

## Radii

| Token | Value | LMX target |
|---|---|---|
| `--radius` | `6px` | `blockBorderRadius="6"` on cards; `borderRadius="6"` on the hero image and the button; `borderRadius: 6` and `buttonBorderRadius: 6` (Theme) |

One radius. No pills: the button takes 6, not 999.

Loops emits a VML `RoundRect` fallback for Outlook Classic — border-radius degrades to square gracefully. Accept it.

## The 6px tinted top bar (LMX has no `::before`)

A `<Divider>` as the **first child** of the card `<Section>`. Because sections cannot nest (see `lmx-notes.md`), the card Section carries `paddingLeft="0" paddingRight="0"` so the divider runs edge-to-edge, and each **inner block** insets itself with `paddingLeft="20" paddingRight="20"`:

```xml
<Section blockColor="#f6f7fa" blockBorderRadius="6" blockBorderWidth="1" blockBorderColor="#e6e9ef" paddingTop="0" paddingBottom="20" paddingLeft="0" paddingRight="0">
  <Divider color="#d6dcf8" borderWidth="6" paddingTop="0" paddingBottom="0"/>
  <Paragraph fontSize="13" paddingTop="16" paddingLeft="20" paddingRight="20"><Text textColor="#5a6170">01</Text></Paragraph>
  <H3 paddingLeft="20" paddingRight="20">Card title</H3>
  <Paragraph fontSize="16" paddingLeft="20" paddingRight="20"><Text textColor="#2a2f37">Card body.</Text></Paragraph>
</Section>
```

`borderWidth` is the Divider's thickness attribute (1–16). There is no `thickness` attribute. The 6 matches the site's `--get-bar`. Whether the bar's top corners follow the card's 6px radius depends on the client; check it at Gate 1.

## The kicker: an accent ◆ and a muted label

The site's eyebrow is 12px, uppercase, muted, led by a diamond (a small square rotated 45°). LMX has no transform, so the glyph ◆ (U+25C6) stands in for the diamond. It is the only ornament in the email.

```xml
<Paragraph fontSize="12" paddingBottom="8"><Text textColor="#3b4bc8">◆</Text><Text textColor="#5a6170"> FIELD REPORT</Text></Paragraph>
```

The assembler uppercases the label itself, since LMX has no `text-transform`. The space between the ◆ and the label sits inside the label's `<Text>`.

## Where color is allowed to live

`<Paragraph>`, `<H1>`, `<H2>`, `<H3>` and `<Quote>` do **not** accept `textColor` — the attribute exists only on the inline tags (`<Text>`, `<Em>`, `<Strong>`, `<Link>`, …). So:

- Body/meta color → `<Paragraph><Text textColor="#2a2f37">…</Text></Paragraph>`.
- Heading color → from the Theme (`heading1Color` …), never inline.

## Typography — one family

ProNova sets everything in **Sora**. Loops adds the fallback itself from `bodyFontCategory`. LMX exposes only `bodyFontFamily` + `bodyFontCategory` — **one family for the whole email** — so the two match. There is no heading-font or mono-font field.

| Theme key | Value |
|---|---|
| `bodyFontFamily` | `Sora` |
| `bodyFontCategory` | `sans-serif` |

Give `bodyFontFamily` the **bare Google Fonts family name**, never a CSS stack. Loops puts the value straight into its Google Fonts request, and a stack makes that request fail: on 2026-11-27 `fonts.googleapis.com/css?family=Sora:400,600` answered 200, while the same request with `Sora, Arial, sans-serif` and with the old theme's `Archivo, system-ui, Arial, sans-serif` answered 400, so the old theme never loaded its web font. Loops builds the fallback chain from `bodyFontCategory` (its docs, "Font support": `SelectedFont, ui-sans-serif, sans-serif`).

Fallback reality: a web font reaches only the clients that load web fonts (Apple Mail, Samsung Mail), and only if Loops serves that family. **Nobody has verified that Loops serves Sora.** Check it in the Gate 1 Apple Mail preview. Gmail, Outlook and Yahoo show Arial either way, so most readers see Arial and the design has to hold there.

Heading scale (px, **no `clamp()`** — email has no fluid type): H1 `34` / H2 `28` / H3 `22` / body `16` / lede `18` / meta `13` / kicker `12`. Line heights stay at the values the template already rendered with: `118` / `124` / `130` for H1–H3 and `165` for body, which is the site's `--lh-body`. The site draws headings tighter (1.05 to 1.2). That is expressible but untested in Arial without the negative tracking, so the Theme does not adopt it.

### What LMX cannot express of the type rules

| ProNova rule | LMX | What the template does |
|---|---|---|
| Body at weight 300, headings at 600 | No `fontWeight` attribute and no weight key in `ThemeStyles` | Body renders at the client's regular weight and H1–H3 at the weight Loops gives a heading. `<Strong>` is bold, not 600 |
| Tight heading tracking (`-0.045em` to `-0.03em`) | `heading*LetterSpacing` exists, but the schema does not document its unit, and one rejected key fails the whole call | Left unset. Add it only after an empirical check |
| Eyebrow tracking `0.08em` | No per-block letter-spacing. `textBaseLetterSpacing` would track every line of body text | Left unset. The kicker is 12px, uppercase and muted, without the tracking |
| Uppercase eyebrows | No `text-transform` | The assembler uppercases the string |
| The diamond (a square rotated 45°) | No transform, no shape | The glyph ◆ in accent |
| A 1px ink rule or a tinted bar on one edge of a card | A Section border is all four sides, one color; no per-side border | A `<Divider>` as its own block |

Hierarchy therefore rests on **size and color**, which survive a font fallback, plus the ink masthead rule and the tinted top bars.

**No monospace.** LMX has no per-block font attribute, and ProNova's type is Sora only. The micro-labels (masthead label, byline, card number, sign-off) are 12–13px in muted.

### `themeId` form — resolved

**Resolved empirically (2026-08-31): `<Style themeId>` takes the opaque `data[].id`** (e.g. `cmrngnrqv…`). Passing the theme *name* returns `422 <Style> references unknown themeId`. No A/B test is outstanding.

## Headings carry no emphasis

ProNova allows no italic and no colored word inside a heading. The H1 is plain ink, and its color comes from the Theme:

```xml
<H1>Ship the boring automation</H1>
```

Do not put `<Em>`, `<Strong>`, `<Underline>` or a `textColor` inside `<H1>`, `<H2>` or `<H3>`. The pull quote (template §10) is plain ink too: the site draws no italics and Sora ships no italic face. No emoji anywhere in the email.

## Dark mode — survive auto-inversion, don't control it

LMX supports **no custom CSS**, so `@media (prefers-color-scheme)` is unavailable, and ProNova defines no dark theme (`tokens.css` declares `color-scheme: light`). There are no dark values to aim for. A client that darkens the email picks its own colors. What the palette gives it to work with:

- Six-digit hex only (never shorthand) — inverts more predictably.
- **Ink on white is the easy case.** `#15181d` on `#ffffff` is 17.79:1 as authored. A plain channel inversion (255 minus each channel, a model and not what any one client does) keeps base text at 17.02:1, lede at 13.68:1, muted at 7.88:1 and links at 9.93:1 on the sheet. On a card: 16.23:1, 13.05:1, 7.52:1 and 9.47:1.
- **Partial inversion is the risk.** If a client darkens the surfaces and leaves a color as authored, links fall to 3.02:1 on the sheet and 2.88:1 on a card, and muted meta lines to 3.37:1 and 3.22:1. Check links and meta lines in the Gate 1 dark preview.
- **CTA button: white `#ffffff` on ink `#15181d`.** Both colors are explicit on the `<Button>`, so most clients keep the pair: 17.79:1 as authored, 17.02:1 if the client flips both. If a client keeps the fill and darkens the card around it, the label stays readable but the fill sits at 1.12:1 against the card and the button loses its outline. **Verify this pair in the Gate 1 dark preview.**
- **Surfaces.** Assume the canvas, sheet and card merge in dark mode; they are only 1.07:1 apart in light. The tinted top bars are decoration. A client that leaves them as authored on a darkened card makes them stand out more (14.73:1 to 17.14:1), which does no harm.
- **Logo.** The ProNova logo is dark ink on a light ground. Export it on an **opaque white ground**, not a transparent one, so the ink wordmark keeps its ground when the sheet darkens. Ink on a fully inverted sheet is 1.18:1.
- `<meta name="color-scheme">` is set at the Theme/document level in the Loops UI (not API-settable). The setup steps still say `light dark`, an instruction that predates this palette. The site declares `light` only. Nobody has re-tested which value serves a light-only design in Apple Mail, so the instruction stands until a Gate 1 dark preview settles it.

## POST /v1/themes body (ThemeStyles-aligned)

`POST /v1/themes` (201) creates it; `POST /v1/themes/{themeId}` updates it. Both are writable. The `styles` keys **must match the ThemeStyles field names exactly** — they are the attribute names accepted by the LMX `<Style />` tag. Every key below is a real field, verified against the live schema.

```json
{
  "name": "ProNova",
  "styles": {
    "backgroundColor": "#f6f7fa",
    "backgroundYPadding": 24,
    "bodyColor": "#ffffff",
    "bodyXPadding": 24,
    "bodyYPadding": 24,
    "bodyFontFamily": "Sora",
    "bodyFontCategory": "sans-serif",
    "borderColor": "#e6e9ef",
    "borderWidth": 1,
    "borderRadius": 6,
    "textBaseColor": "#15181d",
    "textBaseFontSize": 16,
    "textBaseLineHeight": 165,
    "textLinkColor": "#3b4bc8",
    "buttonBodyColor": "#15181d",
    "buttonTextColor": "#ffffff",
    "buttonBorderRadius": 6,
    "buttonBodyXPadding": 32,
    "buttonBodyYPadding": 13,
    "dividerColor": "#e6e9ef",
    "dividerBorderWidth": 1,
    "heading1Color": "#15181d",
    "heading1FontSize": 34,
    "heading1LineHeight": 118,
    "heading2Color": "#15181d",
    "heading2FontSize": 28,
    "heading2LineHeight": 124,
    "heading3Color": "#15181d",
    "heading3FontSize": 22,
    "heading3LineHeight": 130
  }
}
```

Notes:

- **There is no `headingFontFamily`, `monoFontFamily`, `h1FontSize` or `bodyFontSize`.** Earlier versions of this file sent all four; none exist in `ThemeStyles`. The real names are `bodyFontFamily` (one family), `heading1FontSize`, and `textBaseFontSize`.
- `bodyXPadding` / `bodyYPadding` are the **only** body-padding keys — `bodyPadding` is not a field and will be rejected.
- `*LineHeight` is a **percentage** (100–300): `165` = 1.65.
- `heading*LetterSpacing` and `textBaseLetterSpacing` are deliberately **unset**. Sora's headings want negative tracking (`-0.045em` to `-0.03em` on the site) but the schema does not document the unit, and one rejected key fails the whole call. Add them only after an empirical check.
- `fromEmail` and other email-message-level fields do **not** belong here; this body creates the Theme only.
