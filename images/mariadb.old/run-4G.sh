#!/bin/sh

sudo docker run -p 3306:3306 --name bitrix-mariadb --rm -d -e innodb_buffer_pool_size=4G msav/bitrix-mariadb
