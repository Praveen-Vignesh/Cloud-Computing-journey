# Day 008 — 06-11-26

**Title:** Postgres in Docker + a tested, automated backup

**Did:**
- `/opt/postgres/compose.yaml`: `postgres:18`, container `postgres-dev`, a named volume mounted at `/var/lib/postgresql` (Postgres 18 mounts the parent folder, not `/data`).
- Connected with `docker exec -it postgres-dev psql -U postgres`. Made a `sample` table and a row.
- Proved backup and restore by hand: `pg_dump` → `DROP TABLE` → restore from the dump → row back.
- `/home/ashen/bin/db_backup.sh`: `docker exec postgres-dev pg_dump … | gzip` into `/opt/postgres/backups/pg_<date>_<time>.sql.gz`, deleting backups older than 7 days.
- `db_backup.service` (`Type=oneshot`) and `db_backup.timer` (`OnCalendar=daily`, `Persistent=true`).
- Hardening: `restart: unless-stopped`, and the port bound to `127.0.0.1:5432` so only firelink can reach it.
- Follow-up check (Nov 8): confirmed the port binding in `docker ps` and restored from a backup file made by the script.

**Broke:**
- `service:` instead of `services:`
- SQL syntax: trailing comma, `string` instead of `TEXT`, single quotes, missing semicolons
- "permission denied"
- `203/EXEC` on the service (ExecStart path / CRLF line endings / script not executable)

**Fixed by:** read each error message; checked path, line endings and `chmod +x`; fixed the SQL. The full `db_backup.sh` was handed to me at my request, so **retype it once from scratch without looking** (Rule 1 note).

**Still don't understand:** [fill in]. Known gap: backups live on the same disk as the database. A copy somewhere else (S3 later) is still needed.

Fate: this whole stack was deliberately torn down on Day 010. See that log.

Notes: `Notes/postgres-backup.md`
