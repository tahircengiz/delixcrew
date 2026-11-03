# SPEC — <feature name>

> Size: **M** · Tier: <1|2|3> · Date: <YYYY-MM-DD> · Status: draft | **approved (gate 1, <date>)**
> Source: grill decisions K<n>–K<m> (below). Keep it short: a spec longer than half the code is a transcript, not a plan.

## 1. Goal (2–3 sentences)
Who, what, why. What success means.

## 2. Out of scope
- …

## 3. Requirements (testable)
### Requirement: REQ-1 <name>
The system SHALL …
#### Scenario: <name>
- WHEN …
- THEN …

### Requirement: REQ-2 <name>
…

## 4. Interface contracts
| Kind | Name | Signature / shape | Consumer |
|---|---|---|---|
| endpoint | `POST /api/x` | request / response body | frontend |
| function | `module.fn(a: int) -> B` | … | … |
| template context | `templates/x.html` | `{ "items": [...] }` | … |

Design system (UI work only; delete this line otherwise): link to `DESIGN.md`.

## 5. Data and migration
Changed tables/fields; if a migration is needed, its step and rollback.

## 6. Security note
Protected paths touched (Tier 3 means 🔐 human approval); authorization, input validation, secrets.

## 7. Acceptance criteria (DoD)
- [ ] A passing test for every REQ; verification command: `<command>` → `<expected>`
- [ ] Tier ≥ 2: `qa` ACCEPT; Tier 3: `security` CLEAN + human approval
- [ ] "How I tested" in the PR body

## 8. Open questions
- No `[NEEDS CLARIFICATION: …]` may remain; ask before gate 1 if any does.

## 9. Decisions
- K<n>: …
