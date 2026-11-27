# LMX Notes — Gotchas

Loops Markup eXpressions: a **closed, PascalCase, case-sensitive** XML component language. Unknown tags **and unknown attributes** are rejected. There is **no raw-HTML escape hatch** — the `lmx` field on `POST /v1/email-messages/{id}` accepts only LMX; Loops' engine renders it to client-safe HTML.

When in doubt, check the attribute against the vendored spec (`skills/loops-lmx/references/lmx-spec.md`) before using it. Several plausible-sounding attributes do not exist: `thickness`, `blockBorder`, `borderLeft`, `fontFamily`, `fontStyle`, `bodyPadding`.

## Allowed top-level tags
Exactly these may sit at the top level of a document:
`H1`, `H2`, `H3`, `Paragraph`, `Quote`, `CodeBlock`, `Button`, `Image`, `Divider`, `OrderedList`, `UnorderedList`, `Columns`, `Component`, `For`, `Icons`, `Section`, `Style`.

**`<Br/>` is not one of them** — it is inline and 422s at top level ("Top-level `<Br>` is not allowed"). Use `paddingTop`/`paddingBottom` for spacing between blocks. Same for `<Text>`, `<Link>`, `<ListItem>` and `<ColumnItem>`.

## Spacing between cards
Loops puts **no gap between sibling blocks**, and `paddingBottom` on a `<Section>` renders *inside* the `blockColor` fill — it makes the card taller, it does not separate it from the next card. Consecutive cards therefore render as one continuous slab.

Insert an explicit spacer between them:

```xml
<Paragraph fontSize="12"><Br/></Paragraph>
```

`<Br/>` must be wrapped — bare, it 422s at top level. Avoid the alternative "invisible `<Divider>` matching `bodyColor`" trick: it couples the spacer to the palette, so the line reappears the moment `bodyColor` changes. An empty `<Paragraph></Paragraph>` validates but can collapse to zero height in some clients; the `<Br/>` guarantees a line box.

## Images must be Loops-hosted
`<Image src>` must point at Loops' own CDN. An external URL fails with *"is not hosted on our CDN. Uploading external images is not supported yet."* Both `hero_logo_url` **and** `hero_image_url` must come from the 3-step upload flow (`POST /v1/uploads` → `PUT` presigned → `POST /v1/uploads/{id}/complete`), never a pasted link.

## Sections cannot nest
`<Section>` cannot contain another `<Section>`. This rules out the obvious card pattern (outer spacing wrapper → card → inner padding wrapper). Instead:
- **One flat `<Section>` per card.** No outer wrapper; vertical rhythm comes from each block's own `paddingTop`/`paddingBottom`.
- To keep a top-bar `<Divider>` flush to the card edge while text is inset, set `paddingLeft="0" paddingRight="0"` on the Section and `paddingLeft="20" paddingRight="20"` on each **inner block**.
- `body_blocks[]` fragments must not contain a `<Section>`.

## No per-block font
There is no `fontFamily` attribute anywhere. `<Style>`/ThemeStyles exposes **`bodyFontFamily` + `bodyFontCategory` only** — one family for the entire email, no heading font and no mono font.
- ProNova sets everything in Sora (`pronova-website/src/styles/tokens.css`), so this matches.
- **No weight and no tracking either.** There is no `fontWeight` or per-block letter-spacing attribute, so ProNova's light body (300), semibold headings (600) and `0.08em` eyebrow tracking cannot be set. Micro-labels are styled with size + `textColor`, and the assembler uppercases the string itself (no `text-transform`).
- Italic comes from the `<Em>` tag, not a `fontStyle` attribute. The ProNova template uses no italic at all.

## Color lives on inline tags
`<Paragraph>`, `<H1>`-`<H3>` and `<Quote>` do **not** accept `textColor` — and `color` is not a text attribute at all (it belongs to `<Divider>` and `<Icons>`).
- Body/meta color → `<Paragraph><Text textColor="#2a2f37">…</Text></Paragraph>`.
- Heading color → from the Theme (`heading1Color` …).
- `<Text>` is an **inline** tag; it cannot be a direct child of `<Section>`.

## Padding is four numeric attributes
`paddingTop`, `paddingRight`, `paddingBottom`, `paddingLeft` — plain numbers. There is no `padding="0 24 16 24"` shorthand.

## No loops or conditionals
LMX has no `for`/`if`. Expand arrays yourself:
- `key_points[]` → emit N concrete card `<Section>` blocks (3 default, 5 max).
- `body_blocks[]` → concatenate the LMX fragment strings in order. Validate each fragment against the installed **Loops LMX skill**, not against this file.
- Optional sections (hero, prompt callout) → **strip the whole block** if the variable is empty; don't emit an empty block.

## Section border yes, `box-shadow` no
The vendored spec documents only `blockColor`, `blockBorderRadius` and `padding*` on blocks. `<Section>` also takes `blockBorderWidth` + `blockBorderColor` (undocumented upstream; confirmed in the Loops dry run of 2026-11-27, which drew the border only when both were set). There is no per-side border and no shadow.

A card is a `#f6f7fa` `<Section>` on the white `#ffffff` sheet (the outer canvas reuses `#f6f7fa`). That fill is only **1.07:1** against the sheet, too faint to carry a card by itself. The card reads through its 1px `#e6e9ef` border, its 6px tinted top bar, its 6px radius and its padding. Do not add a color from outside the ProNova system to strengthen it. See `token-map.md`.

(`<Image>` is the exception — it does have `borderRadius`, `borderWidth` and `borderColor`.)

## 6px tinted top bar (no `::before`)
A `<Divider color="#d6dcf8" borderWidth="6" paddingTop="0" paddingBottom="0"/>` as the **first child** of the card `<Section>`. Both paddings are `0`: a Divider carries default padding above and below, and without the zeros the bar sits about 24px below the card's top edge with a band of card fill above it (seen in the Loops render of 2026-11-27). The card itself carries `blockBorderWidth="1" blockBorderColor="#e6e9ef"`, the site's hairline: the fill `#f6f7fa` is only 1.07:1 against the white sheet, so the border is what gives the card its edge. Loops draws a Section border only when both attributes are set. The thickness attribute is `borderWidth` (1-16); there is no `thickness`. The color is one of ProNova's four topic tints: periwinkle `#d6dcf8` (default), ice `#d3ecf2`, mint `#cdebdd`, butter `#f3efc6`. See `token-map.md` for the full card pattern.

## No `@media` / no custom CSS
`@media (prefers-color-scheme)` is **not available**. Dark mode = **survive auto-inversion**, don't control it:
- ProNova has one light theme and no dark theme, so there are no dark values to aim for.
- Six-digit hex only (never shorthand) — inverts predictably.
- Ink `#15181d` on the white sheet is 17.79:1 and stays above 17:1 under a plain inversion. Muted `#5a6170` and accent `#3b4bc8` also pass when a client flips text and surface together.
- **Partial inversion is the risk.** On a darkened sheet, a link left in `#3b4bc8` falls to 3.02:1 and a meta line left in `#5a6170` to 3.37:1. Check both in the Gate 1 dark preview.
- **Button: white `#ffffff` on ink `#15181d`** (17.79:1). Both colors are explicit, so most clients keep the pair. If a client darkens the card and keeps the fill, the label stays readable but the button loses its outline. Confirm this pair in the Gate 1 dark preview.
- Set `<meta name="color-scheme" content="light dark">` at the Theme/document level in the Loops UI (not API-settable). This instruction predates the ProNova palette and has not been re-tested against a light-only design; see `token-map.md`.

## Headings carry no emphasis
`<H1>Ship the boring automation</H1>`

ProNova allows no italic and no colored word inside a heading. `textColor` is documented on `<Em>` and every other inline tag, so LMX would accept one; the template does not use it. Keep `<Em>`, `<Strong>` and `textColor` out of `<H1>`-`<H3>`.

## Accent: links and the diamond only
Accent `#3b4bc8` is for **links and the kicker's ◆**. It is 6.93:1 on the sheet and 6.47:1 on a card, so it is safe as small text on both. The button is ink `#15181d`, the masthead rule is a 1px ink `<Divider>`, and card top bars take a topic tint. Don't reach for the accent as a general highlight.

The diamond is ProNova's only ornament: a small square rotated 45°. LMX has no transform, so the glyph ◆ (U+25C6) stands in for it, inside a `<Text textColor="#3b4bc8">`. No emoji anywhere.

## Border radius
`blockBorderRadius="6"` on cards; `buttonBorderRadius: 6` in the Theme and `borderRadius="6"` on the `<Button>` and the hero `<Image>`. One radius, no pills. Loops emits a VML `RoundRect` fallback for Outlook Classic → degrades to square gracefully. Accept the degradation.

## Web fonts
The family is `Sora`, a bare Google Fonts name (a CSS stack breaks Loops' font request, see `token-map.md`). A web font reaches only the clients that load web fonts (Apple Mail, Samsung). Google Fonts serves Sora (checked 2026-11-27); confirm the rendered email's font link in Gate 1. Gmail / Outlook / Yahoo show Arial either way. Mitigation: hierarchy is carried by size and color, both of which survive a fallback, plus the ink masthead rule and the tinted top bars.

## Images
`width` is a **number, 12-600 pixels** — `width="100%"` is invalid. The content column is 600px with `bodyXPadding="24"`, so a full-bleed image inside the body is `552`.

## Columns
`<Columns>` must contain **exactly two `<ColumnItem>`** children. `<ColumnItem>` takes no attributes. The vertical-alignment attribute is `verticalAlignment` (not `verticalAlign`), and it belongs on `<Columns>`.

## Size discipline
- Total LMX **<100KB** (API cap) and **<102KB** (Gmail clip). The assembler enforces this with a trimming cascade (`lmx-master-template.md`).
- No `clamp()` — email has no fluid type. Fixed px heading scale.
- CTA button ≥44px tall (`innerYPadding="13"` — there is no `padding` shorthand on `<Button>`, and `size` is retired).
- `bodyXPadding="24" bodyYPadding="24"` on `<Style/>` (ThemeStyles has X/Y padding keys, no `bodyPadding`); rely on Loops' 600px centered responsive column (don't hand-roll `max-width`).
- `<Columns stackOnMobile="true">` only for the masthead; everything else is single-column.

## No footer authored
Loops auto-appends the campaign footer + `{system.unsubscribe_link}`. Do not author a footer or unsubscribe link — doing so duplicates them.
