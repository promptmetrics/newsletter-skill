# Pre-Send Guardian Checklist

Three checks run in Step 6, after Gate 1 approval, before the list-confirm + Gate 2. Results consolidate into the Gate 2 summary. **Do not auto-proceed past failures** — present them and have the author fix or explicitly acknowledge.

## 6a. Loops Guardian (delegate to the Loops API skill)

`GET /email-messages/{id}/guardian`

**Covers (structural only):**
- Link integrity against the email's known link set
- Merge-variable / `{contact.*}` references resolve
- Required fallbacks present (e.g. `contactPropertiesFallbacks`)
- Structural LMX validity

**Does NOT cover (this is why the skill adds 6b + 6c):**
- ❌ Spam-trigger words
- ❌ Live HTTP broken-link verification (Guardian checks structure, not whether the URL actually returns 2xx)

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
  Loops Guardian:  {PASS | FAIL: <issues>}
  Spam scan:       {PASS | N warnings: <flagged terms>}
  Broken links:    {PASS | N broken: <urls + statuses>}
```

If Guardian fails → structural issue (missing fallback, broken variable, invalid LMX); recommend fixing before send. If spam flags → advisory. If links broken → recommend fixing. The author explicitly acknowledges each non-PASS check (or fixes + re-runs Step 6) before saying "send" at Gate 2.