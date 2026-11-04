#!/usr/bin/env bash
# Deterministic checks for the GitHub Pages site (site/). Run: bash tests/site_tests.sh
# Every page shows the plugin.json version, has its other-language twin, loads nothing from third parties except the
# one allowed self-hosted analytics tag (cases: tests/site_umami_cases.txt),
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

# The one allowed exception (allowlist, fail closed): the self-hosted Umami tag, byte for byte, exactly once per page,
# inside <head>. Only that match is cut out before the scans above run, so any other script, inline script, host,
# attribute order or extra attribute still fails. Fixed-width pattern: no alternation, no open-ended quantifier.
UMAMI = re.compile(r'<script defer src="https://stats\.delix\.dev/u\.js" data-website-id="([0-9a-f]{8}-[0-9a-f]{4}-'
                   r'[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})" data-domains="tahircengiz\.github\.io"></script>')
NIL_ID = "00000000-0000-0000-0000-000000000000"
def page_problems(t):
    """Problems of one page's HTML from the analytics rule and the active-content scans; returns (problems, id)."""
    head_start, head_end = t.find("<head>"), t.find("</head>")
    tags = list(UMAMI.finditer(t))
    in_head = [m for m in tags if head_start != -1 and head_start < m.start() and m.end() <= head_end]
    probs = []
    if len(in_head) != 1 or len(tags) != 1:
        probs.append(f"analytics tag: need exactly one allowed Umami tag inside <head>, found {len(in_head)} in "
                     f"<head> and {len(tags)} in the page")
    site_id = in_head[0].group(1) if len(in_head) == 1 else None
    if site_id == NIL_ID:
        probs.append("analytics tag: website id is the placeholder nil uuid")
    rest = t[:in_head[0].start()] + t[in_head[0].end():] if len(in_head) == 1 else t
    probs += [m.group(0) for m in ACTIVE.finditer(rest)] + [m.group(0) for m in EXT_REF.finditer(rest)]
    return probs, site_id

# the rule itself: every case in tests/site_umami_cases.txt (good and bad) must come out as expected
SAMPLE_ID = "0a1b2c3d-4e5f-4a6b-8c7d-9e0f1a2b3c4d"
SAMPLE_TAG = (f'<script defer src="https://stats.delix.dev/u.js" data-website-id="{SAMPLE_ID}" '
              'data-domains="tahircengiz.github.io"></script>')
cases = [l.rstrip("\n").split("\t") for l in open(os.path.join(root, "tests", "site_umami_cases.txt"), encoding="utf-8")
         if l.strip() and not l.startswith("#")]
wrong = []
for expect, where, name, snippet in cases:
    snippet = snippet.replace("{TAG}", SAMPLE_TAG).replace("{ID}", SAMPLE_ID)
    head, body = (snippet, "") if where == "head" else ("", snippet)
    probs, _ = page_problems(f'<!doctype html>\n<html lang="en">\n<head>\n{head}\n</head>\n<body>{body}</body>\n</html>\n')
    if (expect == "bad") != bool(probs):
        wrong.append(f"{expect} {name}: {probs or 'passed'}")
n_bad = sum(c[0] == "bad" for c in cases)
if cases and n_bad and not wrong:
    ok(f"analytics rule: {n_bad} bad cases rejected, {len(cases) - n_bad} good cases accepted")
else:
    bad(f"analytics rule cases did not come out as expected: {wrong or 'no cases'}")

# regex timing (ReDoS) of the allowlist pattern: ~1 MB near-miss inputs must stay linear (well under 1s)
import time
slow = []
for probe in ('<script defer src="https://stats.delix.dev/u.js" data-website-id="' + "a" * 1000000,
              SAMPLE_TAG[:-9] * 8000, "<script defer " * 80000, SAMPLE_TAG.replace("4d\"", "4\"") * 8000):
    t0 = time.perf_counter(); list(UMAMI.finditer(probe)); dt = time.perf_counter() - t0
    if dt > 1.0:
        slow.append(f"{len(probe)} chars: {dt:.2f}s")
ok("analytics rule: long near-miss inputs stay under 1s") if not slow else bad(f"analytics rule is slow: {slow}")

assets = sorted(os.path.relpath(os.path.join(d, f), site) for d, _, fs in os.walk(os.path.join(site, "assets"))
                for f in fs if f.endswith((".css", ".svg")))
for a in assets:
    s = open(os.path.join(site, a), encoding="utf-8").read()
    hits = [m.group(0) for m in ACTIVE.finditer(s)] + [m.group(0) for m in EXT_REF.finditer(s)]
    ok(f"{a}: no scripts or third-party assets") if not hits else bad(f"{a}: scripts or third-party assets: {hits}")

site_ids = {}
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
    ext, site_ids[p] = page_problems(t)
    ok(f"{p}: only the allowed analytics tag, no other scripts or third-party assets") if not ext \
        else bad(f"{p}: scripts or third-party assets: {ext}")
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

found = set(site_ids.values())
if len(found) == 1 and None not in found:
    ok(f"analytics tag: all {len(site_ids)} pages use the same website id")
else:
    bad(f"analytics tag: pages must share one website id, found {sorted(map(str, found))}")

sys.exit(fail)
PY
