#!/bin/bash

docker run -p 3306:3306 --name bitrix-mysql -e MYSQL_ROOT_PASSWORD=rootpwd --rm -d msav/bitrix-mysql:5.7
