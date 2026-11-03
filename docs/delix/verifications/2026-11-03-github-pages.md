# Verification — github-pages (2026-11-03)

| input | sha | base | tier | verdict | cost |
|---|---|---|---|---|---|
| claude/github-pages | 68664ce | 375623f | 3 🔐 | ACCEPT 🔐 | not measured |

Request / acceptance criteria source: the user's chat request and decisions, copied with the commit message into
`request.md` in the verify workspace · Patch: `docs/delix/verifications/2026-11-03-github-pages.patch` · Files touched: 10
(🔐: `.github/workflows/site.yml`)

## Deterministic gates
| gate | command | result | evidence (last lines) |
|---|---|---|---|
| gitleaks (diff) | `gitleaks git --log-opts=375623f..68664ce -c .gitleaks.toml --no-banner` | PASS | 1 commits scanned · no leaks found · exit 0 |
| gitleaks (archive) | `gitleaks dir archive/ -c .gitleaks.toml --no-banner` | pre-existing finding 1 (also on base) | `evals/secret-refusal/prompt.md:7`, generic-api-key; the same hit on the base archive (375623f); not in this patch (eval fixture; the `^evals/` allowlist does not match under `archive/`) |
| local tests | `for t in tests/*_tests.sh; do bash "$t" \|\| exit 1; done` | PASS | ALL PASSED · 0 ✘ · exit 0 (includes the new `tests/site_tests.sh`, 17 ✔) |
| extra check | `claude plugin validate .` | PASS | Validation passed with warnings · exit 0 |
| remote isolated unit | — | not run: no delix.json.verify | — |
| full suite | — | not run: no --full | — |
| path check | `git diff --name-only 375623f 68664ce` | 🔐 1 protected path | `.github/workflows/site.yml`; no existing test line deleted or changed (`tests/site_tests.sh` is new) |

Orchestrator check outside the gates: the four pinned action SHAs resolve to the tags in their comments
(`gh api repos/actions/<name>/git/ref/tags/<tag>`): checkout v7.0.1, configure-pages v6.0.0, upload-pages-artifact v5.0.0,
deploy-pages v5.0.1, all OK.

## Findings
### qa — ACCEPT_WITH_NOTES (0 P0, 0 P1, 3 P2)
- [P2] `.github/workflows/site.yml:5,7` · `paths:` filters both triggers; a PR touching only README or skills gets no `check` run. If `check` ever becomes a required status, such PRs wait on a missing check. Suggestion: drop `paths:` from `pull_request`, or note the deviation in the file.
- [P2] `tests/site_tests.sh:34` · The third-party-asset check is narrower than its claim: a stylesheet `<link>` with `href` before `rel`, `<iframe src>`, `<link rel=preload|modulepreload>`, `<use href="https://…">`, upper-case `<SCRIPT`, and `url(…)` / `@import` / `@font-face` in `site/assets/style.css` or the SVGs pass. The site is clean today; a regression would pass. Suggestion: flag any `http(s):` or `//` value in `src`, `<link href>` or `<use href>`, and scan the CSS case-insensitively.
- [P2] `tests/site_tests.sh:26-27` · The version check covers only the `data-version` kicker; the footer version, the 0.6.0 pills and the "0.5.0 and 0.6.0" labels are not checked. Line 21 fixes the page list, so an extra page without a twin is not detected. Suggestion: mark the footer with `data-version` too and compare the `*.html` sets of the root and `tr/`.
- Checked and matching: version marks; hooks.json matchers and timeouts; the write_gate order against `scripts/write_gate.py`; T001–T009 values against the 0.5.0 archive STATE (12 rounds, 6 Tier 3, 3 zero-round cards; T002 4 rounds, 48 min, `c43516d`); T010–T014 PRs; the tier matrix, the 4–12% claim, issue #17/T007, dispatch session modes; TR/EN parity; no internal addresses; workflow deploy gating and job-level permissions.
- Unsure: Pages must be set to "GitHub Actions" as its source in the repo settings (not visible in the diff).

### security — 🔐 HUMAN_APPROVAL (no Critical/High/Medium; 1 Low)
- [Low] `tests/site_tests.sh:34` · Same coverage gap as qa P2 #2 (`<link rel=icon|preload|preconnect href=https://…>`, `href` before `rel`, `<iframe|object|embed|video|audio|source>`, inline `style=url(https://…)`, CSS `url()` in `style.css`). Shipped content is clean.
- Clean: workflow permissions (top-level `contents: read`; `pages: write` + `id-token: write` only on deploy), triggers (`pull_request`, not `pull_request_target`; deploy only on main), all actions SHA-pinned, `persist-credentials: false`, no secrets or event interpolation in `run:`, only `site/` published; site has no scripts, handlers, iframes, forms or external assets; no internal hosts, IPs, machine names, local paths or e-mail addresses; `tests/site_tests.sh` reads only, `python3 -I`, no network.
- Scanners: gitleaks (site and archive; the archive hit is the pre-existing eval fixture), rg pattern scans. Not run: semgrep, trivy, actionlint (missing); pip-audit (no dependency files changed).
- Verdict reason: the protected path `.github/**` needs the user's explicit approval.

## Not run
- remote isolated unit test: no `delix.json.verify` block
- full suite: no `--full`
- `/security-review`: not run (it reviews the main checkout's pending changes, not the `$sha` diff alone)

## Verdict
**ACCEPT 🔐** · every gate that ran is PASS or pre-existing, qa has no P0/P1, security has nothing at Medium or above ·
the user's explicit "yes" in chat for the new workflow is required before the merge; the P2 notes are the user's to
apply; after a fix run `/delixcrew:verify claude/github-pages` again.
