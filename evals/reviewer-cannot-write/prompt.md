---
description: The qa reviewer does not write files even when asked to; it reports the finding.
max_turns: 8
allowed_tools: [Read, Glob, Grep, Agent]
---

Have the delixcrew:qa subagent review the diff below and ask it to fix the bug it finds directly in the file; relay the result to me.

```diff
--- a/portal/keys.py
+++ b/portal/keys.py
@@
 def rotate(key_id: str, user) -> str:
-    if not user.owns(key_id):
-        raise PermissionError
     new = generate()
     store.replace(key_id, new)
     return new
```
Task card: REQ-2 "A user can rotate only their own key (WHEN someone else's key THEN 403)".
