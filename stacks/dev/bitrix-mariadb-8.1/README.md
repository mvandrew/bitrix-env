# Bitrix Development Environment

Docker Compose environment for 1C-Bitrix development.

## Stack

| Service | Image | Description |
|---------|-------|-------------|
| web | `msav/bitrix-php-apache:8.1` | PHP 8.1 + Apache |
| db | `msav/bitrix-mariadb:10.11` | MariaDB 10.11 LTS |
| adminer | `adminer:latest` | Lightweight DB manager |
| phpmyadmin | `phpmyadmin:latest` | phpMyAdmin |

## Quick Start

```bash
# 1. Copy environment file
cp .env.example .env

# 2. Edit .env as needed (optional)
nano .env

# 3. Start containers
make up

# 4. Place Bitrix files in ./data/www/
```

## Access URLs

| Service | URL |
|---------|-----|
| Website | http://localhost:8080 |
| Adminer | http://localhost:8081 |
| phpMyAdmin | http://localhost:8082 |

## Commands

### Container Management

```bash
make up          # Start web and db containers
make up-tools    # Start all containers (with Adminer & phpMyAdmin)
make down        # Stop all containers
make restart     # Restart all containers
make logs        # View container logs
make status      # Show container status
```

### PHP Commands

```bash
make php CMD="-v"              # Check PHP version
make php CMD="-m"              # List PHP modules
make composer CMD="install"    # Run Composer install
make shell                     # Open bash in web container
```

### Database Backup

```bash
make dump
# Creates: ./backups/bitrix_YYYYMMDD_HHMMSS.sql.tar.gz
```

Features:
- UTF-8 charset (utf8mb4) for Cyrillic support
- DROP TABLE IF EXISTS for clean restore
- Compressed .tar.gz format
- Includes routines and triggers

### Database Restore

```bash
# From .tar.gz archive
make restore FILE=./backups/bitrix_20241218_143022.sql.tar.gz

# From plain SQL file
make restore FILE=./backup.sql
```

## Directory Structure

```
bitrix-mariadb-8.1/
├── docker-compose.yml    # Docker services
├── .env.example          # Environment template
├── .env                  # Your configuration (git-ignored)
├── Makefile              # All commands
├── README.md             # This file
├── data/                 # Persistent data
│   ├── www/              # Website files (/var/www/html)
│   ├── upload/           # Uploads (/var/www/html/upload)
│   ├── mysql/            # Database files
│   ├── logs/php/         # PHP logs
│   └── sessions/         # PHP sessions
└── backups/              # Database backups
```

## Configuration

### PHP Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `PHP_MEMORY_LIMIT` | 512M | PHP memory limit |
| `PHP_INI_TYPE` | development | PHP ini type (development/production) |
| `MBSTRING_FUNC_OVERLOAD` | 0 | Set to 2 for legacy Bitrix |

### Database Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `MYSQL_DATABASE` | bitrix | Database name |
| `MYSQL_USER` | bitrix | Database user |
| `MYSQL_PASSWORD` | bitrixpwd | User password |
| `MYSQL_ROOT_PASSWORD` | rootpwd | Root password |

### InnoDB Tuning (by host RAM)

| Host RAM | buffer_pool_size | instances |
|----------|------------------|-----------|
| 4 GB | 2G | 2 |
| 8 GB | 4G | 4 |
| 16+ GB | 12G | 12 |

## Bitrix Installation

1. Start the environment:
   ```bash
   make up
   ```

2. Download Bitrix restoration script:
   ```bash
   cd data/www
   wget https://www.1c-bitrix.ru/download/scripts/restore.php
   ```

3. Open http://localhost:8080/restore.php in browser

4. Follow the installation wizard:
   - Database host: `db`
   - Database name: `bitrix`
   - Database user: `bitrix`
   - Database password: `bitrixpwd`

## Troubleshooting

### "Allowed memory size exhausted"
Increase `PHP_MEMORY_LIMIT` in `.env`

### Slow database queries
Check `INNODB_BUFFER_POOL_SIZE` matches your host RAM

### Cyrillic encoding issues
Database uses `utf8mb4` by default. Check your Bitrix `dbconn.php`:
```php
define("BX_UTF", true);
```

### Permission issues
Files should be owned by `www-data:www-data` (UID/GID 33):
```bash
make shell
chown -R www-data:www-data /var/www/html
```

## License

MIT
