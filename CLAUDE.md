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
asset has a script, an event handler, a form or a third-party asset (other than the one analytics tag below), or a local link, anchor or icon does not resolve. Every claim on the site comes from a
repo file; each section names its sources in its `Source:` / `Kaynak:` line.

### Site analytics

The only script allowed on the site is the maintainer's self-hosted Umami tag, byte for byte, once in each page's
`<head>`, with the same website id on all four pages:
`<script defer src="https://stats.delix.dev/u.js" data-website-id="<uuid>" data-domains="tahircengiz.github.io"></script>`.
Umami runs on the maintainer's own server and is reached through Cloudflare at `stats.delix.dev`, where only the
tracker (`/u.js`) and the event endpoint (`/u/e`) are public. The tracker sets no cookies (it reads `localStorage` only
for the `umami.disabled` opt-out), and the visit data is not sold or shared. The site test is an allowlist and fails
closed: another host, path, attribute or attribute order, `async`, a second tag, an inline script, a tag outside
`<head>` or the nil-uuid placeholder fails; its cases are in `tests/site_umami_cases.txt`. The footer of every page
says this in one "Visit statistics" / "Ziyaret istatistiği" line.
