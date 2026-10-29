#!/bin/bash
# Scope: ___________________________________________

# --- config ---
SOURCE_DIR="/home/ashen/bin"
BACKUP_DIR="/home/ashen/backups"
RETENTION_DAYS=7

# --- make sure destination exists ---
mkdir -p "$BACKUP_DIR"

# --- create the timestamped archive, check it worked ---
if tar -czf "$BACKUP_DIR/backup-$(date +%Y-%m-%d).tar.gz" "$SOURCE_DIR"; then
    echo "Backup succeeded: $(date)"
else
    echo "Backup FAILED: $(date)" >&2
    exit 1
fi

# --- delete archives older than retention window ---
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +7 -delete
