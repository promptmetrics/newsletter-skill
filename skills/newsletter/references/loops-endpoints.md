# Loops Endpoints — Quick Reference

The exact endpoints the newsletter workflow calls, with required fields and gotchas. **Delegate these to the installed Loops API skill** — do not hand-roll `curl`/auth/retry. The Loops API skill uses `LOOPS_API_KEY` (Bearer) against base `https://app.loops.so/api`, 10 req/s. **Every path below is `/v1/…` relative to that base** (e.g. `GET /v1/themes` → `https://app.loops.so/api/v1/themes`). OpenAPI: `app.loops.so/openapi.yaml`.

**All calls use `$LOOPS_API_KEY` from the environment**, populated by the guarded keychain-read line that `loops-key.sh install-line` writes to `~/.zprofile` and `~/.zshrc` at shell startup (see `onboarding.md`). The read command is platform-specific: `security` on macOS, `secret-tool lookup …` or `pass show …` on Linux. **Never extract the key with `loops-key.sh get` at runtime** — the auto-mode classifier blocks keychain-secret extraction and it leaks the key into the transcript. If `LOOPS_API_KEY` is unset, stop and tell the user to restart their shell; do not run `get`.

Confirm exact tool names against the installed Loops API skill's `SKILL.md` and update this file if they differ.

## Auth — verify the API key (run this at Step 0, once `LOOPS_API_KEY` is in env)
`GET /v1/api-key` → `{ success: true, teamName: "…" }`.
Use this to confirm the key is valid before doing anything else. It runs at **Step 0 of the first real run, after the post-onboarding shell restart** (the key is not in env during the onboarding session itself, so validation cannot run there). **401** → the key is wrong or revoked; have the user re-enter it via `${CLAUDE_SKILL_DIR}/scripts/loops-key.sh set`, then re-run `${CLAUDE_SKILL_DIR}/scripts/loops-key.sh install-line` (idempotent) and `exec $SHELL -l`, and re-run. Do not proceed past Step 0 until this returns 200.

## Step 0 — prerequisites
`GET /v1/themes` → list themes; look for `name == "PromptMetrics Paper"`. If missing, stop (one-time UI setup in README).

## Step 2 — create draft campaign
`POST /v1/campaigns`
- Body: `{ name, mailingListId? }`
- Returns: `id` (campaignId), `emailMessageId`, `emailMessageContentRevisionId` — **capture all three**.
- **400** → sending domain / `fromName` / `fromEmail` not configured in Loops. Stop; point user to README "One-time Loops UI setup" step 1.

## Step 4 — set email content
`POST /v1/email-messages/{emailMessageId}`
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
`POST /v1/email-messages/{id}/preview`
- Body: `{ emails: ["author@example.com"], contactProperties: { "firstName": "Izzy" } }`
- Limit: 100 preview sends / team / 24h.
- Then STOP for Gate 1.

## Step 6a — guardian
`GET /v1/email-messages/{id}/guardian`
- Structural checks only (see `guardian-checklist.md`). Not spam words, not live HTTP.

## Step 7 — list mailing lists
`GET /v1/lists`
- Returns: `[{ id, name, description, isPublic }]`.
- **No contact count** in the response. Show `name` only at Gate 2; tell the user to verify the count in the Loops UI.

## Step 9 — send (Gate 2, never auto-fire)
`POST /v1/campaigns/{campaignId}`
- Body: `{ scheduling: { method: "now" } }`
- **`scheduling` is unset in every prior call.** It is set ONLY here, ONLY after an explicit human "send" at Gate 2.
- Confirm the campaign moves Draft → Sent.

## Optional / later-phase
- **Uploads (logo)** — three-step flow, delegate to the Loops API skill:
  1. `POST /v1/uploads` → returns a `presignedUrl` (and an upload `id`).
  2. `PUT` the file bytes to the `presignedUrl`.
  3. `POST /v1/uploads/{id}/complete` → returns the public hosted URL. Store that as `hero_logo_url` (one-time).
- `GET /v1/contacts/find` → `POST /v1/contacts/create` | `PUT /v1/contacts/update` — no upsert (not needed for campaign sends in 1a).
- `audienceSegmentId` / inline `audienceFilter` on `POST /v1/campaigns` — segment targeting (Phase 1b, if an "engaged" segment exists).