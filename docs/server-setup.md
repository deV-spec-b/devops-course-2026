# Конфигурация виртуальной машины devops-vm

## 1. Параметры машины
- Оперативная память: 2048 МБ
- Процессоры: 2
- Диск: 25 ГБ (динамический)
- ОС: Ubuntu Server 24.04 LTS

## 2. Сетевые интерфейсы
- Адаптер 1 (NAT): 10.0.2.15 — доступ в интернет
- Адаптер 2 (Host-only): 192.168.56.101 — доступ с хоста

## 3. Правило проброса портов
- Порт хоста: 2222
- Порт гостя: 2222 (после hardening; изначально было 22)
- Протокол: TCP
- Имя правила: ssh

## 4. Учётные записи
- student — создан при установке, в группе sudo
- devops — создан вручную, в группе sudo, аутентификация только по ключу
  (ключ ~/.ssh/devops_vm на хосте, authorized_keys на сервере)

## 5. Служба SSH
- Порт: 2222
- Конфигурация: /etc/ssh/sshd_config.d/99-hardening.conf
- Изменённые директивы:
  - PermitRootLogin no
  - PasswordAuthentication no
  - PubkeyAuthentication yes
  - MaxAuthTries 3
  - AllowUsers devops
  - LoginGraceTime 30
  - X11Forwarding no

## 6. Файрвол (UFW)
- Default: deny incoming, allow outgoing
- 2222/tcp: limit
- 80/tcp, 443/tcp: allow
- Logging: medium

## 7. Веб-сервер
- Версия Nginx: 1.24.0
- Каталог ресурса: /var/www/devops-site
- Имя ресурса: devops.local
- Порты: 80 (редирект на HTTPS), 443 (HTTPS)
- Сертификат: /etc/ssl/certs/devops.crt (самоподписанный)
- Закрытый ключ: /etc/ssl/private/devops.key
- Права: 755 на каталог, 644 на файлы, владелец devops
- Команда доставки: scripts/deploy.sh# Конфигурация виртуальной машины devops-vm

## 1. Параметры машины
- Оперативная память: 2048 МБ
- Процессоры: 2
- Диск: 25 ГБ (динамический)
- ОС: Ubuntu Server 24.04 LTS

## 2. Сетевые интерфейсы
- Адаптер 1 (NAT): 10.0.2.15 — доступ в интернет
- Адаптер 2 (Host-only): 192.168.56.101 — доступ с хоста

## 3. Правило проброса портов
- Порт хоста: 2222
- Порт гостя: 2222 (после hardening; изначально было 22)
- Протокол: TCP
- Имя правила: ssh

## 4. Учётные записи
- student — создан при установке, в группе sudo
- devops — создан вручную, в группе sudo, аутентификация только по ключу
  (ключ ~/.ssh/devops_vm на хосте, authorized_keys на сервере)

## 5. Служба SSH
- Порт: 2222
- Конфигурация: /etc/ssh/sshd_config.d/99-hardening.conf
- Изменённые директивы:
  - PermitRootLogin no
  - PasswordAuthentication no
  - PubkeyAuthentication yes
  - MaxAuthTries 3
  - AllowUsers devops
  - LoginGraceTime 30
  - X11Forwarding no
  - ClientAliveInterval 300
  - ClientAliveCountMax 2
- Служба переведена с ssh.socket на ssh.service
- Вход: ssh devops (через ~/.ssh/config)

## 6. Правила межсетевого экрана
- Default: deny incoming, allow outgoing
- 2222/tcp LIMIT IN (SSH rate-limited)
- 80/tcp ALLOW IN (HTTP)
- 443/tcp ALLOW IN (HTTPS)
- Логирование: medium

## 7. Снимки состояния
- 01-clean-install — после установки и обновления
- 02-keys-configured — после настройки ключей
- 03-ssh-hardened — после hardening SSH

## 9. Контейнеризация

### Установка Docker Engine
Docker Engine установлен из официального репозитория Docker (не из репозитория Ubuntu).  
Версия: Docker Engine 29.9.2, Docker Compose v5.6.1.

### Участники группы docker
Пользователь `devops` добавлен в группу `docker` и может запускать контейнеры без sudo.

### Расположение проекта
Проект находится на сервере в каталоге `/home/devops/app`.

### Файл .env
Файл `/home/devops/app/.env` содержит секреты (пароль базы) и имеет права `600`.  
В репозиторий не попадает (указан в `.gitignore`). На сервере создаётся из `.env.example` с генерацией случайного пароля.

### Публикуемые порты
- Приложение публикуется только на `127.0.0.1:5000` (недоступно извне напрямую).
- Порт базы данных (5432) не публикуется на хост. Доступ только внутри сети Compose.

### Именованные тома
Данные PostgreSQL хранятся в именованном томе `app_db_data`. Том сохраняется при `docker compose down` и удаляется только при `docker compose down -v`.

### Обратный прокси
Nginx принимает HTTPS-запросы на `/app/` и проксирует их на `http://127.0.0.1:5000/`.  
Статический сайт остаётся доступен по корню `/`.