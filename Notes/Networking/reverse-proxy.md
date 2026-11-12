# Reverse proxies: Caddy (Day 8) and nginx (Day 10)

## The idea
A **reverse proxy** stands in front of your apps like a receptionist. Visitors talk only to it; it fetches the answer from the right app behind it and hands it back.
- One front door (ports 80/443) for many apps, which are hidden on `127.0.0.1`.
- TLS handled in one place instead of in every app.
- One place for logs, limits, blocking.
(A *forward* proxy is the opposite: it stands in front of the visitors.)

**A reverse proxy doesn't forward your connection, it makes a second one.** There are two conversations: visitor ↔ nginx, and nginx ↔ app. Everything about headers follows from that.

## A request is a letter with two parts
1. **Where to deliver**: IP + port (`127.0.0.1:8080`)
2. **Who it says it's for**: the `Host:` header, text inside the request

They normally match, but they don't have to. `curl -H "Host: notes.example" http://127.0.0.1:8080` delivers to one place but writes a different name inside. This is how one machine hosts many sites.

## Caddy (Day 8)
```
localhost {
    reverse_proxy localhost:9000
    tls internal
}
```
- `tls internal`: Caddy signs with its own private CA, so browsers warn unless you run `sudo caddy trust`.
- Loop: `caddy validate` → `caddy fmt` → `systemctl reload caddy` → watch `journalctl -u caddy`.
- Missing space before `{` is a syntax error.
- Why I moved on: Caddy hides certificates, headers and renewal behind defaults, so I couldn't see what the proxy layer was doing.

## nginx layout (nginx.org package on firelink)
- `user nginx;` → workers run as the `nginx` user. The **master runs as root** (reads config and certs, owns ports).
- Config is **nested boxes (contexts)**: `main` → `events` / `http` → `server` → `location`. Directives end in `;`, boxes use `{ }`.
- `http { include /etc/nginx/conf.d/*.conf; }` loads every file in `conf.d/`. There's no `sites-available`/`sites-enabled` here.
- My layout, one file per door: `nginx.conf` (globals), `conf.d/memos.conf` (443), `conf.d/redirect.conf` (80), `conf.d/static.conf` (8443).

## How nginx picks what answers
**Round 1, which `server` block:** match the connection's address+port against every `listen`; among those, match the `Host:` header against `server_name`; if none match, the `default_server` for that port answers.
**Round 2, which `location`:** exact match `= /x` wins; otherwise the longest matching prefix is remembered; then regex locations (`~`) are tried in file order and win over the prefix, unless the prefix was `^~`.

## Serving files
`root /data/www;` **joins** the URL path onto the folder: `/index.html` → `/data/www/index.html`.
- Gotcha: `location /images/ { root /data/images; }` looks in `/data/images/images/…`. Use `root /data;` (or `alias`, which *replaces* the matched prefix).
- 403 = nginx can't read the file (worker user is `nginx`). 404 = path doesn't exist.
- `mime.types` must be included (`include /etc/nginx/mime.types;`), otherwise `.html` is served as `application/octet-stream` and browsers download it.

## Proxying
```
location / {
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_pass http://127.0.0.1:5230;
}
```
- `proxy_pass` is **only allowed inside `location`** (error: "directive is not allowed here"). Look up any directive's **Context** line at `nginx.org/r/<directive>`.
- By default nginx replaces `Host` with the backend's own address (`$proxy_host`) and sets `Connection: close`, so the app never learns what name the visitor typed.
| header | gives the app |
|---|---|
| `Host $host` | the name the visitor asked for |
| `X-Real-IP $remote_addr` | the visitor's address (else it only sees 127.0.0.1) |
| `X-Forwarded-For $proxy_add_x_forwarded_for` | the chain of addresses, appended if already present |
| `X-Forwarded-Proto $scheme` | `http` or `https`. Essential once TLS ends at nginx |
`X-…` headers are a convention. The app only uses them if written to, and should only trust them from a proxy it knows.
- `$host` = name without port; `$http_host` = raw header; `$proxy_host` = the backend's address.
- `proxy_set_header` is inherited only if the current level defines none of its own, so set them all in one block.
- **Trailing slash rule:** if `proxy_pass` has any path part (even `/`), the matched `location` prefix is *replaced* by it; with no path part, the URL passes through unchanged.
- To *see* what nginx sends the backend: `sudo tcpdump -i lo -A -nn -l port 5230`.

## Status codes at a proxy
| code | who failed | look at |
|---|---|---|
| 403 / 404 | nginx files / path | `error.log` |
| 502 Bad Gateway | the backend refused or sent junk (stopped, wrong port) | `error.log` says "connection refused" |
| 504 Gateway Timeout | the backend didn't answer in time | `error.log` |
Access log = what was asked and answered. Error log = why.

## Working habits
- `sudo nginx -t` → `sudo systemctl reload nginx` → check logs. **Always `sudo`**: without it `nginx -t` fails on the log file and the root-only key (that's the lock working).
- Reload starts new workers on the new config and lets old ones finish, so it never drops connections. A failed `-t` leaves the old config running.
- `sudo nginx -T` dumps the full config nginx actually loaded.
- Docs: nginx.org, the `ngx_http_proxy_module` and `ngx_http_ssl_module` pages. Check "appeared in version X" against `nginx -v`.

## Redirect 80 → 443
```
server {
    listen 80 default_server;
    server_name firelink.taild258c2.ts.net;
    return 301 https://firelink.taild258c2.ts.net$request_uri;
}
```
A redirect makes the **browser** make a new request. A proxy makes **nginx** do it. Browsers cache 301s aggressively, so test with `curl -I` first.
