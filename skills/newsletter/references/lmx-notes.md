# LMX Notes — Gotchas

Loops Markup eXpressions: a **closed, PascalCase, case-sensitive** XML component language. Unknown tags **and unknown attributes** are rejected. There is **no raw-HTML escape hatch** — the `lmx` field on `POST /v1/email-messages/{id}` accepts only LMX; Loops' engine renders it to client-safe HTML.

When in doubt, check the attribute against the vendored spec (`skills/loops-lmx/references/lmx-spec.md`) before using it. Several plausible-sounding attributes do not exist: `thickness`, `blockBorder`, `borderLeft`, `fontFamily`, `fontStyle`, `bodyPadding`.

## Allowed top-level tags
Exactly these may sit at the top level of a document:
`H1`, `H2`, `H3`, `Paragraph`, `Quote`, `CodeBlock`, `Button`, `Image`, `Divider`, `OrderedList`, `UnorderedList`, `Columns`, `Component`, `For`, `Icons`, `Section`, `Style`.

**`<Br/>` is not one of them** — it is inline and 422s at top level ("Top-level `<Br>` is not allowed"). Use `paddingTop`/`paddingBottom` for spacing between blocks. Same for `<Text>`, `<Link>`, `<ListItem>` and `<ColumnItem>`.

## Images must be Loops-hosted
`<Image src>` must point at Loops' own CDN. An external URL fails with *"is not hosted on our CDN. Uploading external images is not supported yet."* Both `hero_logo_url` **and** `hero_image_url` must come from the 3-step upload flow (`POST /v1/uploads` → `PUT` presigned → `POST /v1/uploads/{id}/complete`), never a pasted link.

## Sections cannot nest
`<Section>` cannot contain another `<Section>`. This rules out the obvious card pattern (outer spacing wrapper → card → inner padding wrapper). Instead:
- **One flat `<Section>` per card.** No outer wrapper; vertical rhythm comes from each block's own `paddingTop`/`paddingBottom`.
- To keep a top-bar `<Divider>` flush to the card edge while text is inset, set `paddingLeft="0" paddingRight="0"` on the Section and `paddingLeft="20" paddingRight="20"` on each **inner block**.
- `body_blocks[]` fragments must not contain a `<Section>`.

## No per-block font
There is no `fontFamily` attribute anywhere. `<Style>`/ThemeStyles exposes **`bodyFontFamily` + `bodyFontCategory` only** — one family for the entire email, no heading font and no mono font.
- The design system is single-family (Archivo) as of 2026-08-24, so this matches.
- **Micro-labels cannot be monospaced.** Style them with size + `textColor` + uppercase + wide tracking instead (as the site's `.pm-kicker` / `.pm-label` do).
- Italic comes from the `<Em>` tag, not a `fontStyle` attribute.

## Color lives on inline tags
`<Paragraph>`, `<H1>`-`<H3>` and `<Quote>` do **not** accept `textColor` — and `color` is not a text attribute at all (it belongs to `<Divider>` and `<Icons>`).
- Body/meta color → `<Paragraph><Text textColor="#39443f">…</Text></Paragraph>`.
- Heading color → from the Theme (`heading1Color` …).
- `<Text>` is an **inline** tag; it cannot be a direct child of `<Section>`.

## Padding is four numeric attributes
`paddingTop`, `paddingRight`, `paddingBottom`, `paddingLeft` — plain numbers. There is no `padding="0 24 16 24"` shorthand.

## No loops or conditionals
LMX has no `for`/`if`. Expand arrays yourself:
- `key_points[]` → emit N concrete card `<Section>` blocks (3 default, 5 max).
- `body_blocks[]` → concatenate the LMX fragment strings in order. Validate each fragment against the installed **Loops LMX skill**, not against this file.
- Optional sections (hero, prompt callout) → **strip the whole block** if the variable is empty; don't emit an empty block.

## No borders, no `box-shadow`
Blocks accept only `blockColor`, `blockBorderRadius` and `padding*`. There is no block border attribute and no shadow, and both would be invisible in Gmail/Outlook/Yahoo anyway.

Depth comes from the **mint surface ladder** instead: `#d2e1db` canvas → `#e9f1ee` sheet → `#e0ebe7` card. The card reads as raised with no border. See `token-map.md`.

(`<Image>` is the exception — it does have `borderRadius`, `borderWidth` and `borderColor`.)

## 3px raspberry top-bar (no `::before`)
A `<Divider color="#b8446a" borderWidth="3"/>` as the **first child** of the card `<Section>`. The thickness attribute is `borderWidth` (1-16); there is no `thickness`. See `token-map.md` for the full card pattern.

## No `@media` / no custom CSS
`@media (prefers-color-scheme)` is **not available**. Dark mode = **survive auto-inversion**, don't control it:
- Six-digit hex only (never shorthand) — inverts predictably.
- Cool-not-pure values (`#161c1a`, `#e9f1ee`) → the mint pair stays mint-adjacent under inversion.
- Raspberry `#b8446a` is mid-luminance → survives both light and dark-inverted backgrounds.
- **Button: white `#ffffff` on raspberry `#b8446a`.** Raspberry is dark enough for white (5.2:1). This reverses the old palette's dark-ink-on-button rule, which existed only because the previous orange coral was too light for white. Confirm this pair in the Gate 1 dark preview.
- Set `<meta name="color-scheme" content="light dark">` at the Theme/document level in the Loops UI (not API-settable).

## Italic-raspberry emphasis
`<H1>Ship the <Em textColor="#8a2c4e">boring</Em> automation</H1>`

`textColor` is documented directly on `<Em>` (and every other inline tag), so no nesting trick is needed.

## Accent rationing
Raspberry is for **CTAs, links, the H1 emphasis word, and card top-bars**. **Teal** (`#276358` text / `#3f8f82` rules) carries the kicker and the masthead rule. Don't reach for raspberry as a general accent.

`#b8446a` is ~3.4:1 on mint — **non-text or ≥18px only**. Any raspberry that is small text must be `#8a2c4e`.

## Border radius
`blockBorderRadius="18"` on cards; `buttonBorderRadius: 999` in the Theme. Loops emits a VML `RoundRect` fallback for Outlook Classic → degrades to square gracefully. Accept the degradation.

## Web fonts
Archivo renders in Apple Mail / Samsung / Comcast. Gmail / Outlook / Yahoo fall back to the `bodyFontCategory` default (system-ui / Arial). Mitigation: hierarchy is carried by size, weight, tracking and color — all of which survive a fallback — plus the raspberry top-bar and teal kicker rule.

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
