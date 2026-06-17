# MariaDB Docker Images для 1C-Битрикс

Docker-образы MariaDB, оптимизированные для разработки и production-развёртывания 1C-Битрикс CMS и Битрикс24. Содержат вшитую конфигурацию с обязательными для платформы параметрами совместимости, кодировкой UTF8MB4 и настройками InnoDB под типовые профили памяти.

## Доступные версии

| Тег | Базовый образ | Статус и совместимость | Примечание |
|-----|---------------|------------------------|------------|
| `11.8` | mariadb:11.8 | LTS, рекомендуемая версия | Соответствует тегу `latest` |
| `10.11` | mariadb:10.11 | LTS, стабильная альтернатива | Для проектов, где не требуется 11.x |
| `10.6` | mariadb:10.6 | Legacy | Только для устаревших проектов |

Тег `latest` указывает на 11.8 LTS — это версия по умолчанию для новых проектов. Все образы используют single-stage сборку поверх официальных образов MariaDB (Debian Bookworm) и несут одинаковую Bitrix-конфигурацию; различаются базовой версией СУБД и набором служебных команд (см. раздел «Различия 10.6 / 10.11 / 11.8»).

### Legacy-версия 10.6

Образ 10.6 оставлен для проектов, которые ещё не переведены на актуальную ветку MariaDB. Он собирается на базе `mariadb:10.6` и использует классические команды (`mysqld`, `mysqladmin`) вместо переименованных в новых версиях. Для новых установок используйте 11.8 или 10.11.

## Быстрый старт

### Сборка образа

Все образы собираются из родительской директории `images/mariadb`, потому что конфигурация `base/conf/bitrix-prod.cnf` лежит вне каталога версии и попадает в контекст сборки:

```bash
cd bitrix-env/images/mariadb
docker build -t msav/bitrix-mariadb:11.8 -f 11.8/Dockerfile .
```

Либо через Makefile из каталога версии:

```bash
cd bitrix-env/images/mariadb/11.8
make build
```

### Запуск контейнера

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
      # Кастомные параметры без пересборки образа
      - ./my-custom.cnf:/etc/mysql/bitrix.d/custom.cnf

volumes:
  db-data:
```

Доступные теги на Docker Hub: `msav/bitrix-mariadb:11.8`, `msav/bitrix-mariadb:10.11`, `msav/bitrix-mariadb:10.6`, `msav/bitrix-mariadb:latest`.

## Переменные окружения

### Учётные данные и инициализация

Образ наследует стандартный механизм инициализации официального образа MariaDB. Переменные применяются только при первом запуске на пустом томе данных.

| Переменная | Обязательность | Описание |
|------------|----------------|----------|
| `MYSQL_ROOT_PASSWORD` | Обязательна | Пароль пользователя `root`. Дополнительно используется в health check для проверки отклика сервера |
| `MYSQL_DATABASE` | Опционально | Имя создаваемой при инициализации базы данных |
| `MYSQL_USER` | Опционально | Имя создаваемого пользователя |
| `MYSQL_PASSWORD` | Опционально | Пароль создаваемого пользователя |

> **Внимание:** без `MYSQL_ROOT_PASSWORD` health check не сможет аутентифицироваться, и контейнер будет помечен как `unhealthy`, даже если сервер фактически запущен.

### Часовой пояс

Часовой пояс задаётся на этапе сборки через build-arg `SITE_TIMEZONE` и пробрасывается в переменную окружения `TZ`.

| Параметр | Тип | Умолчание | Описание |
|----------|-----|-----------|----------|
| `SITE_TIMEZONE` | build-arg | `Europe/Moscow` | Часовой пояс контейнера; определяет `/etc/localtime` и `ENV TZ` |

```bash
docker build \
  --build-arg SITE_TIMEZONE=Europe/Kaliningrad \
  -t msav/bitrix-mariadb:11.8 -f 11.8/Dockerfile .
```

## Конфигурация MariaDB

### Совместимость с Битрикс (обязательно)

Эти параметры вшиты в образ и критичны для корректной работы платформы. Менять их без необходимости не следует.

| Параметр | Значение | Зачем |
|----------|----------|-------|
| `sql_mode` | `""` (пустой) | Битрикс рассчитан на нестрогий режим. При непустом `sql_mode` возникают ошибки вставки и обновления данных |
| `transaction-isolation` | `READ-COMMITTED` | Уровень изоляции, на который ориентирована платформа; снижает число блокировок при конкуренции |
| `innodb_snapshot_isolation` | `OFF` | Начиная с MariaDB 11.6.2/11.8 параметр включён по умолчанию и под нагрузкой провоцирует `ER_CHECKREAD` (ERROR 1020). Отключение возвращает классическое поведение MySQL, ожидаемое Битрикс |
| `max_allowed_packet` | `256M` | Допускает большие пакеты данных при импорте, операциях с инфоблоками и обмене с 1С |
| `innodb_strict_mode` | `OFF` | Снимает строгую проверку параметров создания таблиц, на которую не рассчитаны схемы Битрикс |
| `explicit_defaults_for_timestamp` | `1` | Стандартное поведение колонок `TIMESTAMP` без неявных значений |

### Кодировка

Полная поддержка Unicode обеспечивается кодировкой UTF8MB4 на уровне сервера, клиента и соединения.

| Параметр | Значение |
|----------|----------|
| `character-set-server` | `utf8mb4` |
| `collation-server` | `utf8mb4_unicode_ci` |
| `init-connect` | `SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci` |

Секции `[client]` и `[mysql]` дополнительно задают `default-character-set = utf8mb4`.

### Иерархия загрузки конфигов

Базовый образ MariaDB подключает все файлы из `/etc/mysql/conf.d/`. Bitrix-конфигурация копируется туда под именем `99-bitrix.cnf` — числовой префикс `99-` гарантирует, что файл читается последним и переопределяет значения по умолчанию из стандартных конфигов образа.

Последней директивой Bitrix-конфигурации идёт `!includedir /etc/mysql/bitrix.d/`. Каталог `bitrix.d` смонтирован как том и предназначен для пользовательских переопределений: файлы оттуда подключаются после `99-bitrix.cnf` и имеют наивысший приоритет.

Порядок применения (каждый следующий уровень переопределяет предыдущий):

1. Стандартные конфиги базового образа MariaDB.
2. `/etc/mysql/conf.d/99-bitrix.cnf` — вшитая Bitrix-конфигурация (production).
3. `/etc/mysql/bitrix.d/*.cnf` — пользовательские переопределения (см. «Кастомные настройки без пересборки»).

### Профили памяти InnoDB

Вшитая production-конфигурация рассчитана на хост примерно с 8 ГБ ОЗУ. Для других объёмов памяти подберите `innodb_buffer_pool_size` и число instance-ов по таблице ниже (значения из комментария в `base/conf/bitrix-prod.cnf`):

| RAM хоста | innodb_buffer_pool_size | innodb_buffer_pool_instances |
|-----------|-------------------------|------------------------------|
| 4 GB | 2G | 2 |
| 8 GB | 4G | 4 |
| 16 GB и больше | 12G | 12 |

Переопределять эти значения следует через файл в `/etc/mysql/bitrix.d/`, а не пересборкой образа.

## Режимы конфигурации

### Development vs Production

В образ вшита production-конфигурация (`bitrix-prod.cnf`). Файл `bitrix-dev.cnf` поставляется как эталон для локальной разработки: его монтируют в `/etc/mysql/bitrix.d/`, чтобы понизить потребление ресурсов и включить лог медленных запросов. Обязательные Bitrix-параметры и кодировка в обоих профилях идентичны; различаются только настройки производительности и логирования.

| Параметр | Development | Production |
|----------|-------------|------------|
| `innodb_buffer_pool_size` | 512M | 4G |
| `innodb_log_file_size` | 128M | 512M |
| `innodb_log_buffer_size` | 64M | 256M |
| `innodb_buffer_pool_instances` | 2 | 4 |
| `innodb_flush_log_at_trx_commit` | 2 | 1 |
| `innodb_write_io_threads` | 4 | 16 |
| `innodb_read_io_threads` | 4 | 16 |
| `table_open_cache` | 2048 | 4096 |
| `thread_cache_size` | 16 | 32 |
| `sort_buffer_size` | 1M | 2M |
| `join_buffer_size` | 1M | 64M |
| `max_heap_table_size` | 32M | 64M |
| `tmp_table_size` | 32M | 64M |
| `slow_query_log` | 1 (`long_query_time = 2`) | 0 |

В production `innodb_flush_log_at_trx_commit = 1` обеспечивает максимальную надёжность фиксации транзакций, в development значение `2` снижает нагрузку на диск ценой риска потери последней секунды транзакций при сбое — приемлемый компромисс для локальной машины.

### Кастомные настройки без пересборки

Любой параметр можно переопределить, смонтировав свой `.cnf` в `/etc/mysql/bitrix.d/`. Файлы из этого каталога подключаются после вшитой конфигурации и имеют наивысший приоритет.

Перейти на development-профиль:

```bash
docker run -d \
  --name bitrix-db \
  -e MYSQL_ROOT_PASSWORD=rootpwd \
  -v $(pwd)/base/conf/bitrix-dev.cnf:/etc/mysql/bitrix.d/dev.cnf \
  msav/bitrix-mariadb:11.8
```

Переопределить отдельные параметры под объём памяти хоста:

```ini
# my-custom.cnf
[mysqld]
innodb_buffer_pool_size = 12G
innodb_buffer_pool_instances = 12
```

```bash
docker run -d \
  --name bitrix-db \
  -e MYSQL_ROOT_PASSWORD=rootpwd \
  -v $(pwd)/my-custom.cnf:/etc/mysql/bitrix.d/custom.cnf \
  msav/bitrix-mariadb:11.8
```

## Структура контейнера

### Тома

| Путь | Назначение |
|------|------------|
| `/var/lib/mysql` | Данные базы (объявлен как `VOLUME`) |
| `/etc/mysql/bitrix.d` | Каталог пользовательских переопределений конфигурации (объявлен как `VOLUME`) |

### Порты

| Порт | Протокол |
|------|----------|
| 3306 | MySQL/MariaDB |

### Health Check

Health check выполняется каждые 30 секунд (`--interval=30s`), с таймаутом 10 секунд (`--timeout=10s`), льготным периодом 60 секунд после старта (`--start-period=60s`) и тремя попытками до пометки `unhealthy` (`--retries=3`).

Проверка отправляет команду `ping` от имени `root` с паролем из `MYSQL_ROOT_PASSWORD`:

- В 11.8 и 10.11 используется `mariadb-admin ping`.
- В 10.6 используется `mysqladmin ping` (актуальная для этой версии команда).

Поскольку проверка аутентифицируется как `root`, переменная `MYSQL_ROOT_PASSWORD` обязательна — без неё контейнер будет помечен `unhealthy`.

## Особенности

### Single-stage сборка

В отличие от образов php-apache, MariaDB-образы используют одноэтапную сборку поверх официального образа. Слой сборки добавляет только настройку часового пояса и локали, создание каталога `bitrix.d` и копирование Bitrix-конфигурации, поэтому overhead над базовым образом минимален.

### Часовой пояс и локаль

Слой сборки устанавливает пакеты `locales` и `tzdata`, настраивает `/etc/localtime` и `/etc/timezone` по значению `SITE_TIMEZONE`, после чего генерирует локаль `en_US.UTF-8`. Это обеспечивает корректную работу с временными метками и UTF-8 на уровне ОС контейнера.

### Различия 10.6 / 10.11 / 11.8

Все три образа несут одинаковую Bitrix-конфигурацию. Различия касаются базовой версии СУБД и служебных команд, переименованных в новых ветках MariaDB.

| Аспект | 10.6 | 10.11 | 11.8 |
|--------|------|-------|------|
| Базовый образ | mariadb:10.6 | mariadb:10.11 | mariadb:11.8 |
| Статус | Legacy | LTS, стабильная | LTS, рекомендуемая (`latest`) |
| Команда запуска (`CMD`) | `mysqld` | `mariadbd` | `mariadbd` |
| Команда health check | `mysqladmin ping` | `mariadb-admin ping` | `mariadb-admin ping` |

В 11.8 актуален параметр `innodb_snapshot_isolation = OFF` — без него под конкурентной нагрузкой возникает `ER_CHECKREAD`. Параметр безопасно присутствует и в конфигурации для 10.x: в этих версиях он попросту игнорируется как неизвестный либо уже отключён по умолчанию.

## Сборка и тестирование (Makefile)

В каждом каталоге версии есть Makefile с типовыми целями.

| Цель | Действие |
|------|----------|
| `help` | Список доступных целей |
| `pull` | Загрузка базового образа `mariadb:<версия>` |
| `build` | Сборка образа (с предварительным `pull`) |
| `rebuild` | Сборка без кеша (`--no-cache`) |
| `push` | Публикация на Docker Hub |
| `run` | Запуск контейнера с дефолтными параметрами и пробросом порта 3306 |
| `run-bash` | Запуск контейнера с интерактивным bash |
| `stop` | Остановка и удаление контейнера |
| `clean` | Остановка контейнера и удаление образа |
| `test` | Сборка и smoke-тест ключевых параметров |

Цель `run` поднимает контейнер с учётными данными `MYSQL_ROOT_PASSWORD=rootpwd`, `MYSQL_DATABASE=bitrix`, `MYSQL_USER=bitrix`, `MYSQL_PASSWORD=bitrixpwd` и пробросом `-p 3306:3306`.

Цель `test` запускает контейнер, ждёт 45 секунд инициализации и проверяет ключевые значения: версию (`VERSION()`), `sql_mode`, `character_set_server`, `collation_server`, `transaction_isolation` и `innodb_buffer_pool_size`.

> **Примечание:** для 11.8 и 10.11 цель `push` дополнительно проставляет и публикует тег `latest`. В Makefile для 10.6 публикуется только тег версии — legacy-образ на `latest` не претендует.

## Решение проблем

| Симптом | Причина | Решение |
|---------|---------|---------|
| Ошибки вставки/обновления, отклонение «нулевых» дат | Непустой `sql_mode` (например, из смонтированного конфига) | Убедиться, что итоговый `sql_mode` пустой; проверить переопределения в `/etc/mysql/bitrix.d/` |
| `ERROR 1020 (ER_CHECKREAD)` под нагрузкой на 11.8 | Включён `innodb_snapshot_isolation` | Параметр `innodb_snapshot_isolation = OFF` уже вшит; проверить, что его не переопределяет смонтированный конфиг |
| Контейнер `unhealthy`, хотя сервер работает | Health check не может аутентифицироваться | Задать `MYSQL_ROOT_PASSWORD` |
| Нехватка памяти, медленный старт InnoDB | `innodb_buffer_pool_size` не соответствует ОЗУ хоста | Подобрать значение по таблице профилей памяти и смонтировать переопределение в `bitrix.d` |
| Искажение символов, «кракозябры» | Подключение не в UTF8MB4 | Проверить кодировку клиента и `SET NAMES utf8mb4`; сверить `character_set_server` |
| Медленные запросы | Не хватает буферов или индексов | На время диагностики включить `slow_query_log` (dev-профиль), проанализировать запросы |
| Изменения параметров не применяются | Переопределение перекрыто более приоритетным конфигом | Учитывать порядок загрузки: `conf.d/99-bitrix.cnf` → `bitrix.d/*.cnf` |

### Логи и диагностика

```bash
# Логи сервера MariaDB
docker logs <container>

# Версия СУБД (для 11.8/10.11)
docker exec <container> mariadb -uroot -p<пароль> -e "SELECT VERSION();"

# Проверка обязательных Bitrix-параметров
docker exec <container> mariadb -uroot -p<пароль> -e "SHOW VARIABLES LIKE 'sql_mode';"
docker exec <container> mariadb -uroot -p<пароль> -e "SHOW VARIABLES LIKE 'transaction_isolation';"
docker exec <container> mariadb -uroot -p<пароль> -e "SHOW VARIABLES LIKE 'innodb_snapshot_isolation';"

# Проверка кодировки
docker exec <container> mariadb -uroot -p<пароль> -e "SHOW VARIABLES LIKE 'character_set_server';"
docker exec <container> mariadb -uroot -p<пароль> -e "SHOW VARIABLES LIKE 'collation_server';"

# Проверка памяти InnoDB
docker exec <container> mariadb -uroot -p<пароль> -e "SHOW VARIABLES LIKE 'innodb_buffer_pool_size';"
```

> **Примечание:** в образе 10.6 вместо клиента `mariadb` используйте `mysql`.
