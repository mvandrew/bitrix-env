# PHP-Apache Docker Images для 1C-Битрикс

Docker-образы PHP с Apache, оптимизированные для разработки и production-развёртывания 1C-Битрикс CMS и Битрикс24. Содержат предустановленные расширения PHP, конфигурации Apache и инструменты, необходимые для работы платформы.

## Доступные версии

| PHP | Базовый образ | Совместимость с Битрикс | Примечание |
|-----|---------------|-------------------------|------------|
| 7.4 | php:7.4-apache-bookworm | Legacy-проекты до 2020 | Поддержка `mbstring.func_overload` |
| 8.1 | php:8.1-apache-bookworm | Проекты 2020-2023 | Рекомендуемая версия |
| 8.2 | php:8.2-apache-bookworm | Проекты 2023+ | Современный стек |

Все образы используют Debian Bookworm из-за наличия `libc-client-dev` для IMAP-расширения.

## Быстрый старт

### Сборка образа

```bash
cd bitrix-env/images/php-apache/8.1
docker build -t bitrix-php:8.1 .
```

### Запуск контейнера

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

Доступные теги на Docker Hub: `msav/bitrix-php-apache:7.4`, `msav/bitrix-php-apache:8.1`, `msav/bitrix-php-apache:8.2`

## Переменные окружения

### PHP

| Переменная | Умолчание | Описание |
|------------|-----------|----------|
| `MEMORY_LIMIT` | `2048M` | Лимит памяти PHP |
| `PHP_INI_TYPE` | `development` | Режим работы: `development` или `production` |
| `PHP_EX_OPCACHE_ENABLED` | `1` | Включение OPcache: `0` или `1` |
| `MBSTRING_FUNC_OVERLOAD` | `0` | Перегрузка mbstring-функций (для legacy Битрикс): `0` или `2` |
| `BX_TIMEZONE` | `Europe/Moscow` | Часовой пояс |
| `TZ` | `Europe/Moscow` | Системный часовой пояс |

### Пользователь

| Переменная | Умолчание | Описание |
|------------|-----------|----------|
| `USER_ID` | `1000` | UID пользователя www-data |
| `GROUP_ID` | `1000` | GID группы www-data |

### Сайт и прокси

| Переменная | Умолчание | Описание |
|------------|-----------|----------|
| `SITE_DOMAIN` | `mydomain.ru` | Домен сайта (добавляется в /etc/hosts) |
| `SITE_IP` | `127.0.0.1` | IP для записи в /etc/hosts |
| `PROXY_IPS` | `127.0.0.1 127.0.0.2` | Доверенные IP reverse proxy для mod_rpaf |

### SSL

| Переменная | Умолчание | Описание |
|------------|-----------|----------|
| `ENABLE_SSL` | `0` | Включение HTTPS: `0` или `1` |

При `ENABLE_SSL=1` используется самоподписанный сертификат snakeoil. Для production замените на собственные сертификаты.

### SMTP

| Переменная | Умолчание | Описание |
|------------|-----------|----------|
| `SMTP_HOST` | `mailpit` | Хост SMTP-сервера |
| `SMTP_PORT` | `1025` | Порт SMTP |
| `SMTP_EMAIL` | `noreply@localhost` | Email отправителя |
| `SMTP_PASSWORD` | *(пусто)* | Пароль SMTP |
| `SMTP_AUTH` | `off` | Аутентификация: `off` или `on` |
| `SMTP_TLS` | `off` | TLS: `off` или `on` |
| `SMTP_TLS_STARTTLS` | `off` | STARTTLS: `off` или `on` |

## Режимы работы

### Development vs Production

| Параметр | Development | Production |
|----------|-------------|------------|
| `display_errors` | On | Off |
| `display_startup_errors` | On | Off |
| `error_reporting` | E_ALL | E_ALL & ~E_NOTICE & ~E_WARNING & ~E_DEPRECATED & ~E_STRICT |
| `realpath_cache_ttl` | 600 сек | 3600 сек |
| `opcache.validate_timestamps` | 0 | 1 |
| `opcache.memory_consumption` | 256 МБ | 512 МБ |
| `opcache.interned_strings_buffer` | 32 МБ | 64 МБ |
| `opcache.max_accelerated_files` | 50000 | 100000 |

Переключение режима: `PHP_INI_TYPE=production`

### OPcache

В режиме development OPcache отключает проверку временных меток (`validate_timestamps=0`) для максимальной производительности. В production проверка включена (`validate_timestamps=1`), так как Битрикс требует отслеживания изменений файлов.

## PHP расширения

### Встроенные (docker-php-ext-install)

| Расширение | Назначение |
|------------|------------|
| bz2 | Сжатие Bzip2 |
| calendar | Функции календаря |
| exif | Метаданные изображений |
| gd | Обработка изображений (WebP, JPEG, PNG, XPM, FreeType) |
| gettext | Локализация |
| imap | Работа с почтой (IMAP, POP3, NNTP) |
| ldap | Интеграция с Active Directory |
| mysqli | MySQL/MariaDB |
| opcache | Кеширование байт-кода |
| pdo_mysql | PDO для MySQL |
| pspell | Проверка орфографии |
| shmop | Shared memory |
| sockets | Сетевые сокеты |
| zip | Работа с ZIP-архивами |

### PECL расширения

| Расширение | Назначение |
|------------|------------|
| amqp | RabbitMQ |
| igbinary | Бинарная сериализация |
| imagick | ImageMagick |
| lz4 | Сжатие LZ4 |
| lzf | Сжатие LZF |
| mcrypt | Шифрование (legacy) |
| memcache | Кеш Memcache |
| memcached | Кеш Memcached (с igbinary, msgpack) |
| msgpack | Сериализация MessagePack |
| rdkafka | Apache Kafka |
| redis | Redis (с igbinary, lz4, lzf, msgpack, zstd) |
| rrd | RRDtool графики |
| xlswriter | Генерация Excel-файлов |
| zstd | Сжатие Zstandard |

### PEAR

- `DB` — абстракция базы данных (требуется некоторыми модулями Битрикс)

## Структура контейнера

### Тома

| Путь | Назначение |
|------|------------|
| `/var/www/html` | DocumentRoot Apache |
| `/var/www/session` | Директория сессий PHP |

### Порты

| Порт | Протокол |
|------|----------|
| 80 | HTTP |
| 443 | HTTPS (при `ENABLE_SSL=1`) |

### Ключевые пути

| Путь | Назначение |
|------|------------|
| `/usr/local/etc/php/conf.d/` | Конфигурации PHP |
| `/usr/local/etc/php/conf.d/zzzz-bitrix-runtime.ini` | Runtime-конфигурация (создаётся entrypoint) |
| `/var/log/php/error.log` | Лог ошибок PHP |
| `/var/log/php/opcache.log` | Лог OPcache |
| `/var/log/apache2/` | Логи Apache |
| `/etc/msmtprc` | Конфигурация SMTP |

## Особенности

### Multi-stage сборка

Образ использует двухэтапную сборку:

1. **Builder** — компиляция расширений с dev-пакетами
2. **Runtime** — только runtime-библиотеки

Результат: уменьшение размера образа на 40-50%.

### Российские сертификаты

В образ включены сертификаты Минцифры РФ:

- Russian Trusted Root CA
- Russian Trusted Sub CA

Расположение: `/usr/local/share/ca-certificates/extra/`

### Автоустановка Битрикс

При первом запуске (если `/var/www/html` пуст):

- Загружается `bitrixsetup.php` с сайта 1C-Битрикс
- Создаётся `info.php` с `phpinfo()`

### Health Check

Файл `/var/www/html/health.php` возвращает HTTP 200 с телом `OK`. Используется для проверки состояния контейнера.

## Конфигурация Apache

### Модули

Включены: `rewrite`, `proxy`, `headers`, `include`, `remoteip`, `ssl`, `expires`, `rpaf`

### mod_rpaf

Модуль для корректной работы за reverse proxy. IP-адреса прокси задаются через `PROXY_IPS`.

### Виртуальные хосты

- `bitrix.conf` — HTTP (порт 80)
- `bitrix-ssl.conf` — HTTPS (порт 443, включается через `ENABLE_SSL=1`)

## Решение проблем

| Симптом | Причина | Решение |
|---------|---------|---------|
| Allowed memory size exhausted | Недостаточно памяти | Увеличить `MEMORY_LIMIT` |
| OPcache не видит изменения файлов | `validate_timestamps=0` | Использовать `PHP_INI_TYPE=production` или перезапустить контейнер |
| Ошибки mbstring в legacy-проектах | Требуется перегрузка функций | Установить `MBSTRING_FUNC_OVERLOAD=2` |
| Permission denied на файлы | Несовпадение UID/GID | Настроить `USER_ID` и `GROUP_ID` под хост |
| Почта не отправляется | Неверная конфигурация SMTP | Проверить `SMTP_*` переменные |
| SSL-сертификат недействителен | Самоподписанный сертификат | Заменить сертификаты в `/etc/ssl/` |
| Медленная работа в development | OPcache отключён или мало памяти | Проверить `PHP_EX_OPCACHE_ENABLED=1` |

### Логи для диагностики

```bash
# Логи PHP
docker exec <container> tail -f /var/log/php/error.log

# Логи Apache
docker logs <container>

# Логи OPcache
docker exec <container> tail -f /var/log/php/opcache.log

# Логи SMTP
docker exec <container> tail -f /var/log/msmtp.log
```

### Проверка расширений

```bash
docker exec <container> php -m
```

### Проверка конфигурации

```bash
docker exec <container> php -i | grep memory_limit
docker exec <container> php -i | grep opcache
```
