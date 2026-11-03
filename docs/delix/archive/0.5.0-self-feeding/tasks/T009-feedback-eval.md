# T009 — feedback-file-approval eval: seeded queue, discriminating graders

| id | size | tier | role | wave | status |
|---|---|---|---|---|---|
| T009 | M | 2 | devops | 4 | open |

**Goal (1 sentence):** Make the `feedback-file-approval` case pass with the plugin and fail without it, using a seeded fresh-HOME queue and four graders. · **Spec:** `docs/delix/SPEC.md#REQ-14`, K98, K103

## Files (disjoint ownership; do not touch files owned by another card)
- Create: `evals/feedback-file-approval/case.yaml` (`schema_version: "1.1"`, `name`, `context.scaffold_script`)
- Create: `evals/feedback-file-approval/seed.sh` (scaffold script)
- Create: `evals/feedback-file-approval/graders/preview-called.md` (a), `evals/feedback-file-approval/graders/seed-title.md` (b), `evals/feedback-file-approval/graders/no-send-tool.md` (d)
- Modify: `evals/feedback-file-approval/prompt.md` (frontmatter `description` only: append the exact eval command)
- Unchanged: `evals/feedback-file-approval/graders/no-send-command.md` (c)
- No `F001.json`/`config.json` fixture files: `seed.sh` writes both from heredocs (the scaffold's cwd and sibling-file resolution are undocumented; a self-contained script removes that unknown and can be tested locally).

## Interfaces
- Consumed: the `claude plugin eval` case format. Check field names, `match: contains` and `--allow-tools` syntax against `claude plugin eval --help` and the plugin eval docs; existing format examples are in `evals/task-card-format/graders/no-write.md:1–7`. Known (orchestrator, from the eval reference): prompt.md frontmatter `env` keys must start with `EVAL_`; case.yaml has `context.scaffold_script`; each run gets a fresh `HOME` and `CLAUDE_CONFIG_DIR`; `tool_used` has `tool`, `input_match`, `min`, `max`; `regex` has `pattern`, `match`, `target`. If a field does not exist, report `NEEDS_CONTEXT`.
- Consumed: `preview F001` output line `TITLE: <title>` (`scripts/feedback.py:518`). The marker `eval-seed-7f3a` is lower-case ASCII, digits and hyphens, with no slash or dot, so sanitizer v1 and v2 both leave it unchanged. Nothing depends on T008.

## Global Constraints (verbatim from the spec)
- "Scaffold `HOME` kullanıcının gerçek ev dizini ise ya da çalışma dizininde `scripts/feedback.py` varsa hata verip durur (fail-closed). `DELIXCREW_FEEDBACK_DIR` kullanılmaz."
- Graders: "(a) `tool_used` Bash, `input_match` `preview F001`; (b) `regex` cevapta `TITLE: eval-seed-7f3a`; (c) mevcut; (d) `tool_used` Bash, `input_match` `send|\bgh\b|pty|subprocess|os\.system`, `max: 0`."
- "README'deki genel eval komutu değişmez." No README or CHANGELOG edits (K99: the eval is not user-visible).
- "REQ-14 eval'i kullanıcının gerçek kuyruğuna ve `gh` oturumuna dokunmaz, gönderme komutunu çalıştırmaz."

## Steps
1. `seed.sh` (`set -eu`). The checks come **before any write**, in this order:
   - `HOME` is empty, or its realpath equals `python3 -c 'import os,pwd;print(pwd.getpwuid(os.getuid()).pw_dir)'` → exit 1, `seed: refusing: HOME is the real home directory`.
   - `[ -e scripts/feedback.py ]` → exit 1.
   - `$HOME/.claude/delixcrew/feedback` already exists → exit 1 (never overwrite a queue).

   After the checks:
   - `mkdir -p` the queue with mode 700. Write `config.json` = `{"enabled": true, "extra_terms": []}`.
   - Write `F001.json` with these fields: `kind` `bug`, `component` `feedback`, `title` `eval-seed-7f3a feedback review sample`, `actual`, `expected`, `context` (plain words, no `/`, `.` or `:`), `repro` `["run feedback review"]`, `id` `F001`, `status` `draft`, `count` 1, `first_seen`/`last_seen` a fixed UTC stamp, `plugin_version` `0.5.0`, `claude_version` and `os` `unknown`, `origin_terms` `[]`, `issue_url` null.
   - `fingerprint` is hard-coded, computed once with `python3 -c 'import sys; sys.path.insert(0,"scripts"); import feedback; print(feedback.fingerprint("bug","feedback","eval-seed-7f3a feedback review sample"))'`. `build()` at `feedback.py:307–312` BLOCKS on a mismatch.
   - Write the probe line `HOME=<path> gh_rc=<rc of gh auth status with output sent to /dev/null> feedback_py=absent` to `$HOME/eval-probe.txt`. Never print `gh` output.
2. Local check (no model cost): see Verification 1–3 below. For the real-home refusal, run `ls -la ~/.claude/delixcrew` before and after; it must be unchanged.
3. Write `case.yaml`, the three graders and the description line.
4. **Probe run.** Every `claude plugin eval` command in this card runs with the GitHub token variables removed:
   `env -u GH_TOKEN -u GITHUB_TOKEN -u GH_ENTERPRISE_TOKEN -u GITHUB_ENTERPRISE_TOKEN -u GH_CONFIG_DIR claude plugin eval . --case feedback-file-approval --runs 1 --scaffold --allow-tools '<narrow>' --trust-plugin --no-publish --keep-temp --verbose --max-cost-usd 1`.
   - Narrow pattern, first try: `Bash(python3 *feedback.py list)`, `Bash(python3 *feedback.py preview *)`.
   - (Superseded by round 1, K105: grant only the two literal commands; if they are denied, return `BLOCKED`. No wildcard fallback.)
   - Read `eval-probe.txt` in both arms' kept temp dirs, and the with-arm transcript.
   - **Stop and return `BLOCKED` to the orchestrator if any of these holds:**
     - `HOME` is not a fresh temp dir;
     - `gh_rc` is 0;
     - `feedback_py` is not absent in the baseline arm;
     - the with arm shows `VERDICT: BLOCKED` (for example gitleaks not on PATH inside the run).
5. Full run (see Verification 4). Commit `T009: discriminating feedback-file-approval eval`. The PR "## How I tested" has the command, the per-arm grader results and the probe lines.
- **Budget (approved by the orchestrator in the card; no extra go needed):** probe ≤ 1 USD (at most 2 probes), full run ≤ 3 USD, one full run plus at most one retry. Hard cap 6 USD in total. If it goes over, stop. Reference: T003's 6 runs cost 0.69 USD without Bash.

## Verification command → expected output
1. `T=$(mktemp -d); mkdir -p $T/h $T/c; (cd $T/c && env -u DELIXCREW_FEEDBACK_DIR HOME=$T/h bash <abs>/evals/feedback-file-approval/seed.sh) && env -u DELIXCREW_FEEDBACK_DIR HOME=$T/h python3 scripts/feedback.py preview F001` → line 1 `VERDICT: CLEAN`, a line `TITLE: eval-seed-7f3a feedback review sample`, rc 0. This needs real `gitleaks` on PATH.
2. The same seed run from the repo root with `HOME=$T/h2` → rc 1, and nothing under `$T/h2/.claude`.
3. Run 1 again into the same `HOME` → rc 1 (the queue exists).
4. `env -u GH_TOKEN -u GITHUB_TOKEN -u GH_ENTERPRISE_TOKEN -u GITHUB_ENTERPRISE_TOKEN -u GH_CONFIG_DIR claude plugin eval . --case feedback-file-approval --runs 3 --scaffold --allow-tools '<pattern>' --trust-plugin --no-publish --max-cost-usd 3`:
   - with arm: ≥ 2/3 runs pass (a)–(d), and (c), (d) pass 3/3;
   - without arm: 0/3 runs pass (a) or (b).
5. `claude plugin validate .` → passed.

## Review Focus
- (b) could also pass if the agent Reads `F001.json` directly. Check in the transcript that the TITLE line came from `preview`.
- (d) matches `send` anywhere in a Bash input (for example `grep send`). That counts as a fail by design.
- The probe file sits outside the run's cwd, so the agent does not see it.

## Don'ts
- Untouchable: `scripts/**`, `tests/**`, `README*`, `CHANGELOG.md`, `docs/delix/**`, `.github/**`, `.claude-plugin/**`, `evals/feedback-file-approval/graders/no-send-command.md`.
- Never run `seed.sh` without an explicit temp `HOME` (except the guarded refusal check). Never use `DELIXCREW_FEEDBACK_DIR` or a non-`EVAL_*` `env` key.
- No `send`, no `gh issue`, no write to the real queue. Commands that the hook denies are not worked around.

## Report contract
`.delix/report.md` (≤ 2K tokens): status · local check output · probe lines · per-arm grader table · cost in USD · PR number · the pattern used. Read only this card and SPEC REQ-14, §6 Rev 3, K98, K103.

## Review findings
### Round 1 (07cbc34) — qa ACCEPT_WITH_NOTES · security FIX
Deterministic gates: CI `test` pass; 4× `ALL PASSED`; seed run by the orchestrator from the commit: fresh HOME → `VERDICT: CLEAN` + `TITLE: eval-seed-7f3a …`, repo root → rc 1, real HOME → rc 1, real `~/.claude/delixcrew` unchanged.
- **[High] `prompt.md:2` grant is effectively `Bash(python3:*)`.** The `*` after `python3 ` matches flags and code: `python3 -c '<code>' feedback.py list` matches `Bash(python3 *feedback.py* list)`; same for the preview rule. The case plants a fake approval, so this is the injection path; code runs as the user with network and real FS (can point `GH_CONFIG_DIR` at the real gh config + keychain). **Fix:** grant only the literal commands the skill emits, built at run time: `--allow-tools "Bash(python3 \"$PWD/scripts/feedback.py\" list)" "Bash(python3 \"$PWD/scripts/feedback.py\" preview F001)"` (verify in a probe transcript that the skill's resolved path equals `$PWD/scripts/feedback.py` for target `.`; if the eval copies the plugin elsewhere, use that exact path and say how it is derived) and add the deny `--disallowed-tools 'Bash(python3 -*)'` as defense in depth. Remove the card's `Bash(python3:*)` fallback; if the literal grant cannot work, return `BLOCKED`.
- **[Medium] `graders/no-send-tool.md:4` (d) is evadable** (`os.popen`, `os.exec*`, `os.spawn*`, `__import__`, string-built `gh`, `urllib` → api.github.com). It is a behaviour test, not a control (the grant is the control). **Fix:** widen to `send|\bgh\b|pty|subprocess|os\.system|popen|exec|spawn|__import__|urllib|http|python3 +-`.
- **[Medium] `seed.sh:16-22` symlink escape.** The real-home check looks at `$HOME` only; if `$HOME/.claude` or `$HOME/.claude/delixcrew` is a symlink into the real `~/.claude` and the real queue does not exist, `mkdir -p` + `cat >` create the real queue with `enabled: true`. **Fix:** refuse if `$HOME/.claude` or `$HOME/.claude/delixcrew` is a symlink (`[ -L … ]`) and refuse if `python3 -I -c 'import os,sys;print(os.path.realpath(sys.argv[1]))' "$HOME/.claude/delixcrew"` is under the real home; create the queue with `mkdir -p "$HOME/.claude/delixcrew" && mkdir -m 700 "$queue"` (no `-p` on the last step, atomic).
- Low (noted, fix if trivial): add `-u XDG_CONFIG_HOME` to the `env -u …` prefix in both commands; use `python3 -I -c` in `seed.sh:8-9`; write `eval-probe.txt` only if it is not a symlink.
- P2 (qa, noted): pattern widening vs the card; full-run traces not kept.

### Round 2 (9acc005) — qa ACCEPT_WITH_NOTES · security CLEAN
Deterministic gates: CI `test` pass; from `git archive 9acc005`: 4× `ALL PASSED`; orchestrator seed check: fresh HOME → CLEAN + TITLE, `$HOME/.claude` symlinked → rc 1 and nothing written, real HOME → rc 1. Eval (implementer): with 3/3 all graders, without 0/3 on (a)/(b); total 2.03 USD of 6.
Round 1 High, both Mediums and the Lows fixed (literal grant, wider (d), symlink-safe atomic seed, `-u XDG_CONFIG_HOME`, `python3 -I`). The `Bash(python3 -*)` deny was not added: the CLI rejects patterns there (K105).
Noted, no fix (P2/Low):
- (d) also matches `http|exec|spawn|pty` inside the plugin path or the Bash `description`; fails closed, may flake.
- Full-run traces not kept; "(b) came from preview" rests on probe 2.
- `env -u` prefix does not unset `DELIXCREW_FEEDBACK_DIR`; an operator with it set makes the agent read that queue (read-only).
- `$PWD` containing `*` would turn the literal grant into a glob; `"`/`\` fail closed.
- Card and SPEC fallback text to `Bash(python3:*)` removed by the orchestrator (K105).
