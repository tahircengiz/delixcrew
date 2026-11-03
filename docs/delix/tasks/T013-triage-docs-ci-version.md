# T013 — 🔐 README (EN+TR), CHANGELOG 0.6.0, version, CI step

| id | size | tier | role | wave | status |
|---|---|---|---|---|---|
| T013 | S | 3 | devops | 2 | open |

**🔐 Approved:** 2026-11-03 tahircengiz

> 🔐 Tier 3 (`.github/**`, `.claude-plugin/**`). The orchestrator adds the Approved line after the human says "yes".

**Goal (1 sentence):** User docs for triage, the 0.6.0 release entry and version, and the CI step for the triage tests. · **Spec:** `docs/delix/SPEC.md` §5, §6, §7, K120

## Files
- Modify: `README.md`: new `## Triage` section directly before `## Known limits` (line 180 on main 806febf); a Flow table row after the `any time` `/delixcrew:status` row (line 74); in `## Known limits`, add the triage write paths to the sentence that lists what `bash_gate.py` intercepts "in every session" (lines 189–191).
- Modify: `README.tr.md`: the same three places (directly before `## Bilinen sınırlar`, line 179; the Flow table; the matching sentence in `## Bilinen sınırlar`).
- Modify: `CHANGELOG.md`: new `## 0.6.0 — <date>` above line 5.
- Modify: `.claude-plugin/plugin.json`: line 4, `0.5.0` → `0.6.0`.
- Modify: `.github/workflows/tests.yml`: after lines 24–25 (`Feedback tests`) a step `Triage tests` running `bash tests/triage_tests.sh`.

## Interfaces
- Consumed: `tests/triage_tests.sh` and final CLI messages (T010); deny rules and message (T011); skill flow (T012). Copy messages from the merged code.

## Global Constraints (from the spec)
- README.md and README.tr.md in the same commit; TR is a twin, technical terms English.
- README covers: the flow `index`/`show` → architect → `<decision> #<n>` → `record` → `preview` → `apply` in your own terminal with `APPLY <hash>`; the five labels and when an issue is closed (K116); start takes only `accepted` issues whose text is unchanged since acceptance (REQ-8); where records are stored; the remaining risk (spec §6).
- `marketplace.json` has no version field; do not add one. Keep pinned action SHAs and `permissions: contents: read`.
- CHANGELOG 0.6.0 also notes the start §1a fix (K126).

## Steps
1. Red: `grep -c 'bash tests/triage_tests.sh' .github/workflows/tests.yml` → `0`.
2. Edit the five files.
3. `claude plugin validate .` and `bash tests/triage_tests.sh`, both green.
4. Commit `T013: triage docs, CHANGELOG 0.6.0, CI triage step`; PR body has "## How I tested".

## Verification command → expected output
- `grep -c 'bash tests/triage_tests.sh' .github/workflows/tests.yml` → `1`
- `python3 -c "import json;print(json.load(open('.claude-plugin/plugin.json'))['version'])"` → `0.6.0`
- `grep -c '^## Triage' README.md README.tr.md` → `1` each
- `grep -c '^## 0.6.0' CHANGELOG.md` → `1`
- `claude plugin validate .` → passed; PR CI → green

## Review Focus
- No claim of full blocking; known paths only (K77). EN and TR match section for section.

## Don'ts
- Untouchable: everything not under Files. No new workflow, permissions or secrets. No internal addresses (use `example.*`).

## Report contract
`.delix/report.md` (≤ 1K tokens): status · command output · PR number + CI link.

## Review findings
### Round 1 (9fea6dc) — qa ACCEPT · security 🔐 HUMAN_APPROVAL (no findings) → gate 2
Deterministic gates: CI `test` pass; from `git archive 9fea6dc`: 5× `ALL PASSED`; validate passed; card checks:
tests.yml triage step 1, version `0.6.0`, `## Triage` 1 in each README, `## 0.6.0` 1; internal-address scan 0 hits.
Docs match the merged code (commands, exit codes, deny message, labels, skill flow); EN and TR have the same structure.
CI change keeps `pull_request`, `contents: read`, pinned SHAs; no secrets or new permissions.
Noted, no fix:
- README "only triage.py writes there" (record dir): the hooks deny Write/Edit only, not a Bash redirect; wording at close.
- CHANGELOG "exit 8 otherwise" for `show --require accepted`: a GitHub CLI failure gives exit 7 (SKILL.md has it).
- `index` pending set has a 300-issue cap that the docs do not mention.
