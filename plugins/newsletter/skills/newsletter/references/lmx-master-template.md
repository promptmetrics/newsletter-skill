# LMX Master Template — "Field Notes" Mixed Issue

The 12-section LMX skeleton the assembler emits. `{{variable}}` placeholders are filled from the brief; `key_points[]` and `body_blocks[]` expand into repeated/concrete blocks (LMX has **no loops or conditionals**). One `<Style themeId="{{theme_id}}"/>` is always the first line. `{{theme_id}}` is captured from `GET /v1/themes` at run time; the OpenAPI contract does **not** state what value `<Style themeId="...">` accepts, and it is the **opaque `data[].id`** (e.g. `cmrngnrqv…`), confirmed empirically on 2026-08-31 — passing the theme *name* returns `422 <Style> references unknown themeId`. **No footer** — Loops auto-appends the campaign footer + `{system.unsubscribe_link}`; do not author it.

All hex values are inlined per `token-map.md`. The font comes from the Theme (one family, Sora) — never per-block. Every `{{…}}` slot, the bar colors included, is filled by the assembler before the API call: the LMX that reaches Loops carries literal six-digit hex.

## Structural rules this skeleton obeys

Read `lmx-notes.md` before editing. The five that shape the markup:

1. **Sections cannot nest.** There is exactly one `<Section>` per card, with no outer spacing wrapper. Vertical rhythm comes from each block's own `paddingTop`/`paddingBottom`.
2. **Color lives on inline tags.** `<Paragraph>`/`<H1>`-`<H3>`/`<Quote>` take no `textColor`; wrap content in `<Text textColor="…">`. Heading color comes from the Theme.
3. **Padding is four numeric attributes**, never a shorthand string.
4. **`<Br/>` is inline-only.** Allowed top-level tags are exactly: `H1 H2 H3 Paragraph Quote CodeBlock Button Image Divider OrderedList UnorderedList Columns Component For Icons Section Style`. Spacing between blocks comes from `paddingTop`/`paddingBottom`, never a `<Br/>`.
5. **Headings are plain ink.** No `<Em>`, `<Strong>` or `textColor` inside `<H1>`-`<H3>`. Every text color in this skeleton clears 4.5:1 on the white sheet and on the `#f6f7fa` card (`token-map.md`), so no color is restricted to one surface.

## Skeleton

```xml
<Style themeId="{{theme_id}}" backgroundColor="#f6f7fa" bodyColor="#ffffff" bodyXPadding="24" bodyYPadding="24"/>

<!-- 1. Preheader = the message `previewText` field, not an LMX block. -->

<!-- 2-3. Masthead: the ProNova logo, the issue label, then a 1px ink rule -->
<Columns widths="28,72" gap="12" verticalAlignment="middle" stackOnMobile="true" paddingBottom="12">
  <ColumnItem>
    <Image src="{{hero_logo_url}}" alt="ProNova" width="120"/>
  </ColumnItem>
  <ColumnItem>
    <Paragraph fontSize="13"><Text textColor="#5a6170">{{masthead_label}} · ISSUE {{issue_number}}</Text></Paragraph>
  </ColumnItem>
</Columns>
<Divider color="#15181d" borderWidth="1" paddingBottom="16"/>

<!-- 4. Kicker + Headline. The kicker is an accent ◆ and an uppercase muted label.
     The headline is plain ink: no italic, no colored word. -->
<Paragraph fontSize="12" paddingBottom="8"><Text textColor="#3b4bc8">◆</Text><Text textColor="#5a6170"> {{kicker}}</Text></Paragraph>
<H1 paddingBottom="16">{{headline}}</H1>

<!-- 5. Lede -->
<Paragraph fontSize="18" paddingBottom="16"><Text textColor="#2a2f37">{{lede}}</Text></Paragraph>

<!-- 6. Byline -->
<Paragraph fontSize="13" paddingBottom="24"><Text textColor="#5a6170">{{author_name}} · {{issue_date}} · {{read_time}} min</Text></Paragraph>

<!-- 7. Hero image — OMIT ENTIRELY if {{hero_image_url}} is empty.
     Image carries its own radius; no card Section needed. -->
<Image src="{{hero_image_url}}" alt="{{hero_image_alt}}" width="552" borderRadius="6" align="center"/>
<Paragraph fontSize="12"><Br/></Paragraph>

<!-- 8. Key-points card stack — EXPAND: one card <Section> per element of key_points[]
     (default 3, max 5). Repeat this block N times with {{kp_*}} filled per element.
     paddingLeft/Right="0" on the Section so the top bar runs edge-to-edge;
     inner blocks inset themselves by 20. {{kp_bar_color}} is one of the four tints. -->
<Section blockColor="#f6f7fa" blockBorderRadius="6" blockBorderWidth="1" blockBorderColor="#e6e9ef" paddingTop="0" paddingBottom="20" paddingLeft="0" paddingRight="0">
  <Divider color="{{kp_bar_color}}" borderWidth="6" paddingTop="0" paddingBottom="0"/>
  <Paragraph fontSize="13" paddingTop="16" paddingLeft="20" paddingRight="20"><Text textColor="#5a6170">{{kp_number}}</Text></Paragraph>
  <H3 paddingLeft="20" paddingRight="20">{{kp_title}}</H3>
  <Paragraph fontSize="16" paddingTop="8" paddingLeft="20" paddingRight="20"><Text textColor="#2a2f37">{{kp_description}}</Text></Paragraph>
  <!-- optional link — include only if kp_link_url is non-empty -->
  <Paragraph fontSize="13" paddingTop="8" paddingLeft="20" paddingRight="20"><Link href="{{kp_link_url}}">{{kp_link_label}}</Link></Paragraph>
</Section>
<Paragraph fontSize="12"><Br/></Paragraph>

<!-- 9. Editorial body — EXPAND: concatenate body_blocks[] LMX fragments in order -->
{{body_blocks_expanded}}

<!-- 10. Pull-quote callout — OMIT if {{prompt_quote}} is empty.
     Plain ink, not italic. The tinted top bar marks it as a card. -->
<Section blockColor="#f6f7fa" blockBorderRadius="6" blockBorderWidth="1" blockBorderColor="#e6e9ef" paddingTop="0" paddingBottom="20" paddingLeft="0" paddingRight="0">
  <Divider color="{{bar_color}}" borderWidth="6" paddingTop="0" paddingBottom="0"/>
  <Quote fontSize="18" paddingTop="16" paddingLeft="20" paddingRight="20"><Text textColor="#15181d">{{prompt_quote}}</Text></Quote>
  <!-- attribution line — include only if prompt_attribution is non-empty -->
  <Paragraph fontSize="13" paddingTop="8" paddingLeft="20" paddingRight="20"><Text textColor="#5a6170">— {{prompt_attribution}}</Text></Paragraph>
</Section>
<Paragraph fontSize="12"><Br/></Paragraph>

<!-- 11. Standing community CTA — Operator Stack.
     NOT a per-issue CTA and NOT a newsletter signup: the reader already has
     the newsletter. Defaults below are fixed; the brief may override them.
     The button is ink with a white label and the one 6px radius. -->
<Section blockColor="#f6f7fa" blockBorderRadius="6" blockBorderWidth="1" blockBorderColor="#e6e9ef" paddingTop="0" paddingBottom="24" paddingLeft="0" paddingRight="0">
  <Divider color="{{bar_color}}" borderWidth="6" paddingTop="0" paddingBottom="0"/>
  <H3 align="center" paddingTop="20" paddingLeft="20" paddingRight="20">{{cta_headline}}</H3>
  <Paragraph fontSize="16" align="center" paddingTop="8" paddingLeft="20" paddingRight="20"><Text textColor="#2a2f37">{{cta_supporting}}</Text></Paragraph>
  <Button href="{{cta_url}}" bgColor="#15181d" textColor="#ffffff" borderRadius="6" innerXPadding="32" innerYPadding="13" align="center" paddingTop="16">{{cta_label}}</Button>
</Section>
<Paragraph fontSize="12"><Br/></Paragraph>

<!-- 12. Sign-off (footer + unsubscribe auto-appended by Loops — do not author) -->
<Paragraph fontSize="13"><Text textColor="#5a6170">— {{author_name}}, {{company}}</Text></Paragraph>
```

## Variable slots

| Slot | Source (brief) | Type | Notes |
|---|---|---|---|
| `hero_logo_url` | `hero_logo_url` (brief; sourced from the one-time `POST /v1/uploads`) | string | The ProNova logo tile and wordmark, dark ink on an opaque light ground; Step 0 fail-stops if absent. `width="120"` suits the current asset (528 × 136 px, 3.88:1, so about 31px tall; `onboarding.md` step 4); set it to suit any replacement file |
| `masthead_label` | `masthead_label` | string | Default `"FIELD NOTES"`; emit uppercase |
| `issue_number` | `issue_metadata.issue_number` | string | |
| `kicker` | `kicker` | string | Emit uppercase; muted, after the accent ◆ |
| `headline` | `headline` | string | Plain text. No inline tags |
| `lede` | `lede` | string | |
| `author_name` | `issue_metadata.author` | string | |
| `issue_date` | `issue_metadata.date` | string | ISO `YYYY-MM-DD` or display form |
| `read_time` | `read_time` | number | minutes |
| `hero_image_url` / `hero_image_alt` | `hero_image_url` / `hero_image_alt` | string? | §7 omitted if empty |
| `kp_number` / `kp_title` / `kp_description` / `kp_link_url`? / `kp_link_label`? | `key_points[]` element | per card | 3 default, 5 max |
| `kp_bar_color` | `key_points[].topic`, else `topic` | hex | Tint for that card's top bar; default `#d6dcf8` (see "Top-bar tint") |
| `bar_color` | `topic` | hex | Tint for the §10 and §11 top bars; default `#d6dcf8` |
| `body_blocks_expanded` | `body_blocks[]` | LMX fragment string | concatenated |
| `prompt_quote` / `prompt_attribution`? | `prompt_quote` / `prompt_attribution` | string? | §10 omitted if `prompt_quote` empty |
| `cta_url` | `cta.url` | string | **Defaults to `https://operator.promptmetrics.dev/`** (Operator Stack). Override only for a genuinely different destination |
| `cta_label` | `cta.label` | string | **Defaults to `Join Operator Stack`** |
| `cta_headline` | `cta.headline` | string | **Defaults to `Compare notes with other operators`** |
| `cta_supporting` | `cta.supporting` | string | **Defaults to `Operator Stack is where RevOps, CS and marketing-ops leads working the same problems trade what actually shipped.`** |
| `company` | `company` | string | Sign-off. Default `ProNova` |

Message-level fields (not in LMX): `subject`, `previewText` (from `preview_text`), `fromName` (e.g. `ProNova Field Notes`), `fromEmail`, `replyToEmail`.

## The standing community CTA (§11)

§11 is a **fixed Operator Stack card**, not a per-issue action and **never a newsletter signup** — the reader is already a subscriber, so "Subscribe to Field Notes" is a dead CTA that wastes the issue's only button.

Defaults, used unless the brief explicitly overrides them:

| Slot | Value |
|---|---|
| `cta_url` | `https://operator.promptmetrics.dev/` |
| `cta_label` | `Join Operator Stack` |
| `cta_headline` | `Compare notes with other operators` |
| `cta_supporting` | `Operator Stack is where RevOps, CS and marketing-ops leads working the same problems trade what actually shipped.` |

Do **not** draft per-issue CTA copy from `goal` any more. If an issue genuinely needs its own action, put it on a key-point card's "read more" link (§8), which is what that link is for.

## Top-bar tint

Each card's top bar is a `<Divider borderWidth="6">` in one of ProNova's four tints, one per topic:

| `topic` | Hex |
|---|---|
| `agents` (default) | `#d6dcf8` |
| `engineering` | `#d3ecf2` |
| `mcp` | `#cdebdd` |
| `workflows` | `#f3efc6` |

- `bar_color` comes from the brief's optional `topic` and colors the §10 and §11 bars.
- `kp_bar_color` comes from that key point's optional `topic`; if it has none, it takes `bar_color`.
- Neither set → every bar is periwinkle `#d6dcf8`.
- A value outside the table → use periwinkle and tell the author at Gate 1. Never emit a hex that is not one of the four.

## Expansion rules

### `key_points[]` → repeated card blocks
- Each element `{title, description, link_url?, link_label?, topic?}` emits the §8 card block once, **followed by the spacer** `<Paragraph fontSize="12"><Br/></Paragraph>`.
- **The spacer is required.** Loops puts no gap between sibling blocks, and `paddingBottom` on a card `<Section>` sits *inside* the card fill (it makes the card taller, it does not separate it from the next one). Without the spacer the cards render as one continuous slab. A bare `<Br/>` will not do — it is inline-only and 422s at top level; it must be wrapped in a `<Paragraph>`.
- **Default 3 cards, max 5.** If the brief has fewer than 3, ask the author whether to pad or ship fewer (do not silently pad). If more than 5, truncate to the first 5 and warn the author.
- `{{kp_number}}` = zero-padded index (`01`, `02`, …).
- Include the link `<Paragraph>` **only if** `link_url` is non-empty; otherwise omit it. If `link_url` is set but `link_label` is empty, default the label to `"Read more"`. The `<Link>` inherits `textLinkColor` (`#3b4bc8`) from the Theme — do not set a color on it.

### `body_blocks[]` → concatenated fragments
- Each element is an LMX fragment string (`<Paragraph>…</Paragraph>`, `<H2>…</H2>`, `<UnorderedList>…</UnorderedList>`, `<Quote>…</Quote>`).
- **Validate each fragment** before concatenation: PascalCase tag, properly closed, and **no `<Section>`** (a fragment carrying a Section breaks the flat structure).
- Body-copy color: fragments should wrap long copy in `<Text textColor="#2a2f37">`, ProNova's long-copy color; bare text inherits `textBaseColor` (`#15181d`). An `<H2>` or `<H3>` fragment carries no `<Em>`, `<Strong>` or `textColor`.
- Concatenate in array order. Separate with no extra markup (the fragments carry their own spacing).

### Optional-section stripping
- §7 (hero): strip the `<Image>` **and its following spacer** if `hero_image_url` is empty/absent. The URL **must be Loops-CDN-hosted** (upload flow) — an external URL 422s.
- §10 (callout): strip the whole `<Section>` **and its following spacer** if `prompt_quote` is empty/absent; strip just the attribution `<Paragraph>` if `prompt_attribution` is empty.

## 100KB cap (API) / 102KB (Gmail clip)

Measure the final assembled LMX string **after assembly, before `POST /v1/email-messages`**. If over:
1. Cap body paragraphs at 8. If over, truncate and append:
   `<Paragraph>Read the full issue at <Link href="{{website_url}}">{{website_url}}</Link>.</Paragraph>`
2. If still over, reduce key-point cards to 3 and trim descriptions.
3. If still over, **fail** with: "Issue content exceeds 100KB even after trimming. Reduce body length or move content to a web link." Do not call the API.

## Theme injection

`<Style themeId="{{theme_id}}" backgroundColor="#f6f7fa" bodyColor="#ffffff" bodyXPadding="24" bodyYPadding="24"/>` is always the **first line**. Both surface colors are re-declared here so the canvas and the sheet survive even if the Theme lookup returns an unexpected theme; the Theme still owns the font, heading sizes, link color, button styling and divider default.

The Theme ("ProNova") is **created or verified via the API** at onboarding (`POST /v1/themes` if missing, else `GET /v1/themes` and capture the `id`) — see `onboarding.md` step 2 and `token-map.md` for the `ThemeStyles`-aligned body. The manual Loops UI path is the **fallback** (e.g. if the team's Content API is not enabled) — see README "One-time Loops UI setup".
