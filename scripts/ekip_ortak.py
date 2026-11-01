"""ekip hook'larının ortak yardımcıları. Yalnız stdlib."""
import fnmatch
import json
import os
import sys

INCELEYICILER = {"ekip:mimar", "ekip:kalite", "ekip:guvenlik", "ekip:arayici",
                 "mimar", "kalite", "guvenlik", "arayici"}


def girdi():
    try:
        return json.load(sys.stdin)
    except Exception:
        return {}


def deny(neden):
    print(json.dumps({"hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "deny",
        "permissionDecisionReason": neden}}))
    sys.exit(0)


def kart_yolu(cwd):
    """Uygulayıcı worktree'sinde .ekip/kart varsa kart yolunu döndürür; yoksa None (hook pasif)."""
    p = os.path.join(cwd, ".ekip", "kart")
    if not os.path.isfile(p):
        return None
    with open(p, encoding="utf-8") as f:
        return f.read().strip() or None


def ekip_json(cwd):
    for aday in (os.path.join(cwd, "docs", "ekip", "ekip.json"),):
        if os.path.isfile(aday):
            try:
                with open(aday, encoding="utf-8") as f:
                    return json.load(f)
            except Exception:
                return {}
    return {}


def eslesir(yol, desenler, cwd):
    """Göreli/mutlak yolu cwd'ye göre normalize edip glob desenleriyle karşılaştırır ('**' destekli)."""
    if not yol:
        return None
    rel = os.path.relpath(os.path.abspath(os.path.join(cwd, yol)), cwd)
    rel = rel.replace(os.sep, "/")
    for d in desenler:
        d2 = d.replace("**/", "").replace("/**", "")
        if fnmatch.fnmatch(rel, d) or fnmatch.fnmatch(rel, d2) or rel.startswith(d2.rstrip("*").rstrip("/") + "/") \
                or fnmatch.fnmatch(os.path.basename(rel), d):
            return d
    return None
