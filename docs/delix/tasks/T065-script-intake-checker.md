# T065 — Script: `scripts/intake.py`, the intake record checker (Spec F card A)

| id | size | tier | role | wave | status |
|---|---|---|---|---|---|
| T065 | S | 2 | backend | 34 | open |

**Tier:** 2. New behaviour, three new files; none protected (`docs/delix/delix.json:7-20`). Review: qa + security.

**Goal (1 sentence):** A read-only `scripts/intake.py` (`check`, `list`, `show`, `table()`) enforces the Spec F record
shape, decision table and consent binding, with a CI test. · **Spec:** `docs/delix/specs/F-intake-decisions.md`
REQ-1–REQ-4, REQ-6, §4, §6; K414–K417, K420, K421, K425–K427.

**Docs/site:** none here; T067 owns them.

## Files
- Create: `scripts/intake.py`
- Create: `templates/intake.json` (exactly `{"version": 1, "items": []}` + newline)
- Create: `tests/intake_tests.sh`
- No existing file changes. The suite and CI pick the test up through `tests/*_tests.sh` (REQ-6).

## Interfaces
- **Consumed, unchanged (`scripts/feedback.py`):** `queue_dir` (103), `JSON_MAX` (111), `_shallow` (114),
  `read_json` (126, as a model), `load_config` (171), `load_records` (195), `local_terms` (367), `term_regex` (384),
  `sanitize` (427), `invisible` (495). Import as `scripts/triage.py:25-26`:
  `sys.path.insert(0, os.path.dirname(os.path.realpath(__file__)))`, then `import feedback  # noqa: E402`.
- **Produced:**
  - `table(item) -> str`: REQ-2 rows 1–7 in order, `events = len(item["refs"])`. Row 2 is "`reproduced` does not start
    with `main@`".
  - CLI `python3 scripts/intake.py check | list [--pending] | show I<nnn> [--require accepted]`. Each takes `--file P`
    (default `docs/delix/intake.json`, relative to cwd).
  - Exit codes: 0 ok · 2 shape or usage · 8 rule.
  - A missing file (FileNotFoundError) is `{"version": 1, "items": []}`. Any other unreadable path (directory, FIFO,
    permission) exits 2.
  - **stderr:** one line per error, `delixcrew: intake: <id|file>: <reason>`. `<id>` is the item's id when it is a
    valid id string; otherwise `file`, and the reason names the position (`item 3: …`). `check` runs every shape check
    over the whole file first and the rules only when the shape is clean; errors come in file order; nothing is
    printed on exit 0. Shape reasons are free text. These lines are fixed:
    - repeated ref (the first holder is named): `delixcrew: intake: I001: ref F012 is also in I004`
    - REQ-2: `delixcrew: intake: I001: decision defer differs from the table (accept); set decision, basis, reason and
      consent to null`
    - REQ-3a: `delixcrew: intake: I001: needs the maintainer's "accept I001" in chat` (the quotes hold the item's own
      decision)
    - REQ-3b: `delixcrew: intake: I001: consent is for <cd>/<ct>/<ce>, the item is now <d>/<t>/<e>; set decision,
      basis, reason and consent to null`
    - REQ-3c: `delixcrew: intake: I001: a gate_open item needs work or covered_by (K418)`
  - **`list`:** lines `<id>  <decision>  <events>  <work>  <title>` (two spaces between fields, null as `-`), sorted
    by id.
    - Empty record: `no intake items`; empty pending list: `no pending intake items`.
    - `--pending` = decision null, `needs-info`, or `accept` with work null.
    - A shape error: exit 2 with the check lines and no stdout. Rule errors do not change the output.
  - **`show`:** 18 lines `<field>: <value>`, in this order: `id`, `title`, `refs: a, b`, the six `evidence.<field>`
    lines in §4 order, `decision`, `basis`, `reason`, `consent.decision`, `consent.table`, `consent.events`,
    `consent.at`, `work`, `table` (K425).
    - null is `-`; bools are `true`/`false`; a null consent gives four `-` lines.
    - An id that does not fullmatch `I[0-9]{3}`: `delixcrew: intake: show needs an id like I001`, exit 2. The argument
      is never echoed.
    - An unknown id: `delixcrew: intake: I009: no such item`, exit 2.
    - A shape error anywhere in the file: exit 2.
  - **`--require accepted`:** exit 8 with exactly one line, `delixcrew: I<n> is <x>; only an accepted, unstarted item
    can be started (/delixcrew:intake decide)`.
    - `<x>` is `already started as <work>` when work is set, else `undecided` when the decision is null, else the
      decision. An `accept` item with its own REQ-2/REQ-3 error also gets the decision.
    - Exit 0: stdout = the `show` output.

## Lead decisions (decided; if one looks wrong, write it in the report and do not change the behaviour)
- **K425:** `show` ends with `table: <table(item)>`. The intake skill's `decide` shows the table's decision (REQ-5);
  this line is where it reads it.
- **K426:** "a feedback queue exists" (K417) means `queue_dir()` holds `config.json` or at least one `F<n>.json`.
  - Then `term_re = feedback.term_regex(set(load_config()["extra_terms"]) | local_terms() | origin_terms of every
    record)`, as in `scripts/feedback.py:521-523`.
  - Otherwise `term_re = None`, so an empty `DELIXCREW_FEEDBACK_DIR` gives the CI result on every machine.
- **K417 (spec):** the filter for `title` and `reason` is `NFKC(t) == t`, `feedback.sanitize(t, term_re) == t`,
  `not feedback.invisible(t)` and no character of category `Cc`.
- **K427:** the REQ-4 points this card fixes: `list` gives exit 2 on a shape error; a null consent prints four `-`
  lines in `show`; the `show` exit 2 messages above; `check` is silent on success.

## Global Constraints
- **Reading (REQ-1, K420):**
  - Read like `feedback.read_json`: O_NONBLOCK, regular file only, at most `JSON_MAX` bytes.
  - Decode as strict UTF-8.
  - Parse with `json.loads(..., object_pairs_hook=<raise on a repeated key>, parse_constant=<raise>)`, then check the
    depth with `_shallow`.
  - `OSError`, `ValueError`, `RecursionError` and `MemoryError` → exit 2, never a traceback.
- **Shape:**
  - Exact key sets for the top level, item, evidence and consent.
  - Bools: `type(x) is bool`. Integers: `type(x) is int` for `version` (must be 1) and `consent.events` (≥ 1).
  - For a string: check `type(s) is str` and the length first, then `re.fullmatch(p, s, re.ASCII)`.
  - Refs: one compiled regex per form, kept in a tuple. No alternation inside one regex and no nested quantifier (§6).
  - `decision` null → `basis`, `reason` and `consent` are null. `decision` set → `basis` and `reason` are set.
- **Limits:** no write, network, subprocess, `eval` or `exec`. Stdlib + `feedback` only; Python 3.9 (no `X | Y`
  annotations, no `match`). ASCII source, lines ≤ 120.

## Tests (`tests/intake_tests.sh`, new; last line `ALL PASSED`)
**Rules for the whole file:**
- `set -u`, then `unset DELIXCREW_TRIAGE_DIR` and `export DELIXCREW_FEEDBACK_DIR="$T/fb"` (an empty temp dir).
- The file is ASCII. ✔ and ✘ are octal escapes, as in `tests/stale_card_tests.sh:12` (K429).
- Python writes every fixture with `json.dumps(..., ensure_ascii=True)`. Invisible and other special characters appear
  only as Python or JSON `\uXXXX`; macOS bash 3.2 has no `\u` in `$'…'` (K429).
- Every call goes through the 5 s guard of `tests/triage_config_tests.sh:13-18`. No case may have `Traceback` in its
  stderr.

**Base item:**
- `I001`, title `Start skill misses a step`, refs `["F012"]`
- all four evidence bools false, `reproduced` `main@2464805`, `covered_by` null
- `defer` / `table` / reason `One event so far.`, consent null, work null; its table result is `defer`.

**Cases.** Each label appears once, with ✔. The arrow gives the exit code.
- **S1** (scenario): F012 in both I001 and I004 → 2. The line starts with `delixcrew: intake: I001:` and contains
  `I004`.
- **S2** (scenario): each title → 2: `Fails on /srv/data/x`, `Mail ops@acme.io`, `Breaks on build.acme.io`, one with
  `\u0007`, one with `\u200b`, one with `\uff21` (NFKC). Control: `Start skill reads ~/.claude` → 0.
- **S3** (scenario): refs `["#36"]` → 2.
- **S4** (scenario), no file:
  - `check` → 0; `list` prints `no intake items`; `list --pending` prints `no pending intake items`; `show I001` → 2.
  - `--file templates/intake.json`: `check` → 0 and `list` prints `no intake items`.
- **S5** each → 2: a file over 1 MiB, the byte `\xff`, invalid JSON, a repeated key, `NaN`, 100 000 nested `[`, a
  directory.
- **S6** → 2: a missing key and an extra key at the top level, in an item, in evidence and in consent; `version` 2;
  `version` `"1"`.
- **S7** → 2: `gate_open` 1; `consent.events` true; `title` 5.
- **S8** patterns:
  - each → 2: id `I0001` and `I00\u0661`; refs `F12`, `F012\n`, `T001.R`, `lead.2026-11-21.x`, `k5`; reproduced
    `main@ABC1234` and `main@abc123`; covered_by `F012`; work `T1` and `spec AB`; at `2026-11-21 10:00:00Z`.
  - one valid example of each of the five ref forms → 0.
- **S9**: title of 0 or 121 characters → 2, 120 → 0; reason of 301 → 2, 300 → 0.
- **S10** → 2: decision null with basis `table`; decision `defer` with reason null.
- **S11**: a reason containing `ops@acme.io` → 2.
- **S12** (K417, K426):
  - `$T/fb2` holds `config.json` with `extra_terms` `["zorblat"]`; title `Zorblat build breaks` → 2.
  - The same record with the empty `$T/fb` → 0.
  - `$T/fb3` holds `F001.json` with `origin_terms` `["quuxcorp"]`; a title with `quuxcorp` → 2.
- **S13**: one shape error and one rule error → 2, with no rule line.
- **S14**: a ref of 500 000 characters and a title of 500 000 characters → 2, inside the guard.
- **T1**: `table()` through a Python import.
  - One case per row, 1 to 7.
  - Order: covered_by + gate_open → duplicate; `no` + gate_open → needs-info; misleading_doc + against_principle →
    accept.
  - Counts: blocks_flow with 1 ref → defer, with 2 refs → accept; 3 refs → accept.
- **T2** (scenario): defer/table with 2 refs → 0; a third ref → 8 with the REQ-2 line for I001.
- **T3**: basis `maintainer`, decision different from the table, matching consent → 0.
- **C1** (scenario): accept with consent null → 8; the line contains `needs the maintainer's "accept I001" in chat`.
- **C2**: wontfix with consent null → 8.
- **C3**: gate_open + covered_by `K5`, `duplicate`/`table`, consent null → 8.
- **C4**: basis `maintainer`, consent null → 8.
- **C5** (scenario): consent.decision `wontfix`, decision `accept` → 8.
- **C6**: consent.table differs from the table → 8.
- **C7** (scenario): basis `maintainer`, consent.events 1, a second ref added → 8.
- **C8**: gate_open, accept, valid consent, work and covered_by both null → 8. Control with work `T070` → 0.
- **C9**: duplicate, defer and needs-info, each with basis `table` and no consent → 0.
- **L1**: a file with I003, I001, I002 in that order → `list` gives the exact lines, sorted.
- **L2**: `--pending` includes null, needs-info, and accept with work null. It excludes accept with work set, defer,
  duplicate and wontfix.
- **L3**: `show` → the exact 18 lines.
- **L4**: `show I1`, `show ../x`, `show I009`, and `show I001` with a shape error in another item → 2 each; `../x`
  does not appear in stderr.
- **L5**, `--require accepted`:
  - I004 defer (start scenario) → 8 with the exact line for `defer`.
  - undecided → `undecided`; decision null with work `T070` → `already started as T070`; accept without consent →
    `accept`.
  - a valid accept → 0, and stdout equals the `show` output.
- **L6**: two rule errors → two lines, exit 8.
- **L7**: `grep -cE 'subprocess|socket|urllib|eval\(|exec\(|os\.replace|write_json'` on the script → 0. Every command
  leaves the fixture directory unchanged (file listing and sha256 before and after).
- **R1**: if `$ROOT/docs/delix/intake.json` exists, `check` with `$T/fb` → 0; otherwise print
  `✔ R1 live record: none yet`.

## Steps
1. Baseline: `for t in tests/*_tests.sh; do bash "$t" || exit 1; done` → exit 0. Write down the file count.
2. Write the test with the Write tool. Run it on the base: **red** (the script is missing). Put the ✘ count in the
   report.
3. Write `scripts/intake.py` and `templates/intake.json`.
4. **Green.** Run the suite on Python 3.9.6 and through the 3.13 shim.
5. Write the Verification output to `.delix/evidence/verification.txt`, one block per command: `$ cmd`, output,
   `[exit n]`.
6. Commit and push:
   - Run `git add scripts/intake.py templates/intake.json tests/intake_tests.sh` alone.
   - Commit `T065: intake kaydı denetleyicisi (Spec F A)`.
   - Run `git push -u origin HEAD` alone.
   - Open the PR with `--body-file`; the body has `## How I tested`.

## Definition of done (Verification → expected)
- `bash tests/intake_tests.sh` → no ✘, every label from S1 to R1 present, `ALL PASSED`, exit 0.
- The suite on 3.9.6 and through
  `P13="$(mktemp -d)" && ln -s /opt/homebrew/bin/python3.13 "$P13/python3" && for t in tests/*_tests.sh; do PATH="$P13:$PATH" bash "$t" || exit 1; done`
  → exit 0 both times, base count + 1 files.
- `claude plugin validate .` → exit 0.
- `python3 scripts/intake.py check --file templates/intake.json; echo $?` → `0`.
- `grep -cF 'import feedback' scripts/intake.py` → `1`.
- `git diff --numstat origin/main...HEAD` → only the three files, all added.
- The non-ASCII byte count of `docs/delix/tasks/T059-hooks-gitdir-write-gate.md:268` on each of the three files →
  `0`.
- `awk 'length > 120' scripts/intake.py` → no output.
- **How I tested** (PR body): the red and green counts, both interpreters, the commands above with their outputs.

## Review Focus
- The fixed lines against spec REQ-2 to REQ-4; K425 to K427; fail closed (a broken file gives exit 2 for `show` and
  `list` too); S1 names the first holder.
- The REQ-3b rule runs only on a decided item. `show` never echoes its argument.
- `/delixcrew:intake` inside a title is redacted until `skills/intake` exists (`feedback.plugin_skills`, 419), so the
  tests do not use it.

## Don'ts
- Do not touch any existing file: `scripts/feedback.py`, `docs/delix/**`, `skills/**`, README, `site/**`,
  `CHANGELOG.md`, `.claude-plugin/**`, existing tests.
- Bash text, commit messages and greps: never the feedback script name followed by its publish subcommand, and never
  the triage script name followed by its apply subcommand.
- If a test looks wrong, stop with `NEEDS_CONTEXT`.

## Report contract
`.delix/report.md` holds:
- the status token;
- the red and green counts;
- the Verification output (also in `.delix/evidence/verification.txt`);
- both `python3 --version` lines;
- the PR number in the `**PR:**` line, and the branch;
- assumptions;
- every hook denial of your own commands.

Read only this card and spec §3–§6 and its K list.

## Review findings (filled by the lead)
- **Round 1** (PR #95, branch `claude/elastic-saha-6fc047` @ `7d1c2dd44263dae56c13251d30d6b193124f703e`, 2026-11-21):
  - Deterministic gates:
    - the lead's run on an export of the branch commit: `tests/intake_tests.sh` 34 `✔`, 0 `✘`, `ALL PASSED` on 3.9.6
      and 3.13.13; `check --file templates/intake.json` 0; non-ASCII bytes 0 in all three files; no line over 120;
    - only the three Files paths, all added; no protected path; no existing test file;
    - the Stop gate (`.delix/test-result.txt`) ends `[exit 0]`, 19 `ALL PASSED`; CI `check` and `test` pass.
  - qa: ACCEPT. No findings.
    - Unsure (P2, no fix): Python 3.9 parses a long integer literal in quadratic time. The lead measured `check`
      on a record whose `version` has n digits: 0.30 s at 200 000, 1.06 s at 400 000, 6.46 s at 1 000 000 (the
      1 MiB cap). It still exits 2 cleanly. On 3.13 the same file exits 2 in 0.04 s (integer digit limit).
      The queue module's `read_json` behaves the same.
    - Unsure (no fix): the repeated-ref line is emitted while the second holder is read; it is the fixed S1 line.
  - security: FIX, one Low finding. The lead reproduced it and raised it to P1 (K433, below).
  - **G1 (P1, K417 conformance; security Low).** `term_re()` fails open (`scripts/intake.py:98-110`). With a queue
    whose `config.json` has `"extra_terms": "zorblat"` (a string), or broken JSON, or an unreadable `F002.json`
    that holds the term, or a queue path that is a file, `check` exits **0** for the title `Zorblat build breaks`.
    The control case, a good config that lists the term, exits 2. K417 builds `term_re` from the set in
    `scripts/feedback.py:521-523`, whose consumers fail closed (`load_config(strict=True)`, `bad_ids`). Required:
    - only a missing queue directory (`FileNotFoundError`) gives `None`; any other `OSError` from `os.listdir`,
      `load_config(strict=True)` returning `None`, a non-empty `bad`, or an `origin_terms` that is not a list of
      strings raise `Reject`;
    - `main` prints `delixcrew: intake: file: the feedback queue's config.json or a record is unreadable; fix it so
      its terms apply (K433)` and exits 2.
  - **G2 (P1, §4 exit contract).** A queue record with `"origin_terms": 5` gives a `TypeError` traceback and exit 1
    (`scripts/intake.py:109`). Required: exit 2 with the G1 line.
  - **G3 (P1, data loss).** `tests/intake_tests.sh:9` `T="$(cd "$(mktemp -d)" && pwd -P)"`: when `mktemp -d`
    fails, bash 3.2 runs `cd ""` as a no-op with exit 0. `T` then becomes the caller's directory, and line 448
    `rm -rf "$T"` deletes it. The lead showed `T` resolving to the cwd with a failing `mktemp`. Required:
    `T="$(mktemp -d)" || exit 1; T="$(cd "$T" && pwd -P)" || exit 1`.
  - Tests required, inside S12:
    - the five queues above (string `extra_terms`, broken `config.json`, unreadable `F002.json`, `origin_terms: 5`,
      queue path a file), each `check` exit 2 with exactly the G1 line;
    - a good queue with a title that has no term, exit 0.
  - Lead prototype on the branch export: new tests red on `7d1c2dd` (S12 `✘`, the five queue cases), green after the
    fix (34 `✔`, 0 `✘`, 3.9.6 and 3.13.13). sha256 prefixes after: `scripts/intake.py` `12663da762e0`,
    `tests/intake_tests.sh` `b8ca3f928f87`. Non-ASCII 0, no line over 120. With a failing `mktemp`, the new test
    exits 1 and deletes nothing.
  - Pre-existing, outside this card: the same temp-dir line is at `tests/feedback_tests.sh:6`,
    `tests/sanitize_tests.sh:6`, `tests/triage_tests.sh:6` and `tests/triage_config_tests.sh:7`, and the same
    `origin_terms` traceback is at `scripts/feedback.py:523`. These are lead follow-ups.
  - Not for this card (security unsure, spec level): K417 has no secret pattern check. The lead writes `title` and
    `reason`, and the record's `check` runs in CI. Lead follow-up.
