# Day 002 — October 24, 2026

**Filesystem & permissions**

> Learnt to read and change Linux file permissions and ownership, and where things live on the system.

---

## What I did

1. Read `ls -l` output properly — decoded the permission string for files, directories, and system files.
2. Practised `chmod` (numeric and symbolic) and `chown` on throwaway files.
3. Explored users and groups (`id`, `groups`, `/etc/passwd`, `/etc/group`).
4. Toured the filesystem layout (`/etc`, `/var`, `/opt`, `/home`) and disk tools (`df`, `du`, `lsblk`).

## Key commands

```bash
ls -l / ls -ld            # read permissions (-d for the directory itself)
chmod 644 file            # numeric permissions
chmod +x file             # symbolic: add execute
chown user:group file     # change ownership
id / groups               # which groups I belong to
df -h / du -sh ~ / lsblk  # disk space, usage, block devices
```

## Challenges & problems

_None recorded._

## Still don't understand

<!-- e.g. "when exactly group permission matters vs owner" — if you resolved it, note that it moved to the permissions note -->
