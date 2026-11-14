# firelink: how everything fits together (as of Nov 13, 2026)

## The picture
```
 LAPTOP browser: https://firelink.taild258c2.ts.net
      │
      ▼   DNS: Tailscale MagicDNS → firelink's 100.x address
 ═════╪═══════ Tailscale tunnel (WireGuard, encrypted) ═══════
      │
┌─────▼──────────────────────── FIRELINK (Ubuntu Server 24.04) ─────────────────────────┐
│  interface tailscale0                                                                  │
│      ▼                                                                                 │
│  ufw: allows 443, 80, 8443, only on tailscale0 (default deny incoming)                 │
│      ▼                                                                                 │
│  nginx (master as root + workers as user "nginx")                                      │
│   ├─ :443  TLS  server_name firelink…ts.net ──► proxy to Memos                         │
│   ├─ :80   plain HTTP, default_server ──► 301 redirect to https://…                    │
│   └─ :8443 TLS  ──► static test page (/data/www, /data/images)                         │
│      │  proxy_pass: a NEW plain-HTTP request, loopback only                            │
│      ▼                                                                                 │
│  127.0.0.1:5230 (Docker published port) ──► container "memos" (listens on 5230)        │
│      ▼  bind mount: /var/opt/memos (inside) = /mnt/data/memos (host)                   │
│  1TB HDD: sda1, ext4, /mnt/data (SQLite database file lives here)                      │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

## Ports
| Port | Listener | Reachable from | Speaks | Job |
|---|---|---|---|---|
| 443 | nginx | tailnet (ufw rule on tailscale0) | HTTPS | Memos, the main door |
| 80 | nginx | tailnet | HTTP | only redirects to HTTPS |
| 8443 | nginx | tailnet | HTTPS | static test page |
| 5230 | Docker (docker-proxy) → Memos | `127.0.0.1` only | HTTP | the app itself |
| 22 | sshd | per sshd_config / ufw | SSH | admin access |
| UDP (Tailscale's own) | tailscaled | peers | WireGuard | carries the tunnel |
Verify: `sudo ss -tlnp` and `sudo ss -ulnp`. The **address column** is the security story: `0.0.0.0:443` = all interfaces, `127.0.0.1:5230` = loopback only.

## Processes
| Program | Started by | Notes |
|---|---|---|
| systemd | kernel | starts the rest |
| nginx | `nginx.service` | master (root) + workers (`nginx` user) |
| dockerd → Memos container | `docker.service` | container starts at boot via `restart: unless-stopped`; runs as UID 10001 |
| tailscaled | `tailscaled.service` | tunnel + certificate requests |
| sshd | `ssh.service` | admin login |
| renew_cert.timer | systemd | weekly certificate renewal |

## Three layers of "who can reach Memos"
1. Docker binds it to loopback, so only firelink itself can connect.
2. ufw lets only the tailnet through to nginx (nginx isn't in Docker, so ufw does apply to it).
3. Tailscale only admits my own devices to the tailnet.

## Where things live
| Thing | Path |
|---|---|
| nginx globals | `/etc/nginx/nginx.conf` |
| nginx sites | `/etc/nginx/conf.d/{memos,redirect,static}.conf` |
| TLS certificate + key | `/etc/nginx/certs/` |
| static test site | `/data/www`, `/data/images` (on the NVMe) |
| Memos compose file | `/opt/memos/compose.yaml` (NVMe) |
| Memos data | `/mnt/data/memos` (HDD) |
| fstab entry | `/etc/fstab` (UUID, `nofail`) |
| scripts | `/home/ashen/bin/` |
| systemd units | `/etc/systemd/system/` |
| nginx logs | `/var/log/nginx/{access,error}.log` |
Convention: **config on the fast disk (git-able), data on the big disk (needs backups).**

## One request, start to finish
1. DNS turns the name into the tailnet address.
2. The packet enters the Tailscale tunnel and arrives on `tailscale0`.
3. ufw checks and the 443-on-tailscale0 rule allows it.
4. TCP + TLS handshake with nginx, using the certificate and key.
5. nginx decrypts, picks the `server` block (listen + `Host`) and then the `location`.
6. `proxy_pass`: nginx opens a new plain-HTTP connection to `127.0.0.1:5230` with my four headers attached.
7. Memos reads its SQLite file from `/mnt/data/memos` and replies.
8. nginx wraps the reply in TLS and sends it back through the tunnel.

## Still to do
Netdata (own port, e.g. 8444, same certificate) · off-machine backup of the Memos database · retype scripts and configs from memory (Rule 1).
