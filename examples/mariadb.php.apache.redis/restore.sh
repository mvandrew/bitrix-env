#!/bin/sh

if [ -z "$1" ]; then
    echo "Укажите ИД контейнера.\n"
fi

if [ -n "$2" ]; then
    cat $2 | sudo docker exec -i $1 /usr/bin/mysql -uroot -prootpwd -f bitrix
else
    echo "Укажите путь к дампу БД для восстановления.\n"
fi
