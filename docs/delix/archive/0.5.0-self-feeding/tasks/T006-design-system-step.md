# T006: Conditional design-system step (DESIGN.md) in the spec/architect/qa flow

| id | size | tier | role | wave | status |
|---|---|---|---|---|---|
| T006 | S | 2 | docs | 3 | open |

**Goal (1 sentence):** UI work gets one shared `DESIGN.md`: the spec step produces it when missing, the architect cites
it on UI cards, and qa flags non-token values. · **Spec:** none (size S, request approved in chat 2026-11-03;
independent of `docs/delix/SPEC.md`)

## Files (disjoint ownership; do not touch files owned by another card)
- Modify: `skills/spec/SKILL.md` (§1: new item 5 after line 20 · §2: one bullet after line 27)
- Modify: `agents/architect.md` (job A: append question (7) to lines 19–20 · job B: one sentence after line 30)
- Modify: `agents/qa.md` (new item 6 after item 5, line 28)
- Modify: `templates/spec-M.md` (one line after the §4 table, line 27)
- Modify: `templates/spec-L.md` (extend line 11, §5 Architecture)
- Test: none. Text-only card; no test added or changed.

## Interfaces
- Consumed: `skills/implement/roles/ui-ux.md:2` ("Design system first: from `DESIGN.md` / tokens when they exist…") —
  read-only, do not change.
- Produced: the artefact `DESIGN.md` at the **target repo root** with sections: stack (framework, styling, icons) · type
  scale (display/body font, H1–small sizes) · colour tokens (primary/secondary/accent; 60-30-10 only as a starting
  heuristic; contrast ≥ 4.5:1) · spacing scale · core components · responsive breakpoints.

## Global Constraints (verbatim from the request)
- Trigger only when the work touches UI (new screen/component/visual change) AND the target repo has no `DESIGN.md`
  (nor equivalent token file). Non-UI work: nothing changes, no extra question.
- If the Impeccable plugin is installed, use its DESIGN.md / design-system capability; otherwise a short grill (≤ 3
  questions, one at a time, each with `My pick: … because …`).
- If `DESIGN.md` exists, the spec links it and does not regenerate.
- Keep each addition a few lines; match the surrounding style (terse bullets, English labels); leave every "Reply in the
  user's language" rule untouched.
- Out of scope: `skills/implement/roles/ui-ux.md`, new agents, new skills, hooks, README/CHANGELOG/version bump.

## Steps
0. No failing-test-first step: this card changes text only; grep evidence (verification below) replaces it.
1. `skills/spec/SKILL.md` §1, new item 5 (suggested wording, may be tightened): "**Design system (UI work only):** if the
   work adds a screen/component or changes visuals AND the repo has no `DESIGN.md` (nor a token file such as
   `tokens.*`, a CSS-variables theme or a Tailwind theme config), produce `DESIGN.md` at the repo root before gate 1:
   <the six sections from Interfaces>. If the Impeccable plugin is installed (its skill is visible), use its DESIGN.md /
   design-system capability; otherwise a short grill, ≤ 3 questions, one at a time, each with `My pick`. If `DESIGN.md`
   exists, link it, do not regenerate. Non-UI work: skip silently." In §2 add the bullet: "- UI work: the spec links
   `DESIGN.md` (template line "Design system")."
2. `templates/spec-M.md`, after the §4 table: `Design system (UI work only, optional): link to \`DESIGN.md\`; delete
   this line otherwise.` `templates/spec-L.md` line 11: append `; design system (UI work only): link to \`DESIGN.md\``.
3. `agents/architect.md` job A: add "(7) a UI spec (screen, component, visual change) without a `DESIGN.md` link is a
   finding." Job B: add "Every ui-ux card, and every frontend card with a visual change, puts `DESIGN.md` in Global
   Constraints: its tokens only, no new colour/font/spacing value."
4. `agents/qa.md` new item 6: "**Design tokens** (ui-ux / frontend diffs only): a hard-coded colour, font or spacing
   value not present as a `DESIGN.md` token is a P2 finding: `file:line` + nearest token. Do not flag the token
   definitions themselves (`DESIGN.md`, token files, CSS custom-property / theme definition files). If the repo has no
   `DESIGN.md`, skip this item."
5. Run the verification below. Commit only these 5 files by name: `T006: conditional DESIGN.md step in spec, architect,
   qa, spec templates`; open a PR whose body includes "How I tested" (commands + output).

## Verification command → expected output
1. `for t in tests/*_tests.sh; do bash "$t" || exit 1; done` → every script ends with `ALL PASSED`
2. `claude plugin validate .` → passes, no error
3. `grep -n "DESIGN.md" skills/spec/SKILL.md agents/architect.md agents/qa.md templates/spec-M.md templates/spec-L.md`
   → ≥ 1 line per file (5 files)
4. `grep -n "Impeccable" skills/spec/SKILL.md` → ≥ 1 line · `grep -c "Reply in the user's language" skills/spec/SKILL.md`
   → `1` (unchanged)
5. `git diff --stat main` → exactly the 5 files above

## Review Focus
- The conditional must not trigger on non-UI work (no question, no added line in the spec when there is no screen,
  component or visual change).
- The Impeccable path degrades gracefully when the plugin is not installed (falls back to the ≤ 3-question grill, no
  failure/stall).
- The qa rule must not flag values that are themselves token definitions (`DESIGN.md`, token files, CSS-variable/theme
  files), and skips repos without `DESIGN.md`.
- Existing `DESIGN.md` / token file is linked, never regenerated.
- Additions stay short; the spec skill does not bloat.

## Don'ts
- Untouchable: `hooks/hooks.json`, `scripts/*_gate.py`, `scripts/common.py`, `.github/**`, `.claude-plugin/**`,
  `docs/delix/delix.json`, `docs/delix/**`, `tests/**`, `evals/**`, `skills/implement/roles/ui-ux.md`, `README*`,
  `CHANGELOG.md`.
- Do not touch files owned by T001–T005 (`scripts/feedback*`, `scripts/bash_gate.py`, `scripts/write_gate.py`,
  `skills/feedback/**`, `skills/close|review|start/SKILL.md`, `.github/**`, `README*`, `CHANGELOG.md`).
- If a test looks wrong, **do not change it**: stop, explain with `NEEDS_CONTEXT` in the report.
- No new dependency, agent, skill or hook.

## Report contract
At the end, `.delix/report.md` (≤ 1–2K tokens): `DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED` · evidence (each of
the 5 verification commands' output) · PR number · assumptions · remaining work. Do not read the whole plan; only this
card and the 5 files.

## Review findings (filled by the orchestrator)
- Round 1: …
