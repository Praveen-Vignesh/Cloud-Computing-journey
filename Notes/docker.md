# Docker (as used on firelink)

## What a container is
A normal Linux process with three things done to it:
- **namespaces** limit what it can *see* (its own process table, network, filesystem root)
- **cgroups** limit what it can *use* (CPU, RAM)
- **a filesystem built from an image**

It is not a VM: there's no second kernel, it's the host kernel with blinkers on. That's also why handing a container the Docker socket is dangerous. It hands over root on the host.

## Image, container, volume
- **Image:** read-only layers, a frozen filesystem plus a default command. Built once, shared.
- **Container:** an image + a thin **writable layer** + a running process. Delete the container and that layer is gone.
- **Volume:** storage outside the container's life. If you can't answer "where does this app keep its state, and is that path a volume?", it isn't ready to run.

Two kinds:
| | Named volume | Bind mount |
|---|---|---|
| Written as | `memos_data:/var/opt/memos` | `/mnt/data/memos:/var/opt/memos` |
| Lives | Docker's folder, `/var/lib/docker/volumes/` (system disk) | Any host path you choose (e.g. the HDD) |
| Declared at top-level `volumes:` | Yes | No |
| Permissions | Docker handles it | You handle it |

Rule: look at the **left side of the colon**. A bare name is a named volume; a path starting with `/` is a bind mount.

## Compose file keys
| Key | Answers |
|---|---|
| `services:` (plural!) | What processes are in the stack |
| `image:` | Which image, **pin the tag** (don't use `latest`) |
| `container_name:` | A readable name |
| `ports:` | `host_ip:host_port:container_port` |
| `volumes:` | Persistent storage, host side : container side |
| `environment:` | Config the app reads at start. Only set what you need to override |
| `restart:` | `unless-stopped` brings it back after a crash or reboot |

The container port is whatever the app listens on inside. The docs tell you, you can't pick it.

## Translating `docker run` to compose
| flag | compose key |
|---|---|
| `--name` | `container_name:` |
| `--publish H:C` | `ports:` |
| `--volume H:C` | `volumes:` |
| `--restart` | `restart:` |
| `-e VAR=x` | `environment:` |
| last argument (image) | `image:` |
A leftover `version:` line at the top of old examples is obsolete. Ignore it.

## Ports and the firewall
- Docker publishes ports by writing its own firewall (iptables) rules, evaluated **before** ufw. So `ufw deny` does not stop a published port.
- Fix: bind to loopback, `127.0.0.1:HOST:CONTAINER`. Then nothing outside the machine can reach it, and a reverse proxy on the same machine can.
- nginx is *not* in Docker, so ufw does control it.

## Networking
Compose gives each stack a private network. Containers reach each other **by service name** (Docker runs a tiny DNS). If only another container needs a service, it needs no `ports:` at all.

## Users
Container processes have numeric UIDs (Memos: 10001). On a bind mount, that same **number** shows up as the file owner on the host (`ls -ln`), even though no such user exists there.

## Commands
```
docker compose config            # parse + print, catches typos without starting
docker compose up -d
docker compose ps
docker compose logs --tail 30
docker compose stop / start
docker compose down              # removes container + network, KEEPS volumes
docker compose down -v           # also deletes named volumes (and their data)
docker volume ls / inspect <name>
docker inspect <ctr> --format '{{json .Mounts}}'    # shows Type bind/volume
docker exec -it <ctr> <cmd>
docker image rm <image>          # only after no container uses it
```

## Gotchas
- A container is **not a systemd unit**. `systemctl status memos` says "not found". Use `docker compose ps`.
- Run `docker compose down -v` **before** deleting the volume declaration from the file, because `-v` only knows volumes the file declares.
- If a bind-mount host folder doesn't exist at start, Docker creates it **as root on whatever disk is there**, which is dangerous if the HDD failed to mount. See `linux/disks-and-mounting.md` (the `chattr +i` guard).
