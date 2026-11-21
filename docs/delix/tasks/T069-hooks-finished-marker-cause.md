# T069 🔐 — Hooks: when a finished card's marker blocks the next one, the deny names the cause (I002)

| id | size | tier | role | wave | status |
|---|---|---|---|---|---|
| T069 | S | 3 | backend | 37 | open |

**🔐 Approved:** 2026-11-21 tahircengiz

> 🔐 Tier 3: `scripts/common.py` and `scripts/write_gate.py` are protected (`docs/delix/delix.json:13`, `:10`). After the
> maintainer's yes in chat for this card, the lead adds the Approved line and commits it to main before the session
> starts. The session branches from that commit.

**Goal (1 sentence):** When the write gate denies a new `.delix/card` (MARKER_DENY), the message adds one `Cause:`
sentence if the old card is in fact finished but one of two lead-side gaps hides it (H1: no `file` in its record;
H2: origin/HEAD is not the default branch), and the lead skills close both gaps. The decision itself does not change.
· **Source:** intake I002 (F033), `docs/delix/intake.json`

**Docs/site:** none in this card. README, README.tr, `site/**` and CHANGELOG go with T070.

## Files (disjoint ownership; do not touch files owned by another card)
- Modify: `scripts/common.py` (E1 lines 67–79; E2 insert before line 113)
- Modify: `scripts/write_gate.py` (E3 lines 11–12; E4 line 96)
- Modify: `skills/dispatch/SKILL.md` (E5 line 13; E6 line 16; E7 insert after line 37)
- Modify: `skills/implement/SKILL.md` (E8 line 25)
- Create: `tests/finished_marker_tests.sh` (E9)
- Test: no existing test file changes.

## Interfaces
- **Consumed, unchanged:**
  - `common.git(cwd, *args)`, `common.card_id(text)`, `common._trusted_json(cwd, sha, rel)`, `common.delix_json(cwd)`
  - `common.deny(reason)`
  - `write_gate.MARKER_DENY`: its text stays byte for byte.
- **Produced (`scripts/common.py`):**
  - `_ref_sha(cwd, ref) -> str | None`: today's full-ref check, with the ref name as a parameter.
  - `_finished_at(cwd, sha, marker) -> str | None`: today's decision at a given commit, behaviour unchanged.
  - `_card_finished(cwd, marker)`: same signature and result as today (`_finished_at` at origin/HEAD's sha).
  - `_safe_branch(name) -> bool`.
  - `marker_cause(cwd, marker) -> str`: `""` or exactly one sentence starting `Cause: `; it never raises.
- **Produced (deny message):** `MARKER_DENY.format(<id>)`. When `marker_cause` is non-empty, one space and the sentence
  follow it:
  - H1: `Cause: the record of <id> in the STATE on origin/HEAD is finished but has no file field; the lead sets file to the card path in .delix/card and pushes.`
  - H2 (round 2 text, see Review findings): `Cause: the card is finished in the STATE on origin/<Y>, the default_branch in the worktree delix.json, but refs/remotes/origin/HEAD does not point at it; the lead runs the origin/HEAD check of /delixcrew:dispatch step 4 with default_branch from the main checkout.`
  - T070 documents these two texts.
- **Unchanged:** `card_path`, the stale stderr line, `stop_gate.py`, `bash_gate.py` (owned by T063).

## Global Constraints
- Fail closed. The decision does not change: K344, K345, K353 (same id; `file` equal to the marker; status `accepted`
  or `merged` an object; the live record decides; an archive only when the id is not live). K352: the single trust
  anchor is `refs/remotes/origin/HEAD`.
- Python 3.9 stdlib only. No new import, no new regex, no dependency.
- Git only through `git()`:
  - object reads with `--no-lazy-fetch --no-replace-objects` (through `_trusted_json`);
  - `show-ref` and `symbolic-ref` with `--no-lazy-fetch`.
- Deny messages carry only the card id from the marker (K348). `<Y>` comes from delix.json, never from the marker.
- New lines in `scripts/` and `skills/` are ASCII and at most 120 characters (121 in the diff). No new line ends
  with a space.
- The suites run on Python 3.9.6 and on the 3.13 shim. CI runs 3.12.

## Edit anchors (base main `c74146b962d3416c5b3341ccce82450f6e638cd4`)
- `scripts/`, `skills/` and `tests/` are the same on `9539d06` (T067 merged): `git diff --stat c74146b 9539d06 --
  scripts skills tests` prints nothing.
- `wc -l` on the base: common.py 351, write_gate.py 139, dispatch 85, implement 73.
- sha256 prefixes on the base: common.py `c8ff7c536c88`, write_gate.py `1a2193d18f29`, dispatch `45c7d5cc6042`,
  implement `274ab16dde01`.
- sha256 prefixes after E1–E9 (the lead's independent applier on a copy of the base): common.py `d62c5f99d676`,
  write_gate.py `de601974e61d`, dispatch `9e96ab17db30`, implement `2a0e6083215c`, test `b54c04df28c4`.
- Match each quoted current text exactly before you edit; if it differs, stop with `NEEDS_CONTEXT`.
- Use the Edit tool for E1–E8 (the Bash hook denies shell writes to protected paths) and the Write tool for E9.
- Copy leading spaces exactly.

**E1 · `scripts/common.py` · lines 67–79 · replace** (13 lines → 34). Current:
```python
def _card_finished(cwd, marker):
    """Spec D REQ-1 (K344, K345, K353): the card id when the card the marker names is finished on origin/HEAD (its
    record's file equals the marker; status accepted or merged an object); None in every other case (fail closed)."""
    try:
        cid = card_id(marker)
        if cid is None:
            return None
        r = git(cwd, "--no-lazy-fetch", "show-ref", "--verify", "refs/remotes/origin/HEAD")
        fields = r.stdout.split() if r is not None and r.returncode == 0 else []
        if len(fields) != 2 or fields[1] != "refs/remotes/origin/HEAD" or len(fields[0]) not in (40, 64) \
                or any(c not in "0123456789abcdef" for c in fields[0]):
            return None
        sha = fields[0]
```
New:
```python
def _ref_sha(cwd, ref):
    """Spec D REQ-1 (K352): the sha of the full ref <ref> (show-ref --verify, no lazy fetch; 40 or 64 lower-case
    hex, the second field exactly <ref>); None on any other result or error."""
    try:
        r = git(cwd, "--no-lazy-fetch", "show-ref", "--verify", ref)
        fields = r.stdout.split() if r is not None and r.returncode == 0 else []
        if len(fields) != 2 or fields[1] != ref or len(fields[0]) not in (40, 64) \
                or any(c not in "0123456789abcdef" for c in fields[0]):
            return None
        return fields[0]
    except Exception:
        return None


def _card_finished(cwd, marker):
    """Spec D REQ-1 (K344, K345, K353): _finished_at at the sha of refs/remotes/origin/HEAD, the single trust anchor;
    None when the marker has no card id, origin/HEAD does not verify or on any error (fail closed)."""
    try:
        if card_id(marker) is None:
            return None
        sha = _ref_sha(cwd, "refs/remotes/origin/HEAD")
        return _finished_at(cwd, sha, marker) if sha else None
    except Exception:
        return None


def _finished_at(cwd, sha, marker):
    """Spec D REQ-1 (K344, K345, K353): the card id when the card the marker names is finished in the STATE of commit
    <sha> (its record's file equals the marker; status accepted or merged an object; the live record decides, the
    archive only when the id is not live); None in every other case (fail closed)."""
    try:
        cid = card_id(marker)
        if cid is None:
            return None
```
Base lines 80–110 stay exactly as they are and become the rest of `_finished_at`: the blank line, `decide`, the
STATE and archive reads, and `except Exception: return None`.

**E2 · `scripts/common.py` · insert before base line 113 `def card_path(cwd):`** (44 lines). With Edit,
old_string is `def card_path(cwd):` and new_string is the block below followed by `def card_path(cwd):`. The block
ends with two blank lines:
```python
def _safe_branch(name):
    """I002: True for a str a Cause sentence may name as a branch (no regex): 1 to 100 of A-Z a-z 0-9 . _ - /; not
    starting with - . or /; no .. or //; not ending in /, . or .lock."""
    ok = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._-/"
    return (isinstance(name, str) and 0 < len(name) <= 100 and all(c in ok for c in name) and name[0] not in "-./"
            and ".." not in name and "//" not in name and not name.endswith(("/", ".", ".lock")))


def marker_cause(cwd, marker):
    """I002 (F033): "" or one sentence that starts with "Cause: ", for the deny of a marker that is not finished on
    origin/HEAD; a hint only, _card_finished still decides. H1, checked first: the live record at origin/HEAD is
    finished and its file is missing or not a str (never an archive record or a file that differs, K353). H2: the
    card is finished at origin/<Y>, Y the worktree delix.json default_branch and a safe branch name, and
    refs/remotes/origin/HEAD is not a symbolic ref to it. A sentence holds no marker text but the card id (K348);
    never raises ("" on any error)."""
    try:
        cid = card_id(marker)
        if cid is None:
            return ""
        head = _ref_sha(cwd, "refs/remotes/origin/HEAD")
        state = _trusted_json(cwd, head, "docs/delix/STATE.json") if head else None
        cards = state.get("cards") if state is not None else None
        rec = cards.get(cid) if isinstance(cards, dict) else None
        if isinstance(rec, dict) and not isinstance(rec.get("file"), str) \
                and (rec.get("status") == "accepted" or isinstance(rec.get("merged"), dict)):
            return (f"Cause: the record of {cid} in the STATE on origin/HEAD is finished but has no file field; "
                    "the lead sets file to the card path in .delix/card and pushes.")
        cfg = delix_json(cwd)
        y = cfg.get("default_branch") if cfg is not None else None
        if not _safe_branch(y):
            return ""
        ref = "refs/remotes/origin/" + y
        sha = _ref_sha(cwd, ref)
        r = git(cwd, "--no-lazy-fetch", "symbolic-ref", "--quiet", "refs/remotes/origin/HEAD")
        target = r.stdout.strip() if r is not None and r.returncode == 0 else ""
        if sha and target != ref and _finished_at(cwd, sha, marker) == cid:
            return (f"Cause: the card is finished in the STATE on origin/{y}, the default_branch in delix.json, "
                    f"but refs/remotes/origin/HEAD does not point at it; if {y} is the default branch, the user runs "
                    f"git remote set-head origin {y} in the main checkout.")
        return ""
    except Exception:
        return ""


```
After E1 and E2, `scripts/common.py` has **416** lines, and `def card_path(cwd):` is at line 178.

**E3 · `scripts/write_gate.py` · lines 11–12 · replace** (2 → 2). Current:
```python
from common import (CONFIG_DENY, REVIEWERS, card_id, card_path, deny, gate_config, matches,  # noqa: E402
                    matches_both, read_input, trust_file)
```
New:
```python
from common import (CONFIG_DENY, REVIEWERS, card_id, card_path, deny, gate_config, marker_cause,  # noqa: E402
                    matches, matches_both, read_input, trust_file)
```

**E4 · `scripts/write_gate.py` · line 96 · replace** (1 → 2; 4 leading spaces). Current:
```python
    deny(MARKER_DENY.format(card_id(card) or "unknown"))
```
New:
```python
    cause = marker_cause(cwd, card)  # I002 (F033): computed only on this deny path
    deny(MARKER_DENY.format(card_id(card) or "unknown") + (" " + cause if cause else ""))
```
After E3 and E4, `scripts/write_gate.py` has **140** lines. `MARKER_DENY` (lines 20–22) does not change.

**E5 · `skills/dispatch/SKILL.md` · line 13 · replace** (1 → 2). Current:
```text
as a single wave and go to step 2). Otherwise `Agent` with `delixcrew:architect`: the SPEC path, `docs/delix/delix.json` (protected paths, test paths, max parallel), "job B:
```
New:
```text
as a single wave, its record with `file` as below, and go to step 2). Otherwise `Agent` with `delixcrew:architect`:
the SPEC path, `docs/delix/delix.json` (protected paths, test paths, max parallel), "job B:
```

**E6 · `skills/dispatch/SKILL.md` · line 16 · replace** (1 → 3). Current:
```text
`## Wave plan` into `STATE.json.waves`, the cards into `STATE.json.cards` (status `open`, rounds 0).
```
New:
```text
`## Wave plan` into `STATE.json.waves`, the cards into `STATE.json.cards` (status `open`, rounds 0). Every card
record gets `file`: the card path exactly as the implementer writes it into `.delix/card`
(`docs/delix/tasks/T<nnn>-<slug>.md`); the hooks count a card as finished only through it (K353).
```

**E7 · `skills/dispatch/SKILL.md` · insert after base line 37** (line 40 after E5 and E6), whose content is
`One line per card for the user: card, role, tier, how to open it.`. It goes before the "Stop gate approval"
bullet. Insert 4 lines:
```text
- **origin/HEAD:** before the first session, check that `git symbolic-ref --short refs/remotes/origin/HEAD` prints
  `origin/<default_branch>`. Otherwise stop and give the user the one-line command to run in the main checkout,
  `git remote set-head origin <default_branch>`: you push your records to `<default_branch>` and the hooks read
  them from origin/HEAD, so a finished card's `.delix/card` would keep blocking the next card in its worktree.
```
After E5–E7, `skills/dispatch/SKILL.md` has **92** lines.

**E8 · `skills/implement/SKILL.md` · line 25 · replace** (1 → 2; 3 leading spaces). Current:
```text
   your final message with `BLOCKED`. If it allows it, move everything else in `.delix/` except `card` and
```
New:
```text
   your final message with `BLOCKED`; quote the deny message as it is above that token (its `Cause:` sentence, when
   present, tells the lead what to fix). If it allows it, move everything else in `.delix/` except `card` and
```
After E8, `skills/implement/SKILL.md` has **74** lines.

**E9 · `tests/finished_marker_tests.sh` · create** (107 lines, ASCII only):
```bash
#!/usr/bin/env bash
# T069 (intake I002, F033): when the write gate denies a new .delix/card because the old card is not finished on
# origin/HEAD, the message names the cause if it is one of two: H1, the live record at origin/HEAD is finished but has
# no string file; H2, the card is finished on origin/<default_branch of delix.json> and origin/HEAD does not point
# there. The decision is unchanged. The trigger words are assembled at run time; this file holds none of them, and it
# stays ASCII (check marks and the e-acute are octal escapes; in JSON it is a \uXXXX escape).
# Run: bash tests/finished_marker_tests.sh
set -u
unset DELIXCREW_FEEDBACK_DIR DELIXCREW_TRIAGE_DIR
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; S="$ROOT/scripts"; FAIL=0
G=gi; G="${G}t"; P=pu; P="${P}sh"; U=update; U="${U}-ref"; R=rem; R="${R}ote"
OK=$'\342\234\224'; NO=$'\342\234\230'; BS=$(printf '\134')
$G --version
T="$(mktemp -d)" || exit 1
W="$T/w"; SRC="$T/s"; DJ="$W/docs/delix/delix.json"; RO="refs/${R}s/origin"
GC="$G -c user.name=t -c user.email=t@t -c commit.gpgsign=false -c core.hooksPath=/dev/null"
C55="docs/delix/tasks/T055-x.md"; NEXT="docs/delix/tasks/T056-y.md"; FILE='"file": "'"$C55"'"'
MARKER="delixcrew: .delix/card names T055, which is not finished on origin/HEAD; this worktree belongs to that card. Write nothing under .delix; end with BLOCKED in your final message; the lead opens a new worktree."
H1="Cause: the record of T055 in the STATE on origin/HEAD is finished but has no file field; the lead sets file to the card path in .delix/card and ${P}es."
h2(){ printf 'Cause: the card is finished in the STATE on origin/%s, the default_branch in delix.json, but %s/HEAD does not point at it; if %s is the default branch, the user runs %s %s set-head origin %s in the main checkout.' "$1" "$RO" "$1" "$G" "$R" "$1"; }
SL="delixcrew: .delix/card names T055, which is accepted on origin/HEAD; implementer hooks stay inactive here. Move .delix aside before starting a new card."
PROT="is a protected path (scripts/x.py, Tier 3)"
cfg(){ # [<default_branch as JSON>]: the worktree delix.json; without an argument it has no default_branch
  d=""; [ $# -ge 1 ] && d=', "default_branch": '"$1"
  printf '{"test_command": "touch %s/MARK", "protected_paths": ["scripts/x.py"], "test_paths": ["tests/**"]%s}' \
    "$T" "$d" > "$DJ"; }
rec(){ # <status> [<more members>]: a STATE text with one T055 record
  printf '{"cards": {"T055": {"status": "%s"%s}}}' "$1" "${2:+, $2}"; }

# Fixture W, the card worktree (set up by direct calls, never through a hook)
mkdir -p "$W" && $G -C "$W" init -q && $G -C "$W" symbolic-ref HEAD refs/heads/claude/t1 \
  && $GC -C "$W" commit -q --allow-empty -m init || exit 1
mkdir -p "$W/.delix" "$W/docs/delix/tasks" "$W/scripts"
echo ".delix/" >> "$W/.$G/info/exclude"; echo "$C55" > "$W/.delix/card"; echo x > "$W/scripts/x.py"; cfg
printf '# T055 card\n\n## Files\n- Modify: `src/free.py`\n\n## Steps\n1. none\n' > "$W/$C55"
# Fixture S, the source repo: put commits a STATE on S main and fetches that commit into W's origin/<name>
mkdir -p "$SRC" && $G -C "$SRC" init -q && $G -C "$SRC" symbolic-ref HEAD refs/heads/main || exit 1; SN=0
put(){ # <name> <STATE text> [<path> <text>]: the only docs/ content of a new S main commit, fetched into origin/<name>
  rm -rf "$SRC/docs"; mkdir -p "$SRC/docs/delix"; printf '%s' "$2" > "$SRC/docs/delix/STATE.json"
  if [ $# -ge 4 ]; then mkdir -p "$SRC/$(dirname "$3")"; printf '%s' "$4" > "$SRC/$3"; fi
  SN=$((SN + 1)); $G -C "$SRC" add -A && $GC -C "$SRC" commit -q --allow-empty -m "s$SN" \
    && $G -C "$W" fetch -q "$SRC" "+refs/heads/main:$RO/$1"; }
oh(){ $G -C "$W" symbolic-ref "$RO/HEAD" "$RO/$1"; }  # origin/HEAD -> origin/<name>

hj(){ # <tool> <cwd> <path or command> [content]: hook input
  python3 -c 'import json, sys
tool, cwd, path = sys.argv[1], sys.argv[2], sys.argv[3]
ti = {"command": path} if tool == "Bash" else {"notebook_path": path} if tool == "NotebookEdit" else {"file_path": path}
if len(sys.argv) > 4:
    ti["content"] = sys.argv[4]
print(json.dumps({"tool_name": tool, "cwd": cwd, "tool_input": ti}))' "$@"; }
run(){ OUT=$(printf '%s\n' "$2" | python3 "$S/$1" 2>"$T/err"); RC=$?; ERR=$(cat "$T/err"); }
ok(){ echo "$OK $1"; }
ko(){ echo "$NO $1: $2"; FAIL=1; }
isdeny(){ printf '%s' "$OUT" | grep -qF '"permissionDecision": "deny"'; }
clean(){ ! printf '%s' "$ERR" | grep -qF Traceback; }
why(){ printf '%s' "$OUT" | python3 -c 'import json, sys
try:
    print(json.load(sys.stdin)["hookSpecificOutput"]["permissionDecisionReason"])
except Exception:
    print("")'; }
mk(){ # <name> <expected reason> [<tool>]: writing another card path into .delix/card is denied with exactly that reason
  run write_gate.py "$(hj "${3:-Write}" "$W" .delix/card "$NEXT")"; got=$(why)
  if [ $RC -eq 0 ] && isdeny && [ "$got" = "$2" ] && clean; then ok "$1"; else ko "$1" "exit $RC, reason: $got $ERR"; fi; }
prot(){ # <name>: the gate is still active: a protected path that is not in Files is denied
  run write_gate.py "$(hj Write "$W" scripts/x.py x)"
  if [ $RC -eq 0 ] && isdeny && printf '%s' "$OUT" | grep -qF -- "$PROT" && clean; then ok "$1"; else ko "$1" "exit $RC: $OUT $ERR"; fi; }
allow(){ run "$2" "$3"; if [ $RC -eq 0 ] && ! isdeny && clean; then ok "$1"; else ko "$1" "expected allow, exit $RC: $OUT $ERR"; fi; }
once(){ n=$(printf '%s\n' "$ERR" | grep -cxF -- "$SL"); if [ "$n" = 1 ]; then ok "$1"; else ko "$1" "stale line $n times: $ERR"; fi; }
stop(){ rm -f "$W/.delix/test-result.txt" "$T/MARK"
  run stop_gate.py "$(python3 -c 'import json, sys; print(json.dumps({"cwd": sys.argv[1], "stop_hook_active": False}))' "$W")"
  if [ $RC -eq 0 ] && clean && [ ! -e "$T/MARK" ] && [ ! -e "$W/.delix/test-result.txt" ]; then ok "$1"
  else ko "$1" "expected exit 0 and nothing run, exit $RC: $ERR"; fi; }
inactive(){ # <name>: the three hooks are inactive, each with the stale line once
  allow "$1: Write docs/delix/SPEC.md" write_gate.py "$(hj Write "$W" docs/delix/SPEC.md x)"; once "$1: write gate stale line once"
  allow "$1: Bash echo x > scripts/x.py" bash_gate.py "$(hj Bash "$W" "echo x > scripts/x.py")"; once "$1: Bash gate stale line once"
  stop "$1: Stop exits 0, nothing run"; once "$1: Stop gate stale line once"; }

# ---- H1: the live record at origin/HEAD is finished but has no string file (origin/HEAD -> origin/main, no default_branch)
put main "$(rec accepted "$FILE")"; oh main; inactive "1 C1 accepted, file equal"
put main "$(rec accepted)"; mk "2 C2 accepted, no file: H1" "$MARKER $H1"; prot "2 C2: the gate is still active"
for t in Edit MultiEdit NotebookEdit; do mk "2 C2 $t .delix/card: H1" "$MARKER $H1" "$t"; done
put main "$(rec escalated '"merged": {"pr": 7}')"; mk "3 merged an object, no file: H1" "$MARKER $H1"
put main "$(rec accepted '"file": null')"; mk "3 accepted, file null: H1" "$MARKER $H1"
put main "$(rec accepted '"file": "docs/delix/tasks/T055-other.md"')"; mk "4 file a different string: no cause" "$MARKER"
put main "$(rec in_progress)"; mk "4 in_progress, no file: no cause" "$MARKER"
put main '{"cards": {}, "archive": ["docs/delix/archive/old/STATE.json"]}' docs/delix/archive/old/STATE.json "$(rec accepted)"
mk "4 only an archive record, accepted, no file: no cause" "$MARKER"

# ---- H2: finished on origin/<default_branch> only, origin/HEAD elsewhere
put main "$(rec in_progress "$FILE")"; put v01 "$(rec accepted "$FILE")"; oh main; cfg '"v01"'
mk "5 C3 finished on origin/v01, origin/HEAD -> origin/main: H2" "$MARKER $(h2 v01)"; prot "5 C3: the gate is still active"
SHA=$($G -C "$W" rev-parse "$RO/main"); $G -C "$W" symbolic-ref --delete "$RO/HEAD"; $G -C "$W" $U "$RO/HEAD" "$SHA"
mk "5 origin/HEAD a plain ref, not symbolic: H2" "$MARKER $(h2 v01)"
$G -C "$W" $U -d "$RO/HEAD"; oh v01; inactive "6 C4 origin/HEAD -> origin/v01"; oh main
put main "$(rec accepted)"; mk "7 H1 and H2 both: the H1 sentence only" "$MARKER $H1"; put main "$(rec in_progress "$FILE")"

# ---- the default_branch name is a hint: only a safe name is used (these refs exist and hold the card finished)
L100=$(python3 -c 'print("a" * 100)'); L101="${L100}a"; NA=$(printf 'v\303\25101')
put "$L100" "$(rec accepted "$FILE")"; put "$L101" "$(rec accepted "$FILE")"; put "$NA" "$(rec accepted "$FILE")"
cfg "\"$L100\""; mk "8 control: default_branch of 100 characters: H2" "$MARKER $(h2 "$L100")"
cfg "\"$L101\""; mk "8 default_branch of 101 characters: no cause" "$MARKER"
cfg '"v'"$BS"'u00e901"'; mk "8 default_branch v + U+00E9 + 01: no cause" "$MARKER"
for b in '"v 01"' '"-v01"' '"v..01"' 5; do cfg "$b"; mk "8 default_branch $b: no cause" "$MARKER"; done
cfg '"v01"'; $G -C "$W" $U -d "$RO/v01"; mk "9 default_branch v01, origin/v01 missing: no cause" "$MARKER"

rm -rf "$T"; [ $FAIL -eq 0 ] && echo "ALL PASSED" || { echo "FAILED"; exit 1; }
```

**Expected counts (34 checks):**
- On the base `c74146b`, 10 `✘` and 24 `✔`, last line `FAILED`, exit 1. The red checks:
  - `2 C2 accepted, no file: H1`
  - `2 C2 Edit|MultiEdit|NotebookEdit .delix/card: H1` (3)
  - `3 merged an object, no file: H1`
  - `3 accepted, file null: H1`
  - `5 C3 … : H2`
  - `5 origin/HEAD a plain ref, not symbolic: H2`
  - `7 H1 and H2 both: the H1 sentence only`
  - `8 control: default_branch of 100 characters: H2`
- After E1–E4, 34 `✔` and 0 `✘`, last line `ALL PASSED`, exit 0.

## Steps
1. **Baseline:** run `for t in tests/*_tests.sh; do bash "$t" || exit 1; done`. Expect exit 0 with 20 files (21 if
   T063's `tests/redirect_gate_tests.sh` is already on main). Run `wc -l` on the four files and compare with the
   anchor section.
2. **Red:** write E9 with the Write tool and run `bash tests/finished_marker_tests.sh` on the base code. Expect red:
   10 `✘` / 24 `✔`, the red checks exactly as listed above, exit 1. Write the counts in the report.
3. **Implement:** apply E1, E2, E3 and E4 with the Edit tool. Then run
   `python3 -c "import ast,sys; [ast.parse(open(p).read()) for p in sys.argv[1:]]" scripts/common.py scripts/write_gate.py`.
   It prints nothing.
4. **Green:** run E9 again and expect 34 `✔`, 0 `✘`. Run `bash tests/stale_card_tests.sh` unchanged: `ALL PASSED`.
5. Apply E5–E8 with the Edit tool. Run the full Verification on 3.9.6 and on the 3.13 shim.
6. Write the Verification output to `.delix/evidence/verification.txt`, one block per command: `$ <command>`, its
   output, `[exit <code>]`.
7. **Commit and push.** Run each command in a call of its own:
   - `git add scripts/common.py scripts/write_gate.py skills/dispatch/SKILL.md skills/implement/SKILL.md tests/finished_marker_tests.sh`
   - `git commit -m "T069: bitmiş kart işareti reddi neden cümlesi taşır; dispatch file alanı ve origin/HEAD denetimi (I002)"`
   - `git push -u origin HEAD`, from the worktree root.
   - Write `.delix/pr-body.md` with the Write tool. It holds `## How I tested` (the commands below with their
     outputs) and the red/green counts. Then run
     `gh pr create --title "<commit subject>" --body-file .delix/pr-body.md`.

## Verification command → expected output
- `bash tests/finished_marker_tests.sh` → 34 `✔`, 0 `✘`, last line `ALL PASSED`, exit 0.
- `bash tests/stale_card_tests.sh` → `ALL PASSED`, exit 0.
  `git diff --quiet origin/main...HEAD -- tests/stale_card_tests.sh` → exit 0.
- `for t in tests/*_tests.sh; do bash "$t" || exit 1; done` → exit 0 with 21 files (22 with T063), no `✘`.
  Also run it through the 3.13 shim:
  `P13="$(mktemp -d)" && ln -s /opt/homebrew/bin/python3.13 "$P13/python3" && for t in tests/*_tests.sh; do PATH="$P13:$PATH" bash "$t" || exit 1; done`
  → exit 0.
- `claude plugin validate .` → exit 0.
- `git diff --name-only origin/main...HEAD` → exactly the 5 Files paths.
- `wc -l scripts/common.py scripts/write_gate.py skills/dispatch/SKILL.md skills/implement/SKILL.md tests/finished_marker_tests.sh`
  → 416, 140, 92, 74, 107.
- `grep -c marker_cause scripts/write_gate.py` → `2` (the import and the deny path only).
- `python3 -c "import sys; sys.path.insert(0, 'scripts'); import common; print(repr(common.marker_cause('/nonexistent', 'docs/delix/tasks/T1-x.md')), repr(common.marker_cause('.', None)))"`
  → `'' ''`.
- No new regex:
  `git diff -U0 origin/main...HEAD -- scripts | grep '^+' | grep -cE 're\.(compile|search|match|fullmatch|findall|finditer|sub|split)\('`
  → `0`.
- Added lines over 121 characters:
  `git diff -U0 origin/main...HEAD -- scripts skills | python3 -c "import sys; [print(len(l), l[:60]) for l in sys.stdin.read().splitlines() if l.startswith('+') and not l.startswith('+++') and len(l) > 121]"`
  → no output.
- Non-ASCII bytes in the test:
  `python3 -c "import sys; d=open(sys.argv[1],'rb').read(); print(sum(1 for b in d if b > 126 or (b < 32 and b not in (9, 10))))" tests/finished_marker_tests.sh`
  → `0`.

## Review Focus
- **Same decision:** the `_finished_at` extraction and `_ref_sha` behave exactly like the old code.
  - Base lines 80–110 are untouched.
  - The full-ref check equals base lines 74–78 with `ref` in place of the literal.
  - A marker without an id still returns before any git call.
  - `tests/stale_card_tests.sh` is unchanged and green.
- **Never raises, costs nothing on allowed writes:** `marker_cause` is wrapped in `try`/`except Exception` and
  returns `""`. It is called only on the MARKER_DENY path (`write_gate.py` E4).
- **H1 scope:** H1 fires only for a live `cards[cid]` dict at origin/HEAD that is finished and whose `file` is missing
  or not a str. It never fires for an archive-only record, a `file` string that differs (K353), or a record that is
  not finished (cases 4).
- **Branch name:** `_safe_branch` is the rule set from the approved design, with no regex. The 101-character and
  non-ASCII cases have a real finished ref, so they test the name check itself; the 100-character case is the
  control.
- **Exactly one sentence:** at most one `Cause:` (case 7 compares the full reason). No marker text other than the
  id appears in either sentence (K348).
- **Security (H2):** `<Y>` comes from the worktree's `delix.json`, which a card branch can change. The safeguards:
  - H2 needs `origin/<Y>` to verify and to hold the card finished in a trusted read;
  - the sentence says "if `<Y>` is the default branch";
  - the hooks never act on `<Y>`; only the user runs the command.
  Check that nothing else reads `<Y>`.

## Don'ts
- Do not touch:
  - `scripts/bash_gate.py` (T063), `scripts/stop_gate.py`, `scripts/trust.py`, `hooks/hooks.json`, `.github/**`;
  - `docs/delix/**` (STATE.json too), `templates/**`, `agents/**`, other skills;
  - `README.md`, `README.tr.md`, `site/**`, `CHANGELOG.md`;
  - every existing test file.
- Do not change `MARKER_DENY`, the stale stderr line, `card_path`, or what counts as finished.
- Add no import, regex, dependency or option.
- Do not run `git remote set-head`, `update-ref` or `symbolic-ref` in the worktree (the Bash hook denies ref writes).
  The test runs them only inside its own temp repos.
- No line in a new text ends with a space.
- If a test looks wrong, stop with `NEEDS_CONTEXT`; do not change it.

## Out of scope (each with the reason)
- README, README.tr, `site/**` and CHANGELOG: T067 and T068 hold them now; T070 documents the two sentences.
- `templates/STATE.json`: it already has `file`.
- Reading `default_branch` from origin/HEAD's tree: the approved design takes it from the worktree copy, as a hint.

## Report contract
`.delix/report.md` (at most 1K tokens) holds:
- the status token;
- the red and green counts and the names of the red checks;
- the Verification outputs (also in `.delix/evidence/verification.txt`);
- `python3 --version` (3.9.6 and 3.13) and `git --version`;
- the PR number in the `**PR:**` line, and the branch;
- assumptions;
- every hook denial of your own commands.

Do not write STATE.json. Read only this card and the dispatch prompt.

## Review findings (filled by the lead)

### Round 1 (head `42e9ead5187e9857768883a7328e69d542580fb7`): qa ACCEPT, security 🔐 HUMAN_APPROVAL
Deterministic gates green: Stop gate `[exit 0]`, CI `check` and `test` pass, the five files equal the lead's
prototype (sha256), the full suite from `git archive 42e9ead` exits 0 on 3.9.6 and 3.13.13.

- **S1 (security Low, fixed in round 2 by the maintainer's choice, 2026-11-21).** `scripts/common.py:170-172`: the
  H2 sentence puts `<Y>`, read from the worktree copy of `docs/delix/delix.json`, into a command for the user
  (`git remote set-head origin <Y>`). A card branch can set `default_branch` to a branch it pushed with a STATE that
  marks its card finished; the deny message then recommends moving `refs/remotes/origin/HEAD`, the single trust
  anchor, to that branch, which would switch the hooks off in every worktree. Lead's reproduction: on head the deny
  reads `... the user runs git remote set-head origin claude/t1-pushed in the main checkout.`; on main the same
  setup gives no `Cause:` sentence, so the exposure is new with this card. Fix: H2 keeps the detection and names
  `<Y>`, but gives no command; it sends the lead to the dispatch step 4 check, which reads `default_branch` from the
  main checkout. Exact lines:
  - `scripts/common.py` lines 170–172, current:
    ```python
                return (f"Cause: the card is finished in the STATE on origin/{y}, the default_branch in delix.json, "
                        f"but refs/remotes/origin/HEAD does not point at it; if {y} is the default branch, the user runs "
                        f"git remote set-head origin {y} in the main checkout.")
    ```
    new:
    ```python
                return (f"Cause: the card is finished in the STATE on origin/{y}, the default_branch in the worktree "
                        "delix.json, but refs/remotes/origin/HEAD does not point at it; the lead runs the origin/HEAD "
                        "check of /delixcrew:dispatch step 4 with default_branch from the main checkout.")
    ```
  - `tests/finished_marker_tests.sh` line 20 (this card's own new test; only this line), current:
    `h2(){ printf 'Cause: the card is finished in the STATE on origin/%s, the default_branch in delix.json, but %s/HEAD does not point at it; if %s is the default branch, the user runs %s %s set-head origin %s in the main checkout.' "$1" "$RO" "$1" "$G" "$R" "$1"; }`
    new:
    `h2(){ printf 'Cause: the card is finished in the STATE on origin/%s, the default_branch in the worktree delix.json, but %s/HEAD does not point at it; the lead runs the origin/HEAD check of /delixcrew:dispatch step 4 with default_branch from the main checkout.' "$1" "$RO"; }`
  - Lead's prototype on `git archive 42e9ead`: `finished_marker_tests.sh` 34 `✔` / 0 `✘`, `stale_card_tests.sh`
    `ALL PASSED`, `wc -l` 416 and 107 (unchanged), the three new lines 114, 115 and 102 characters,
    `grep -c set-head scripts/common.py tests/finished_marker_tests.sh` gives `0` and `0`; sha256 prefixes after:
    common.py `974a2e00b1ac`, test `631be80d78ae` (write_gate, dispatch, implement unchanged).
- Notes, no fix (not findings): qa unsure, the worktree `delix.json` is read without a size cap (the same read as
  `gate_config`, not new); security unsure, deny-path time with 20 archive STATEs of ~1 MiB on both refs: lead
  measured 0.39–0.57 s on main and 0.78–0.81 s on head against the 10 s hook timeout (and a timeout still blocks);
  whether Bash can rewrite the worktree `delix.json` is T063's scope and no longer matters for S1 after the fix.
