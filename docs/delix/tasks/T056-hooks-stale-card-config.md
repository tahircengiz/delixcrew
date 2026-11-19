# T056 🔐 — Hooks: a finished card's `.delix/card` goes stale, `delix.json` fails closed, paths match by real path and folded case

| id | size | tier | role | wave | status |
|---|---|---|---|---|---|
| T056 | M | 3 | backend | 27 | open |

**🔐 Approved:** 2026-11-19 tahircengiz

> 🔐 Tier 3: `scripts/common.py`, `scripts/write_gate.py` and `scripts/bash_gate.py` are protected (`docs/delix/delix.json:10`, `:11`, `:13`). The 🔐 Approved line above records the user's item-specific yes in chat on 2026-11-19 ("Evet, T056", said in the lead session). The lead commits it to main before the session starts; the session branches from that commit.
> - `tests/ref_gate_tests.sh` is an existing test file. Only lines 30 and 111 change, and they change on purpose (K354). qa counts any other change in that file as a finding.

**Goal (1 sentence):** These hooks change: `card_path` returns `None` for a card that is finished on `origin/HEAD`, the write and Bash gates deny with one message when `delix.json` cannot be read, the write gate guards a live `.delix/card`, and `common.matches` also matches the folded real path. · **Spec:** `docs/delix/specs/D-stale-card-config.md` REQ-1, REQ-2, REQ-5, §4, §6, K344–K348, K351–K357

**Docs/site:** none in this card. README, README.tr, the site and CHANGELOG belong to T057 (K349).

## Files (disjoint ownership; do not touch files owned by another card)
- Modify: `scripts/common.py` (C1 to C5)
- Modify: `scripts/write_gate.py` (W1 to W6)
- Modify: `scripts/bash_gate.py` (B1 and B2)
- Create: `tests/stale_card_tests.sh`
- Test: `tests/ref_gate_tests.sh` (R1 and R2 only, lines 30 and 111, K354)

## Interfaces
- **Changed:**
  - `common.card_path(cwd) -> str | None`. It runs today's local checks first. If the card is finished, it writes one stderr line and returns `None`.
  - `common.delix_json(cwd) -> dict | None`. It returns `None` where it used to return `{}`.
  - `common.matches(path, patterns, cwd) -> str | None`. The signature is the same. A pattern matches the folded given path or the folded real path.
- **New in common.py:**
  - `CONFIG_DENY`
  - `card_id(text) -> str | None`
  - `gate_config(cwd) -> dict | None`
  - `matches_both(path, patterns, cwd) -> str | None`
  - private helpers `_trusted_json`, `_card_finished`, `_fold_text`, `_rel_forms`, `_match_one`
- **Consumed, unchanged:** `common.git(cwd, *args)` (`scripts/common.py:30-39`: fsmonitor off, `GIT_*` env removed, `GIT_NO_LAZY_FETCH=1`, 5 s). Every git call goes through it (spec §4).
- **`scripts/stop_gate.py` needs no change:**
  - It calls `card_path` once (`scripts/stop_gate.py:35`), so a stale marker exits 0 before anything runs.
  - `stop_commands` already maps a non-dict config to `{}` (`scripts/common.py:83-84`), so `pytest -q` stays the fallback (spec §2, §5).
- **Exact texts** (spec lines 52–53, 80–81, 91–93). `<id>` is `card_id(marker)`. In the deny message it falls back to `unknown`.
  - Stale line on stderr, ending in `\n`: `delixcrew: .delix/card names <id>, which is accepted on origin/HEAD; implementer hooks stay inactive here. Move .delix aside before starting a new card.`
  - `MARKER_DENY`: `delixcrew: .delix/card names <id>, which is not finished on origin/HEAD; this worktree belongs to that card. Write nothing under .delix; end with BLOCKED in your final message; the lead opens a new worktree.`
  - `CONFIG_DENY`: `delixcrew: docs/delix/delix.json is missing, not valid JSON or not a JSON object with string lists; this card worktree stays blocked until the user fixes it from their own terminal`

## Edit anchors (base main 22a51ef, full SHA 22a51ef68d01180425c0d1fab5edd9303a46f4f9)
Line numbers are from that commit. Match the quoted content before you edit; if it differs, stop with `NEEDS_CONTEXT`. Use the Edit tool for every file under `scripts/`, because the hook denies shell writes to protected paths.
Base sha256 (22a51ef): `scripts/common.py` `d1232adf24c66ace032e2be552f6731a63ff99053fd82eb5f1c24a749c10271d`,
`scripts/write_gate.py` `4ee16124caf3d72cdfec5fc2be0ce89d6248fa4f98ef7628f8cd7a0cbfd202fb`,
`scripts/bash_gate.py` `64ed73c98e5148dae2d5713c281118feef3d412227235c4e951dbfde2e547265`,
`tests/ref_gate_tests.sh` `313ac1b22d44d19049ccb2a8cdd432be1ee5259d51bd4247683cec129edbe082`. The lead applied R1 and R2 to
a base copy: `bash tests/ref_gate_tests.sh` gives exactly 7 `✘` (cases 47–52 and 57), and on line 111 `"$W"` and
`"$JSON_DENY"` start in the same columns as on line 103.

### `scripts/common.py` (214 lines on the base)
**C1 · insert after line 9** (`import sys`): the line `import unicodedata`.

**C2 · insert after line 41.** That is the second blank line after `git()`, before line 42 `def card_path(cwd):`. Add three helpers, then two blank lines:
- **`card_id(text)`:**
  - Take the part of `text` after its last `/` (all of `text` if there is none).
  - If that part starts with `T` and then at least one ASCII digit `0`–`9`, return `"T"` plus the whole run of ASCII digits. `T1000-x.md` gives `T1000`.
  - Otherwise return `None`. Do not use `str.isdigit`, because it accepts other scripts' digits.
- **`_trusted_json(cwd, sha, rel)`:**
  - Run `git(cwd, "--no-lazy-fetch", "--no-replace-objects", "cat-file", "blob", sha + ":" + rel)`.
  - Return the parsed object only when the exit code is 0, `len(stdout.encode("utf-8")) <= 1 << 20`, `json.loads` succeeds and the result is a dict.
  - Return `None` in every other case, including any exception (a bad byte, a NUL in `rel`). Wrap the body in `try/except Exception`.
- **`_card_finished(cwd, marker)`:** the whole body sits in `try/except Exception` and gives `None` on any exception.
  1. `cid = card_id(marker)`. If it is `None`, return `None`.
  2. `r = git(cwd, "--no-lazy-fetch", "show-ref", "--verify", "refs/remotes/origin/HEAD")`. Continue only if the exit code is 0, `r.stdout.split()` has exactly 2 fields, field 2 is `refs/remotes/origin/HEAD`, and field 1 has 40 or 64 characters from `0123456789abcdef`. That field is `sha`.
  3. `state = _trusted_json(cwd, sha, "docs/delix/STATE.json")`. The worktree copy is never read.
  4. A record counts only if it is a dict whose `file` is a str equal to `marker`. It is finished if its `status` is `"accepted"` or its `merged` is a dict.
  5. If `cid` is a key of `state["cards"]` (a dict), that record alone decides: return `cid` if it counts and is finished, else `None`. The archive is not read in this case.
  6. Otherwise take `state["archive"]` (a list) and read only its first 20 items. Skip any item that is not a str, does not start with `docs/delix/archive/`, does not end with `/STATE.json`, has an empty middle part, has a `/` in the middle part, or contains `..`.
  7. For each remaining item, `_trusted_json(cwd, sha, item)`. Skip `None`. The first archive whose `cards` holds `cid` with a counting record decides, as in step 5.
  8. If nothing decides, return `None`.

**C3 · lines 63–64 · replace.** Current:
```text
    with open(p, encoding="utf-8") as f:
        return f.read().strip() or None
```
Replace with this behaviour:
- `text = f.read().strip()`. If it is empty, return `None`.
- If `cid = _card_finished(cwd, text)` is not `None`, write the stale line to `sys.stderr` once and return `None`.
- Otherwise return `text`.

You may add one sentence on REQ-1 to the docstring (lines 43–46).

**C4 · lines 67–75 · replace.** Current:
```text
def delix_json(cwd):
    for candidate in (os.path.join(cwd, "docs", "delix", "delix.json"),):
        if os.path.isfile(candidate):
            try:
                with open(candidate, encoding="utf-8") as f:
                    return json.load(f)
            except Exception:
                return {}
    return {}
```
Replace with three things:
- **`delix_json`:** same path, keeps the `os.path.isfile` check (so a FIFO or a directory is never opened). It returns the loaded value only if it is a dict, and `None` in every other case.
- **`CONFIG_DENY`:** the exact text above.
- **`gate_config(cwd)`:** returns `delix_json(cwd)` when it is a dict and each of `protected_paths` and `test_paths` is either absent or a list whose items are all str. Otherwise `None`. A key that is present with `null` gives `None`.

**C5 · lines 203–214 · replace.** Current:
```text
def matches(path, patterns, cwd):
    """Normalizes a relative/absolute path against cwd and compares it with glob patterns ('**' supported)."""
    if not path:
        return None
    rel = os.path.relpath(os.path.abspath(os.path.join(cwd, path)), cwd)
    rel = rel.replace(os.sep, "/")
    for d in patterns:
        d2 = d.replace("**/", "").replace("/**", "")
        if fnmatch.fnmatch(rel, d) or fnmatch.fnmatch(rel, d2) or rel.startswith(d2.rstrip("*").rstrip("/") + "/") \
                or fnmatch.fnmatch(os.path.basename(rel), d):
            return d
    return None
```
Replace with these functions:
- **`_fold_text(s)`:** `unicodedata.normalize("NFD", s).casefold()`, in the same order as `write_gate._fold` (K129).
- **`_rel_forms(path, cwd)`:** returns two values, both with `os.sep` changed to `/` and both folded:
  - given: `relpath(abspath(join(cwd, path)), cwd)`;
  - real: `relpath(realpath(join(cwd, path)), realpath(cwd))`.
- **`_match_one(rel, patterns)`:** today's four checks on the folded `rel` and the folded pattern (and its `d2`). It returns the original, unfolded pattern.
- **`matches`:** returns `None` for an empty path. Otherwise it returns the first pattern that matches the given form, else the first that matches the real form, else `None`.
- **`matches_both`:** returns the given form's pattern only when the given form and the real form each match some pattern. Otherwise `None` (K357).

### `scripts/write_gate.py` (115 lines on the base)
**W1 · line 11 · replace.** Current:
```text
from common import REVIEWERS, card_path, delix_json, deny, matches, read_input, trust_file  # noqa: E402
```
With (2 lines):
```text
from common import (CONFIG_DENY, REVIEWERS, card_id, card_path, deny, gate_config, matches,  # noqa: E402
                    matches_both, read_input, trust_file)
```

**W2 · insert after line 18** (the `TRUST_DENY = ...` line): a `MARKER_DENY` constant, with the exact text above and `{}` in place of `<id>`. Use `str.format`, and keep each line at most 120 characters.

**W3 · lines 47–51 · replace.** Current:
```text
cwd = g.get("cwd") or os.getcwd()
if not card_path(cwd):
    sys.exit(0)  # not an implementer session, inactive

card = card_path(cwd)
```
With:
```text
cwd = g.get("cwd") or os.getcwd()
card = card_path(cwd)  # REQ-1: called once; None for no card, a non-local card or a finished card
if not card:
    sys.exit(0)  # not an implementer session, inactive
```

**W4 · lines 81–85 · replace.** Current:
```text
cfg = delix_json(cwd)
ti = g.get("tool_input") or {}
path = ti.get("file_path") or ti.get("notebook_path") or ""
protected = cfg.get("protected_paths") or []
test_paths = cfg.get("test_paths") or ["tests/**"]
```
With:
```text
ti = g.get("tool_input") or {}
path = ti.get("file_path") or ti.get("notebook_path") or ""
```

**W5 · insert after line 89** (the end of the `outside_cwd` deny). Keep this order:
- **(a) Live marker (REQ-1, K348, K356):** this applies when `path` is set and `_fold(os.path.join(cwd, path)) == _fold(os.path.join(cwd, ".delix", "card"))`.
  - Exit 0 only when `tool_name` is `"Write"` and `tool_input["content"]` is a str whose `.strip()` equals `card`.
  - Otherwise `deny(MARKER_DENY.format(card_id(card) or "unknown"))`.
- **(b) Config (REQ-2):** `cfg = gate_config(cwd)`. If it is `None`:
  - exit 0 when `os.path.realpath(os.path.join(cwd, path))` is inside `os.path.join(os.path.realpath(cwd), ".delix")` (checked with `os.path.commonpath`, exact and not folded, and not equal to that directory);
  - otherwise `deny(CONFIG_DENY)`.
- **(c)** Then the two lines `protected = cfg.get("protected_paths") or []` and `test_paths = cfg.get("test_paths") or ["tests/**"]`.

**W6 · line 96 · replace.** Current `listed = bool(matches(path, files, cwd))`. New: `listed = bool(matches_both(path, files, cwd))  # K357: given and real path both listed`.

### `scripts/bash_gate.py` (821 lines on the base)
**B1 · line 11 · replace.** Current:
```text
from common import REVIEWERS, card_path, delix_json, deny, git, matches, read_input  # noqa: E402
```
With:
```text
from common import CONFIG_DENY, REVIEWERS, card_path, deny, gate_config, git, matches, read_input  # noqa: E402
```

**B2 · lines 113–117 · replace.** Current:
```text
cfg = delix_json(cwd)
if not isinstance(cfg, dict):  # R-U4: the rules below read cfg; a list, string, number or null is not a config
    deny("delixcrew: docs/delix/delix.json is not a JSON object; Bash stays blocked in this card worktree until the "
         "user fixes it from their own terminal")
protected = cfg.get("protected_paths") or []
```
With:
```text
cfg = gate_config(cwd)
if cfg is None:  # Spec D REQ-2 (K346): missing, broken, not an object, or a path list that is not a list of str
    deny(CONFIG_DENY)
protected = cfg.get("protected_paths") or []
```

### `tests/ref_gate_tests.sh` (152 lines on the base)
**R1 · line 30 · replace.** Current:
```text
JSON_DENY="delixcrew: docs/delix/delix.json is not a JSON object; Bash stays blocked in this card worktree until the user fixes it from their own terminal"
```
With:
```text
JSON_DENY="delixcrew: docs/delix/delix.json is missing, not valid JSON or not a JSON object with string lists; this card worktree stays blocked until the user fixes it from their own terminal"
```

**R2 · line 111 · replace.** Current (15 spaces after the label, as at line 111):
```text
allow "57 delix.json removed: ls"               "$W" "ls"
```
With: 16 spaces after the label and 44 spaces after `"ls"`, so that `"$W"` starts at column 49 and the message at column 102, the same as line 103:
```text
deny "57 delix.json removed: ls"                "$W" "ls"                                            "$JSON_DENY"
```

## Tests (`tests/stale_card_tests.sh`, new; ends with `ALL PASSED`)
**Shape (copy `tests/ref_gate_tests.sh:7-36`):**
- `set -u`. Check marks come from octal escapes. The file is ASCII only.
- Build `git`, `push`, `update-ref` and `remote` at run time from parts (`G=gi; G="${G}t"`, `refs/${R}s/...`). The file holds none of `git`, `push`, `update-ref`, `remote`, `send`, `triage` or `script` as a literal word (`scripts/` paths are fine).
- Hook input is built with `python3 -c 'import json,sys; ...'`.
- Each run captures stdout, stderr and the exit code.
  - **allow:** exit 0, no deny decision, no `Traceback` in stderr.
  - **deny `<msg>`:** exit 0, the deny decision, `grep -F` of the message, no `Traceback`.
- **🔐 in a card file:** written with `printf '\360\237\224\220'`.
- **Non-ASCII paths:** use JSON `\uXXXX` escapes only. Bash 3.2 has no `$'\u'`.

**Fixtures:**
- **W (card worktree):**
  - `init`, one empty commit on `claude/t1`;
  - `.delix/` in `.$G/info/exclude`;
  - `.delix/card` set per case, default `docs/delix/tasks/T055-release-0-7-2.md`, with that card file present in the work tree;
  - `docs/delix/delix.json` = `{"test_command": "touch <T>/MARK", "protected_paths": ["scripts/x.py", "scripts/common.py", "scripts/café.py"], "test_paths": ["tests/**"]}`;
  - files `scripts/x.py`, `tests/a_tests.sh`;
  - symlinks `lnk -> scripts`, `tlink -> tests`, `docs/a.md -> ../scripts/common.py`, `src/a.py -> ../tests/a_tests.sh`.
- **S (source repo):** a helper commits the given `docs/delix/STATE.json` (and any archive files) on S `main`, then fetches it into W with `+refs/heads/main:refs/${R}s/origin/main`. `refs/${R}s/origin/HEAD` is a symbolic ref to `refs/${R}s/origin/main`. These setup calls run git directly, never through a hook.
- **Base STATE:** `{"cards": {"T055": {"file": "docs/delix/tasks/T055-release-0-7-2.md", "status": "accepted"}}}`

**REQ-1 cases:**
1. **Accepted:** Write `docs/delix/SPEC.md` is allowed. Bash `echo x > scripts/x.py` is allowed. Stop (`{"cwd": W, "stop_hook_active": false}`) exits 0, with no `.delix/test-result.txt` and no MARK. Each of the three stderrs holds the stale line exactly once (`grep -cxF` gives `1`).
2. **Escalated:** `escalated` with `merged` a dict gives the same results as case 1.
3. **Not finished:** each of `open`, `in_progress`, `in_review`, `fixing`, `rejected`, `escalated` with no `merged`, `merged: null` and `merged: "x"`. Write `docs/delix/SPEC.md` is denied (the docs/delix message), Bash `echo x > scripts/x.py` is denied (protected), and Stop exits 2.
4. **Write `docs/delix/SPEC.md` is denied in each of these:**
   - the card is in no STATE;
   - `file` differs;
   - the marker is `docs/delix/tasks/x.md` or `docs/delix/tasks/t055-x.md`;
   - `refs/${R}s/origin/HEAD` is deleted;
   - the STATE is not JSON, or is `[]`;
   - `cards` is a list;
   - the STATE is larger than 1 MiB (the accepted card plus padding);
   - the STATE holds byte `\377`.
5. **Spoofed anchors:** with `origin/HEAD` deleted, `refs/tags/refs/${R}s/origin/HEAD`, or a branch of that name, points at an accepted commit: denied. A `replace` of the origin STATE blob by an accepted blob: denied.
6. **Id and copy:**
   - the marker is `docs/delix/tasks/T1000-x.md` and the STATE has `T100` `accepted` with `file` `docs/delix/tasks/T1000-x.md`: denied;
   - the worktree's own `docs/delix/STATE.json` says accepted while origin says `in_progress`: denied.
7. **Archive:** the current STATE has no T021. Its `archive` is `[5, "../x/STATE.json", "docs/delix/archive/a/../b/STATE.json", "docs/delix/archive/a/b/STATE.json", "docs/delix/archive/missing/STATE.json", "docs/delix/archive/old/STATE.json"]`, and `old` holds T021 `accepted` with an equal `file`: inactive, as in case 1. Two variants stay denied:
   - the same archive placed as item 21;
   - an archive record with the same id and a different `file`.
8. **Live marker** (T055 `in_progress`). Each of these is denied with `MARKER_DENY` naming T055:
   - Write `.delix/card` with another card path;
   - Write `.DELIX/card` with another text;
   - Edit, MultiEdit and NotebookEdit on `.delix/card`.

   Write `.delix/card` with the same text plus `\n`, or with two leading spaces, is allowed. Write `.delix/report.md` is allowed.
9. **Stale marker:** Write `.delix/card` with a new card path is allowed.

**REQ-2 cases** (live marker):

10. `{"protected_paths": [`: Write `scripts/x.py` and Bash `ls` are both denied with `CONFIG_DENY`.
11. `[]`, `{"protected_paths": 5}`, `{"test_paths": [1]}` and `{"protected_paths": null}`: both gates deny with `CONFIG_DENY`, with no `Traceback`.
12. **delix.json removed:** both gates deny.
13. **Broken config, writes under `.delix/`:** Write `.delix/report.md` and `.delix/evidence/v.txt` are allowed.
14. **Broken config, escapes:** Write `.delix/../scripts/common.py` is denied. Write `.delix/x/common.py`, with `.delix/x -> ../scripts`, is denied.
15. **Broken config outside a card worktree:** with no `.delix/card`, Write `scripts/x.py` and Bash `ls` are allowed. With a stale marker, Write and Bash are allowed and Stop exits 0.
16. **Stop gate fallback:** with a broken delix.json, `python3 -c` importing `common` gives `stop_commands(W) == ["pytest -q"]`.

**REQ-5 cases** (live marker, valid config):

17. **Folder symlink:** Write `lnk/x.py` is denied (protected). Bash `cp a lnk/x.py` is denied. Write `scripts/x.py` is denied.
18. **Test-path symlink:** Edit `tlink/a_tests.sh` is denied with the existing test message.
19. **Letter case:** Write `Scripts/x.py` and `SCRIPTS/x.py` are denied (protected). Write `DOCS/delix/STATE.json` is denied (the docs/delix message).
20. **Unicode normalization:** Write `"scripts/café.py"` is denied (protected).
21. **Listed symlinks:** the card lists `docs/a.md` and carries Approved: Write `docs/a.md` is denied. The card lists `src/a.py`: Write `src/a.py` is denied.
22. **Controls:**
    - the card lists `scripts/x.py` and carries Approved: Write `scripts/x.py` is allowed, but Write `lnk/x.py` is denied;
    - a new `tests/b_tests.sh` is allowed;
    - `src/free.py` is allowed.

**Network case:**

23. **Treeless clone, no network (K284):**
    1. The source has `old` (an empty commit) and `main`, whose commit holds a STATE with T900 `accepted`. Set `uploadpack.allowFilter` and `uploadpack.allowAnySHA1InWant` to true.
    2. Clone with `clone -q --filter=tree:0 --branch old file://<src>` and make sure `origin/HEAD` is a symbolic ref to `origin/main`.
    3. Write the marker for T900 and the exclude.
    4. Count `.$G/objects/pack/*.pack`. Write `docs/delix/SPEC.md` through the hook must be denied, and the pack count must not change.
    5. **Control:** a plain `cat-file blob` of `origin/HEAD`'s STATE, run without `--no-lazy-fetch` and without `GIT_NO_LAZY_FETCH`, must add a pack. That proves the fixture is lazy.

The first output line is `git --version`.

## Global Constraints (verbatim from the spec, or from repo rules)
- "Her hata ya da istisna (git yok, zaman aşımı, ref yok, boyut, UTF-8, JSON, beklenmeyen tip) işareti etkin bırakır. `write_gate.py` `card_path`'i bir kez çağırır."
- "Worktree'deki `docs/delix/STATE.json` kopyası hiç okunmaz." "\"İşi bitti\" kararı yalnız `card_path`'tedir."
- "Ret yönündeki kurallar iki yol biçiminden (verilen, realpath) birine bakar; izin yönündeki Files denetimi ikisini birden ister." (K357)
- "Stop gate davranışı değişmez."
- Python 3.9 stdlib only and no new dependency. Write no `X | Y` type annotations. The suites run on Python 3.9.6 (Mac) and through a 3.13 shim; CI runs 3.12.
- No new regex: no new `re.` call in `scripts/`. All new lines are ASCII, with no invisible character. New lines in `scripts/` are at most 120 characters.
- The REQ-1 "inactive" cases need git 2.44 or later (spec §6). Put `git --version` in the report. CI runs git 2.56.1 (`tests.yml`
  run 44594483825 on 22a51ef), so these cases run there too.

## Steps
1. Write `tests/stale_card_tests.sh` with the Write tool, and apply R1 and R2 with the Edit tool. On the base code:
   - `bash tests/ref_gate_tests.sh` gives exactly 7 `✘` (cases 47–52 and 57);
   - `bash tests/stale_card_tests.sh` is **red**. Write its counts in the report.
2. Apply C1 to C5, W1 to W6 and B1 to B2 with the Edit tool. Check each file parses: `python3 -c "import ast,sys; [ast.parse(open(f).read()) for f in sys.argv[1:]]" scripts/common.py scripts/write_gate.py scripts/bash_gate.py` prints nothing.
3. Both files are **green**. Then run every suite on Python 3.9.6 and on the 3.13 shim.
4. Write the Verification output to `.delix/evidence/verification.txt`, one block per command: `$ <command>`, its output, `[exit <code>]`.
5. Commit and push:
   - Run `git add` with the 5 paths by name, in a call of its own.
   - Commit `T056: stale card marker, delix.json fails closed, real-path and folded path rules` in a call of its own.
   - Run `git push -u origin HEAD` as its own command from the worktree root. No other command of yours puts `git` and `push` on one line.
   - Write the PR body with the Write tool and open the PR with `--body-file`. The body has `## How I tested`.

## Verification command → expected output
- `bash tests/stale_card_tests.sh` → last line `ALL PASSED`, no `✘`. Case 23 shows the same pack count after the hook and one more pack after the control.
- `bash tests/ref_gate_tests.sh` → `ALL PASSED`
- `for t in tests/*_tests.sh; do bash "$t" || exit 1; done` → exit 0, 18 files, no `✘`. Run it on Python 3.9.6 and through `P13="$(mktemp -d)" && ln -s /opt/homebrew/bin/python3.13 "$P13/python3" && for t in tests/*_tests.sh; do PATH="$P13:$PATH" bash "$t" || exit 1; done`.
- `claude plugin validate .` → exit 0
- `git diff --numstat origin/main...HEAD` → exactly the 5 Files. `tests/ref_gate_tests.sh` shows `2	2`.
- `git diff -U0 origin/main...HEAD -- tests/ref_gate_tests.sh | grep -c '^@@'` → `2`, at lines 30 and 111.
- Each `grep -cF` gives `1`:
  - `'"show-ref", "--verify", "refs/remotes/origin/HEAD"'` in `scripts/common.py`
  - `'"--no-replace-objects", "cat-file", "blob"'` in `scripts/common.py`
  - `'which is accepted on origin/HEAD; implementer hooks stay inactive here'` in `scripts/common.py`
  - `'is missing, not valid JSON or not a JSON object with string lists'` in `scripts/common.py`
  - `'which is not finished on origin/HEAD; this worktree belongs to that card'` in `scripts/write_gate.py`
- `grep -c 'card_path(cwd)' scripts/write_gate.py scripts/bash_gate.py scripts/stop_gate.py` → `1` each
- `git diff -U0 origin/main...HEAD -- scripts | grep -E '^\+.*\bre\.'` → no output (no new regex)
- `git diff -U0 origin/main...HEAD | python3 -c "import sys; [print(ascii(l)) for l in sys.stdin.buffer.read().decode('utf-8').splitlines() if l.startswith('+') and not l.startswith('+++') and any(ord(c) > 126 or (ord(c) < 32 and c != '\t') for c in l)]"` → no output
- Lines longer than 121 characters among the added lines of `git diff -U0 origin/main...HEAD -- scripts` → none
- No linear-time claim is made. Any timing claim in the PR is measured with ×4 to ×8 growth ratios.

## Review Focus
- **REQ-1 scenarios:** kabul edilmiş (case 1), merge edilmiş escalated (2), süren ya da bilinmeyen (3, 4), çapayı taklit eden yollar (5), kimlik ve kopya (6), arşivdeki kart (7), canlı başka kartın işareti (8), aynı kartın işareti (8). Also the stale line appears once in each hook.
- **REQ-2 scenarios:** bozuk JSON (10), nesne olmayan JSON (11), eksik dosya (12, and ref_gate case 57), rapor yazılabilir (13), muafiyetten kaçış (14), kart worktree'si dışı (15). Stop is unchanged (16).
- **REQ-5 scenarios:** klasör symlink'i (17), test yolu (18), harf farkı (19, 20), listedeki symlink (21). Case 22 checks for over-denial.
- **Read rules:**
  - The trusted read is exactly the two §4 argv, both through `common.git`.
  - It fails closed on every branch.
  - The archive is read only when the id is missing from `cards`.
  - The size limit is checked before `json.loads`.
- **`tests/ref_gate_tests.sh`:** only R1 and R2 change (K354).

## Don'ts
- Untouchable:
  - `scripts/stop_gate.py`, `scripts/trust.py`, `scripts/board.py`, `hooks/hooks.json`, `.github/**`, `docs/delix/**` (STATE.json too), `plugins/**`;
  - `README.md`, `README.tr.md`, `CHANGELOG.md`, `site/**`, `skills/**`, `agents/**`, `templates/**`;
  - every other test file, and every line of `tests/ref_gate_tests.sh` except 30 and 111.
- Do not change the signatures of `common.git` or `matches`. Add no option and no dependency. If a test looks wrong, stop with `NEEDS_CONTEXT`.
- Add no Bash rule against moving `origin/HEAD`; it is a known limit (K351).

## Out of scope (each with the reason)
- Bash rules for `symbolic-ref`, `fetch` refspecs, `fast-import`: K351, a known limit written by T057.
- Docs and site text: T057 (K349).
- A non-UTF-8 `.delix/card` still raises in `card_path` (`scripts/common.py:63`). This was there before Spec D and is not in it; mention it in the report.

## Report contract
`.delix/report.md` (at most 1K tokens) holds:
- the status token;
- the red and green counts for both test files;
- the Verification outputs, also in `.delix/evidence/verification.txt`;
- `python3 --version` (3.9.6 and 3.13), `git --version`;
- the PR number in the `**PR:**` line, and the branch;
- assumptions;
- every hook denial of your own commands.

Do not write STATE.json. Read only this card and spec §1–§7, K344–K357.

## Review findings (filled by the lead)
- Round 1: …
