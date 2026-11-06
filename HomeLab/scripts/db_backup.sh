#!/bin/bash

set -euo pipefail

BACKUP_DIR = /opt/postgres/backups
FILE = "$BACKUP_DIR/pg_$(date +%F_%H%M).sql.gz"

mkdir -p "$BACKUP_DIR"

docker exec postgres-dev pg_dump -U postgres postgres | gzip > "$FILE"

find "$BACKUP_DIR" -name '*.sql.gz' -mtime +7 -delete