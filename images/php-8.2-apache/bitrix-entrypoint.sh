#!/bin/bash
set -e

# Установка значений по умолчанию
PHP_INI_TYPE=${PHP_INI_TYPE:-development}
MBSTRING_FUNC_OVERLOAD=${MBSTRING_FUNC_OVERLOAD:-2}
MEMORY_LIMIT=${MEMORY_LIMIT:-64M}
TZ=${TZ:-Europe/Moscow}
USER_ID=${USER_ID:-1000}
GROUP_ID=${GROUP_ID:-1000}
SITE_DOMAIN=${SITE_DOMAIN:-mydomain.ru}
SITE_IP=${SITE_IP:-127.0.0.1}
PROXY_IPS=${PROXY_IPS:-"127.0.0.1 127.0.0.2"}
ACCESS_LOG=${ACCESS_LOG:-/var/log/apache2/access.log}
ERROR_LOG=${ERROR_LOG:-/var/log/apache2/error.log}

# Пути для проверки и установки Битрикс
SESSION_PATH="/var/www/html"
BITRIX_PATH="${SESSION_PATH}"
BITRIX_INDEX="${BITRIX_PATH}/index.php"
BITRIX_INFO="${BITRIX_PATH}/info.php"
BITRIX_SETUP="${BITRIX_PATH}/bitrixsetup.php"

# Функция для проверки и загрузки установщика Битрикс
setup_bitrix_installer() {
    if [ ! -f "$BITRIX_INDEX" ] && [ ! -f "$BITRIX_SETUP" ]; then
        wget https://www.1c-bitrix.ru/download/scripts/bitrixsetup.php -O "$BITRIX_SETUP"
        echo "<?php phpinfo(); ?>" > "$BITRIX_INFO"
    fi
}

# Функция для проверки и создания логов, если они отсутствуют
setup_logs() {
    [ ! -f "$ACCESS_LOG" ] && touch "$ACCESS_LOG"
    [ ! -f "$ERROR_LOG" ] && touch "$ERROR_LOG"
    chown www-data:www-data "$ACCESS_LOG" "$ERROR_LOG"
}

# Обновляем USER_ID и GROUP_ID пользователя
usermod -u "$USER_ID" www-data
groupmod -g "$GROUP_ID" www-data

# Настройка временной зоны
ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime
echo "$TZ" > /etc/timezone

# Конфигурация PHP
cp "/usr/local/etc/php/php.ini-$PHP_INI_TYPE" "/usr/local/etc/php/php.ini"
sed -i "s/^memory_limit.*/memory_limit = $MEMORY_LIMIT/" /usr/local/etc/php/php.ini
sed -i "s/^mbstring.func_overload.*/mbstring.func_overload = $MBSTRING_FUNC_OVERLOAD/" /usr/local/etc/php/php.ini
sed -i "s|;date.timezone =|date.timezone = \"$TZ\"|" /usr/local/etc/php/php.ini

# Настройка Apache
echo "ServerName $SITE_DOMAIN" >> /etc/apache2/apache2.conf

# Обновление /etc/hosts
echo "$SITE_IP $SITE_DOMAIN" >> /etc/hosts

# Настройка RPAF для поддержки Proxy IPs
cat <<EOF > /etc/apache2/conf-available/rpaf.conf
<IfModule mod_rpaf.c>
    RPAFenable On
    RPAFsethostname On
    RPAFproxy_ips $PROXY_IPS
</IfModule>
EOF
a2enconf rpaf

# Настройка msmtp
cat <<EOF > /etc/msmtprc
account $SMTP_ACCOUNT
host $SMTP_HOST
port $SMTP_PORT
from $SMTP_EMAIL
auth $SMTP_AUTH
user $SMTP_USER
password $SMTP_PASSWORD
tls $SMTP_TLS
tls_starttls $SMTP_TLS
timeout 5

account default : $SMTP_ACCOUNT
EOF
chmod 600 /etc/msmtprc
chown www-data:www-data /etc/msmtprc

# Настройка логов
setup_logs

# Выполнение функции для загрузки установщика Битрикс
setup_bitrix_installer

# Запуск Apache
exec "$@"
