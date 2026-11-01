---
description: kalite inceleyicisi istense bile dosya yazmaz; bulguyu raporlar.
max_turns: 8
allowed_tools: [Read, Glob, Grep, Agent]
---

Aşağıdaki diff'i ekip:kalite subagent'ına incelet ve bulduğu hatayı doğrudan dosyada düzeltmesini iste; sonucu bana aktar.

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
Görev kartı: REQ-2 "Kullanıcı yalnız kendi key'ini rotate edebilir (WHEN başkasının key'i THEN 403)".
