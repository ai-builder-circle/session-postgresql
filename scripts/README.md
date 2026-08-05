# scripts/

Helpers for people who don't have `make` (e.g. some Windows setups).

- `up.sh`   — start Postgres
- `psql.sh` — open a psql shell
- `run.sh path/to/file.sql` — run a SQL file

On Windows, either use WSL, or run the raw `docker compose ...` commands
listed in `modules/00-setup/README.md`.
