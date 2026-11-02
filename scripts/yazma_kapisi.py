#!/usr/bin/env python3
"""PreToolUse (Write|Edit|MultiEdit|NotebookEdit): inceleyici roller yazamaz; uygulayıcı kart dosyasına ve
docs/ekip/**'ye yazamaz; korunan yola yalnız kartın Files listesinde ve kartta 🔐 Onay satırı varsa, var olan test
dosyasına yalnız Files listesindeyse yazar (yeni test dosyası serbest); cwd (worktree) dışına hiç yazamaz (A13).
Uygulayıcı kapısı yalnız cwd/.ekip/kart varsa aktif."""
import os
import re
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

kart = kart_yolu(cwd)
ONAY = re.compile(r"^\*\*🔐 Onay:\*\* \d{4}-\d{2}-\d{2} \S+", re.M)


def kart_oku():
    """(Files listesindeki yollar, onay var mı). Files: '## Files' sonrası ilk '## ' başlığına kadar backtick içi yollar
    (parantezli açıklama ve ':satır' atılır). Onay: ilk '## ' başlığından önceki başlık alanında tek satır."""
    try:
        with open(os.path.join(cwd, kart), encoding="utf-8") as f:
            metin = f.read()
    except OSError:
        return [], False
    bas = metin.split("\n## ", 1)[0]
    m = re.search(r"^## Files\b.*?$(.*?)(?=^## |\Z)", metin, re.M | re.S)
    yollar = []
    for satir in (m.group(1) if m else "").splitlines():
        for y in re.findall(r"`([^`]+)`", re.sub(r"\([^)]*\)", "", satir)):
            y = y.split(":", 1)[0].strip()
            if y:
                yollar.append(y)
    return yollar, bool(ONAY.search(bas))


def cwd_disi(yol):
    """Yol cwd'nin (worktree) dışına çıkıyor mu? Sembolik bağlar (/tmp → /private/tmp) için realpath."""
    kok = os.path.realpath(cwd)
    hedef = os.path.realpath(os.path.join(cwd, yol))
    return os.path.commonpath([kok, hedef]) != kok


cfg = ekip_json(cwd)
ti = g.get("tool_input") or {}
yol = ti.get("file_path") or ti.get("notebook_path") or ""
korunan = cfg.get("korunan_yollar") or []
test_yollari = cfg.get("test_yollari") or ["tests/**"]

if yol and cwd_disi(yol):
    deny(f"ekip: '{yol}' worktree'nin ({cwd}) dışında; uygulayıcı yalnız kendi worktree'sine yazar (A13). Yolu cwd'ye "
         f"göre kur; dosya gerçekten başka yerdeyse raporda NEEDS_CONTEXT yaz.")

if eslesir(yol, ["docs/ekip/**", kart], cwd):
    deny(f"ekip: '{yol}' kart ya da docs/ekip altında; uygulayıcı bunları değiştiremez. Gerekiyorsa raporda "
         f"NEEDS_CONTEXT ile açıkla, orkestratör günceller.")

files, onay = kart_oku()
listede = bool(eslesir(yol, files, cwd))

d = eslesir(yol, korunan, cwd)
if d:
    if listede and onay:
        sys.exit(0)  # Kademe 3: kartta listeli ve insan onaylı
    neden = "" if listede else " Yol kartın Files listesinde yok."
    if not onay:
        neden += " Kartta 🔐 Onay satırı yok."
    deny(f"ekip: '{yol}' korunan yol ({d}, Kademe 3). Bu kart bu yola dokunamaz;{neden} Raporda BLOCKED/NEEDS_CONTEXT "
         f"ile açıkla, orkestratör insan onayı alır.")

if eslesir(yol, test_yollari, cwd) and not listede:
    tam = os.path.abspath(os.path.join(cwd, yol))
    tool = g.get("tool_name") or ""
    if tool == "Write" and not os.path.exists(tam):
        sys.exit(0)  # yeni test dosyası serbest
    deny(f"ekip: mevcut test dosyası '{yol}' değiştirilemez (test zayıflatma yasağı). Yeni test için yeni dosya ya da "
         f"yeni fonksiyon ekle; test hatalı görünüyorsa dur ve raporda NEEDS_CONTEXT yaz.")
sys.exit(0)
