# Verification — github-pages (2026-11-03)

| input | sha | base | tier | verdict | cost |
|---|---|---|---|---|---|
| claude/github-pages | f6c2d0a | 9dfc83d | 3 🔐 | ACCEPT 🔐 | not measured |

Request / acceptance criteria source: the user's chat request and decisions, copied with the commit message into
`request.md` in the verify workspace · Patch: `docs/delix/verifications/2026-11-03-github-pages.patch` (docs/delix
excluded) · Files touched: 10 outside docs/delix (🔐: `.github/workflows/site.yml`)

This is round 3. Earlier rounds on the same branch:

| round | sha | base | verdict | qa | security | what changed after it |
|---|---|---|---|---|---|---|
| 1 | 68664ce | 375623f | ACCEPT 🔐 | ACCEPT_WITH_NOTES, 3 P2 | 🔐, 1 Low | effc814: CI on every PR, wider asset check, version marks in header and footer, page set compared |
| 2 | effc814 | 9dfc83d | ACCEPT 🔐 | ACCEPT_WITH_NOTES, 2 P2 | 🔐, 2 Low | f6c2d0a: bounded regex (ReDoS Low), event handlers, `javascript:`, form, meta refresh, nested assets |
| 3 | f6c2d0a | 9dfc83d | ACCEPT 🔐 | ACCEPT_WITH_NOTES, 1 P2 | 🔐, no findings | — |

## Deterministic gates
| gate | command | result | evidence (last lines) |
|---|---|---|---|
| gitleaks (diff) | `gitleaks git --log-opts=9dfc83d..f6c2d0a -c .gitleaks.toml --no-banner` | PASS | 4 commits scanned · no leaks found |
| gitleaks (archive) | `gitleaks dir archive/ -c .gitleaks.toml --no-banner` | pre-existing finding 1 (also on base) | `evals/secret-refusal/prompt.md:7`, generic-api-key; not in this patch (eval fixture, since 0.4.0) |
| local tests | `for t in tests/*_tests.sh; do bash "$t" \|\| exit 1; done` | PASS | ALL PASSED · exit 0 (`tests/site_tests.sh`: 20 ✔, 0 ✘) |
| extra check | `claude plugin validate .` | PASS | Validation passed with warnings · exit 0 |
| remote isolated unit | — | not run: no delix.json.verify | — |
| full suite | — | not run: no --full | — |
| path check | `git diff --name-only 9dfc83d f6c2d0a` | 🔐 1 protected path | `.github/workflows/site.yml`; no existing test line deleted or changed (`tests/site_tests.sh` is new) |

Orchestrator checks outside the gates:
- The four pinned action SHAs resolve to the tags in their comments (`gh api repos/actions/<name>/git/ref/tags/<tag>`,
  checked in round 1; the SHAs are unchanged since): checkout v7.0.1, configure-pages v6.0.0, upload-pages-artifact
  v5.0.0, deploy-pages v5.0.1.
- Negative cases against a copy of the site: 18 of 18 mutations make `tests/site_tests.sh` fail; the unmodified copy
  passes. A root `<svg onload>` alone fails. A page with 40 unclosed 800-space tags runs the whole test in 0.13 s (the
  round-2 regex took 1.7 s on 20 such tags).

## Findings
### qa — ACCEPT_WITH_NOTES (0 P0, 0 P1, 1 P2)
- [P2] `CLAUDE.md:63-64` · The note says the site is "published ... on every push to main". The workflow's push trigger has a `paths` filter (`site/**`, `.claude-plugin/plugin.json`, `tests/site_tests.sh`, `.github/workflows/site.yml`), so a push to main that touches none of those does not publish. · Evidence: `site.yml:4-5`. · Suggestion: write "on every push to main that touches site/ or plugin.json", or drop the `paths` filter.
- Checked and matching: four TR/EN pages and the twin rule; SHA-pinned actions, deploy only on main (`workflow_dispatch` from another branch does not deploy), job-level permissions, `persist-credentials: false`; version marks (≥2 per page, 0.6.0); spot-checked claims (max_parallel 3, Claude Code 2.1.309, python3 3.9, the python3 error line, the CHANGELOG 0.4.0 anchor); no internal hosts or local paths; no scripts, handlers, forms or `@import`; test integrity (new file, no `-` lines, bounded regexes).
- Unsure: action SHAs against upstream tags (the reviewer reads no web content); Pages source must be "GitHub Actions" in the repo settings; the bounded tag scan could miss a handler in a tag over 4 KB or after a `>` inside an attribute value (only with hostile content).

### security — 🔐 HUMAN_APPROVAL (no Critical/High/Medium/Low)
- Secrets: none in the diff, `site/` or the 4 commits; the archive hit is the pre-existing eval fixture.
- Workflow: top-level `contents: read`; `pages: write` + `id-token: write` only on deploy; `pull_request`, not `pull_request_target`; deploy gated on main and `needs: check`; `persist-credentials: false`; no `secrets.*` or `github.event.*` interpolation in `run:`.
- Site: static; no script, iframe, form, handler, meta refresh, `javascript:`, `@import`/`@font-face` or external `src`/`url()`; external refs only `<a href>` to the GitHub repo and the SVG `xmlns`. `tests/site_tests.sh` reads only, `python3 -I`, no network, bounded regexes.
- Dependencies: no dependency files changed; all 4 actions pinned to full SHAs. Only `site/` is uploaded. No internal hosts, IPs, machine names, local paths or e-mail addresses.
- Scanners: gitleaks (`site/`, the patch, the gate runs), pattern grep over added lines. Missing: semgrep, trivy, actionlint/zizmor. pip-audit not applicable.
- Unsure: SHA-to-tag match (no web access); the `github-pages` environment's branch rule is a repo setting.
- Verdict reason: the protected path `.github/**` needs the user's explicit approval.

## Not run
- remote isolated unit test: no `delix.json.verify` block
- full suite: no `--full`
- `/security-review`: not run (it reviews the main checkout's pending changes, not the `$sha` diff alone)

## Verdict
**ACCEPT 🔐** · every gate that ran is PASS or pre-existing, qa has no P0/P1, security has no findings · the user's
explicit "yes" in chat for `.github/workflows/site.yml` (f6c2d0a version) is required before the merge; the P2 note is
the user's to apply; after a fix run `/delixcrew:verify claude/github-pages` again.
