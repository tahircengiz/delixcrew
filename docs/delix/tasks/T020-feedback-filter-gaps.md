# T020 — 🔐 feedback.py: path after a host, IP edge forms, invisible-character allowlist, cmd_add id check

| id | size | tier | role | wave | status |
|---|---|---|---|---|---|
| T020 | M | 3 | backend | 1 | open |

> 🔐 Tier 3: `sanitize()` filters text published on a public repo (issue body, triage comment; SPEC §6). The lead adds the Approved line after the human says "yes".

**🔐 Approved:** 2026-11-04 tahircengiz

**Goal (1 sentence):** `sanitize()` redacts the path or port after a host, IP, e-mail or MAC address, and a plain-text `github.com/…` path outside the owner allowlist. It also recognises IPs next to `_` and IPv4 with leading zeros. `build()` blocks characters outside the K133 allowlist as `invisible character` and never crashes on a lone surrogate, and `cmd_add`/`get_record` accept only ids that pass `ID_RE.fullmatch`. · **Spec:** `docs/delix/SPEC.md#REQ-1` … `#REQ-6`; §4, §6; K159–K163, K165, K168–K172

## Files
- Modify: `scripts/feedback.py`
- Modify: `scripts/triage.py`: only move `visible`, `invisible`, `INVISIBLE_IN_ALLOWED`, `INVISIBLE_RANGES`, `SELECTORS` (and their K133 comment) into `feedback.py`, and import them. No behaviour change.
- Test: `tests/sanitize_tests.sh`: **insert only**. No existing line changes or is deleted.

## Edit anchors (base 5638435; match the content, not only the number)
`scripts/feedback.py`:
1. Line 69 `IPV4_RE = re.compile(r"(?<![^\W_])(?<!\.)\d{1,3}(?:\.\d{1,3}){3}(?!\w|\.\d)")`: change the lookahead `(?!\w|\.\d)` to `(?![^\W_]|\.\d)`, so `_` may follow.
2. Line 70 `IPV6_RE = re.compile(r"(?<![\w:.])[0-9A-Fa-f]*:[0-9A-Fa-f:]*:[0-9A-Fa-f]*(?![\w:])")`: change the lookbehind to `(?<![^\W_]|[:.])` and the lookahead to `(?![^\W_]|:)`.
3. Line 77 `URL_NAME_RE = re.compile(r"(?<![\w.@/:\\-])([\w-]+(?:\.[\w-]+)*)(?::(\d{1,5}))?/")`: remove `:` and `\\` from the lookbehind, giving `(?<![\w.@/-])`. Edit 6 then limits what is accepted after `:`/`\`.
4. Insert after line 84 `URL_RUN_RE = re.compile(r"[^\s%s]*" % _STOP_CLS)`:
   - REQ-1b `AFTER_PH_RE`: `(<redacted:(?:host|ip|email|mac)>)[:/][^\s<stop chars>]+`.
   - REQ-1c `GH_PLAIN_RE`: `(?<![\w-])(github\.com)(/[^\s<stop chars>]*)`, `re.IGNORECASE`.
   - Stop chars = `_STOP_CLS`.
5. Line 208 `        return m.group(0)` (inside `_ipv4_repl`, lines 204–209; **not** line 216 in `_ipv6_repl`): return `"<redacted:ip>"` if every octet is ≤ 255, else `m.group(0)` (K172, fail closed).
6. Lines 287–289 in `_url_pass` (`            if not (m.group(2) or _looks_like_host(m.group(1))):` / `pos = m.end()` / `continue`):
   - If the character before `m.start()` is `:` or `\`, the match is a URL only if `_looks_like_host(m.group(1))`. The port alone does not count there (REQ-1a, K169).
   - Otherwise the rule stays as it is today.
7. Insert after line 342 `    return "<redacted:path>" + tok[len(core):]` (end of `_single_seg_repl`), before line 345 `def plugin_skills():`: `_gh_plain_repl(m)`:
   - Segments are `m.group(2)` with trailing `.,;:` stripped, lower-cased, split on `/`.
   - Keep the match if `segs[1:3] == ["tahircengiz", "delixcrew"]`, `segs[1] == "anthropics"`, or `m.group(2) == "/"`.
   - Otherwise return `github.com` as written + `<redacted:path>` + the trailing `.,;:`.
8. Insert after line 363 `                t = _sub_outside(regex, repl, t)` (inside the `for regex, repl` loop of `sanitize`), at the loop's indentation level, before line 364 `            if term_re:`:
   - `t = _sub_outside(GH_PLAIN_RE, _gh_plain_repl, t)`
   - then `t = AFTER_PH_RE.sub(<placeholder + "<redacted:path>" + trailing .,;: of the match>, t)`.
   - `AFTER_PH_RE` must run on the placeholders, so do not wrap it in `_sub_outside`.
9. Insert between line 401 `    return c not in "\n\t" and unicodedata.category(c) in ("Cc", "Cf", "Co")` and line 404 `def tty_escape(s):`:
   - `scripts/triage.py` lines 51–56: the 3-line K133 comment and the 3 constants, verbatim.
   - `def visible(c)`: verbatim from triage.py lines 287–291.
   - `def invisible(text, extra="")`: triage.py lines 294–304, where `elif not visible(c):` becomes `elif c not in extra and not visible(c):`.
   - Keep two blank lines between top-level blocks.
10. Insert after line 435 `    content = {"repo": REPO, "label": LABELS.get(rec.get("kind"), "bug"), "title": title, "body": body}`:
    - Search for a Cs character in `raw_vals` + `str(rec.get("kind", ""))` + `str(rec.get("fingerprint", ""))`.
    - If one is found, `return content, ["invisible character"], ""`. No gitleaks, no hash.
11. Insert after line 444 `        reasons.append("unicode control character (Cc/Cf/Co)")`: `if invisible(raw, "\t") or invisible(clean, "\t"): reasons.append("invisible character")`. `raw` is the NFKC text of line 437.
12. Insert after line 484 `        vals = d.get(k) if k == "repro" else [d.get(k) or ""]` (in `validate`): `if any(unicodedata.category(c) == "Cs" for x in vals for c in x): return "%s: lone surrogate" % k`.
13. `cmd_add` and `get_record`, three changes:
    - Line 569 `        if r.get("fingerprint") == fp:`: add `and isinstance(r.get("id"), str) and ID_RE.fullmatch(r["id"])`.
    - Line 576: `ID_RE.match(str(r.get("id", "")))` becomes `ID_RE.fullmatch(str(r.get("id", "")))`.
    - Line 639 `    if not ID_RE.match(rid):` becomes `ID_RE.fullmatch`.
    - Line 39 `ID_RE` itself is unchanged.

`scripts/triage.py`:
14. Lines 27–28 `from feedback import (GH_SCRUB, OPAQUE_RE, … write_json)`: add `invisible, visible` to the import list. The rest stays.
15. Delete lines 51–56 (K133 comment + `INVISIBLE_IN_ALLOWED`, `INVISIBLE_RANGES`, `SELECTORS`). Delete lines 287–306 (`def visible` … `return False` plus one blank line), so two blank lines remain before line 307 `def actions(decision):`. Keep line 23 `import unicodedata`: it is still used at lines 327, 332 and 342. Line 332 `invisible(t)` keeps the default `extra=""`, so a tab is still invisible in triage.

## Interfaces
- Produced:
  - `feedback.visible(c) -> bool`
  - `feedback.invisible(text: str, extra: str = "") -> bool`
  - constants `feedback.INVISIBLE_IN_ALLOWED`, `INVISIBLE_RANGES`, `SELECTORS`
  - BLOCKED reason `invisible character`
  - `validate()` error `<field>: lone surrogate` (`add` exits 2)
- Unchanged: `feedback.sanitize(text, term_re) -> str` (signature); `SANITIZER_VERSION = "3"` (K161); `bad_char` and the reason `unicode control character (Cc/Cf/Co)` (K169); every name that `triage.py` imports today.
- Consumed by T021 (docs, wave 2) after merge: the outputs below.

## Global Constraints (from the spec)
- REQ-1a applies only to a dotted host (last label passes `_looks_like_host`). In this context `name:port/…` is not a URL candidate. MAC and IPv6 groups keep their current rules. The other left contexts (`\w . @ / -`) stay exempt.
- REQ-1b applies only right after a placeholder (K168). Do not reorder the sanitize steps. The part ends at whitespace or one of `` `'"<>()[] ``; trailing `.,;:` stays.
- REQ-1c: in every left context except `\w` and `-`. Only `tahircengiz/delixcrew` and `anthropics/…` stay.
- REQ-2: an address glued to a letter, a digit or `.` is still not recognised.
- K163: do not touch `_url_pass` merging (`put()` lines 271–275, `return out` line 301). K164: no site change.
- REQ-5: no overlapping alternation. Every new or changed regex: a ≈50 000-character input through `sanitize(x, None)` in < 0.5 s.
- Stdlib only (K71). `feedback.py` stays a single file: `tests/feedback_tests.sh:174` copies it alone.
- No existing test expectation is relaxed. `tests/triage_tests.sh` passes unchanged.
- Example values only like `acme-corp`, `10.1.2.3`, `example-corp`. No real internal names.
- Invisible characters are always written as `\uXXXX` escapes (Python) in code and tests, never as raw characters.

## Steps
1. **Write the failing tests first** (insert only, base 5638435, `tests/sanitize_tests.sh`). Separate columns with a literal TAB, as in the existing heredocs.
   a. **Case files.** Insert after line 157 `EOF` (end of `r3_absent.txt`), before line 159 `cat > "$T/cases.py" <<'PY'`, four heredocs:
      - `t020_req1_exact.txt` (input → expected):
        - `key:ci.acme-corp.net/api/x` → `key:<redacted:url>`
        - `ref:github.com/acme/private` → `ref:<redacted:url>`
        - `x\ci.acme-corp.net/api/x` → `x\<redacted:url>`
        - `user@ci.acme-corp.net/api/x` → `<redacted:email><redacted:path>`
        - `see 10.1.2.3/api/x` → `see <redacted:ip><redacted:path>`
        - `a/ci.acme-corp.net:8080/api/x` → `a/<redacted:host><redacted:path>`
        - `ci.acme-corp.net:acme/private` → `<redacted:host><redacted:path>`
        - `git@github.com:acme/private` → `<redacted:email><redacted:path>`
        - `vendor/github.com/acme/private-lib/x.go` → `vendor/github.com<redacted:path>`
        - `~/src/github.com/acme/private` → `~/src/github.com<redacted:path>`
        - `(@github.com/acme/private)` → `(@github.com<redacted:path>)`
        - `see x.acme-corp.net: ok` → `see <redacted:host>: ok`
        - `nas:/volume1/x` → `nas:<redacted:path>`
        - `de:ad:be:ef:00:11/x` → `<redacted:mac><redacted:path>`
        - Trailing punctuation: `see 10.1.2.3/api/x.` → `see <redacted:ip><redacted:path>.` and `vendor/github.com/acme/x,` → `vendor/github.com<redacted:path>,`
        - §6 / K169 fail closed: `10.1.2.0/24` → `<redacted:ip><redacted:path>`, `fd00::/64` → `<redacted:ip><redacted:path>`, `10.1.2.3:8080` → `<redacted:ip><redacted:path>`, `fd12:3456:789a:1:2:3:4:5/64` → `<redacted:ip><redacted:path>`
      - `t020_req1_kept.txt` (unchanged, one per line): `see github.com/tahircengiz/delixcrew/issues/1.`, `go github.com/anthropics/x`, `github.com/`, `a/b`, `w/o`, `a:b:8080/x`
      - `t020_req2_exact.txt`: `10.20.30.40_` → `<redacted:ip>_`; `fd00:1:2::3_` → `<redacted:ip>_`; `_fd00:1:2::3` → `_<redacted:ip>`; `host 010.001.002.003` → `host <redacted:ip>`; `v1.2.3.4` → `v1.2.3.4`; `1.2.3.4a` → `1.2.3.4a`; `999.1.1.1` → `999.1.1.1`
      - `t020_req6_exact.txt`: `a//b` → `a/<redacted:path>`; `>/Users/alice/x` → `><redacted:path>`
   b. **Loops in `cases.py`.** Insert after line 238 `    res("jenkins" not in got and "acme" not in got, "round 3 %s → %s" % (x, got))`, before line 239 `res(f.SANITIZER_VERSION == "3", …)`. Every call goes through `s(x)` (no term), so the inputs join `seen` for the REQ-4/REQ-6 idempotence check on line 241.
      - `pairs("t020_req1_exact.txt")` → `T020 REQ-1 <in> → <want>`
      - `lines("t020_req1_kept.txt")` → unchanged
      - `pairs("t020_req2_exact.txt")` → `T020 REQ-2 …`
      - `pairs("t020_req6_exact.txt")` → `REQ-6 <in> → <want>` (one ✔ line each)
      - Then REQ-3 function checks, with `inv = getattr(f, "invisible", None)` so that red prints ✘ instead of crashing:
        - `inv("ok" + "︀"*8)`, `inv("aㅤb")`, `inv("a b")`, `inv("a b")` → True
        - `inv("I ❤️ it", "\t")`, `inv("a\tb\nc", "\t")` → False
        - `inv("a\tb")` → True (triage default)
        - `import triage`; `triage.invisible is f.invisible and triage.visible is f.visible`
   c. **REQ-5 timings.** Insert after line 256 `    res(dt_ < 0.5, "REQ-5 %s %.3f s" % (name, dt_))`, before line 257 `sys.exit(FAIL)`.
      - Add `best(x)`: the minimum of 3 `perf_counter` runs of `f.sanitize(x, None)`.
      - Cases, each cut to ≈50 000 characters, each printing `✔ REQ-5 t020-<name> <s> s` and failing at ≥ 0.5 s:
        - `"a //b "` repeat
        - `"http://github.com/tahircengiz/delixcrew/" + "1."` repeat
        - `"key:a.bc/"` repeat
        - `"<redacted:host>/" * 3125`
        - `"<redacted:host>:" * 3125`
        - `":" * 50000`
        - `"\\" * 50000`
        - `"_a:"` repeat
        - `"github.com/"` repeat
        - `"010." * 12500`
      - Growth check: `best` of `("a //b " * 33334)[:200000]` ≤ 6 × `best` of the 50 000 version. Print both values and the ratio.
   d. **Second residual draft (REQ-6).** Insert after line 276 (`  && ok "REQ-4 preview of the REQ-1 inputs: no residual match ($v)" || bad …`), in the same queue `$T/q` (terms `acme`).
      - Build the draft the same way as lines 263–272, from the first column of `req2_redirect.txt`, `req2_kept.txt`, `req3.txt`, `t020_req1_exact.txt`, `t020_req1_kept.txt`, `t020_req2_exact.txt`.
      - Use title `"Path and IP inputs"` and new variable names (`J6`, `out6`, `id6`, `v6`).
      - If `add` reports a field over 2000 characters, split the inputs across `actual` and `context`.
      - Pass: `out6 = "<id> new"`, the first preview line starts with `VERDICT:`, and it has no `residual match`.
   e. **CLI checks.** Insert after line 309 `PY` (end of the REQ-7 block), before line 311 `rm -rf "$T"; …`: one `python3 - "$S/feedback.py" "$T" <<'PY' || FAIL=1` block.
      - Use `subprocess.run([sys.executable, fb, …], env=dict(os.environ, DELIXCREW_FEEDBACK_DIR=<own queue>), cwd=$T/proj, capture_output=True)`.
      - Use one new queue per case (`$T/q3b0` …). Run `enable` first. Use the same `res()` style as lines 295–298.
      - REQ-3 blocked:
        - Inputs: `title` = `"ok"+"︀"*8`; `title` = `"aㅤb"`; `actual` = `"x y"`; `actual` = `"x y"`.
        - Expected: `add` exit 0; `preview` exit 4; the first stdout line starts with `VERDICT: BLOCKED: ` and contains `invisible character`; stdout bytes contain neither U+2028 nor U+2029 (UTF-8).
      - REQ-3 allowed: `title` = `"I ❤️ it"`, `actual` = `"a\tb\nc"`. Preview stdout has no `invisible character`.
      - Surrogate in a record file:
        - `add` a draft, then rewrite the record file with `json.dump` (default `ensure_ascii`) and `title` = `"x\ud800"`.
        - Expected: `preview` exit 4, first line exactly `VERDICT: BLOCKED: invisible character`, no `Traceback` in stderr; `list` exit 0 and no `Traceback`.
        - Repeat with `"fingerprint": "\ud800"`: preview exit 4, no `Traceback`.
      - Surrogate through `add`: stdin `json.dumps(draft with title "x\ud800")`. Expected exit 2, stderr contains `title: lone surrogate`, no `Traceback`, and the queue listing is unchanged.
      - REQ-4: for each bad id `"../x"` and `"F001\n"`, in its own queue:
        - `add` a draft (`F001 new`), set the record's `id` to the bad id, then run the same `add` again.
        - Expected: exit 0, stdout exactly `F002 new`; the queue listing is the old one + `F002.json`; the listing of `$T` (parent) is unchanged (no `x.json`).
        - In the `"F001\n"` queue, `preview "F001\n"` exits 2.
   f. Run `bash tests/sanitize_tests.sh` and see **red**. Expected red: the REQ-1/REQ-2/REQ-3/REQ-4 cases and the surrogate Traceback. The REQ-6 pins and most timings may already be green; that is expected.
2. **Implement** edits 1–15. Touch only the paths in Files.
3. **Green:** `bash tests/sanitize_tests.sh`, then the full loop. If an existing line goes ✘, do not edit it: report `NEEDS_CONTEXT` with the input and output.
4. **Commit** `T020: feedback path after host, IP edges, invisible-character allowlist, cmd_add id check`. The PR body (`--body-file`) has `## How I tested` with the commands, the ✔/✘ counts and **every REQ-5 timing** (10 new + growth ratio). The lead runs the internal-address scan before push.

## Verification command → expected output
- `for t in tests/*_tests.sh; do bash "$t" || exit 1; done` → exit 0.
- `bash tests/sanitize_tests.sh` → no `✘` line; 28 `REQ-5 …` lines (17 existing, measured at 5638435, + 10 `t020-…` + 1 growth), each < 0.5 s, growth ≤ 6×; last line `ALL PASSED`.
- `python3 -c 'import sys;sys.path.insert(0,"scripts");import feedback as f;print(f.sanitize("key:ci.acme-corp.net/api/x see 10.1.2.3/api/x vendor/github.com/acme/x 10.20.30.40_ host 010.001.002.003 de:ad:be:ef:00:11/x",None))'` → `key:<redacted:url> see <redacted:ip><redacted:path> vendor/github.com<redacted:path> <redacted:ip>_ host <redacted:ip> <redacted:mac><redacted:path>`
- `python3 -c 'import sys;sys.path.insert(0,"scripts");import feedback,triage;print(triage.invisible is feedback.invisible, triage.invisible("a\tb"), feedback.invisible("a\tb","\t"))'` → `True True False`
- `git diff origin/main -- tests/sanitize_tests.sh | grep -c '^-[^-]'` → `0`
- `git diff -U0 origin/main -- scripts/triage.py | grep '^+[^+]'` → only the `from feedback import (…)` line(s)
- `git diff --stat origin/main` → only the 3 files in Files.

## Review Focus
- `_url_pass` `put()`/`return out` are unchanged (K163).
- After `:`, `name:port/` is never a URL: `de:ad:be:ef:00:11/x` and `fd12:3456:789a:1:2:3:4:5/64` leave no hex group visible (K169). Tests: step 1a.
- Cs check covers `kind` and `fingerprint` too. Without it, `fingerprint()` or the hash raises on a hand-edited record. Test: step 1e.
- `ID_RE` `$` matches before a trailing `\n`, which is why `fullmatch` is needed (`"F001\n"`). `get_record` is tightened the same way.
- Tab is allowed only in feedback (`extra="\t"`). Triage still blocks it (`tests/triage_tests.sh` unchanged).
- Expected fail-closed effects (SPEC §6): `1.2.3.4_beta` → `<redacted:ip>_beta`; network prefixes and `ip:port` → `<redacted:ip><redacted:path>`; Devanagari in a draft is BLOCKED.
- Not a target: REQ-1b ends at `<` (`…/api<b>internal/secret`); plain `<redacted:x>` text splitting an IP (§6).

## Don'ts
- Do not touch: `scripts/write_gate.py`, `scripts/bash_gate.py`, `scripts/stop_gate.py`, `scripts/common.py`, `hooks/**`, `README*`, `CHANGELOG.md`, `site/**`, `.claude-plugin/**`, `.github/**`, `docs/delix/**`, and every other `tests/*` file.
- In `tests/sanitize_tests.sh`, do not change or delete any existing line. If a test looks wrong, stop: `NEEDS_CONTEXT`.
- No new dependency, no fixpoint loop, no network, no `SANITIZER_VERSION` change, no change to `bad_char`.

## Notes
- Optional reference, not a spec: the lead's prototype diffs `t020-prototype-feedback.diff` and `t020-prototype-triage.diff`. The lead gives their location in the handoff; they are outside the repo.
  - They cover REQ-1, REQ-2 and REQ-3 and passed all 8 `tests/*_tests.sh` suites. That run did not include the new tests above.
  - They do **not** cover REQ-4 (`ID_RE.fullmatch`) or the Cs check on `kind`/`fingerprint`: implement edits 10 and 13 yourself.
  - Do **not** copy their `_url_pass` `put()` list rewrite (K163, out of scope).
  - Their triage diff leaves extra blank lines where `visible`/`invisible` were.
  - You may implement differently if every SPEC output holds.

## Report contract
`.delix/report.md` (≤ 1.5K tokens): `DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED` · commands + output (✔/✘ count, all REQ-5 timings, growth ratio) · PR number · assumptions. Read only this card and SPEC REQ-1–REQ-6, §4, §6, §9.

## Review findings (filled by the lead)
- Round 1 (deterministic gate, PR #39 @ 907012c): CI `test` failed with `✘ REQ-5 t020-growth a //b 50K 0.104 s, 200K 0.809 s, ratio 7.79 (≤ 6)`.
  - **F1 [P1]** Root cause: `_url_pass` merges unprotected parts by string concatenation, which is quadratic. Lead measurement, main `7d2889a`, `a //b ` repeat: 200K 0.533 s, 800K 5.514 s. With list accumulation the same input takes 0.278 s and 1.104 s. K163 is withdrawn and replaced by K173.
  - Fix:
    1. In `put()`, collect the parts of each segment in a list and join them in the `return`, so `_url_pass` returns the same `[(str, bool)]` with identical output.
    2. The growth check added in this PR measures 50K against 400K (`("a //b " * 66667)[:400000]`) with limit ≤ 12× (best of 3), and prints both times and the ratio.
  - Measured ratios: quadratic 17.1, linear 8.0.
  - Global Constraint "K163: do not touch `_url_pass` merging" no longer applies: only this list change is allowed, nothing else in `_url_pass`.
