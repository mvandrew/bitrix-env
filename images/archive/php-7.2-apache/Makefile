build:
	docker build --rm -t msav/bitrix-php-apache:7.2 .

push: build
	docker push msav/bitrix-php-apache:7.2

run: build
	docker run -p 80:80 --name bitrix-php-apache --rm -d msav/bitrix-php-apache:7.2

run-bash: build
	docker run --rm -it msav/bitrix-php-apache:7.2 /bin/bash
