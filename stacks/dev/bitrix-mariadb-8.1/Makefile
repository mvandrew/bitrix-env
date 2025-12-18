# ===========================================
# Makefile for Bitrix Development Environment
# PHP 8.1 + MariaDB 10.11 + Adminer + phpMyAdmin
# ===========================================

# Load environment variables from .env file
ifneq (,$(wildcard ./.env))
    include .env
    export
endif

# Default values
PROJECT ?= bitrix
DATA_PATH ?= ./data
BACKUP_PATH ?= ./backups
MYSQL_DATABASE ?= bitrix
MYSQL_USER ?= bitrix
MYSQL_PASSWORD ?= bitrixpwd
MYSQL_ROOT_PASSWORD ?= rootpwd

# Container names
WEB_CONTAINER = $(PROJECT)_web
DB_CONTAINER = $(PROJECT)_db

# Timestamp for backups
TIMESTAMP = $(shell date +%Y%m%d_%H%M%S)

.PHONY: help up up-tools down restart logs status \
        php composer shell \
        dump restore \
        init clean

# ===========================================
# HELP
# ===========================================

help:
	@echo ""
	@echo "Bitrix Development Environment"
	@echo "==============================="
	@echo ""
	@echo "Container Management:"
	@echo "  make up          - Start web and db containers"
	@echo "  make up-tools    - Start all containers (with Adminer & phpMyAdmin)"
	@echo "  make down        - Stop all containers"
	@echo "  make restart     - Restart all containers"
	@echo "  make logs        - View container logs"
	@echo "  make status      - Show container status"
	@echo ""
	@echo "PHP Commands:"
	@echo "  make php CMD=\"-v\"           - Run PHP command"
	@echo "  make composer CMD=\"install\" - Run Composer command"
	@echo "  make shell                   - Open bash shell in web container"
	@echo ""
	@echo "Database Backup/Restore:"
	@echo "  make dump                           - Backup database to .sql.tar.gz"
	@echo "  make restore FILE=backup.sql.tar.gz - Restore from archive"
	@echo "  make restore FILE=backup.sql        - Restore from SQL file"
	@echo ""
	@echo "Setup:"
	@echo "  make init        - Initialize data directories"
	@echo "  make clean       - Remove all data (DANGEROUS!)"
	@echo ""

# ===========================================
# CONTAINER MANAGEMENT
# ===========================================

up: init
	@echo "Starting web and db containers..."
	docker compose up -d
	@echo ""
	@echo "Services started:"
	@echo "  Web:  http://localhost:$${WEB_HTTP_PORT:-8080}"
	@echo ""

up-tools: init
	@echo "Starting all containers (including tools)..."
	docker compose --profile tools up -d
	@echo ""
	@echo "Services started:"
	@echo "  Web:        http://localhost:$${WEB_HTTP_PORT:-8080}"
	@echo "  Adminer:    http://localhost:$${ADMINER_PORT:-8081}"
	@echo "  phpMyAdmin: http://localhost:$${PHPMYADMIN_PORT:-8082}"
	@echo "  Mailpit:    http://localhost:$${MAILPIT_WEB_PORT:-8025}"
	@echo ""

down:
	@echo "Stopping all containers..."
	docker compose --profile tools down

restart: down up

logs:
	docker compose logs -f

status:
	@echo "Container status:"
	@docker compose ps
	@echo ""
	@echo "Health status:"
	@docker inspect --format='{{.Name}}: {{.State.Health.Status}}' $(WEB_CONTAINER) $(DB_CONTAINER) 2>/dev/null || true

# ===========================================
# PHP COMMANDS
# ===========================================

php:
ifndef CMD
	@echo "Usage: make php CMD=\"-v\""
	@echo "Example: make php CMD=\"-m\""
else
	docker exec -it $(WEB_CONTAINER) php $(CMD)
endif

composer:
ifndef CMD
	@echo "Usage: make composer CMD=\"install\""
	@echo "Example: make composer CMD=\"require vendor/package\""
else
	docker exec -it $(WEB_CONTAINER) composer $(CMD)
endif

shell:
	docker exec -it $(WEB_CONTAINER) /bin/bash

# ===========================================
# DATABASE BACKUP
# ===========================================

dump:
	@mkdir -p $(BACKUP_PATH)
	@echo "Creating database dump..."
	@echo "Database: $(MYSQL_DATABASE)"
	@echo "Charset: utf8mb4"
	@docker exec $(DB_CONTAINER) mariadb-dump \
		--user=$(MYSQL_USER) \
		--password=$(MYSQL_PASSWORD) \
		--default-character-set=utf8mb4 \
		--add-drop-table \
		--routines \
		--triggers \
		--single-transaction \
		--quick \
		$(MYSQL_DATABASE) > $(BACKUP_PATH)/$(MYSQL_DATABASE)_$(TIMESTAMP).sql
	@echo "Compressing..."
	@cd $(BACKUP_PATH) && tar -czf $(MYSQL_DATABASE)_$(TIMESTAMP).sql.tar.gz $(MYSQL_DATABASE)_$(TIMESTAMP).sql
	@rm $(BACKUP_PATH)/$(MYSQL_DATABASE)_$(TIMESTAMP).sql
	@echo ""
	@echo "Backup created: $(BACKUP_PATH)/$(MYSQL_DATABASE)_$(TIMESTAMP).sql.tar.gz"
	@ls -lh $(BACKUP_PATH)/$(MYSQL_DATABASE)_$(TIMESTAMP).sql.tar.gz

# ===========================================
# DATABASE RESTORE
# ===========================================

restore:
ifndef FILE
	@echo "Usage: make restore FILE=backup.sql.tar.gz"
	@echo "       make restore FILE=backup.sql"
	@echo ""
	@echo "Available backups:"
	@ls -lh $(BACKUP_PATH)/*.sql.tar.gz 2>/dev/null || echo "  No backups found in $(BACKUP_PATH)/"
else
	@echo "Restoring database from: $(FILE)"
	@echo "Database: $(MYSQL_DATABASE)"
	@echo "Charset: utf8mb4"
	@echo ""
	@if echo "$(FILE)" | grep -q '\.tar\.gz$$'; then \
		echo "Extracting archive..."; \
		SQLFILE=$$(basename "$(FILE)" .tar.gz); \
		tar -xzf "$(FILE)" -C /tmp; \
		echo "Restoring..."; \
		docker exec -i $(DB_CONTAINER) mariadb \
			--user=$(MYSQL_USER) \
			--password=$(MYSQL_PASSWORD) \
			--default-character-set=utf8mb4 \
			$(MYSQL_DATABASE) < /tmp/$$SQLFILE; \
		rm -f /tmp/$$SQLFILE; \
	elif echo "$(FILE)" | grep -q '\.sql$$'; then \
		echo "Restoring from SQL file..."; \
		docker exec -i $(DB_CONTAINER) mariadb \
			--user=$(MYSQL_USER) \
			--password=$(MYSQL_PASSWORD) \
			--default-character-set=utf8mb4 \
			$(MYSQL_DATABASE) < "$(FILE)"; \
	else \
		echo "Error: Unsupported file format. Use .sql or .sql.tar.gz"; \
		exit 1; \
	fi
	@echo ""
	@echo "Database restored successfully!"
endif

# ===========================================
# SETUP
# ===========================================

init:
	@mkdir -p $(DATA_PATH)/www
	@mkdir -p $(DATA_PATH)/upload
	@mkdir -p $(DATA_PATH)/mysql
	@mkdir -p $(DATA_PATH)/logs/php
	@mkdir -p $(DATA_PATH)/sessions
	@mkdir -p $(BACKUP_PATH)

clean:
	@echo "WARNING: This will delete ALL data including:"
	@echo "  - Website files ($(DATA_PATH)/www)"
	@echo "  - Database ($(DATA_PATH)/mysql)"
	@echo "  - Uploads ($(DATA_PATH)/upload)"
	@echo "  - Logs ($(DATA_PATH)/logs)"
	@echo "  - Sessions ($(DATA_PATH)/sessions)"
	@echo ""
	@read -p "Are you sure? Type 'yes' to confirm: " confirm && [ "$$confirm" = "yes" ] || exit 1
	docker compose --profile tools down -v
	rm -rf $(DATA_PATH)
	@echo "All data removed."
