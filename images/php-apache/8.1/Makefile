# ===========================================
# Makefile for Bitrix PHP 8.1 Apache Image
# ===========================================

IMAGE_NAME = msav/bitrix-php-apache
TAG = 8.1
CONTAINER_NAME = bitrix-php-8.1

.PHONY: pull build rebuild push run run-bash stop clean test

# Pull base image (bookworm for libc-client-dev compatibility)
pull:
	docker pull php:8.1-apache-bookworm

# Build image (context is parent directory php-apache/)
build: pull
	cd .. && docker build --rm -t $(IMAGE_NAME):$(TAG) -f 8.1/Dockerfile .

# Rebuild without cache
rebuild: pull
	cd .. && docker build --no-cache --rm -t $(IMAGE_NAME):$(TAG) -f 8.1/Dockerfile .

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
	docker run --rm -it $(IMAGE_NAME):$(TAG) /bin/bash

# Stop container
stop:
	docker stop $(CONTAINER_NAME) || true

# Clean up
clean: stop
	docker ps -aq --filter ancestor=$(IMAGE_NAME):$(TAG) | xargs -r docker rm -f 2>/dev/null || true
	docker rmi -f $(IMAGE_NAME):$(TAG) 2>/dev/null || true
	rm -rf ./data

# Test extensions
test: build
	@echo "Testing PHP version..."
	docker run --rm $(IMAGE_NAME):$(TAG) php -v | head -1
	@echo ""
	@echo "Testing key extensions..."
	docker run --rm $(IMAGE_NAME):$(TAG) php -m | grep -E '^(redis|imagick|opcache|mysqli|gd|memcached)$$' | sort
	@echo ""
	@echo "Testing health check..."
	docker run --rm -d -p 8888:80 --name $(CONTAINER_NAME)-test $(IMAGE_NAME):$(TAG)
	sleep 3
	curl -sf http://localhost:8888/health.php && echo " - Health check OK"
	docker stop $(CONTAINER_NAME)-test
	@echo ""
	@echo "All tests passed!"
