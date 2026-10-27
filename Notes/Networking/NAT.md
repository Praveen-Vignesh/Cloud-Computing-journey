# NAT & Port Forwarding

## What NAT is

Through **Network Address Translation (NAT)**, a router has one public IP
address, and that single public IP is shared among every device on the
local network.

A device out on the internet can reach anything in our network *only*
through this one public IP — our individual devices have **private IPs**
(e.g. `192.168.1.50`) that don't exist as far as the outside world is
concerned.

## Inbound vs Outbound

The whole behaviour of NAT comes down to this asymmetry:

### Inbound (reaching *in* to us) — blocked by default
A request arrives at our router first. The problem:
- The sender only knows the **router's public IP** — it has no idea which
  device inside is the target.
- The inbound packet carries only that public IP and a port. Private IPs
  aren't visible from outside, so there's **no information** telling the
  router which device to hand it to.
- With nothing to go on, the router **drops it**. (Not dumb — the info
  genuinely isn't there.)

### Outbound (reaching *out* to the internet) — works fine
We initiate the request. The router writes a temporary entry in its
**NAT table** (its logbook): *"this device started a conversation with
that server — route the reply back here."*

When the response returns, that logbook entry tells the router exactly
which device it's for, and it's routed correctly.

> **Therefore: through NAT, OUTBOUND is possible but INBOUND is not.**

## Port Forwarding

Port forwarding is how you *force* inbound to work — by writing a
**permanent** logbook entry by hand.

### Analogy
You live in flat 7, building on street 23. The internet knows
**street 23 has a building** (your router's public IP) but has no idea
which flat you're in. So any mail arrives at the building's mailbox
(the router) and stops there — it doesn't know which flat to deliver to.
→ *this is the inbound problem.*

Now you write a rule in the building's logbook: *"any mail arriving in
slot 2222, send it up to flat 7."* You've created a standing delivery
rule. → *this is port forwarding.*

### In real terms
You tell the router: **any request on public port 2222 → my device's
port 22.**


### Why it's a security hole
That logbook rule is permanent and open to *everyone* — every bot
scanning the internet can now knock on port 2222 and reach your SSH.
One rule = one exposed door. Each extra service = another door to
harden and watch.

## The two logbook entries (the key mental model)

Both inbound-outbound and port forwarding use the *same* NAT logbook —
the difference is who writes it and how long it lasts:

| | Who creates it | Lifetime |
|---|---|---|
| Outbound reply path | The router, automatically | Temporary (per conversation) |
| Port forward | You, manually | Permanent (standing rule) |

---
*See also: `tailscale.md` — how to reach the server from anywhere
without writing any inbound rule at all.*