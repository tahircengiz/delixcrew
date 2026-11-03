# Role note — devops
- Infrastructure as code only: compose files, Dockerfile, CI, proxy labels, `.env.example`. No hand changes on the host;
  everything the card delivers is reproducible from the repo. Imitate the existing service pattern, add no new layer.
- These files are usually protected paths (Tier 3): touch only what the card lists. Never weaken the perimeter — no
  `ports:` that bypass the proxy, no TLS verification off, no `privileged`, no `docker.sock` mount, no default
  passwords. If the card seems to need one of these, stop and report `NEEDS_CONTEXT` instead of doing it.
- Secrets never enter the repo, the logs, the report or the evidence; they come from the vault / environment at runtime.
  `.env.example` carries placeholders only.
- Pin and verify: image tags with a digest, dependencies with pinned versions (hashes where the ecosystem supports it);
  scanners that the project runs (trivy, gitleaks, pip-audit) run again and their output is evidence.
- Evidence is operational: the service up (`docker compose ps` healthy, an HTTPS request through the proxy returning the
  expected status), logs clean after start, and the rollback command written in the report. A measurement the card
  asks for is command + number, never an estimate. You gather it in an isolated, throwaway run (own compose project
  name and directory, torn down afterwards); the shared test environment is the lead's (implement §3), so
  what needs it goes into the report as commands for the lead's run.
