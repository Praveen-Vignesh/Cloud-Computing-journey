# Processes & systemd

## Processes

Every running process has a **process ID (PID)** — a program is the file
on disk; a process is a running instance of it.

## Why systemd

systemd is the supervisor that manages services. You hand it a process
and it can:
- **restart** it automatically when it crashes
- **start** it at boot
- **capture its logs** so you can read them later
- give you one consistent set of controls for every service on the box

## Unit files

A **unit file** turns a process / executable into a *service* that
systemd manages. It's not code — it's **metadata** telling systemd *how*
to run and babysit the program.

Example script — `heartbeat.sh`:

```bash
#!/bin/bash
while true; do
    echo "heartbeat at $(date)"
    sleep 10
done
```

Its unit file lives at `/etc/systemd/system/heartbeat.service`:

```ini
[Unit]
Description=A trivial heartbeat service for learning systemd
After=network.target

[Service]
ExecStart=/home/praveen/bin/heartbeat.sh
Restart=on-failure
User=praveen

[Install]
WantedBy=multi-user.target
```

### What each line does

| Line | Meaning |
|------|---------|
| `Description` | Human-readable name shown in status output |
| `After=network.target` | Don't start until networking is up |
| `ExecStart` | Absolute path to the program (no `~` — systemd has no home dir) |
| `Restart=on-failure` | Restart the program if it crashes |
| `User=praveen` | Run as this user, not root (least privilege) |
| `WantedBy=multi-user.target` | Start at boot, once the system is in normal multi-user operation |

## Controlling it

```bash
sudo systemctl daemon-reload     # after editing any unit file
sudo systemctl start heartbeat   # start now
sudo systemctl enable heartbeat  # start at boot
systemctl status heartbeat
journalctl -u heartbeat -f       # read logs, -f = follow live
```

> **`start` = now. `enable` = at boot. Usually you want both.**

## Errors I hit

`status=203/EXEC` when starting a service = systemd couldn't execute the
`ExecStart` program. In my case the script was missing its `#!/bin/bash`