#!/bin/sh

sudo docker run -p 80:80 --name bitrix-php-apache --rm -d msav/bitrix-php-apache
