# Day 004 — October 26, 2026

**Tailscale / tailnet — reaching the server from anywhere *without* port forwarding**

> Set up a private virtual network (tailnet) so I can SSH to my server from any network, with no ports exposed to the public internet.

---

## What I did

1. Created a Tailscale account.
2. Added my server as a device on the tailnet.
3. Added my Windows PC as a device too, putting both on the same private network so they can reach each other directly.

## What I learnt

- A lot about networking: **NAT**, private virtual networks, **port forwarding** and why it's unsafe.
- Why port forwarding exposes a permanent public door for every bot to find — and how **Tailscale avoids that entirely** by never exposing a port at all.
- How Tailscale connects two devices behind NAT: outbound-only connections to a **coordination server**, **NAT hole-punching**, and a direct encrypted **WireGuard** tunnel (with **DERP** as a relay fallback).

> Full conceptual notes are in `Notes/networking/` (`NAT.md`, `tailscale.md`).

## Key commands

```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up          # authenticate via the printed URL
tailscale ip -4            # the server's 100.x address
tailscale status           # devices on the tailnet
ssh praveen@100.x.x.x      # connect over the tailnet
```

## Still to do

- The real proof: SSH from a network that **isn't** my home (college / mobile hotspot). A connection from home doesn't yet demonstrate the point.

## Still don't understand

<!-- e.g. how NAT hole-punching tricks two routers into a direct connection -->
