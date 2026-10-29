# Day 003 — October 25, 2026

**Processes & systemd**

> Created a trivial heartbeat process and used systemd to make it survive a crash and a reboot — the day the whole deployment model clicked.

---

## What I did

1. Created a trivial `heartbeat.sh` that echoes a line every 10 seconds.
2. Made it executable (`chmod +x`).
3. Wrote a `.service` unit file to turn the script into a systemd-managed service.
4. Enabled and started it with `systemctl`, then confirmed it **restarts after a kill** and **survives a reboot**.
5. Read its output with `journalctl`.

## Key commands

```bash
sudo nano /etc/systemd/system/heartbeat.service
sudo systemctl daemon-reload     # after editing a unit
sudo systemctl start heartbeat
sudo systemctl enable heartbeat  # start at boot
systemctl status heartbeat
journalctl -u heartbeat -f       # follow logs live
```

## Challenges & problems

Hit a `status=203/EXEC` error when starting the service.

## How I solved it

The script was missing its shebang line. Adding `#!/bin/bash` at the top fixed it — without it, the system didn't know how to execute the file. (`203/EXEC` = systemd couldn't execute the `ExecStart` program.)

## Still don't understand

<!-- e.g. Restart=always vs on-failure, what the other .target units are -->
