#!/bin/bash

REPORT_DIR="/var/log/security-audit-reports"
REPORT_DATE=$(date '+%Y-%m-%d')
REPORT="$REPORT_DIR/security-audit-$REPORT_DATE.txt"

HOST=$(hostname)
DATE=$(date '+%Y-%m-%d %H:%M:%S')
START_TIME="yesterday"

mkdir -p "$REPORT_DIR"
chown root:security-auditors "$REPORT_DIR"
chmod 750 "$REPORT_DIR"

{
echo "============================================================"
echo "              SECURITY AUDIT REPORT"
echo "============================================================"
echo
echo "Host: $HOST"
echo "Generated: $DATE"
echo "Time window: Last 24 hours"
echo

echo "============================================================"
echo "1. EXECUTIVE SUMMARY"
echo "============================================================"

echo "Failed authentications:"
ausearch -m USER_AUTH -sv no -ts "$START_TIME" 2>/dev/null | grep -c '^type=USER_AUTH' || true

echo "Failed logins:"
ausearch -m USER_LOGIN -sv no -ts "$START_TIME" 2>/dev/null | grep -c '^type=USER_LOGIN' || true

echo "Privileged command events:"
ausearch -k privileged_commands -ts "$START_TIME" 2>/dev/null | grep -c '^type=SYSCALL' || true

echo "Identity change events:"
ausearch -k identity_changes -ts "$START_TIME" 2>/dev/null | grep -c '^type=SYSCALL' || true

echo "Privilege configuration change events:"
ausearch -k privilege_changes -ts "$START_TIME" 2>/dev/null | grep -c '^type=SYSCALL' || true

echo "SSH configuration change events:"
ausearch -k ssh_config_changes -ts "$START_TIME" 2>/dev/null | grep -c '^type=SYSCALL' || true

echo "Logging configuration change events:"
ausearch -k logging_changes -ts "$START_TIME" 2>/dev/null | grep -c '^type=SYSCALL' || true

echo "AppArmor configuration change events:"
ausearch -k apparmor_changes -ts "$START_TIME" 2>/dev/null | grep -c '^type=SYSCALL' || true

echo

echo "============================================================"
echo "2. AUDIT SUMMARY"
echo "============================================================"
aureport --summary -ts "$START_TIME"
echo

echo "============================================================"
echo "3. AUTHENTICATION REPORT"
echo "============================================================"
aureport --auth -ts "$START_TIME"
echo

echo "============================================================"
echo "4. LOGIN REPORT"
echo "============================================================"
aureport --login -ts "$START_TIME"
echo

echo "============================================================"
echo "5. IDENTITY CHANGES"
echo "============================================================"
ausearch -k identity_changes -ts "$START_TIME" -i 2>/dev/null || true
echo

echo "============================================================"
echo "6. PRIVILEGE CONFIGURATION CHANGES"
echo "============================================================"
ausearch -k privilege_changes -ts "$START_TIME" -i 2>/dev/null || true
echo

echo "============================================================"
echo "7. PRIVILEGED COMMAND EXECUTION"
echo "============================================================"
ausearch -k privileged_commands -ts "$START_TIME" -i 2>/dev/null || true
echo

echo "============================================================"
echo "8. SSH CONFIGURATION CHANGES"
echo "============================================================"
ausearch -k ssh_config_changes -ts "$START_TIME" -i 2>/dev/null || true
echo

echo "============================================================"
echo "9. SECURE LOGGING CONFIGURATION CHANGES"
echo "============================================================"
ausearch -k logging_changes -ts "$START_TIME" -i 2>/dev/null || true
echo

echo "============================================================"
echo "10. APPARMOR CONFIGURATION CHANGES"
echo "============================================================"
ausearch -k apparmor_changes -ts "$START_TIME" -i 2>/dev/null || true
echo

echo "============================================================"
echo "11. AUDIT CONFIGURATION CHANGES"
echo "============================================================"
ausearch -k audit_config_changes -ts "$START_TIME" -i 2>/dev/null || true
echo

echo "============================================================"
echo "                   END OF REPORT"
echo "============================================================"

} > "$REPORT"

chown root:security-auditors "$REPORT"
chmod 640 "$REPORT"

# Delete reports older than 30 days
find "$REPORT_DIR" \
    -type f \
    -name 'security-audit-*.txt' \
    -mtime +30 \
    -delete

echo "Security audit report generated:"
echo "$REPORT"
