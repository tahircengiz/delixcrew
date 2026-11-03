# T004 — 🔐 Issue forms, CI step, version 0.5.0

| id | size | tier | role | wave | status |
|---|---|---|---|---|---|
| T004 | S | 3 | devops | 2 | open |

**🔐 Approved:** 2026-11-03 tahircengiz

> 🔐 Tier 3 (`.github/**`, `.claude-plugin/**`). The orchestrator adds the Approved line after the human's "yes".

**Goal (1 sentence):** Web issue forms with the same headings as the CLI body, a CI step for feedback tests, and the version bump. · **Spec:** `docs/delix/SPEC.md` §4 (issue body, file row), §5, §7

## Files (disjoint ownership; do not touch files owned by another card)
- Create: `.github/ISSUE_TEMPLATE/bug.yml`
- Create: `.github/ISSUE_TEMPLATE/feature.yml`
- Modify: `.github/workflows/tests.yml` (after the `Board tests` step, a new step `Feedback tests`: `bash tests/feedback_tests.sh`)
- Modify: `.claude-plugin/plugin.json` (`version` `0.4.0` → `0.5.0`)

## Interfaces
- Consumed: `tests/feedback_tests.sh` (T001, merged in wave 1).
- Produced: issue forms whose textarea labels are, in order: `Component`, `Version`, `What happened`, `Expected`, `Steps to reproduce`, `Context`. Labels: `bug.yml` → `[bug]`, `feature.yml` → `[enhancement]` (existing labels only, K70).

## Global Constraints (verbatim from the spec)
- "Repo'da yeni label" is out of scope (no new label in the repo); no Discussions; no `config.yml`.
- Version `0.5.0` (K74).
- `marketplace.json` has no version field: do not add one.
- Keep pinned action SHAs and `permissions: contents: read` as they are.

## Steps
1. Check: `grep -c 'bash tests/feedback_tests.sh' .github/workflows/tests.yml` → `0` (red).
2. Write the forms and the step; bump the version.
3. Run `claude plugin validate .` and `bash tests/feedback_tests.sh` → green. The CI run on the PR is the final check.
4. Commit `T004: issue forms, CI feedback step, 0.5.0`. PR body has "## How I tested".

## Verification command → expected output
- `grep -c 'bash tests/feedback_tests.sh' .github/workflows/tests.yml` → `1`
- `python3 -c "import json;print(json.load(open('.claude-plugin/plugin.json'))['version'])"` → `0.5.0`
- `claude plugin validate .` → passed
- PR CI → green

## Review Focus
- The form headings match T001's body headings character for character (so the remote duplicate search and REQ-10 read the same layout).

## Don'ts
- Untouchable: everything not listed under Files; no new workflow, no new permissions, no secrets in the workflow.
- No internal addresses in form placeholders (use `example.*`).

## Report contract
`.delix/report.md` (≤ 1K tokens): status · command output · PR number + CI link.

## Review findings (filled by the orchestrator)
- Round 0 (2026-11-03, 9e5b4ff): qa ACCEPT_WITH_NOTES, security 🔐 HUMAN_APPROVAL (no finding; protected `.github/**`, `.claude-plugin/**`). Orchestrator (git archive 9e5b4ff): card greps `1` / `0.5.0`, `claude plugin validate .` passed, board/feedback/hook/trust ALL PASSED, CI pass, gitleaks and internal-address scan clean. Notes (P2): `Steps to reproduce` and `Context` are optional in the forms (spec silent); merge after T005 so 0.5.0 never sits on main without its CHANGELOG/README (SPEC §187). Gate 2 → user.
