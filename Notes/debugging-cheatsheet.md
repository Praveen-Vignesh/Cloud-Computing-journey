# Debugging cheat sheet: errors I've hit and what they meant

| Symptom / message | Meaning | Fix |
|---|---|---|
| `service:` error in compose | the key is `services:` (plural) | fix the typo, run `docker compose config` |
| SQL syntax errors | trailing comma, `string` (use `TEXT`), single vs double quotes, missing `;` | read the position in the error |
| `203/EXEC` on a systemd service | systemd can't run `ExecStart` | check the path, `chmod +x`, CRLF line endings |
| `caddy validate` fails | missing space before `{` | add it |
| `systemctl status memos` → not found | it's a Docker container, not a unit | `docker compose ps` |
| `curl` → connection refused | nothing listening on that address:port (check digits! 5230 vs 5320) | `sudo ss -tlnp \| grep PORT` |
| `curl`: empty reply / reset | Docker's door is open but the app inside isn't answering on that port | `docker compose logs`; check the right-hand port number |
| disk absent from `lsblk` | below the filesystem: power, cable, BIOS, drive | `dmesg`, BIOS storage page |
| `mount: wrong fs type, bad superblock` | mounting a whole disk (or a blank one) | mount the partition, or create a filesystem first |
| fdisk ran only `g` when I typed `gn` | fdisk reads the first character only | one command per line |
| fdisk: "remove the signature?" | an old filesystem is there | stop and decide whether the data matters |
| `"proxy_pass" directive is not allowed here` | wrong context | put it inside `location { }`. Check **Context** at `nginx.org/r/<directive>` |
| `nginx -t` permission denied (log or key) | ran without `sudo`; the key is root-only on purpose | `sudo nginx -t` |
| `duplicate default server` | two blocks claim `default_server` on one port | remove the old one |
| `cannot load certificate` | path or name typo, or a permissions problem | compare with `ls -l /etc/nginx/certs` |
| files download instead of displaying | `mime.types` not included | `include /etc/nginx/mime.types;` inside `http` |
| `/images/x.png` not found | `root` appends the URL path | `root /data;` or use `alias` |
| 502 Bad Gateway | the backend isn't answering | `error.log` → "connection refused"; is the container up? |
| 504 Gateway Timeout | the backend is too slow | check the backend |
| cert errors via Tailscale | HTTPS not enabled, MagicDNS off, wrong name | check the admin console and the exact full name |
| ufw rule for a Docker port does nothing | Docker's iptables rules run before ufw | bind to `127.0.0.1` |
| SSH drops after restarting tailscaled | the session ran through Tailscale | `tmux`, or reconnect |
| `ls -l` key not `-rw-------` | the private key is too readable | `chmod 600`, `chown root:root` |

## Habits that prevent most of these
- Validate before you apply: `docker compose config`, `sudo nginx -t`, `caddy validate`, `mount -a`.
- Test the layer below before the layer above (the app on loopback before the proxy, the proxy before TLS).
- Read the error text first: it usually names the file and line.
- **Copy-paste output instead of retyping it** (a digit swap cost a long detour).
- Back up before editing config you can't easily rebuild (`cp -a /etc/nginx /etc/nginx.bak`, `cp /etc/fstab /etc/fstab.bak`).
- Nothing is written to a disk until `w` in fdisk and `mkfs` don't forgive.
