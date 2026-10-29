# Day 001 — October 23, 2026

**Hardened SSH and locked down the firewall**

> First working day. Took a fresh Ubuntu Server install (SSH + ethernet only) and made it reachable *only* by key-based SSH from my own machine, with nothing else exposed.

---

## What I did

1. **Set up the base Ubuntu server** and generated an `ed25519` key-pair (`ssh-keygen`) to connect to it.
2. **Allowed key-based authentication only** — copied the public key to the server's `authorized_keys`, confirmed key login worked *before* changing anything else.
3. **Disabled password authentication and root login** in `sshd_config`, so the only way in is my key.
4. **Set up the `ufw` firewall** with a default-deny policy, allowing only port 22 (SSH).

## What I built

A hardened Ubuntu server: key-only SSH access, no password or root login, and a firewall that drops everything except SSH. First committed config: `sshd_config`.

## Key commands

```bash
ssh-keygen -t ed25519            # generate the key-pair (on Windows)
sudo nano /etc/ssh/sshd_config   # PasswordAuthentication no, PermitRootLogin no
sudo sshd -t                     # validate config before restarting
sudo systemctl restart ssh
sudo ufw allow 22
sudo ufw default deny incoming
sudo ufw enable
sudo ufw status verbose
```

## Challenges & problems

_None recorded — went smoothly._

## Still don't understand

<!-- fill this in — even "nothing today" is a valid entry -->
