# Newsletter Skill — Build Plan & Handoff

**For:** PromptMetrics team
**Status:** Planning complete, ready to scaffold
**Purpose:** Hand-off doc to continue the build in Claude Code. Captures the where-to-build decision, repo layout, phasing, and open decisions.

---

## The idea (recap)

A skill that takes a newsletter brief, builds a mobile-friendly newsletter in Loops.so, sends a preview to the author's inbox, and — once approved — shows the available Loops mailing lists, asks which one to send to, and sends it. Two human gates: approve the preview, confirm the send.

Every step maps to a real Loops API endpoint (Campaign API + LMX, shipped for coding agents). We sit on Loops' shipped SDK/skill/MCP and build the opinionated PromptMetrics workflow on top — we do not hand-roll raw API calls.

---

## Decision 1: Build in a NEW repo, not inside the PromptMetrics OS project

**Recommendation: new standalone repo.** Confirmed direction.

**Why a separate repo wins.** This is a shippable tool, not a document. It has its own release cycle, a `LOOPS_API_KEY` secret, network dependencies, and it gets *installed* onto the whole team's machines (Claude Code now, Cowork later). That profile — versioned, distributable, secret-bearing, multi-user — is what a dedicated repo is for. PromptMetrics OS is a knowledge/context store; mixing a deployable skill into it couples two things with different lifecycles and access needs.

A separate repo lets you:

- Package it as a plugin and distribute via git install, so teammates get updates by pulling, not copy-paste.
- Scope secrets and CI to just this tool.
- Tag releases (Phase 1a → 1b → 2) without churning the OS repo history.

**What stays in PromptMetrics OS.** The structured brief schema (the "backbone"). It's the first instance of "PromptMetrics OS as structured docs" and it's org data. Split it:

- **New repo** = the skill (workflow logic, gap-collection, guardian check, Loops calls).
- **PromptMetrics OS** = the brief schema / required-fields definition, plus the Loops theme spec once designed.

The skill *reads* the schema as an input contract. One source of truth for "what a valid brief is" so the skill and the humans filling out briefs never drift.

---

## Decision 2: Distribution = standalone plugin repo

One repo = one installable plugin (skill + any bundled MCP config). Team installs/updates via git. Cleanest for a single tool with its own release cycle. (Chosen over a shared marketplace repo or a bare skill folder.)

---

## Repo layout

**Repo name:** `promptmetrics/newsletter-skill` (or `loops-newsletter`)

```
newsletter-skill/
├── .claude-plugin/
│   └── plugin.json            # name, version, description
├── skills/
│   └── newsletter/
│       ├── SKILL.md           # the workflow: brief→draft→preview→approve→send
│       └── references/
│           ├── brief-schema.md # MIRROR of the OS schema (OS is canonical)
│           ├── lmx-notes.md    # Loops markup gotchas
│           └── guardian.md     # pre-send safety checklist
├── .env.example               # LOOPS_API_KEY=  (never the real key)
├── .gitignore                 # .env, secrets
└── README.md                  # install + who-can-send policy
```

**Schema handling.** Source of truth stays in PromptMetrics OS. The repo keeps a *mirror* in `references/brief-schema.md` so the skill is self-contained and installable without OS access. Note in both places that OS is canonical, and sync on change. Copy with a pointer back — do not fork the definition.

---

## Phasing (mapped to the repo)

- **Phase 1a — prove the loop (`v0.1`).** `SKILL.md` implements interview → brief → draft → preview → send, sitting on Loops' own SDK/skill/MCP. No Notion dependency. Ships fastest, validates the approve-and-send gates end to end.
- **Phase 1b — add the backbone (`v0.2`).** Wire in the Notion brief-DB read + gap-collection logic + PromptMetrics theme.
- **Phase 2 — Cowork (`v0.3`).** Same skill, add a Cowork wrapper/entry so non-coders can run it.

---

## Brief input model (layered, not one source)

- **Structured Notion brief** = the backbone (enforces team consistency; lives in the shared wiki; versioned).
- **Freeform paste** = fallback for quick one-offs.
- **Fathom call** = optional enrichment when a brief references a call — never the primary source (transcripts are messy).
- **Interview mode** = when there's no brief, Claude interviews the author, builds one, then writes it back into the Notion brief database.
- **Gap-driven collection:** whatever the source, the skill checks the brief against required fields and only asks about what's missing. Full Notion brief → zero questions. Two-line paste → a few targeted questions. Nothing → full interview.

---

## Safety / human gates

- **Gate 1:** approve the preview.
- **Gate 2:** confirm the send (the one irreversible step). Show the list name + contact count and wait for an explicit "send." Never auto-fire.
- **Pre-send:** run Loops' Guardian check (spam triggers / broken links) right before the send gate.

---

## Open decisions that block the build (not the repo)

The repo layout doesn't depend on these, but **Phase 1a does**:

1. **Required brief fields.** Starting proposal (~6): target list/audience, goal, 3–5 key points, one CTA + link, tone / must-avoid. → Confirm and lock; this becomes the gap-collection contract.
2. **Who's allowed to approve and send.** Becomes a hard check in the send gate + a line in the README. Any permission boundaries?
3. **Loops API surface — verify before writing `SKILL.md`.** Confirm whether you're building *on* Loops' shipped agent skill vs. wrapping their MCP. A ~10-min check of the actual current API surface decides how thin your layer is. Build on what shipped, not the brainstorm's description of it.

## Other open questions (from team brainstorm)

- Interview-first MVP (1a) vs. Notion-first — which gets a usable tool faster? (Plan leans 1a.)
- Who designs the Loops theme and what's our newsletter look? (Gates the "beautiful" part.)
- Do we need segment targeting (e.g. "engaged contacts") or are raw mailing lists enough?
- Expected cadence and volume? (Affects whether the build is worth it.)

## Flag to resolve

Org runbooks/wiki are **Obsidian**, but the brief backbone is specced as a **Notion** database. Looks deliberate (versioned Notion DB vs. Markdown wiki) — confirm it's intentional, because it changes where the schema source-of-truth lives.

---

## Suggested next steps in Claude Code

1. Verify the current Loops Campaign API / agent-skill surface (do this first — decides the layer thickness).
2. Scaffold the repo (files above, ready to `git init`).
3. Draft `SKILL.md` for Phase 1a.
4. Lock the 6 required brief fields + the who-can-send policy.

## Note for the Claude Code session

Several connectors relevant to later phases (Notion, Fathom, Gmail, Slack) require OAuth authorization before their tools work. Authorize them via claude.ai connector settings, or `claude mcp` / `/mcp` in an interactive session, before Phase 1b.
