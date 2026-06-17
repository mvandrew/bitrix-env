# PHP-Apache для 1C-Битрикс

Docker-образы PHP с Apache, оптимизированные для разработки и production-развёртывания 1C-Битрикс CMS и Битрикс24.

## Поддерживаемые теги

| Тег | PHP | Базовый образ | Назначение |
|-----|-----|---------------|------------|
| `8.1` | 8.1 | php:8.1-apache-bookworm | Проекты 2020-2023, рекомендуемая версия |
| `8.2` | 8.2 | php:8.2-apache-bookworm | Проекты 2023+, современный стек |

Теги 8.1 и 8.2 поддерживаются в полном паритете (одинаковый набор расширений и конфигураций).

### Архивные версии (7.4 / 7.2)

Образы PHP 7.4 и 7.2 перемещены в архив (`bitrix-env/images/archive/`), не поддерживаются и не обновляются; PHP 7.2 достиг EOL. Для новых проектов используйте 8.1 или 8.2.

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
| `SITE_IP` | `127.0.0.1` | IP для записи домена в /etc/hosts |
| `PROXY_IPS` | `127.0.0.1 127.0.0.2` | Доверенные IP reverse proxy |
| `ENABLE_SSL` | `0` | Включение HTTPS |

### SMTP

| Переменная | Умолчание | Описание |
|------------|-----------|----------|
| `SMTP_HOST` | `mailpit` | Хост SMTP-сервера |
| `SMTP_PORT` | `1025` | Порт SMTP |
| `SMTP_EMAIL` | `noreply@localhost` | Email отправителя |
| `SMTP_AUTH` | `off` | Аутентификация SMTP |
| `SMTP_TLS` | `off` | TLS |
| `SMTP_TLS_STARTTLS` | `off` | STARTTLS |

### Права и отладка

| Переменная | Умолчание | Описание |
|------------|-----------|----------|
| `CHOWN_MODE` | `smart` | Режим установки прав: `skip`, `sync`, `async`, `smart` |
| `XDEBUG_ENABLED` | `0` | Активация Xdebug в runtime |
| `XHPROF_ENABLED` | `0` | Активация XHProf в runtime |
| `XDEBUG_MODE` | `off` | Режим Xdebug: `off`, `debug`, `profile`, `trace` |

## PHP расширения

### Встроенные

bz2, calendar, exif, ftp, gd (WebP, JPEG, PNG, XPM, FreeType, AVIF), gettext, imap, intl, ldap, mysqli, opcache, pdo_mysql, pspell, shmop, sockets, sodium, sysvmsg, sysvsem, sysvshm, xsl, zip

### PECL

amqp, apcu, igbinary, imagick, lz4, lzf, mcrypt, memcache, memcached, msgpack, rdkafka, redis (с igbinary, lz4, lzf, msgpack, zstd), rrd, ssh2 (1.5.0), xlswriter, zstd

## Особенности

### Multi-stage сборка

Образ использует двухэтапную сборку: компиляция расширений с dev-пакетами, затем только runtime-библиотеки. Уменьшение размера на 40-50%.

### Российские сертификаты

Включены сертификаты Минцифры РФ (Russian Trusted Root CA, Russian Trusted Sub CA) для работы с российскими сервисами.

### Автоустановка Битрикс

При первом запуске с пустым `/var/www/html` автоматически загружается `bitrixsetup.php`.

### Health Check

Файл `/var/www/html/health.php` возвращает HTTP 200 для проверки состояния контейнера.

### Xdebug и XHProf

Xdebug 3.5.1 и XHProf 2.3.10 скомпилированы в образ, но по умолчанию выключены (нулевой overhead в production). Активация в runtime: `XDEBUG_ENABLED=1` (режим через `XDEBUG_MODE`) и `XHPROF_ENABLED=1`.

### Индексация документов

Включены CLI-инструменты для полнотекстовой индексации и `search.title` Битрикс: `catdoc` (DOC), `poppler-utils`/`pdftotext` (PDF), `aspell` (орфография), `msmtp` (SMTP-клиент).

### OPcache JIT отключён

JIT-компиляция отключена намеренно (`opcache.jit=disable`): команда 1С-Битрикс официально не использует JIT и не гарантирует стабильность продукта с ним. Включать только осознанно.

## Development vs Production

| Параметр | Development | Production |
|----------|-------------|------------|
| `display_errors` | On | Off |
| `error_reporting` | E_ALL | E_ALL без NOTICE, WARNING |
| `realpath_cache_ttl` | 600 сек | 3600 сек |
| `opcache.validate_timestamps` | 1 | 1 |
| `opcache.revalidate_freq` | 0 | 2 |
| `opcache.memory_consumption` | 128 МБ | 512 МБ |
| `opcache.interned_strings_buffer` | 16 МБ | 64 МБ |
| `opcache.max_accelerated_files` | 20000 | 100000 |

В обоих режимах `opcache.validate_timestamps=1` (Битрикс динамически перезаписывает PHP-файлы). Различие — в `revalidate_freq`: в development файлы проверяются на каждом запросе (`0`), в production — не чаще раза в 2 секунды (`2`).

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
| OPcache не сразу видит изменения | Использовать `PHP_INI_TYPE=development` (`revalidate_freq=0`) |
| Ошибки mbstring в legacy | Установить `MBSTRING_FUNC_OVERLOAD=2` |
| Permission denied | Настроить `USER_ID` и `GROUP_ID` |
| Почта не отправляется | Проверить `SMTP_*` переменные |

## Ссылки

- **GitHub**: [mvandrew/bitrix-env](https://github.com/mvandrew/bitrix-env)
- **Полная документация**: [README.md](https://github.com/mvandrew/bitrix-env/blob/main/images/php-apache/README.md)
