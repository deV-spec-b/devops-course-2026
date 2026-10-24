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

echo ""
echo "=== [5] Контейнеризация ==="

check "Docker service is active" "systemctl is-active --quiet docker"

check "DB container is healthy" "docker inspect -f '{{.State.Health.Status}}' app-db-1 2>/dev/null | grep -q healthy"

check "Port 5000 only on 127.0.0.1" "! ss -tln | grep -E ':5000 ' | grep -v '127.0.0.1'"

check "Port 5432 not published on host" "! ss -tln | grep -q ':5432 '"

check ".env permissions are 600" "[ \"\$(stat -c %a /home/devops/app/.env 2>/dev/null)\" = \"600\" ]"

exit $fail