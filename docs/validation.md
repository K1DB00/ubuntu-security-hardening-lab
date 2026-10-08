# Validation

## Purpose

This document summarizes how the controls in [architecture.md](architecture.md) were checked on the running hosts. Each section below links to the relevant effective-state file in `configs/` and the screenshots collected in `evidence/`.

## SSH

[`configs/ssh/effective-ssh-policy.txt`](../configs/ssh/effective-ssh-policy.txt) and [`evidence/ssh/effective-ssh-policy.png`](../evidence/ssh/effective-ssh-policy.png) show `sshd -T`'s effective policy on `sec-server`: `passwordauthentication no`, `permitrootlogin no`, `maxauthtries 3`, `allowusers adminsec`.

[`evidence/ssh/adminsec-login-success.png`](../evidence/ssh/adminsec-login-success.png) shows `adminsec` authenticating from `sec-workstation` with its key. [`evidence/ssh/ubuntu-login-denied.png`](../evidence/ssh/ubuntu-login-denied.png) shows a connection attempt as `ubuntu`, forced to public-key auth, rejected with `Permission denied (publickey)` — consistent with the configured access restriction on that account.

## Firewall

[`configs/ufw/effective-ufw-policy.txt`](../configs/ufw/effective-ufw-policy.txt) and [`evidence/firewall/effective-ufw-policy.png`](../evidence/firewall/effective-ufw-policy.png) both show `ufw status verbose` on `sec-server`: default deny incoming, the active allow rules, and TCP/6514 scoped to `192.168.223.128`.

## Fail2Ban

[`configs/fail2ban/effective-sshd-jail.txt`](../configs/fail2ban/effective-sshd-jail.txt) and [`evidence/fail2ban/sshd-jail-status.png`](../evidence/fail2ban/sshd-jail-status.png) show `systemctl is-active`/`is-enabled fail2ban` and `fail2ban-client status sshd`, with the jail's `maxretry`/`findtime`/`bantime` read back from the running service.

## auditd

[`configs/auditd/effective-audit-state.txt`](../configs/auditd/effective-audit-state.txt) and [`evidence/auditd/active-rules-and-status.png`](../evidence/auditd/active-rules-and-status.png) show `auditctl -l` and `auditctl -s`, confirming `enabled 2` — immutable mode from [`99-finalize.rules`](../configs/auditd/99-finalize.rules) is active.

[`evidence/auditd/privileged-command-attribution.png`](../evidence/auditd/privileged-command-attribution.png) is an `ausearch` record for a command run through `sudo`, showing `auid=adminsec` alongside `euid=root` on the same event — the original login identity preserved through privilege escalation.

## PAM stack

[`configs/pam/pam-stack-relevant-lines.txt`](../configs/pam/pam-stack-relevant-lines.txt) documents where `pam_faillock` and `pam_pwquality` are hooked into `common-auth`/`common-account`/`common-password`. [`evidence/pam/effective-pam-policy.png`](../evidence/pam/effective-pam-policy.png) confirms the values in [`pwquality.conf`](../configs/pam/pwquality.conf) and [`faillock.conf`](../configs/pam/faillock.conf) match what's installed on `sec-server`.

[`evidence/pam/weak-password-rejected.png`](../evidence/pam/weak-password-rejected.png) shows `pwquality` rejecting a weak password during a `passwd` attempt (`BAD PASSWORD: The password contains less than 1 uppercase letters`).

## Certificates and mTLS

[`configs/rsyslog/server-certificate-metadata.txt`](../configs/rsyslog/server-certificate-metadata.txt) and [`configs/rsyslog/workstation-certificate-metadata.txt`](../configs/rsyslog/workstation-certificate-metadata.txt) document the installed certificates' subject, issuer, SAN, key usage, and file permissions, without including any key or certificate contents.

[`evidence/mtls/authorized-log-sent.png`](../evidence/mtls/authorized-log-sent.png) and [`evidence/mtls/authorized-log-received.png`](../evidence/mtls/authorized-log-received.png) show a tagged log line sent from `sec-workstation` and received on `sec-server` over the mTLS channel.

[`evidence/mtls/client-certificate-required.png`](../evidence/mtls/client-certificate-required.png) shows `rsyslogd` on `sec-server` rejecting a connection that didn't present a client certificate ("did not provide a certificate, not permitted to talk to it"), consistent with the mutual-authentication requirement.

## AppArmor

[`evidence/apparmor/rsyslog-enforcement.png`](../evidence/apparmor/rsyslog-enforcement.png) is `aa-status` output showing the `rsyslogd` process running under the packaged profile in enforce mode.

## IAM / identity model

[`evidence/iam/user-group-membership.png`](../evidence/iam/user-group-membership.png) shows `id`/`getent group` output for all three accounts: `adminsec` belongs to `sudo`, `auditor` belongs to `security-auditors`, and `ubuntu` has no additional group membership beyond its own primary group. [`evidence/iam/audit-report-permissions.png`](../evidence/iam/audit-report-permissions.png) shows the report directory and files carrying `root:security-auditors` ownership at `0750`/`0640`, matching what [`generate-audit-report.sh`](../scripts/generate-audit-report.sh) sets.

## Automation

[`configs/cron/root-crontab`](../configs/cron/root-crontab) notes that `cron` is active and enabled at boot, and [`evidence/automation/scheduled-tasks.png`](../evidence/automation/scheduled-tasks.png) shows the live `crontab -l` on `sec-server` with the four jobs loaded.

[`evidence/automation/generated-outputs.png`](../evidence/automation/generated-outputs.png) is a directory listing showing audit reports and backup archives for two consecutive days, plus a recent entry in the monitoring log — evidence the jobs are producing dated output on schedule.

## Limitations

A few things aren't covered by the evidence above. `pam_faillock`'s lockout behavior — an account actually locking after 5 failed attempts and unlocking after 300 seconds — isn't demonstrated, only its configuration and PAM stack wiring are. The 30-day retention logic in [`generate-audit-report.sh`](../scripts/generate-audit-report.sh) and [`cleanup-backups.sh`](../scripts/cleanup-backups.sh) hasn't been observed actually removing files once they age past that point. No backup archive has been extracted or restored to confirm its integrity. And the mTLS negative test on record shows rejection of a connection with no client certificate, not rejection of a certificate issued to an unauthorized identity. These gaps aren't claims that the behavior fails — they're simply not covered by a tracked artifact.
