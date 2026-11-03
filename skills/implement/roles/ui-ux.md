# Role note — ui-ux
- Design system first: from `DESIGN.md` / tokens when they exist; invent no new colour, spacing or typography value.
- If the Impeccable plugin is installed, run `critique` first, then implement; "works but plain" is not acceptable.
- For every screen: hierarchy, empty/error/loading states, mobile, focus visibility, 4.5:1 contrast.
- Evidence is mandatory: before/after screenshots (desktop + mobile) in `.delix/evidence/`, accessibility check output.
- SVG icons, not emoji; copy short and action-oriented.
- No taglines, helper text or secondary labels; if a screen needs them to make sense, fix the layout instead.
  Accessible names, form labels and error messages stay.
