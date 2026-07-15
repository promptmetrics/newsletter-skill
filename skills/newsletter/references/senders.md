# Who Can Send — Allowlist

> **Placeholder.** Replace the emails below with the real team before first send. The env var `NEWSLETTER_SENDERS` (comma-separated emails) overrides this file if set.

The skill checks this allowlist at **Gate 2** (Step 8), before `POST /campaigns/{id}` with `scheduling.method:"now"`. If the current user is not authorized, the skill **refuses to send** even if the user says "send".

Two roles. If your team uses the same people for both, list them under `senders:` only and leave `approvers:` empty (an empty `approvers:` section means anyone can approve the preview at Gate 1, but only `senders:` can fire).

## approvers
# Users who may approve the preview at Gate 1. Empty = anyone may approve.
you@example.com

## senders
# Users who may confirm the send at Gate 2 (the irreversible step).
you@example.com

---

## How the current user is identified

The skill resolves the current user's email from, in order:
1. `NEWSLETTER_SENDER` env var (if set — explicit override for this session),
2. git config `user.email` for the current repo,
3. the Claude Code session identity.

If it cannot resolve an email, it treats the user as **not authorized** and asks them to set `NEWSLETTER_SENDER` or be added to this file.

## Enforcement notes

- This is **team-discipline enforcement, not cryptographic** and not Loops-side RBAC. A determined user could edit this file. It exists to make the irreversible send a deliberate, attributed act.
- The skill never reads or logs `LOOPS_API_KEY` (that's handled by the Loops API skill). This file holds only emails.
- Log who approved and who sent (email + timestamp) in the session output for audit.