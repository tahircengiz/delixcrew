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

expected = ["index.html", "usage.html", "tr/index.html", "tr/usage.html"]
missing = [p for p in expected if p not in text]
ok("4 pages: EN and TR, what-is and usage") if not missing else bad(f"missing pages: {missing}")

for p, t in text.items():
    marks = re.findall(r'data-version="([^"]*)"[^>]*>([^<]*)<', t)
    if marks and all(v == version and s.strip() == f"delixcrew {version}" for v, s in marks):
        ok(f"{p}: version {version}")
    else:
        bad(f"{p}: version marks {marks or 'none'} do not match plugin.json {version}; update the site with the release")
    lang = re.search(r'<html lang="(en|tr)">', t)
    want = "tr" if p.startswith("tr/") else "en"
    ok(f"{p}: lang={want}") if lang and lang.group(1) == want else bad(f"{p}: <html lang> should be {want}")
    ext = re.findall(r'<script\b|<link\b[^>]*rel="stylesheet"[^>]*href="(?:https?:)?//|<img\b[^>]*src="(?:https?:)?//|@import', t)
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
