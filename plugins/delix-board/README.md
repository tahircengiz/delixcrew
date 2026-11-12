# delix-board — a live board for delix

A companion mod for [delix](../../README.md). It reads a delix project (`docs/delix/STATE.json`, the task cards,
`metrics.md`, the implementer worktrees' `.delix/` files) and shows it beside the chat: a pane with four views, a band
above the prompt while a long run is going, a status line entry and a toast when the run ends. It only reads; it writes
no project file and changes nothing in delix itself.

The lead may write `STATE.json` in a worktree of its own (Claude Desktop opens one per session) while the main
checkout stays behind. The board therefore reads the copy that changed last among the worktrees that hold one (an
uncommitted copy by its mtime, a clean one by the commit that last touched it), leaving out implementer worktrees
(those with `.delix/card`), and names that worktree in its header when it is not the main checkout. It looks again
every 20 seconds.

Beside the files it runs only read-only local git, every call as `git --no-optional-locks -c core.fsmonitor=false …`
(the repository calls in the session's checkout, the others in the worktree they ask about): once at start
`rev-parse --show-toplevel`; every 20 seconds `rev-parse --git-common-dir`, `worktree list --porcelain -z`,
`for-each-ref refs/heads refs/remotes --format=%(refname)%09%(objectname)%09%(upstream)%09%(upstream:track,nobracket)%09%(committerdate:unix)`
and `--no-lazy-fetch --no-replace-objects cat-file blob refs/remotes/origin/HEAD:docs/delix/STATE.json`, then in each
worktree `status --porcelain` and, where there is no `.delix/card` and `STATE.json` has no uncommitted change,
`diff --no-ext-diff --quiet origin/<default>...HEAD -- docs/delix/STATE.json` (`<default>`: `default_branch` in
`docs/delix/delix.json`, else `main`) and, if it holds a `STATE.json`,
`log -1 --no-show-signature --format=%ct -- docs/delix/STATE.json`: at most 4 + 3N calls per look for N worktrees.
There is no `git fetch` and no `gh`, so remote data is as of the last fetch, whose time the header shows. A card is
ready to merge only when the STATE at `refs/remotes/origin/HEAD` shows the same card, PR and reviewed SHA; when
`origin/HEAD` is missing no card is, and `git remote set-head origin -a` sets it.

![Board view in the terminal](assets/board-terminal-pano.png)

## Installation

```bash
claude plugin marketplace add tahircengiz/delixcrew
```

```bash
claude plugin install delix-board@delixcrew
```

delix and delix-board are independent: either can be installed without the other. For a one-off trial from a clone,
`claude --plugin-dir /path/to/delixcrew/plugins/delix-board`.

## Views

The pane opens by itself in a delix project; elsewhere `/delix-board` shows the empty state ("not a delix project").
Switch views with the tabs, the keys `1`–`4`, or the command:

| Command | View | Shows |
|---|---|---|
| `/delix-board` or `/delix-board pano` | Pano (board) | card count, rounds, cost, a status bar, pending gates (Tier 3 approval, merge, escalation), the Spec C sections Leads, Ajanlar (agents: role, worktree, branch, upstream, where the changes land, uncommitted files), Seni bekliyor (waiting on you), Merge'e hazır (ready to merge) and Git işleri (git actions: each command as text; the pane never runs it), cards by wave, cards of the previous spec, verifications |
| `/delix-board bekleme` | Bekleme (wait) | tracked long runs: elapsed time, suites and PASS/FAIL counts, the last output lines, the expected duration from earlier runs |
| `/delix-board kart T010` | Kart (card) | one card: header, review verdicts, Files list, the worktree report and test result, review rounds with finding severities; Kayıt: the card's `agents` ledger (who opened it, every qa / security record) |
| `/delix-board olcum` | Ölçüm (metrics) | cost, rounds, duration and gates per card as bars, with totals; unmeasured values are marked, never guessed |

![Card view](assets/board-terminal-kart.png)
![Metrics view](assets/board-terminal-olcum.png)

A Bash command matching `run_all.sh`, `upgrade_restore_drill`, `install_trial`, `release.sh`, `build.sh`,
`gh run watch`, `gh pr checks --watch` or `docker build`, and every `delixcrew:*` subagent, is tracked as a run. While it
runs, the band above the prompt shows it; the `extraPatterns` option adds patterns of your own.

![Band above the prompt](assets/board-terminal-band.png)

## Surfaces

The terminal draws charts with Raster cells and text glyphs; the desktop app draws SVG icons and bars. Every view reads
on both. In a headless session (`claude -p`, the delix implementer and reviewer runs) the mod registers nothing and
draws nothing.

## Development

Checks: `claude plugin validate plugins/delix-board`, `claude plugin test plugins/delix-board` (view tests on a
synthetic project in `tests/fixtures.ts`). The design and its decisions (Turkish): [docs/spec/delix-board.md](../../docs/spec/delix-board.md).
`tests/board_parity.ts` is `export const PARITY = ` followed by the bytes of the repository's `tests/fixtures/board_parity.json`; the pane's `derive` must return its `expected` (`tests/board.test.tsx`), and `bash tests/board_tests.sh` checks the copy.

## License

MIT, see [LICENSE](../../LICENSE).
