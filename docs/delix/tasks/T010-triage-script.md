# T010 — 🔐 triage.py: show, index, record, preview, apply

| id | size | tier | role | wave | status |
|---|---|---|---|---|---|
| T010 | L | 3 | backend | 1 | open |

**🔐 Approved:** 2026-11-03 tahircengiz

> 🔐 Tier 3: the path that writes comments, labels and closes on a public repo. The orchestrator adds the `**🔐 Approved:**` line after the human says "yes".

**Goal (1 sentence):** One stdlib script that reads issues cleanly, records a triage decision and applies it from the user's own terminal. · **Spec:** `docs/delix/SPEC.md#REQ-1`, `#REQ-2`, `#REQ-5`, `#REQ-6`, `#REQ-8` (script side), §4

## Files
- Create: `scripts/triage.py`
- Test: `tests/triage_tests.sh` (new)

## Interfaces
- Produced (exact; T012 and T013 are written against it). All commands exit 7 when `gh` fails.
  - `show <n> [--require accepted]` (0·7·8)
  - `index` (0·7)
  - `record <n>`: JSON on stdin, prints `#<n> recorded <decision>` (0·2·7)
  - `preview <n>`: prints `REPO:`, `ISSUE: #<n> <url>`, `ACTIONS: …`, `---`, the comment (marker line included), `---`, `VERDICT: CLEAN|BLOCKED: <r>[; …]`, `HASH: <12hex>`. Exit 0·2 (no record)·4·7.
  - `apply <n> --confirm <hash>` (0·4·5·6·7)
- `ACTIONS` format: `ACTIONS: ensure-label <L>; comment; add-label <L>; remove-labels <the other 4, comma-joined>; close <not-planned|no>`. Label order is fixed: `accepted,needs-info,duplicate,wontfix,deferred`.
- Consumed: `import feedback`, with `sys.path.insert(0, <script dir>)`.
  - Functions: `sanitize`, `term_regex`, `local_terms`, `load_config`, `gitleaks`, `bad_char`, `repo_ok`, `gh`; may also use `write_json`, `read_json`, `now`, `err`.
  - Constants: `OPAQUE_RE`, `GH_SCRUB`, `REPO`, `SANITIZER_VERSION`.
  - `feedback.gh(args, env)` puts `-R` after the 2nd argument (`scripts/feedback.py:568-580`). Never use `gh api`.

## Global Constraints (from the spec)
- REQ-1 to REQ-6 and REQ-8, word for word, including every exit code and every message in the spec.
- Cleaning order: (1) remove Cc (except `\n` and `\t`), Cf and Co; (2) then HTML comments (`<!--.*?(?:-->|\Z)`, DOTALL); (3) count both over every printed string (title, body, comments, labels, logins).
- `issue-sha` = `sha256(clean_title + "\n" + clean_body)`, first 12 hex.
- `reported-version` = the first `plugin <tok>` in the body; `unknown` unless `tok` fullmatches `\d+\.\d+\.\d+`.
- `source` (K126, measured with gh 2.86.0: `gh issue view|list --json` has no issue-level `authorAssociation`): issue author is `maintainer` iff `author.login` equals the owner part of `feedback.REPO`; otherwise `external`. Comments: use each comment's `authorAssociation` (present in `--json comments`); maintainer = OWNER, MEMBER or COLLABORATOR. Never request `authorAssociation` as a top-level `--json` field.
- `decision`: the issue's decision label(s), joined with `,` and no spaces; `none` if there is none.
- Valid triage comment: author association maintainer; last line fullmatches `delixcrew-triage: (accept|needs-info|duplicate|wontfix|defer) [0-9a-f]{12} [0-9a-f]{12}`; the **last** such comment counts; every comment after it gets the header suffix `(after triage, not reviewed)`.
- `index` line: `#<n> <open|closed> <decision|none> <maintainer|external> <json.dumps(clean_title, ensure_ascii=False)>`, read with `gh issue list --state all --limit 300 --json number,state,labels,author,title`.
- Hash: `sha256(json.dumps({repo, issue, issue_sha, decision, comment, sanitizer_version}, sort_keys=True, ensure_ascii=False, separators=(",",":")))`, first 12 hex; `comment` is the sanitized text **without** the marker line; published text = `comment + "\n\n" + marker`.
- BLOCKED checks for HTML (`<[A-Za-z/!]`), `<!--` and `@login` (`(?<![\w.])@[A-Za-z0-9]`) run on the **raw** `reason` and `questions` (sanitize adds `<redacted:…>` placeholders). Residual check: `sanitize(x) != x`, as `scripts/feedback.py:342`.
- Fixed labels (`label create <L> --color <hex> --description <d>`): `accepted` `0e8a16` `Triaged: accepted` · `needs-info` `fbca04` `Triaged: more information needed` · `deferred` `c5def5` `Triaged: deferred` · `duplicate` `cfd3d7` `This issue or pull request already exists` · `wontfix` `ffffff` `This will not be worked on`.
- Records: `$DELIXCREW_TRIAGE_DIR` (default `~/.claude/delixcrew/triage`), dir mode 0700, written with `feedback.write_json` (atomic); on read-back in `preview`/`apply` every unknown key or bad type is `invalid record`.
- `apply`: checks in REQ-6 order; after `APPLY <hash>` read the issue once (`gh issue view <n> --json state,labels,comments`) and run steps 1–4 from that read; on failure one stderr line `delixcrew triage: step <k> (<name>) failed: <err>`, exit 7.

## Steps
1. Write `tests/triage_tests.sh` in the style of `tests/feedback_tests.sh` (✔/✘ lines, `ALL PASSED` at the end).
   - Export `DELIXCREW_TRIAGE_DIR`, `HOME`, `USER`, fake `GH_HOST` and `GH_REPO`. Copy `tty_run` (`tests/feedback_tests.sh:17-19`) and the `gitleaks` stub (`:22-29`).
   - `gh` stub: a **stateful Python script** reading/writing `$TRT/state.json` (issues with title, body, state, url, author, labels, comments with `authorAssociation`; plus repo labels); handles `issue view|list|comment|edit|close` and `label list|create`; rejects a top-level `authorAssociation` field with `Unknown JSON field` like real gh; logs `ARGS:` and `GH_`/`GITHUB_` env lines to `gh.log`; new comments get `${GH_ASSOC:-OWNER}`; `GH_FAIL=close` makes `issue close` fail.
   - One test per spec scenario in REQ-1, 2, 5, 6 and 8, plus each REQ-5 schema error (exit 2, no file), plus: HTML, `<!--`, `@alice`, `FAKE_SECRET_MARKER` and a runtime-built 32+ opaque string each BLOCKED; `HASH` unchanged after labels change (K121); non-TTY run leaves no write call in `gh.log`; plugin.json mismatch on a copied tree; `--require accepted` pass prints the body, fail leaves stdout empty; issue author `someone-else` → `source: external`.
   - Run it, see **red**.
2. Implement `scripts/triage.py`.
3. Green: `bash tests/triage_tests.sh`, then the full loop.
4. Commit `T010: triage.py show/index/record/preview/apply`; PR body has "## How I tested".

## Verification command → expected output
- `bash tests/triage_tests.sh` → `ALL PASSED`
- `for t in tests/*_tests.sh; do bash "$t" || exit 1; done` → every script `ALL PASSED`
- `git diff --stat origin/main -- scripts/feedback.py` → empty

## Review Focus
- After the hash check `apply` re-reads nothing from disk; a re-run makes no second comment and no second edit (REQ-6 scenario).
- A marker comment from a `NONE` account counts neither for the comment step nor for `--require accepted`.
- No top-level `authorAssociation` in any `gh` call (K126).

## Don'ts
- Untouchable: `scripts/feedback.py` (K115), hook scripts, `.github/**`, `.claude-plugin/**`, `docs/delix/**`, existing tests.
- No real network, no real `gh`, no new dependency, no realistic key literals. Import from `feedback.py`, never copy. Test looks wrong: NEEDS_CONTEXT.

## Report contract
`.delix/report.md` (≤ 2K tokens): status · command + output · PR number · assumptions · remaining work. Read only this card and SPEC REQ-1, 2, 5, 6, 8, §4, §6.

## Review findings
### Round 1 (c0fd189) — qa REJECT (1 P1) · security FIX with 1 Medium → fixing
Deterministic gates: CI `test` pass; from `git archive c0fd189`: 5× `ALL PASSED` (triage included); validate passed;
diff touches only `scripts/triage.py` and `tests/triage_tests.sh` (new files, 0 deletions); `feedback.py` unchanged.
To fix (round 1):
- [P1 / Medium] `scripts/triage.py:308-312`: the HTML, `<!--` and `@mention` BLOCKED checks run on the raw
  `reason`/`questions`, but the published comment is `sanitize(raw)`, which starts with NFKC (`feedback.py:250`).
  Fullwidth and small-form characters pass the raw check and become ASCII in the comment: `＠` U+FF20 and `﹫` U+FE6B
  become `@`, `＜` U+FF1C becomes `<`. A reason `Ask ＠alice` gives preview `VERDICT: CLEAN` and publishes `@alice`
  (a ping from the maintainer account); `＜!-- x` publishes a hidden HTML comment. `bad_char`, the residual check
  (NFKC is idempotent), `OPAQUE_RE` and gitleaks do not catch it. Fix: run the three checks on both `x` and
  `unicodedata.normalize("NFKC", x)` for every `x` in `user` (no placeholders are added, so K122 holds). Tests
  (append to `blocked`): `Ask ＠alice` (mention), `＜b＞x` (HTML), `＜!-- x` (HTML), each BLOCKED.
- [Low, fix too: secret hygiene, K130] `tests/triage_tests.sh:43`: the `gh` stub logs every `GH_*`/`GITHUB_*`
  variable as `name=value` to `gh.log`, and failing tests print `gh.log` (lines 149, 175). An exported real token
  variable would land in terminal or CI output. Fix: log names only; the assertions at 180 and 321 need names only.
Noted, no fix:
- [P2] `scripts/triage.py:221-226`: `validate` rejects `duplicate_of` outside `duplicate` and `questions` outside
  `needs-info`; stricter than the REQ-5 schema list. Fails closed; spec note at close.
- [Low] `scripts/triage.py:263`: `makedirs(mode=0o700, exist_ok=True)` does not re-chmod an existing dir; files are 0600.
- `apply` without a record exits 2 (shared `prepare()`), outside the card's apply set 0·4·5·6·7; tested, accepted.
- Unsure (security): U+2028/U+2029 in `index` titles not escaped; a fake `--- comment by … | OWNER` line inside a body
  in `show` output (shown in an UNTRUSTED block; `--require accepted` reads raw gh data).

### Round 2 (06b0e52) — qa REJECT (1 P1) · security FIX with 1 Medium → fixing
Deterministic gates: CI `test` pass; from `git archive 06b0e52`: 5× `ALL PASSED`; validate passed; `feedback.py`
unchanged. Round 1 fixed: HTML and mention checks run on the raw and the NFKC text (4 tests); the stub logs names only.
To fix (round 2):
- [P1 / Medium] `scripts/triage.py:310-314`: the mention check still has a bypass of the same class. `sanitize` can put
  a placeholder ending in `>` right before `@`, and `MENTION_RE`'s lookbehind `(?<![\w.])` hides the `@` only in the
  raw text. Reproduced by the orchestrator against the archive tree: `sanitize("Ask acme@carol", term_regex(["acme"]))`
  gives `Ask <redacted:term>@carol`; `sanitize("Ask acme.io@alice", term_regex([]))` gives `Ask <redacted:host>@alice`;
  `MENTION_RE` matches both outputs and neither input. The local USER or hostname term works the same way. Preview says
  `VERDICT: CLEAN` and apply publishes the mention. Fix: also run `MENTION_RE` on the sanitized `comment` (no
  placeholder, `**Triage: …**`, `Questions:` or `Duplicate of #N` contains `@`, so K122 holds). Keep the HTML check on
  raw + NFKC only (placeholders start with `<r`). Tests (append in `blocked`, reason `mention`): `Ask acme@carol` with
  extra term `acme`; `Ask acme.io@alice`; a USER-term case with a test USER of ≥ 3 characters. Check that
  `bob@example.com` still gives CLEAN.
Noted, no fix (carried over): makedirs re-chmod (Low); `apply` without record exits 2; `validate` stricter (P2).
Unsure (security, not checked): `gh issue view --json comments` may cap at 100 comments, so on a long thread the
re-run check and `--require accepted` could miss the newest marker; cross-repo references and GitHub URLs in `reason`
create backlinks from the maintainer account (visible in preview).

### Round 3 (8a2dd43) — qa ACCEPT_WITH_NOTES · security FIX with 1 Medium → escalated (round cap)
Deterministic gates: CI `test` pass; from `git archive 8a2dd43`: 5× `ALL PASSED`; validate passed; also 5×
`ALL PASSED` with `triage.py` + its tests laid over current main (T011 merged). Round 2 fixed: `MENTION_RE` also runs
on the sanitized comment; tests for term, host and USER placeholders; `bob@example.com` stays CLEAN.
Open (third form of the same class):
- [Medium] `scripts/triage.py:49`, `:314`: the lookbehind `(?<![\w.])` lets an `@` after `.` or after a non-ASCII
  letter through (Python `\w` is Unicode). Reproduced by the orchestrator: `Ask .@alice`, `x.@alice`, `Café@alice`,
  `中@alice` pass raw, NFKC and comment checks unchanged, so preview says CLEAN. GitHub's mention boundary is believed
  to be ASCII `\W` (html-pipeline), so these would likely ping; not verified live. `&#64;alice` (HTML character
  reference) also passes; GitHub rendering not verified.
- Class-wide fix proposal: on the sanitized comment, block any `@[A-Za-z0-9]` with no lookbehind (emails are already
  `<redacted:email>`, no placeholder contains `@`) and any HTML character reference `&#…;` / `&name;`. Tests: the four
  cases above and `&#64;alice` BLOCKED; `bob@example.com` CLEAN.
Noted, no fix: Markdown link reference definitions and link targets hide text (visible as raw Markdown in preview);
`gh issue view --json comments` paging unverified; carried-over Lows and P2 from rounds 1–2.
Decision (user, chat, 2026-11-03; K131): one last fix round with the class-wide rule above → fixing (round 4).

### Round 4 (cb42b72) — qa ACCEPT_WITH_NOTES · security FIX with 1 Medium (new class) → escalated
Deterministic gates: CI `test` pass; from `git archive cb42b72`: 5× `ALL PASSED`; validate passed; 5× `ALL PASSED`
laid over current main. K131 fixed: `@[A-Za-z0-9]` and HTML character references are BLOCKED on the sanitized
comment (6 tests; `bob@example.com` CLEAN). Mention/HTML class closed (qa and security agree).
Open (new class, outside K131):
- [Medium] `scripts/triage.py:304-305` (`bad_char` = Cc/Cf/Co only, `feedback.py:291-293`): invisible code points
  outside those categories survive NFKC and `sanitize` and are published, unseen in preview and at the `APPLY` prompt.
  Reproduced by the orchestrator: variation selectors U+FE00–FE0F and U+E0100–E01EF (Mn), U+3164 Hangul filler (Lo),
  U+2028 (Zl), U+2800 blank Braille (So) all pass. Runs of variation selectors can encode arbitrary bytes ("emoji
  smuggling"); this breaks the SPEC §6 premise that the user sees the comment exactly. Proposed fix: BLOCKED
  `invisible character` for U+034F, U+115F, U+1160, U+180B–180D, U+180F, U+2028, U+2029, U+2800, U+3164, U+FFA0,
  U+FE00–FE0F, U+E0100–E01EF in `raw + comment`; optionally allow a single U+FE0E/U+FE0F after a non-selector (emoji).
Unsure (security, not verified): Markdown links to `github.com` survive host redaction (visible in preview); IDN,
U+3002-dot and decimal-IP hosts may escape `feedback.py` host redaction (K115 scope).
