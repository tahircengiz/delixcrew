#!/usr/bin/env python3
"""PreToolUse (Bash): inceleyici rollerde yalnız salt-okunur komutlar; uygulayıcı worktree'sinde commit öncesi
gitleaks ve korunan yola yönelik shell yazımı engeli."""
import os
import re
import shutil
import subprocess
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from ekip_ortak import INCELEYICILER, deny, ekip_json, eslesir, girdi, kart_yolu  # noqa: E402

g = girdi()
cmd = ((g.get("tool_input") or {}).get("command") or "").strip()
agent = (g.get("agent_type") or "").strip()
cwd = g.get("cwd") or os.getcwd()

YAZAN = re.compile(r"(^|[\s;&|(])(rm|mv|cp|tee|sed\s+-i|chmod|chown|truncate|mkdir|touch|dd|git\s+(add|commit|push|"
                   r"checkout|switch|reset|rebase|merge|stash|apply|cherry-pick|tag|branch\s+-[dD]))\b|>>?\s*[^&\s]|"
                   r"\bpip\s+install\b|\bnpm\s+(i|install|ci)\b|\buv\s+(add|sync|pip)\b|\bbrew\s+install\b")
if agent in INCELEYICILER:
    if agent.endswith("guvenlik"):
        izinli = re.compile(r"^(gitleaks|semgrep|pip-audit|trivy|osv-scanner|bandit|git\s+(diff|log|show|status|"
                            r"ls-files|grep)|rg|grep|cat|head|tail|wc|ls|find|jq|python3?\s+-m\s+pip\s+index)\b")
        if YAZAN.search(cmd) or not izinli.match(cmd):
            deny("ekip: 'guvenlik' rolü yalnız salt-okunur tarayıcı ve git okuma komutları çalıştırabilir "
                 "(gitleaks, semgrep, pip-audit, trivy, git diff/log/show, rg/grep/cat).")
        sys.exit(0)
    deny(f"ekip: '{agent}' rolü salt-okunurdur; Bash çalıştıramaz.")

if not kart_yolu(cwd):
    sys.exit(0)

cfg = ekip_json(cwd)
korunan = cfg.get("korunan_yollar") or []

# shell redirect / cp / mv ile korunan yola yazma
for m in re.finditer(r"(?:>>?|\bcp\b[^|;&]*|\bmv\b[^|;&]*|\btee\b)\s+([^\s;&|]+)", cmd):
    hedef = m.group(1).strip("'\"")
    d = eslesir(hedef, korunan, cwd)
    if d:
        deny(f"ekip: komut korunan yola yazıyor ('{hedef}' ~ {d}). Kademe 3 yolu; insan onayı gerekir.")

if re.search(r"\bgit\s+commit\b", cmd):
    gl = shutil.which("gitleaks")
    if gl:
        r = subprocess.run([gl, "protect", "--staged", "--no-banner", "--redact", "--exit-code", "2"],
                           cwd=cwd, capture_output=True, text=True, timeout=50)
        if r.returncode == 2:
            ozet = (r.stdout or r.stderr).strip().splitlines()[-8:]
            deny("ekip: gitleaks staged değişikliklerde sır buldu; commit engellendi.\n" + "\n".join(ozet))
        if r.returncode not in (0, 2):
            deny(f"ekip: gitleaks çalışmadı (kod {r.returncode}); commit engellendi. Çıktı: {(r.stderr or '')[:300]}")
    else:
        uyari = os.path.join(cwd, ".ekip", "uyarilar.log")
        os.makedirs(os.path.dirname(uyari), exist_ok=True)
        with open(uyari, "a", encoding="utf-8") as f:
            f.write("gitleaks yok: commit sır taramasız geçti\n")
sys.exit(0)
