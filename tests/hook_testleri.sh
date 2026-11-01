#!/usr/bin/env bash
# ekip hook betiklerinin deterministik testleri. Çalıştır: bash tests/hook_testleri.sh
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; S="$ROOT/scripts"; FAIL=0
T="$(mktemp -d)"; mkdir -p "$T/.ekip" "$T/docs/ekip" "$T/tests" "$T/auth"
echo "docs/ekip/tasks/T001-x.md" > "$T/.ekip/kart"
python3 - "$T/docs/ekip/ekip.json" <<'PY'
import json,sys; json.dump({"test_komutu":"true","ek_kontroller":[],"korunan_yollar":["auth/**",".env*"],"test_yollari":["tests/**"]},open(sys.argv[1],"w"))
PY
echo "def test_a(): assert 1" > "$T/tests/test_a.py"
deny(){ # ad, betik, json  → çıktı deny içermeli
  out=$(echo "$3" | python3 "$S/$2"); if echo "$out" | grep -q '"permissionDecision": "deny"'; then echo "✔ $1"; else echo "✘ $1 (deny bekleniyordu)"; FAIL=1; fi; }
allow(){ out=$(echo "$3" | python3 "$S/$2"); rc=$?; if [ $rc -eq 0 ] && ! echo "$out" | grep -q deny; then echo "✔ $1"; else echo "✘ $1 (izin bekleniyordu)"; FAIL=1; fi; }
deny  "inceleyici Write engellenir"      yazma_kapisi.py "{\"tool_name\":\"Write\",\"agent_type\":\"ekip:kalite\",\"cwd\":\"$T\",\"tool_input\":{\"file_path\":\"$T/x.py\"}}"
deny  "mimar Edit engellenir"            yazma_kapisi.py "{\"tool_name\":\"Edit\",\"agent_type\":\"ekip:mimar\",\"cwd\":\"$T\",\"tool_input\":{\"file_path\":\"$T/x.py\"}}"
allow "kart yokken pasif"                yazma_kapisi.py "{\"tool_name\":\"Write\",\"cwd\":\"/tmp\",\"tool_input\":{\"file_path\":\"/tmp/x.py\"}}"
deny  "uygulayıcı korunan yol auth/"     yazma_kapisi.py "{\"tool_name\":\"Edit\",\"cwd\":\"$T\",\"tool_input\":{\"file_path\":\"$T/auth/x.py\"}}"
deny  "uygulayıcı mevcut test düzenler"  yazma_kapisi.py "{\"tool_name\":\"Edit\",\"cwd\":\"$T\",\"tool_input\":{\"file_path\":\"tests/test_a.py\"}}"
allow "uygulayıcı yeni test dosyası"     yazma_kapisi.py "{\"tool_name\":\"Write\",\"cwd\":\"$T\",\"tool_input\":{\"file_path\":\"tests/test_b.py\"}}"
allow "uygulayıcı serbest dosya"         yazma_kapisi.py "{\"tool_name\":\"Edit\",\"cwd\":\"$T\",\"tool_input\":{\"file_path\":\"portal/app.py\"}}"
# Karta özel izin (Files listesi + 🔐 Onay satırı)
mkdir -p "$T/docs/ekip/tasks"; echo "x" > "$T/tests/listeli.py"; echo "x" > "$T/auth/izinli.py"
cat > "$T/docs/ekip/tasks/T001-x.md" <<'MD'
# T001 — x

| id | boy | kademe | rol | wave | status |
|---|---|---|---|---|---|
| T001 | S | 3 | backend | 1 | acik |

## Files (sahiplik ayrık)
- Değiştir: `auth/izinli.py` (`fn_x` 10–20)
- Değiştir (yalnız ekleme): `tests/listeli.py:12` (~satır 156)

## Steps
- `auth/steps_disi.py`
MD
allow "listedeki mevcut test dosyası"    yazma_kapisi.py "{\"tool_name\":\"Edit\",\"cwd\":\"$T\",\"tool_input\":{\"file_path\":\"$T/tests/listeli.py\"}}"
deny  "listede olmayan mevcut test"      yazma_kapisi.py "{\"tool_name\":\"Edit\",\"cwd\":\"$T\",\"tool_input\":{\"file_path\":\"tests/test_a.py\"}}"
out=$(echo "{\"tool_name\":\"Edit\",\"cwd\":\"$T\",\"tool_input\":{\"file_path\":\"auth/izinli.py\"}}" | python3 "$S/yazma_kapisi.py")
echo "$out" | grep -q '"permissionDecision": "deny"' && echo "$out" | grep -q "Onay sat" && echo "✔ korunan + listede + onaysız ret" || { echo "✘ korunan + listede + onaysız ret (Onay satırı yok mesajı)"; FAIL=1; }
deny  "Files dışı bölümdeki yol sayılmaz" yazma_kapisi.py "{\"tool_name\":\"Edit\",\"cwd\":\"$T\",\"tool_input\":{\"file_path\":\"auth/steps_disi.py\"}}"
python3 - "$T/docs/ekip/tasks/T001-x.md" <<'PY2'
import sys; p=sys.argv[1]; s=open(p).read(); s=s.replace("| T001 | S | 3 | backend | 1 | acik |\n", "| T001 | S | 3 | backend | 1 | acik |\n\n**🔐 Onay:** 2026-11-01 tahir\n"); open(p,"w").write(s)
PY2
allow "korunan + listede + onaylı izin"  yazma_kapisi.py "{\"tool_name\":\"Edit\",\"cwd\":\"$T\",\"tool_input\":{\"file_path\":\"auth/izinli.py\"}}"
deny  "korunan + listede değil + onaylı" yazma_kapisi.py "{\"tool_name\":\"Edit\",\"cwd\":\"$T\",\"tool_input\":{\"file_path\":\"auth/x.py\"}}"
deny  "kart dosyasına yazma ret"         yazma_kapisi.py "{\"tool_name\":\"Edit\",\"cwd\":\"$T\",\"tool_input\":{\"file_path\":\"$T/docs/ekip/tasks/T001-x.md\"}}"
deny  "docs/ekip/** yazma ret"           yazma_kapisi.py "{\"tool_name\":\"Write\",\"cwd\":\"$T\",\"tool_input\":{\"file_path\":\"docs/ekip/yeni.md\"}}"
allow "kendi .ekip/ dizini serbest"      yazma_kapisi.py "{\"tool_name\":\"Write\",\"cwd\":\"$T\",\"tool_input\":{\"file_path\":\".ekip/rapor.md\"}}"
deny  "inceleyici onaylı listede de ret" yazma_kapisi.py "{\"tool_name\":\"Edit\",\"agent_type\":\"ekip:kalite\",\"cwd\":\"$T\",\"tool_input\":{\"file_path\":\"auth/izinli.py\"}}"
allow "kart yokken pasif (docs/ekip)"    yazma_kapisi.py "{\"tool_name\":\"Write\",\"cwd\":\"/tmp\",\"tool_input\":{\"file_path\":\"/tmp/docs/ekip/x.md\"}}"
deny  "uygulayıcı .env redirect"         bash_kapisi.py  "{\"tool_name\":\"Bash\",\"cwd\":\"$T\",\"tool_input\":{\"command\":\"echo X=1 >> .env\"}}"
allow "guvenlik git diff"                bash_kapisi.py  "{\"tool_name\":\"Bash\",\"agent_type\":\"ekip:guvenlik\",\"cwd\":\"$T\",\"tool_input\":{\"command\":\"git diff main...HEAD\"}}"
deny  "guvenlik sed -i"                  bash_kapisi.py  "{\"tool_name\":\"Bash\",\"agent_type\":\"ekip:guvenlik\",\"cwd\":\"$T\",\"tool_input\":{\"command\":\"sed -i s/a/b/ x.py\"}}"
deny  "kalite Bash"                      bash_kapisi.py  "{\"tool_name\":\"Bash\",\"agent_type\":\"ekip:kalite\",\"cwd\":\"$T\",\"tool_input\":{\"command\":\"ls\"}}"
# Stop
printf '{"cwd":"%s","stop_hook_active":false}' "$T" | python3 "$S/stop_kapisi.py" 2>/dev/null; [ $? -eq 0 ] && echo "✔ stop: test geçer, durur" || { echo "✘ stop: geçen testte durmalıydı"; FAIL=1; }
python3 - "$T/docs/ekip/ekip.json" <<'PY'
import json,sys; p=sys.argv[1]; d=json.load(open(p)); d["test_komutu"]="false"; json.dump(d,open(p,"w"))
PY
printf '{"cwd":"%s","stop_hook_active":false}' "$T" | python3 "$S/stop_kapisi.py" 2>/dev/null; [ $? -eq 2 ] && echo "✔ stop: test kırık, engeller (exit 2)" || { echo "✘ stop: kırık testte exit 2 bekleniyordu"; FAIL=1; }
printf '{"cwd":"%s","stop_hook_active":true}' "$T" | python3 "$S/stop_kapisi.py" 2>/dev/null; [ $? -eq 0 ] && echo "✔ stop: stop_hook_active → durur" || { echo "✘ stop_hook_active"; FAIL=1; }
echo "NEEDS_CONTEXT: kart belirsiz" > "$T/.ekip/rapor.md"
printf '{"cwd":"%s","stop_hook_active":false}' "$T" | python3 "$S/stop_kapisi.py" 2>/dev/null; [ $? -eq 0 ] && echo "✔ stop: NEEDS_CONTEXT raporu → durur" || { echo "✘ NEEDS_CONTEXT"; FAIL=1; }
rm -rf "$T"; [ $FAIL -eq 0 ] && echo "TÜMÜ GEÇTİ" || { echo "BAŞARISIZ"; exit 1; }
