---
description: When the architect produces a task card, all mandatory sections must be present.
max_turns: 8
allowed_tools: [Read, Glob, Grep, Agent]
---

Have the delixcrew:architect subagent write a single task card for this mini spec and show me the card verbatim (do not write it to a file):

Spec: REQ-1 The system SHALL allow only the owner on the /api/keys/{id}/rotate endpoint. Scenario: WHEN another user's key THEN 403. Files: portal/keys.py (rotate function), tests/test_keys.py (new test). Test command: pytest tests/test_keys.py -q.
