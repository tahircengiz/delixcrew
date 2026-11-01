#!/usr/bin/env python3
"""ekip panosu: docs/ekip/STATE.json + kartlar + worktree .ekip/rapor.md → tek Markdown tablo.

Kullanım (proje kökünde):
    python3 pano_uret.py             # tabloyu stdout'a basar (dosya yazmaz)
    python3 pano_uret.py --dosya     # ayrıca docs/ekip/PANO.md'yi yeniden üretir (retro A8: varsayılan kapalı)
    python3 pano_uret.py --json      # ham veri (testler için)
    python3 pano_uret.py --proje <kök>

Yalnız stdlib. Salt-okunur: yalnız --dosya ile docs/ekip/PANO.md yazar. Ajan panodan komut almaz (spec §14).
"""
import argparse
import datetime as dt
import json
import os
import re
import subprocess
import sys

DURUM_RE = re.compile(r"\*\*Durum:\*\*\s*([A-Z_]+)")
PR_RE = re.compile(r"\*\*PR:\*\*\s*#?(\d+)")
RAPOR_DURUMLARI = ("DONE_WITH_CONCERNS", "DONE", "NEEDS_CONTEXT", "BLOCKED")
ACIK_STATUSLER = {"acik", "suruyor", "incelemede", "duzeltme"}


def oku(yol):
    try:
        with open(yol, encoding="utf-8") as f:
            return f.read()
    except OSError:
        return None


def json_oku(yol):
    m = oku(yol)
    if m is None:
        return None
    try:
        return json.loads(m)
    except ValueError as e:
        print(f"uyarı: {yol} JSON değil ({e})", file=sys.stderr)
        return None


def worktreeler(kok):
    """`git worktree list --porcelain` → [(yol, dal)]. Git yoksa ya da repo değilse boş liste."""
    try:
        cp = subprocess.run(["git", "worktree", "list", "--porcelain"], cwd=kok,
                            capture_output=True, text=True, timeout=10)
    except (OSError, subprocess.TimeoutExpired):
        return []
    if cp.returncode != 0:
        return []
    sonuc, yol, dal = [], None, ""
    for satir in cp.stdout.splitlines() + [""]:
        if satir.startswith("worktree "):
            yol, dal = satir[len("worktree "):], ""
        elif satir.startswith("branch "):
            dal = satir[len("branch "):].replace("refs/heads/", "")
        elif satir == "" and yol:
            sonuc.append((yol, dal))
            yol = None
    return sonuc


def rapor_ozeti(metin):
    """rapor.md → (durum, pr, tek satır özet)."""
    durum = None
    m = DURUM_RE.search(metin)
    if m:
        durum = m.group(1)
    else:
        for d in RAPOR_DURUMLARI:  # serbest biçim: 'NEEDS_CONTEXT: kart belirsiz'
            if d in metin:
                durum = d
                break
    pr = None
    m = PR_RE.search(metin)
    if m:
        pr = int(m.group(1))
    # özet: Çekinceler / kalan iş bölümünün ilk dolu maddesi, yoksa Kanıt'ın ilki, yoksa ilk düz satır
    ozet = ""
    for baslik in ("## Çekinceler", "## Kanıt"):
        i = metin.find(baslik)
        if i < 0:
            continue
        for satir in metin[i:].splitlines()[1:]:
            s = satir.strip()
            if s.startswith("## "):
                break
            if s.startswith("- ") and s[2:].strip() not in ("", "…", "..."):
                ozet = s[2:].strip()
                break
        if ozet:
            break
    if not ozet:
        for satir in metin.splitlines():
            s = satir.strip()
            if s and not s.startswith("#") and not s.startswith("**"):
                ozet = s
                break
    ozet = re.sub(r"\s+", " ", ozet).replace("|", "/")
    if len(ozet) > 70:
        ozet = ozet[:67].rstrip() + "…"
    return durum, pr, ozet


def kart_dosyasindan(metin):
    """Görev kartının başındaki tablo satırından rol/kademe/wave/status (STATE eksikse yedek)."""
    for satir in metin.splitlines():
        if satir.startswith("| T") and satir.count("|") >= 7:
            h = [x.strip() for x in satir.strip("|").split("|")]
            return {"rol": h[3], "kademe": h[2], "wave": h[4], "status": h[5]}
    return {}


def topla(kok):
    ekip = os.path.join(kok, "docs", "ekip")
    state = json_oku(os.path.join(ekip, "STATE.json")) or {}
    kartlar = dict(state.get("kartlar") or {})
    tasks = os.path.join(ekip, "tasks")
    if os.path.isdir(tasks):
        for ad in sorted(os.listdir(tasks)):
            m = re.match(r"(T\d{3})-.*\.md$", ad)
            if not m:
                continue
            kid = m.group(1)
            metin = oku(os.path.join(tasks, ad)) or ""
            yedek = kart_dosyasindan(metin)
            k = kartlar.setdefault(kid, {})
            k.setdefault("dosya", os.path.join("docs", "ekip", "tasks", ad))
            for alan in ("rol", "kademe", "status"):
                if k.get(alan) in (None, "") and yedek.get(alan):
                    k[alan] = yedek[alan]
            if k.get("wave") is None and yedek.get("wave", "").isdigit():
                k["wave"] = int(yedek["wave"])
    if not kartlar:
        return {"proje": kok, "spec": state.get("spec"), "boy": state.get("boy"),
                "guncelleme": state.get("guncelleme"), "kartlar": [], "worktree_sayisi": 0}

    wave_no = {}
    for i, w in enumerate(state.get("waves") or [], 1):
        for kid in w:
            wave_no.setdefault(kid, i)

    # worktree → kart eşlemesi: .ekip/kart içeriği, yoksa dal adındaki T<nnn>
    raporlar = {}
    wts = worktreeler(kok)
    for yol, dal in wts:
        kid = None
        kart = oku(os.path.join(yol, ".ekip", "kart"))
        if kart:
            m = re.search(r"(T\d{3})", kart)
            kid = m.group(1) if m else None
        if not kid:
            m = re.search(r"(T\d{3})", dal or os.path.basename(yol))
            kid = m.group(1) if m else None
        if not kid:
            continue
        rapor = oku(os.path.join(yol, ".ekip", "rapor.md"))
        raporlar[kid] = {"worktree": yol, "dal": dal, "rapor": rapor}

    satirlar = []
    for kid in sorted(kartlar):
        k = kartlar[kid]
        r = raporlar.get(kid, {})
        durum, rpr, ozet = (None, None, "")
        if r.get("rapor"):
            durum, rpr, ozet = rapor_ozeti(r["rapor"])
        status = k.get("status") or "acik"
        kademe = k.get("kademe")
        try:
            kademe = int(kademe)
        except (TypeError, ValueError):
            pass
        pr = k.get("pr") or rpr
        kapilar = []
        if kademe == 3 and status in ACIK_STATUSLER:
            kapilar.append("🔐")
        if status == "kabul" and pr:
            kapilar.append("merge")
        if status == "eskale":
            kapilar.append("eskale")
        if durum in ("NEEDS_CONTEXT", "BLOCKED") and status in ACIK_STATUSLER:
            kapilar.append(durum.lower())
        satirlar.append({
            "wave": wave_no.get(kid, k.get("wave")),
            "id": kid, "rol": k.get("rol") or "?", "kademe": kademe if kademe is not None else "?",
            "status": status, "tur": k.get("tur", 0), "pr": pr,
            "maliyet_usd": k.get("maliyet_usd"),
            "rapor_durumu": durum, "rapor_ozeti": ozet,
            "worktree": r.get("worktree"), "dal": r.get("dal"),
            "kapilar": kapilar, "dosya": k.get("dosya"),
        })
    satirlar.sort(key=lambda s: (s["wave"] if isinstance(s["wave"], int) else 99, s["id"]))
    return {"proje": kok, "spec": state.get("spec"), "boy": state.get("boy"),
            "guncelleme": state.get("guncelleme"), "kartlar": satirlar, "worktree_sayisi": len(wts)}


def tablo(veri):
    simdi = dt.datetime.now().strftime("%Y-%m-%d %H:%M")
    bas = [f"# Ekip panosu — {os.path.basename(veri['proje'].rstrip('/'))}", "",
           f"Üretildi: {simdi} · spec: `{veri.get('spec') or '-'}` · boy: {veri.get('boy') or '-'} · "
           f"STATE güncellemesi: {veri.get('guncelleme') or '-'}  ",
           "Salt-okunur; `/ekip:durum` yeniden üretir. Kaynak: `docs/ekip/STATE.json`, `docs/ekip/tasks/`, "
           "worktree `.ekip/rapor.md`.", ""]
    if not veri["kartlar"]:
        bas += ["**Kart yok.** `docs/ekip/STATE.json` ya da `docs/ekip/tasks/` bulunamadı ya da boş. "
                "Başlamak için `/ekip:basla <istek>`, kartlar için `/ekip:dagit`.", ""]
        return "\n".join(bas)
    say = {}
    for s in veri["kartlar"]:
        say[s["status"]] = say.get(s["status"], 0) + 1
    ozet = " · ".join(f"{k} {v}" for k, v in sorted(say.items()))
    bas.append(f"Kart {len(veri['kartlar'])}: {ozet} · worktree {veri['worktree_sayisi']}")
    bas.append("")
    bas.append("| wave | kart | rol | kademe | status | tur | PR | maliyet | son rapor | bekleyen kapı |")
    bas.append("|---|---|---|---|---|---|---|---|---|---|")
    for s in veri["kartlar"]:
        pr = f"#{s['pr']}" if s["pr"] else "-"
        maliyet = f"${s['maliyet_usd']:.2f}" if isinstance(s["maliyet_usd"], (int, float)) else "ölçülmedi"
        rapor = "-"
        if s["rapor_durumu"] or s["rapor_ozeti"]:
            rapor = " · ".join(x for x in (s["rapor_durumu"], s["rapor_ozeti"]) if x)
        elif s["worktree"]:
            rapor = "rapor yok (worktree açık)"
        kapi = " ".join(s["kapilar"]) or "-"
        bas.append(f"| {s['wave'] if s['wave'] is not None else '-'} | {s['id']} | {s['rol']} | {s['kademe']} | "
                   f"{s['status']} | {s['tur']} | {pr} | {maliyet} | {rapor} | {kapi} |")
    bekleyen = [f"{s['id']} ({', '.join(s['kapilar'])})" for s in veri["kartlar"] if s["kapilar"]]
    bas.append("")
    bas.append("**Bekleyen kapılar:** " + ("; ".join(bekleyen) if bekleyen else "yok") +
               "  \n🔐 = Kademe 3, interaktif oturum + güvenlik onayı · merge = kapı 2, insan merge eder.")
    return "\n".join(bas) + "\n"


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--proje", default=os.getcwd())
    ap.add_argument("--dosya", action="store_true", help="docs/ekip/PANO.md'yi de yaz (varsayılan: yalnız stdout)")
    ap.add_argument("--json", action="store_true", help="tabloyu değil ham veriyi bas")
    a = ap.parse_args()
    kok = os.path.abspath(a.proje)
    veri = topla(kok)
    if a.json:
        print(json.dumps(veri, ensure_ascii=False, indent=1))
        return
    metin = tablo(veri)
    print(metin, end="")
    ekip = os.path.join(kok, "docs", "ekip")
    if a.dosya and os.path.isdir(ekip):
        pano = os.path.join(ekip, "PANO.md")
        with open(pano, "w", encoding="utf-8") as f:
            f.write(metin)
        print(f"\n(PANO yazıldı: {os.path.relpath(pano, kok)})")


if __name__ == "__main__":
    main()
