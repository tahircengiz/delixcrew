# T023 — 🔐 Confirmation prompt says what to type; exit 8 names a recorded but unapplied accept (#34, #35)

| id | size | tier | role | wave | status |
|---|---|---|---|---|---|
| T023 | M | 3 | backend | 1 | open |

> 🔐 Tier 3: changes the confirmation step of the two publish paths (`triage.py apply`, `feedback.py send`) and the exit 8 text that `/delixcrew:start` shows (SPEC §6, K186). The lead adds the Approved line after the human says "yes".

**🔐 Approved:** 2026-11-04 tahircengiz

**Goal (1 sentence):** `triage.py apply` and `feedback.py send` print the REQ-1 prompt and refusal texts. `triage.py show <n> --require accepted` prints the REQ-2 recorded-locally line in both exit 8 branches when a valid, unapplied `accept` record matches the live text. `skills/start` step 1a and both READMEs follow. · **Spec:** `docs/delix/SPEC.md#REQ-1`, `#REQ-2`; §4, §6; K180, K181, K184, K186, K189, K190

## Files
- Modify: `scripts/triage.py` (lines 133–159 and 385–388)
- Modify: `scripts/feedback.py` (lines 792–795)
- Modify: `skills/start/SKILL.md` (line 30)
- Modify: `README.md` (lines 296–297)
- Modify: `README.tr.md` (line 297)
- Test: `tests/triage_tests.sh` (insert only, 3 places)
- Test: `tests/feedback_tests.sh` (insert only, 1 place)

## Edit anchors (base 4b52a3b; match the content, not only the number)
`scripts/triage.py`:
1. Insert after line 135 `    return 7` (end of `gh_failed`, lines 133–135) and before line 138 `# --- show / index ---…`. Keep two blank lines on each side:
```python
def not_accepted(n, sha, line):
    """REQ-8 exit 8 with `line` on stderr. REQ-2 (#35, K181, K189, K190): a valid local record that is an accept, not
    applied yet and made for the live text says where to go next instead; it never counts as acceptance."""
    rec, _ = load_record(n)
    if rec is not None and rec["decision"] == "accept" and rec["status"] == "recorded" and rec["issue_sha"] == sha:
        line = ('issue #%d is recorded locally as accept but not applied; from your own terminal run python3 "%s" '
                "preview %d, then the apply command with the HASH it prints" % (n, os.path.abspath(__file__), n))
    err(line)
    return 8
```
2. Lines 155–156 (`            err("issue #%d is not triaged as accepted; run /delixcrew:triage #%d" % (n, n))` / `            return 8`) become one line: `            return not_accepted(n, sha, "issue #%d is not triaged as accepted; run /delixcrew:triage #%d" % (n, n))`
3. Lines 158–159 (`            err("issue #%d changed since it was accepted; run /delixcrew:triage #%d" % (n, n))` / `            return 8`) become `            return not_accepted(n, sha, "issue #%d changed since it was accepted; run /delixcrew:triage #%d" % (n, n))`. Lines 154 and 157 (the two `if`) stay unchanged. `sha` is the value from line 151.
4. Line 385 `    sys.stdout.write("Type APPLY %s to apply it: " % h)` → `    sys.stdout.write("Type APPLY %s to apply it (the word APPLY, a space, then the hash): " % h)`
5. Line 388 `        err("not confirmed; nothing applied")` → `        err("not confirmed: type exactly APPLY %s (the word APPLY, a space, then the hash); nothing applied" % h)`

`scripts/feedback.py`:
6. Line 792 `    sys.stdout.write("Type SEND %s to send it: " % h)` → `    sys.stdout.write("Type SEND %s to send it (the word SEND, a space, then the hash): " % h)`
7. Line 795 `        err("not confirmed; nothing sent")` → `        err("not confirmed: type exactly SEND %s (the word SEND, a space, then the hash); nothing sent" % h)`

`skills/start/SKILL.md`:
8. Line 30 `   Exit 8: show the stderr line as it is, say "run `/delixcrew:triage #<n>` first" and stop. Exit 7: show the message and` → `   Exit 8: show only the stderr line, as it is, and stop; it already names the next step. Exit 7: show the message and`. Line 31 stays unchanged.

`README.md` (4b52a3b tree):
9. Lines 296–297 (`` `/delixcrew:triage #12` again in that case. Issue intake works only in the delixcrew repository and is still at least`` / `Tier 2.`) become:
```
`/delixcrew:triage #12` again in that case. If an `accept` decision for the current text is recorded locally but not
applied yet, the exit 8 message says so instead and gives the script's full path: from your own terminal, run its
`preview 12`, then the `apply` command with the `HASH` it prints. A local record never counts as acceptance. Issue
intake works only in the delixcrew repository and is still at least Tier 2.
```
`README.tr.md` (4b52a3b tree):
10. Line 297 (`` `/delixcrew:triage #12`'yi yeniden çalıştırın. Issue alımı yalnız delixcrew reposunda çalışır ve en az Tier 2'dir.``) becomes:
```
`/delixcrew:triage #12`'yi yeniden çalıştırın. Güncel metin için bir `accept` kararı yerelde kaydedilmiş ama henüz
uygulanmamışsa, çıkış 8 mesajı bu durumu söyler ve script'in tam yolunu verir: kendi terminalinizde o script ile
önce `preview 12`'yi, sonra yazdırdığı `HASH` ile `apply` komutunu çalıştırın. Yerel kayıt hiçbir zaman kabul
sayılmaz. Issue alımı yalnız delixcrew reposunda çalışır ve en az Tier 2'dir.
```

## Interfaces
- Produced: the REQ-1 prompt on stdout and refusal on stderr; the REQ-2 stderr line; `triage.not_accepted(n: int, sha: str, line: str) -> int` (internal, always returns 8).
- Consumed: `load_record(n) -> (dict | None, exists: bool)` (`triage.py:273–279`), `err(msg)` (`feedback.py:99`), `sha` = `issue_sha(title, body)` (`triage.py:151`).
- Consumer: `skills/start/SKILL.md` 1a shows the stderr line as it is.
- Unchanged: exit codes 6 and 8; `show` stdout; both existing exit 8 strings; `validate()`; record format (§5).

## Global Constraints (verbatim from the spec)
- REQ-1: "The system SHALL `triage.py apply` ve `feedback.py send`'in istem ve ret satırlarını şu metinlerle yazmalı (`<h>` gerçek 12 hex hash): istem `Type APPLY <h> to apply it (the word APPLY, a space, then the hash): ` ve `Type SEND <h> to send it (the word SEND, a space, then the hash): `; ret (stderr, `err()` ile) `not confirmed: type exactly APPLY <h> (the word APPLY, a space, then the hash); nothing applied` ve `not confirmed: type exactly SEND <h> (the word SEND, a space, then the hash); nothing sent`. Birebir karşılaştırma (`readline().strip() != "APPLY " + h`), TTY kontrolü, hash bağlama ve exit 6 aynen kalır; yazılan satır hiçbir çıktıya eklenmez (bugünkü kod; yeni test istenmez)."
- REQ-1 test method: "birleşik çıktıda `tr -d '\r' | grep -qF '<ret satırı>'` geçer (pty stdout ve stderr'i birleştirir, `\r\n` verir; `2>dosya` ve `grep -x` kullanılmaz)"
- K180: "Tırnak kullanılmaz: kullanıcı tırnağı da yazar ve birebir karşılaştırma reddeder. Yazılan metin yankılanmaz (K139 terminal güvenliği)."
- REQ-2: "`triage.py show <n> --require accepted`'ın **iki** exit 8 dalında da (etiket/işaret yok; işaret eski sha'lı) mesajı basmadan önce `load_record(n)`'a bakmalı: geçerli kayıtta `decision == "accept"`, `status == "recorded"` ve `issue_sha` canlı `issue_sha(title, body)`'ye eşitse stderr'e `issue #<n> is recorded locally as accept but not applied; from your own terminal run python3 "<path>" preview <n>, then the apply command with the HASH it prints` yazmalı (`<path>` = `os.path.abspath(__file__)`). Başka her durumda o dalın bugünkü mesajı birebir kalır. Exit 8 ve boş stdout her durumda kalır; yerel kayıt hiçbir zaman kabul sayılmaz. `skills/start/SKILL.md` adım 1a, exit 8'de sabit "run triage first" cümlesi yerine yalnız stderr satırını gösterip durur. README.md "From issue to work" paragrafı ve README.tr.md karşılığı bu durumu anlatır."
- REQ-2 scenario: "kayıt yoktur; kayıt JSON'u geçersizdir; kayıt eski sha taşır; kayıt `defer`'dir; kayıt `status: applied`'dır ama etiket yoktur → exit 8, stdout boş, stderr birebir `issue #<n> is not triaged as accepted; run /delixcrew:triage #<n>`"
- K181: "`applied` kaydı varken etiketin eksik olması (biri kaldırmış) bugünkü mesajı alır, çünkü yeniden triage doğru adımdır."
- K184: no site change. K179: CHANGELOG is written by the lead.
- Stdlib only, no new import. `feedback.py` stays one file (`tests/feedback_tests.sh:174` copies it alone). No existing test expectation is relaxed. Write invisible characters as escapes, never raw.

## Steps
1. **Write the failing tests first.** Insert only.
   a. `tests/triage_tests.sh`: insert after line 197 `  && ok "REQ-5 record dir 0700, file 0600" || bad "REQ-5 modes"`, before line 198 `ISHA13=…`:
```bash
# T023 REQ-2 (#35): accept recorded for the live text, not applied: the recorded-locally line, still exit 8
out=$(tr_ show 12 --require accepted 2>"$T/err"); rc=$?
[ $rc -eq 8 ] && [ -z "$out" ] && [ "$(cat "$T/err")" = "issue #12 is recorded locally as accept but not applied; from your own terminal run python3 \"$S/triage.py\" preview 12, then the apply command with the HASH it prints" ] \
  && ok "T023 REQ-2 accept recorded, not applied (#12): exit 8, stdout empty, exact line" || bad "T023 REQ-2 #12 (rc=$rc, $out, $(cat "$T/err"))"
```
   b. Same file: insert after line 381 `  && echo "$out" | grep -qF "delixcrew-triage: accept $H12 $ISHA12" && ok "REQ-6 apply prints repo, …" || bad "REQ-6 display ($out)"`, before line 382 `out=$(GH_FAIL=all tr_ apply 12 …`:
```bash
# T023 REQ-1 (#34): the word alone is refused with the expected text (the pty merges stdout and stderr, \r\n)
out=$(tty_run "APPLY" python3 "$S/triage.py" apply 12 --confirm "$H12"); rc=$?
[ $rc -eq 6 ] && [ "$(writes)" = 0 ] \
  && printf '%s\n' "$out" | tr -d '\r' | grep -qF "Type APPLY $H12 to apply it (the word APPLY, a space, then the hash): " \
  && printf '%s\n' "$out" | tr -d '\r' | grep -qF "not confirmed: type exactly APPLY $H12 (the word APPLY, a space, then the hash); nothing applied" \
  && ok "T023 REQ-1 APPLY alone on a TTY: exit 6, no gh write call, exact prompt and refusal" || bad "T023 REQ-1 APPLY alone (rc=$rc, $out)"
```
   c. Same file: insert after line 431 `out=$(tr_ apply 99 --confirm 000000000000 </dev/null 2>&1); [ $? -eq 2 ] && ok "apply without record: exit 2" || bad "apply no record ($out)"`, before line 433 `rm -rf "$T"; …`:
```bash
# --- T023 REQ-2 (#35, K181, K190): exit 8 and a local accept record ---------------
D2="$T/tri2"
st 's["issues"]["30"]={"title":"Recorded but not applied","body":"Body.","author":"tahircengiz","state":"OPEN","labels":[],"comments":[]}'
ISHA30=$(field "$(tr_ show 30)" issue-sha)
NOT30="issue #30 is not triaged as accepted; run /delixcrew:triage #30"
CHG30="issue #30 changed since it was accepted; run /delixcrew:triage #30"
NEW30="issue #30 is recorded locally as accept but not applied; from your own terminal run python3 \"$S/triage.py\" preview 30, then the apply command with the HASH it prints"
req2(){ # name, expected stderr (whole, exact)
  out=$(DELIXCREW_TRIAGE_DIR="$D2" tr_ show 30 --require accepted 2>"$T/err"); rc=$?
  [ $rc -eq 8 ] && [ -z "$out" ] && [ "$(cat "$T/err")" = "$2" ] && ok "T023 REQ-2 $1: exit 8, stdout empty, exact line" \
    || bad "T023 REQ-2 $1 (rc=$rc, $out, $(cat "$T/err"))"; }
rec30(){ # name, python mutation of the stored record, expected stderr; the record is restored afterwards
  cp "$D2/30.json" "$T/30.bak"
  python3 -c 'import json,sys; p=sys.argv[1]; d=json.load(open(p)); exec(sys.argv[2]); json.dump(d,open(p,"w"))' "$D2/30.json" "$2"
  req2 "$1" "$3"; cp "$T/30.bak" "$D2/30.json"; }
req2 "no record" "$NOT30"
printf '{"issue_sha":"%s","decision":"accept","reason":"Yes."}' "$ISHA30" | DELIXCREW_TRIAGE_DIR="$D2" tr_ record 30 >/dev/null
req2 "accept recorded for the live text, not applied" "$NEW30"
rec30 "record with an old sha"             'd["issue_sha"]="0123456789ab"'                                  "$NOT30"
rec30 "defer record"                       'd["decision"]="defer"'                                          "$NOT30"
rec30 "applied record, label missing"      'd["status"]="applied"; d["applied_at"]="2026-11-04T00:00:00Z"' "$NOT30"
rec30 "record for another issue (invalid)" 'd["issue"]=31'                                                 "$NOT30"
cp "$D2/30.json" "$T/30.bak"; echo '{broken' > "$D2/30.json"; req2 "record not JSON" "$NOT30"; cp "$T/30.bak" "$D2/30.json"
# K190: second exit 8 branch (label + maintainer marker for an older text), recorded again for the live text
st 's["issues"]["30"]["labels"]=["accepted"]; s["issues"]["30"]["comments"].append({"login":"tahircengiz","assoc":"OWNER","body":"ok\n\ndelixcrew-triage: accept 0123456789ab 0123456789ab"})'
req2 "changed since accepted, recorded again, not applied" "$NEW30"
rec30 "changed since accepted, applied record" 'd["status"]="applied"'          "$CHG30"
rec30 "changed since accepted, old-sha record" 'd["issue_sha"]="0123456789ab"'  "$CHG30"
```
   d. `tests/feedback_tests.sh`: insert after line 171 `  && ok "REQ-6 send prints queue dir, repo and body itself" || bad "REQ-6 send display ($out)"`, before line 173 `# --- REQ-8 send and remote duplicate …`:
```bash
# T023 REQ-1 (#34): the word alone is refused with the expected text (the pty merges stdout and stderr, \r\n)
out=$(tty_run "SEND" python3 "$S/feedback.py" send F002 --confirm "$H"); rc=$?
[ $rc -eq 6 ] && ! grep -q "issue" "$T/gh.log" \
  && printf '%s\n' "$out" | tr -d '\r' | grep -qF "Type SEND $H to send it (the word SEND, a space, then the hash): " \
  && printf '%s\n' "$out" | tr -d '\r' | grep -qF "not confirmed: type exactly SEND $H (the word SEND, a space, then the hash); nothing sent" \
  && ok "T023 REQ-1 SEND alone on a TTY: exit 6, gh not called, exact prompt and refusal" || bad "T023 REQ-1 SEND alone (rc=$rc, $out)"
```
   e. Run `bash tests/triage_tests.sh` and `bash tests/feedback_tests.sh` and see **red**. Expected ✘ lines:
      - triage: 4 (1a; 1b; in 1c, "accept recorded for the live text, not applied" and "changed since accepted, recorded again, not applied");
      - feedback: 1 (1d).
      The other 8 new triage lines already pass: they pin today's messages.
2. **Implement** edits 1–10. Touch only the paths in Files.
3. **Green:** run both test files, then the full loop and `claude plugin validate .`. If an existing line goes ✘, do not edit it: report `NEEDS_CONTEXT` with the output.
4. **Commit** `T023: confirmation prompt says what to type; exit 8 names a recorded but unapplied accept`. Open the PR with `--body-file`; the body has `## How I tested` (commands, ✔/✘ counts).

## Verification command → expected output
- `for t in tests/*_tests.sh; do bash "$t" || exit 1; done` → exit 0; `claude plugin validate .` → passes
- `bash tests/triage_tests.sh | grep -c '^✔ T023'` → `12`; `bash tests/triage_tests.sh | grep -c '^✘'` → `0`; last line `ALL PASSED`
- `bash tests/feedback_tests.sh | grep -c '^✔ T023'` → `1`; last line `ALL PASSED`
- `git diff origin/main -- tests/triage_tests.sh tests/feedback_tests.sh | grep -c '^-[^-]'` → `0`
- `git diff -U0 origin/main -- scripts/triage.py scripts/feedback.py | grep -E '^[-+].*(isatty|readline|args\.confirm)'` → no output
- `grep -n 'Exit 8' skills/start/SKILL.md` → `30:   Exit 8: show only the stderr line, as it is, and stop; it already names the next step. Exit 7: show the message and`
- `git diff --stat origin/main` → only the 7 files in Files

## Review Focus
- Forged record (§6): it changes only the stderr line. Every new REQ-2 test asserts exit 8 and empty stdout; no record path reaches exit 0.
- `load_record` is called only inside the two exit 8 branches. Check this by reading the diff (not tested): `show` without `--require` and the accepted path never read the record.
- The refusal line uses the computed `h`, never the `readline()` text (K180, K139). The comparison, TTY and hash lines stay unchanged: `triage.py:374–380, 387` and `feedback.py:783–789, 794`.
- Implied but not tested:
  - An install path that contains `"`, `$`, a backtick or a control character is printed inside `"…"` as it is. The spec fixes the format: do not escape it; note it in the report if it matters.
  - A closed issue with a matching recorded accept also gets the new line (`show` ignores state).
- SKILL 1a: the agent shows only the line and stops; it does not run `preview` or `apply` itself.
- README and README.tr carry the same content, and every claim matches the code.

## Don'ts
- Do not touch: `scripts/bash_gate.py` and `tests/hook_tests.sh` (T024), `scripts/write_gate.py`, `scripts/stop_gate.py`, `scripts/common.py`, `hooks/**`, `skills/triage/SKILL.md`, `skills/feedback/SKILL.md`, `SECURITY.md`, `CHANGELOG.md`, `site/**`, `.claude-plugin/**`, `.github/**`, `docs/delix/**`, any other `tests/*` file.
- Do not change or delete any existing test line. If a test looks wrong, stop: `NEEDS_CONTEXT`.
- No quotes around `APPLY <h>`/`SEND <h>`, no echo of the typed line, no case folding, no hash-only match (K180).
- Do not change the two existing exit 8 strings, exit codes, or the README "Remaining risk" paragraphs (`README.md:311–315`, `README.tr.md:311–315`; §2, §8).
- Do not run ad-hoc Bash commands whose text has `triage.py`/`feedback.py` with `apply`/`send`/`script`/`expect`/`unbuffer`/`pty.spawn`: the live hook denies them. Exercise the scripts only through the test files.
- No new dependency.

## Report contract
`.delix/report.md` (≤ 1.5K tokens): `DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED` · commands + output (✔/✘ counts per file) · PR number · assumptions. Read only this card and SPEC REQ-1, REQ-2, §4, §6, §9.

## Review findings (filled by the lead)
- Round 1: …
