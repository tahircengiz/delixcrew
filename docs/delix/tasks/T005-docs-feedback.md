# T005 — README Feedback section (EN + TR) and CHANGELOG 0.5.0

| id | size | tier | role | wave | status |
|---|---|---|---|---|---|
| T005 | S | 1 | docs | 2 | open |

**Goal (1 sentence):** Document opt-in, review/send flow, requirements and remaining risk. · **Spec:** `docs/delix/SPEC.md` §4 (issue body row), §6, §7, K78; issue #7

## Files (disjoint ownership; do not touch files owned by another card)
- Modify: `README.md` (new `## Feedback` before `## Known limits`; update the paragraph about what `bash_gate.py` intercepts)
- Modify: `README.tr.md` (same, `## Geri bildirim` before `## Bilinen sınırlar`)
- Modify: `CHANGELOG.md` (insert `## 0.5.0 — <date>` above the 0.4.0 section)
- Modify: `templates/spec-M.md` (line 29) and `templates/spec-L.md` (line 11): ``link to `DESIGN.md` `` → ``link to `DESIGN.md` (or the repo's token file)`` (T006 leftover, verification r2 qa P2)

## Interfaces
- Consumed: T001 CLI (SPEC §4), T002 deny message, T003 `/delixcrew:feedback [note | review]`.

## Global Constraints (verbatim from the spec)
- Content of the Feedback section:
  - off by default (`feedback.py enable [--terms a,b]`); queue `~/.claude/delixcrew/feedback/`
  - review in chat, `yes F<nnn>`, then the user runs `send` in their own terminal and types `SEND <hash>`
  - `gitleaks` and a logged-in `gh` are required for sending
  - what is redacted and what is blocked
  - remaining risk (K77)
  - the suggestion `permissions.deny`: `Bash(gh issue create:*)`, `Bash(gh api:*)`. The README only suggests this; the plugin does not change settings (K78).
- README.md and README.tr.md change in the **same commit**. English in README.md, Turkish in README.tr.md; technical terms stay English.

## Steps
1. Check: `grep -c '^## Feedback' README.md` → `0` (red).
2. Write both READMEs and the CHANGELOG entry (feedback queue, hook rules, issue forms, `start #<n>`).
   Data & privacy (issue #7, P0, release blocker for 0.5.0; added by the user's decision K92): inside the Feedback section of both READMEs, a short `### Data & privacy` / `### Veri ve gizlilik` subsection:
   - the exact list of what is sent (SPEC §4 "gövde" row: Component, Version = plugin + Claude Code + OS name, What happened, Expected, Steps to reproduce, Context, last line `delixcrew-fp: <fp>`; label `bug`/`enhancement`) and what is **not** sent (`origin_terms`, local paths, home dir, emails, hosts outside the allowlist are redacted; secrets block the send);
   - the issue is **public** on `tahircengiz/delixcrew` and is opened with the user's own GitHub account; the basis is the user's explicit action (off by default, `SEND <hash>` typed by the user);
   - where the local queue lives (`~/.claude/delixcrew/feedback/`, or `DELIXCREW_FEEDBACK_DIR`) and how to delete it (`feedback.py drop <id>` marks a draft; delete the directory to remove everything);
   - deletion of a sent issue: the author can edit it but cannot delete it; ask for deletion through GitHub private reporting (`https://github.com/tahircengiz/delixcrew/security/advisories/new`).
   CHANGELOG 0.5.0 also lists the T007 security fix (PR #16, `b22f45a`, issue #8): hooks trust only the local, git-untracked `.delix/card`; remaining archive risk tracked in issue #17.
   Also (T006 leftover, PR #15 `f84e675`): in both READMEs, one short note where the spec step is described that `/delixcrew:spec` adds a conditional design-system step for UI work (link to `DESIGN.md` or the repo's token file); add the same item to the 0.5.0 CHANGELOG entry. Then the two template lines above.
3. Green, then commit `T005: README feedback section, CHANGELOG 0.5.0`.

## Verification command → expected output
`grep -c '^## Feedback' README.md; grep -c '^## Geri bildirim' README.tr.md; grep -c '^## 0.5.0' CHANGELOG.md` → `1` `1` `1`
`grep -c '^### Data & privacy' README.md; grep -c '^### Veri ve gizlilik' README.tr.md` → `1` `1`; `grep -c 'security/advisories/new' README.md README.tr.md` → `1` each; `grep -c '#16\|T007\|\.delix/card' CHANGELOG.md` → ≥ `1`
`grep -c "or the repo's token file" templates/spec-M.md templates/spec-L.md` → `1` each; `grep -c 'DESIGN.md' README.md README.tr.md CHANGELOG.md` → ≥ `1` each

## Review Focus
- No claim of full blocking; no internal addresses; the examples use `example-corp.dev` / `10.x`.

## Don'ts
- Untouchable: `.claude-plugin/**` (version is T004; no other version bump), `skills/**`, `scripts/**`, `docs/delix/**`.

## Report contract
`.delix/report.md` (≤ 1K tokens): status · grep output · PR number.

## Review findings (filled by the orchestrator)
- Round 1 (deterministic gate, 2026-11-03, c6302b4): original verification greps all green, CI pass, 4 test suites pass. Scope gap (orchestrator's, not the implementer's): the K92 additions (Data & privacy subsection, T007 CHANGELOG item) were committed on main as c332201 but not pushed before the session started; `grep -c '^### Data & privacy' README.md` → 0, `security/advisories/new` → 0, `#16|T007|.delix/card` in CHANGELOG → 0. Sent to the implementer with the full Step 2 text.
- Round 2 (2026-11-03, re-review of 62979ef; qa REJECT, 1 P1, orchestrator verified the lines). Fix:
  - [P1, qa] unqualified "full blocking" claims, against the Review Focus and SPEC §6 K77: `README.md:99` "Nothing leaves your machine unless you send it yourself, from your own terminal."; `README.md:126` "Claude never sends:"; `README.md:167` "nothing is sent until you type `SEND <hash>`"; `CHANGELOG.md:7` "sent only by you"; same sentences in `README.tr.md` (e.g. `:167` "yazana kadar hiçbir şey gönderilmez"). Rephrase as "delixcrew never sends on its own; the hooks block the known ways for Claude to send (see Remaining risk)" and "delixcrew sends nothing until you type `SEND <hash>` in your own terminal; the hooks close the known paths for Claude only, see Remaining risk".
  - [P1, qa P2 raised by orchestrator: issue #7 asks where local data lives] Local queue bullet: queue files keep the raw, unredacted draft text and the project terms (`origin_terms`); redaction is applied at preview and send (`feedback.py:443-445`, `build()`). Add that, and that redaction is pattern-based, so read the preview.
- Round 2 re-review (2026-11-03, 7448e8c): qa ACCEPT_WITH_NOTES (0 P0/P1); all round-2 P1s and the optional P2s fixed. Orchestrator (git archive 7448e8c): 10 card greps expected, validate passed, board/feedback/hook/trust ALL PASSED, CI pass, gitleaks and internal-address scan clean; every commit changes README.md and README.tr.md together; private vulnerability reporting `enabled: true`; no conflict with T004 (#18) in either order. Notes (P2, follow-up): "every other absolute path" → single-segment paths (`/srv`) are not redacted; `example.*` → only `example.com/.net/.org` + reserved TLDs (safe direction). Gate 2 → user; merge before T004.
- Round 2 notes (P2, no fix required): "What blocks a draft" omits `fingerprint mismatch` and `unreadable queue record`; CHANGELOG says "private IPs" but every IP except loopback/documentation ranges is redacted; `example.*` allowlist is only `.com/.net/.org` + reserved TLDs; single-segment absolute paths (`/srv`) are not redacted.
