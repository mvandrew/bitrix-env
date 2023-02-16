build:
	docker build --rm -t msav/bitrix-php-apache:7.4 .

push: build
	docker push msav/bitrix-php-apache:7.4
	docker push msav/bitrix-php-apache:latest

run: build
	docker run -p 80:80 --name bitrix-php-apache --rm -d msav/bitrix-php-apache:7.4

run-bash: build
	docker run --rm -it msav/bitrix-php-apache:7.4 /bin/bash

stop:
	docker stop bitrix-php-apache
