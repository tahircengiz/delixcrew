# T022 — SECURITY.md and README "What this plugin does on your machine" (EN/TR)

| id | size | tier | role | wave | status |
|---|---|---|---|---|---|
| T022 | S | 2 | docs | 3 | open |

**Goal (1 sentence):** Publish a security policy and one README section (EN and TR) that says what the hooks and scripts
do on the user's machine, with every claim taken from code. · **Spec:** issue
<https://github.com/tahircengiz/delixcrew/issues/10> (accepted in triage; no SPEC REQ; size S, so gate 1 is this card)

## Files (base 1b3cf9e; disjoint ownership)
- Create: `SECURITY.md` (repo root, English)
- Modify: `README.md`
  - A: insert the new `## What this plugin does on your machine` section after line 94
    (`` `.delix/test-result.txt`, `.delix/evidence/`. ``) and before line 96 `## Feedback`.
  - B: insert one line after line 290 (`MIT, see [LICENSE](LICENSE). Source and issues: …`).
- Modify: `README.tr.md`
  - A: same place, after line 94 (`` `.delix/test-result.txt`, `.delix/evidence/`. ``) and before line 96
    `## Geri bildirim`; heading `## Bu plugin makinende ne yapar`.
  - B: insert one line after line 288 (`MIT, bkz. [LICENSE](LICENSE). …`).
- Test: none (docs only; existing tests must stay green)

## Interfaces
- Produced anchors: `README.md#what-this-plugin-does-on-your-machine`, `README.tr.md#bu-plugin-makinende-ne-yapar`.
- Consumed anchors (link to them, do not repeat their content): `#data--privacy` (README.md:186),
  `#veri-ve-gizlilik` (README.tr.md), `#triage`, `#known-limits` / `#bilinen-sınırlar`.

## Global Constraints
- Every sentence is backed by an F-line in the Fact inventory below. A fact marked UNCONFIRMED is left out or worded as
  stated there.
- EN and TR carry the same content, bullet for bullet, in the same commit. Technical terms stay in English.
- Example hosts and IPs use only `acme-corp`, `10.1.2.3` or `<ssh-host>`.
- SECURITY.md contains: the reporting channel (GitHub private vulnerability reporting: Security tab, then "Report a
  vulnerability"; enabled, checked 2026-11-04 with `gh api …/private-vulnerability-reporting` → `{"enabled":true}`);
  supported version 0.6.x; best effort from a single maintainer, with no response time; fixes ship as a `plugin.json`
  version bump and are announced in CHANGELOG and a GitHub Security Advisory; a trust model in 3 bullets or fewer
  (T1, T2); a link to the README section instead of repeating it.
- License line, only because it is missing today: "Not affiliated with or endorsed by Anthropic. MIT, provided as is,
  without warranty (see LICENSE)." (TR equivalent in README.tr.md.)
- Network list has two parts (lead correction of the request, K-T022-1): commands the scripts run, and commands the
  skills tell Claude to run (N3, N6). No "never goes online" wording; the Stop gate runs commands the project defines.

## Steps
1. Baseline: run the verification command and see it **green** before you edit anything (docs card, no red test).
2. Write the 3 files, only at the anchors above.
3. In `.delix/report.md`, add a claim table: each sentence of the new text, then its F-id and `file:line`.
4. Run the command again and see it **green**; `claude plugin validate .` passes.
5. Commit `T022: SECURITY.md, README "What this plugin does on your machine" (#10)`; open a PR with a `## How I tested`
   section.

## Verification command → expected output
`for t in tests/*_tests.sh; do bash "$t" || exit 1; done` → every suite passes, exit 0

## Review Focus
- Claim vs code: hook matchers, what each gate blocks, the network list, the file paths.
- The EN and TR sections match. The Data & privacy content is linked, not copied.
- No promise of a response time in SECURITY.md.

## Don'ts
- Do not touch: `scripts/**`, `hooks/**`, `.github/**`, `.claude-plugin/**`, `docs/delix/**`, `tests/**`, `site/**`,
  `CHANGELOG.md` (it has no `## Unreleased` section; CHANGELOG.md:5 is `## 0.6.2`). No version bump.
- Do not describe the delix-board plugin. One pointer is allowed: it is a separate plugin with its own
  `plugins/delix-board/hooks/hooks.json`.
- If a fact is unclear, write `NEEDS_CONTEXT` instead of guessing.

## Report contract
`.delix/report.md`: `DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED`, plus the claim table, the command output and
the PR number.

## Fact inventory (architect, base 1b3cf9e)

**Hooks**
- H1: Matchers: `Write|Edit|MultiEdit|NotebookEdit` → write_gate (hooks.json:5-7); `Bash` → bash_gate (:11-13); `Stop`
  → stop_gate (:17-20). Both PreToolUse hooks start with `command -v python3 … exit 2` plus `onFailure: block`, so
  without python3 every Write/Edit/MultiEdit/NotebookEdit/Bash call is blocked (:7, :13; README.md:20-21). The Stop
  hook has no such guard (:20); what Stop does without python3 is UNCONFIRMED.
- H2: Active in every session: Write/Edit into the feedback and triage directories is denied (write_gate.py:21-32);
  `feedback.py send`, `triage.py apply`, the `script`/`expect`/`unbuffer`/`pty.spawn` wrappers and writing
  `gh issue`/`gh label`/`gh api` calls aimed at delixcrew are denied (bash_gate.py:17-69).
- H3: Reviewer agents (common.py:8-9): writes denied (write_gate.py:35-36); Bash denied, except the security role, which
  may run scanners and git reads only (bash_gate.py:75-83).
- H4: Implementer gates turn on only when `.delix/card` exists at the work-tree root, is not a symlink, and git tracks
  nothing under `.delix`; a card that arrives with a clone does not activate them (common.py:27-53). They deny: writes
  outside cwd (write_gate.py:78); the card file and `docs/delix/**` (:82); a protected path unless it is in the card's
  Files list and the card has an Approved line (:89-97); an existing test file (:99-105); shell `>`, `cp`, `mv` or `tee`
  into a protected path (bash_gate.py:92-96); `git commit` when `gitleaks protect --staged` finds a secret or fails
  (bash_gate.py:98-107).
- H5: Stop, implementer only: skipped when `stop_hook_active` is set, or when report.md contains NEEDS_CONTEXT or
  BLOCKED. Otherwise it runs `delix.json` `test_command` (default `pytest -q`) and `extra_checks` with `shell=True`, a
  540 s timeout per command and a 600 s hook timeout; exit 2 keeps the turn open (stop_gate.py:13-48; hooks.json:20).

**Network**
- N1: Hooks make no network call of their own. Their subprocesses are git (common.py:38; bash_gate.py:37, :65
  `git remote -v`) and gitleaks (bash_gate.py:101). The Stop commands are whatever `delix.json` defines
  (stop_gate.py:25-31).
- N2: `feedback.py send` runs `gh issue list` and then `gh issue create` (feedback.py:800, :818). The repo is fixed with
  `-R github.com/tahircengiz/delixcrew` (:35, :750); GH_HOST, GH_REPO and the enterprise tokens are removed from the
  environment (:38, :797). It needs a TTY and the typed `SEND <hash>` (:787-796).
- N3: `triage.py show`, `index`, `record` and `preview` only read through `gh issue view/list` (triage.py:123, :175,
  :253, :339). Claude runs these in `/delixcrew:triage` (skills/triage/SKILL.md:27, :34) and in `/delixcrew:start #n`
  (skills/start/SKILL.md:25-31). `apply` runs gh label list/create and issue comment/edit/close (triage.py:402-431),
  only from a TTY after `APPLY <hash>` (:378-389).
- N4: `feedback.py add` runs `git remote -v` (feedback.py:585) and `claude --version` (:606, :646) to fill the draft.
  Whether `claude --version` makes a network call: UNCONFIRMED.
- N5: gitleaks runs on the draft or comment text in preview, send and triage preview/apply (feedback.py:400-415, :500;
  triage.py:302), and in verify (skills/verify/SKILL.md:33-34).
- N6: Commands the skills tell Claude to run through Bash: `gh pr create` (implement/SKILL.md:49), `gh pr checks`
  (review/SKILL.md:14), `gh repo view` (triage/SKILL.md:18; start/SKILL.md:22); `ssh` and `rsync` to `delix.json`
  `verify.remote`, only when that block exists (verify/SKILL.md:38-41; review/SKILL.md:23; templates/delix.json:15-18);
  `claude -p` implementer sessions (dispatch/SKILL.md:43, :48). `gh pr merge` is never run by Claude
  (review/SKILL.md:63-64; verify/SKILL.md:119).
- N7: The scripts have no other network code. `socket` is used only for `gethostname()`, to redact the host name
  (feedback.py:330); `urlsplit` is parsing only (:31).

**Files written**
- W1: `.delix/test-result.txt` (stop_gate.py:26-33).
- W2: `.delix/warnings.log`, when gitleaks is missing (bash_gate.py:108-112).
- W3: `docs/delix/BOARD.md`, only with `--write` (board.py:11, :288-290), git-ignored (start/SKILL.md:18).
- W4: Feedback queue `~/.claude/delixcrew/feedback/`: `config.json` and `F<nnn>.json`, directory 0700, files 0600
  (feedback.py:14, :104, :119-136, :649, :667).
- W5: Triage records `~/.claude/delixcrew/triage/<n>.json` (triage.py:12, :58-62, :266-267, :436).
- W6: The issue body goes to a temp file in the system temp directory, deleted after the gh call (feedback.py:814-820;
  triage.py:415-421).
- W7: The lead skills write `docs/delix/STATE.json` (templates/STATE.json:2; start/SKILL.md:17; dispatch/SKILL.md:16,
  :57; review/SKILL.md:46, :64; verify/SKILL.md:110); `cost_usd` fields at templates/STATE.json:10, :18, filled by
  close/SKILL.md:14 and verify/SKILL.md:115-116. Verify also writes `docs/delix/verifications/*.md|.patch`
  (verify/SKILL.md:22) and a workspace at `${TMPDIR:-/tmp}/delix-verify-<name>/` (:20). "STATE.json is committed" is
  UNCONFIRMED as a rule; wording: "lives in your repo; not git-ignored".
- W8: Implementer: `.delix/report.md` and `.delix/evidence/` (implement/SKILL.md:36-37, :53).

**SECURITY.md**
- T1: A card that comes with a clone does not activate the hooks (common.py:28-51).
- T2: In implementer mode, Stop runs the repo's `docs/delix/delix.json` commands (H5).
- T3: An installed plugin updates only when its version changes (README.md:42-46).
- T4: Current version 0.6.2 (.claude-plugin/plugin.json:4). LICENSE says "AS IS" (LICENSE:15). README has no
  "Anthropic" disclaimer and no warranty line (README.md:288-290; README.tr.md:286-288).
- T5: Private reporting URL already linked (README.md:203-205); setting enabled (checked by the lead, see Global
  Constraints).

**Site:** no change (K-T022-2): no command, hook rule, role, gate or project-side file is added, removed or renamed;
SECURITY.md is a repo file, not a `docs/delix` project file.

## Review findings (filled by the lead)
- Round 1: …
