#!/usr/bin/env bash
# Deterministic checks for the GitHub Pages site (site/). Run: bash tests/site_tests.sh
# Every page shows the plugin.json version, has its other-language twin, loads nothing from third parties,
# and every local link, anchor and icon reference resolves. A version bump without a site update fails here.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 -I - "$ROOT" <<'PY'
import json, os, re, sys
root = sys.argv[1]; site = os.path.join(root, "site"); fail = 0
def ok(m): print("✔ " + m)
def bad(m):
    global fail; fail = 1; print("✘ " + m)

version = json.load(open(os.path.join(root, ".claude-plugin", "plugin.json"), encoding="utf-8"))["version"]
pages = sorted(os.path.relpath(os.path.join(d, f), site) for d, _, fs in os.walk(site) for f in fs if f.endswith(".html"))
text = {p: open(os.path.join(site, p), encoding="utf-8").read() for p in pages}
ids = {p: set(re.findall(r'\bid="([^"]+)"', t)) for p, t in text.items()}
icons_path = os.path.join(site, "assets", "icons.svg")
symbols = set(re.findall(r'<symbol id="([^"]+)"', open(icons_path, encoding="utf-8").read())) if os.path.isfile(icons_path) else set()

en = {p for p in pages if not p.startswith("tr/")}
tr = {p[len("tr/"):] for p in pages if p.startswith("tr/")}
if {"index.html", "usage.html"} <= en and en == tr:
    ok(f"{len(pages)} pages: every English page has its Turkish twin")
else:
    bad(f"pages without a twin: EN only {sorted(en - tr)}, TR only {sorted(tr - en)} (index.html and usage.html are required)")

# active content or anything loaded from another host; a plain <a href> to another site is allowed.
# Tag scans are bounded ({0,4096}) so a long unclosed tag cannot make them backtrack polynomially.
ACTIVE = re.compile(r"<(?:script|iframe|object|embed|video|audio|source|base|form)\b|@import|@font-face|javascript:"
                    r"|url\(\s*['\"]?(?:https?:)?//|<[a-z][^>]{0,4096}?\s(?:on[a-z]+\s*=|http-equiv\s*=\s*['\"]?refresh)", re.I)
EXT_REF = re.compile(r"<(?!a\b)[a-z][^>]{0,4096}?\b(?:href|src|srcset|poster|data)\s*=\s*(?:['\"]\s*)?(?:https?:)?//", re.I)
assets = sorted(os.path.relpath(os.path.join(d, f), site) for d, _, fs in os.walk(os.path.join(site, "assets"))
                for f in fs if f.endswith((".css", ".svg")))
for a in assets:
    s = open(os.path.join(site, a), encoding="utf-8").read()
    hits = [m.group(0) for m in ACTIVE.finditer(s)] + [m.group(0) for m in EXT_REF.finditer(s)]
    ok(f"{a}: no scripts or third-party assets") if not hits else bad(f"{a}: scripts or third-party assets: {hits}")

for p, t in text.items():
    marks = re.findall(r'data-version="([^"]*)"[^>]*>([^<]*)<', t)
    if len(marks) >= 2 and all(v == version and s.strip() == f"delixcrew {version}" for v, s in marks):
        ok(f"{p}: version {version} ({len(marks)} marks)")
    else:
        bad(f"{p}: version marks {marks or 'none'} do not match plugin.json {version} (need the header and the footer "
            "mark); update the site with the release")
    lang = re.search(r'<html lang="(en|tr)">', t)
    want = "tr" if p.startswith("tr/") else "en"
    ok(f"{p}: lang={want}") if lang and lang.group(1) == want else bad(f"{p}: <html lang> should be {want}")
    ext = [m.group(0) for m in ACTIVE.finditer(t)] + [m.group(0) for m in EXT_REF.finditer(t)]
    ok(f"{p}: no scripts or third-party assets") if not ext else bad(f"{p}: scripts or third-party assets: {ext}")
    broken = []
    for attr, ref in re.findall(r'\b(href|src)="([^"]+)"', t):
        if re.match(r"(?:[a-z]+:|//)", ref):
            continue
        path, _, frag = ref.partition("#")
        target = os.path.normpath(os.path.join(os.path.dirname(p), path)) if path else p
        full = os.path.join(site, target)
        if os.path.isdir(full):
            target = os.path.join(target, "index.html"); full = os.path.join(site, target)
        if not os.path.isfile(full):
            broken.append(ref); continue
        if frag and target.endswith(".html") and frag not in ids.get(target, set()):
            broken.append(ref)
        if frag and target.endswith("icons.svg") and frag not in symbols:
            broken.append(ref)
    ok(f"{p}: local links, anchors and icons resolve") if not broken else bad(f"{p}: broken references {sorted(set(broken))}")

sys.exit(fail)
PY
