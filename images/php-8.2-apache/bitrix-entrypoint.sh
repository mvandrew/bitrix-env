#!/bin/bash
set -e

# Установка значений по умолчанию
PHP_INI_TYPE=${PHP_INI_TYPE:-development}
MBSTRING_FUNC_OVERLOAD=${MBSTRING_FUNC_OVERLOAD:-2}
PHP_MEMORY_LIMIT=${PHP_MEMORY_LIMIT:-64M}
TZ=${TZ:-Europe/Moscow}
UID=${UID:-1000}
GID=${GID:-1000}
SERVER_NAME=${SERVER_NAME:-mydomain.ru}
SERVER_IP=${SERVER_IP:-127.0.0.1}
PROXY_IPS=${PROXY_IPS:-"127.0.0.1 127.0.0.2"}

# Обновляем UID и GID пользователя
usermod -u "$UID" www-data
groupmod -g "$GID" www-data

# Настройка временной зоны
ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime
echo "$TZ" > /etc/timezone

# Конфигурация PHP
cp "/usr/local/etc/php/php.ini-$PHP_INI_TYPE" "/usr/local/etc/php/php.ini"
sed -i "s/^memory_limit.*/memory_limit = $PHP_MEMORY_LIMIT/" /usr/local/etc/php/php.ini
sed -i "s/^mbstring.func_overload.*/mbstring.func_overload = $MBSTRING_FUNC_OVERLOAD/" /usr/local/etc/php/php.ini
sed -i "s|;date.timezone =|date.timezone = \"$TZ\"|" /usr/local/etc/php/php.ini

# Настройка Apache
echo "ServerName $SERVER_NAME" >> /etc/apache2/apache2.conf

# Обновление /etc/hosts
echo "$SERVER_IP $SERVER_NAME" >> /etc/hosts

# Настройка RPAF для поддержки Proxy IPs
cat <<EOF > /etc/apache2/conf-available/rpaf.conf
<IfModule mod_rpaf.c>
    RPAFenable On
    RPAFsethostname On
    RPAFproxy_ips $PROXY_IPS
</IfModule>
EOF
a2enconf rpaf

# Запуск Apache
exec "$@"
