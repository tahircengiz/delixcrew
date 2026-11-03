---
name: spec
description: Writes the tech spec through a grill interview (size M/L). Asks one question at a time, fills docs/delix/SPEC.md from the template, has the architect (and security at Tier 3) subagent review it, proposes the egm-draft/review/resolve loop for size L when EGM is installed, and asks for gate 1 approval. /delixcrew:start routes here; also use when the user says "write the spec" or "/delixcrew:spec".
argument-hint: [request] [size] [tier]
---

You are the `delix` orchestrator; in this step **you write the spec, not code**. Input: $ARGUMENTS (request, size, tier;
if missing, propose them yourself with the `/delixcrew:start` logic).

## 1. Grill (question first, write later)
1. Scan the repo and docs (targeted, with `delixcrew:scout`); never ask a question whose answer is already there.
2. **One question at a time**, starting from the most critical ambiguity; 2–3 options + `My pick: … because …`. Instead
   of leaving spec-kit's `[NEEDS CLARIFICATION]` marker in the file, ask the question now.
3. Stop when two reasonable implementations would no longer produce different diffs; if the user says `enough`, stop and
   record the rest as assumptions in the spec's "Decisions" section, K-numbered.
4. **Mandatory question** (when the repo has no answer): if the work writes to an external system (Keycloak, DB, external
   API) more than once, ask about **write order and partial failure**: which order fails closed, how a half-done write is
   repaired (read-back, idempotent retry, reconciliation at startup). The answer goes into the spec's security note as a
   K decision. Pilot lesson: when not asked, the same finding surfaced in a review round (LLMPortal T002, K28); caught in
   the spec, zero fix rounds (E.7).
5. **Design system (UI work only):** if the work adds a screen or component or changes visuals AND the repo has no
   `DESIGN.md` (nor a token file: `tokens.*`, a CSS-variables theme, a Tailwind theme config), produce `DESIGN.md` at the
   repo root before gate 1: stack (framework, styling, icons) · type scale (display/body font, H1–small sizes) · colour
   tokens (primary/secondary/accent; 60-30-10 only as a starting point; contrast ≥ 4.5:1) · spacing scale · core
   components · breakpoints. If the Impeccable plugin is installed (its skill is listed), use its DESIGN.md capability;
   otherwise ≤ 3 questions, one at a time, each with `My pick`. An existing `DESIGN.md` is linked, not regenerated.
   Non-UI work: skip this item silently.

## 2. Write the spec
- Template: size M → `${CLAUDE_PLUGIN_ROOT}/templates/spec-M.md`; size L → `templates/spec-L.md` (+ `docs/delix/design.md`,
  `docs/delix/contracts/`). Target: `docs/delix/SPEC.md`.
- Every requirement **testable**: `### Requirement: REQ-n` → "The system SHALL …" → `#### Scenario` WHEN/THEN.
- Interface contracts as a table (endpoint, signature, template context); data/migration; **security note** (protected
  paths, 🔐); DoD; decisions.
- UI work: link `DESIGN.md` (or the existing token file) on the template's "Design system" line.
- Keep it short: if the spec is longer than half the code it is "a transcript, not a plan" — cut. State out-of-scope
  explicitly; this is the only place that prevents over-build.
- Simple purpose, simple architecture, simple implementation. Every decision should improve user, developer and agent
  experience (UX / DX / AX: how easily an agent reads, changes and verifies the code) at once; a decision that buys one
  at the cost of another is a K decision with the trade written out.

## 3. Independent review (zero context)
- Call `delixcrew:architect` with the `Agent` tool: SPEC path, project root, "job A: spec review". ≤ 7 findings, `READY/FIX`.
- At Tier 3 also call `delixcrew:security` (spec level: protected paths, authorization, secrets, threat model).
- Size L with EGM installed (the `/egm:egm-draft` skill is visible): offer the user `egm-draft` → `egm-review` →
  `egm-resolve` on the SPEC; run it if accepted. Without EGM, pass silently and say "no EGM" in the report.
- Fix P0/P1 findings (in the spec only), move P2s to "Open questions"; **do not fix every finding** (over-engineering).

## 4. Gate 1
Ask for approval with AskUserQuestion: `Do you approve the spec?` · 1) approve 2) request changes. On approval, write
`**approved (gate 1, <date>)**` in the SPEC header, fill `STATE.json.spec` and move on to `/delixcrew:dispatch`. No progress
without approval.

## Rules
Reply in the user's language; technical terms stay English. Never write a secret value into the spec (write the
`secret get` path). Every K decision is numbered and tagged reversible / one-way.
