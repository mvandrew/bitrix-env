# ===========================================
# Makefile for Bitrix PHP 8.2 Apache Image
# ===========================================

IMAGE_NAME = msav/bitrix-php-apache
TAG = 8.2
CONTAINER_NAME = bitrix-php-8.2

.PHONY: pull build rebuild push run run-bash stop clean test

# Pull base image (bookworm for libc-client-dev compatibility)
pull:
	docker pull php:8.2-apache-bookworm

# Build image (context is parent directory php-apache/)
build: pull
	cd .. && docker build --rm -t $(IMAGE_NAME):$(TAG) -f 8.2/Dockerfile .

# Rebuild without cache
rebuild: pull
	cd .. && docker build --no-cache --rm -t $(IMAGE_NAME):$(TAG) -f 8.2/Dockerfile .

# Push to Docker Hub
push: build
	docker push $(IMAGE_NAME):$(TAG)

# Run container
run: build
	docker run -p 8080:80 --name $(CONTAINER_NAME) --rm -d \
		-e PHP_INI_TYPE=production \
		-v ./data/www:/var/www/html \
		-v ./data/logs:/var/log/php \
		$(IMAGE_NAME):$(TAG)
	@echo "Container started at http://localhost:8080"

# Run with bash shell
run-bash: build
	docker run -e PHP_INI_TYPE=production --rm -it $(IMAGE_NAME):$(TAG) /bin/bash

# Stop container
stop:
	docker stop $(CONTAINER_NAME) || true

# Clean up
clean: stop
	docker ps -aq --filter ancestor=$(IMAGE_NAME):$(TAG) | xargs -r docker rm -f 2>/dev/null || true
	docker rmi -f $(IMAGE_NAME):$(TAG) 2>/dev/null || true
	rm -rf ./data

# Проверка PHP, расширений и HTTP через общий сценарий
test: build
	bash ../base/scripts/test-image.sh "$(IMAGE_NAME):$(TAG)" "8.2" 0 "$(CONTAINER_NAME)-test"
