#!/bin/bash
# ===========================================
# Bitrix Docker Entrypoint Script
# ===========================================

set -e

# Default values
: "${USER_ID:=1000}"
: "${GROUP_ID:=1000}"
: "${SITE_DOMAIN:=localhost}"
: "${SITE_IP:=127.0.0.1}"
: "${PROXY_IPS:=127.0.0.1 127.0.0.2}"
: "${MEMORY_LIMIT:=512M}"
: "${MBSTRING_FUNC_OVERLOAD:=0}"
: "${PHP_EX_OPCACHE_ENABLED:=1}"
: "${PHP_INI_TYPE:=development}"
: "${ENABLE_SSL:=0}"
: "${BX_TIMEZONE:=Europe/Moscow}"
: "${TZ:=$BX_TIMEZONE}"
: "${SMTP_HOST:=mailhog}"
: "${SMTP_PORT:=1025}"
: "${SMTP_EMAIL:=noreply@localhost}"
: "${SMTP_PASSWORD:=}"

# Paths
PHP_CONFIG_DIR="/usr/local/etc/php/conf.d"
PHP_CONFIG_FILE_EX="${PHP_CONFIG_DIR}/zzzz-bitrix-runtime.ini"
BITRIX_PATH="/var/www/html"
SESSION_PATH="/var/www/session"
BITRIX_INDEX="${BITRIX_PATH}/index.php"
BITRIX_SETUP="${BITRIX_PATH}/bitrixsetup.php"

echo "=== Bitrix Docker Container Starting ==="
echo "PHP_INI_TYPE: ${PHP_INI_TYPE}"
echo "MEMORY_LIMIT: ${MEMORY_LIMIT}"
echo "SITE_DOMAIN: ${SITE_DOMAIN}"

# 1. Set user/group IDs for www-data
if [ "${USER_ID}" != "33" ]; then
    echo "Setting www-data UID to ${USER_ID}"
    usermod -u "${USER_ID}" www-data 2>/dev/null || true
fi
if [ "${GROUP_ID}" != "33" ]; then
    echo "Setting www-data GID to ${GROUP_ID}"
    groupmod -g "${GROUP_ID}" www-data 2>/dev/null || true
fi

# 2. Add site domain to hosts
echo "${SITE_IP} ${SITE_DOMAIN}" >> /etc/hosts

# 3. Configure RPAF for proxy (if available)
if [ -f /etc/apache2/mods-available/rpaf.conf ]; then
    sed -i "s/RPAFproxy_ips.*/RPAFproxy_ips ${PROXY_IPS}/" /etc/apache2/mods-available/rpaf.conf
fi

# 4. Select PHP configuration based on PHP_INI_TYPE
if [ "${PHP_INI_TYPE}" = "production" ]; then
    echo "Using production PHP configuration"
    cp /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini 2>/dev/null || true
else
    echo "Using development PHP configuration"
    cp /usr/local/etc/php/php.ini-development /usr/local/etc/php/php.ini 2>/dev/null || true
fi

# 4b. Select OPcache configuration based on PHP_INI_TYPE
if [ "${PHP_INI_TYPE}" = "production" ]; then
    echo "Using production OPcache configuration"
    cp /usr/local/share/bitrix/opcache-prod.ini ${PHP_CONFIG_DIR}/zzz-opcache.ini
else
    echo "Using development OPcache configuration"
    cp /usr/local/share/bitrix/opcache-dev.ini ${PHP_CONFIG_DIR}/zzz-opcache.ini
fi

# 5. Create runtime PHP configuration
echo "[php]" > "${PHP_CONFIG_FILE_EX}"
echo "memory_limit = ${MEMORY_LIMIT}" >> "${PHP_CONFIG_FILE_EX}"
echo "mbstring.func_overload = ${MBSTRING_FUNC_OVERLOAD}" >> "${PHP_CONFIG_FILE_EX}"
echo "date.timezone = ${TZ}" >> "${PHP_CONFIG_FILE_EX}"

# 6. OPcache configuration
echo "" >> "${PHP_CONFIG_FILE_EX}"
echo "[opcache]" >> "${PHP_CONFIG_FILE_EX}"
echo "opcache.enable = ${PHP_EX_OPCACHE_ENABLED}" >> "${PHP_CONFIG_FILE_EX}"
echo "opcache.enable_cli = ${PHP_EX_OPCACHE_ENABLED}" >> "${PHP_CONFIG_FILE_EX}"

# 7. Download Bitrix installer if needed
if [ ! -f "${BITRIX_INDEX}" ] && [ ! -f "${BITRIX_SETUP}" ]; then
    echo "Downloading Bitrix installer..."
    wget -q https://www.1c-bitrix.ru/download/scripts/bitrixsetup.php -O "${BITRIX_SETUP}" || true
    echo "<?php phpinfo(); ?>" > "${BITRIX_PATH}/info.php"
fi

# 8. Enable SSL if requested
if [ "${ENABLE_SSL}" = "1" ]; then
    echo "Enabling SSL virtual host..."
    a2ensite bitrix-ssl.conf 2>/dev/null || true
fi

# 9. Configure msmtp for mail
if [ -f /etc/msmtprc ]; then
    sed -i "s/#SMTP_HOST#/${SMTP_HOST}/" /etc/msmtprc
    sed -i "s/#SMTP_PORT#/${SMTP_PORT}/" /etc/msmtprc
    sed -i "s/#SMTP_EMAIL#/${SMTP_EMAIL}/g" /etc/msmtprc
    sed -i "s/#SMTP_PASSWORD#/${SMTP_PASSWORD}/" /etc/msmtprc
fi

# 10. Set file permissions
echo "Setting file permissions..."
chown -R www-data:www-data "${BITRIX_PATH}" 2>/dev/null || true
chown -R www-data:www-data "${SESSION_PATH}" 2>/dev/null || true

# Create log directories if not exist
mkdir -p /var/log/php
chown www-data:www-data /var/log/php

# Copy health check to web root
if [ -f /usr/local/share/bitrix/health.php ]; then
    cp /usr/local/share/bitrix/health.php "${BITRIX_PATH}/health.php"
    chown www-data:www-data "${BITRIX_PATH}/health.php"
fi

echo "=== Container Ready ==="

# Execute the main command
exec "$@"
