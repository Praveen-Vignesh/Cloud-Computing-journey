# TLS, certificates, and renewal

## The picture
HTTP is a postcard anyone en route can read. HTTPS wraps it in a **locked tube**.
- A **certificate** is a server's ID card ("this key belongs to `firelink…ts.net`"), signed by a **certificate authority** (a notary the browser already trusts). Public.
- The **private key** proves the card is really yours. Secret, root-only. Anyone holding it can impersonate you.

## The handshake
1. TCP connects to port 443.
2. **ClientHello**: the browser lists what it supports and names the site it wants (**SNI**, sent in the clear, so nginx can pick the right certificate before encryption starts, and why `openssl s_client` needs `-servername`).
3. The server sends its certificate chain.
4. The browser checks: trusted authority? name matches? within its dates?
5. Both sides derive a shared secret that is never sent over the wire; the server proves it holds the private key.
6. Encrypted traffic starts. Each session uses fresh temporary keys, so stealing the key later doesn't decrypt old recordings.

Other facts: a certificate is bound to a **name**, so browsing by IP gives a warning. Missing intermediate certificates (the chain) is a classic "works in the browser, fails in curl" cause.

## TLS termination
TLS ends at nginx. Nginx then makes a **plain-HTTP** request to Memos on loopback. That's safe because it never leaves the machine, and it's why `X-Forwarded-Proto` must tell the app the visitor used HTTPS.

## Why TLS when Tailscale already encrypts?
Tailscale protects the *network path* and decides who can reach the machine. TLS gives the **browser** a verifiable identity (padlock, no warnings), enables HTTPS-only browser features (clipboard, service workers, installable web apps), and the same config works unchanged on the public internet.

## How the certificate was obtained
`sudo tailscale cert <name>` → Tailscale answers Let's Encrypt's "prove you control this name" challenge on my behalf (it controls DNS for `ts.net`) → Let's Encrypt signs → two files written.
- Mine: issuer Let's Encrypt (intermediate `YE1`), valid 90 days, **expires Feb 11 2027**.
- Files in `/etc/nginx/certs/`: `.crt` is `-rw-r--r--`; **`.key` is `-rw-------` root only**. The nginx master runs as root and reads both at startup; workers don't need them.

## nginx directives
```
listen 443 ssl;
server_name firelink.taild258c2.ts.net;
ssl_certificate     /etc/nginx/certs/<name>.crt;
ssl_certificate_key /etc/nginx/certs/<name>.key;
```
- `listen … ssl` switches TLS on for that port. The old `ssl on;` directive was **removed in nginx 1.25.1**, so tutorials using it are outdated.
- Don't copy cipher lists out of old examples (some include broken ciphers like RC4). Leave `ssl_ciphers` at its default and read `nginx.org/r/ssl_protocols`.
- One certificate can serve several ports (443 for Memos, 8443 for the static page), because it's for the **name**, not the port.

## Inspecting
```
openssl x509 -in <name>.crt -noout -subject -issuer -dates
curl -v --resolve NAME:443:127.0.0.1 https://NAME        # handshake from the server itself
openssl s_client -connect NAME:443 -servername NAME      # shows the chain
```
`--resolve NAME:PORT:IP` makes curl use that IP for that name while still checking the certificate against the name.

## Renewal (my job, nothing does it automatically)
Short lifetimes limit how long a stolen key is useful, and force automation. `renew_cert.sh`: `tailscale cert` with `--cert-file`/`--key-file` absolute paths → `nginx -t` → `systemctl reload nginx` (nginx only re-reads certificates on reload). Run by `renew_cert.timer` weekly. See `linux/systemd-timers.md`.
- `tailscale cert` reuses a still-valid certificate, so the dates won't change today. Real proof is later.
- **Reminder: around Jan 15 2027, run `openssl x509 -in /etc/nginx/certs/<name>.crt -noout -enddate`** and confirm the date moved past Feb 11.
- If it ever fails, the site keeps working on the old certificate until it expires, so read `journalctl -u renew_cert.service`.

## Privacy note
Certificates are recorded in public logs, so the machine and tailnet names are visible publicly.
