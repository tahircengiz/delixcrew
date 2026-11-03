# T016 — 🔐 feedback.py: URL allowlist, path contexts, Unicode host, list/add escaping

| id | size | tier | role | wave | status |
|---|---|---|---|---|---|
| T016 | M | 3 | backend | 1 | open |

> 🔐 Tier 3: `sanitize()` filters text published on a public repo (issue body, triage comment; SPEC §6). The lead adds the Approved line after the human says "yes".

**Goal (1 sentence):** `sanitize()` keeps only allowlisted URLs, redacts absolute paths in every non-word left context, UNC paths and Unicode hosts, `SANITIZER_VERSION` becomes `"3"`, and `list`/`add` print disk values escaped. · **Spec:** `docs/delix/SPEC.md#REQ-1`, `#REQ-2`, `#REQ-3`, `#REQ-4`, `#REQ-5`, `#REQ-7`; §6; K134–K139, K142, K146–K148

## Files
- Modify: `scripts/feedback.py`
- Modify: `tests/feedback_tests.sh` (lines 255–256 only)
- Modify: `tests/triage_tests.sh` (line 21 only)
- Create: `tests/sanitize_tests.sh`

## Edit anchors (base 79ef030; match the content, not only the number)
`scripts/feedback.py`:
1. Replace line 34 `SANITIZER_VERSION = "2"` → `SANITIZER_VERSION = "3"`.
2. Replace line 49 `RESERVED_TLDS = {"example", "test", "invalid", "localhost"}  # RFC 2606` → `RESERVED_TLDS = {"example"}  # K147` (`localhost` stays allowed as an exact name through `ALLOWED_HOSTS`).
3. Replace line 60 `_PATH_LB = r"(?<![\w.~/<>\]\\-])"  # K101: no ':' here, …` (K135): not after `\w` or `~`, not after a `./`/`../` prefix whose first `.` is not preceded by `\w` or `.`. Suggested: `r"(?<![\w~])(?<!(?<![\w.])\.)(?<!(?<![\w.])\.\.)"`. Lines 61–62 keep using it; line 58 `HOME_RE` unchanged.
4. Replace line 71 `TOKEN_RE = re.compile(r"(?<![\w.@-])[A-Za-z0-9_-]+(?:\.[A-Za-z0-9_-]+)+(?![\w-])")`: label class `[\w-]` (Unicode, REQ-3). Line 72 unchanged.
5. Insert after line 73 `DOC_NETS = [ipaddress.ip_network(n) for n in (…)]`: `UNC_RE`, `URL_SCHEME_RE`, `URL_NAME_RE`, `URL_HOST_OK_RE`, `URL_TAIL_OK_RE`, `URL_STOP` (Step 2).
6. Insert after line 167 `    h = host.lower().rstrip(".")`: `if not h.isascii(): return False` (K137).
7. Lines 174–179 `_host_repl`: move the host test of line 177 into `_looks_like_host(tok)` (last label ≥ 2, `LAST_LABEL_RE`, not in `FILE_EXTS`); same output.
8. Insert after line 205 `    return "".join(p if i % 2 else regex.sub(repl, p) for i, p in enumerate(parts))`: `_url_allowed(…)`, `_url_split(text, term_re) -> list[tuple[str, bool]]` (True = allowed URL, untouched).
9. Replace lines 249–259 (`def sanitize(text, term_re):` … `    return t`), same signature (Step 2).
10. Insert after line 293 `    return c not in "\n\t" and unicodedata.category(c) in ("Cc", "Cf", "Co")`: `def tty_escape(s: str) -> str` (K139: `not c.isprintable()` → `\xnn` ≤ U+00FF, `\unnnn` ≤ U+FFFF, else `\Unnnnnnnn`, lower-case hex; `\` itself not escaped).
11. Replace line 459 `            print("%s duplicate (count %d, %s)" % (r["id"], r["count"], r.get("status")))`: wrap id and status in `tty_escape(str(…))`.
12. Replace lines 513–514 (`    rows += [(str(r.get("id", "")), …` + continuation): every column `tty_escape(str(…))`; line 515 widths then use escaped text.

`tests/feedback_tests.sh`: on line 255 change `SANITIZER_VERSION == "2"` to `"3"`; on line 256 change `is 2` / `not 2` to `is 3` / `not 3`. Nothing else.
`tests/triage_tests.sh` line 21 (`hash_()`): substring `"sanitizer_version":"2"` → `"sanitizer_version":"3"`. Nothing else.

## Interfaces
- Produced: `feedback.sanitize(text: str, term_re) -> str` (signature unchanged); `SANITIZER_VERSION = "3"`; placeholder `<redacted:url>`; `feedback.tty_escape(s: str) -> str`.
- Consumed, keep importable and unchanged: `scripts/triage.py:26-28` imports `GH_SCRUB, OPAQUE_RE, REPO, SANITIZER_VERSION, bad_char, err, gh, gitleaks, load_config, local_terms, now, read_json, repo_ok, sanitize, term_regex, write_json`. K142: `triage.py` does not change; its comments get the new rules through `sanitize`.

## Global Constraints (from the spec)
- Order NFKC → URL → home → path → … → term. An allowed URL stays exactly as written and no later step touches it.
- URL forms, stop characters, authority, allowed hosts: SPEC REQ-1. Any parse doubt → not allowed (fail closed).
- K146: path `[A-Za-z0-9._~/-]`, after `?`/`#` `[A-Za-z0-9._~=&+-]`; no `.`/`..` segment; no host, IPv4 or `term_re` match in the tail. `%` → not allowed; no percent-decoding.
- K136: only canonical IPv4 (`str(IPv4Address(h)) == h`) or bracketed IPv6 without a zone, and only `_ip_allowed`.
- REQ-4: no fixpoint loop; the residual check (lines 342–343) and the existing BLOCKED cases stay.
- Repo rule / REQ-5: no overlapping alternation (`(a|a.)*`); every new or changed regex gets a ≈50 000-character timing case < 0.5 s.
- Stdlib only (K71). `feedback.py` stays a single file (the test copies it alone into `$T/fake`).

## Steps
1. Create `tests/sanitize_tests.sh` in the style of `tests/feedback_tests.sh:4-15`: temp `HOME`, `USER`, `DELIXCREW_FEEDBACK_DIR`; stub `claude` and `gitleaks` on PATH. Cases go in heredocs (or a Python file written by the test), one per line, checked by `python3` calling `feedback.sanitize`:
   - REQ-1: every WHEN/THEN of SPEC REQ-1, line for line. "Authority tricks" checks absence plus prefix. `--terms acme` means `term_regex({"acme"})`.
   - REQ-2 and REQ-3: every WHEN/THEN of SPEC REQ-2 and REQ-3.
   - REQ-4: `s(s(x)) == s(x)` for every input above, plus one `add` + `preview` whose `actual` holds the REQ-1 inputs: the VERDICT has no `residual match`.
   - REQ-5: the 7 inputs of SPEC REQ-5, plus `"https://github.com/"+"a/"*25000`, `"http://x/?"+"a&"*25000`, `"ü."*25000`, `"a."*25000+"/"`. Each goes through `sanitize(x, None)` and prints `✔ REQ-5 <name> <s> s`; ≥ 0.5 s fails.
   - REQ-7: SPEC REQ-7 scenario. Edit records with default `json.dump`. Check stdout bytes in Python: no 0x1B, 0x07 or U+2028; the texts `\x1b]8;;`, ` ` and `\ud800` are visible; exit 0; `status` on disk still raw.
   Run it and see **red**.
2. Implement edits 1–12:
   - `URL_SCHEME_RE = (?<![A-Za-z0-9+.\-/:\\])(?:[A-Za-z][A-Za-z0-9+.-]*:)?//`. The lookbehind lets a long run start only once. If whitespace, the end of text or a stop character other than `[` follows `//`, there is no URL.
   - The authority runs to the first `/ \ ? #`, stop character or end; a `[…]` IPv6 host is kept whole. The URL runs to whitespace or a stop character. Trailing `.,;:` go back into the text. The next search starts at the URL end, so the scan stays linear.
   - `URL_NAME_RE = (?<![\w.@/:\\-])([\w-]+(?:\.[\w-]+)*)(?::(\d{1,5}))?/` runs only on text left over after the scheme pass. It is a URL only if it has a port or `_looks_like_host(name)`; otherwise continue at `m.end()`.
   - Allowed only if: no `@` in the authority; port of 1–5 digits dropped; host lower-cased and a fullmatch of `[a-z0-9.-]+|\[[0-9a-f:.]+\]`; host passes `is_allowed_host` or is an allowed IP; the github.com rule (SPEC REQ-1; segments from `path.split("/")` without dropping empty ones, case-insensitive); the tail is a fullmatch of `[A-Za-z0-9._~/-]*(?:\?[A-Za-z0-9._~=&+-]*)?(?:#[A-Za-z0-9._~=&+-]*)?` and holds no `.`/`..` segment and no host, IPv4 or term match.
   - Not allowed: `scheme://<redacted:url>`; the other forms become `<redacted:url>` whole.
   - `UNC_RE = (?<![\w\\])\\\\[^\s\\]+(?:\\[^\s\\]*)*`, placed after `WIN_ABS_RE` in the tuple.
   - `sanitize`: NFKC → `_url_split`; each unprotected segment gets today's lines 251–258; join.
3. Make it **green**: `bash tests/sanitize_tests.sh`, then the full loop. `tests/triage_tests.sh` must pass with no other edit.
4. Commit `T016: feedback sanitize URL allowlist, path contexts, IDN host, list/add escaping`. The PR body has "## How I tested" with the REQ-5 timings (use `--body-file`).

## Verification command → expected output
- `bash tests/sanitize_tests.sh` → every line ✔, 11 `REQ-5 … s` lines all < 0.5, last line `ALL PASSED`
- `for t in tests/*_tests.sh; do bash "$t" || exit 1; done` → exit 0
- `python3 -c 'import sys;sys.path.insert(0,"scripts");import feedback as f;print(f.sanitize("smb://nas/x http://localhost:8080/a //fs/s jenkins:8080/j cmd >/srv/a bücher.example-corp.de",None))'` → `smb://<redacted:url> http://localhost:8080/a <redacted:url> <redacted:url> cmd ><redacted:path> <redacted:host>`
- `git diff -U0 origin/main -- tests/feedback_tests.sh tests/triage_tests.sh | grep -c '^[-+][^-+]'` → `6`; `git diff --stat origin/main -- scripts/triage.py` → empty

## Review Focus
- These stay as they are: `tests/feedback_tests.sh:100,109,229,249` (`github.com/tahircengiz/delixcrew`, `~/.claude/plugins/cache/…/0.5.0/skills/x`) and `:242-246` (`nas:/volume1` stays a path, K148).
- Segment edge: in `(https://github.com/tahircengiz/delixcrew)/srv/x`, `/srv/x` is redacted. `https://github.com/tahircengiz/delixcrew./srv` is not allowed.
- `[fe80::1%en0]` is not allowed; `http://[::1]:8080/` is allowed; `https://github.com//tahircengiz/delixcrew` is not allowed.
- Note only: a duplicate `add` on a record that holds a lone surrogate would still fail in `write_json`; the spec puts the surrogate in another record.

## Don'ts
- Do not touch: `scripts/triage.py`, `scripts/*_gate.py`, `scripts/common.py`, `hooks/**`, `README*`, `CHANGELOG.md`, `site/**`, `.claude-plugin/**`, `.github/**`, `docs/delix/**`, any other `tests/*`.
- In the two existing test files, change only the three version lines. If anything else goes red, do not edit it: report `NEEDS_CONTEXT` with the input and the output.
- No new dependency, no fixpoint loop, no network.

## Report contract
`.delix/report.md` (≤ 1.5K tokens): status · commands + output (✔ count, the 11 timings) · PR number · assumptions. Read only this card and SPEC REQ-1–5, REQ-7, §6.

## Review findings (filled by the lead)
