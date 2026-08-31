# LMX Master Template — "Field Notes" Mixed Issue

The 12-section LMX skeleton the assembler emits. `{{variable}}` placeholders are filled from the brief; `key_points[]` and `body_blocks[]` expand into repeated/concrete blocks (LMX has **no loops or conditionals**). One `<Style themeId="{{theme_id}}"/>` is always the first line. `{{theme_id}}` is captured from `GET /v1/themes` at run time; the OpenAPI contract does **not** state what value `<Style themeId="...">` accepts, and it is the **opaque `data[].id`** (e.g. `cmrngnrqv…`), confirmed empirically on 2026-08-31 — passing the theme *name* returns `422 <Style> references unknown themeId`. **No footer** — Loops auto-appends the campaign footer + `{system.unsubscribe_link}`; do not author it.

All hex values are inlined per `token-map.md`. The font comes from the Theme (one family, Archivo) — never per-block.

## Structural rules this skeleton obeys

Read `lmx-notes.md` before editing. The three that shape the markup:

1. **Sections cannot nest.** There is exactly one `<Section>` per card, with no outer spacing wrapper. Vertical rhythm comes from each block's own `paddingTop`/`paddingBottom`.
2. **Color lives on inline tags.** `<Paragraph>`/`<H1>`-`<H3>`/`<Quote>` take no `textColor`; wrap content in `<Text textColor="…">`. Heading color comes from the Theme.
3. **Padding is four numeric attributes**, never a shorthand string.
4. **`<Br/>` is inline-only.** Allowed top-level tags are exactly: `H1 H2 H3 Paragraph Quote CodeBlock Button Image Divider OrderedList UnorderedList Columns Component For Icons Section Style`. Spacing between blocks comes from `paddingTop`/`paddingBottom`, never a `<Br/>`.
5. **Muted `#5e6f68` is sheet-only.** It clears AA on `#e9f1ee` (4.63:1) but *not* on the `#e0ebe7` card (4.36:1). On cards, 13px labels/indices use teal-dark `#276358` and 13px prose uses ink-2 `#39443f`.

## Skeleton

```xml
<Style themeId="{{theme_id}}" backgroundColor="#d2e1db" bodyColor="#e9f1ee" bodyXPadding="24" bodyYPadding="24"/>

<!-- 1. Preheader = the message `previewText` field, not an LMX block. -->

<!-- 2-3. Masthead -->
<Columns widths="28,72" gap="12" verticalAlignment="middle" stackOnMobile="true" paddingBottom="12">
  <ColumnItem>
    <Image src="{{hero_logo_url}}" alt="PromptMetrics pinwheel" width="28"/>
  </ColumnItem>
  <ColumnItem>
    <Paragraph fontSize="13"><Text textColor="#5e6f68">{{masthead_label}} · ISSUE {{issue_number}}</Text></Paragraph>
  </ColumnItem>
</Columns>
<Divider color="#3f8f82" borderWidth="1" paddingBottom="16"/>

<!-- 4. Kicker + Headline (exactly one italic-raspberry emphasis word) -->
<Paragraph fontSize="12" paddingBottom="8"><Text textColor="#276358">— {{kicker}}</Text></Paragraph>
<H1 paddingBottom="16">{{headline_before_em}}<Em textColor="#8a2c4e">{{emphasis_word}}</Em>{{headline_after_em}}</H1>

<!-- 5. Lede -->
<Paragraph fontSize="18" paddingBottom="16"><Text textColor="#39443f">{{lede}}</Text></Paragraph>

<!-- 6. Byline -->
<Paragraph fontSize="13" paddingBottom="24"><Text textColor="#5e6f68">{{author_name}} · {{issue_date}} · {{read_time}} min</Text></Paragraph>

<!-- 7. Hero image — OMIT ENTIRELY if {{hero_image_url}} is empty.
     Image carries its own radius; no card Section needed. -->
<Image src="{{hero_image_url}}" alt="{{hero_image_alt}}" width="552" borderRadius="18" align="center"/>

<!-- 8. Key-points card stack — EXPAND: one card <Section> per element of key_points[]
     (default 3, max 5). Repeat this block N times with {{kp_*}} filled per element.
     paddingLeft/Right="0" on the Section so the top-bar runs edge-to-edge;
     inner blocks inset themselves by 20. -->
<Section blockColor="#e0ebe7" blockBorderRadius="18" paddingTop="0" paddingBottom="20" paddingLeft="0" paddingRight="0">
  <Divider color="#b8446a" borderWidth="3"/>
  <Paragraph fontSize="13" paddingTop="16" paddingLeft="20" paddingRight="20"><Text textColor="#276358">{{kp_number}}</Text></Paragraph>
  <H3 paddingLeft="20" paddingRight="20">{{kp_title}}</H3>
  <Paragraph fontSize="16" paddingTop="8" paddingLeft="20" paddingRight="20"><Text textColor="#39443f">{{kp_description}}</Text></Paragraph>
  <!-- optional link — include only if kp_link_url is non-empty -->
  <Paragraph fontSize="13" paddingTop="8" paddingLeft="20" paddingRight="20"><Link href="{{kp_link_url}}">{{kp_link_label}}</Link></Paragraph>
</Section>

<!-- 9. Editorial body — EXPAND: concatenate body_blocks[] LMX fragments in order -->
{{body_blocks_expanded}}

<!-- 10. Italic "prompt" callout — OMIT if {{prompt_quote}} is empty.
     Raspberry top-bar stands in for the site's left rule (no borderLeft in LMX). -->
<Section blockColor="#e0ebe7" blockBorderRadius="18" paddingTop="0" paddingBottom="20" paddingLeft="0" paddingRight="0">
  <Divider color="#b8446a" borderWidth="3"/>
  <Quote fontSize="18" paddingTop="16" paddingLeft="20" paddingRight="20"><Em textColor="#161c1a">{{prompt_quote}}</Em></Quote>
  <!-- attribution line — include only if prompt_attribution is non-empty -->
  <Paragraph fontSize="13" paddingTop="8" paddingLeft="20" paddingRight="20"><Text textColor="#39443f">— {{prompt_attribution}}</Text></Paragraph>
</Section>

<!-- 11. Primary CTA card -->
<Section blockColor="#e0ebe7" blockBorderRadius="18" paddingTop="0" paddingBottom="24" paddingLeft="0" paddingRight="0">
  <Divider color="#b8446a" borderWidth="3"/>
  <H3 align="center" paddingTop="20" paddingLeft="20" paddingRight="20">{{cta_headline}}</H3>
  <Paragraph fontSize="16" align="center" paddingTop="8" paddingLeft="20" paddingRight="20"><Text textColor="#39443f">{{cta_supporting}}</Text></Paragraph>
  <Button href="{{cta_url}}" bgColor="#b8446a" textColor="#ffffff" borderRadius="999" innerXPadding="32" innerYPadding="13" align="center" paddingTop="16">{{cta_label}}</Button>
</Section>

<!-- 12. Sign-off (footer + unsubscribe auto-appended by Loops — do not author) -->
<Paragraph fontSize="13"><Text textColor="#5e6f68">— {{author_name}}, {{company}}</Text></Paragraph>
```

## Variable slots

| Slot | Source (brief) | Type | Notes |
|---|---|---|---|
| `hero_logo_url` | `hero_logo_url` (brief; sourced from the one-time `POST /v1/uploads`) | string | Dark-mode-safe variant; Step 0 fail-stops if absent |
| `masthead_label` | `masthead_label` | string | Default `"FIELD NOTES"`; emit uppercase |
| `issue_number` | `issue_metadata.issue_number` | string | |
| `kicker` | `kicker` | string | Uppercase; teal |
| `headline_before_em` / `emphasis_word` / `headline_after_em` | `headline` split at `emphasis_word` | string×3 | Exactly one emphasis word |
| `lede` | `lede` | string | |
| `author_name` | `issue_metadata.author` | string | |
| `issue_date` | `issue_metadata.date` | string | ISO `YYYY-MM-DD` or display form |
| `read_time` | `read_time` | number | minutes |
| `hero_image_url` / `hero_image_alt` | `hero_image_url` / `hero_image_alt` | string? | §7 omitted if empty |
| `kp_number` / `kp_title` / `kp_description` / `kp_link_url`? / `kp_link_label`? | `key_points[]` element | per card | 3 default, 5 max |
| `body_blocks_expanded` | `body_blocks[]` | LMX fragment string | concatenated |
| `prompt_quote` / `prompt_attribution`? | `prompt_quote` / `prompt_attribution` | string? | §10 omitted if `prompt_quote` empty |
| `cta_label` / `cta_url` | `cta.label` / `cta.url` (required) | string | |
| `cta_headline` / `cta_supporting` | drafted from `goal` / `key_points[0].description` if absent | string | Approved at Gate 1 |
| `company` | `company` | string | sign-off |

Message-level fields (not in LMX): `subject`, `previewText` (from `preview_text`), `fromName`, `fromEmail`, `replyToEmail`.

## Expansion rules

### `key_points[]` → repeated card blocks
- Each element `{title, description, link_url?, link_label?}` emits the §8 card block once. Do **not** separate cards with `<Br/>` — it is inline-only and 422s at top level; Loops spaces sibling blocks on its own.
- **Default 3 cards, max 5.** If the brief has fewer than 3, ask the author whether to pad or ship fewer (do not silently pad). If more than 5, truncate to the first 5 and warn the author.
- `{{kp_number}}` = zero-padded index (`01`, `02`, …).
- Include the link `<Paragraph>` **only if** `link_url` is non-empty; otherwise omit it. If `link_url` is set but `link_label` is empty, default the label to `"Read more"`. The `<Link>` inherits `textLinkColor` (`#8a2c4e`) from the Theme — do not set a color on it.

### `body_blocks[]` → concatenated fragments
- Each element is an LMX fragment string (`<Paragraph>…</Paragraph>`, `<H2>…</H2>`, `<UnorderedList>…</UnorderedList>`, `<Quote>…</Quote>`).
- **Validate each fragment** before concatenation: PascalCase tag, properly closed, and **no `<Section>`** (a fragment carrying a Section breaks the flat structure).
- Body-copy color: fragments should wrap prose in `<Text textColor="#39443f">` for the lede-grey voice, or leave it bare to inherit `textBaseColor` (`#161c1a`).
- Concatenate in array order. Separate with no extra markup (the fragments carry their own spacing).

### Optional-section stripping
- §7 (hero): strip the `<Image>` if `hero_image_url` is empty/absent. The URL **must be Loops-CDN-hosted** (upload flow) — an external URL 422s.
- §10 (callout): strip the whole `<Section>` if `prompt_quote` is empty/absent; strip just the attribution `<Paragraph>` if `prompt_attribution` is empty.

## 100KB cap (API) / 102KB (Gmail clip)

Measure the final assembled LMX string **after assembly, before `POST /v1/email-messages`**. If over:
1. Cap body paragraphs at 8. If over, truncate and append:
   `<Paragraph>Read the full issue at <Link href="{{website_url}}">{{website_url}}</Link>.</Paragraph>`
2. If still over, reduce key-point cards to 3 and trim descriptions.
3. If still over, **fail** with: "Issue content exceeds 100KB even after trimming. Reduce body length or move content to a web link." Do not call the API.

## Theme injection

`<Style themeId="{{theme_id}}" backgroundColor="#d2e1db" bodyColor="#e9f1ee" bodyXPadding="24" bodyYPadding="24"/>` is always the **first line**. Both surface colors are re-declared here so the mint ladder survives even if the Theme lookup returns an unexpected theme; the Theme still owns the font, heading sizes, link color, button styling and divider default.

The Theme ("PromptMetrics Sea Glass") is **created or verified via the API** at onboarding (`POST /v1/themes` if missing, else `GET /v1/themes` and capture the `id`) — see `onboarding.md` step 2 and `token-map.md` for the `ThemeStyles`-aligned body. The manual Loops UI path is the **fallback** (e.g. if the team's Content API is not enabled) — see README "One-time Loops UI setup".
