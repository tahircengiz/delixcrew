# T001 — 🔐 feedback.py: queue, sanitizer, send

| id | size | tier | role | wave | status |
|---|---|---|---|---|---|
| T001 | L | 3 | backend | 1 | open |

**🔐 Approved:** 2026-11-03 tahircengiz

> 🔐 Tier 3 (implements the send-to-GitHub path). The orchestrator adds the Approved line after the human's "yes".

**Goal (1 sentence):** Single stdlib script implementing the feedback CLI end to end. · **Spec:** `docs/delix/SPEC.md#REQ-1` … `#REQ-6`, `#REQ-8`, §4

## Files (disjoint ownership; do not touch files owned by another card)
- Create: `scripts/feedback.py`
- Test: `tests/feedback_tests.sh` (new)

## Interfaces
- Produced (exact; T003 and T005 are written against it):
  - `feedback.py enable [--terms a,b] | disable | status` → exit 0. `config.json` = `{"enabled": bool, "extra_terms": [str]}`. `status` prints state, queue dir and draft count.
  - `feedback.py add` (stdin JSON) → stdout `F<nnn> new` or `F<nnn> duplicate (count n, <status>)`; exit 0. Schema error → exit 2 (field + reason). Opt-in off → exit 3 with stderr exactly `delixcrew feedback is off; enable: python3 <abs path>/feedback.py enable`.
  - `feedback.py list` → table `id kind component count status title`.
  - `feedback.py preview <id>` → lines `VERDICT: CLEAN|BLOCKED: <reason>[; …]`, `HASH: <12hex>`, `REPO`, `LABEL`, `TITLE`, `---`, body. Exit 0 if CLEAN, 4 if BLOCKED.
  - `feedback.py send <id> --confirm <hash>` → exit 0/4/5/6/7, checked in this order:
    1. `plugin.json` repository ≠ `https://github.com/tahircengiz/delixcrew` → 7
    2. Build the content in memory; if BLOCKED → 4
    3. Hash ≠ `--confirm` → 5, message `content changed since preview; run preview again`
    4. stdin not a TTY → 6
    5. Print queue dir, repo, label, title, body; read one line; if it is not `SEND <hash>` → 6
    6. Remote duplicate found → exit 0, print the URL, `status: duplicate`
    7. `gh issue create` → `status: sent`, `issue_url`
    8. Any `gh` failure → 7, one line, record stays `draft`
  - `feedback.py drop <id>` → `status: dropped`; the file is kept.
  - Env `DELIXCREW_FEEDBACK_DIR` (default `~/.claude/delixcrew/feedback`).
- Consumed: `.claude-plugin/plugin.json` (`version`, `repository`), read relative to the script (`../.claude-plugin/plugin.json`).

## Global Constraints (verbatim from the spec)
- "Python 3 stdlib" single file (K71). Draft schema, record fields, issue-body headings, fingerprint and label mapping exactly as in SPEC §4.
- REQ-3 allowlist + REQ-4 fail-closed list, word for word, including the clarifications K81 (opaque class `[A-Za-z0-9+=_-]{32,}`, no `/` or `.`) and K82 (case-insensitive substring match, terms shorter than 3 chars ignored, allowlisted hosts never in `origin_terms`). Send `sanitizer_version` as a constant.
- "`send` … **aynı bellek içi içeriği** göndermeli (onaydan sonra taslak ya da config yeniden okunmaz)" (`send` sends the same in-memory content; it does not re-read the draft or config after confirmation).
- `gh` runs with `GH_HOST`, `GH_REPO`, `GH_ENTERPRISE_TOKEN`, `GITHUB_ENTERPRISE_TOKEN` removed and with `-R github.com/tahircengiz/delixcrew`. The last body line is `delixcrew-fp: <fp>`. The hash covers the body including that line.
- "fixture ve metinlerde iç adres deseni yok" (no internal-address patterns in fixtures or text). Use `10.x`, `172.16.x`, `example.*`, `example-corp.dev`.

## Steps
1. Write `tests/feedback_tests.sh` in the style of `tests/hook_tests.sh` (✔/✘ lines, `ALL PASSED`).
   - Set up: `mktemp -d`; `DELIXCREW_FEEDBACK_DIR=$T/q`; `HOME=$T/home`; `USER=alice-test`.
   - Put a stub dir first on PATH:
     - `gitleaks`: exit 2 and print `RuleID: generic-api-key` when stdin contains `FAKE_SECRET_MARKER`. Mode `GL_RC=1` → exit 1.
     - `gh`: append its args and `env | grep -E 'GH_|GITHUB_'` to `$T/gh.log`. Modes `GH_MODE=found|new|fail`; `issue create` prints `https://github.com/tahircengiz/delixcrew/issues/99`.
   - "gitleaks not found" case: PATH is a dir of symlinks to `python3`, `git`, `script` only.
   - One test per scenario of REQ-1, 2, 3, 4, 5, 6 and 8 (including the plugin.json mismatch, using a copied tree with a fake `plugin.json`), plus: a `~/.claude/plugins/cache/delixcrew/delixcrew/0.5.0/skills/x` path is not BLOCKED (K81); a 2-char extra term is ignored (K82).
   - TTY: macOS `script -q /dev/null <cmd>`; util-linux `script -qec "<cmd>" /dev/null` (detect with `script --version`). Input comes from `printf 'SEND <hash>\n' |`.
   - Run it and see **red**.
2. Implement `scripts/feedback.py`:
   - Write new records with `O_EXCL`.
   - `origin_terms` come from the cwd basename and the `git remote -v` host/owner/repo parts. Leave out `delixcrew`, `tahircengiz/delixcrew`, `delix` and allowlisted hosts.
   - Run gitleaks via `subprocess.run(..., timeout=30)` on both the raw and the sanitized text.
3. Green: `bash tests/feedback_tests.sh`, then the full test loop.
4. Commit `T001: feedback.py queue, sanitizer, send`. PR body has "## How I tested".

## Verification command → expected output
`bash tests/feedback_tests.sh` → last line `ALL PASSED`; `for t in tests/*_tests.sh; do bash "$t" || exit 1; done` → every script `ALL PASSED`

## Review Focus
- No secret value in any output path (preview, send, stderr). BLOCKED messages give the rule id only.
- `send` never reads the disk after the hash check. The duplicate record is unchanged (`dropped` stays dropped).
- Hostname vs file-name heuristic (REQ-3): `SKILL.md`, `feedback.py`, `plugin.json` are not hosts; `build.example-corp.dev` is.

## Don'ts
- Untouchable: `scripts/bash_gate.py`, `scripts/write_gate.py`, `.github/**`, `.claude-plugin/**`, `docs/delix/**`, existing tests.
- No realistic key literals in fixtures (the commit gate's gitleaks would block them). Use `FAKE_SECRET_MARKER` and build 32+ char strings at runtime.
- No real network, no real `gh`; no new dependency.
- If a test looks wrong, do not change it: NEEDS_CONTEXT.

## Report contract
`.delix/report.md` (≤ 2K tokens): `DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED` · command + output · PR number · assumptions · remaining work. Read only this card and SPEC §3–4, §6, §9 K81–K82.

## Review findings (filled by the orchestrator)
- Round 1 (2026-11-03; qa ACCEPT_WITH_NOTES, security FIX). Fix:
  - [Medium, security] `scripts/feedback.py:300` (+ print sites :503, :568): only Unicode `Cf`/`Co` are rejected; `Cc` control characters (ESC `\x1b`, `\r`, backspace) pass `validate()` and are printed raw by `preview` and `send` before `SEND <hash>`. A crafted draft (e.g. `\u001b[2K`, `\x1b[8m`, `\r`) can make the terminal show different text from what is sent, defeating REQ-6's human read. Fix: reject any `Cc` except `\n` and `\t` in `validate()` (exit 2) and also BLOCK in `build()`; add tests with `\u001b[2K` and `\r`.
  - [Medium, security] `scripts/feedback.py:291`, `:294–295`: the body's last line `delixcrew-fp: <fp>` takes `rec["fingerprint"]` from disk unchecked and outside all fail-closed checks; a tampered record can inject arbitrary text into the public body and the `--search` argument with a matching hash. Fix: in `build()` recompute `fingerprint(kind, component, title)` and BLOCK if the stored value differs (or require `[0-9a-f]{16}`); test with a tampered record.
  - [P1, qa P2 raised by orchestrator: violates the REQ-3 scenario "`github.com/tahircengiz/delixcrew` değişmez"] `scripts/feedback.py:384-389`: for a non-plugin remote owned by `tahircengiz` (e.g. `git@github.com:tahircengiz/foo.git`) the owner becomes an origin term and every later body renders `github.com/<redacted:term>/delixcrew`. Fix: never add the plugin repo's owner `tahircengiz` to `origin_terms` (treat it like `PLUGIN_TERMS`); test with a `tahircengiz/foo` remote.
- Round 1 notes (P2/Low, no fix required): `d["kind"] not in LABELS` raises TypeError for non-string kind (REQ-2 wants exit 2); `ABS_PATH_RE` misses single-segment absolute paths (`/acme-internal`); `cmd_add` duplicate branch writes to `record_path(r["id"])` with an unvalidated id from disk (Low, path traversal from a tampered record); FILE_EXTS contains real ccTLDs (`.sh`, `.pl`, `.rs`…) so `corp-intranet.pl` is not redacted (SPEC decision K75).
- Round 1 re-review (2026-11-03, 12c4fc3): qa ACCEPT_WITH_NOTES, security 🔐 HUMAN_APPROVAL; all three round-1 findings fixed; tests at 12c4fc3 (orchestrator, git archive): feedback 64 ✔ / hook 39 ✔ / board 15 ✔, validate passed, CI pass. Notes (P2/Low, no fix): newline allowed in `title` (a fake `HASH:` line in preview can only make send stop with exit 5); `cmd_list` prints raw fields of a record edited on disk; `send` does not check `status` (a dropped record can be sent).
