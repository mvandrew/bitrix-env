# MariaDB для 1C-Битрикс

Docker-образы MariaDB с вшитой конфигурацией для 1C-Битрикс CMS и Битрикс24: обязательные параметры совместимости, кодировка UTF8MB4 и настройки InnoDB под типовые профили памяти.

## Поддерживаемые теги

| Тег | Базовый образ | Назначение |
|-----|---------------|------------|
| `11.8`, `latest` | mariadb:11.8 | LTS, рекомендуемая версия для новых проектов |
| `10.11` | mariadb:10.11 | LTS, стабильная альтернатива |
| `10.6` | mariadb:10.6 | Legacy, только для устаревших проектов |

## Быстрый старт

### Docker Run

```bash
docker run -d \
  --name bitrix-db \
  -p 3306:3306 \
  -e MYSQL_ROOT_PASSWORD=rootpwd \
  -e MYSQL_DATABASE=bitrix \
  -e MYSQL_USER=bitrix \
  -e MYSQL_PASSWORD=bitrixpwd \
  -v bitrix-db-data:/var/lib/mysql \
  msav/bitrix-mariadb:11.8
```

### Docker Compose

```yaml
services:
  db:
    image: msav/bitrix-mariadb:11.8
    ports:
      - "3306:3306"
    environment:
      MYSQL_ROOT_PASSWORD: "rootpwd"
      MYSQL_DATABASE: "bitrix"
      MYSQL_USER: "bitrix"
      MYSQL_PASSWORD: "bitrixpwd"
    volumes:
      - db-data:/var/lib/mysql
      - ./my-custom.cnf:/etc/mysql/bitrix.d/custom.cnf

volumes:
  db-data:
```

## Переменные окружения

| Переменная | Обязательность | Описание |
|------------|----------------|----------|
| `MYSQL_ROOT_PASSWORD` | Обязательна | Пароль `root`; также используется в health check |
| `MYSQL_DATABASE` | Опционально | Имя создаваемой базы |
| `MYSQL_USER` | Опционально | Имя создаваемого пользователя |
| `MYSQL_PASSWORD` | Опционально | Пароль создаваемого пользователя |

Часовой пояс задаётся на этапе сборки через build-arg `SITE_TIMEZONE` (по умолчанию `Europe/Moscow`) и пробрасывается в `ENV TZ`.

## Конфигурация MariaDB

Обязательные параметры совместимости с Битрикс вшиты в образ:

| Параметр | Значение | Зачем |
|----------|----------|-------|
| `sql_mode` | `""` | Иначе ошибки вставки и обновления данных |
| `transaction-isolation` | `READ-COMMITTED` | Ожидаемый платформой уровень изоляции |
| `innodb_snapshot_isolation` | `OFF` | Иначе `ER_CHECKREAD` (ERROR 1020) под нагрузкой на MariaDB 11.6.2/11.8 |
| `max_allowed_packet` | `256M` | Большие пакеты при импорте и обмене с 1С |
| `innodb_strict_mode` | `OFF` | Снимает строгую проверку схем таблиц |
| `explicit_defaults_for_timestamp` | `1` | Стандартное поведение `TIMESTAMP` |

Кодировка: `character-set-server = utf8mb4`, `collation-server = utf8mb4_unicode_ci`, `init-connect = "SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci"`.

Любой параметр переопределяется без пересборки: смонтируйте свой `.cnf` в `/etc/mysql/bitrix.d/` — файлы оттуда загружаются после вшитой конфигурации и имеют наивысший приоритет.

## Development vs Production

В образ вшита production-конфигурация. Для разработки смонтируйте `bitrix-dev.cnf` в `/etc/mysql/bitrix.d/`.

| Параметр | Development | Production |
|----------|-------------|------------|
| `innodb_buffer_pool_size` | 512M | 4G |
| `innodb_log_file_size` | 128M | 512M |
| `innodb_buffer_pool_instances` | 2 | 4 |
| `innodb_flush_log_at_trx_commit` | 2 | 1 |
| `slow_query_log` | 1 | 0 |

Профили `innodb_buffer_pool_size` по объёму ОЗУ хоста:

| RAM хоста | innodb_buffer_pool_size | instances |
|-----------|-------------------------|-----------|
| 4 GB | 2G | 2 |
| 8 GB | 4G | 4 |
| 16 GB и больше | 12G | 12 |

## Тома

| Путь | Назначение |
|------|------------|
| `/var/lib/mysql` | Данные базы |
| `/etc/mysql/bitrix.d` | Пользовательские переопределения конфигурации |

## Порты

| Порт | Протокол |
|------|----------|
| 3306 | MySQL/MariaDB |

## Health Check

Каждые 30 секунд выполняется команда `ping` от имени `root` с паролем из `MYSQL_ROOT_PASSWORD`: `mariadb-admin ping` в 11.8 и 10.11, `mysqladmin ping` в 10.6. Без `MYSQL_ROOT_PASSWORD` контейнер будет помечен `unhealthy`.

## Решение проблем

| Симптом | Решение |
|---------|---------|
| Ошибки вставки/обновления данных | Убедиться, что итоговый `sql_mode` пустой |
| `ERROR 1020 (ER_CHECKREAD)` на 11.8 | Проверить, что `innodb_snapshot_isolation = OFF` не переопределён |
| Контейнер `unhealthy` | Задать `MYSQL_ROOT_PASSWORD` |
| Нехватка памяти, медленный InnoDB | Подобрать `innodb_buffer_pool_size` по ОЗУ хоста |
| Искажение символов | Проверить кодировку подключения (UTF8MB4) |

## Ссылки

- **GitHub**: [mvandrew/bitrix-env](https://github.com/mvandrew/bitrix-env)
- **Полная документация**: [README.md](https://github.com/mvandrew/bitrix-env/blob/main/images/mariadb/README.md)
