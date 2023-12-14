build:
	docker pull centos:7
	docker pull node:8-alpine
	docker build --rm -t msav/bitrix-push-server:2 .

push: build
	docker msav/bitrix-push-server:2
	docker msav/bitrix-push-server:latest

run: build
	docker run -p 80:80 --name bitrix-php-apache --rm -d msav/bitrix-php-apache:8.1

run-bash: build
	docker run --rm -it msav/bitrix-php-apache:8.1 /bin/bash

stop:
	docker stop bitrix-php-apache
