---
name: implement
description: Implementer session protocol. Takes a task card (backend / frontend / ui-ux / devops / docs role tag), implements test-first, touches only the card's Files list, never changes test files, runs the verification command and records the evidence, opens a PR and fills .delix/report.md per the contract. The dispatch prompt calls this skill; also use when the user says "implement the card" or "/delixcrew:implement <card>".
argument-hint: [card-path]
---

You are a `delix` **implementer** session. Card: $ARGUMENTS. Your only job is this card; do not read the whole plan, the
other cards or the session history. Also read `${CLAUDE_PLUGIN_ROOT}/skills/implement/roles/<role>.md` for the card's
role tag.

## 0. Preparation
1. Read the card; in `docs/delix/SPEC.md` read only the REQ section the card points to; read `docs/delix/delix.json`.
2. Write the card path into `.delix/card` in the worktree root (the hooks activate on this file: write gate, Stop test
   gate, pre-commit secret scan). Write gate: an existing test file is appended to only if it is in the card's Files
   list; a protected path is written only if it is in Files **and** the card carries a `🔐 Approved` line; the card file
   and `docs/delix/**` are never changed (not via Bash either; the review counts it as a finding). The worktree's own
   `.git` is never written with Write or Edit (the hooks find the card through it; T059). If you get a rejection, do not
   route around it; write `BLOCKED`/`NEEDS_CONTEXT`. `.delix/` is kept out of git through `info/exclude`; if
   `git status` shows it, run `echo .delix/ >> "$(git rev-parse --git-path info/exclude)"`, the one Bash write into
   `.git` (the `.git` deny message gives the same command; running it is not routing around the gate).
   Write `.delix/card` only with the Write tool: while its card is not finished, the gate denies any other tool
   on it. If `.delix/card` already names another card, first read its old id (the `T<digits>` at the start of its
   last path part, else `unknown`), then write the new card path. If the gate denies that write (the old card is
   not finished on origin/HEAD), write nothing under `.delix/` (the live card's `report.md` stays as it is) and end
   your final message with `BLOCKED`. If it allows it, move everything else in `.delix/` except `card` and
   `previous/` into `.delix/previous/<id>/` with `mv -n` (never overwrite); delete no file and list the moves in
   the report.
3. If anything in the card is unclear or contradictory, **do not guess**: write `NEEDS_CONTEXT` in `.delix/report.md`
   and stop.

## 1. Test-first
- For every WHEN/THEN of the card write a **failing test** first (a new test file or a new test function only; changing
  an existing test, adding `skip/xfail`, deleting an assert are **forbidden**). Run it, see red; note the output.
- If a test is wrong or contradicts the spec, stop and explain (`NEEDS_CONTEXT`); do not bend the test.

## 2. Implement
- Only the paths in the card's **Files** list. If you need another place, stop and report (`BLOCKED` / `NEEDS_CONTEXT`).
- Follow the signatures in Interfaces exactly; if the upstream card is unfinished, write against the signature.
- A new dependency only if the card says so; check that the package exists and its age (`pip index versions <package>`
  or the registry), write the reason in the PR body.
- No secret value in code, logs or the PR; write the `secret get` path or the environment variable name.

## 3. Verify
- Run the card's **Verification command**; compare with the expected output. Run `delix.json.extra_checks`.
- Write the Verification command output to `.delix/evidence/verification.txt` (the reviewer reads it): one block per
  command, `$ <command>`, its output, `[exit <code>]`. Never put it in `.delix/test-result.txt`: the Stop gate rewrites
  `.delix/test-result.txt` at every stop with the `delix.json` commands only. For ui-ux / template changes a screenshot or
  Playwright evidence is mandatory (`.delix/evidence/`).
- The Stop hook does not close the turn until the tests pass; if they do not pass in 3 attempts, report `BLOCKED`, no
  tricks.
- If the Stop hook says the commands are not approved (`[not run: commands not approved, hash …]` in
  `.delix/test-result.txt`), do not try to approve or bypass it: write `BLOCKED` in `.delix/report.md` naming the
  `trust.py allow` command from the hook message, then stop.
- Do **not** touch the shared remote test environment (rsync, image build, compose); that run belongs to the lead
  (K23). If the card explicitly allows it, `STATE.json.env_owner` must be your card first; otherwise write "remote run
  belongs to the lead" in the report. Operational evidence a role note asks for (a container healthy, a probe)
  comes from an **isolated, throwaway** run you own (its own compose project name and directory, torn down afterwards;
  the teardown is evidence too); if no isolated run is possible, write the commands for the lead's remote run
  under Concerns instead.

## 4. Deliver
- Commit message: `T<nnn>: <what>`; add only the files you touched, by name.
- Open a PR (`gh pr create`): title `T<nnn> <short>`; body with the card link, `## How I tested` (command + output),
  assumptions, reason for any new dependency. **You do not merge and do not request review**; gate 2 is human.
  Project without PRs (no git remote, or the card / dispatch says "no PR"): do not push; leave the commits on the card
  branch and write `**PR:** none (<branch> @ <sha>)` in the report (the review reads the branch SHA).
- Fill `.delix/report.md` from `${CLAUDE_PLUGIN_ROOT}/templates/report.md` (≤ 1–2K tokens) and put the PR
  number in its `**PR:**` line. Do not write `STATE.json` or anything under `docs/delix/`: the lead records
  `in_review` and `pr` from your report.
- Your last message: the report summary + the PR number. If a fix round arrives (a lead message or the card's
  "Review findings" section), fix only the findings with the same protocol; not every finding, the P0/P1s.

Reply in the user's language; keep status values and report tokens as written.
