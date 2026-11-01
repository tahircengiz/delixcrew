#!/usr/bin/env python3
"""PreToolUse (Write|Edit|MultiEdit|NotebookEdit): inceleyici roller yazamaz; uygulayıcı korunan yola ve test
dosyasına (yeni test dosyası hariç) yazamaz. Uygulayıcı kapısı yalnız cwd/.ekip/kart varsa aktif."""
import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from ekip_ortak import INCELEYICILER, deny, ekip_json, eslesir, girdi, kart_yolu  # noqa: E402

g = girdi()
agent = (g.get("agent_type") or "").strip()
if agent in INCELEYICILER:
    deny(f"ekip: '{agent}' rolü salt-okunurdur; dosya yazamaz. Bulguyu raporuna yaz, orkestratör uygular.")

cwd = g.get("cwd") or os.getcwd()
if not kart_yolu(cwd):
    sys.exit(0)  # uygulayıcı oturumu değil, pasif

cfg = ekip_json(cwd)
ti = g.get("tool_input") or {}
yol = ti.get("file_path") or ti.get("notebook_path") or ""
korunan = cfg.get("korunan_yollar") or []
test_yollari = cfg.get("test_yollari") or ["tests/**"]

d = eslesir(yol, korunan, cwd)
if d:
    deny(f"ekip: '{yol}' korunan yol ({d}, Kademe 3). Bu kart bu yola dokunamaz; raporda BLOCKED/NEEDS_CONTEXT ile "
         f"açıkla, orkestratör insan onayı alır.")

if eslesir(yol, test_yollari, cwd):
    tam = os.path.abspath(os.path.join(cwd, yol))
    tool = g.get("tool_name") or ""
    if tool == "Write" and not os.path.exists(tam):
        sys.exit(0)  # yeni test dosyası serbest
    deny(f"ekip: mevcut test dosyası '{yol}' değiştirilemez (test zayıflatma yasağı). Yeni test için yeni dosya ya da "
         f"yeni fonksiyon ekle; test hatalı görünüyorsa dur ve raporda NEEDS_CONTEXT yaz.")
sys.exit(0)
