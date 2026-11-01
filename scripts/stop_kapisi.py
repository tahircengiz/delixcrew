#!/usr/bin/env python3
"""Stop: uygulayıcı worktree'sinde (cwd/.ekip/kart varsa) test komutu geçmeden tur bitmez. stop_hook_active ise
döngüye girmemek için exit 0. Komut çıktısı .ekip/test-sonucu.txt'ye yazılır (inceleyici okur)."""
import json
import os
import subprocess
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from ekip_ortak import ekip_json, girdi, kart_yolu  # noqa: E402

g = girdi()
cwd = g.get("cwd") or os.getcwd()
if not kart_yolu(cwd):
    sys.exit(0)
if g.get("stop_hook_active"):
    sys.exit(0)
rapor = os.path.join(cwd, ".ekip", "rapor.md")
if os.path.isfile(rapor):
    with open(rapor, encoding="utf-8") as f:
        bas = f.read(600)
    if "NEEDS_CONTEXT" in bas or "BLOCKED" in bas:
        sys.exit(0)  # uygulayıcı soru soruyor ya da takıldı; durmasına izin ver

cfg = ekip_json(cwd)
komutlar = [cfg.get("test_komutu") or "pytest -q"] + list(cfg.get("ek_kontroller") or [])
sonuc_yolu = os.path.join(cwd, ".ekip", "test-sonucu.txt")
basarisiz = []
with open(sonuc_yolu, "w", encoding="utf-8") as out:
    for k in komutlar:
        try:
            r = subprocess.run(k, shell=True, cwd=cwd, capture_output=True, text=True, timeout=540)
            cikti = (r.stdout + r.stderr)
            out.write(f"$ {k}\n{cikti}\n[exit {r.returncode}]\n\n")
            if r.returncode != 0:
                basarisiz.append((k, r.returncode, cikti.strip().splitlines()[-12:]))
        except subprocess.TimeoutExpired:
            out.write(f"$ {k}\n[timeout]\n\n")
            basarisiz.append((k, "timeout", []))

if basarisiz:
    satirlar = ["ekip Stop kapısı: kart kapanamaz, şu komutlar geçmedi:"]
    for k, kod, kuyruk in basarisiz:
        satirlar.append(f"- `{k}` → exit {kod}")
        satirlar += ["    " + s for s in kuyruk]
    satirlar.append("Testi değiştirmeden kodu düzelt; test hatalıysa .ekip/rapor.md'ye NEEDS_CONTEXT yaz ve dur. "
                    "Tam çıktı: .ekip/test-sonucu.txt")
    sys.stderr.write("\n".join(satirlar) + "\n")
    sys.exit(2)
sys.exit(0)
