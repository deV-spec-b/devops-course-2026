#!/usr/bin/env bash
set -uo pipefail

PASS=0; FAIL=0

check() {
    local desc="$1" expected="$2" actual="$3"
    if [[ "$actual" == "$expected" ]]; then
        echo "  [OK]   $desc"; ((PASS++))
    else
        echo "  [FAIL] $desc (ожидалось: '$expected', получено: '$actual')"; ((FAIL++))
    fi
}

echo "Аудит конфигурации: $(hostname -f), $(date '+%Y-%m-%d %H:%M')"

echo "[1] Служба SSH"
check "Вход от имени root запрещён"        "no"  "$(sudo sshd -T | awk '/^permitrootlogin/{print $2}')"
check "Парольная аутентификация отключена" "no"  "$(sudo sshd -T | awk '/^passwordauthentication/{print $2}')"

PORT=$(sudo sshd -T | awk '/^port /{print $2}')
if [[ "$PORT" != "22" ]]; then
    echo "  [OK]   Порт SSH отличен от 22 (текущий: $PORT)"; ((PASS++))
else
    echo "  [FAIL] Порт SSH отличен от 22 (ожидалось: не 22, получено: $PORT)"; ((FAIL++))
fi

check "MaxAuthTries равен 3" "3" "$(sudo sshd -T | awk '/^maxauthtries/{print $2}')"

echo "[2] Межсетевой экран"
check "Межсетевой экран активен" "active" "$(sudo ufw status | awk '/^Status:/{print $2}')"

DEFAULT=$(sudo ufw status verbose | grep -i "Default:" | grep -o "deny (incoming)" || true)
if [[ -n "$DEFAULT" ]]; then
    echo "  [OK]   Политика входящего трафика: deny"; ((PASS++))
else
    echo "  [FAIL] Политика входящего трафика: deny (не найдено)"; ((FAIL++))
fi

echo "[3] Учётные записи"
awk -F: '$3>=1000 && $3<65534 {printf "    %s (uid=%s)\n",$1,$3}' /etc/passwd

echo "Пройдено: $PASS, не пройдено: $FAIL"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
