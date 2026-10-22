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
