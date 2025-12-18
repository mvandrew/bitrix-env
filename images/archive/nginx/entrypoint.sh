#!/bin/sh

echo "$SITE_DOMAIN" > /etc/hostname

if [ -n "$1" ]; then
    exec "$1"
else
    exec "nginx"
fi
