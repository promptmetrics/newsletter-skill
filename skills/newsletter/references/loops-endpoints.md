# Loops Endpoints — Quick Reference

The exact endpoints the newsletter workflow calls, with required fields and gotchas. **Delegate these to the installed Loops API skill** — do not hand-roll `curl`/auth/retry. The Loops API skill uses `LOOPS_API_KEY` (Bearer) against base `https://app.loops.so/api`, 10 req/s. OpenAPI: `app.loops.so/openapi.yaml`.

Confirm exact tool names against the installed Loops API skill's `SKILL.md` and update this file if they differ.

## Step 0 — prerequisites
`GET /themes` → list themes; look for `name == "PromptMetrics Paper"`. If missing, stop (one-time UI setup in README).

## Step 2 — create draft campaign
`POST /campaigns`
- Body: `{ name, mailingListId? }`
- Returns: `id` (campaignId), `emailMessageId`, `emailMessageContentRevisionId` — **capture all three**.
- **400** → sending domain / `fromName` / `fromEmail` not configured in Loops. Stop; point user to README "One-time Loops UI setup" step 1.

## Step 4 — set email content
`POST /email-messages/{emailMessageId}`
- Body:
  ```json
  {
    "expectedRevisionId": "<emailMessageContentRevisionId from Step 2>",
    "subject": "...",
    "previewText": "...",
    "fromName": "...",
    "fromEmail": "...",
    "replyToEmail": "...",
    "emailFormat": "styled",
    "languageCode": "en",
    "lmx": "<assembled LMX string>",
    "contactPropertiesFallbacks": { "firstName": "there" }
  }
  ```
- **`lmx` field only — no HTML.** Unknown LMX tags are rejected; no raw-HTML escape hatch.
- `expectedRevisionId` = optimistic concurrency; reuse the revision id from Step 2 unless a prior write returned a new one.
- **≤100KB** for the `lmx` payload. The assembler enforces this before the call.
- **409** → the message was authored as MJML/legacy and can't take LMX. Should not happen for a fresh campaign; if it does, recreate the campaign.

## Step 5 — preview (Gate 1)
`POST /email-messages/{id}/preview`
- Body: `{ emails: ["author@example.com"], contactProperties: { "firstName": "Izzy" } }`
- Limit: 100 preview sends / team / 24h.
- Then STOP for Gate 1.

## Step 6a — guardian
`GET /email-messages/{id}/guardian`
- Structural checks only (see `guardian-checklist.md`). Not spam words, not live HTTP.

## Step 7 — list mailing lists
`GET /lists`
- Returns: `[{ id, name, description, isPublic }]`.
- **No contact count** in the response. Show `name` only at Gate 2; tell the user to verify the count in the Loops UI.

## Step 9 — send (Gate 2, never auto-fire)
`POST /campaigns/{campaignId}`
- Body: `{ scheduling: { method: "now" } }`
- **`scheduling` is unset in every prior call.** It is set ONLY here, ONLY after an explicit human "send" at Gate 2.
- Confirm the campaign moves Draft → Sent.

## Optional / later-phase
- `POST /uploads` — upload the logo (one-time) → returns a Loops-hosted static URL for `hero_logo_url`.
- `GET /contacts/find` → `POST /contacts/create` | `PUT /contacts/update` — no upsert (not needed for campaign sends in 1a).
- `audienceSegmentId` / inline `audienceFilter` on `POST /campaigns` — segment targeting (Phase 1b, if an "engaged" segment exists).