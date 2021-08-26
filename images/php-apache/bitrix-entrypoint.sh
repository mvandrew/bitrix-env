#!/bin/sh

# Конифиг PHP
echo "[php]" > ${PHP_CONFIG_FILE_EX} \
    && echo "memory_limit = ${MEMORY_LIMIT}" >> ${PHP_CONFIG_FILE_EX}

if [ ${SET_FUNC_OVERLOAD} -eq 1 ]; then
    echo "mbstring.func_overload = 2" >> ${PHP_CONFIG_FILE_EX}
fi

# Проверка необходимости залить установщик Битрикс
BITRIX_PATH="/var/www/bitrix"
BITRIX_INDEX="${BITRIX_PATH}/index.php"
BITRIX_SETUP="${BITRIX_PATH}/bitrixsetup.php"
if [ ! -f $BITRIX_INDEX ] && [ ! -f $BITRIX_SETUP ]; then
    wget https://www.1c-bitrix.ru/download/scripts/bitrixsetup.php -O $BITRIX_SETUP
fi

# Обновление прав доступа к файлам
chown -R www-data:www-data $BITRIX_PATH
chmod 775 $(find ${BITRIX_PATH} -type d)
chmod 664 $(find ${BITRIX_PATH} -type f)

exec "$@"
