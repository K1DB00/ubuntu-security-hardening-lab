#!/bin/bash

# ============================================================
# Security Hardening Lab - Backup Retention
# ============================================================

set -euo pipefail

BACKUP_DIR="/var/backups/security-logs"
RETENTION_DAYS=30

if [ ! -d "$BACKUP_DIR" ]; then
    logger -t security-backup \
        "WARNING: Backup directory does not exist: $BACKUP_DIR"
    echo "Backup directory does not exist: $BACKUP_DIR"
    exit 0
fi

DELETED_COUNT=0

while IFS= read -r -d '' FILE; do
    rm -f -- "$FILE"
    DELETED_COUNT=$((DELETED_COUNT + 1))
done < <(
    find "$BACKUP_DIR" \
        -type f \
        -name 'security-logs-*.tar.gz' \
        -mtime +"$RETENTION_DAYS" \
        -print0
)

logger -t security-backup \
    "Backup retention completed: $DELETED_COUNT backup(s) older than $RETENTION_DAYS days removed"

echo "Backup retention completed."
echo "Retention period: $RETENTION_DAYS days"
echo "Backups removed: $DELETED_COUNT"
