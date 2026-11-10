# Day 09 — Nov 8–13, 2026

**Title:** Memos on a 1TB HDD behind nginx with real HTTPS

This "day" ran over several sittings. If you want one log per calendar day, split it at the section headings.

**Did:**

*A. Tore down the Day 9 Postgres stack (Nov 8)*
- Order matters, stop the trigger before the thing it triggers: `systemctl disable --now db_backup.timer` → stop the service → remove both unit files → `daemon-reload` → `docker compose down -v` (the `-v` deletes the volume, so the database) → `docker image rm postgres:18` → delete `/opt/postgres` and `/home/ashen/bin/db_backup.sh`.
- Verified with `docker ps -a`, `docker volume ls`, `docker images`, `systemctl list-timers`.

*B. Memos in Docker*
- Chose Memos (notes app, SQLite, one container) as the self-hosted service.
- Found four facts in its docs before writing anything: image + pinned tag, container port 5230, data path `/var/opt/memos`, runs as UID 10001 (its startup script fixes volume ownership). No environment variables needed, because defaults already do what I want.
- `/opt/memos/compose.yaml` with `127.0.0.1:5230:5230` and `restart: unless-stopped`.
- Learned to translate `docker run` flags into compose keys.

*C. Mounted the 1TB HDD and moved Memos' data onto it*
- Layers: block device → partition table → filesystem → mount.
- Checked health first: `smartctl -H` PASSED; reallocated, pending and uncorrectable sector counters all 0; ~11,675 power-on hours; short self-tests all passed.
- `fdisk /dev/sda` (GPT, one partition), `mkfs.ext4 -L data -m 1 /dev/sda1`, mounted at `/mnt/data`.
- Permanent mount via `/etc/fstab` by UUID with `nofail`; tested with `umount` + `mount -a` + `findmnt --verify` before any reboot. [confirm: did the real reboot test pass?]
- Optional trap-guard: `chattr +i /mnt/data` on the empty mount point while unmounted. [confirm: did I do this?]
- Switched Memos from a named volume to a bind mount `/mnt/data/memos:/var/opt/memos` and deleted the top-level `volumes:` block. Ran `docker compose down -v` first to clear the old volume.

*D. Caddy → nginx*
- Decided to move from Caddy to nginx to understand the proxy layer and TLS by hand. Caddy was already removed from firelink.
- Installed nginx, wrote my own static server block (port 80, `root /data/www`). Learned that a URL path is joined onto `root`.
- Reverse proxy: `location / { proxy_pass http://127.0.0.1:5230; }`.
- Added four headers: `Host $host`, `X-Real-IP $remote_addr`, `X-Forwarded-For $proxy_add_x_forwarded_for`, `X-Forwarded-Proto $scheme`. Learned nginx writes a brand-new request to the backend, and by default replaces `Host` with the backend's own address.



**Broke / Fixed by:**
1. `systemctl status memos` → "not found". Memos is a Docker container, not a systemd unit. Use `docker compose ps`.
2. `curl` to port **5320** → connection refused. I swapped the digits; the port is 5230. Copy-paste output instead of retyping it.
3. HDD missing from `lsblk`. [fill in: what changed before `sda` appeared? reseat, cable, BIOS?]
4. `mount /dev/sda` → "wrong fs type, bad superblock". I tried to mount the whole disk. The filesystem lives inside a partition (`sda1`), and the disk had none yet.
5. `fdisk`: typed `gn` on one line, so only `g` ran (fdisk reads the first character). Pasted text also leaked into the prompt. Quit with `q` (nothing is written until `w`) and restarted one command per line.
6. `fdisk` asked to remove an old filesystem signature, so the disk had held something before. I wrote the new table. [confirm: nothing on it mattered]
7. `"proxy_pass" directive is not allowed here` → I'd put it outside a `location` block. Fixed by checking its **Context** line on nginx.org/r/proxy_pass.
8. `nginx -t` with permission-denied errors on the log and key → I ran it without `sudo`. The root-only key was doing its job.
9. `mime.types` missing/empty (so files would be served as downloads) → reinstalled the package restoring missing config files. [confirm: `wc -c /etc/nginx/mime.types` is more than 0]
10. Confusion about ports 80/443/5230 and "third server block". Fixed by drawing the whole architecture, see `Notes/homelab-architecture.md`.

**Still don't understand:** [fill in. Candidates from this sitting: exactly how `location` precedence works with regex blocks; what the TLS handshake does step by step; how Tailscale proves name ownership to Let's Encrypt; how to back up a live SQLite file safely]

**Open items:**
- Retype `db_backup.sh` from memory (Rule 1 note), if I still want the exercise. The stack is gone.
- Remove the `TS_PERMIT_CERT_UID` line from `/etc/default/tailscaled` if it's still there. It was only for Caddy.
- Netdata, still to do from the Day 10 plan.
- Off-machine backup of the Memos database (S3 later).
- Log entries for Days 5–7 need filling in.

Notes: `Notes/docker.md`, `Notes/postgres-backup.md`, `Notes/linux/disks-and-mounting.md`, `Notes/reverse-proxy.md`, `Notes/tls-and-certificates.md`, `Notes/homelab-architecture.md`, `Notes/debugging-cheatsheet.md`
