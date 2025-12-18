pull:
	docker pull php:8.2-apache

build: pull
	docker build --rm -t msav/bitrix-php-apache:8.2 -t msav/bitrix-php-apache:latest .

rebuild: pull
	docker build --no-cache --rm -t msav/bitrix-php-apache:8.2 .

push: build
	docker push msav/bitrix-php-apache:8.2
	docker push msav/bitrix-php-apache:latest

run: build
	docker run -p 80:80 --name bitrix-php-apache --rm -d \
        -v ./data/logs:/var/log/apache2 \
        msav/bitrix-php-apache:8.2

run-bash: build
	docker run --rm -it msav/bitrix-php-apache:8.2 /bin/bash

stop:
	docker stop bitrix-php-apache
