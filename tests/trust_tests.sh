#!/usr/bin/env bash
# Issue #8: a repo that ships its own .delix/card must not switch the hooks on (the Stop gate would run the repo's
# delix.json commands). The card counts only as a local, untracked file in a git work tree. Run: bash tests/trust_tests.sh
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; S="$ROOT/scripts"; FAIL=0
T="$(mktemp -d)"
G="git -c user.email=t@t -c user.name=t -c commit.gpgsign=false"
mkrepo(){ # dir → repo whose delix.json test_command touches $1/MARK (the "attacker command")
  mkdir -p "$1/docs/delix"
  printf '{"test_command":"touch %s/MARK","extra_checks":[]}' "$1" > "$1/docs/delix/delix.json"; }
stop(){ printf '{"cwd":"%s","stop_hook_active":false}' "$1" | python3 "$S/stop_gate.py" 2>"$1.err"; }
ran(){ [ -e "$1/MARK" ]; }
ok(){ echo "✔ $1"; }; ko(){ echo "✘ $1"; FAIL=1; }

# 1) Foreign repo: .delix/card committed together with delix.json (git clone delivers both)
R="$T/foreign"; mkrepo "$R"; mkdir -p "$R/.delix"; echo "docs/delix/tasks/T001-x.md" > "$R/.delix/card"
git -C "$R" init -q && $G -C "$R" add -A && $G -C "$R" commit -qm x
stop "$R"; rc=$?
ran "$R" && ko "tracked card: repo command ran" || ok "tracked card: repo command not run"
[ $rc -eq 0 ] && ok "tracked card: Stop exits 0" || ko "tracked card: Stop exit $rc"
[ "$(wc -l < "$R.err")" -eq 1 ] && grep -q '^delixcrew: ' "$R.err" && ok "tracked card: one stderr line" || ko "tracked card: stderr: $(cat "$R.err")"
out=$(printf '{"tool_name":"Edit","cwd":"%s","tool_input":{"file_path":"docs/delix/delix.json"}}' "$R" | python3 "$S/write_gate.py" 2>/dev/null)
echo "$out" | grep -q deny && ko "tracked card: write gate active" || ok "tracked card: write gate inactive"

# 2) Foreign repo: committed symlink .delix → a dir holding a committed 'card' (git sees no .delix/card)
R="$T/symlink"; mkrepo "$R"; mkdir -p "$R/docs/x"; echo "docs/delix/tasks/T001-x.md" > "$R/docs/x/card"; ln -s docs/x "$R/.delix"
git -C "$R" init -q && $G -C "$R" add -A && $G -C "$R" commit -qm x
stop "$R"; ran "$R" && ko "symlinked .delix: repo command ran" || ok "symlinked .delix: repo command not run"

# 3) Not a git work tree (archive download): card is not trusted
R="$T/archive"; mkrepo "$R"; mkdir -p "$R/.delix"; echo "docs/delix/tasks/T001-x.md" > "$R/.delix/card"
stop "$R"; ran "$R" && ko "no git: repo command ran" || ok "no git: repo command not run"

# 4) Normal dispatch: delix.json committed, .delix/ written locally and excluded (.git/info/exclude) → gate runs
R="$T/worktree"; mkrepo "$R"; git -C "$R" init -q && $G -C "$R" add -A && $G -C "$R" commit -qm x
echo ".delix/" >> "$R/.git/info/exclude"; mkdir -p "$R/.delix"; echo "docs/delix/tasks/T001-x.md" > "$R/.delix/card"
stop "$R"; rc=$?
ran "$R" && ok "local card: Stop gate runs the test command" || ko "local card: test command not run"
[ $rc -eq 0 ] && ok "local card: passing command → exit 0" || ko "local card: Stop exit $rc"
out=$(printf '{"tool_name":"Edit","cwd":"%s","tool_input":{"file_path":"docs/delix/delix.json"}}' "$R" | python3 "$S/write_gate.py" 2>/dev/null)
echo "$out" | grep -q deny && ok "local card: write gate active" || ko "local card: write gate inactive"

# 5) Foreign repo: case variant .Delix/card (case-insensitive file systems see it as .delix/card; git pathspecs do not)
R="$T/case"; mkrepo "$R"; mkdir -p "$R/.Delix"; echo "docs/delix/tasks/T001-x.md" > "$R/.Delix/card"
git -C "$R" init -q && $G -C "$R" add -A && $G -C "$R" commit -qm x
stop "$R"; ran "$R" && ko "case variant .Delix: repo command ran" || ok "case variant .Delix: repo command not run"

# 6) Foreign repo: submodule at .delix whose repo holds 'card' (superproject index only has the gitlink)
M="$T/subsrc"; mkdir -p "$M"; echo "docs/delix/tasks/T001-x.md" > "$M/card"
git -C "$M" init -q && $G -C "$M" add -A && $G -C "$M" commit -qm x
R="$T/submodule"; mkrepo "$R"; git -C "$R" init -q
$G -C "$R" -c protocol.file.allow=always submodule add -q "$M" .delix 2>/dev/null && $G -C "$R" add -A && $G -C "$R" commit -qm x
[ -f "$R/.delix/card" ] || ko "submodule fixture not built"
stop "$R"; ran "$R" && ko "submodule .delix: repo command ran" || ok "submodule .delix: repo command not run"

# 7) Archive extracted inside another git repo: git walks up to the parent, where .delix/card is untracked
P="$T/parent"; mkdir -p "$P"; git -C "$P" init -q
R="$P/vendor/pkg"; mkrepo "$R"; mkdir -p "$R/.delix"; echo "docs/delix/tasks/T001-x.md" > "$R/.delix/card"
stop "$R"; ran "$R" && ko "archive inside a parent repo: repo command ran" || ok "archive inside a parent repo: repo command not run"

rm -rf "$T"; [ $FAIL -eq 0 ] && echo "ALL PASSED" || { echo "FAILED"; exit 1; }
