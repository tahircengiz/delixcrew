# T051 — Board fixes: an escalated card keeps its worktree (K297), the dated Approved line (K310), the panel's `.delix` rule in board.py (K293), control characters in `plain()` (T043 P2)

| id | size | tier | role | wave | status |
|---|---|---|---|---|---|
| T051 | S | 2 | frontend | 22 | open |

> **Tier 2.** None of the four Files is in `docs/delix/delix.json` `protected_paths` (lines 7–18). `scripts/write_gate.py`
> is protected and is not touched (O1). Tier 2 because the card changes when the board offers a cleanup command and when
> it calls a tier 3 card approved.
>
> - **Source:** the drift check of the follow-up round's close (STATUS §13, "Açık iş (takip turu kapanışı, 2026-11-17)";
>   spec K326) and T043's review note P2. The user chose this round on 2026-11-17 ("Board düzeltmeleri").
> - **Why one card for both surfaces:** REQ-6 asks `scripts/board.py` and the delix-board panel for the same answer on
>   the same raw input. Three of the four items are a gap between the two surfaces or between them and the spec. The
>   parity fixture does not change.

**Goal (1 sentence):** Both board surfaces give no `remove_worktree` on the 7-day idle path to a card whose trusted
status is `escalated`, count a tier 3 card as approved only with write_gate's dated Approved line in the header, decide
"no card" by the panel's `.delix` listing rule, and draw data text with control, line and paragraph separator characters
turned into spaces.

**Spec:** `docs/delix/specs/C-board-visibility.md` REQ-4 (amended by K327), REQ-6, K293, K297, K310 (its "Yolda çıktı"
item), K326, K327.

**Docs/site:** none (D6). Do not touch `README.md`, `README.tr.md`, `site/**` or `CHANGELOG.md`.

## Files (disjoint ownership; do not touch files owned by another card)
- Modify: `scripts/board.py` (anchors B1 to B5)
- Modify: `plugins/delix-board/hooks/parse.ts` (anchors P1 to P5)
- Test: `tests/board_tests.sh` (anchor T1, one insertion after line 478; no existing line changes)
- Test: `plugins/delix-board/tests/board.test.tsx` (anchors T2 and T3, one line after line 7 and one block after line
  946; no existing line changes)

## Edit anchors (base main 5b2fa5c, full SHA 5b2fa5cba5712391cd94821ce920b8e0300fef3b)
The dispatch commit adds docs only; on it the four files are byte-equal to 5b2fa5c. The code blocks sit at the top
level: copy each line exactly as it stands (indentation included). Line numbers are the base's; apply the anchors
of one file from the bottom up so they stay valid.

| File | base lines | base sha256 | after lines | after sha256 |
|---|---|---|---|---|
| `scripts/board.py` | 922 | `a8b7088a939721c7adb56ed94c2bc6d54ad4b7dc99d59ccae8afde069abad42b` | 924 | `dc1e180b76ec722a2d78bad9f1a9651e92370fd7226feb1483df474219a39c4d` |
| `plugins/delix-board/hooks/parse.ts` | 819 | `0bf30f132b78e5caaab0695e2dd93cdd7ccf4975aeebe4e9a36806c5aa36ec0d` | 822 | `bce409393acd9f0b572d14f7a775474f2dab478c379364e801bcd6bab9ea0fe4` |
| `tests/board_tests.sh` | 479 | `326878c47cc062a6c633a4e692fadc5b0c0d69e969d2deed87869bd56b40bc3e` | 547 | `8b35062f2861a8947d06bf88f98fe1338456ee57af36115bcb4a6df7e79b476b` |
| `plugins/delix-board/tests/board.test.tsx` | 946 | `78f002e93015839f15e27490614ecba4e20cc5aa983e9df13c93f6833eb7a0ef` | 993 | `edd51e8745fd76db8298d8569d9fd447c257c0db557975bcb7b937fa7db71587` |

### `scripts/board.py`

**B1, line 129, replace** this line:
````text
APPROVED = "**🔐 Approved:**"
````
with these 3 lines:
````text
# K310: write_gate's Approved form (searched in the header only); ASCII digits, and the character after the date
# is whitespace neither in Python nor in JavaScript, so the panel's APPROVED_RE accepts the same lines
APPROVED = re.compile(r"^\*\*\U0001F510 Approved:\*\* [0-9]{4}-[0-9]{2}-[0-9]{2} [^\s\x1c-\x1f\x85\ufeff]", re.M)
````

**B2, lines 218 to 228, replace** these 11 lines:
````text
def _card_present(wt):
    """K293: <wt>/.delix/card exists in any form (regular file, link incl. a dangling one, directory, FIFO, a file
    that cannot be read). lstat follows no final link; only "not found" and "not a directory" count as absent, any
    other error as present (call 5 then does not run: fail closed)."""
    try:
        os.lstat(os.path.join(wt, ".delix", "card"))
    except (FileNotFoundError, NotADirectoryError):
        return False
    except (OSError, ValueError):
        return True
    return True
````
with these 10 lines:
````text
def _card_present(wt):
    """K293, the panel's rule: <wt>/.delix/card is there in any form when the listing of .delix names an entry `card`,
    whatever its kind (a link is listed, not followed, a dangling one too). A .delix that cannot be listed but is a
    directory counts as holding one (call 5 then does not run: fail closed); one that neither lists nor is a
    directory holds none."""
    dot = os.path.join(wt, ".delix")
    try:
        return "card" in os.listdir(dot)
    except (OSError, ValueError):
        return os.path.isdir(dot)
````

**B3, line 528, replace** this line:
````text
            if not isinstance(text, str) or not any(line.startswith(APPROVED) for line in text.split("\n")):
````
with this line:
````text
            if not isinstance(text, str) or not APPROVED.search(text.split("\n## ", 1)[0]):
````

**B4, after line 641, insert** 1 line. Above: line 641 `merged = isinstance(c, dict) and c.get("status") == "accepted" and isinstance(c.get("merged"), dict)`; below: line 642 `last = _latest(r["ctime"], _changed_at(r["w"])) if r["role"] == "lead" else r["ctime"]`.
````text
        escalated = isinstance(c, dict) and c.get("status") == "escalated"  # K297: stays under Waiting on you
````

**B5, line 645, replace** this line:
````text
        if merged or aged:
````
with this line:
````text
        if merged or (aged and not escalated):
````

### `plugins/delix-board/hooks/parse.ts`

**P1, after line 411, insert** 2 lines. Above: line 411 `const LOCK = '\u{1F510}'`; below: line 412 `export const BRANCH_RE = /^[A-Za-z0-9][A-Za-z0-9._-]*(\/[A-Za-z0-9][A-Za-z0-9._-]*)*$/`.
````text
/** K310: board.py's APPROVED, one line at a time (no `m` flag: it would also start a line after `\r`, U+2028 and U+2029). */
const APPROVED_RE = new RegExp(`^\\*\\*${LOCK} Approved:\\*\\* [0-9]{4}-[0-9]{2}-[0-9]{2} [^\\s\\x1c-\\x1f\\x85\\ufeff]`, 'u')
````

**P2, line 620, replace** this line:
````text
        if (text === null || !text.split('\n').some(l => l.startsWith(`**${LOCK} Approved:**`))) reasons.push('tier 3 approval')
````
with this line:
````text
        if (text === null || !(text.split('\n## ')[0] ?? '').split('\n').some(l => APPROVED_RE.test(l))) reasons.push('tier 3 approval')
````

**P3, after line 731, insert** 1 line. Above: line 731 `const isMergedCard = isObject(trusted) && trusted.status === 'accepted' && isObject(trusted.merged)`; below: line 732 `const isIdle = isOld(lastActivity(t, row?.role === 'lead')) && hasUpstream(t) && (up === 'in sync' || /^\d+ behind$/.test(up))`.
````text
    const isEscalated = isObject(trusted) && trusted.status === 'escalated' // K297: stays under Waiting on you
````

**P4, line 733, replace** this line:
````text
    if (isMergedCard || isIdle) guarded('remove_worktree', t.path, card, PATH_RE.test(t.path), `git worktree remove ${t.path}`, uncommitted)
````
with this line:
````text
    if (isMergedCard || (isIdle && !isEscalated)) guarded('remove_worktree', t.path, card, PATH_RE.test(t.path), `git worktree remove ${t.path}`, uncommitted)
````

**P5, lines 813 to 814, replace** these 2 lines:
````text
/** Data text as drawn: the lock emoji the records use becomes the board's own single-width lock, other emoji go (a double-width glyph shifts a terminal row). */
export const plain = (s: string) => s.replace(/\u{1F510}\uFE0F?/gu, '◈').replace(/\p{Extended_Pictographic}\uFE0F?/gu, '').replace(/ {2,}/g, ' ')
````
with these 2 lines:
````text
/** Data text as drawn: control (C*), line and paragraph separator characters become spaces as in board.py's `one_line` (T043 P2), the lock emoji the records use becomes the board's own single-width lock, other emoji go (a double-width glyph shifts a terminal row). */
export const plain = (s: string) => s.replace(/[\p{C}\u2028\u2029]/gu, ' ').replace(/\u{1F510}\uFE0F?/gu, '\u25c8').replace(/\p{Extended_Pictographic}\uFE0F?/gu, '').replace(/ {2,}/g, ' ')
````

### `tests/board_tests.sh`

**T1, after line 478, insert** 68 lines. Above: line 478 (empty); below: line 479 `cd /; rm -rf "$T"; [ $FAIL -eq 0 ] && echo "ALL PASSED" || { echo "FAILED"; exit 1; }`.
````text
# T051 A) K297: on the 7-day idle path an escalated card's worktree gets no remove_worktree and the card stays under Waiting on you; an in_review one still gets it
python3 - "$S" "$J" <<'PYS' && ok "T051 K297: an idle escalated worktree gets no remove_worktree, an idle in_review one does" || bad "T051 K297: escalated worktree on the idle path"
import json, sys
sys.path.insert(0, sys.argv[1])
import board
raw = json.load(open(sys.argv[2], encoding="utf-8"))["raw"]
raw["now"] += 30 * 86400
W = "/r/.claude/worktrees/"
rm = lambda d: {a["target"] for a in d["actions"] if a["kind"] == "remove_worktree"}
assert {W + "impl-30", W + "impl-39"} <= rm(board.derive(raw)), rm(board.derive(raw))
st = json.loads(raw["trusted_state"]); st["cards"]["T039"]["status"] = "escalated"; raw["trusted_state"] = json.dumps(st)
d = board.derive(raw)
assert W + "impl-30" in rm(d) and W + "impl-39" not in rm(d), rm(d)
lead = raw["worktrees"][W + "lead-c"]["files"]  # the lead's own STATE carries the same status (Waiting on you reads it)
st = json.loads(lead["docs/delix/STATE.json"]); st["cards"]["T039"]["status"] = "escalated"; lead["docs/delix/STATE.json"] = json.dumps(st)
d = board.derive(raw)
assert W + "impl-39" not in rm(d), rm(d)
assert any(e["card"] == "T039" and e["reason"] == "escalated" for e in d["queue"]["waiting"]), d["queue"]["waiting"]
PYS

# T051 B) K310: a tier 3 open card counts as approved only with write_gate's dated line, in the header before the first "\n## "
python3 - "$S" "$J" <<'PYS' && ok "T051 K310: only a dated Approved line in the header clears tier 3 approval" || bad "T051 K310: Approved line form"
import json, sys
sys.path.insert(0, sys.argv[1])
import board
raw = json.load(open(sys.argv[2], encoding="utf-8"))["raw"]
files = raw["worktrees"]["/r/.claude/worktrees/lead-c"]["files"]
L = "# T038 - ci\n\n**\U0001F510 Approved:** "
def waits(text):
    files["docs/delix/tasks/T038-ci.md"] = text
    return any(e["card"] == "T038" and e["reason"] == "tier 3 approval" for e in board.derive(raw)["queue"]["waiting"])
assert not waits(L + "2026-11-04 user\n") and not waits(L + "2026-11-04 \u00c7a\u011fr\u0131\n## Scope\n")
for text in (L + "user\n", L + "2026-11-04\n", L + "2026-11-04 \n", L + "2026-11-04 \u3000user\n", L + "2026-11-04 \ufeffuser\n",
             L + "2026-11-04 \x1cuser\n", L + "\u0662\u0660\u0662\u0666-11-04 user\n",
             "# T038 - ci\n\n## Scope\n**\U0001F510 Approved:** 2026-11-04 user\n",
             "# T038 - ci\nx\r**\U0001F510 Approved:** 2026-11-04 user\n", "# T038 - ci\nx\u2028**\U0001F510 Approved:** 2026-11-04 user\n"):
    assert waits(text), repr(text)
PYS

# T051 C) K293: board.py takes the panel's rule; a .delix that cannot be listed but is a directory holds a card (call 5 skipped)
R="$(mktemp -d)"; R="$(cd "$R" && pwd -P)"
git init -q -b main "$R/r"
mkdir -p "$R/r/docs/delix"; printf '{"spec":"docs/delix/SPEC.md","cards":{}}\n' > "$R/r/docs/delix/STATE.json"
gc -C "$R/r" add -A && gc -C "$R/r" commit -q -m init
echo ".delix/" >> "$R/r/.git/info/exclude"
for n in none empty execonly file; do git -C "$R/r" worktree add -q -b "w-$n" "$R/$n" >/dev/null 2>&1; done
mkdir "$R/empty/.delix" "$R/execonly/.delix"; printf 'x\n' > "$R/file/.delix"; chmod 100 "$R/execonly/.delix"
python3 - "$S" "$R" <<'PYS' && ok "T051 K293: an exec-only .delix holds a card, an empty or file .delix none; call 5 follows" || bad "T051 K293: .delix listing rule"
import os, signal, sys
sys.path.insert(0, sys.argv[1])
import board
signal.alarm(60)
R = sys.argv[2]
root = os.geteuid() == 0  # root lists an exec-only directory
want = {"none": False, "empty": False, "execonly": not root, "file": False}
assert {n: board._card_present(os.path.join(R, n)) for n in want} == want
calls = []
real = board.subprocess.run
def run(argv, *a, **kw):
    calls.append((list(argv), kw.get("cwd")))
    return real(argv, *a, **kw)
board.subprocess.run = run
board.git_raw(os.path.join(R, "r"))
diffs = sorted(c for a, c in calls if "diff" in a)
assert diffs == sorted(os.path.join(R, n) for n in ["r"] + [n for n, v in want.items() if not v]), diffs
PYS
chmod 700 "$R/execonly/.delix"; rm -rf "$R"

````

### `plugins/delix-board/tests/board.test.tsx`

**T2, after line 7, insert** 1 line. Above: line 7 `import { PARITY } from './board_parity'`; below: line 8 (empty).
````text
import { plain } from '../hooks/parse'
````

**T3, after line 946, insert** 46 lines. Above: line 946 `})`; below: the end of the file.
````text

const t051Raw = () => JSON.parse(JSON.stringify(PARITY.raw)) as Raw & { now: number; trusted_state: string; worktrees: Record<string, { files: Record<string, string> }> }

test('T051 K297: on the 7-day idle path an escalated card keeps its worktree and waits; an in_review one gets remove_worktree', () => {
  const raw = t051Raw()
  raw.now += 30 * 86400
  const W = '/r/.claude/worktrees/'
  const rm = (r: Raw) => derive(r).actions.filter(a => a.kind === 'remove_worktree').map(a => a.target)
  expect([rm(raw).includes(`${W}impl-30`), rm(raw).includes(`${W}impl-39`)]).toEqual([true, true])
  const st = JSON.parse(raw.trusted_state) as { cards: Record<string, { status: string }> }
  const t039 = st.cards.T039
  if (t039) t039.status = 'escalated'
  raw.trusted_state = JSON.stringify(st)
  expect([rm(raw).includes(`${W}impl-30`), rm(raw).includes(`${W}impl-39`)]).toEqual([true, false])
  const lead = raw.worktrees[`${W}lead-c`]?.files ?? {}
  const own = JSON.parse(lead['docs/delix/STATE.json'] ?? '{}') as { cards: Record<string, { status: string }> }
  const own039 = own.cards.T039
  if (own039) own039.status = 'escalated'
  lead['docs/delix/STATE.json'] = JSON.stringify(own)
  expect(rm(raw).includes(`${W}impl-39`)).toBe(false)
  expect(derive(raw).queue.waiting.some(e => e.card === 'T039' && e.reason === 'escalated')).toBe(true)
})

test("T051 K310: a tier 3 open card counts as approved only with write_gate's dated line in the header", () => {
  const raw = t051Raw()
  const files = raw.worktrees['/r/.claude/worktrees/lead-c']?.files ?? {}
  const L = '# T038 - ci\n\n**\u{1F510} Approved:** '
  const waits = (text: string) => {
    files['docs/delix/tasks/T038-ci.md'] = text
    return derive(raw).queue.waiting.some(e => e.card === 'T038' && e.reason === 'tier 3 approval')
  }
  expect(waits(`${L}2026-11-04 user\n`)).toBe(false)
  expect(waits(`${L}2026-11-04 \u00c7a\u011fr\u0131\n## Scope\n`)).toBe(false)
  for (const text of [`${L}user\n`, `${L}2026-11-04\n`, `${L}2026-11-04 \n`, `${L}2026-11-04 \u3000user\n`, `${L}2026-11-04 \ufeffuser\n`,
    `${L}2026-11-04 \x1cuser\n`, `${L}\u0662\u0660\u0662\u0666-11-04 user\n`,
    '# T038 - ci\n\n## Scope\n**\u{1F510} Approved:** 2026-11-04 user\n',
    '# T038 - ci\nx\r**\u{1F510} Approved:** 2026-11-04 user\n', '# T038 - ci\nx\u2028**\u{1F510} Approved:** 2026-11-04 user\n']) {
    expect([JSON.stringify(text), waits(text)]).toEqual([JSON.stringify(text), true])
  }
})

test("T043 P2: plain turns control, line and paragraph separator characters into spaces like board.py's one_line", () => {
  expect(plain('qa r1\n@abc\rACCEPT\u2028by\u2029x\ty\u0007z\u0085w\u200bv')).toBe('qa r1 @abc ACCEPT by x y z w v')
  expect(plain('security\u001b[2J \u{1F510} HUMAN_APPROVAL\u0000')).toBe('security [2J \u25c8 HUMAN_APPROVAL ')
  expect(cut('a\nb\u2028c', 10)).toBe('a b c')
})
````

## Rules (both surfaces, one answer)
- **R-E, escalated (K297):** on the 7-day idle path (`aged` in board.py, `isIdle` in the panel) a worktree gets no
  `remove_worktree` when its card's status in the trusted STATE (the `origin/HEAD` copy, the source the merged path
  already reads) is `escalated`. The merged path is unchanged: it asks for `accepted` and a `merged` record. The
  `escalated` reason under Waiting on you is unchanged (it reads the lead's own STATE).
- **R-A, the Approved line (K310):** a tier 3 `open` card counts as approved only when one line of its text before the
  first `"\n## "` matches the pattern of anchor B1: the bold lock word, `Approved:`, a space, a date in ASCII digits
  (`YYYY-MM-DD`), a space, then one character from the class of anchor B1. That class leaves out every character that
  Python's `\s` or JavaScript's `\s` matches, so both surfaces accept the same lines. board.py searches the header with
  `re.M`. The panel splits the header on `"\n"` and tests each line with no `m` flag: in JavaScript `m` also starts a
  line after a carriage return, U+2028 and U+2029, in Python only after `"\n"`.
- **R-L, the `.delix` rule (K293):** board.py's `_card_present(wt)` gives the panel's `hasCardEntry` answer
  (`plugins/delix-board/hooks/data.ts:161-168`, unchanged). If the listing of `<wt>/.delix` works, the answer is whether
  it names `card`. If the listing fails, a `.delix` that is a directory counts as holding a card (call 5 does not run:
  fail closed); anything else holds none.
- **R-P, drawn text (T043 P2):** the panel's `plain(s)` first turns every `\p{C}` character, U+2028 and U+2029 into a
  space, as board.py's `one_line` does with categories `C*`, `Zl` and `Zp`; the existing replacements follow. `cut()`
  calls `plain`, so every data text the panel draws through either function follows the rule.
- **Regex discipline:** one new pattern per surface, anchored, no alternation, no nested quantifier.

## Decisions (lead, 2026-11-17)
- **D1, evidence (lead prototype on 5b2fa5c, Python 3.9.6 and 3.13.13, `claude plugin test`).** The anchors below are
  the prototype; the lead built them from it and applied them to the base again to check the "after" sha256s.
  - `tests/board_tests.sh` with the new block on the base: 3 `✘` (the three T051 lines), 46 `✔`, `FAILED`. On
    the prototype: 49 `✔`, `ALL PASSED`.
  - `claude plugin test plugins/delix-board` with the new tests on the base: 48 pass, 3 fail (the three new
    tests). On the prototype: 51 pass, 0 fail.
  - All 16 `tests/*_tests.sh` exit 0 with no `✘` on the prototype, on Python 3.9.6 and through a 3.13 PATH shim.
    `claude plugin validate .` passes.
- **D2, R-E reads the trusted STATE.** The merged path takes `merged` only from the `origin/HEAD` STATE (R10'), so the
  idle path takes `escalated` from the same place. A worktree cannot hide or fake the status, and both surfaces see
  the same value. Spec REQ-4's `remove_worktree` item said "or its last activity is older than 7 days"; K327 adds "and
  its card is not `escalated`". The lead edits the spec at dispatch.
- **D3, R-A is the same on both surfaces and stricter than write_gate.** ASCII digits and the class of B1 make board.py
  and the panel accept the same lines. Both are stricter than `scripts/write_gate.py:52` in two cases: write_gate's
  `\d` takes other scripts' digits, and its `\S` takes U+FEFF after the date. In those cases the board shows
  `tier 3 approval` for a card write_gate lets through. That is the safe direction (a Waiting on you line, not a
  block). The header area is write_gate's: the text before the first `"\n## "`.
- **D4, R-L takes the panel's rule.** K293 asks for one rule on both surfaces, and the panel already fails closed.
  board.py changes only for a `.delix` that cannot be listed: an exec-only `.delix` with no `card` counted as "no card"
  before and now holds one. A readable `.delix` with no `card`, a missing `.delix` and a `.delix` that is a file still
  hold none. The six forms of T043's test (link, dangling link, directory, FIFO, unreadable file, id-less file) are
  still "card present".
- **D5, R-P uses `one_line`'s character set.** Both surfaces take the category from their own Unicode tables, so a code
  point that is unassigned (`Cn`) in one runtime's version and assigned in the other's can differ (O2).
- **D6, no docs and no version.** README (line 386), README.tr (line 387) and the site's usage pages (line 94) already
  give a dated line (README `<YYYY-MM-DD> <who>`, the site `<date> <who>`); the board now follows them. None of
  them describes the idle path, the `.delix` rule or `plain` (the lead searched them for "7 day", "idle", "boşta",
  "remove_worktree", "worktree remove" and "Approved"). The delix-board version and the CHANGELOG line come with the
  next release card.
- **D7, the tests.** T1 adds three blocks to `tests/board_tests.sh`: K297 and K310 on the parity fixture's raw input,
  K293 on live git worktrees. T3 adds three panel tests: K297 and K310 on `PARITY.raw`, R-P on `plain` and `cut`.
  Every non-ASCII test character is an escape. The exec-only case expects "no card" when the suite runs as root (root
  lists the directory).

## Out of scope (each with the reason)
- **O1, `scripts/write_gate.py`:** a protected path; its `\d` and `\S` stay. The board is the stricter side (D3).
- **O2, Unicode version gaps:** `Cn` in R-P and the whitespace sets follow each runtime's Unicode version (Python 3.9:
  Unicode 13.0). No test pins an unassigned code point.
- **O3, `.delix` as a link:** `os.listdir` and `os.path.isdir` follow it; whether the panel's `$.fs.list` and
  `$.fs.stat` do is unverified. Not tested.
- **O4, the rest of STATUS §13:** K296 (no card), K292 (the panel screenshot, the lead's), spec §2 and §6, the bash_gate
  notes, O5 and O6.

## Interfaces
- Consumed: board.py `t_cards`, `files`, `os.listdir`, `os.path.isdir`; panel `trustedCards`, `fileOf`, `LOCK`.
- Produced: none. `derive`'s keys and the parity fixture do not change.

## Global Constraints (verbatim)
- K293: "Ham girdi iki yüzeyde tek kurala bağlanır (REQ-6)".
- K297: "kart Seni bekliyor'da kalır ve `remove_worktree` önerilmez (`accepted` ister)."
- K310: "Board'un tarihli deseni kullanması ayrı takip kartıdır."
- Repo rules: no regex with overlapping alternation; the existing tests are not changed; new lines are ASCII (other
  characters as escapes, no invisible character); Python 3.9 stdlib; the suites run on 3.13 as well (the Mac runs
  3.9.6, CI 3.12).

## Steps
1. Insert T1, T2 and T3. Run `bash tests/board_tests.sh` and see **red**: 3 `✘` lines, the three T051 labels,
   46 `✔`, `FAILED`, exit 1. Run `claude plugin test plugins/delix-board` and see 48 pass and
   3 fail (the three new tests). A different count means a copy error: compare with the anchors before going on.
2. Edit `scripts/board.py` per B1 to B5 and `plugins/delix-board/hooks/parse.ts` per P1 to P5.
3. See **green**: `bash tests/board_tests.sh` 49 `✔`, no `✘`, `ALL PASSED`; `claude plugin test
   plugins/delix-board` 51 pass, 0 fail. Run the suites on Python 3.13 through the PATH shim (Verification).
   If `/opt/homebrew/bin/python3.13` is missing, say so in the report.
4. Run every Verification command. Write the output to `.delix/evidence/verification.txt`, one block per command:
   `$ <command>`, its output, `[exit <code>]`.
5. Run `git add` with the 4 paths by name. Commit `T051: board fixes (K297, K310, K293, T043 P2)`. Push with
   `git push -u origin HEAD` from the worktree root. Open the PR with `--body-file` (the body has the `## How I tested`
   section).

## Verification command → expected output
- `bash tests/board_tests.sh | tail -1` → `ALL PASSED` · `bash tests/board_tests.sh | grep -c '^✔'` → `49`
- `claude plugin test plugins/delix-board` → `51 pass` and `0 fail`
- on Python 3.13: `P13="$(mktemp -d)" && ln -s /opt/homebrew/bin/python3.13 "$P13/python3" && PATH="$P13:$PATH" bash tests/board_tests.sh | tail -1` → `ALL PASSED`
- `for t in tests/*_tests.sh; do bash "$t" || exit 1; done` → exit 0, on Python 3.9.6 and through the 3.13 shim
- `claude plugin validate .` → passes
- `git diff --stat origin/main` → exactly the 4 Files
- `git diff origin/main -- tests plugins/delix-board/tests | grep -c '^-[^-]'` → `0`
- `git diff origin/main -- tests/board_tests.sh | grep -c '^+[^+]'` → `65` · `git diff origin/main -- plugins/delix-board/tests/board.test.tsx | grep -c '^+[^+]'` → `43`
- `git diff origin/main -- scripts/board.py | grep -c '^-[^-]'` → `11` · `| grep -c '^+[^+]'` → `13`
- `git diff origin/main -- plugins/delix-board/hooks/parse.ts | grep -c '^-[^-]'` → `4` · `| grep -c '^+[^+]'` → `7`
- `git diff -U0 origin/main | python3 -c "import sys; [print(l) for l in sys.stdin.buffer.read().decode('utf-8').split('\n') if l.startswith('+') and not l.startswith('+++') and any(ord(c) > 126 or (ord(c) < 32 and c != '\t') for c in l)]"` → no output
- `shasum -a 256 scripts/board.py plugins/delix-board/hooks/parse.ts tests/board_tests.sh plugins/delix-board/tests/board.test.tsx` → the four "after" values of the Edit anchors table

## Review Focus
- R-E: only the idle path changes; `escalated` comes from the trusted STATE; a merged `accepted` card still gets
  `remove_worktree`; the `escalated` Waiting on you line stays.
- R-A: the two patterns accept the same lines (the class of B1 and P1 are the same characters); the panel tests line by
  line without `m`; the header is the text before the first `"\n## "`; the T038 fixture card (a dated header line)
  stays approved and the parity test passes unchanged.
- R-L: the new `_card_present` gives `hasCardEntry`'s answer on every case of T043's block and T1's third block.
- R-P: `plain` keeps its lock and emoji handling; `cut` widths count the spaces.
- No existing test line changes; the 16 suites pass on Python 3.9.6 and 3.13.

## Don'ts
- Untouchable: `scripts/write_gate.py`, `plugins/delix-board/hooks/data.ts`, `plugins/delix-board/hooks/views.tsx`,
  `tests/fixtures/board_parity.json`, `plugins/delix-board/tests/board_parity.ts`, `docs/delix/**`, `README.md`,
  `README.tr.md`, `site/**`, `CHANGELOG.md`, every `plugin.json`, every other test file and every existing test line.
- If a test looks wrong, **do not change it**: stop and explain with `NEEDS_CONTEXT` in the report.
- Do not add a dependency, an option or a rule beyond R-E, R-A, R-L and R-P. If an Out of scope case looks easy, write
  it in the report instead.
- No raw non-ASCII or invisible character in a new line (the anchors carry escapes only).

## Report contract
`.delix/report.md` (≤ 1K tokens):
- status token (`DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED`);
- commands and output (also in `.delix/evidence/verification.txt`), `python3 --version`, `git --version`;
- the red and green counts of both test files;
- PR number and branch;
- assumptions;
- every pre-existing slow path or crash seen and not fixed.

Read only this card and spec REQ-4, REQ-6, K293, K297, K310 and K327.

## Spec K entry (K327 in the spec)
```text
- **K327** (lead, 2026-11-17, geri alınır) T051 kartı (Tier 2, frontend; lead yazdı): board düzeltmeleri. Kaynak:
  takip turu kapanışının drift listesi (K326) ve T043 P2; kullanıcı turu 2026-11-17'de seçti.
  - **K297 (R-E):** iki yüzeyde 7 günlük boşta yolu, kartı güvenilir STATE'te (`origin/HEAD`) `escalated` olan
    worktree'ye `remove_worktree` vermez. REQ-4'ün `remove_worktree` maddesine "kartı `escalated` değilse" eklendi.
  - **K310 (R-A):** tier 3 açık kart yalnız başlık alanında (ilk `\n## `'dan önce) write_gate biçimindeki tarihli
    Approved satırıyla onaylı sayılır. İki yüzey aynı satırları kabul eder: ASCII rakam, tarihten sonra Python ve
    JavaScript boşluk kümelerinin ikisinde de olmayan bir karakter, panelde satır satır ve `m` bayrağı olmadan. İkisi
    de write_gate'ten iki durumda katıdır (başka yazı sistemlerinin rakamları, tarihten sonra U+FEFF); bu güvenli yön.
  - **K293 (R-L):** `board.py` panelin `.delix` listeleme kuralını alır: listelenemeyen ama dizin olan `.delix` kart
    tutar (fail closed).
  - **T043 P2 (R-P):** panelin `plain()`'i kontrol (`\p{C}`), satır ve paragraf ayırıcı karakterlerini boşluğa çevirir.
  - **Ölçüm:** yeni testler tabanda board 46 ✔ / 3 ✘, panel 48 geçer / 3 kalır; prototipte board
    49 ✔, panel 51 geçer; 16 paket Python 3.9.6 ve 3.13'te geçer.
  - **Belge:** README ve site Approved satırını zaten tarihli anlatır, board artık ona uyar; boşta yolu, `.delix`
    kuralını ve `plain`'i anlatmazlar. delix-board sürümü ve CHANGELOG satırı sonraki sürüm kartında.
```

## Review findings (filled by the lead)
- Round 1 (PR #82, head `aefa44c7b285a293ea7a76c3b06919305cb50993`, base `66cbeae`, 2026-11-17): qa `ACCEPT` (0 P0,
  0 P1), security `CLEAN` (no finding). Lead gates on the clean `git archive` of the head: exactly the 4 Files, numstat
  13/11, 7/4, 68/0, 47/0; the 4 sha256s equal the card's "after" values and the lead's prototype; 16 suites exit 0 with
  no `✘` on Python 3.9.6 and 3.13.13 (`board_tests.sh` 49 `✔`); `claude plugin test plugins/delix-board` 51 pass,
  0 fail; `claude plugin validate .` passes (the warnings main has); the Stop gate gives `[exit 0]` twice; CI `check`
  and `test` green.
  - P2 (the lead's card text, reproduced by the lead, no fix): D4 says board.py changes only for a `.delix` that
    cannot be listed. Two more cases go from "card present" to "no card": a readable `.delix` that cannot be searched
    (mode 400) with no `card` entry, and a `.delix` link that loops. Both are the panel's answer (K293 parity); call 5
    then runs, which a worktree with no `.delix` gets anyway (security).
  - Note (qa unsure, checked by the lead): `plain` now turns the ZWJ (Cf) of an emoji sequence into a space, so
    `a<man><ZWJ><woman>b` draws `a b`; before, an invisible ZWJ stayed between `a` and `b`. This follows R-P.
  - Note (security unsure): `_card_present` now lists `.delix`, so its cost grows with the entries there; the panel
    lists the same way. Not measured. Whether every data string in `views.tsx` goes through `plain` or `cut` predates
    this card.
  - Note (implementer): the Edit tool turned some escapes of the test strings into raw characters (sha256 mismatch);
    the implementer applied the anchors with a script instead and got the card's sha256s. The lead met the same tool
    behaviour when writing the card.
  - Evidence: `rev82/` files in the lead's scratchpad (not in the repo).
