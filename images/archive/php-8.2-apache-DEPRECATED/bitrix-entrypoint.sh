#!/bin/sh

usermod -u "${USER_ID}" www-data
groupmod -g "${GROUP_ID}" www-data

# Добавление адреса сайта в файл hosts
echo "${SITE_IP} ${SITE_DOMAIN}" >> /etc/hosts

# Установка IP адресов прокси сервера в модуле rpaf
sed -i "s/RPAFproxy_ips.*/RPAFproxy_ips ${PROXY_IPS}/" /etc/apache2/mods-available/rpaf.conf

# Расширение конфигурации PHP
echo "[php]" > "${PHP_CONFIG_FILE_EX}" \
    && echo "memory_limit = ${MEMORY_LIMIT}" >> "${PHP_CONFIG_FILE_EX}" \
    && echo "mbstring.func_overload = ${MBSTRING_FUNC_OVERLOAD}" >> "${PHP_CONFIG_FILE_EX}"

# Проверка необходимости залить установщик Битрикс
SESSION_PATH="/var/www/html"
BITRIX_PATH="/var/www/html"
BITRIX_INDEX="${BITRIX_PATH}/index.php"
BITRIX_INFO="${BITRIX_PATH}/info.php"
BITRIX_SETUP="${BITRIX_PATH}/bitrixsetup.php"
if [ ! -f $BITRIX_INDEX ] && [ ! -f $BITRIX_SETUP ]; then
    wget https://www.1c-bitrix.ru/download/scripts/bitrixsetup.php -O $BITRIX_SETUP
    echo "<?php phpinfo(); ?>" > $BITRIX_INFO
fi

# Контроль запуска модуля opcache
echo "[opcache]" >> "${PHP_CONFIG_FILE_EX}" \
    && echo "opcache.enable = ${PHP_EX_OPCACHE_ENABLED}" >> "${PHP_CONFIG_FILE_EX}" \
    && echo "opcache.enable_cli = ${PHP_EX_OPCACHE_ENABLED}" >> "${PHP_CONFIG_FILE_EX}"

# Активация ssl виртуального хоста
if [ "$ENABLE_SSL" = 1 ]; then
  a2ensite bitrix-ssl.conf
fi

# Параметры доступа к почтовому серверу
sed -i "s/#SMTP_HOST#/${SMTP_HOST}/" /etc/msmtprc \
  && sed -i "s/#SMTP_PORT#/${SMTP_PORT}/" /etc/msmtprc \
  && sed -i "s/#SMTP_EMAIL#/${SMTP_EMAIL}/" /etc/msmtprc \
  && sed -i "s/#SMTP_PASSWORD#/${SMTP_PASSWORD}/" /etc/msmtprc

# Обновление прав доступа к файлам
chown -R www-data:www-data $BITRIX_PATH
chmod 775 $(find ${SESSION_PATH} -type d)
chmod 664 $(find ${SESSION_PATH} -type f)

exec "$@"
