#!/bin/sh

echo "[mysqld]" > /etc/mysql/conf.d/zzz-bitrix-ext.cnf \
    && echo "innodb_buffer_pool_size=${innodb_buffer_pool_size}" >> /etc/mysql/conf.d/zzz-bitrix-ext.cnf \
    && echo "innodb_buffer_pool_instances=${innodb_buffer_pool_instances}" >> /etc/mysql/conf.d/zzz-bitrix-ext.cnf \
    && echo "innodb_log_file_size=${innodb_log_file_size}" >> /etc/mysql/conf.d/zzz-bitrix-ext.cnf

exec "$@"
