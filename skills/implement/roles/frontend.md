# Role note — frontend
- Contract first: write against the API shape in Interfaces; if the backend is unfinished, use fake data, but keep the
  shape exact.
- Accessibility: labelled form fields, keyboard navigation, contrast; respect the CSP (no inline style/script if none
  exist).
- States: loading / empty / error screens, at least empty and error even if the card does not list them.
- Evidence: screenshots (desktop + mobile) in `.delix/evidence/`; Playwright if e2e exists.
- Copy in the project's language; no hardcoded strings inside components (follow the existing i18n/template pattern).
