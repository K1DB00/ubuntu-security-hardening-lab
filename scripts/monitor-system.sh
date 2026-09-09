#!/bin/bash

# ============================================================
# Security Hardening Lab - System Resource Monitor
# ============================================================

HOST=$(hostname)
DATE=$(date '+%Y-%m-%d %H:%M:%S')

DISK_THRESHOLD=80
MEM_THRESHOLD=85
LOAD_THRESHOLD=2.00

echo "============================================================"
echo "SYSTEM MONITOR - $HOST"
echo "Timestamp: $DATE"
echo "============================================================"

# Disk usage
DISK_USAGE=$(df / --output=pcent | tail -1 | tr -dc '0-9')
echo "Disk usage: ${DISK_USAGE}%"

if [ "$DISK_USAGE" -ge "$DISK_THRESHOLD" ]; then
    MESSAGE="WARNING: Disk usage on $HOST is ${DISK_USAGE}%"
    echo "$MESSAGE"
    logger -t security-monitor "$MESSAGE"
fi

# Memory usage
MEM_USAGE=$(free | awk '/Mem:/ {printf("%.0f"), $3/$2 * 100}')
echo "Memory usage: ${MEM_USAGE}%"

if [ "$MEM_USAGE" -ge "$MEM_THRESHOLD" ]; then
    MESSAGE="WARNING: Memory usage on $HOST is ${MEM_USAGE}%"
    echo "$MESSAGE"
    logger -t security-monitor "$MESSAGE"
fi

# Load average
LOAD=$(awk '{print $1}' /proc/loadavg)
echo "Load average (1 min): $LOAD"

if awk "BEGIN {exit !($LOAD >= $LOAD_THRESHOLD)}"; then
    MESSAGE="WARNING: High system load on $HOST: $LOAD"
    echo "$MESSAGE"
    logger -t security-monitor "$MESSAGE"
fi

echo
echo "Uptime:"
uptime -p

echo
echo "Top 5 processes by memory usage:"
ps -eo pid,user,comm,%mem,%cpu --sort=-%mem | head -6

echo
echo "Monitoring completed."
