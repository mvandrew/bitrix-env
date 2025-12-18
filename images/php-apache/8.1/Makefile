# ===========================================
# Makefile for Bitrix PHP 8.1 Apache Image
# ===========================================

IMAGE_NAME = msav/bitrix-php-apache
TAG = 8.1
TAG_OPT = 8.1-optimized
CONTAINER_NAME = bitrix-php-8.1

.PHONY: pull build rebuild push run run-bash stop clean test build-optimized rebuild-optimized test-optimized compare

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
	docker rmi $(IMAGE_NAME):$(TAG) || true

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

# ===========================================
# Optimized Multi-Stage Build Targets
# ===========================================

# Build optimized image (multi-stage)
build-optimized: pull
	cd .. && docker build --rm -t $(IMAGE_NAME):$(TAG_OPT) -f 8.1/Dockerfile.optimized .

# Rebuild optimized without cache
rebuild-optimized: pull
	cd .. && docker build --no-cache --rm -t $(IMAGE_NAME):$(TAG_OPT) -f 8.1/Dockerfile.optimized .

# Test optimized image
test-optimized: build-optimized
	@echo "Testing PHP version (optimized)..."
	docker run --rm $(IMAGE_NAME):$(TAG_OPT) php -v | head -1
	@echo ""
	@echo "Testing key extensions (optimized)..."
	docker run --rm $(IMAGE_NAME):$(TAG_OPT) php -m | grep -E '^(redis|imagick|opcache|mysqli|gd|memcached)$$' | sort
	@echo ""
	@echo "Testing health check (optimized)..."
	docker run --rm -d -p 8889:80 --name $(CONTAINER_NAME)-opt-test $(IMAGE_NAME):$(TAG_OPT)
	sleep 3
	curl -sf http://localhost:8889/health.php && echo " - Health check OK"
	docker stop $(CONTAINER_NAME)-opt-test
	@echo ""
	@echo "All optimized tests passed!"

# Compare image sizes
compare:
	@echo "=== Image Size Comparison ==="
	@echo "Original:"
	@docker images $(IMAGE_NAME):$(TAG) --format "  {{.Repository}}:{{.Tag}} - {{.Size}}" 2>/dev/null || echo "  Not built"
	@echo "Optimized:"
	@docker images $(IMAGE_NAME):$(TAG_OPT) --format "  {{.Repository}}:{{.Tag}} - {{.Size}}" 2>/dev/null || echo "  Not built"
