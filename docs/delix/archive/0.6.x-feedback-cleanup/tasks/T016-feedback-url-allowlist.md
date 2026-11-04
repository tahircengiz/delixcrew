# T016 — 🔐 feedback.py: URL allowlist, path contexts, Unicode host, list/add escaping

| id | size | tier | role | wave | status |
|---|---|---|---|---|---|
| T016 | M | 3 | backend | 1 | open |

> 🔐 Tier 3: `sanitize()` filters text published on a public repo (issue body, triage comment; SPEC §6). The lead adds the Approved line after the human says "yes".

**🔐 Approved:** 2026-11-03 tahircengiz

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

### Round 0 (2026-11-03, PR #33, b8ca34f, base f46f006)
- Deterministic gates (lead, from `git archive b8ca34f`): `bash tests/sanitize_tests.sh` 92 ✔ ALL PASSED, 11 REQ-5 timings ≤ 0.024 s; full loop exit 0; existing tests: only the 3 version lines; CI `test` + `check` SUCCESS.
- qa: ACCEPT_WITH_NOTES (P0 0, P1 0, P2 1). security: FIX (1 Medium, 2 Low). Lead reproduced every input below on b8ca34f.
- **[Medium, fix] F1 scheme bypass** (`scripts/feedback.py:46` `URL_SCHEME_RE`, `_url_pass` keep branch): an allowed URL is kept with any scheme, and the scheme text is only term-checked. `jenkins.acme-corp.internal://github.com/tahircengiz/delixcrew`, `acme-corp.dev+https://github.com/anthropics/x`, `ip-10-1-2-3.ec2.internal://code.claude.com/docs`, `bücher.example-corp.de+https://github.com/tahircengiz/delixcrew` all come out unchanged. Fix: a URL is allowed only if its scheme is empty (`//`, `host/`, `name:port/` forms), `http` or `https` (ASCII, case-insensitive); any other scheme → not allowed (then the denied form's prefix goes through the later rules as today). Test: each input above, assert `jenkins`, `acme`, `ec2.internal`, `example-corp`, `bücher` are absent from the output.
- **[P1, fix] F2 Unicode TLD** (REQ-3 "Unicode harfleriyle de tanımalı"): `LAST_LABEL_RE` is ASCII, so `intranet.corp.рф` and `foo.рф/x` come out unchanged. Fix: the last label may start with any Unicode letter (`[^\W\d_]`), `FILE_EXTS` check unchanged. Test: `intranet.corp.рф` → `<redacted:host>`; `foo.рф/x` → `<redacted:url>`; `notlar.md` unchanged.
- **[P1, fix] F3 host after a leading dot** (REQ-1 K146 tail "no REQ-3 host"; also plain text): `TOKEN_RE` lookbehind `(?<![\w.@-])` skips a host right after `.`: `https://code.claude.com/.jenkins.acme-corp.internal` and `see .jenkins.acme-corp.internal`, `a..jenkins.acme-corp.internal` come out unchanged. Fix: a host token may also start right after one or more `.` (keep one start per run, no overlapping alternation); the allowed-URL tail check uses the same rule. Test: first input → `https://<redacted:url>`; the other two lose `jenkins`/`acme-corp`.
- **[P1, fix] F4 e-mail prefix regression** (line 36, `EMAIL_RE` local part `{1,64}`, outside the card's anchors): `"a"*70+"@corp.com"` → `aaaaaa<redacted:email>` (main redacts it whole). Fix: unbounded local part with a lookbehind `(?<![A-Za-z0-9._%+-])` so each run starts once (linear); add a REQ-5 timing case for `"a"*50000+"@"` and `"."*50000` through `sanitize`. Test: the 70-char address → exactly `<redacted:email>`.
- [P2, no fix, notes] `Link:https://github.com/tahircengiz/delixcrew` → `Link:https:/<redacted:path>` (fail closed). `cmd_add` duplicate branch writes `record_path(r["id"])` without `ID_RE` (pre-existing; needs Bash write to the queue, SPEC §6) → follow-up. `preview`/`send` print U+2028 raw (outside REQ-7) → follow-up. `_url_pass` concat on `"//a "*12500`: 0.147 s.

### Round 1 (2026-11-03, PR #33, f60dd67, base f46f006)
- Deterministic gates (lead, from `git archive f60dd67`): `bash tests/sanitize_tests.sh` 105 ✔ ALL PASSED, 13 REQ-5 timings ≤ 0.018 s; full loop exit 0; CI `test` + `check` SUCCESS. F1–F4 fixed (qa and security agree).
- qa: ACCEPT_WITH_NOTES (P0 0, P1 0, P2 2). security: FIX (2 Medium, 1 Low). Lead reproduced every input below on f60dd67; a lead prototype of the fixes below passes all of them plus `sanitize`, `feedback` and `triage` tests, timings ≤ 0.017 s.
- **[Medium, fix] G1 `_` suffix and allowed-URL tail** (`scripts/feedback.py:72` `LAST_LABEL_RE`, `_url_allowed` path checks after the `"." in segs` line): a last label with `_` is not a host, so `_jenkins.acme-corp.internal_` stays; inside an allowed URL the tail check misses it (new in this card): `https://code.claude.com/docs/jenkins.acme-corp.internal_`, `https://github.com/tahircengiz/delixcrew/blob/main/jenkins.acme-corp.internal_` and `jenkins.acme-corp.internal_https://github.com/anthropics/x` come out unchanged. Fix, two parts: (a) `LAST_LABEL_RE = [^\W\d_][\w-]*` (still fullmatch only); (b) allowlist for the tail (K146 is allowlist-first): split the tail on `[/?#=&+]`; every part that holds `.` must have each label after the first in `FILE_EXTS` or all digits, else not allowed (keep the existing `TOKEN_RE`/IPv4/MAC/term checks). Tests: first input → `<redacted:host>`; the two URLs → `https://<redacted:url>`; the fourth loses `jenkins`/`acme`; unchanged: `https://github.com/tahircengiz/delixcrew/releases/tag/v0.6.1`, `https://code.claude.com/docs/a.tar.gz`, `https://github.com/anthropics/claude-code/blob/main/README.md`, `https://code.claude.com/docs/x_y`.
- **[Medium, fix] G2 host after `@`** (`:67` `EMAIL_RE`, `:71` `TOKEN_RE`): `EMAIL_RE` is ASCII and `TOKEN_RE`'s lookbehinds exclude `@`, so `admin@bücher.example-corp.de`, `@jenkins.acme-corp.internal`, `@.jenkins.acme-corp.internal` come out unchanged and `jürgen.schmidt@acme-corp.de` → `jü<redacted:email>` (also on main; REQ-3 class). Fix: `EMAIL_RE = (?<![\w.%+-])[\w.%+-]+@[\w-]+(?:\.[\w-]+)+` (one start per run, as F4); drop `@` from both `TOKEN_RE` lookbehinds: `(?<![\w-])(?<![\w-]\.)`. Tests: the two addresses → exactly `<redacted:email>`; the other two lose `jenkins`/`acme`; REQ-5 timing cases `"ab@"*16000` and `"_."*25000`.
- [Low, no fix] Combining marks split a token (`intranet.corp.भारत` unchanged): Python `\w` has no Mn/Mc. Lead adds it to SPEC §6 at close.
- [P2, no fix, notes] `.env.local` → `.<redacted:host>` (F3 side effect, fail closed). `intranet.firma.pl` stays because `pl` is in `FILE_EXTS` (by design). `os.path` → `<redacted:host>` (pre-existing over-redaction). Earlier P2 follow-ups unchanged.

### Round 2 (2026-11-03, PR #33, 842707d, base f46f006)
- Deterministic gates (lead, from `git archive 842707d`): `bash tests/sanitize_tests.sh` 119 ✔ ALL PASSED, 15 REQ-5 timings ≤ 0.018 s; full loop exit 0; CI `test` + `check` SUCCESS (PR run used the branch's old `tests.yml`, so `sanitize_tests.sh` ran only in the lead run). G1 and G2 fixed (qa and security agree).
- qa: ACCEPT_WITH_NOTES (P0 0, P1 0). security: FIX (1 Medium, 1 Low). Lead reproduced both on 842707d and on main (pre-existing); a lead prototype of the fixes below passes them and every `tests/*_tests.sh`, timings ≤ 0.024 s.
- **[Medium, fix] H1 trailing non-letter label** (`scripts/feedback.py:187-189` `_looks_like_host`): `_The build runs on jenkins.acme-corp.internal._` (Markdown italics) and `on jenkins.acme-corp.internal.__` come out unchanged: the token's last label is `_`/`__`, so it is not a host. Fix (no regex, linear): `labels = [lab.strip("_-") for lab in tok.split(".")]`; `while len(labels) > 1 and not labels[-1]: labels.pop()`; `last = labels[-1]`; return `len(labels) >= 2 and len(last) >= 2 and LAST_LABEL_RE.fullmatch(last) and last.lower() not in FILE_EXTS`. Tests: both inputs lose `jenkins`/`acme`; `jenkins.acme-corp._internal` → `<redacted:host>`; unchanged: `notlar.md._`, `v0.6.1`, `__init__.py`, `x._`; REQ-5 timing `"a" + "._" * 25000`.
- **[Low, fix] H2 IPv4 glued to `_` or `.`** (`:69` `IPV4_RE`, `_url_allowed` tail): `https://code.claude.com/docs/_10.20.30.40`, `https://code.claude.com/docs/x.10.20.30.40` stay (K146 "no IP in the tail"); `_10.20.30.40` stays in plain text. Fix: in `_url_allowed`, before the github.com rule, `if re.search(r"(?<!\d)\d{1,3}(?:\.\d{1,3}){3}(?!\d)", tail): return False`; `IPV4_RE` lookbehind `(?<![\w.])` → `(?<![^\W_])(?<!\.)`. Tests: both URLs → `https://<redacted:url>`; `_10.20.30.40` → `_<redacted:ip>`; `v1.2.3.4` unchanged; REQ-5 timing `"_1.2.3.4" * 6000`.
- [Note, no fix] `self.term_re`, `module.some_function` → `<redacted:host>` (G1 side effect, fail closed, same as `os.path` on main). `jenkins.acme-corp.internal.1` and `jenkins:8080` without `/` stay (pre-existing, design call): lead adds to SPEC §6 at close with the combining marks. qa P2 notes: `_url_pass` concat O(n²) (follow-up), adjacent placeholders may change on a second pass (fail closed, follow-up).
- Round 3 is the last (`max_review_rounds` 3): a further Medium escalates to the user.

### Round 3 (2026-11-03, PR #33, 1d82c9d, base f46f006)
- Deterministic gates (lead, from `git archive 1d82c9d`): `bash tests/sanitize_tests.sh` 132 ✔ ALL PASSED, 17 REQ-5 timings ≤ 0.019 s; full loop exit 0; CI `test` + `check` SUCCESS. H1 and H2 fixed.
- qa: ACCEPT_WITH_NOTES (P0 0, P1 0, P2 1). security: 🔐 HUMAN_APPROVAL (no Critical/High/Medium; 3 Low). Lead reproduced every item below; all are pre-existing on main except the timing gap, all are plain-text heuristic limits (class b), none breaks a REQ.
- [P2/Low, follow-up] IP followed by `_`: `_10.20.30.40_`, `10.20.30.40_`, `_fd00:1:2::3_` unchanged (`IPV4_RE`/`IPV6_RE` lookahead treats `_` as `\w`).
- [Low, §6] host with a known extension as last label: `jenkins.acme-corp.internal.conf` unchanged (REQ-3 says so; denied inside a URL tail).
- [Low, follow-up] path after a host that starts after `:`: `key:jenkins.acme-corp.internal/api/acme-bank` → `key:<redacted:host>/api/acme-bank`.
- [Low, follow-up, test only] no ≈50 000-character timing case through the new tail IPv4 check; lead measured `"https://code.claude.com/docs/" + "1111." * 10000` at 0.007 s.
- [Note] `jenkins.acme-corp.internal.a_` unchanged (1-letter label, contrived); `http://[2001:db8::10.1.2.3]/` kept (documentation IPv6).
- Round cap reached; the lead does not open a round 4. Residuals go to one follow-up card and SPEC §6 at close.
