# Postgres in Docker + automated backups (Day 9)

*This stack was torn down on Day 010, but the pattern is reused in Week 6 (blog backend).*

## Running it
- `/opt/postgres/compose.yaml`: image `postgres:18`, container `postgres-dev`, named volume.
- **Postgres 18 mounts the volume at `/var/lib/postgresql`** (the parent folder), not `/var/lib/postgresql/data` as older versions did.
- Bind the port to loopback: `127.0.0.1:5432:5432`. Otherwise the database is published on every interface, and Docker's rules bypass ufw.
- `restart: unless-stopped`.
- Get a prompt: `docker exec -it postgres-dev psql -U postgres`.

## Backup and restore by hand
- Backup: `pg_dump` writes the database as SQL text. Piping through `gzip` shrinks it.
- Restore: `zcat file.sql.gz | docker exec -i postgres-dev psql -U postgres postgres`.
  - Use `-i` (keep stdin open), **not** `-it`. A terminal (`-t`) breaks piped input.
  - To prove a restore works, drop the table first, restore, confirm the row is back. A backup you haven't restored is a hope, not a backup.

## The automated version
1. `db_backup.sh`: `docker exec … pg_dump … | gzip > /opt/postgres/backups/pg_<date>_<time>.sql.gz`, then delete files older than 7 days.
2. `db_backup.service` (`Type=oneshot`) runs the script.
3. `db_backup.timer` (`OnCalendar=daily`, `Persistent=true`) triggers it.
See `linux/systemd-timers.md`.

## Known gap
Backups sit on the **same disk** as the database. If the disk dies, both go. The fix is an off-machine copy (S3 in Week 3–4). A second disk in the same machine is capacity, not a backup.

## Removing the whole stack cleanly (order matters)
1. `sudo systemctl disable --now db_backup.timer`, so nothing fires mid-teardown
2. `sudo systemctl stop db_backup.service`
3. remove `db_backup.service` and `db_backup.timer` from `/etc/systemd/system/`, then `daemon-reload`
4. `docker compose down -v`, because the `-v` deletes the volume and therefore the data
5. `docker image rm postgres:18`, only possible once no container uses it
6. delete `/opt/postgres` (compose file and backups) and the script
7. verify: `docker ps -a`, `docker volume ls`, `docker images`, `systemctl list-timers`
