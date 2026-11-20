# T059 🔐 — Hooks: the write gate denies Write/Edit to the card worktree's own `.git`

| id | size | tier | role | wave | status |
|---|---|---|---|---|---|
| T059 | S | 3 | backend | 29 | open |

**🔐 Approved:** 2026-11-20 tahircengiz

> 🔐 Tier 3: `scripts/write_gate.py` is protected (`docs/delix/delix.json:10`). The lead adds the Approved line after the user's item-specific yes in chat and commits it to main before the session starts; the session branches from that commit.
> - The lead filled the base SHA and the sha256s at dispatch from its prototype (below). If a placeholder is left in this card, stop with `NEEDS_CONTEXT`.

**Goal (1 sentence):** In a card worktree, `scripts/write_gate.py` denies Write, Edit, MultiEdit and NotebookEdit on the worktree's own `.git` (gitfile or directory) and on everything under it, with one fixed message. The rule sits after the `docs/delix/**` rule and before the Files permission. · **Spec:** `docs/delix/specs/E-gitdir-bash-outside.md` REQ-1, §4, §5, §6, K358–K360, K364

**Docs/site:** none in this card. README, README.tr, the site and CHANGELOG belong to T060 (K362, same release).

## Files (disjoint ownership; do not touch files owned by another card)
- Modify: `scripts/write_gate.py` (W1 line 3; W2 insert after line 111)
- Create: `tests/gitdir_gate_tests.sh`
- Test: no existing test file changes (spec §7).

## Interfaces
- **Consumed, unchanged:**
  - `common.matches(path, patterns, cwd) -> str | None` (`scripts/common.py:331-339`). It tries the folded given path first, then the folded real path. A path it cannot resolve matches `patterns[0]`.
  - `common.deny(reason)` (`scripts/common.py:23-28`), which prints the reason JSON-encoded.
- **Produced:**
  - The rule: `matches(path, [".git/**"], cwd)` is not `None` → deny.
  - The message: one line, where `<path>` is the tool's `file_path` or `notebook_path` as given:
    `delixcrew: '<path>' is the worktree's .git; the implementer cannot change it with this tool (the hooks find the card through it). .delix/ is excluded with: echo .delix/ >> "$(git rev-parse --git-path info/exclude)"; for anything else, explain with NEEDS_CONTEXT in the report.`
- **Rule order in `write_gate.py` after the change:**
  1. outside cwd (A13, lines 87–89)
  2. live marker (91–96)
  3. config (98–107)
  4. card and `docs/delix/**` (109–111)
  5. **`.git` (new, 113–117)**
  6. `read_card` / Files (119 onwards)

## Edit anchors (base main af6c35b, full SHA `af6c35bb1b6cf8960dc763d879b22a75a35e560b`)
- `scripts/write_gate.py` has 133 lines on the base; base sha256 is
  `c5fefbd52eaa939ec19513030994d087fdbcff69f85d547e138ce133df362479`.
- Match the quoted content before you edit; if it differs, stop with `NEEDS_CONTEXT`.
- Use the Edit tool, because the hook denies shell writes to protected paths.
- Code blocks are not indented: copy each line exactly, leading spaces included.

**W1 · line 3 · replace.** Current (113 characters):
```text
file or docs/delix/**; a protected path is writable only if it is in the card's Files list and the card carries a
```
With (119 characters):
```text
file, docs/delix/** or .git; a protected path is writable only if it is in the card's Files list and the card carries a
```

**W2 · insert after line 111.** Lines 109–113 on the base:
```text
if matches(path, ["docs/delix/**", card], cwd):
    deny(f"delixcrew: '{path}' is the card or under docs/delix; the implementer cannot change these. If needed, explain "
         f"with NEEDS_CONTEXT in the report, the lead updates them.")

files, approved = read_card()
```
Insert these 6 lines after line 111. The first one is blank. Line 112 (the blank line before `files, approved = read_card()`) stays. The new lines are 0, 105, 35, 104, 92 and 119 characters long:
```text

# Spec E REQ-1 (K358-K360): the worktree's own .git (gitfile or directory) is how the hooks find the card
if matches(path, [".git/**"], cwd):
    deny(f"delixcrew: '{path}' is the worktree's .git; the implementer cannot change it with this tool "
         f"(the hooks find the card through it). .delix/ is excluded with: echo .delix/ >> "
         f"\"$(git rev-parse --git-path info/exclude)\"; for anything else, explain with NEEDS_CONTEXT in the report.")
```
The file then has 139 lines. Taken together, the three string parts are exactly the message under Interfaces.

**Lead prototype (2026-11-20, af6c35b, Python 3.9.6 and 3.13.13, git 2.54.0):** an independent applier of W1, W2 and
the Tests block below gives these sha256 prefixes (16 hex); compare yours with `shasum -a 256 <file>`, and if one
differs, find the anchor before you go on.

| file | base | after |
|---|---|---|
| `scripts/write_gate.py` | `c5fefbd52eaa939e` | `1a2193d18f2990e7` |
| `tests/gitdir_gate_tests.sh` | (new) | `f2a3b69481c873d3` |

On that copy the new test gave 38 `✘` / 27 `✔` on the base code and 65 `✔` with W1 and W2; all 19 test files exit 0
on 3.9.6 and on the 3.13 shim; the added lines are at most 119 characters; the message equals spec REQ-1.

## Tests (`tests/gitdir_gate_tests.sh`, new; ends with `ALL PASSED`)
**Shape (rules for the whole file):**
- `set -u`. The file is ASCII only. Check marks and the lock sign are octal escapes, as in `tests/stale_card_tests.sh:12`.
- None of `git`, `push`, `update-ref`, `remote`, `send`, `triage` or `script` appears as a literal word. They are built at run time. `scripts/` paths and the file's own name on the `# Run:` line are fine.
- The REQ-1 text is compared exactly: the test JSON-decodes `permissionDecisionReason` and checks it for equality. Do not `grep` the JSON, because it escapes the `"` in the message.
- The first output line is `git --version`.

Write this file. The one line in angle brackets stands for a block you copy byte for byte: lines 56–71 of `tests/stale_card_tests.sh` (`hj`, `run`, `ok`, `ko`, `isdeny`, `clean`, the comment line, `allow`, `deny`).
```bash
#!/usr/bin/env bash
# T059 (Spec E REQ-1, K358-K360): in a card worktree the write gate denies Write, Edit, MultiEdit and NotebookEdit on
# the worktree's own repository entry (a gitfile or a directory) and everything under it, in any letter case and
# through a symlink, even for a listed and approved card; the other write gate rules keep their messages. The trigger
# words are assembled at run time; this file holds none of them, and it stays ASCII (the check marks and the lock
# sign are octal escapes).
# Run: bash tests/gitdir_gate_tests.sh
set -u
unset DELIXCREW_FEEDBACK_DIR DELIXCREW_TRIAGE_DIR
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; S="$ROOT/scripts"; FAIL=0
G=gi; G="${G}t"; GUP=GI; GUP="${GUP}T"; GCAP=Gi; GCAP="${GCAP}t"; R=rem; R="${R}ote"
OK=$'\342\234\224'; NO=$'\342\234\230'; LOCK=$(printf '\360\237\224\220')
$G --version
T="$(mktemp -d)"; M="$T/m"; W="$M/.claude/worktrees/x"; P="$T/p"; SRC="$T/s"
GC="$G -c user.name=t -c user.email=t@t -c commit.gpgsign=false -c core.hooksPath=/dev/null"
C59="docs/delix/tasks/T059-x.md"
VALID='{"protected_paths": ["scripts/x.py"], "test_paths": ["tests/**"]}'
CONFIG="delixcrew: docs/delix/delix.json is missing, not valid JSON or not a JSON object with string lists; this card worktree stays blocked until the user fixes it from their own terminal"
DOCS="is the card or under docs/delix; the implementer cannot change these"
PROT="is a protected path (scripts/x.py, Tier 3)"
TEST="cannot be modified (no test weakening)"
gmsg(){ # <path>: the REQ-1 deny text, letter for letter
  printf '%s' "delixcrew: '$1' is the worktree's .$G; the implementer cannot change it with this tool (the hooks find the card through it). .delix/ is excluded with: echo .delix/ >> \"\$($G rev-parse --$G-path info/exclude)\"; for anything else, explain with NEEDS_CONTEXT in the report."; }
card(){ # <dir> <yes|no> <path>...: the T059 card file in <dir>, with the lock line when $2 is yes, these paths under Files
  dir=$1; a=$2; shift 2
  { printf '# T059 card\n\n| id | tier |\n|---|---|\n| T059 | 3 |\n\n'
    [ "$a" = yes ] && printf '**%s Approved:** 2026-11-20 t\n\n' "$LOCK"
    printf '## Files\n'; for f in "$@"; do printf -- '- Modify: `%s`\n' "$f"; done
    printf '\n## Steps\n1. none\n'; } > "$dir/$C59"; }
mkrepo(){ # <dir>: one commit on main with delix.json, the card, scripts/x.py, tests/a_tests.sh and the symlinks l, d
  mkdir -p "$1/docs/delix/tasks" "$1/scripts" "$1/tests" && $G -C "$1" init -q && $G -C "$1" symbolic-ref HEAD refs/heads/main
  printf '%s' "$VALID" > "$1/docs/delix/delix.json"; card "$1" no src/free.py
  echo x > "$1/scripts/x.py"; echo x > "$1/tests/a_tests.sh"; ln -s ".$G" "$1/l"; ln -s . "$1/d"
  $G -C "$1" add -A && $GC -C "$1" commit -q -m init; }
# Fixtures (setup by direct calls, never through a hook): W is a linked card worktree under M/.claude/worktrees/x,
# P is a main checkout that is itself the card worktree; both hold the T059 marker, untracked and excluded
mkrepo "$M"; echo ".delix/" >> "$M/.$G/info/exclude"; $GC -C "$M" worktree add -q -b claude/t1 "$W"
mkrepo "$P"; echo ".delix/" >> "$P/.$G/info/exclude"
for c in "$W" "$P"; do mkdir -p "$c/.delix" "$c/src"; echo "$C59" > "$c/.delix/card"; done
mkdir -p "$SRC/docs/delix" && $G -C "$SRC" init -q && $G -C "$SRC" symbolic-ref HEAD refs/heads/main
printf '{"cards": {"T059": {"file": "%s", "status": "accepted"}}}' "$C59" > "$SRC/docs/delix/STATE.json"
$G -C "$SRC" add -A && $GC -C "$SRC" commit -q -m s1

<tests/stale_card_tests.sh lines 56-71, byte for byte>
why(){ printf '%s' "$OUT" | python3 -c 'import json, sys
try:
    sys.stdout.write(json.load(sys.stdin)["hookSpecificOutput"]["permissionDecisionReason"])
except Exception:
    pass'; }
gdeny(){ # <name> <tool> <cwd> <path>: exit 0, the deny decision with exactly gmsg <path>, no Traceback
  if [ "$2" = Write ]; then j=$(hj Write "$3" "$4" x); else j=$(hj "$2" "$3" "$4"); fi
  run write_gate.py "$j"
  if [ $RC -eq 0 ] && isdeny && [ "$(why)" = "$(gmsg "$4")" ] && clean; then ok "$1"; else ko "$1" "expected the REQ-1 deny, exit $RC: $OUT $ERR"; fi; }

# ---- A. Scenario: the linked worktree's gitfile (6 forms x 4 tools), then the docs/delix rule still applies
for t in Write Edit MultiEdit NotebookEdit; do
  for p in ".$G" "./.$G" ".$GUP" ".$GCAP" "$W/.$G" "src/../.$G"; do gdeny "A $t $p" "$t" "$W" "$p"; done
done
deny "A then Write docs/delix/STATE.json" write_gate.py "$(hj Write "$W" docs/delix/STATE.json x)" "$DOCS"

# ---- B. Scenario: through a tracked symlink (l -> .G, d -> .), in both fixtures
for c in "$W" "$P"; do n=linked; [ "$c" = "$P" ] && n=main
  for p in l "d/.$G" "d/d/.$G"; do gdeny "B $n: Write $p" Write "$c" "$p"; done
done

# ---- C. Scenario: the main checkout is the card worktree (.G is a directory)
gdeny "C Write .$G/HEAD" Write "$P" ".$G/HEAD"
gdeny "C Write .$G/refs/${R}s/origin/HEAD" Write "$P" ".$G/refs/${R}s/origin/HEAD"
gdeny "C Edit .$GUP/config" Edit "$P" ".$GUP/config"
gdeny "C Edit l/info/exclude" Edit "$P" "l/info/exclude"

# ---- D. Scenario: controls in both fixtures; the last allow is an extra over-denial check (.G + hub)
for c in "$W" "$P"; do n=linked; [ "$c" = "$P" ] && n=main
  for p in ".${G}ignore" ".${G}attributes" ".${G}keep" "src/.$G" src/x.py .delix/report.md ".${G}hub/x.yml"; do
    allow "D $n: Write $p" write_gate.py "$(hj Write "$c" "$p" x)"
  done
  deny "D $n: Write docs/delix/STATE.json" write_gate.py "$(hj Write "$c" docs/delix/STATE.json x)" "$DOCS"
  deny "D $n: Write scripts/x.py" write_gate.py "$(hj Write "$c" scripts/x.py x)" "$PROT"
  deny "D $n: Edit tests/a_tests.sh" write_gate.py "$(hj Edit "$c" tests/a_tests.sh)" "$TEST"
done

# ---- E. Scenario: the gate is not active (no marker; the card accepted on origin/HEAD)
mv "$P/.delix/card" "$P/.delix/card.off"
allow "E no marker: Write .$G/HEAD" write_gate.py "$(hj Write "$P" ".$G/HEAD" x)"
mv "$P/.delix/card.off" "$P/.delix/card"
mv "$W/.delix/card" "$W/.delix/card.off"
allow "E no marker: Write .$G" write_gate.py "$(hj Write "$W" ".$G" x)"
mv "$W/.delix/card.off" "$W/.delix/card"
$G -C "$P" fetch -q "$SRC" "+refs/heads/main:refs/${R}s/origin/main"
$G -C "$P" symbolic-ref "refs/${R}s/origin/HEAD" "refs/${R}s/origin/main"
allow "E card accepted on origin/HEAD: Write .$G/HEAD" write_gate.py "$(hj Write "$P" ".$G/HEAD" x)"
$G -C "$P" symbolic-ref --delete "refs/${R}s/origin/HEAD"

# ---- F. Scenario: a listed and approved .G
card "$W" yes ".$G" scripts/x.py
gdeny "F listed and approved: Write .$G" Write "$W" ".$G"
allow "F control: listed and approved scripts/x.py" write_gate.py "$(hj Write "$W" scripts/x.py x)"
card "$P" yes ".$G/HEAD"
gdeny "F listed and approved: Write .$G/HEAD" Write "$P" ".$G/HEAD"
card "$W" no src/free.py; card "$P" no src/free.py

# ---- G. Scenario: a delix.json the gate cannot read (Spec D REQ-2 message)
cp "$W/docs/delix/delix.json" "$T/dj.bak"; printf '{"protected_paths": [' > "$W/docs/delix/delix.json"
deny "G broken delix.json: Write .$G" write_gate.py "$(hj Write "$W" ".$G" x)" "$CONFIG"
cp "$T/dj.bak" "$W/docs/delix/delix.json"

# ---- H. Extra (K364): the exclude command that the deny text gives passes the Bash gate
allow "H Bash: the exclude command of the deny text" bash_gate.py "$(hj Bash "$W" "echo .delix/ >> \"\$($G rev-parse --$G-path info/exclude)\"")"

# ---- I. The lead's repro (spec section 7): Write junk to .G, then Write docs/delix/STATE.json
run write_gate.py "$(hj Write "$W" ".$G" junk)"
if [ $RC -eq 0 ] && isdeny && [ "$(why)" = "$(gmsg ".$G")" ] && clean; then ok "I repro: Write .$G is denied"
else
  ko "I repro: Write .$G is denied" "exit $RC: $OUT $ERR"
  if [ $RC -eq 0 ] && ! isdeny; then cp "$W/.$G" "$T/gitfile.bak"; printf junk > "$W/.$G"; fi  # what the Write tool does
fi
deny "I repro: then Write docs/delix/STATE.json is still denied" write_gate.py "$(hj Write "$W" docs/delix/STATE.json x)" "$DOCS"
[ -f "$T/gitfile.bak" ] && cp "$T/gitfile.bak" "$W/.$G"

rm -rf "$T"; [ $FAIL -eq 0 ] && echo "ALL PASSED" || { echo "FAILED"; exit 1; }
```
**Expected counts (measured by the lead, see the prototype above):**

| Group | Cases | Base `af6c35b` | With the fix |
|---|---|---|---|
| A | 25 | 24 ✘ (only the `docs/delix` follow-up passes) | 25 ✔ |
| B | 6 | 6 ✘ | 6 ✔ |
| C | 4 | 4 ✘ | 4 ✔ |
| D | 20 | 20 ✔ | 20 ✔ |
| E | 3 | 3 ✔ | 3 ✔ |
| F | 3 | 2 ✘ (the control passes) | 3 ✔ |
| G | 1 | 1 ✔ | 1 ✔ |
| H | 1 | 1 ✔ | 1 ✔ |
| I | 2 | 2 ✘ | 2 ✔ |
| **Total** | **65** | **38 ✘, 27 ✔** | **65 ✔** |

**Fallbacks:**
- If git refuses to commit or check out the tracked symlinks `l` or `d`, create them untracked in W and P after the checkout, and say so in the report.
- If case H is denied, stop with `NEEDS_CONTEXT` and paste the message: the deny text would point to a blocked route (K364).

## Global Constraints (verbatim from the spec, or from repo rules)
- "Eşleşme `common.matches(path, [".git/**"], cwd)` ile yapılır: verilen yol ya da realpath, NFD + `casefold` katlanmış (Spec D REQ-5). Kural `docs/delix/**` kuralından sonra, Files izninden önce durur: listelenmiş ve `🔐 Approved` taşıyan kart da `.git`'i açamaz."
- "REQ-1 yalnız ret yönündedir; hiçbir yazımı açmaz. Çözülemeyen yol bugünkü gibi `docs/delix/**` kuralında fail closed reddedilir (kural ondan sonra durur)."
- "Şema değişmez. … Yeni git çağrısı yok." (§5) "var olan test dosyası değişmez." (§7)
- Python 3.9 stdlib only and no new dependency. Write no `X | Y` annotations.
- No new `re.` call in `scripts/`, so no ReDoS run is needed.
- New lines are ASCII, with no invisible character. New lines in `scripts/` are at most 120 characters.
- The suites run on Python 3.9.6 (Mac) and through the 3.13 shim; CI runs 3.12.
- Case E "accepted" needs git 2.44 or later (Spec D §6). Put `git --version` in the report.

## Steps
1. Baseline: `for t in tests/*_tests.sh; do bash "$t" || exit 1; done` → 18 files, exit 0.
2. Write `tests/gitdir_gate_tests.sh` with the Write tool and run it on the base code. You should see **red**: 38 `✘`, last line `FAILED`, exit 1. Write the counts in the report.
3. Apply W1 and W2 with the Edit tool. `python3 -c "import ast,sys; ast.parse(open(sys.argv[1]).read())" scripts/write_gate.py` prints nothing.
4. You should see **green**. Then run every suite on Python 3.9.6 and on the 3.13 shim.
5. Write the Verification output to `.delix/evidence/verification.txt`, one block per command: `$ <command>`, its output, `[exit <code>]`.
6. Commit and push:
   - Run `git add scripts/write_gate.py tests/gitdir_gate_tests.sh` in a call of its own.
   - Commit `T059: yazma kapısı .git yazımını reddeder (Spec E REQ-1)` in a call of its own.
   - Run `git push -u origin HEAD` alone, from the worktree root.
   - Write the PR body with the Write tool and open the PR with `--body-file`. The body has `## How I tested`.

## Verification command → expected output
- `bash tests/gitdir_gate_tests.sh` → first line `git version …`, 65 `✔`, no `✘`, last line `ALL PASSED`, exit 0.
- `for t in tests/*_tests.sh; do bash "$t" || exit 1; done` → exit 0, 19 files, no `✘`. Run it on 3.9.6 and through `P13="$(mktemp -d)" && ln -s /opt/homebrew/bin/python3.13 "$P13/python3" && for t in tests/*_tests.sh; do PATH="$P13:$PATH" bash "$t" || exit 1; done`.
- `claude plugin validate .` → exit 0.
- `grep -nF -e 'if matches(path, ["docs/delix/**", card], cwd):' -e 'if matches(path, [".git/**"], cwd):' -e 'files, approved = read_card()' scripts/write_gate.py` → lines `109:`, `114:`, `119:` in that order.
- Each `grep -cF` gives `1`:
  - `"is the worktree's .git; the implementer cannot change it with this tool "` in `scripts/write_gate.py`;
  - `'file, docs/delix/** or .git; a protected path'` in `scripts/write_gate.py`.
- `wc -l < scripts/write_gate.py` → `139`.
- `git diff --numstat origin/main...HEAD` → exactly `7	1	scripts/write_gate.py` and `<n>	0	tests/gitdir_gate_tests.sh`.
- `git diff -U0 origin/main...HEAD -- scripts | grep -E '^\+.*\bre\.'` → no output.
- Added lines longer than 121 characters: `git diff -U0 origin/main...HEAD -- scripts | python3 -c "import sys; [print(len(l), l[:60]) for l in sys.stdin.read().splitlines() if l.startswith('+') and not l.startswith('+++') and len(l) > 121]"` → no output.
- Trigger words: `grep -cwF -e git -e push -e update-ref -e remote -e send -e triage -e script tests/gitdir_gate_tests.sh` → `0`.
- Non-ASCII bytes: `python3 -c "import sys; d=open(sys.argv[1],'rb').read(); print(sum(1 for b in d if b > 126 or (b < 32 and b not in (9, 10))))" tests/gitdir_gate_tests.sh` → `0`.

## Review Focus
- **Scenarios to cases:**
  - bağlı worktree'nin gitfile'ı (A, 24 forms plus the `docs/delix` follow-up)
  - symlink üzerinden (B)
  - ana checkout kart worktree'si (C)
  - kontroller (D)
  - kapı etkin değil (E)
  - listelenmiş `.git` (F)
  - okunamayan `delix.json` (G)
  - repro (I)
  - extras: H (K364) and `.github/x.yml` in D
- **Message:** byte for byte equal to spec line 37, both in the code and in `gmsg`. The test compares the decoded reason.
- **Order:** after the config and `docs/delix` rules, so an unresolvable path keeps the `docs/delix` message (K360). Before `read_card`, so Files cannot open `.git`.
- **Over-denial:** `.gitignore`, `.gitattributes`, `.gitkeep`, `.github/…` and `src/.git` are allowed. The cause is `_match_one` on `.git/**` (K360).
- **Not re-tested here:** the §6 claim that the common git dir and the `gitdir` record sit outside cwd (A13). qa may run `Write ../../../.git/info/exclude` from W and expect the A13 message.
- **Unchanged:** Bash on `.git` stays allowed (K361, the known limit T060 writes); no Bash rule is added.

## Don'ts
- Untouchable:
  - `scripts/common.py`, `scripts/bash_gate.py`, `scripts/stop_gate.py`, `scripts/trust.py`, `hooks/hooks.json`, `.github/**`, `docs/delix/**` (STATE.json too), `plugins/**`;
  - `README.md`, `README.tr.md`, `CHANGELOG.md`, `site/**`, `skills/**`, `agents/**`, `templates/**`;
  - every existing test file.
- Change no signature. Add no git call, no option and no dependency. If a test looks wrong, stop with `NEEDS_CONTEXT`.

## Out of scope (each with the reason)
- Denying Bash writes to `.git` (K361), and a worktree-outside check in the Bash rule (K358): both are T060 known limits.
- `card_path` failing closed on a broken git (K359).
- Nested `.git` and submodules (spec §2).
- The implement skill's `.git/info/exclude` line (`skills/implement/SKILL.md:17-18`): the deny text gives the command (K364).

## Report contract
`.delix/report.md` (at most 1K tokens) holds:
- the status token;
- the red and green counts;
- the Verification outputs, also in `.delix/evidence/verification.txt`;
- `python3 --version` (3.9.6 and 3.13) and `git --version`;
- the PR number in the `**PR:**` line, and the branch;
- assumptions, including whether the symlink fallback was used;
- every hook denial of your own commands.

Do not write STATE.json. Read only this card and spec §1–§7, K358–K365.

## Review findings (filled by the lead)
- Round 1 (PR #91 @ `5e59102c54c8bdd2cdcf9e92b6b219490c1a4729`): deterministic gate green. Both files equal the lead's
  prototype (`1a2193d18f2990e7`, `f2a3b69481c873d3`; numstat 7/1 and 135/0). The lead's full suite on the archived
  commit: 19 files, 1622 `✔`, 0 `✘` on Python 3.9.6 and on the 3.13.13 shim. CI `test` (3.12) and `check` pass; Stop
  gate and Verification `[exit 0]`. Lead repro with this commit's hooks in a temp card worktree: Write `.git`,
  `./.git` and `.GIT` are denied; Write to the common git dir (`../../../.git/info/exclude`, absolute) and to the
  `gitdir` record is denied (A13); `.gitignore` and `src/.git` are allowed. After junk is written to `.git` outside
  the hooks they are off (K361), and Bash writes outside cwd are allowed (K358); both are T060's known limits.
  qa **ACCEPT** (P0 0, P1 0):
  - P2, noted (no fix): `.delix/evidence/verification.txt` summarises the new test's output instead of copying it;
    the full run is in `.delix/test-result.txt` and the counts agree.
  security **🔐 HUMAN_APPROVAL**: no finding. The protected path carries the Approved line (`bcc2928`, an ancestor of
  `5e59102`).
  - Unsure (two, pre-existing, all implementer rules): a leading `~` and surrounding whitespace in `file_path`. The
    lead checked this with Claude Code 2.1.309 and the installed hooks, with its own session in a temp card worktree.
    The Write tool expands `~` and trims the whitespace before the PreToolUse hook runs. In all four tries the hook
    got the absolute path and denied the protected path. Not a finding.
  - `/security-review` was not run: it reviews the current branch, and the lead's checkout stays on main.
