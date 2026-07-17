# Pre-Send Guardian Checklist

Three checks run in Step 6, after Gate 1 approval, before the list-confirm + Gate 2. Results consolidate into the Gate 2 summary. **Do not auto-proceed past failures** — present them and have the author fix or explicitly acknowledge.

## 6a. Loops Guardian (delegate to the Loops API skill)

`GET /v1/email-messages/{id}/guardian` → `{errors:[GuardianRule], warnings:[GuardianRule]}`

**Covers — the `GuardianRule.rule` enum (variables / fallbacks / links):**
- `missingButtonHrefs` / `invalidButtonHrefs` — `<Button>` missing or malformed `href`
- `missingLinkHrefs` / `invalidLinkHrefs` — `<Link>` missing or malformed `href`
- `missingFallbackContactProperties` — `{contact.*}` used without a `contactPropertiesFallbacks` entry
- `unsupportedContactProperties` — `{contact.*}` reference not recognized by the API
- (other rules in the `rule` enum as Loops adds them — variables, fallbacks, links only)

**Two severities, two outcomes:**
- `errors[]` → **BLOCKING.** Publishing is blocked; map to **FAIL** at Gate 2. Author must fix + re-run Step 6.
- `warnings[]` → **advisory.** Map to **PASS with warnings** at Gate 2; author acknowledges.

**Does NOT cover (this is why the skill adds 6b + 6c):**
- ❌ Spam-trigger words
- ❌ Live HTTP broken-link verification (Guardian checks href structure, not whether the URL actually returns 2xx)
- ❌ Structural LMX validity — enforced at write time (`POST /v1/email-messages/{id}` returns 422 on unparseable LMX, 413 over 100KB), so it cannot reach Guardian in a broken state

## 6b. Spam-trigger-word scan (skill does this)

- **Input:** assembled `subject` + `previewText` + body text (LMX tags stripped, text nodes concatenated).
- **Process:** lowercase, match against `references/spam-terms.md` (read at scan time), also match the brief's `tone.must_avoid[]`.
- **Output:** flagged terms with category + ±20-char context + location (subject / preview / body). `must_avoid` hits flagged with higher salience.
- **Severity:** **advisory.** Context-dependent ("free" in "free trade" is not spam). Author acknowledges or revises. Not a hard block.

## 6c. Live HTTP broken-link check (skill does this)

- **Input:** all URLs extracted from the assembled LMX — `href="..."` (from `<Link>`, `<Button>`, `<Section href>`) and `src="..."` (from `<Image>`).
- **Process:** dedupe → HEAD each → on 405 fall back to GET → 10s timeout per URL → max ~3 concurrent. Flag 4xx/5xx and timeouts. 3xx that resolves to 2xx is OK (noted, not flagged); 3xx chains ending in 4xx/5xx are flagged.
- **Output:** per-URL status: OK (2xx) / redirected (3xx→2xx) / BROKEN (4xx/5xx/timeout).
- **Severity:** **advisory, harder than spam.** A broken CTA link means the primary action fails — recommend fixing before sending to the list. Still not a hard block (staging URLs are legitimate in a preview). Author fixes or acknowledges.

## Gate 2 presentation format

```
Pre-send checks:
  Loops Guardian:  {PASS | PASS with warnings: <rules> | FAIL: <rules>}
  Spam scan:       {PASS | N warnings: <flagged terms>}
  Broken links:    {PASS | N broken: <urls + statuses>}
```

Guardian outcomes map from the response shape: `errors[]` → **FAIL** (blocking, fix + re-run Step 6); `warnings[]` → **PASS with warnings** (author acknowledges); empty → **PASS**. If spam flags → advisory. If links broken → recommend fixing. The author explicitly acknowledges each non-PASS check (or fixes + re-runs Step 6) before saying "send" at Gate 2.