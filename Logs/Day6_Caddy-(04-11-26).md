# Day 006 — 04-11-26

**Title:** Caddy: my first reverse proxy

**Did:**
- Installed Caddy from the official apt repo. Inspected its unit with `systemctl cat caddy` and `journalctl -u caddy`.
- Wrote my own Caddyfile: a `localhost` site block with `reverse_proxy localhost:9000` and `tls internal`.
- Proxied a throwaway `python3 -m http.server 9000` and checked it with `curl https://localhost`.
- Learned: ports, what a reverse proxy is, TLS termination, Caddy's internal CA and `sudo caddy trust`.
- The loop: `caddy validate` → `caddy fmt` → `systemctl reload caddy` → watch the journal.

**Broke:** missing space before `{` (`localhost{`).

**Fixed by:** `caddy validate` pointed at the line. Caddy needs a space before the brace.

**Still don't understand:** what actually happens at the reverse-proxy layer. Caddy hides headers, certificates and renewal behind defaults, which is why I later switched to nginx (Day 010).

Live file was `/etc/caddy/Caddyfile`. Caddy was later removed from firelink.

Notes: `Notes/reverse-proxy.md` (Caddy section)
