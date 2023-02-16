build:
	docker build --rm -t msav/bitrix-mariadb:10.3 .

push: build
	docker push msav/bitrix-mariadb:10.3

run: build
	docker run -e MYSQL_ROOT_PASSWORD=rootpwd -p 3306:3306 --name bitrix-mariadb --rm -d msav/bitrix-mariadb:10.3

run-bash: build
	docker run --rm -it msav/bitrix-mariadb:10.3 /bin/bash

stop:
	docker stop msav/bitrix-mariadb
