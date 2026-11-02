#!/usr/bin/env bash
# pano_uret.py deterministik testleri. Çalıştır: bash tests/pano_testleri.sh
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; S="$ROOT/scripts"; FAIL=0
ok(){ echo "✔ $1"; }; bad(){ echo "✘ $1"; FAIL=1; }
T="$(mktemp -d)"; cd "$T" || exit 1

# 1) boş proje → kart yok, PANO yazılmaz
out=$(python3 "$S/pano_uret.py"); echo "$out" | grep -q "Kart yok" && ok "boş proje: Kart yok" || bad "boş proje: Kart yok bekleniyordu"
[ ! -e docs/ekip/PANO.md ] && ok "boş proje: PANO yazılmadı" || bad "boş proje: PANO yazılmamalıydı"

# 2) sahte proje: git repo + STATE + 2 kart + worktree'de rapor
git init -q -b main . && git -c user.email=t@t -c user.name=t commit -q --allow-empty -m init
mkdir -p docs/ekip/tasks
cat > docs/ekip/STATE.json <<'J'
{"spec":"docs/ekip/SPEC.md","boy":"M","guncelleme":"2026-11-01T10:00:00Z","waves":[["T001","T002"]],
 "kartlar":{"T001":{"dosya":"docs/ekip/tasks/T001-api.md","rol":"backend","kademe":2,"status":"suruyor","pr":null,"tur":0,"maliyet_usd":null},
            "T002":{"dosya":"docs/ekip/tasks/T002-auth.md","rol":"backend","kademe":3,"status":"kabul","pr":12,"tur":2,"maliyet_usd":1.5}}}
J
printf '# T001 — api\n\n| id | boy | kademe | rol | wave | status |\n|---|---|---|---|---|---|\n| T001 | M | 2 | backend | 1 | acik |\n' > docs/ekip/tasks/T001-api.md
printf '# T002 — auth\n' > docs/ekip/tasks/T002-auth.md
printf '# T003 — yalnız kart dosyası\n\n| id | boy | kademe | rol | wave | status |\n|---|---|---|---|---|---|\n| T003 | S | 1 | frontend | 2 | acik |\n' > docs/ekip/tasks/T003-ui.md
git -c user.email=t@t -c user.name=t add -A && git -c user.email=t@t -c user.name=t commit -q -m kartlar
git worktree add -q "$T/wt-T001" -b ekip-T001 >/dev/null 2>&1
mkdir -p "$T/wt-T001/.ekip"; echo "docs/ekip/tasks/T001-api.md" > "$T/wt-T001/.ekip/kart"
printf '# Rapor — T001\n\n**Durum:** NEEDS_CONTEXT\n**PR:** #7 (ekip-T001)\n\n## Kanıt\n- `pytest -q` → 3 passed\n\n## Çekinceler / kalan iş\n- Keycloak realm adı spec'"'"'te yok\n' > "$T/wt-T001/.ekip/rapor.md"

out=$(python3 "$S/pano_uret.py")
[ ! -e docs/ekip/PANO.md ] && ok "varsayılan: PANO yazılmadı" || bad "varsayılan: PANO yazılmamalıydı"
out=$(python3 "$S/pano_uret.py" --dosya)
echo "$out" | grep -q "| 1 | T001 | backend | 2 | suruyor | 0 | #7 | ölçülmedi | NEEDS_CONTEXT · Keycloak realm adı spec'te yok | needs_context |" && ok "T001 satırı (rapor, PR, kapı)" || { bad "T001 satırı"; echo "$out"; }
echo "$out" | grep -q "| 1 | T002 | backend | 3 | kabul | 2 | #12 | \$1.50 | - | merge |" && ok "T002 satırı (maliyet, merge kapısı)" || { bad "T002 satırı"; echo "$out"; }
echo "$out" | grep -q "| 2 | T003 | frontend | 1 | acik | 0 | - | ölçülmedi | - | - |" && ok "T003 yalnız kart dosyasından" || { bad "T003 satırı"; echo "$out"; }
[ -f docs/ekip/PANO.md ] && grep -q "T001" docs/ekip/PANO.md && ok "--dosya: PANO.md yazıldı" || bad "PANO.md yok"
python3 "$S/pano_uret.py" --json | python3 -c 'import json,sys; d=json.load(sys.stdin); assert len(d["kartlar"])==3 and d["kartlar"][0]["worktree"], d' && ok "--json çıktısı" || bad "--json"

# 3) /ekip:dogrula kaydı (STATE.json.dogrulama) → "Doğrulamalar" tablosu; kartlı ve kartsız projede
python3 - <<'PYS'
import json; p="docs/ekip/STATE.json"; d=json.load(open(p))
d["dogrulama"]=[{"ad":"a10c-e7","tarih":"2026-11-02","sha":"abcdef0123","taban":"40735be","girdi":"a10c-e7","kademe":"3 🔐","karar":"DÜZELT 🔐",
 "rapor":"docs/ekip/dogrulama/2026-11-02-a10c-e7.md","kapilar":{"gitleaks":"GEÇTİ","yerel":"GEÇTİ","uzak_birim":"GEÇTİ 41/41","tam":"koşulmadı: --tam yok"},
 "kalite":"KABUL_ÇEKİNCELİ","guvenlik":"🔐 İNSAN ONAYI","maliyet_usd":1.25}]
json.dump(d,open(p,"w"),ensure_ascii=False)
PYS
out=$(python3 "$S/pano_uret.py")
echo "$out" | grep -qF "| 2026-11-02 | a10c-e7 | abcdef0 | 3 🔐 | GEÇTİ | GEÇTİ | GEÇTİ 41/41 | koşulmadı: --tam yok | KABUL_ÇEKİNCELİ | 🔐 İNSAN ONAYI | DÜZELT 🔐 | \$1.25 | \`docs/ekip/dogrulama/2026-11-02-a10c-e7.md\` |" && ok "dogrulama satırı (kartlı proje)" || { bad "dogrulama satırı"; echo "$out"; }
echo "$out" | grep -qF "Bekleyen düzeltme:** a10c-e7" && ok "dogrulama: bekleyen düzeltme" || bad "dogrulama: bekleyen düzeltme"
python3 "$S/pano_uret.py" --json | python3 -c 'import json,sys; d=json.load(sys.stdin); assert d["dogrulama"][0]["ad"]=="a10c-e7", d' && ok "--json dogrulama" || bad "--json dogrulama"
python3 - <<'PYS'
import json; p="docs/ekip/STATE.json"; d=json.load(open(p)); d["kartlar"]={}; json.dump(d,open(p,"w"),ensure_ascii=False)
PYS
rm -f docs/ekip/tasks/*.md
out=$(python3 "$S/pano_uret.py")
echo "$out" | grep -q "Kart yok" && echo "$out" | grep -qF "| 2026-11-02 | a10c-e7 |" && ok "dogrulama: kartsız projede de görünür" || { bad "dogrulama kartsız"; echo "$out"; }

cd /; rm -rf "$T"; [ $FAIL -eq 0 ] && echo "TÜMÜ GEÇTİ" || { echo "BAŞARISIZ"; exit 1; }
