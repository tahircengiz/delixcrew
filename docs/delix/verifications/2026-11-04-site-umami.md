# Verification — site-umami (2026-11-04)

| input | sha | base | tier | verdict | cost |
|---|---|---|---|---|---|
| merge commit of PR #40 on main | e120c5a | d5d77da | 2 | ACCEPT | not measured |

Request / acceptance criteria source: brief from the lead session (local_4608bbd4, 2026-11-04), saved for the reviewers
as `delix-verify-site-umami/request.md` in the workspace (not in the repo) · Patch:
`docs/delix/verifications/2026-11-04-site-umami.patch` · Files touched: 7 (🔐: none)

Base is the parent of the squash merge (`e120c5a^`), since `merge-base main e120c5a` is the commit itself. The archive
comes from `git archive e120c5a`, not from the worktree.

## Deterministic gates
| gate | command | result | evidence (last lines) |
|---|---|---|---|
| gitleaks (diff) | `gitleaks git --log-opts=d5d77da..e120c5a -c .gitleaks.toml --no-banner` | PASS | 1 commits scanned · no leaks found |
| gitleaks (archive) | `gitleaks dir archive/ -c .gitleaks.toml --no-banner` | pre-existing finding 1 (also on base) | `evals/secret-refusal/prompt.md:7`, generic-api-key; same finding in the d5d77da archive; not in this patch (eval fixture) |
| local tests | `for t in tests/*_tests.sh; do bash "$t" \|\| exit 1; done` (in `archive/`) | PASS (rc 0) | 8/8 PASS · `analytics rule: 24 bad cases rejected, 1 good cases accepted` · `long near-miss inputs stay under 1s` · `all 4 pages use the same website id` |
| extra check | `claude plugin validate .` (in `archive/`) | PASS (rc 0) | passed with 1 warning + 1 plugin directory warning; the same warnings on base |
| remote isolated unit | — | not run: no delix.json.verify | — |
| full suite | — | not run: no --full | — |
| CI on PR #40 | `site` + `tests` workflows | PASS | 2 passing, 1 skipped (deploy runs only on main) |
| Pages deploy | `site.yml` on main | PASS | run for e120c5a: completed success |

Live evidence (outside the gates, recorded by the session that did the work):
- `curl -s https://tahircengiz.github.io/delixcrew/{,usage.html,tr/,tr/usage.html} | grep -c 'stats.delix.dev/u.js" data-website-id="aa8134df'`
  gives 1 on each page.
- Umami Realtime for `delixcrew` after one visit: Views 1, Visitors 1, 1 Online.
- `stats.delix.dev` resolves to Cloudflare addresses through 1.1.1.1 and through the local resolver. Responses: `/u.js` 200,
  `/u/e` 405 on GET, `/login` 404.
- The live `u.js` contains `cookie` 0 times. It reads `localStorage` only for the `umami.disabled` opt-out.

## Findings
### qa — ACCEPT_WITH_NOTES (P0 0, P1 0, P2 2)
- [P2] `site/index.html:696` (same line on the other 3 pages) and `CLAUDE.md:21-23`
  - The footer says "no cookies; no personal data is sold or shared". Its `Source:` line points only to `CLAUDE.md` and
    `tests/site_tests.sh`, and both restate the claim; no repo file shows what Umami stores or whether data is shared.
  - Suggestion: word the line as the maintainer's statement of intent, or cite a repo file that holds the Umami
    configuration or the privacy decision.
  - Lead note: the cookie part was checked against the live `u.js` (see Live evidence). "Not sold or shared" is the
    maintainer's own commitment, and no file in this repo can prove it.
- [P2] `tests/site_tests.sh:135-140`
  - The head check uses `t.find("<head>")` and `t.find("</head>")`. A page that wrote `<head lang=..>` would make the
    tag count as "not in head" and fail.
  - This fails closed and is safe today. The note is only about how brittle the check is; no change is required.
- What holds:
  - The allowlist is fixed-width, with no alternation and no open-ended quantifier.
  - Only the one exact match is cut out before the old ACTIVE and EXT_REF scans run.
  - Exactly one tag, inside `<head>`, the same id on all four pages, and the nil uuid is rejected.
  - 24 bad cases are read from a file.
  - No existing test line was deleted or loosened.
  - There is no CSP meta, so there was nothing to update.
  - The EN/TR footers are twins.
  - CI, SPEC, STATE, `tasks/`, `data-version` and the plugin version are untouched.

### security — CLEAN
- [Low] `site/*.html:12`: third-party script without SRI or CSP.
  - `u.js` runs with full privileges on the shared `tahircengiz.github.io` origin, which also serves the user's other
    Pages sites and shares `localStorage` with them.
  - If the homelab Umami or the Cloudflare route is compromised, an attacker can run script on these pages.
  - The impact is small: the site is static, with no auth, forms or secrets.
  - Meets the request: a CSP was asked for only if one already existed.
  - Optional fix (a maintainer decision): accept the risk, or add a CSP meta tag
    (`script-src 'self' https://stats.delix.dev; connect-src https://stats.delix.dev`) and the matching test allowlist
    rule. SRI is a poor fit because every Umami update would break it.
- Unsure (not counted as findings):
  - The no-cookie claim depends on the Umami version that serves `u.js`.
  - The public `/u/e` endpoint accepts unauthenticated events, so anyone can send fake stats. This exposure existed
    before the change.
- Scanners:
  - gitleaks (patch: no leaks; archive: only the pre-existing finding above).
  - Internal-name grep over the patch: 0 matches.
  - CSP/SRI grep over `site/`.
  - pip-audit not applicable.
  - semgrep not run: plugin hooks blocked the reviewer's commands. The only code change, the Python allowlist, was
    reviewed by hand.

## Not run
- remote isolated unit test: no `delix.json.verify`
- full suite: no `--full`
- `/security-review`: tier 2
- STATE.json record: not written here. The lead session keeps STATE; this job's brief forbids touching `STATE.json`.

## Verdict
**ACCEPT** · All gates that ran are PASS or a pre-existing finding. qa has no P0/P1 and security has nothing above Low. The
two P2 notes and the Low (optional CSP) are for the user to decide; to re-check after a change, run
`/delixcrew:verify <input>` again.
