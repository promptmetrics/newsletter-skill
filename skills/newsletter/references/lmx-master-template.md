# LMX Master Template — "Field Notes" Mixed Issue

The 12-section LMX skeleton the assembler emits. `{{variable}}` placeholders are filled from the brief; `key_points[]` and `body_blocks[]` expand into repeated/concrete blocks (LMX has **no loops or conditionals**). One `<Style themeId="{{theme_id}}"/>` is always the first line. `{{theme_id}}` is captured from `GET /v1/themes` at run time; the OpenAPI contract does **not** state what value `<Style themeId="...">` accepts, so its form (opaque `data[].id` from the Themes response vs. the theme's name, e.g. `"PromptMetrics Paper"`) is decided by an empirical A/B test — do not assert one form over the other. **No footer** — Loops auto-appends the campaign footer + `{system.unsubscribe_link}`; do not author it.

All hex values are inlined per `token-map.md`. Fonts come from the Theme, not per-block.

## Skeleton

```xml
<Style themeId="{{theme_id}}" backgroundColor="#f4efe7" bodyXPadding="24" bodyYPadding="24"/>

<!-- 1. Preheader = the message `previewText` field, not an LMX block. -->

<!-- 2–3. Masthead -->
<Section blockColor="#f4efe7" padding="0 24 16 24">
  <Columns widths="28,72" stackOnMobile="true">
    <Section><Image src="{{hero_logo_url}}" alt="PromptMetrics pinwheel" width="28"/></Section>
    <Section verticalAlign="middle"><Text color="#6f665a" fontSize="13" fontFamily="monospace">{{masthead_label}} · ISSUE {{issue_number}}</Text></Section>
  </Columns>
  <Divider color="#d97757" thickness="1"/>
</Section>

<!-- 4. Kicker + Headline (exactly one italic-coral emphasis word) -->
<Section padding="16 24 8 24">
  <Text color="#a1482a" fontSize="12" fontFamily="monospace">— {{kicker}}</Text>
</Section>
<Section padding="0 24 16 24">
  <H1><Text>{{headline_before_em}}</Text><Em><Text color="#a1482a">{{emphasis_word}}</Text></Em><Text>{{headline_after_em}}</Text></H1>
</Section>

<!-- 5. Lede -->
<Section padding="0 24 16 24">
  <Paragraph color="#43403a" fontSize="18">{{lede}}</Paragraph>
</Section>

<!-- 6. Byline -->
<Section padding="0 24 24 24">
  <Text color="#6f665a" fontSize="13" fontFamily="monospace">{{author_name}} · {{issue_date}} · {{read_time}} min</Text>
</Section>

<!-- 7. Hero image — OMIT ENTIRELY if {{hero_image_url}} is empty -->
<Section padding="0 24 24 24">
  <Section blockColor="#efe8db" blockBorderRadius="18" blockBorder="1px #cabfac" padding="0">
    <Divider color="#d97757" thickness="3"/>
    <Section padding="16"><Image src="{{hero_image_url}}" alt="{{hero_image_alt}}" width="100%"/></Section>
  </Section>
</Section>

<!-- 8. Key-points card stack — EXPAND: one card <Section> per element of key_points[]
     (default 3, max 5). Repeat this block N times with {{kp_*}} filled per element. -->
<Section padding="0 24 16 24">
  <Section blockColor="#efe8db" blockBorderRadius="18" blockBorder="1px #cabfac" padding="0">
    <Divider color="#d97757" thickness="3"/>
    <Section padding="20">
      <Text color="#6f665a" fontSize="13" fontFamily="monospace">{{kp_number}}</Text>
      <H3>{{kp_title}}</H3>
      <Paragraph color="#43403a" fontSize="16">{{kp_description}}</Paragraph>
      <!-- optional link — include only if kp_link_url is non-empty -->
      <Text color="#a1482a" fontSize="13"><Link href="{{kp_link_url}}">{{kp_link_label}}</Link></Text>
    </Section>
  </Section>
</Section>

<!-- 9. Editorial body — EXPAND: concatenate body_blocks[] LMX fragments in order -->
<Section padding="8 24 24 24">
  {{body_blocks_expanded}}
</Section>

<!-- 10. Italic "prompt" callout — OMIT if {{prompt_quote}} is empty -->
<Section padding="0 24 24 24">
  <Section blockColor="#efe8db" blockBorderRadius="18" blockBorder="1px #cabfac" padding="0">
    <Section padding="0 0 0 3px" borderLeft="3px #d97757">
      <Section padding="20">
        <Quote fontFamily="serif" fontStyle="italic" color="#43403a" fontSize="18">{{prompt_quote}}</Quote>
        <!-- attribution line — include only if prompt_attribution is non-empty -->
        <Text color="#6f665a" fontSize="13" fontFamily="monospace">— {{prompt_attribution}}</Text>
      </Section>
    </Section>
  </Section>
</Section>

<!-- 11. Primary CTA card -->
<Section padding="0 24 24 24">
  <Section blockColor="#efe8db" blockBorderRadius="18" blockBorder="1px #cabfac" padding="0">
    <Divider color="#d97757" thickness="3"/>
    <Section padding="24" align="center">
      <H3>{{cta_headline}}</H3>
      <Paragraph color="#43403a" fontSize="16">{{cta_supporting}}</Paragraph>
      <Button backgroundColor="#d97757" color="#2a160e" borderRadius="999" padding="13 32" href="{{cta_url}}">{{cta_label}}</Button>
    </Section>
  </Section>
</Section>

<!-- 12. Sign-off (footer + unsubscribe auto-appended by Loops — do not author) -->
<Section padding="0 24 24 24">
  <Text color="#6f665a" fontSize="13" fontFamily="monospace">— {{author_name}}, {{company}}</Text>
</Section>
```

## Variable slots

| Slot | Source (brief) | Type | Notes |
|---|---|---|---|
| `hero_logo_url` | `hero_logo_url` (brief; sourced from the one-time `POST /v1/uploads`) | string | Dark-mode-safe variant; Step 0 fail-stops if absent |
| `masthead_label` | `masthead_label` | string | Default `"FIELD NOTES"` |
| `issue_number` | `issue_metadata.issue_number` | string | |
| `kicker` | `kicker` | string | Mono uppercase |
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
- Each element `{title, description, link_url?, link_label?}` emits the §8 card block once.
- **Default 3 cards, max 5.** If the brief has fewer than 3, ask the author whether to pad or ship fewer (do not silently pad). If more than 5, truncate to the first 5 and warn the author.
- `{{kp_number}}` = zero-padded index (`01`, `02`, …).
- Include the `<Text><Link>` line **only if** `link_url` is non-empty; otherwise omit it. If `link_url` is set but `link_label` is empty, default the label to `"Read more"`.

### `body_blocks[]` → concatenated fragments
- Each element is an LMX fragment string (`<Paragraph>…</Paragraph>`, `<H2>…</H2>`, `<UnorderedList>…</UnorderedList>`, `<Quote>…</Quote>`).
- **Validate each fragment** before concatenation: PascalCase tag, properly closed. Reject and ask the author to fix if invalid.
- Concatenate in array order inside the §9 `<Section>`. Separate with no extra markup (the fragments carry their own spacing).

### Optional-section stripping
- §7 (hero): strip the whole `<Section>` if `hero_image_url` is empty/absent.
- §10 (callout): strip the whole `<Section>` if `prompt_quote` is empty/absent; strip just the attribution `<Text>` if `prompt_attribution` is empty.

## 100KB cap (API) / 102KB (Gmail clip)

Measure the final assembled LMX string **after assembly, before `POST /v1/email-messages`**. If over:
1. Cap body paragraphs at 8. If over, truncate and append:
   `<Paragraph>Read the full issue at <Link href="{{website_url}}">{{website_url}}</Link>.</Paragraph>`
2. If still over, reduce key-point cards to 3 and trim descriptions.
3. If still over, **fail** with: "Issue content exceeds 100KB even after trimming. Reduce body length or move content to a web link." Do not call the API.

## Theme injection

`<Style themeId="{{theme_id}}" backgroundColor="#f4efe7" bodyXPadding="24" bodyYPadding="24"/>` is always the **first line**. The Theme (fonts, heading sizes, button radius, body padding, link color) is **created or verified via the API** at onboarding (`POST /v1/themes` if missing, else `GET /v1/themes` and capture the `id`) — see `onboarding.md` step 2 and `token-map.md` for the `ThemeStyles`-aligned body. The manual Loops UI path is the **fallback** (e.g. if the team's Content API is not enabled) — see README "One-time Loops UI setup".