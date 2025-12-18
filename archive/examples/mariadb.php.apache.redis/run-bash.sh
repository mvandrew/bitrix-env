#!/bin/sh

if [ -n "$1" ]; then
    sudo docker exec -it $1 bash
else
    echo "Укажите ИД контейнера.\n"
fi
