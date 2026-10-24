#!/usr/bin/env bash
# Доставка статического ресурса на devops-vm
# Использование: scripts/deploy.sh [--dry-run]
set -euo pipefail

REMOTE="devops"
REMOTE_DIR="/var/www/devops-site"
SITE_URL="https://devops.local"
CA_CERT="${HOME}/devops.crt"
LOCAL_DIR="$(git rev-parse --show-toplevel)/site/"

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
fi

# Требование 4: наличие index.html
if [[ ! -f "${LOCAL_DIR}index.html" ]]; then
    echo "Ошибка: файл site/index.html отсутствует" >&2
    exit 1
fi

# Требование 5: нет незафиксированных изменений
if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "Ошибка: есть незафиксированные изменения в репозитории" >&2
    exit 1
fi

# Требование 3 + 8 + 9: один rsync через SSH с BatchMode
RSYNC_OPTS=(-avz --delete --chmod=D755,F644 -e "ssh -o BatchMode=yes -o ConnectTimeout=5")
if $DRY_RUN; then
    RSYNC_OPTS+=(--dry-run)
fi

rsync "${RSYNC_OPTS[@]}" "${LOCAL_DIR}" "${REMOTE}:${REMOTE_DIR}"

if $DRY_RUN; then
    echo "Dry-run завершён, изменения не применены"
    exit 0
fi

# Требование 6: проверка доступности с сертификатом
if ! curl -f --cacert "${CA_CERT}" -s -o /dev/null "${SITE_URL}"; then
    echo "Ошибка: ресурс недоступен после доставки" >&2
    exit 1
fi

# Требование 7: короткий хеш коммита
echo "Доставлен коммит: $(git rev-parse --short HEAD)"
exit 0
