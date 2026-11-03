# T<nnn> — <short title>

| id | size | tier | role | wave | status |
|---|---|---|---|---|---|
| T<nnn> | S/M/L | 1/2/3 | backend / frontend / ui-ux / devops / docs | <n> | open |

**Goal (1 sentence):** … · **Spec:** `docs/delix/SPEC.md#REQ-<n>`

## Files (disjoint ownership; do not touch files owned by another card)
- Create: `path/to/new.py`
- Modify: `path/to/existing.py` (lines ~40–80, `fn_x`)
- Test: `tests/test_x.py` (only **new** tests are added; existing tests are not changed)

## Interfaces
- Consumed: `module.fn(a: int) -> B` (produced by T<prev>; if unfinished, write against the signature)
- Produced: `POST /api/x` → `{ "id": str }`

## Global Constraints (verbatim from the spec)
- …

## Steps
1. Write a failing test (`tests/test_x.py::test_y`), run it, see **red**.
2. Implement (only the paths in Files).
3. Run, see **green**; `ruff`/`mypy` clean.
4. Commit: `T<nnn>: <what>`; open a PR, body includes "How I tested" (command + output).

## Verification command → expected output
`pytest tests/test_x.py -q` → `3 passed`

## Review Focus
- Input the spec implies but does not test: … (covering test: …)

## Don'ts
- Untouchable: `auth/**`, `tests/**` (except new tests), <protected paths>
- If a test looks wrong, **do not change it**: stop, explain with `NEEDS_CONTEXT` in the report.
- New dependencies only with a reason, written in the card.

## Report contract
At the end, `.delix/report.md` (≤ 1–2K tokens): `DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED` · evidence (command,
output, screenshot path) · PR number · assumptions · remaining work. Do not read the whole plan; only this card and the
relevant spec section.

## Review findings (filled by the lead)
- Round 1: …
