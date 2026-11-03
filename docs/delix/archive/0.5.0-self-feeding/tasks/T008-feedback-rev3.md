# T008 — 🔐 feedback.py rev 3: kind type, single-segment paths, draft-only send, missing tests

| id | size | tier | role | wave | status |
|---|---|---|---|---|---|
| T008 | M | 3 | backend | 4 | open |

**🔐 Approved:** 2026-11-03 tahircengiz

> 🔐 Tier 3 (changes the sanitize and send path to a public repo, SPEC §6 Rev 3). The orchestrator adds the Approved line after the human's "yes".

**Goal (1 sentence):** Type-safe `kind`, single-segment and `name:/path` redaction with sanitizer v2, send only for `draft` records, plus the missing rev-3 tests. · **Spec:** `docs/delix/SPEC.md#REQ-11`, `#REQ-12`, `#REQ-13`, `#REQ-3`, §7 rev-3 DoD line 1

## Files (disjoint ownership; do not touch files owned by another card)
- Modify: `scripts/feedback.py`: `:34` `SANITIZER_VERSION`; `:58–60` regexes; `:226–236` `sanitize`; `:338` `validate`; `:560–574` `cmd_send`
- Modify: `README.md` `:137–142` · `README.tr.md` `:136–141` (allowlist + path sentence)
- Modify: `CHANGELOG.md` (one new bullet at the end of `## 0.5.0`, after `:35`)
- Test: `tests/feedback_tests.sh` (new tests only, inserted before the final `rm -rf "$T"` line `:231`)

## Interfaces
- Produced: `send` exit 2 + stderr `error: F<nnn> is <sent|duplicate|dropped|unknown>; nothing sent`; check order repo(7) → id(2) → status(2) → BLOCKED(4) → hash(5) → TTY(6). `preview` is unchanged for every status.
- Produced: `add` with a non-string `kind` → exit 2, stderr `error: kind: must be bug or feature`.
- Consumed: the directory names under `<plugin root>/skills/` (`os.path.join(SCRIPT_DIR, "..", "skills")`), read at run time. If it cannot be read, the set is empty (fail-closed).
- No interface with T009.

## Global Constraints (verbatim from the spec)
- REQ-12: "yalnız şu iki biçim değişmez: `/delixcrew:<skill>` … ve yerleşik komut listesi `/agents /clear /compact /config /context /cost /doctor /exit /export /help /hooks /init /login /logout /mcp /memory /model /permissions /plugin /resume /review /status`". Before comparing, split off trailing `.,;:)` (they stay in the output). Exact match, ASCII only, case-sensitive. "`<ad>:/yol` (scp/NAS biçimi) de yol sayılır (K101)". `SANITIZER_VERSION` `"2"`.
- K100: the exemption is `/delixcrew:<skill>` only, not the `/<name>:<name>` shape.
- K101: "URL'ler (`https://…`) etkilenmez: `//` sonrası parça host kuralına girer."
- REQ-13: "`<status>` yalnız `sent|duplicate|dropped` ise basılır, aksi halde `unknown` (diskten okunan değer terminale basılmaz)". No `gh` call and no record write.
- K97: README text follows the code (`example.com/.net/.org`). The code is not widened.
- K99: no version bump. The new text goes into the 0.5.0 entry.
- K102: the gitleaks timeout test runs in process; no new env var and no code change for it.
- "fixture ve metinlerde iç adres deseni yok" (use `10.x`, `example-corp.dev`, `acme`).

## Steps
1. Write the tests and see them go **red**. Start the new section with a fresh queue (`export DELIXCREW_FEEDBACK_DIR="$T/q3"; Q="$DELIXCREW_FEEDBACK_DIR"`). Add drafts from `$B`. Use the existing `ok`/`bad`/`fb`/`mk`/`jq_`/`tty_run` helpers.
   - REQ-11: `kind` set to `1`, `["bug"]`, `{}` and `null`. Each gives rc 2, stderr contains `kind: must be bug or feature`, no `Traceback`, and no new file.
   - REQ-12 "tek parça": the six inputs from the scenario go into `actual`. `preview` is CLEAN, and none of `/srv`, `/acme-builds`, `/tmp`, `/acme:builds`, `/volume1` is left. `/delixcrew:nosuch` and `/acme-corp:deploy` are redacted (K100).
   - REQ-12 "komutlar": the scenario strings plus `a/b`, `w/o`, `bug / feature` are unchanged.
   - Version: `python3 -c` with `sys.path.insert(0, "$S")` and `import feedback` checks `SANITIZER_VERSION == "2"`.
   - REQ-13:
     - After `fb drop`, run `tty_run "SEND $H"` send with the right hash. Expect rc 2, stderr `error: F00n is dropped; nothing sent`, `gh.log` empty (truncate it first) and the status still `dropped`.
     - Status set with `python3` to `sent`, `null`, missing and `"x\u001b"` gives `sent` / `unknown` / `unknown` / `unknown`.
     - Status `sent` with `GL_RC=1` gives rc 2, not 4 (order).
   - REQ-4 residual: run `fb enable --terms acme`, then put `see x.ioacme.md` in the body. Expect `BLOCKED: residual match after sanitizing`.
   - REQ-4 timeout: `python3 -c` imports `feedback`, sets `feedback.subprocess.run` to a function that raises `subprocess.TimeoutExpired`, then runs `sys.exit(feedback.main(["preview","F00n"]))`. Expect stdout `BLOCKED: gitleaks failed (timeout)` and rc 4.
   - REQ-8 gh missing: build a PATH dir of symlinks to `python3 git script sleep cat sh env grep sed`, plus a copy of the gitleaks and claude stubs, and no `gh`. Expect rc 7, `gh not found` and status `draft`.
   - REQ-8 "list ok, create fails": write a new stub in `$T/stub2/gh` (`issue list` → `[]` rc 0, `issue create` → rc 1) and put it first on PATH. Expect rc 7 and status `draft`. Do not edit the existing stub.
   - REQ-2: set `first_seen`/`last_seen` to `2000-01-01T00:00:00Z`, then add the same draft again. `first_seen` stays the same and `last_seen` changes.
2. Implement in `feedback.py`:
   - In `validate` add `not isinstance(d["kind"], str) or …`.
   - Remove `:` from the `ABS_PATH_RE` lookbehind. Leave `HOME_RE` as it is.
   - Add `SINGLE_SEG_RE` (same lookbehind as the new `ABS_PATH_RE`, `/` + `_SEG`+, not followed by `/`), applied after `ABS_PATH_RE` with `_sub_outside`. Its repl keeps the trailing `.,;:)` and compares the rest against the skill set and the builtin list.
   - In `cmd_send`, add the status check right after `get_record`.
   - Set the version constant to `"2"`.
3. README.md / README.tr.md: in the allowlist, `example.*` → `example.com`, `example.net`, `example.org` (and their subdomains). In the path sentence add single-segment paths (`/srv`), `nas:/volume1/x`, and the two exemptions. CHANGELOG: one bullet (kind type, single-segment paths, earlier preview hashes invalid, send only for drafts).
4. **Green:** run `bash tests/feedback_tests.sh`, then the full loop, then `claude plugin validate .`. Commit everything in one commit, `T008: feedback.py rev 3 hardening (REQ-11–13)`. The PR body has "## How I tested".

## Verification command → expected output
- `bash tests/feedback_tests.sh | tail -1` → `ALL PASSED`. `grep -c '^✘'` on the same output → `0`.
- `for t in tests/*_tests.sh; do bash "$t" || exit 1; done` → every script ends with `ALL PASSED`.
- `claude plugin validate .` → validation passed.

## Review Focus
- Existing test `tests/feedback_tests.sh:109` expects `/delixcrew:feedback` to be kept. `feedback` must be in the skills set.
- Placeholders (`<redacted:path>`) are not re-matched, and the residual check (`:319`) does not fire on `host:<redacted:path>`.
- No value read from disk is printed in the REQ-13 message (uses `args.id` and the mapped status).
- Pre-existing gap, report it and do not fix: `file:///etc/passwd` stays, because the lookbehind has `/`.

## Don'ts
- Untouchable: `scripts/bash_gate.py`, `scripts/write_gate.py`, `.github/**`, `.claude-plugin/**`, `docs/delix/**`, `evals/**`, existing test lines and stubs.
- Do not run the `send` subcommand from Bash by hand outside the test file: the hook denies it by design. Do not try to get around it.
- No new env var, no new dependency, and no realistic key literals.
- If an existing test breaks because of REQ-12, do not edit it: report `NEEDS_CONTEXT`.

## Report contract
`.delix/report.md` (≤ 2K tokens): `DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED` · test output tail with ✔ counts · PR number · assumptions. Read only this card and SPEC REQ-3, 4, 8, 11–13, §4, K94–K102.

## Review findings
### Round 1 (26758b7) — qa ACCEPT · security 🔐 HUMAN_APPROVAL (no finding in this change)
Deterministic gates: CI `test` pass; from `git archive 26758b7`: 4× `ALL PASSED`, 0 `✘` (feedback ✔84); test file diff 86 insertions, 0 deletions.
Pre-existing (not introduced here; follow-up, K104):
- [Medium] `_PATH_LB` still excludes `>`, `\`, `-`, `.`: `cmd >/srv/acme-prod/out.log`, `2>/var/lib/acme/x`, JSON-escaped `\/srv\/acme`, `x-/srv` are not redacted.
- [Medium] URL authority with a single-label host is kept: `smb://nas/volume1/acme`, `http://jenkins:8080/job/acme-x`, `//fileserver/share/x`, `file:///etc/passwd` (K101's "host rule after `//`" only covers dotted names).
- [Low] `cmd_add` duplicate line and `cmd_list` print disk values raw (ANSI/OSC if a record is edited on disk).
- Unsure (noted): concurrent `send` on one draft; U+2215 slash look-alikes; `/export` as a real dir name kept.
