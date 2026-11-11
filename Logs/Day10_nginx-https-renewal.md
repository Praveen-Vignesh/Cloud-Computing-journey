# Day 011 — Nov 8–13, 2026
**Title:** Memos on a 1TB HDD behind nginx with real HTTPS


*A. HTTPS*
- Enabled HTTPS in the Tailscale admin console. `sudo tailscale cert <name>` wrote a `.crt` and `.key` into `/etc/nginx/certs/` (key is `-rw-------` root only).
- Inspected it with `openssl x509 … -noout -subject -issuer -dates`: issuer Let's Encrypt (intermediate YE1), valid 90 days, **expires Feb 11 2027**.
- `listen 443 ssl;` server block with the certificate and key paths. Tested with `curl --resolve NAME:443:127.0.0.1 https://NAME` → `200 OK`. Opened it from the laptop over Tailscale: padlock, no warning.
- ufw: allowed 443, 80 and 8443 **only on `tailscale0`**.

*B. Cleaned up the structure*
- One file per door: `nginx.conf` (globals), `conf.d/memos.conf` (443 → Memos), `conf.d/redirect.conf` (80 → 301 to HTTPS), `conf.d/static.conf` (8443, static page and images).
- Backed up `/etc/nginx` first, moved the old config aside as `.old`.

*C. Certificate renewal* (designed with Claude) [confirm: script and timer written and tested?]
- `renew_cert.sh`: `tailscale cert` with absolute paths → `nginx -t` → `systemctl reload nginx`, with `set -euo pipefail` so a failure leaves the old certificate in place.
- `renew_cert.service` (oneshot, runs as root) + `renew_cert.timer` (`OnCalendar=weekly`, `Persistent=true`).
- Reminder: check the expiry date moved around Jan 15, 2027.