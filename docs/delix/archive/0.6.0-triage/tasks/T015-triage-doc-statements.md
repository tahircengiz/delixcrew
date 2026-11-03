# T015 — Triage 0.6.0 doc statements match the code

| id | size | tier | role | wave | status |
|---|---|---|---|---|---|
| T015 | S | 1 | docs | 3 | open |

**Goal (1 sentence):** Correct five triage statements in README.md, README.tr.md and the CHANGELOG 0.6.0 entry so they
match `scripts/triage.py`. · **Spec:** `docs/delix/SPEC.md` §10 "Doküman yanlışları"

## Files (disjoint ownership; do not touch files owned by another card)
- Modify: `README.md` (Triage: `show` cleaning, `apply` stop, Records)
- Modify: `README.tr.md` (same three places; Turkish twin, same commit)
- Modify: `CHANGELOG.md` (0.6.0 entry only; edit in place, no new version)
- Test: none (docs only; no failing test is possible or needed)

## Interfaces
- Consumed (facts, do not change):
  1. `show` removes only Cc (except `\n`, `\t`), Cf and Co, plus HTML comments (`scripts/feedback.py` `bad_char`,
     `scripts/triage.py` `Cleaner`). Other invisible characters (e.g. Hangul fillers, category Lo) stay.
  2. The hooks deny Write/Edit into the record dir (`scripts/write_gate.py`). A shell write (redirection, `cp`, `tee`)
     is not denied (SPEC §8 P2).
  3. `show --require accepted`: exit 7 when `gh` fails (`gh_failed`); exit 8 only when the accepted label or marker
     comment is missing or the issue-sha differs.
  4. `index` runs `gh issue list --state all --limit 300`, so it lists at most 300 issues.
  5. `apply` rebuilds the comment and stops when the hash differs from `--confirm` (exit 5) or the comment is now
     BLOCKED, e.g. the issue's title or body changed since the record (exit 4). Labels, comments and state are re-read
     after `APPLY` and only the missing steps run (K112); they are not compared with the preview.
- Produced: none.

## Global Constraints (verbatim from the spec)
- Plugin texts are English; README.tr.md is the Turkish twin and changes in the same commit with the same meaning.
- No code change. CHANGELOG 0.6.0 is edited in place; no new version entry.

## Steps
1. No failing test (docs only). Run the old-phrase greps below and see the hits.
2. Replace the five statements (EN and TR with the same meaning).
3. Run the verification below and see **green**.
4. Commit: `T015: triage 0.6.0 doc statements match the code` (stage the files by name); open a PR whose body has
   "How I tested" (commands + output).

## Verification command → expected output
- `for t in tests/*_tests.sh; do bash "$t"; done` → every file ends with `ALL PASSED`
- `claude plugin validate .` → passes
- `cat README.md CHANGELOG.md | tr '\n' ' ' | tr -s ' ' | grep -oE 'control and invisible characters|only .triage\.py. writes there|exit 8 otherwise|lists every issue|anything changed since the preview'` → no output
- `tr '\n' ' ' < README.tr.md | tr -s ' ' | grep -oE 'kontrol ve görünmez karakterler|oraya yalnız .triage\.py. yazar|önizlemeden sonra bir şey değiştiyse durur'` → no output

## Review Focus
- EN and TR say the same thing in all three places.
- Exit codes are right: 4 = BLOCKED, 5 = hash mismatch, 7 = gh, 8 = acceptance.
- Correct statements elsewhere in the Triage section stay unchanged.

## Don'ts
- Untouchable: `scripts/**`, `hooks/**`, `tests/**`, every other README/CHANGELOG section and version.
- If a fact above disagrees with the code, do not change the code: stop and report `NEEDS_CONTEXT` with `path:line`.
- No new dependencies.

## Report contract
At the end, `.delix/report.md` (≤ 1–2K tokens): `DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED` · evidence
(commands, output) · PR number · assumptions · remaining work. Read only this card and SPEC §10.

## Review findings (filled by the orchestrator)
- Round 1: …
