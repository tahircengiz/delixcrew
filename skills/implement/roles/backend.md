# Role note — backend
- Layer boundary: route → service → repository; business rules do not leak into routes. Imitate the existing pattern,
  add no new abstraction.
- Validate input at the boundary (pydantic/schema); error paths are tested; no secrets or personal data in logs.
- If data changes, a migration file + rollback; if the migration is not in the card, stop.
- Authorization is explicit on every new endpoint; no "added later".
- Performance: no N+1 and no unbounded queries; if the card asks for a measurement, give command + number.
