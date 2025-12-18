# MariaDB 10.11 LTS Docker Image for 1C-Bitrix
# Build, test, and publish commands

IMAGE_NAME = msav/bitrix-mariadb
TAG = 10.11
CONTAINER_NAME = bitrix-mariadb-10.11

.PHONY: pull build rebuild push run run-bash stop clean test help

help:
	@echo "Available targets:"
	@echo "  pull      - Pull base mariadb:10.11 image"
	@echo "  build     - Build the image"
	@echo "  rebuild   - Build without cache"
	@echo "  push      - Push to Docker Hub"
	@echo "  run       - Run container with default settings"
	@echo "  run-bash  - Run container with bash shell"
	@echo "  stop      - Stop and remove container"
	@echo "  clean     - Stop container and remove image"
	@echo "  test      - Build and test the image"

pull:
	docker pull mariadb:10.11

build: pull
	cd .. && docker build --rm -t $(IMAGE_NAME):$(TAG) -f 10.11/Dockerfile .

rebuild: pull
	cd .. && docker build --no-cache --rm -t $(IMAGE_NAME):$(TAG) -f 10.11/Dockerfile .

push: build
	docker tag $(IMAGE_NAME):$(TAG) $(IMAGE_NAME):latest
	docker push $(IMAGE_NAME):$(TAG)
	docker push $(IMAGE_NAME):latest

run: build
	docker run -d --name $(CONTAINER_NAME) \
		-e MYSQL_ROOT_PASSWORD=rootpwd \
		-e MYSQL_DATABASE=bitrix \
		-e MYSQL_USER=bitrix \
		-e MYSQL_PASSWORD=bitrixpwd \
		-p 3306:3306 \
		$(IMAGE_NAME):$(TAG)
	@echo "MariaDB 10.11 started on port 3306"
	@echo "Database: bitrix, User: bitrix, Password: bitrixpwd"

run-bash: build
	docker run --rm -it $(IMAGE_NAME):$(TAG) /bin/bash

stop:
	docker stop $(CONTAINER_NAME) 2>/dev/null || true
	docker rm $(CONTAINER_NAME) 2>/dev/null || true

clean: stop
	docker rmi $(IMAGE_NAME):$(TAG) 2>/dev/null || true

test: build
	@echo "=== Testing MariaDB 10.11 image ==="
	@echo ""
	@echo "1. Starting container..."
	docker run --rm -d --name $(CONTAINER_NAME)-test \
		-e MYSQL_ROOT_PASSWORD=testpwd \
		-e MYSQL_DATABASE=bitrix_test \
		$(IMAGE_NAME):$(TAG)
	@echo "   Waiting for MariaDB to initialize (45s)..."
	@sleep 45
	@echo ""
	@echo "2. Checking MariaDB version:"
	@docker exec $(CONTAINER_NAME)-test mariadb -uroot -ptestpwd -e "SELECT VERSION();" 2>/dev/null || true
	@echo ""
	@echo "3. Checking sql_mode (must be empty for Bitrix):"
	@docker exec $(CONTAINER_NAME)-test mariadb -uroot -ptestpwd -e "SHOW VARIABLES LIKE 'sql_mode';" 2>/dev/null || true
	@echo ""
	@echo "4. Checking character_set_server (must be utf8mb4):"
	@docker exec $(CONTAINER_NAME)-test mariadb -uroot -ptestpwd -e "SHOW VARIABLES LIKE 'character_set_server';" 2>/dev/null || true
	@echo ""
	@echo "5. Checking collation_server:"
	@docker exec $(CONTAINER_NAME)-test mariadb -uroot -ptestpwd -e "SHOW VARIABLES LIKE 'collation_server';" 2>/dev/null || true
	@echo ""
	@echo "6. Checking transaction_isolation:"
	@docker exec $(CONTAINER_NAME)-test mariadb -uroot -ptestpwd -e "SHOW VARIABLES LIKE 'transaction_isolation';" 2>/dev/null || true
	@echo ""
	@echo "7. Checking innodb_buffer_pool_size:"
	@docker exec $(CONTAINER_NAME)-test mariadb -uroot -ptestpwd -e "SHOW VARIABLES LIKE 'innodb_buffer_pool_size';" 2>/dev/null || true
	@echo ""
	@echo "Stopping test container..."
	@docker stop $(CONTAINER_NAME)-test 2>/dev/null || true
	@echo ""
	@echo "=== Tests completed ==="
