#!/usr/bin/env bash
# REQ-6 (K129): write_gate.py compares the feedback queue and triage dirs case- and NFD-insensitively.
# Run: bash tests/write_gate_case_tests.sh
set -u
unset DELIXCREW_FEEDBACK_DIR DELIXCREW_TRIAGE_DIR
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; S="$ROOT/scripts"; FAIL=0
T="$(mktemp -d)"; N="$T/nocard"; mkdir -p "$N" "$T/home"
FBMSG="delixcrew: feedback is sent only by the user from their own terminal"
TQMSG="delixcrew: triage decisions are applied only by the user from their own terminal"
# macOS bash 3.2 has no $'\u…': build the NFC / NFD names with python3
NFC=$(python3 -c 'print("Masaüstü")'); NFD=$(python3 -c 'print("Masaüstü")')
UPC=$(python3 -c 'print("MASAÜSTÜ")')
wjson(){ # tool, file_path → hook JSON (cwd without .delix/card)
  python3 -c 'import json,sys; print(json.dumps({"tool_name":sys.argv[1],"cwd":sys.argv[2],"tool_input":{"file_path":sys.argv[3]}}))' "$1" "$N" "$2"; }
gdeny(){ # name, message, json, env… → deny with the exact message
  name=$1; msg=$2; js=$3; shift 3
  out=$(echo "$js" | env HOME="$T/home" "$@" python3 "$S/write_gate.py")
  if echo "$out" | grep -q '"permissionDecision": "deny"' && echo "$out" | grep -qF "$msg"; then echo "✔ $name"; else echo "✘ $name (expected deny): $out"; FAIL=1; fi; }
gallow(){ # name, json, env… → rc 0, no deny
  name=$1; js=$2; shift 2
  out=$(echo "$js" | env HOME="$T/home" "$@" python3 "$S/write_gate.py"); rc=$?
  if [ $rc -eq 0 ] && ! echo "$out" | grep -q deny; then echo "✔ $name"; else echo "✘ $name (expected allow): rc=$rc $out"; FAIL=1; fi; }

gdeny  "1 upper-case FEEDBACK dir (default ~)"  "$FBMSG" "$(wjson Write "$T/home/.claude/delixcrew/FEEDBACK/F001.json")"
gdeny  "2 mixed case literal ~ path"            "$FBMSG" "$(wjson Edit "~/.Claude/DelixCrew/feedback/config.json")"
gdeny  "3 feedback env NFC, target NFD"         "$FBMSG" "$(wjson Write "$T/$NFD/fb/F001.json")" DELIXCREW_FEEDBACK_DIR="$T/$NFC/fb"
gdeny  "4 feedback env NFD, target NFC"         "$FBMSG" "$(wjson Write "$T/$NFC/fb/F001.json")" DELIXCREW_FEEDBACK_DIR="$T/$NFD/fb"
gdeny  "5 triage env NFC, target NFD"           "$TQMSG" "$(wjson Write "$T/$NFD/tq/12.json")"   DELIXCREW_TRIAGE_DIR="$T/$NFC/tq"
gdeny  "6 triage env NFD, target NFC upper"     "$TQMSG" "$(wjson Edit "$T/$UPC/TQ/12.json")"    DELIXCREW_TRIAGE_DIR="$T/$NFD/tq"
gallow "7 neighbour feedback-notes.md is free"  "$(wjson Write "~/.claude/delixcrew/feedback-notes.md")"
gallow "8 lookalike fbx dir is free"            "$(wjson Write "$T/$NFC/fbx/F001.json")" DELIXCREW_FEEDBACK_DIR="$T/$NFC/fb"

rm -rf "$T"
[ $FAIL -eq 0 ] && echo "ALL PASSED" || { echo "FAILED"; exit 1; }
