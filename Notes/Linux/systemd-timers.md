# Shell scripts + systemd services and timers

Used for: `backup.sh` (Week 1), `db_backup` (Day 9, since removed), `renew_cert` (Day 10).

## Writing the script
- First line `#!/bin/bash` (the shebang) says which program runs it.
- `set -euo pipefail`:
  - `-e` stop at the first command that fails
  - `-u` treat an unset variable as an error
  - `-o pipefail` a pipeline fails if *any* part fails, not just the last
  Why it matters: in `renew_cert.sh`, if the certificate step fails, the script stops **before** reloading nginx, so the old working certificate stays in place.
- `chmod +x script.sh`, and use **absolute paths** inside scripts (systemd doesn't run them from your home folder).
- Variables once at the top: `NAME=...`, then `"$NAME"` in quotes.
- **CRLF line endings** (from editing on Windows) break the shebang. Check with `file script.sh`, fix with `sed -i 's/\r$//' script.sh`.

## The service + timer pair
Files live in `/etc/systemd/system/`.

`something.service`:
- `[Unit] Description=`
- `[Service] Type=oneshot` means it runs, finishes and exits, as opposed to staying running
- `ExecStart=` is the absolute path to the script
- No `User=` line means it runs as **root** (needed for root-owned files, or reloading nginx)

`something.timer`:
- `OnCalendar=daily` or `weekly` is when it fires
- `Persistent=true` means if the machine was off at that time, run once at next boot instead of skipping
- `[Install] WantedBy=timers.target` makes `enable` start it at boot

## The loop
```
sudo systemctl daemon-reload              # after any unit file change
sudo systemctl start something.service    # run it NOW, by hand, to test
systemctl status something.service        # oneshot shows inactive (dead) + status=0/SUCCESS when fine
journalctl -u something.service -n 20     # what it printed
sudo systemctl enable --now something.timer
systemctl list-timers something.timer     # NEXT should show a time
systemd-analyze calendar weekly           # see what a schedule string really means
```
Test the *service* by hand. Never wait for the timer to find out it's broken.

## `203/EXEC`
systemd couldn't execute `ExecStart`. Causes I've hit, in order of likelihood: wrong path, script not executable (`chmod +x`), CRLF line endings in the shebang line.

## Timers vs cron
Same job, but timers log to the journal (`journalctl -u`), can catch up after downtime (`Persistent=true`), and show up in `list-timers`.
