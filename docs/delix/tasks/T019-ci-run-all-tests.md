# T019 — 🔐 CI: tests.yml runs every tests/*_tests.sh

| id | size | tier | role | wave | status |
|---|---|---|---|---|---|
| T019 | S | 3 | devops | 2 | open |

> 🔐 Tier 3: `.github/**` is a protected path (`docs/delix/delix.json:8`). The lead adds the Approved line after the human says "yes".

**Goal (1 sentence):** CI runs the same test loop as `docs/delix/delix.json` `test_command`, so every current and future `tests/*_tests.sh` runs on each push and PR. · **Spec:** `docs/delix/SPEC.md` §9 K149; follow-up to the T017 round 0 P2 finding (`docs/delix/tasks/T017-write-gate-queue-casefold.md`, Round 0)

## Files
- Modify: `.github/workflows/tests.yml`

## Edit anchors (base bdfc2f6; match the content, not only the number)
1. Replace lines 20–27 (the four steps `- name: Hook tests` / `run: bash tests/hook_tests.sh`, `Board tests`, `Feedback tests`, `Triage tests` / `run: bash tests/triage_tests.sh`) with this one step (6-space indent, like line 20):
   `      - name: All tests (tests/*_tests.sh)`
   `        # same command as docs/delix/delix.json test_command; -x logs one "+ bash tests/<file>" line per file`
   `        shell: bash --noprofile --norc -x -eo pipefail {0}`
   `        run: for t in tests/*_tests.sh; do bash "$t" || exit 1; done`
2. Lines 1–19 and 28–34 stay byte-identical: the comment, `on:`, `permissions: contents: read`, `runs-on: ubuntu-24.04`, `timeout-minutes: 10`, both pinned SHAs (checkout `3d3c42e…`, setup-node `949feb2…`), `persist-credentials: false`, the Claude Code pin `2.1.309` and `claude plugin validate .`.

## Interfaces
- The `run:` string is exactly the `test_command` value in `docs/delix/delix.json:3`. If one of them changes, the other must change in the same PR.
- The default GitHub shell is `bash --noprofile --norc -eo pipefail {0}`; this card only adds `-x`. The child `bash "$t"` is not traced, so test output does not change.

## Global Constraints
- Tool check (base bdfc2f6): `tests/site_tests.sh` needs only python3. `tests/trust_tests.sh` needs git, python3, `mktemp` and `sed -i.bak` (works with GNU sed). `tests/write_gate_case_tests.sh` needs python3. `feedback_tests.sh` and `triage_tests.sh` stub gitleaks, gh and claude and already pass on this runner. Nothing is installed.
- `tests/trust_tests.sh:55-59` (case 5) proves its point only on macOS; it passes on Linux without proving anything. Keep it as is.
- No new action, no new permission, no `continue-on-error`, no `if:` around the step, and no test is skipped or excluded.

## Steps
1. Red: run Verification check 1 on the base; it prints `DIFF`.
2. Apply edits 1–2 (only `.github/workflows/tests.yml`).
3. Green: check 1 prints `SAME`; check 2 exits 0 on macOS; check 3 is empty.
4. Commit `T019: tests.yml runs every tests/*_tests.sh (same loop as delix.json test_command)`. Open the PR with `--body-file`. The body has "## How I tested": the three checks, plus the `test` job log lines `+ bash tests/<file>` for every file (`board, feedback, hook, site, triage, trust, write_gate_case`; `sanitize` too if T016 has merged).
5. If any file fails in the CI `test` job (Linux) but passes locally, do not change the test or the workflow to skip it. Write `NEEDS_CONTEXT` with the failing file and the last 20 log lines.

## Verification command → expected output
1. `python3 -I -c 'import json,sys; c=json.load(open("docs/delix/delix.json"))["test_command"]; y=open(".github/workflows/tests.yml").read(); print("SAME" if ("        run: "+c+"\n") in y else "DIFF")'` → `SAME`
2. `for t in tests/*_tests.sh; do bash "$t" || exit 1; done` → exit 0
3. `git diff --stat origin/main -- README.md README.tr.md CHANGELOG.md docs/ tests/ .github/workflows/site.yml` → empty
4. PR checks: `test` SUCCESS. Its "All tests" log has one `+ bash tests/…_tests.sh` line for each file in `ls tests/*_tests.sh` at the PR head.

## Review Focus
- An empty glob runs `bash 'tests/*_tests.sh'`, which fails, so the job fails (fail closed). That is accepted.
- `site_tests.sh` now also runs in `tests`; `site.yml` runs it on every pull_request too: duplicated but cheap, kept for parity with `test_command`.
- The `-x` trace shows only the loop lines. No secret is in the env (`permissions: contents: read`, no `secrets.*`).

## Don'ts
- Do not touch `.github/workflows/site.yml`, `docs/delix/delix.json`, `tests/**`, `README*`, `CHANGELOG.md`, or any `scripts/*`.
- No per-file steps, no matrix, no new install step. If a tool is missing, report `NEEDS_CONTEXT`; do not add one.

## Report contract
`.delix/report.md` (≤ 1K tokens): `DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED` · the commands and their output · PR number · the list of `+ bash` lines from the CI log · assumptions. Read only this card.

## Review findings (filled by the lead)
