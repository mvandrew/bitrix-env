#!/bin/bash

if [ -z "$(ls -A "/var/www/html")" ]; then
    gosu www-data wget -P /var/www/html https://www.1c-bitrix.ru/download/scripts/bitrixsetup.php
    gosu www-data wget -P /var/www/html http://dev.1c-bitrix.ru/download/scripts/bitrix_server_test.php
fi

/etc/init.d/apache2 start

exec "$@"
