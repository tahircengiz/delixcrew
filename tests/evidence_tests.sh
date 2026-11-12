#!/usr/bin/env bash
# T040 (F010): the card's Verification command output goes to .delix/evidence/verification.txt, which the Stop gate never opens; implement, review and qa name it. Run: bash tests/evidence_tests.sh
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; FAIL=0
ok(){ echo "✔ $1"; }; bad(){ echo "✘ $1"; FAIL=1; }
IMPL="$ROOT/skills/implement/SKILL.md"; REVIEW="$ROOT/skills/review/SKILL.md"; QA="$ROOT/agents/qa.md"
grep -qF 'Write the Verification command output to `.delix/evidence/verification.txt`' "$IMPL" && ok "implement: verification output to evidence file" || bad "implement: evidence file line missing"
grep -qF 'Never put it in `.delix/test-result.txt`' "$IMPL" && ok "implement: never in test-result.txt" || bad "implement: never-in-test-result line missing"
! grep -qF 'Write the outputs to `.delix/test-result.txt`' "$IMPL" && ok "implement: old test-result.txt instruction gone" || bad "implement: still writes outputs to test-result.txt"
grep -qF '`.delix/evidence/verification.txt` (the Verification command output)' "$REVIEW" && ok "review: worktree check names the evidence file" || bad "review: evidence file missing from worktree check"
grep -qF 'Does `.delix/evidence/verification.txt` match the' "$REVIEW" && ok "review: evidence file matched against expected output" || bad "review: expected-output check line missing"
grep -qF '(`.delix/test-result.txt`, `.delix/evidence/verification.txt`)' "$REVIEW" && ok "review: qa gets both output files" || bad "review: qa input line missing"
grep -qF '`.delix/evidence/verification.txt`, the Verification command output' "$QA" && ok "qa: input names the evidence file" || bad "qa: evidence file missing from input"
[ $FAIL -eq 0 ] && echo "ALL PASSED" || { echo "FAILED"; exit 1; }
