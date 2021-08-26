#!/bin/sh

sudo docker run -p 3306:3306 --name bitrix-mariadb --rm -d msav/bitrix-mariadb
