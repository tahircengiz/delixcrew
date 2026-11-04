# T024 — 🔐 bash_gate: no option-like capture path; one capture match exempts both scripts' rules (#36)

| id | size | tier | role | wave | status |
|---|---|---|---|---|---|
| T024 | M | 3 | backend | 1 | open |

> 🔐 Tier 3: `scripts/bash_gate.py` is a protected path, and REQ-3 changes which heredoc bodies the publish-path rules skip. It also closes the `python3 -ic…/feedback.py add` hole found on main (SPEC §6, K187). The lead adds the Approved line after the human says "yes".

**🔐 Approved:** 2026-11-04 tahircengiz

**Goal (1 sentence):** The four capture path patterns reject a path that starts with `-`. One `ADD_HEREDOC` or `RECORD_HEREDOC` fullmatch with no early delimiter limits feedback (a)/(b) and triage (a)/(b) to the header line. Every other shape keeps its full-text check, and rule order and deny texts stay unchanged. · **Spec:** `docs/delix/SPEC.md#REQ-3`; §4, §6; K182, K183, K187, K188

## Files
- Modify: `scripts/bash_gate.py` (lines 23–28 and 45–52)
- Test: `tests/hook_tests.sh` (insert only, after line 251)

## Edit anchors (base 4b52a3b; match the content, not only the number)
`scripts/bash_gate.py`:
1. Line 23, old → new:
```python
_QPATH = r"\"(?:[^\"\n$`\\]*/)?feedback\.py\""
_QPATH = r"\"(?!-)(?:[^\"\n$`\\]*/)?feedback\.py\""
```
2. Line 24, old → new:
```python
_PATH = r"(?:[^\s'\"$`\\;&|<>(){}#*?\[\]~]*/)?feedback\.py"
_PATH = r"(?!-)(?:[^\s'\"$`\\;&|<>(){}#*?\[\]~]*/)?feedback\.py"
```
3. Insert after line 26 `                         r"\n(.*)\n\3", re.S)` (end of `ADD_HEREDOC`), before line 27 `m = ADD_HEREDOC.fullmatch(cmd.strip())`. This block is lines 47–50 moved up, with `(?!-)` added:
```python
# The same shape for exactly one `python3 <path>/triage.py record <n> <<'DELIM'` call.
_TQPATH = r"\"(?!-)(?:[^\"\n$`\\]*/)?triage\.py\""
_TPATH = r"(?!-)(?:[^\s'\"$`\\;&|<>(){}#*?\[\]~]*/)?triage\.py"
RECORD_HEREDOC = re.compile(r"(python3[ \t]+(?:" + _TQPATH + "|" + _TPATH + r")[ \t]+record[ \t]+\d+[ \t]+<<(['\"])"
                            r"([A-Za-z_][\w.-]*)\2)\n(.*)\n\3", re.S)
# REQ-3 (#36, K182, K187): no path starts with `-` (`python3 -ic<dir>/feedback.py` runs the body as code); one
# capture match of either script limits the feedback and the triage (a)/(b) rules to its first line (order unchanged).
```
4. Line 27 → `m = ADD_HEREDOC.fullmatch(cmd.strip()) or RECORD_HEREDOC.fullmatch(cmd.strip())`. Lines 28–31 (`checked = …`, the feedback `if`, `deny(FEEDBACK_DENY)`) stay unchanged.
5. Lines 45–46 (`# (a) and (b) skip a heredoc body only for exactly one …` / `# ADD_HEREDOC shape above (literal path, …`) become:
```python
# (a) and (b) see `checked` from the feedback block: the first line of one capture call (ADD_HEREDOC or
# RECORD_HEREDOC, defined above), otherwise the full text. (c) and (d) see the full text.
```
6. Delete lines 47–50 (`_TQPATH`, `_TPATH`, both `RECORD_HEREDOC` lines): edit 3 moved them.
7. Lines 51–52 (`tm = RECORD_HEREDOC.fullmatch(cmd.strip())` / `tchecked = tm.group(1) if tm and …`) become one line: `tchecked = checked`. Lines 53–55 (triage `if` + `deny(TRIAGE_DENY)`) and everything from line 56 on stay byte-identical.

## Interfaces
- Produced: no new name. Hook decisions change only as REQ-3 says.
- Unchanged: `FEEDBACK_DENY` (`:18`) and `TRIAGE_DENY` (`:44`); the group numbers of `ADD_HEREDOC`/`RECORD_HEREDOC` (1 header, 2 quote, 3 delimiter, 4 body); the gh rules; the reviewer block; the protected-path redirect check; gitleaks.
- Consumed (tests): `deny`/`allow` (`tests/hook_tests.sh:11–13`), `bashjson` (`:107`), `hd` (`:120`), `rtime` (`:228–243`), `$N` (`:86`).

## Global Constraints (verbatim from the spec)
- REQ-3: "**(a)** dört yol kalıbında (`_QPATH`, `_PATH`, `_TQPATH`, `_TPATH`) yolun `-` ile başlamasını reddetmeli (`(?!-)`, tırnaklı biçimde tırnaktan hemen sonra); böyle bir komut kalıba uymaz ve tam metinle denetlenir; **(b)** komutun tamamı `ADD_HEREDOC` ya da `RECORD_HEREDOC`'a fullmatch oluyor ve ayraç gövdede erken geçmiyorsa feedback (a)/(b) ve triage (a)/(b) kurallarının **ikisini de** yalnız başlık satırına (group 1) uygulamalı. Kural sırası, kalıpların geri kalanı, `gh` kuralları, deny metinleri ve korumalı yol yönlendirme denetimi değişmez."
- Test note: "Test genel `deny` yardımcısını kullanır (`tests/hook_tests.sh:11`): tam metne düşen komutta feedback bloğu önce çalıştığı için hangi deny metninin geleceği gövdeye bağlıdır; sıra değiştirilmez."
- K182: "Çapraz muafiyet iki kalıbın zaten hesaplanan eşleşmesini paylaşır; yeni regex yok (ReDoS yüzeyi büyümez)." The only new regex element is the `(?!-)` lookahead (K187).
- K183: "muafiyet tek çağrı + tırnaklı ayraçla sınırlı kalır (fail closed)."
- Timing: "mevcut ReDoS probe'larına çapraz biçimde iki probe eklenir (50 000+ karakter gövde) → her probe mevcut eşiğin (`ls`'e göre < 0,1 sn) altında; süreler PR gövdesinde".
- Stdlib only. Write the tab as `printf '\t'`, never as a raw character.

## Steps
1. **Write the failing tests first.** Insert after line 251 `DELIXCREW_TRIAGE_DIR="$T/tq" allow "triage lookalike dir still free (case fix)" write_gate.py …`, before line 252 `rm -rf "$T"; [ $FAIL -eq 0 ] && echo "ALL PASSED" || { echo "FAILED"; exit 1; }`:
```bash
# T024 REQ-3 (#36, K182, K187, K188): one capture call of either script exempts its body from both scripts' (a)/(b);
# a path starting with `-` is never a capture call; deny cases use the generic deny helper (rule order unchanged)
FAH="python3 \"/x/scripts/feedback.py\" add <<'EOF'"; TRH="python3 \"/x/scripts/triage.py\" record 12 <<'EOF'"
allow "T024 cross: add body names triage.py apply"        bash_gate.py "$(hd "$FAH" '{"title": "triage.py apply 12 --confirm abc fails"}' 'EOF')"
allow "T024 cross: add body, triage.py under script"      bash_gate.py "$(hd "$FAH" '{"title": "triage.py record hangs under script"}' 'EOF')"
allow "T024 cross: record body names feedback.py send"    bash_gate.py "$(hd "$TRH" '{"reason": "feedback.py send F001 --confirm abc is refused"}' 'EOF')"
allow "T024 cross: record body, feedback.py under script" bash_gate.py "$(hd "$TRH" '{"reason": "feedback.py add hangs under script"}' 'EOF')"
PSF='import pty; pty.spawn(["python3","/x/feedback.py","send","F001","--confirm","abc"])'
PST='import pty; pty.spawn(["python3","/x/triage.py","apply","12","--confirm","abc"])'
for c in 'python3 -ic/x/feedback.py add' 'python3 "-ic/x/feedback.py" add' 'python3 -ic/x/triage.py record 12' 'python3 "-ic/x/triage.py" record 12'; do
  deny "T024 option-like path [$c], body drives feedback send" bash_gate.py "$(hd "$c <<'EOF'" "$PSF" 'EOF')"
  deny "T024 option-like path [$c], body drives triage apply"  bash_gate.py "$(hd "$c <<'EOF'" "$PST" 'EOF')"
done
XT='python3 scripts/triage.py apply 12 --confirm abc'; XF='python3 scripts/feedback.py send F001 --confirm abc'
xtricks(){ # label, carrier call without the heredoc operator, the other script's write call
  local w="$1" c="$2" p="$3"
  deny "T024 $w: unquoted <<EOF with \$(…)"              bash_gate.py "$(hd "$c <<EOF" "\$($p)" 'EOF')"
  deny "T024 $w: unquoted <<EOF with backticks"           bash_gate.py "$(hd "$c <<EOF" "\`$p\`" 'EOF')"
  deny "T024 $w: command on the delimiter line"           bash_gate.py "$(hd "$c <<'EOF'" '{"t":"x"}' "EOF; $p")"
  deny "T024 $w: line after the delimiter"                bash_gate.py "$(hd "$c <<'EOF'" '{"t":"x"}' 'EOF' "$p")"
  deny "T024 $w: early delimiter inside the body"         bash_gate.py "$(hd "$c <<'EOF'" '{"t":"x"}' 'EOF' "$p" 'EOF')"
  deny "T024 $w: <<- and a tab-indented early delimiter"  bash_gate.py "$(hd "$c <<-'EOF'" '{"t":"x"}' "$(printf '\tEOF')" "$p" 'EOF')"
  deny "T024 $w: header suffix | bash"                    bash_gate.py "$(hd "$c <<'EOF' | bash" "$p" 'EOF')"
  deny "T024 $w: header suffix && x"                      bash_gate.py "$(hd "$c <<'EOF' && x" "$p" 'EOF')"
  deny "T024 $w: # <<EOF comment trick"                   bash_gate.py "$(hd "$c # <<EOF" "$p" 'EOF')"
  deny "T024 $w: \\<<EOF escape trick"                    bash_gate.py "$(hd "$c \\<<EOF" "$p" 'EOF')"
  deny "T024 $w: \"<<EOF quote trick"                     bash_gate.py "$(hd "$c \"<<EOF" "\"; $p" 'EOF')"
  deny "T024 $w: cd x && <capture>"                       bash_gate.py "$(hd "cd x && $c <<'EOF'" "$p" 'EOF')"
  deny "T024 $w: <capture>; echo x"                       bash_gate.py "$(hd "$c <<'EOF'; echo x" "$p" 'EOF')"
}
xtricks "add carrier"    'python3 "/x/scripts/feedback.py" add'     "$XT"
xtricks "record carrier" 'python3 "/x/scripts/triage.py" record 12' "$XF"
deny "T024 add carrier: \${VAR} path"    bash_gate.py "$(hd "python3 \"\${CLAUDE_PLUGIN_ROOT}/scripts/feedback.py\" add <<'EOF'" '{"title": "triage.py apply 12 --confirm abc"}' 'EOF')"
deny "T024 record carrier: \${VAR} path" bash_gate.py "$(hd "python3 \"\${CLAUDE_PLUGIN_ROOT}/scripts/triage.py\" record 12 <<'EOF'" '{"reason": "feedback.py send F001 --confirm abc"}' 'EOF')"
python3 - "$T" "$N" <<'PYX'
import json, sys
t, n = sys.argv[1], sys.argv[2]
probes = {
    "xadd": "python3 \"/x/scripts/feedback.py\" add <<'EOF'\n" + ("triage.py -a apply script " * 25 + "\n") * 100 + "EOF",
    "xrec": "python3 \"/x/scripts/triage.py\" record 12 <<'EOF'\n" + ("feedback.py -a send script " * 25 + "\n") * 100 + "EOF",
}
for k, c in probes.items():
    with open(f"{t}/probe-{k}.json", "w") as f:
        json.dump({"tool_name": "Bash", "cwd": n, "tool_input": {"command": c}}, f)
PYX
rtime "ReDoS: 65 KB cross body in add heredoc"    "$T/probe-xadd.json"
rtime "ReDoS: 67 KB cross body in record heredoc" "$T/probe-xrec.json"
```
   Run `bash tests/hook_tests.sh` and see **red**. Expected ✘ lines:
   - the 4 cross allows;
   - the option-like cases whose body drives the same script: `[…feedback.py add], body drives feedback send` ×2 and `[…triage.py record 12], body drives triage apply` ×2. The lead measured these four shapes on main 4b52a3b (all allowed today; SPEC §3, §6). Report the names of the ✘ lines you get.
   - Trick, `${VAR}` and timing lines already pass.
2. **Implement** edits 1–7. Touch only the paths in Files.
3. **Green:** `bash tests/hook_tests.sh`, then the full loop and `claude plugin validate .`. If an existing line goes ✘, do not edit it: report `NEEDS_CONTEXT` with the output.
4. **Commit** `T024: no option-like capture path; one capture match exempts both rule sets`. Open the PR with `--body-file`; `## How I tested` has the commands, the ✔/✘ counts and all six `ReDoS:` Δ values.

## Verification command → expected output
- `for t in tests/*_tests.sh; do bash "$t" || exit 1; done` → exit 0; `claude plugin validate .` → passes
- `bash tests/hook_tests.sh | grep -c '^✔ T024'` → `40` at round 0; `44` after fix round 1 (K197 adds 4 `T024 glob path` denies)
- After fix round 1: `grep -cF '~^]*/' scripts/bash_gate.py` → `2` (`-F`: some `grep` builds read a mid-pattern `^` as an anchor)
- `bash tests/hook_tests.sh | grep '^✔ ReDoS'` → 6 lines (4 existing + 2 new), each Δ < 0.1 s
- `bash tests/hook_tests.sh | grep -c '^✘'` → `0`; last line `ALL PASSED`
- `grep -c '(?!-)' scripts/bash_gate.py` → `4`
- `git diff -U0 origin/main -- scripts/bash_gate.py | grep -E '^[-+].*(deny\(|_DENY =|re\.search|finditer|subprocess)'` → no output
- `git diff origin/main -- tests/hook_tests.sh | grep -c '^-[^-]'` → `0`
- `git diff --stat origin/main` → only the 2 files in Files

## Review Focus
- The early-delimiter check applies to whichever pattern matched. Tests: "early delimiter inside the body" for both carriers.
- The moved `_TQPATH`, `_TPATH` and `RECORD_HEREDOC` are identical except for `(?!-)`. Check with `git diff --color-moved=zebra`.
- `[ \t]+` cannot take the `-`, so the lookahead covers every token that starts with `-`. In the quoted form the lookahead sits right after `"`.
- Implied but not tested:
  - `<<"EOF"` (double-quoted delimiter) in the cross form is allowed, like `<<'EOF'`.
  - A tab instead of a space in the header.
  - A CRLF body: for bash, `EOF\r` is not the delimiter, and the check agrees.
  - `python3 ./-ic/x/feedback.py` is a real file path, not options (§6 remaining-risk class).
  - `gh` rules (c)/(d) still check the full text: a capture body naming `gh issue comment` and delixcrew stays denied (over-blocking is out of scope, §2).
- Not a target: the triage (a) argv-list form (§8).

## Don'ts
- Do not touch anything outside the 2 files, in particular `scripts/common.py`, `scripts/write_gate.py`, `hooks/hooks.json`, `README*`, `SECURITY.md`, `CHANGELOG.md`, `site/**`, `docs/delix/**`, and T023's files.
- Do not reorder rules, change deny texts, or edit the gh rules (`:32–41`, `:56–69`), the reviewer block (`:71–83`), the redirect check (`:91–96`) or the gitleaks block.
- No new regex, alternation or class beyond `(?!-)` (K182). No exemption for `cat >> notes <<'EOF'`, `cd … &&`, `; echo`, `${…}` (K183, §2).
- Do not change or delete any existing test line. If a test looks wrong, stop: `NEEDS_CONTEXT`.
- Do not run ad-hoc Bash commands with the hook's trigger words (the live hook denies them). Exercise the gate only through `bash tests/hook_tests.sh`.

## Report contract
`.delix/report.md` (≤ 1.5K tokens): `DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED` · commands + output (✔/✘ counts, the names of the red lines from step 1, the six ReDoS Δ) · PR number · assumptions. Read only this card and SPEC REQ-3, §4, §6, §9.

## Review findings (filled by the lead)
- Round 0 (PR #48 @ c90163a): qa ACCEPT (P0 0, P1 0). security 🔐 HUMAN_APPROVAL (protected path), 0 findings;
  gitleaks on the diff, `scripts/` and `tests/`: no leaks. `/security-review` on the diff: no findings. CI green (test,
  check). Lead ran all 8 suites from `git archive c90163a`: 0 ✘ (hook 182 ✔, 40 `✔ T024`, `(?!-)` 4); removed test
  lines 0; internal address scan of `+` lines 0. Lead probe: the 4 option-like shapes allowed on main 9f6f8e7 are
  denied on c90163a; the normal add shape is still allowed.
  - Low (security "unsure", reproduced by the lead): the unquoted path classes `_PATH`/`_TPATH` still allow `^`. With
    zsh `extendedglob` (not the zsh default; off in the lead's shell) `^q/x.py` expands to `-ic/x.py` when that
    directory exists (measured: default zsh and bash keep it literal). `python3 ^x/feedback.py add <<'EOF'` and
    `python3 ^x/triage.py record 12 <<'EOF'` with a pty body are allowed on c90163a (3/3, cross included) and on main
    (2/3, cross denied), so the K187 shape reopens at expansion time. Lead prototype on a scratch copy: `~^]` in both
    classes makes 3/3 deny, all hook tests pass, 4 new tests go from 4 ✘ (c90163a) to 44 `✔ T024`, ReDoS unchanged.
  - Decision (user, in chat, 2026-11-04): fix it in this card, round 1. K197 (reversible): `^` joins the excluded
    characters of `_PATH`/`_TPATH`; this is the only class change beyond `(?!-)` that K182 now allows.
- Round 1 (PR #48 @ e58d867, fix round 1): the fix is byte-identical to the lead's prototype (`cmp` on both files).
  qa ACCEPT_WITH_NOTES (P0 0, P1 0); security 🔐 HUMAN_APPROVAL, 0 findings; gitleaks on the diff, `scripts/` and
  `tests/`: no leaks. CI green (test, check). Lead ran all 8 suites from `git archive e58d867`: 0 ✘ (hook 186 ✔, 44
  `✔ T024`, `(?!-)` 4, `~^]*/` 2), and again on `git merge-tree origin/main e58d867` (main e2a82db, T023 merged): no
  conflict, 0 ✘. Lead probe: the 4 `-ic` shapes, the 3 `^x` shapes and plain `python3 -` are denied; the normal add
  shape is allowed. Gate 2: user.
  - P2, fixed by the lead in this card: the Verification count was 40; it is 44 after K197 (line above).
  - Security "unsure", checked by the lead, no finding: zsh `EQUALS` keeps `=ls/../x.py` from running (`not found`,
    the command aborts) and bash leaves it literal; a `-` result would need a PATH or hash entry that a fullmatch
    command cannot set. `.strip()` of Unicode whitespace before `python3` predates this card and needs a planted
    executable (SPEC §6 class).
