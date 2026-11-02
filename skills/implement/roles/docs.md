# Role note — docs
- Source of truth is the code and the running system: every command, path, flag, version and number in the text is
  verified against the repo or by running it. Nothing is "should work"; what was not run is marked as not verified.
- Reader first: say who reads the page and what they do next. An install or quickstart runs top to bottom on a clean
  machine (or a fresh temporary HOME) and each step shows its expected output.
- One job per page; headings answer the reader's question; new terms get a short glossary; code is linked by path.
  Public docs carry no secrets, internal hostnames, IP addresses or personal data.
- Keep pairs in sync: a user-visible change gets a CHANGELOG line; README and `--help` text agree; language pairs
  (`README.md` / `README.tr.md`) change in the same commit.
- Evidence: the rendered page checked (links resolve, code blocks run), and after a rename an `rg` for stale names with
  the remaining hits listed and justified.
