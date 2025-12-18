# Apache+PHP для 1С-Битрикс

Образ Docker, оптимизированный для запуска проектов на базе CMS 1С-Битрикс.

## Технические характеристики

- Базовый образ: PHP 8.2 с Apache
- Настроенные PHP-расширения для корректной работы Битрикс
- Поддержка SSL с автоматической генерацией самоподписных сертификатов
- Настроенный веб-сервер Apache с оптимальными параметрами
- Настройка отправки почты через внешний SMTP-сервер

## Переменные окружения

### Общие настройки

- `PHP_INI_TYPE` - тип конфигурации PHP (development/production), по умолчанию: development
- `MBSTRING_FUNC_OVERLOAD` - настройка перегрузки функций mbstring, по умолчанию: 2
- `MEMORY_LIMIT` - лимит памяти для PHP, по умолчанию: 64M
- `TZ` - временная зона, по умолчанию: Europe/Moscow
- `USER_ID` - ID пользователя, по умолчанию: 1000
- `GROUP_ID` - ID группы, по умолчанию: 1000
- `SITE_DOMAIN` - домен сайта, по умолчанию: mydomain.ru
- `SITE_IP` - IP сайта, по умолчанию: 127.0.0.1
- `PROXY_IPS` - IP-адреса прокси-серверов, по умолчанию: "127.0.0.1 127.0.0.2"
- `ACCESS_LOG` - путь к лог-файлу доступа, по умолчанию: /var/log/apache2/access.log
- `ERROR_LOG` - путь к лог-файлу ошибок, по умолчанию: /var/log/apache2/error.log

### Настройки SMTP

- `SMTP_ACCOUNT` - имя аккаунта SMTP, по умолчанию: docker
- `SMTP_HOST` - хост SMTP-сервера, по умолчанию: smtp.example.com
- `SMTP_PORT` - порт SMTP-сервера, по умолчанию: 587
- `SMTP_USER` - пользователь SMTP, по умолчанию: smtp_user
- `SMTP_PASSWORD` - пароль SMTP, по умолчанию: smtp_password
- `SMTP_TLS` - использование TLS, по умолчанию: on
- `SMTP_EMAIL` - email отправителя, по умолчанию: from@example.com
- `SMTP_AUTH` - использование аутентификации, по умолчанию: on

## Установленные PHP-расширения

- gd (с поддержкой freetype, jpeg, webp, xpm)
- mysqli
- mbstring
- xml
- opcache
- bz2
- calendar
- curl
- dom
- exif
- fileinfo
- ftp
- iconv
- ldap
- zip
- apcu

## Тома (Volumes)

- `/var/www/html` - корневая директория веб-сервера
- `/var/www/session` - директория для хранения сессий PHP
- `/var/log/apache2` - директория для логов Apache

## Порты

- 80 - HTTP
- 443 - HTTPS (SSL)

## Использование

### Пример docker-compose.yml

```yaml
version: '3'

services:
  bitrix:
    build:
      context: ./images/php-8.2-apache
      args:
        PHP_INI_TYPE_ARG: production
    volumes:
      - ./www:/var/www/html
      - ./sessions:/var/www/session
      - ./logs:/var/log/apache2
    environment:
      - SITE_DOMAIN=mysite.ru
      - MEMORY_LIMIT=256M
      - SMTP_HOST=smtp.company.ru
      - SMTP_USER=user
      - SMTP_PASSWORD=password
      - SMTP_EMAIL=noreply@company.ru
    ports:
      - "80:80"
      - "443:443"
```

### Запуск

```bash
docker-compose up -d
```

## Безопасность

- В образе установлены российские корневые сертификаты
- Генерируется самоподписный SSL-сертификат для домена, указанного в переменной SITE_DOMAIN
- Настроена отправка почты через защищенное SMTP-соединение

## Дополнительно

В образе используются следующие конфигурационные файлы:
- `php-opcache.ini` - оптимизированные настройки OPcache
- `zbx-php.ini` - дополнительные настройки PHP
- `bitrix-httpd.conf` - конфигурация Apache для работы с Битрикс
- `bitrix-entrypoint.sh` - скрипт, выполняемый при запуске контейнера
