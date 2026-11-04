# T029 — board.py: derive() for agents, leads, queue and git actions; Run blocks in /delixcrew:status

| id | size | tier | role | wave | status |
|---|---|---|---|---|---|
| T029 | M | 2 | backend | 7 | open |

> Tier 2: no protected path is touched (`scripts/board.py` and `tests/board_tests.sh` are not in `protected_paths`). It is Tier 2 because it is new behaviour that prints commands the user runs with Desktop's Run button.

**Goal (1 sentence):** `board.py` collects local git facts once (rules G). A pure `derive(raw)` (rules R) turns them into `agents`, `leads`, `queue`, `actions` and `fetched_at`. These are added to `--json` and printed as five new Markdown sections under the unchanged card table (format F), with every command in its own one-line `bash` block. For the parity fixture, `derive` returns exactly its `expected`. · **Spec:** `docs/delix/specs/C-board-visibility.md#REQ-1`, `#REQ-3`, `#REQ-4`, `#REQ-5`, `#REQ-6`; §4, §6; K245–K258, K260

**Docs/site:** none in this card (T032).

## Files
- Modify: `scripts/board.py` (anchors below)
- Test: `tests/board_tests.sh` (insert after line 75 only; every existing line stays byte-identical, K254)

## Edit anchors (base origin/main ad27168, unchanged at d9ac35b; match the content, not only the number)
1. `scripts/board.py`, after line 24 (`OPEN_STATUSES = {"open", "in_progress", "in_review", "fixing"}`): add `BRANCH_RE`, `PATH_RE`, `SHA_RE` (R10), `WEEK = 604800` and `KIND_ORDER = ("push", "merge", "remove_worktree", "delete_branch")`.
2. Insert before line 118 (`def collect(root):`): `def git_raw(root)` (rules G, I/O only), `def derive(raw)` and its helpers (rules R; no I/O, no clock), and `def git_sections(data)` (format F).
3. `collect`: both returns (lines 139–142 and 202–204) also carry `**derive(git_raw(root))`. Nothing else in either dict changes.
4. Gates, lines 183–191:
   - When the STATE card has a non-empty `agents` list, the gates are, in this order: `🔐` if its R8 reasons include `tier 3 approval`; `merge` if R8 ready; `escalated` if the status is `escalated`; `needs_context` / `blocked` for that R8 reason.
   - Otherwise lines 184–191 run unchanged (K254).
5. `table`: insert `out += git_sections(data)` after line 244 (`out += verifications_table(data.get("verifications"))`, the no-cards path) and after line 269 (the same call, cards path).

## Rules G: git_raw(root) (Python 3.9 stdlib)
Each call is `subprocess.run(argv, cwd=<dir>, capture_output=True, text=True, timeout=5)`; `worktree list` gets timeout 10. An OSError, a timeout or a non-zero exit gives `None`. For `diff`, only exit codes 0 and 1 are values. Every path from git, and `root`, goes through `os.path.realpath`.
1. `git rev-parse --git-common-dir` in root. A relative output is joined to root.
2. `git worktree list --porcelain` gives `worktree_list` (`""` on failure).
3. `git for-each-ref refs/heads refs/remotes --format=%(refname)%09%(objectname)%09%(upstream)%09%(upstream:track,nobracket)%09%(committerdate:unix)` gives `for_each_ref`.
4. Per worktree (cwd = the worktree): `git status --porcelain` gives `status`.
5. Per worktree without `.delix/card` whose status has no STATE line (R5a): `git diff --quiet origin/<default_branch>...HEAD -- docs/delix/STATE.json` gives `state_diff_exit` (0 or 1).
6. Per Leads row (the main checkout and every `lead`, R5):
   - STATE not dirty: `git log -1 --format=%ct -- docs/delix/STATE.json` gives `state_log_ct` (int).
   - STATE dirty: `int(os.stat(<wt>/docs/delix/STATE.json).st_mtime)` gives `state_mtime`.

Other raw values:
- `files` (only those that exist): for every worktree, `.delix/card` and `.delix/report.md`. For Leads rows also `docs/delix/STATE.json`, the file named in its `spec`, and the `file` of each card with tier 3 and status `open`.
- `fetch_head_mtimes`: `int(st_mtime)` of `<common>/FETCH_HEAD` and of each existing `<common>/worktrees/*/FETCH_HEAD`.
- `default_branch`: `default_branch` from `docs/delix/delix.json` in root, else `"main"`.
- `now`: `int(time.time())`.
- `self` = `source` = realpath(root) (K256).
- Outside git: empty text and dicts; `derive` still returns empty lists.

## Rules R: derive(raw), pure (T030 implements the identical text)
- **R1 Input.** `raw` has `default_branch`, `now` (s), `self`, `source`, `common_dir`, `fetch_head_mtimes` {path: s}, `worktree_list`, `for_each_ref`, and `worktrees` {path: {`status` str|null, `state_diff_exit` 0|1|null, `state_log_ct` int|null, `state_mtime` int|null, `files` {relpath: text}}}. A missing key counts as null or empty. `derive` never raises.
- **R2 Parse.**
  - `worktree_list`: blocks split by an empty line. Read `worktree <path>`, `HEAD <sha>`, and either `branch refs/heads/<b>` (strip that prefix once) or `detached`; ignore other lines. The first block is the main checkout.
  - `for_each_ref`: only lines with exactly 5 TAB fields (refname, objectname, upstream, track, committer time); skip others.
  - A STATE is the JSON of `files["docs/delix/STATE.json"]`; invalid or missing means no cards and no verifications.
- **R3 Upstream text** of a checked-out branch b, from line `refs/heads/b`:

  | Input | Text |
  |---|---|
  | no line | `?` |
  | upstream field empty | `no upstream` |
  | track `""` | `in sync` |
  | `ahead N` | `N ahead` |
  | `behind N` | `N behind` |
  | `ahead N, behind M` | `N ahead, M behind` |
  | `gone` | `gone` |
  | detached | `detached <HEAD[:7]>` |

  The short upstream is the upstream without a leading `refs/remotes/`.
- **R4 Source.** The source STATE is the STATE of `raw.source`. byValues = every `by` of every `agents` record in it.
- **R5 Role.**
  - `files[".delix/card"]` contains `T\d{3}` → `implementer T<nnn>`, card `T<nnn>`.
  - Else `lead` if any of: (a) a `status` line whose text from index 3 equals `docs/delix/STATE.json`; (b) `state_diff_exit == 1`; (c) the branch is in byValues.
  - Else `other`.
- **R6 Agent row** `{path, branch, main, role, card, upstream, uncommitted, lands, opened_by, last_round}`:
  - `branch`: null when detached. `main`: true for the first block.
  - `uncommitted`: count of non-empty status lines; `"?"` when status is null.
  - `lands`: an implementer whose card has a PR (R7) → `PR #<n> → <default_branch>`; else, if an upstream is configured → `pushed: <short upstream>`; else `local only`.
  - `opened_by`: the `by` of the card's last `implementer` record in the source STATE, else null.
  - `last_round`: for an implementer card in the source STATE, let R = the max `round` of its `qa`/`security` records. Each such record with round R, in list order, becomes `<role> r<round> @<sha[:7] or -> <verdict or -> · by <by>`. Otherwise `[]`.
  - Order: lead, then implementer, then other; then by path, using plain code-point comparison (never locale).
- **R7 Card facts in a STATE S.**
  - `pr`: a positive int, or a string matching `^#?[0-9]+$` → int; else null (`merge <sha>` → null). For an implementer worktree's card whose `pr` is null, use the report's `**PR:** #(\d+)`.
  - Report status: `\*\*Status:\*\*\s*([A-Z_]+)` in `.delix/report.md` of the worktree whose card it is.
  - Branch: `branch` of the last `implementer` record if not null, else that worktree's branch.
  - Remote tip: objectname of `refs/remotes/origin/<branch>` (no line → null).
  - Tier: the int value; a non-int counts as 2.
- **R8 Queue of S.** R = max round over `qa`/`security` records; qa = the last `qa` record with round R; sec = the last `security` record with round R.
  - **Ready:** status `in_review`, an int pr, qa verdict `ACCEPT` or `ACCEPT_WITH_NOTES`, (tier < 2, or sec verdict `CLEAN` or `🔐 HUMAN_APPROVAL`), and remote tip == qa sha → `{card, pr, sha: <qa sha>}`.
  - **Waiting** reasons, in this order:
    1. `ready to merge`
    2. `tier 3 approval`: status `open`, tier 3, and the card's `file` (in S's worktree `files`) is missing or has no line starting with `**🔐 Approved:**`
    3. `needs_context` / `blocked`: report status NEEDS_CONTEXT / BLOCKED, and status in open, in_progress, in_review or fixing
    4. `escalated`
    5. `changed after review`: every ready condition holds except tip == sha
    6. `no review record`: status `in_review`, an int pr, and `agents` missing or empty

    Each gives `{card, verification: null, reason}`. Then every verification whose verdict starts with `FIX` and has no non-empty `resolution` gives `{card: null, verification: <name>, reason: "verification FIX"}`.
  - **Done:** status `accepted` → `{card, pr}`.
  - Order: lists by card id (code point); a card's reasons in the order above; verifications last, in STATE order.
- **R9 Leads.** The main checkout first, then every other `lead` row by path. Row: `{path, branch, main, source, spec_title, open, waiting, ready, changed_at, stale}`.
  - `source`: path == `raw.source`.
  - `spec_title`: the first line of `files[<STATE.spec>]` that starts with `# `, minus `# ` and trailing spaces; else null.
  - `open`: cards with status open, in_progress, in_review or fixing.
  - `waiting`: distinct card ids with a card reason (R8) in that STATE.
  - `ready`: count of ready cards.
  - `changed_at`: `state_mtime` if R5a holds, else `state_log_ct`; null if missing.
  - Last activity = the max of the known values among the branch committer time and `changed_at`. `stale` = not main, last activity known, and now − last activity > 604800.
- **R10 Actions.** Consider every worktree except the main checkout and `raw.self`.
  - **Push candidate:** branch not null and ≠ default_branch; upstream text not `gone` or `?`; and the text is `no upstream` or contains `ahead`. Command `git -C <path> push -u origin <branch>`, target = path.
  - **Remove candidate:** either the card is in the source STATE with status `accepted` and `merged` as an object; or the last activity is known and now − it > 604800, an upstream is configured, and the text is `in sync` or `N behind`. Last activity is R9's (branch time and `changed_at`) for leads, and only the branch committer time for other worktrees. Command `git worktree remove <path>`, target = path.
  - For each candidate, in this order: uncommitted ≠ 0 (or `?`) → command null, note `uncommitted <n> files: commit or discard in its session`; a name fails its pattern → command null, note `unsafe name: run by hand`; else note `""`.
  - **Merge:** each ready card of the source STATE → `gh pr merge <pr> --squash --match-head-commit <sha>`, target `#<pr>`.
  - **Delete:** each source card with a `merged` object whose branch (R7, implementer record) meets all of: a `refs/heads/<branch>` line exists; the branch is not checked out in any worktree; its objectname == `merged.head`. Command `git branch -D <branch>`, target = branch.
  - `card`: the worktree's card for push/remove, the card itself for merge/delete, else null.
  - Name patterns:
    - branch: `^[A-Za-z0-9][A-Za-z0-9._-]*(/[A-Za-z0-9][A-Za-z0-9._-]*)*$`
    - path: `^/[A-Za-z0-9_./-]+$` (K260)
    - PR: a positive int
    - SHA: `^[0-9a-f]{40}$`
  - An action is `{kind, target, card, command, note}`. Order by (card if not null, else target) in code-point order, then push < merge < remove_worktree < delete_branch.
- **R11** `fetched_at` = the max value in `fetch_head_mtimes`, or `"never fetched"` when it is empty.
- **R12** The output is `{agents, leads, queue: {waiting, ready, done}, actions, fetched_at}`; the queue is the source STATE's.

## Format F: git_sections (after the existing output)
- Times are `YYYY-MM-DD HH:MM UTC` via `datetime.datetime.fromtimestamp(ts, datetime.timezone.utc)` (not `utcfromtimestamp`, which is deprecated in 3.12). An unknown time prints `?`.
- In cells, `|` becomes `/` and a newline becomes a space; backticks are removed from paths and targets. A missing `opened_by` or `last_round` prints `—` (U+2014).
```
## Leads
Card table and queue source: `<source>` · remote data as of the last fetch: <fetched_at time or never fetched>

| path | branch | spec | open | waiting | ready | STATE changed | stale |
|---|---|---|---|---|---|---|---|
| `<path>`[ (main checkout)][ (source)] | <branch or -> | <spec_title or -> | n | n | n | <time> | stale or - |

## Agents
| role | path | branch | upstream | uncommitted | lands | opened by | last round |
|---|---|---|---|---|---|---|---|
| <role>[ (main checkout)] | `<path>` | <branch or detached> | <upstream> | n | <lands> | <opened_by or —> | <last_round joined with "; " or —> |

## Waiting on you
- <card> · <reason>            (a verification: - <name> (verification) · verification FIX); none: none

## Ready to merge
- <card> · PR #<pr> · reviewed <sha[:7]>; none: none

## Git actions
You run these with Desktop's Run button; the lead never runs them.

**<kind>** `<target>`
~~~bash
<command>
~~~
```
- In the real output the command block is a normal triple-backtick `bash` fence holding exactly one command line.
- A null command prints `**<kind>** `<target>`: <note>`.
- No actions prints `none`.

## Tests to add (tests/board_tests.sh, insert after line 75, before line 77 `cd /; rm -rf "$T"; …`)
```bash
# 5) Spec C REQ-6 (K252): derive(raw) == fixture expected; TS copy byte-equal; REQ-4 forbidden tokens
J="$ROOT/tests/fixtures/board_parity.json"; P="$ROOT/plugins/delix-board/tests/board_parity.ts"
python3 - "$S" "$J" <<'PYS' && ok "parity: derive(raw) == expected" || bad "parity: derive(raw) != expected"
import json, sys
sys.path.insert(0, sys.argv[1])
import board
f = json.load(open(sys.argv[2], encoding="utf-8"))
got = board.derive(f["raw"])
for k in ("agents", "leads", "queue", "actions", "fetched_at"):
    assert got[k] == f["expected"][k], (k, json.dumps(got[k], ensure_ascii=False))
PYS
[ "$(head -c 22 "$P")" = "export const PARITY = " ] && tail -c +23 "$P" | cmp -s - "$J" && ok "parity: TS copy is byte-equal" || bad "parity: board_parity.ts is not prefix + tests/fixtures/board_parity.json"
python3 - "$S" "$J" <<'PYS' && ok "REQ-4: no forbidden token, no main or self path" || bad "REQ-4: forbidden token in a command"
import json, re, sys
sys.path.insert(0, sys.argv[1])
import board
raw = json.load(open(sys.argv[2], encoding="utf-8"))["raw"]
assert all(re.fullmatch(r"[0-9a-f]{40}", l.split("\t")[1]) for l in raw["for_each_ref"].splitlines()), "fixture sha"
main = raw["worktree_list"].splitlines()[0][len("worktree "):]
banned = {"--force", "-f", "--force-with-lease", "--mirror", "reset", "clean", main, raw["self"]}
for a in board.derive(raw)["actions"]:
    toks = (a["command"] or "").split()
    assert not banned & set(toks), a
    assert not (a["kind"] == "push" and toks[-1:] == [raw["default_branch"]]), a
PYS

# 6) Spec C on a real repository: roles, upstream, push commands; main checkout and self get none (REQ-1, REQ-4)
G="$(mktemp -d)"; gc(){ git -c user.email=t@t -c user.name=t "$@"; }
git init -q --bare "$G/origin.git"; git init -q -b main "$G/r"
mkdir -p "$G/r/docs/delix"; printf '{"spec":"docs/delix/SPEC.md","cards":{}}\n' > "$G/r/docs/delix/STATE.json"
gc -C "$G/r" add -A && gc -C "$G/r" commit -q -m init && git -C "$G/r" remote add origin "$G/origin.git" && git -C "$G/r" push -q -u origin main 2>/dev/null
echo ".delix/" >> "$G/r/.git/info/exclude"
git -C "$G/r" worktree add -q -b claude/impl "$G/impl" >/dev/null 2>&1; mkdir -p "$G/impl/.delix"; echo "docs/delix/tasks/T029-x.md" > "$G/impl/.delix/card"
gc -C "$G/impl" commit -q --allow-empty -m a && git -C "$G/impl" push -q -u origin claude/impl 2>/dev/null
gc -C "$G/impl" commit -q --allow-empty -m b && gc -C "$G/impl" commit -q --allow-empty -m c
git -C "$G/r" worktree add -q -b claude/lead "$G/lead" >/dev/null 2>&1; printf '{"spec":"docs/delix/SPEC.md","cards":{},"updated":"x"}\n' > "$G/lead/docs/delix/STATE.json"
git -C "$G/r" worktree add -q -b x-fix "$G/xfix" >/dev/null 2>&1
(cd "$G/lead" && python3 "$S/board.py" --json) > "$G/out.json"
python3 - "$G" <<'PYS' && ok "real repo: roles, 2 ahead, push commands; main and self excluded" || { bad "real repo"; cat "$G/out.json"; }
import json, os, sys
G = sys.argv[1]; d = json.load(open(os.path.join(G, "out.json"), encoding="utf-8"))
real = lambda p: os.path.realpath(os.path.join(G, p))
rows = {a["path"]: a for a in d["agents"]}
assert rows[real("impl")]["role"] == "implementer T029" and rows[real("impl")]["upstream"] == "2 ahead", rows
assert rows[real("lead")]["role"] == "lead" and rows[real("xfix")]["role"] == "other", rows
cmds = [a["command"] for a in d["actions"] if a["command"]]
assert "git -C %s push -u origin claude/impl" % real("impl") in cmds, cmds
assert "git -C %s push -u origin x-fix" % real("xfix") in cmds, cmds
assert not [c for c in cmds if real("r") in c.split() or real("lead") in c.split()], cmds
PYS
md="$(cd "$G/lead" && python3 "$S/board.py")"
echo "$md" | grep -qxF '```bash' && echo "$md" | grep -qxF "git -C $(cd "$G/impl" && pwd -P) push -u origin claude/impl" && ok "real repo: one-line bash block" || { bad "real repo: bash block"; echo "$md"; }
rm -rf "$G"
```

## Interfaces
- Consumed, read-only (the lead commits both to main before dispatch, K252; neither is in your Files):
  - `tests/fixtures/board_parity.json` (`raw` + `expected`)
  - `plugins/delix-board/tests/board_parity.ts` (`export const PARITY = ` + the same bytes)
- Produced:
  - `board.derive(raw: dict) -> {"agents", "leads", "queue", "actions", "fetched_at"}`
  - `board.py --json`: the existing keys unchanged, plus those five keys.
  - Section headings `## Leads`, `## Agents`, `## Waiting on you`, `## Ready to merge`, `## Git actions` (T031's status skill names them).

## Global Constraints (verbatim from the spec)
- REQ-4: "Komut yalnız dal adı `^[A-Za-z0-9][A-Za-z0-9._-]*(/[A-Za-z0-9][A-Za-z0-9._-]*)*$`, yol `^/[A-Za-z0-9_./-]+$`, PR numarası pozitif tamsayı ve SHA `^[0-9a-f]{40}$` iken üretilir; aksi halde `unsafe name: run by hand` (K248)." In this card the path pattern is `^/[A-Za-z0-9_./-]+$` per K260.
- REQ-4: "komutların token listesinde `--force`, `-f`, `--force-with-lease`, `--mirror`, `reset`, `clean`, varsayılan dala push, ana checkout yolu ya da board'u çalıştıran worktree'nin yolu bulunmaz (denetim token düzeyinde)".
- §2/§6: "Board ve panel ağ kullanmaz, yazmaz, çalıştırmaz." No `git fetch`, no `gh`.
- K254: "Kart tablosu sütunları değişmez; yeni bilgi yeni bölümlere. `agents`'sız kartta 'pending gate' bugünkü kuralı izler".
- K256: "board.py ana tablo kaynağı bugünkü gibi kendi kökü".
- Python 3.9 compatible (the Mac's python3 is 3.9.6; CI runs 3.12): no `match`, no `X | Y` annotations at runtime, stdlib only.

## Steps
1. Insert the tests above. Run `bash tests/board_tests.sh` and see **red** (`board.derive` is missing).
2. Implement anchors 1–5 in `scripts/board.py` only.
3. Run and see **green**. Run the full loop, on python3 3.9 and on a 3.12 if one is available.
4. Commit `T029: board.py derive(): agents, leads, queue, git actions (Spec C)`. Open a PR whose `## How I tested` gives the commands and their output.

## Verification command → expected output
- `bash tests/board_tests.sh` → ends `ALL PASSED`; no line starts with `✘`.
- `for t in tests/*_tests.sh; do bash "$t" || exit 1; done` → exit 0.
- `git diff origin/main -- tests/board_tests.sh | grep -c '^-[^-]'` → `0`.
- `git diff --stat origin/main` → only `scripts/board.py` and `tests/board_tests.sh`.

## Review Focus
- `derive` is pure: no `subprocess`, `os`, `open` or `time` inside it or its helpers.
- Path sorting is code-point order, and `realpath` is applied in `git_raw` only.
- The existing lines 32 and 65 of `board_tests.sh` still pass, because cards without a ledger keep today's gates.
- No command is produced for the main checkout or self, and none from a failed name check.

## Don'ts
- Untouchable: every file not in Files, especially `tests/fixtures/board_parity.json`, `plugins/delix-board/**`, `hooks/**`, `skills/**`, `.claude-plugin/**`.
- Do not change existing `board_tests.sh` lines. If a test looks wrong, stop and write `NEEDS_CONTEXT`.
- If the fixture disagrees with these rules, do not edit it: write `NEEDS_CONTEXT` and name the field.
- No new dependency.

## Report contract
`.delix/report.md` (≤ 1–2K tokens) containing:
- `DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED`;
- the commands and their output, including the python3 version;
- the PR number;
- assumptions.

Read only this card and spec §3–§6.

## Review findings (filled by the lead)
- Round 1 (3423549, 2026-11-04): deterministic gates pass (board_tests 20 ✔ on python3 3.9.6 and 3.13; full loop 903 ✔ 0 ✘; validate passes; 0 removed test lines). qa `ACCEPT` (0 P0/P1). security `FIX`.
- **Medium (security, fix round 1):** CR (U+000D) and other control or separator characters in STATE.json string fields reach the Markdown output unchanged; a CR followed by a `bash` fence line opens a fenced block that Desktop shows with a Run button. Lead repro on 3423549 and on main: `spec`, `cards.<T>.role`, `cards.<T>.status`, `verifications[].name` and `verifications[].verdict` each open a fence. Not reproduced: spec title, worktree path, report line (`splitlines` cuts them at the CR). Fix: `one_line()` at the two `table()` joins; the Pending gates element splits in two so the output stays byte-identical (real repo, 87 lines). New test appended; red on 3423549, green after.
- Low (follow-up K262, no fix here): (a) `git status --porcelain` without `--no-optional-locks` can write other worktrees' index (`board.py:218`); (b) `spec` and card `file` from another lead's STATE are read without a containment, regular-file or size check (`board.py:162`, `:173-177`); (c) `worktree list --porcelain` without `-z`: a path with `\n` (or `\r`, because of `splitlines`) forges blocks, and exclusion is by index (`board.py:204`, `:285-303`, `:544`). (a) and (c) also apply to the panel (T030) and change spec §4/R2.
- P2 notes: `_pr` takes `"#0"` as pr 0 (`board.py:306`; the merge command is still null). Security unsure: `core.fsmonitor` in a worktree config runs on `git status`; quadratic `int()` on 3.9 for a very long digit run (pre-existing, `:90`).
