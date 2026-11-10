# Tailscale

## What it is
A mesh VPN built on WireGuard. Every device you sign in becomes part of your **tailnet** and gets:
- a stable private address in `100.x.y.z` (Tailscale uses the `100.64.0.0/10` range)
- a MagicDNS name: `<machine>.<tailnet>.ts.net` (mine: `firelink.taild258c2.ts.net`)

On Linux the daemon is `tailscaled` and the network interface is **`tailscale0`**.

## Why it fits a homelab
- You can reach firelink from anywhere without opening a port on your router. Tailscale's coordination server helps two devices find each other and punch through NAT, then traffic flows device to device, encrypted.
- Only devices signed into your tailnet can reach it. That's an access layer *before* any firewall rule.
- Firewall rules can be written per interface: `ufw allow in on tailscale0 to any port 443 proto tcp` means "443 from the tailnet only". The home LAN gets nothing.

## Everyday commands
- `tailscale status`: machines on the tailnet, and whether you're connected
- `tailscale ip`: this machine's tailnet address
- `tailscale cert <full-name>`: fetch an HTTPS certificate (see `tls-and-certificates.md`)
- `tailscale cert --help`: flags for the output file names

## HTTPS certificates
1. Admin console → **DNS** page → make sure **MagicDNS** is on → enable **HTTPS Certificates**.
2. Run `sudo tailscale cert <full-name>`. It writes `<name>.crt` (public) and `<name>.key` (secret).
3. Certificates are **short-lived (90 days)** and `tailscale cert` does not renew them on its own. You own renewal.
4. Enabling HTTPS means your machine and tailnet names show up in public certificate logs. Fine for a personal tailnet, but know it.

## Gotchas
- **Restarting `tailscaled` over an SSH session that runs through Tailscale drops the session** for a few seconds. Use `tmux`, or reconnect.
- `TS_PERMIT_CERT_UID` (in `/etc/default/tailscaled`) is only needed when a **non-root** program such as Caddy fetches certificates itself. With nginx I run `tailscale cert` as root, so it isn't needed.
- If `tailscale cert` fails: HTTPS not enabled in the console, MagicDNS off, or the name isn't exactly the machine's full name.
