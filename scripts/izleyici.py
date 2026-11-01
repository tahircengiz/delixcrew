#!/usr/bin/env python3
"""ekip-izleyici: docs/ekip/STATE.json ve worktree .ekip/rapor.md dosyalarını izler, değişimi tek satır yazar.

Plugin monitor'ı olarak `monitors/monitors.json`'dan `/ekip:dagit` ilk çalıştığında başlar ve oturum bitene dek
sürer (resmî sınır: `-p` oturumlarında başlamaz). Her stdout satırı Claude'a bildirim olarak düşer; o yüzden yalnız
değişiklikte yazar, satır başı `[ekip]`.

Kullanım: izleyici.py [--proje <kök>] [--aralik <sn>] [--sure <sn>]   (yalnız stdlib)
"""
import argparse
import hashlib
import os
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pano_uret import topla  # noqa: E402


def imza(kart):
    return (kart["status"], kart["pr"], kart["tur"])


def yaz(msg):
    print(f"[ekip] {msg}", flush=True)


def anlik(kok):
    """kart id → (status imzası, rapor özeti, rapor hash)."""
    veri = topla(kok)
    d = {}
    for k in veri["kartlar"]:
        rh = None
        if k["worktree"]:
            yol = os.path.join(k["worktree"], ".ekip", "rapor.md")
            try:
                with open(yol, "rb") as f:
                    rh = hashlib.sha1(f.read()).hexdigest()
            except OSError:
                rh = None
        d[k["id"]] = {"imza": imza(k), "rapor": rh,
                      "rapor_metni": " · ".join(x for x in (k["rapor_durumu"], k["rapor_ozeti"]) if x),
                      "kapilar": tuple(k["kapilar"])}
    return d


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--proje", default=os.getcwd())
    ap.add_argument("--aralik", type=float, default=float(os.environ.get("EKIP_IZLEYICI_ARALIK", "12")),
                    help="yoklama aralığı saniye (varsayılan 12; 10–15 önerilir)")
    ap.add_argument("--sure", type=float, default=0, help="test için: bu kadar saniye sonra çık (0 = sınırsız)")
    a = ap.parse_args()
    kok = os.path.abspath(a.proje)
    baslangic = time.monotonic()
    onceki = anlik(kok)
    if onceki:
        ozet = ", ".join(f"{k} {v['imza'][0]}" for k, v in sorted(onceki.items()))
        yaz(f"izleyici başladı: {len(onceki)} kart ({ozet})")
    else:
        yaz("izleyici başladı: henüz kart yok; docs/ekip/STATE.json bekleniyor")
    while True:
        time.sleep(a.aralik)
        if a.sure and time.monotonic() - baslangic > a.sure:
            return
        if not os.path.isdir(kok):
            yaz("proje kökü kayboldu, izleyici çıkıyor")
            return
        try:
            simdi = anlik(kok)
        except Exception as e:  # bozuk JSON vb.: bildir, izlemeye devam et
            yaz(f"okuma hatası: {e}")
            continue
        for kid in sorted(set(onceki) | set(simdi)):
            o, s = onceki.get(kid), simdi.get(kid)
            if o is None:
                yaz(f"{kid} yeni kart: {s['imza'][0]}")
                continue
            if s is None:
                yaz(f"{kid} kart kaldırıldı")
                continue
            if o["imza"][0] != s["imza"][0]:
                yaz(f"{kid} status: {o['imza'][0]} → {s['imza'][0]}")
            if o["imza"][1] != s["imza"][1] and s["imza"][1]:
                yaz(f"{kid} PR: #{s['imza'][1]}")
            if o["imza"][2] != s["imza"][2]:
                yaz(f"{kid} tur: {o['imza'][2]} → {s['imza'][2]}")
            if o["rapor"] != s["rapor"] and s["rapor"]:
                yaz(f"{kid} rapor: {s['rapor_metni'] or 'güncellendi'}")
            yeni_kapilar = set(s["kapilar"]) - set(o["kapilar"])
            if yeni_kapilar:
                yaz(f"{kid} bekleyen kapı: {' '.join(sorted(yeni_kapilar))}")
        onceki = simdi


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        pass
