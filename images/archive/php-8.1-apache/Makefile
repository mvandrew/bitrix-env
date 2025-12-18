build:
	docker pull php:8.1-apache
	docker build --rm -t msav/bitrix-php-apache:8.1 .

push: build
	docker push msav/bitrix-php-apache:8.1

run: build
	docker run -p 80:80 --name bitrix-php-apache --rm -d msav/bitrix-php-apache:8.1

run-bash: build
	docker run --rm -it msav/bitrix-php-apache:8.1 /bin/bash

stop:
	docker stop bitrix-php-apache
