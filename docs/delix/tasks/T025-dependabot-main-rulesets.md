# T025 — 🔐 Dependabot for GitHub Actions pins, main ruleset definitions (user applies) (#9)

| id | size | tier | role | wave | status |
|---|---|---|---|---|---|
| T025 | S | 3 | devops | 4 | open |

> 🔐 Tier 3: every file is under `.github/**`, which is protected (docs/delix/delix.json). The lead adds the Approved line after the user says "yes" in chat.

**🔐 Approved:** 2026-11-04 tahircengiz

**Goal (1 sentence):** Dependabot updates the SHA-pinned actions every week, and two ruleset JSON files define the main-branch protection that the user applies from their own terminal. · **Spec:** issue <https://github.com/tahircengiz/delixcrew/issues/9> (accepted; size S, so gate 1 is this card). Already on (verified 2026-11-04 with `gh api`): secret scanning, push protection, Dependabot alerts, Dependabot security updates, private vulnerability reporting.

## Files (base origin/main 9f6f8e7; all new)
- Create: `.github/dependabot.yml`
- Create: `.github/rulesets/main-integrity.json`
- Create: `.github/rulesets/main-review.json`
- Test: none new (config only; the existing 8 suites must stay green)

## Interfaces
- Consumed: job ids `test` (`.github/workflows/tests.yml`, `jobs.test`) and `check` (`.github/workflows/site.yml`, `jobs.check`). Neither job has a `name:`, so the check-run contexts are `test` and `check`. Both workflows run on every `pull_request` with no paths filter; site.yml's `paths` filter covers only `push`. Both can therefore be required.
- Consumed: pins in the form `uses: <action>@<40-hex> # vX.Y.Z` in both workflows. Dependabot updates the SHA and the comment.
- Produced: request bodies for `POST /repos/tahircengiz/delixcrew/rulesets`.

## Global Constraints
- `.github/dependabot.yml`, exactly: `version: 2`, then `updates:` with one entry: `package-ecosystem: "github-actions"`, `directory: "/"`, `schedule.interval: "weekly"`. No other ecosystem or key.
- Two rulesets, because bypass actors apply to the whole ruleset (K-T025-2). Both: `"target":"branch"`, `"enforcement":"active"`, `"conditions":{"ref_name":{"include":["~DEFAULT_BRANCH"],"exclude":[]}}`.
  - `main-integrity.json`: `"name":"main-integrity"`, `"bypass_actors":[]`, `"rules":[{"type":"deletion"},{"type":"non_fast_forward"}]`.
  - `main-review.json`: `"name":"main-review"`, `"bypass_actors":[{"actor_id":5,"actor_type":"RepositoryRole","bypass_mode":"always"}]`, and two rules:
    - `{"type":"pull_request","parameters":{"required_approving_review_count":0,"dismiss_stale_reviews_on_push":false,"require_code_owner_review":false,"require_last_push_approval":false,"required_review_thread_resolution":false}}`
    - `{"type":"required_status_checks","parameters":{"strict_required_status_checks_policy":false,"required_status_checks":[{"context":"test","integration_id":15368},{"context":"check","integration_id":15368}]}}`. The id 15368 is GitHub Actions; the lead confirmed it from a live check run on 9f6f8e7 (`test app=15368 github-actions`).
- The JSON is plain, with 2-space indent and no extra key such as `$comment`, because the API rejects unknown fields.
- The review count is 0 because there is one maintainer and gate 2 (the merge) stays with the user. Strict mode is off so that direct STATE pushes do not force PR branches to rebase (K-T025-3).
- Bypass decision (user, 2026-11-04, K-T025-1): owner bypass.
  - Force push and deletion are forbidden for everyone.
  - The PR and required-check rules can be bypassed by the repo admin role, so the delix flow's direct STATE/card record pushes keep working.
- The implementer never applies a setting. `scripts/bash_gate.py` denies agent `gh api` writes to this repo; do not look for a way around that.

## Steps
1. Baseline: run the verification command and see it green before any edit.
2. Create the 3 files with the Write tool, only at the paths in Files. Shell `>`, `cp`, `mv` and `tee` into `.github/**` are denied by the hook.
3. Run the parse check (see Verification), then the suites and `claude plugin validate .` again, and see them green.
4. Commit `T025: Dependabot for github-actions, main ruleset definitions (#9)` and open a PR. The PR body has two sections: `## How I tested` (commands and output) and `## Apply (user, own terminal, after merge)`, which carries the block below exactly.

Apply (user):
- `gh api -X POST repos/tahircengiz/delixcrew/rulesets --input .github/rulesets/main-integrity.json`
- `gh api -X POST repos/tahircengiz/delixcrew/rulesets --input .github/rulesets/main-review.json`

Read (the outputs go into the issue #9 comment that the user publishes):
- `gh api repos/tahircengiz/delixcrew/rulesets --jq '.[] | {id,name,enforcement}'` → 2 rows, both `active`
- `gh api repos/tahircengiz/delixcrew/rules/branches/main --jq '[.[].type]'` → contains `deletion`, `non_fast_forward`, `pull_request`, `required_status_checks`
- `gh api repos/tahircengiz/delixcrew/rulesets/<id> --jq .current_user_can_bypass` → `always` for main-review, `never` for main-integrity
- 2FA: user check at github.com/settings/security (the token cannot read it).

## Verification command → expected output
- `for t in tests/*_tests.sh; do bash "$t" || exit 1; done` → 8 suites pass, exit 0
- `claude plugin validate .` → passes
- `python3 -c 'import json,sys; [json.load(open(f)) for f in sys.argv[1:]]' .github/rulesets/main-integrity.json .github/rulesets/main-review.json` → exit 0
- `ruby -ryaml -e 'p YAML.load_file(".github/dependabot.yml")'` → `{"version"=>2, "updates"=>[{"package-ecosystem"=>"github-actions", "directory"=>"/", "schedule"=>{"interval"=>"weekly"}}]}`. PyYAML is not installed on the lead's machine; Ruby 2.6 is. Do not install anything; if neither parser exists, report DONE_WITH_CONCERNS.

## Review Focus
- The contexts `test` and `check` match the job ids, and both run on every PR. A wrong context would leave every PR waiting.
- `main-integrity` has no bypass actor; `main-review` has only the admin role.
- The JSON has no `$comment` key, and Dependabot has no extra ecosystem.
- Not verified against a live call:
  - `actor_id` 5 is the admin repository role.
  - A repository-role bypass works on a user-owned repo.
  - Both are confirmed by the first `current_user_can_bypass` read after apply. If main-review reads `never`, the user deletes that ruleset (`gh api -X DELETE repos/tahircengiz/delixcrew/rulesets/<id>`) and the lead reports it.
- After the user applies, the acceptance has three parts:
  - A normal PR merges.
  - An owner STATE push to main is accepted with a "bypassed rule violations" notice.
  - The `rules/branches/main` read lists `non_fast_forward`. A real force-push test is optional; only the user runs it.

## Don'ts
- Do not touch `.github/workflows/**`, `.github/ISSUE_TEMPLATE/**`, `scripts/**`, `hooks/**`, `.claude-plugin/**`, `tests/**`, `docs/delix/**`, `README*.md`, `site/**`, `SECURITY.md` or `CHANGELOG.md`. No version bump.
- Do not run `gh api` with `-X POST/PUT/PATCH/DELETE`, `--input` or `-f`. Do not run `git push` to main.
- Do not quote the issue text. If an API field looks wrong, report `NEEDS_CONTEXT`; do not guess.

## Report contract
`.delix/report.md`: one of `DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED`, the 4 verification outputs, the PR number and assumptions.

**Docs/site:** no change (K-T025-4). No command, hook rule, role, gate or project-side file (README "Files on the project side") is added, and nothing shipped in the plugin changes, so there is no `plugin.json` bump and the CLAUDE.md site triggers do not fire.

## Review findings (filled by the lead)
- Round 1: …
