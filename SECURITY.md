# Security policy

## Reporting a vulnerability

Report it privately through GitHub: the repository's **Security** tab, then **Report a vulnerability**
([security/advisories/new](https://github.com/tahircengiz/delixcrew/security/advisories/new)). Please do not open a
public issue or send a feedback draft for a vulnerability; feedback drafts become public issues.

delixcrew has a single maintainer. Reports are handled on a best-effort basis; there is no promised response or fix
time.

## Supported versions

| Version | Supported |
|---|---|
| 0.6.x | yes |
| < 0.6 | no |

## How fixes ship

A fix ships as a new version in `.claude-plugin/plugin.json`. An installed plugin updates only when that version changes
(see [Installation](README.md#installation)), so a fix without a version bump does not reach users. Each fix is
described in the [CHANGELOG](CHANGELOG.md) and, for a vulnerability, in a GitHub Security Advisory on this repository.

## Trust model

- The plugin's hooks load in every Claude Code session where the plugin is enabled. What each hook blocks or runs, which
  files the plugin writes and when it uses the network:
  [What this plugin does on your machine](README.md#what-this-plugin-does-on-your-machine).
- In an implementer worktree the Stop hook runs the `test_command` and `extra_checks` of the project's
  `docs/delix/delix.json` through the shell. These commands come from the project; read them before you start an
  implementer session in a repository you do not trust.
- The implementer hooks turn on only for a `.delix/card` that you wrote locally: a card that git tracks, a symlink, or a
  card outside the root of a git work tree leaves them off, so a cloned repository cannot switch them on.
