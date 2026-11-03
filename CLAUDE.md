# delixcrew repo notes

## Site (GitHub Pages)

`site/` is the public site: plain HTML and CSS, no build step, published by `.github/workflows/site.yml` on every push
to main. Four pages, one per language and topic: `index.html` and `usage.html` (English), `tr/index.html` and
`tr/usage.html` (Turkish). The English and Turkish pages carry the same content.

Update the site in the same change when:
- the version in `.claude-plugin/plugin.json` changes: every `data-version` mark and its `delixcrew <version>` text,
  and the "coming in" / "ile gelecek" labels that the release turns into shipped features;
- a command, hook rule, role, gate or project file is added, removed or renamed (README Flow, Roles, Files, Known limits).

`bash tests/site_tests.sh` fails when a page's version differs from `plugin.json`, a TR/EN twin is missing, a page or an
asset has a script, an event handler, a form or a third-party asset, or a local link, anchor or icon does not resolve. Every claim on the site comes from a
repo file; each section names its sources in its `Source:` / `Kaynak:` line.
