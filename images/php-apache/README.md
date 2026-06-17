# PHP-Apache Docker Images для 1C-Битрикс

Docker-образы PHP с Apache, оптимизированные для разработки и production-развёртывания 1C-Битрикс CMS и Битрикс24. Содержат предустановленные расширения PHP, конфигурации Apache и инструменты, необходимые для работы платформы.

## Доступные версии

| PHP | Базовый образ | Совместимость с Битрикс | Примечание |
|-----|---------------|-------------------------|------------|
| 8.1 | php:8.1-apache-bookworm | Проекты 2020-2023 | Рекомендуемая версия |
| 8.2 | php:8.2-apache-bookworm | Проекты 2023+ | Современный стек |

Версии 8.1 и 8.2 поддерживаются в полном паритете: одинаковый набор расширений, конфигураций и инструментов, единый multi-stage Dockerfile.

Все образы используют Debian Bookworm из-за наличия `libc-client-dev` для IMAP-расширения.

### Архивные версии (7.4 / 7.2)

Образы PHP 7.4 и 7.2 перемещены в `bitrix-env/images/archive/` (`php-7.4-apache`, `php-7.2-apache`). Это single-stage сборки, которые не поддерживаются и не обновляются; PHP 7.2 достиг конца жизненного цикла (EOL). Для новых проектов используйте 8.1 или 8.2. Архивные образы оставлены исключительно для совместимости с устаревшими проектами Битрикс, которые ещё не переведены на PHP 8.

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

Доступные теги на Docker Hub: `msav/bitrix-php-apache:8.1`, `msav/bitrix-php-apache:8.2`

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

### Права на файлы

| Переменная | Умолчание | Описание |
|------------|-----------|----------|
| `CHOWN_MODE` | `smart` | Режим установки прав на файлы Битрикс: `skip`, `sync`, `async`, `smart` |

Режим `smart` (по умолчанию) синхронно выставляет права на сессии и критичные файлы Битрикс (`bitrix/php_interface`, `.settings.php`, `.settings_extra.php`), а оставшееся дерево обрабатывает в фоне. Режим `sync` выставляет права на весь каталог синхронно (медленнее старт на больших проектах), `async` — полностью в фоне, `skip` пропускает установку прав.

### Отладка и профилирование

| Переменная | Умолчание | Описание |
|------------|-----------|----------|
| `XDEBUG_ENABLED` | `0` | Активация Xdebug в runtime: `0` или `1` |
| `XHPROF_ENABLED` | `0` | Активация XHProf в runtime: `0` или `1` |
| `XDEBUG_MODE` | `off` | Режим Xdebug: `off`, `debug`, `profile`, `trace` и др. |

Расширения скомпилированы в образ, но по умолчанию выключены (см. раздел «Xdebug и XHProf»).

## Режимы работы

### Development vs Production

| Параметр | Development | Production |
|----------|-------------|------------|
| `display_errors` | On | Off |
| `display_startup_errors` | On | Off |
| `error_reporting` | E_ALL | E_ALL & ~E_NOTICE & ~E_WARNING & ~E_DEPRECATED & ~E_STRICT |
| `realpath_cache_ttl` | 600 сек | 3600 сек |
| `opcache.enable` | 1 | 1 |
| `opcache.enable_cli` | 0 | 1 |
| `opcache.validate_timestamps` | 1 | 1 |
| `opcache.revalidate_freq` | 0 | 2 |
| `opcache.memory_consumption` | 128 МБ | 512 МБ |
| `opcache.interned_strings_buffer` | 16 МБ | 64 МБ |
| `opcache.max_accelerated_files` | 20000 | 100000 |
| `opcache.jit` | (не задан) | disable |
| `opcache.jit_buffer_size` | (не задан) | 0 |

Переключение режима: `PHP_INI_TYPE=production`

### OPcache

В обоих режимах проверка временных меток включена (`opcache.validate_timestamps=1`), потому что Битрикс динамически генерирует и перезаписывает PHP-файлы, и кеш обязан отслеживать их изменения. Разница между режимами — в частоте проверки и в объёме выделяемых ресурсов:

- **Development**: `opcache.revalidate_freq=0` — файлы проверяются на каждом запросе, изменения кода применяются мгновенно. Память и лимит файлов умеренные (128 МБ, 20000 файлов), CLI-кеш отключён.
- **Production**: `opcache.revalidate_freq=2` — проверка не чаще одного раза в 2 секунды, что снижает нагрузку на файловую систему. Память и лимит файлов рассчитаны на крупные установки (512 МБ, 100000 файлов), CLI-кеш включён.

**JIT отключён намеренно.** Команда 1С-Битрикс официально не использует JIT-компиляцию и не гарантирует стабильность продукта с включённым JIT, поэтому в production-конфигурации заданы `opcache.jit=disable` и `opcache.jit_buffer_size=0`. Включать JIT следует только осознанно и с тестированием на staging.

## PHP расширения

### Встроенные (docker-php-ext-install)

| Расширение | Назначение |
|------------|------------|
| bz2 | Сжатие Bzip2 |
| calendar | Функции календаря |
| exif | Метаданные изображений |
| ftp | Клиент FTP |
| gd | Обработка изображений (WebP, JPEG, PNG, XPM, FreeType, AVIF) |
| gettext | Локализация |
| imap | Работа с почтой (IMAP, POP3, NNTP) |
| intl | Интернационализация (ICU) |
| ldap | Интеграция с Active Directory |
| mysqli | MySQL/MariaDB |
| opcache | Кеширование байт-кода |
| pdo_mysql | PDO для MySQL |
| pspell | Проверка орфографии |
| shmop | Shared memory |
| sockets | Сетевые сокеты |
| sodium | Современная криптография (libsodium) |
| sysvmsg | System V очереди сообщений |
| sysvsem | System V семафоры |
| sysvshm | System V разделяемая память |
| xsl | XSLT-преобразования |
| zip | Работа с ZIP-архивами |

### PECL расширения

| Расширение | Назначение |
|------------|------------|
| amqp | RabbitMQ |
| apcu | Пользовательский кеш в разделяемой памяти (APCu) — backend кеша Битрикс |
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
| ssh2 | Клиент SSH2/SFTP (версия 1.5.0) |
| xlswriter | Генерация Excel-файлов |
| zstd | Сжатие Zstandard |

### PEAR

- `DB` — абстракция базы данных (требуется некоторыми модулями Битрикс)

### Xdebug и XHProf

Расширения отладки и профилирования скомпилированы в образ, но **по умолчанию выключены**: на этапе сборки не выполняется `docker-php-ext-enable`, поэтому `.so`-файлы присутствуют, но не загружаются. В production это даёт нулевой overhead и сохраняет обратную совместимость.

| Расширение | Версия | Назначение |
|------------|--------|------------|
| xdebug | 3.5.1 | Пошаговая отладка, профилирование, трассировка |
| xhprof | 2.3.10 | Иерархическое профилирование производительности |

Активация выполняется в runtime через entrypoint, без пересборки образа:

- `XDEBUG_ENABLED=1` — создаётся `zzz-xdebug.ini` с `xdebug.mode=${XDEBUG_MODE}` (по умолчанию `off`), `xdebug.start_with_request=trigger` и `xdebug.client_host=host.docker.internal`.
- `XHPROF_ENABLED=1` — создаётся `zzz-xhprof.ini`, загружающий расширение.
- `XDEBUG_MODE` задаёт режим Xdebug (`debug`, `profile`, `trace` и др.).

```bash
docker run -d \
  -e XDEBUG_ENABLED=1 \
  -e XDEBUG_MODE=debug \
  msav/bitrix-php-apache:8.2
```

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

### Индексация документов

В образ включены CLI-инструменты, которые Битрикс использует для полнотекстовой индексации и модуля `search.title`:

| Инструмент | Назначение |
|------------|------------|
| `catdoc` | Извлечение текста из документов DOC |
| `poppler-utils` (`pdftotext`) | Извлечение текста из PDF |
| `aspell` | Проверка орфографии |
| `msmtp` | SMTP-клиент для отправки почты |

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
| OPcache не сразу видит изменения файлов | В production `revalidate_freq=2` (проверка раз в 2 с) | Использовать `PHP_INI_TYPE=development` (`revalidate_freq=0`) или перезапустить контейнер |
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
