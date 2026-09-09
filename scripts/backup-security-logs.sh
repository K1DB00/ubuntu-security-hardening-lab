#!/bin/bash

# ============================================================
# Security Hardening Lab - Security Log Backup
# ============================================================

set -euo pipefail

BACKUP_DIR="/var/backups/security-logs"
AUDIT_REPORT_DIR="/var/log/security-audit-reports"
TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')
BACKUP_FILE="$BACKUP_DIR/security-logs-$TIMESTAMP.tar.gz"

mkdir -p "$BACKUP_DIR"
chown root:root "$BACKUP_DIR"
chmod 700 "$BACKUP_DIR"

FILES=()

# Security-related logs
[ -f /var/log/syslog ] && FILES+=("/var/log/syslog")
[ -f /var/log/auth.log ] && FILES+=("/var/log/auth.log")
[ -f /var/log/fail2ban.log ] && FILES+=("/var/log/fail2ban.log")
[ -f /var/log/audit/audit.log ] && FILES+=("/var/log/audit/audit.log")

# Generated audit reports
if [ -d "$AUDIT_REPORT_DIR" ]; then
    FILES+=("$AUDIT_REPORT_DIR")
fi

if [ "${#FILES[@]}" -eq 0 ]; then
    logger -t security-backup "ERROR: No security logs found to back up"
    echo "ERROR: No security logs found."
    exit 1
fi

tar -czf "$BACKUP_FILE" "${FILES[@]}"

chown root:root "$BACKUP_FILE"
chmod 600 "$BACKUP_FILE"

if [ -s "$BACKUP_FILE" ]; then
    logger -t security-backup \
        "Security log backup created successfully: $BACKUP_FILE"

    echo "Security log backup created successfully:"
    echo "$BACKUP_FILE"
    echo "Size: $(du -h "$BACKUP_FILE" | cut -f1)"
else
    logger -t security-backup "ERROR: Backup file is empty: $BACKUP_FILE"
    rm -f "$BACKUP_FILE"
    exit 1
fi
