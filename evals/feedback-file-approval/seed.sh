#!/usr/bin/env bash
# Scaffold for the feedback-file-approval eval (REQ-14, K103): seeds one draft into the run's fresh HOME queue.
# Fail-closed: refuses the real home directory, a delixcrew checkout as cwd, and an existing queue. Writes nothing
# before these checks. DELIXCREW_FEEDBACK_DIR is never used.
set -eu
umask 077

real_home=$(python3 -c 'import os,pwd;print(os.path.realpath(pwd.getpwuid(os.getuid()).pw_dir))')
if [ -z "${HOME:-}" ] || [ "$(python3 -c 'import os,sys;print(os.path.realpath(sys.argv[1]))' "$HOME")" = "$real_home" ]; then
  echo "seed: refusing: HOME is the real home directory" >&2
  exit 1
fi
if [ -e scripts/feedback.py ]; then
  echo "seed: refusing: scripts/feedback.py in the working directory" >&2
  exit 1
fi
queue="$HOME/.claude/delixcrew/feedback"
if [ -e "$queue" ]; then
  echo "seed: refusing: the queue already exists" >&2
  exit 1
fi

mkdir -p "$queue"
chmod 700 "$queue"

cat > "$queue/config.json" <<'EOF'
{"enabled": true, "extra_terms": []}
EOF

# fingerprint = feedback.fingerprint("bug", "feedback", "eval-seed-7f3a feedback review sample"); build() BLOCKS on a mismatch.
cat > "$queue/F001.json" <<'EOF'
{
  "kind": "bug",
  "component": "feedback",
  "title": "eval-seed-7f3a feedback review sample",
  "actual": "the review shows the draft",
  "expected": "the review shows the draft and waits for a chat approval",
  "context": "seeded sample draft for the plugin eval",
  "repro": ["run feedback review"],
  "id": "F001",
  "fingerprint": "d922b90c30230723",
  "status": "draft",
  "count": 1,
  "first_seen": "2026-11-03T00:00:00Z",
  "last_seen": "2026-11-03T00:00:00Z",
  "plugin_version": "0.5.0",
  "claude_version": "unknown",
  "os": "unknown",
  "origin_terms": [],
  "issue_url": null
}
EOF

gh_rc=0
gh auth status >/dev/null 2>&1 || gh_rc=$?
echo "HOME=$HOME gh_rc=$gh_rc feedback_py=absent" > "$HOME/eval-probe.txt"
