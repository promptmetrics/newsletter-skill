# Loops Endpoints — Quick Reference

The exact endpoints the newsletter workflow calls, with required fields and gotchas. **Delegate these to the installed Loops API skill** — do not hand-roll `curl`/auth/retry. The Loops API skill uses `LOOPS_API_KEY` (Bearer) against base `https://app.loops.so/api`, 10 req/s. **Every path below is `/v1/…` relative to that base** (e.g. `GET /v1/themes` → `https://app.loops.so/api/v1/themes`). OpenAPI: `app.loops.so/openapi.json`.

**All calls use `$LOOPS_API_KEY` from the environment**, populated by the guarded keychain-read line that `loops-key.sh install-line` writes to `~/.zprofile` and `~/.zshrc` at shell startup (see `onboarding.md`). The read command is platform-specific: `security` on macOS, `secret-tool lookup …` or `pass show …` on Linux. **Never extract the key with `loops-key.sh get` at runtime** — the auto-mode classifier blocks keychain-secret extraction and it leaks the key into the transcript. If `LOOPS_API_KEY` is unset, stop and tell the user to restart their shell; do not run `get`.

Confirm exact tool names against the installed Loops API skill's `SKILL.md` and update this file if they differ.

## Auth — verify the API key (run this at Step 0, once `LOOPS_API_KEY` is in env)
`GET /v1/api-key` → `{ success: true, teamName: "…" }`.
Use this to confirm the key is valid before doing anything else. It runs at **Step 0 of the first real run, after the post-onboarding shell restart** (the key is not in env during the onboarding session itself, so validation cannot run there). **401** → the key is wrong or revoked; have the user re-enter it via `${CLAUDE_SKILL_DIR}/scripts/loops-key.sh set`, then re-run `${CLAUDE_SKILL_DIR}/scripts/loops-key.sh install-line` (idempotent) and `exec $SHELL -l`, and re-run. Do not proceed past Step 0 until this returns 200.

## Step 0 — prerequisites
`GET /v1/themes` → paginated `{ pagination, data: [{ id, name, styles, isDefault, createdAt, updatedAt }] }`. **Paginated**: `perPage` 10–50, advance via `pagination.nextCursor`. Loop pages until a theme with `name == "PromptMetrics Paper"` is found or pages are exhausted before concluding it is missing. If missing, stop (one-time UI setup in README).

**Capture the theme id.** `data[].id` is an opaque value (e.g. `cm_…`), not a slug. When `name == "PromptMetrics Paper"`, record its `id` as `<themeId>` — it is needed for `POST /v1/themes/{themeId}` reconciliation in M3, and it is one candidate for `<Style themeId="…" />` in the assembled LMX. The OpenAPI does not state what value `<Style themeId>` accepts (llms-full.txt's only example uses the theme *name* `"default"`, not an opaque id); the correct form for this template is decided by an empirical A/B test (opaque id vs. theme name `"PromptMetrics Paper"`), not asserted here.

## Step 2 — create draft campaign
`POST /v1/campaigns` → **201** `{ id, name, status: "Draft", emailMessageId, emailMessageContentRevisionId }`.
- Body: `{ name, mailingListId? }`
- Returns: `id` (campaignId), `emailMessageId`, `emailMessageContentRevisionId` — **capture all three**.
- **400** → sending domain / `fromName` / `fromEmail` not configured in Loops. Stop; point user to README "One-time Loops UI setup" step 1.
- **401** → key is invalid, OR the team Content API is not enabled (see "Content API not enabled" note below).

## Step 4 — set email content
`POST /v1/email-messages/{emailMessageId}`
- Body:
  ```json
  {
    "expectedRevisionId": "<emailMessageContentRevisionId from Step 2>",
    "subject": "...",
    "previewText": "...",
    "fromName": "...",
    "fromEmail": "fieldnotes",
    "replyToEmail": "...",
    "emailFormat": "styled",
    "languageCode": "en",
    "lmx": "<assembled LMX string>",
    "contactPropertiesFallbacks": { "firstName": "there" }
  }
  ```
- **`fromEmail` is the USERNAME ONLY** (e.g. `fieldnotes` — no `@`, no domain); the team's sending domain is appended automatically by Loops. Do not confuse this with the **Loops UI → Settings → Domains** sending-address config (`fieldnotes@<sending-domain>`), which is a separate, UI-only prerequisite (README "One-time Loops UI setup" step 1) and is not set via this API field.
- **`lmx` field only — no HTML.** Unknown LMX tags are rejected; no raw-HTML escape hatch.
- `expectedRevisionId` = optimistic concurrency; reuse the revision id from Step 2 unless a prior write returned a new one.
- **≤100KB** for the `lmx` payload. The assembler enforces this before the call.
- **409** has four distinct causes — do NOT recreate the campaign blindly (a stale-revision 409 would discard a valid draft):
  1. **stale `contentRevisionId`** → re-fetch via `GET /v1/email-messages/{emailMessageId}`, read the fresh `contentRevisionId`, and retry with that value.
  2. **not draft** (campaign already sent/locked) → recreate the campaign from Step 2.
  3. **content unparseable** → fix the LMX and retry; if it cannot be repaired in place, recreate the campaign.
  4. **MJML/legacy message** → recreate the campaign (a fresh draft is always LMX, never MJML).
- **413** → `lmx` payload exceeds 100KB; trim content and retry (the assembler should prevent this pre-call).
- **422** → LMX failed to compile; fix the LMX and retry.
- **400** → invalid body; fix and retry.
- **404** → `emailMessageId` not found.
- **401** → key is invalid, OR the team Content API is not enabled (see "Content API not enabled" note below).

## Step 5 — preview (Gate 1)
`POST /v1/email-messages/{id}/preview` → 200 `{ id }`.
- Body: `{ emails: ["author@example.com"], contactProperties: { "firstName": "Izzy" } }`
- Limit: a daily per-team preview limit applies (**HTTP 429** when exceeded); the exact quota is in the Loops docs.
- Then STOP for Gate 1.

## Step 6a — guardian
`GET /v1/email-messages/{id}/guardian`
- Structural checks only (see `guardian-checklist.md`). Not spam words, not live HTTP.

## Step 7 — list mailing lists
`GET /v1/lists`
- Returns: `[{ id, name, description, isPublic }]`.
- **No contact count** in the response. Show `name` only at Gate 2; tell the user to verify the count in the Loops UI.

## Step 9 — send (Gate 2, never auto-fire)
`POST /v1/campaigns/{campaignId}` → 200 updated.
- Body: `{ scheduling: { method: "now" } }`
- **`scheduling` is unset in every prior call.** It is set ONLY here, ONLY after an explicit human "send" at Gate 2.
- Confirm the campaign moves Draft → Sent.
- **409** → campaign is not in draft (already sent/locked); recreate from Step 2 if a re-send is genuinely needed.
- **404** → campaign not found.

## Content API not enabled (general note)
A **401 on `/v1/campaigns`, `/v1/email-messages/*`, `/v1/themes`, or `/v1/uploads` with an otherwise-valid key** means the team's **Content API is not enabled** — a distinct condition from the Step 0 `GET /v1/api-key` 401 (which means the key itself is wrong/revoked). If Step 0 passed but later calls 401, point the user to **Loops → Settings** to enable the Content API for the team; do not re-prompt for the key.

## Optional / later-phase
- **Uploads (logo)** — three-step flow, delegate to the Loops API skill:
  1. `POST /v1/uploads` — body `{ contentType, contentLength }`. Allowed MIME: `image/jpeg | image/png | image/gif | image/webp`. Hard cap: **4,000,000 bytes (4 MB)**. → 200 `{ emailAssetId, presignedUrl }`. **400** → unsupported `contentType`. **413** → content over the size cap. **401** → invalid key or Content API not enabled (see note above). (llms-full-txt mentions a 429 for this endpoint, but it is **not wired to `POST /v1/uploads` in OpenAPI v1.19.0**; treat any 429 as ambiguous and consult the Loops docs.)
  2. `PUT` the file bytes to the `presignedUrl` — the request **must echo the same `Content-Type` and `Content-Length`** used in the `POST` body.
  3. `POST /v1/uploads/{emailAssetId}/complete` (`{id}` is the `emailAssetId` from step 1) → 200 `{ emailAssetId, finalUrl }`. Store `finalUrl` as `hero_logo_url` (one-time).
- `GET /v1/contacts/find` → `POST /v1/contacts/create` | `PUT /v1/contacts/update` — no upsert (not needed for campaign sends in 1a).
- `GET /v1/audience-segments` — confirmed queryable; use it to discover segment ids for Phase 1b segment targeting on `POST /v1/campaigns`.
- Other Phase 1b tools (discovery / hygiene, not yet wired into the workflow): `GET /v1/contacts/properties` (discover personalization fields beyond `contact.firstName`); `POST /v1/contacts/delete` (list hygiene).