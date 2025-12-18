build:
	docker pull php:8.1-apache
	docker build --rm -t msav/bitrix-php-apache:8.1-debug .

push: build
	docker push msav/bitrix-php-apache:8.1-debug

run: build
	docker run -p 80:80 --name bitrix-php-apache-debug --rm -d msav/bitrix-php-apache:8.1-debug

run-bash: build
	docker run --rm -it msav/bitrix-php-apache:8.1-debug /bin/bash

stop:
	docker stop bitrix-php-apache-debug
