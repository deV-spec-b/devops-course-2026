#!/usr/bin/env bash
# Проверка конфигурации devops-vm
set -euo pipefail

fail=0

check() {
    local name="$1"
    local cmd="$2"
    if eval "$cmd" >/dev/null 2>&1; then
        echo "OK: $name"
    else
        echo "FAIL: $name"
        fail=1
    fi
}

echo "=== Аудит конфигурации ==="

# SSH
check "PermitRootLogin no" "sudo sshd -T | grep -qi 'permitrootlogin no'"
check "PasswordAuthentication no" "sudo sshd -T | grep -qi 'passwordauthentication no'"

# Firewall
check "UFW active" "sudo ufw status | grep -q 'Status: active'"
check "UFW default deny incoming" "sudo ufw status verbose | grep -q 'deny (incoming)'"

# Web server
check "Nginx is running" "systemctl is-active --quiet nginx"
check "Port 443 is listening" "ss -tln | grep -q ':443'"
check "Site directory permissions 755" "[[ \$(stat -c %a /var/www/devops-site) == 755 ]]"

echo "=== Конец аудита ==="
exit $fail
