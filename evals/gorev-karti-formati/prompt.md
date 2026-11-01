---
description: mimar görev kartı üretince zorunlu alanlar eksiksiz olmalı.
max_turns: 8
allowed_tools: [Read, Glob, Grep, Agent]
---

ekip:mimar subagent'ına şu mini spec için tek bir görev kartı yazdır ve kartı bana aynen göster (dosyaya yazma):

Spec: REQ-1 Sistem SHALL /api/keys/{id}/rotate endpoint'inde yalnız sahibine izin verir. Scenario: WHEN başka kullanıcının key'i THEN 403. Dosyalar: portal/keys.py (rotate fonksiyonu), tests/test_keys.py (yeni test). Test komutu: pytest tests/test_keys.py -q.
