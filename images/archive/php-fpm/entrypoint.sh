#!/bin/sh
set -e

dig -4 +short web.local >> /etc/hosts
truncate -s -1 /etc/hosts
echo " $SITE_DOMAIN" >> /etc/hosts
echo " $SITE_DOMAIN"

if [ -n "$1" ]; then
    exec "$1"
else
    exec "php-fpm"
fi
