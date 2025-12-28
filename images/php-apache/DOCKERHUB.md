# PHP-Apache для 1C-Битрикс

Docker-образы PHP с Apache, оптимизированные для разработки и production-развёртывания 1C-Битрикс CMS и Битрикс24.

## Поддерживаемые теги

| Тег | PHP | Базовый образ | Назначение |
|-----|-----|---------------|------------|
| `7.4` | 7.4 | php:7.4-apache-bookworm | Legacy-проекты до 2020, поддержка `mbstring.func_overload` |
| `8.1` | 8.1 | php:8.1-apache-bookworm | Проекты 2020-2023, рекомендуемая версия |
| `8.2` | 8.2 | php:8.2-apache-bookworm | Проекты 2023+, современный стек |

## Быстрый старт

### Docker Run

```bash
docker run -d \
  --name bitrix \
  -p 80:80 \
  -v $(pwd)/www:/var/www/html \
  -e MEMORY_LIMIT=1024M \
  -e PHP_INI_TYPE=development \
  msav/bitrix-php-apache:8.1
```

### Docker Compose

```yaml
services:
  php:
    image: msav/bitrix-php-apache:8.1
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./www:/var/www/html
      - ./session:/var/www/session
    environment:
      MEMORY_LIMIT: "1024M"
      PHP_INI_TYPE: "development"
      USER_ID: "1000"
      GROUP_ID: "1000"
```

## Переменные окружения

### PHP

| Переменная | Умолчание | Описание |
|------------|-----------|----------|
| `MEMORY_LIMIT` | `2048M` | Лимит памяти PHP |
| `PHP_INI_TYPE` | `development` | Режим: `development` или `production` |
| `PHP_EX_OPCACHE_ENABLED` | `1` | Включение OPcache |
| `MBSTRING_FUNC_OVERLOAD` | `0` | Перегрузка mbstring (для legacy) |
| `BX_TIMEZONE` | `Europe/Moscow` | Часовой пояс |

### Пользователь

| Переменная | Умолчание | Описание |
|------------|-----------|----------|
| `USER_ID` | `1000` | UID пользователя www-data |
| `GROUP_ID` | `1000` | GID группы www-data |

### Сайт и прокси

| Переменная | Умолчание | Описание |
|------------|-----------|----------|
| `SITE_DOMAIN` | `mydomain.ru` | Домен сайта |
| `PROXY_IPS` | `127.0.0.1 127.0.0.2` | Доверенные IP reverse proxy |
| `ENABLE_SSL` | `0` | Включение HTTPS |

### SMTP

| Переменная | Умолчание | Описание |
|------------|-----------|----------|
| `SMTP_HOST` | `mailpit` | Хост SMTP-сервера |
| `SMTP_PORT` | `1025` | Порт SMTP |
| `SMTP_EMAIL` | `noreply@localhost` | Email отправителя |
| `SMTP_AUTH` | `off` | Аутентификация SMTP |

## PHP расширения

### Встроенные

bz2, calendar, exif, gd (WebP, JPEG, PNG, FreeType), gettext, imap, ldap, mysqli, opcache, pdo_mysql, pspell, shmop, sockets, zip

### PECL

amqp, igbinary, imagick, lz4, lzf, mcrypt, memcache, memcached, msgpack, rdkafka, redis (с igbinary, lz4, lzf, msgpack, zstd), rrd, xlswriter, zstd

## Особенности

### Multi-stage сборка

Образ использует двухэтапную сборку: компиляция расширений с dev-пакетами, затем только runtime-библиотеки. Уменьшение размера на 40-50%.

### Российские сертификаты

Включены сертификаты Минцифры РФ (Russian Trusted Root CA, Russian Trusted Sub CA) для работы с российскими сервисами.

### Автоустановка Битрикс

При первом запуске с пустым `/var/www/html` автоматически загружается `bitrixsetup.php`.

### Health Check

Файл `/var/www/html/health.php` возвращает HTTP 200 для проверки состояния контейнера.

## Development vs Production

| Параметр | Development | Production |
|----------|-------------|------------|
| `display_errors` | On | Off |
| `error_reporting` | E_ALL | E_ALL без NOTICE, WARNING |
| `opcache.validate_timestamps` | 0 | 1 |
| `opcache.memory_consumption` | 256 МБ | 512 МБ |

## Тома

| Путь | Назначение |
|------|------------|
| `/var/www/html` | DocumentRoot Apache |
| `/var/www/session` | Директория сессий PHP |

## Порты

| Порт | Протокол |
|------|----------|
| 80 | HTTP |
| 443 | HTTPS (при `ENABLE_SSL=1`) |

## Решение проблем

| Симптом | Решение |
|---------|---------|
| Allowed memory size exhausted | Увеличить `MEMORY_LIMIT` |
| OPcache не видит изменения | Использовать `PHP_INI_TYPE=production` |
| Ошибки mbstring в legacy | Установить `MBSTRING_FUNC_OVERLOAD=2` |
| Permission denied | Настроить `USER_ID` и `GROUP_ID` |
| Почта не отправляется | Проверить `SMTP_*` переменные |

## Ссылки

- **GitHub**: [mvandrew/bitrix-env](https://github.com/mvandrew/bitrix-env)
- **Полная документация**: [README.md](https://github.com/mvandrew/bitrix-env/blob/main/images/php-apache/README.md)
