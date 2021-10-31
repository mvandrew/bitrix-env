# Пример docker-compose для связки MariaDB+PHP+Apache+Redis

Можно использовать независимо или с локальным репозиторием-клоном ветки master.

**Независимое использование** даёт полную свободу доработки всех файлов в каталоге примера.

Использование с **локальным репозиторием-клоном ветки master** позволяет своевременно получать обновления примера от автора.

## Как использовать

Можно скопировать к себе в локальный каталог все файлы из текущего каталога примера и далее модфифицировать/настраивать на своё усмотрение, или клонировать репозиторий целиком:

```
$ git clone https://github.com/mvandrew/bitrix-env.git
```

Во втором случае можно получать обновления из репозитория, когда они будут выпущены автором:

```
$ cd ~/bitrix-env && git pull
```

Для начала работы скопируйте файл текущего каталога ``default.env`` в ``.env``.

В файле ``.env`` задайте параметры своего компьютера и проекта.

**Важно**: по умолчанию параметры настроены на использование **12Gb** оперативной памяти MariaDB. Соответствующим образом сконфигурирован PHP. Эту конфигурацию можно использовать на компьютерах с **RAM 16G+**. Если у вашего компьютера памяти меньше, настройте параметры под него. В файле примера есть настройки для компьютеров с памятью **8G**: для таких компьютеров MariaDB ограничивается **4G RAM**.

После завершения настройки рекомендуется принудительно получить/обновить образы для MariaDB и PHP. Выполнить обновление можно скриптом:

```
$ ./update-images.sh
```

Запустить compose можно скриптом:

```
$ ./start.sh
```

## Установка 1С-Битрикс

Если compose запускается для нового проекта, в корне проекта будет создан файл установки 1С-Битрикс: [bitrixsetup.php](http://localhost/bitrixsetup.php).

Перейдите по указанной ссылке и запустите процесс установки.

При указании параметров подключения к БД контейнера MariaDB укажите:

* Host: **db**
* User: **bitrix**
* Password: **bitrixpwd**
* Database: **bitrix**

## Восстановление БД из дампа

Базу данных в контейнере MariaDB можно восстановить из дампа.

Восстановление выполяется скриптом ``restore.sh`` из каталога текущего примера.

Для запуска процесса восстановления следует указать аргументы:

1. **Имя контейнера**. Составляется из префикса имени проекта, который указан в файле ``.env`` в параметре ``PROJECT``. По-умолчанию - ``BitrixApache``. Вторая часть - суффикс имени контейнера, который указан в файле ``docker-compose.yml`` в параметре ``container_name`` сервиса БД. По-умолчанию - ``db``.
2. **Путь к файлу дампа**.

Пример использования:

```
$ ./restore.sh BitrixApachedb ~/site-db.dump
```

## Обратная совместимость со старыми версиями 1С-Битрикс

Образ собран на PHP 7.4, поэтому директива ``mbstring.func_overload`` устарела и новые версии 1С-Битрикс будут выдавать ошибку. Однако, если вы запускаете старую версию, которая жёстко проверяет наличие директивы, следует при запуске контейнера передать параметр ``SET_FUNC_OVERLOAD=1``.

В результате в конфигурационный файл php будет добавлена директива ``mbstring.func_overload = 2``.

**Важно**: в старых версиях 1С-Битрикс без указания этой директивы не будут работать часть строковых функций ядра и некоторых модулей, например ``CUtil::translit`` не будет видеть кирилицу.