#!/usr/bin/env bash
# Общая проверка образов PHP Apache для Makefile и GitHub Actions.
set -euo pipefail

image=${1:?Укажите образ}
version=${2:?Укажите версию PHP: 8.1 или 8.2}
port=${3:-0}
name=${4:-bitrix-php-test}
container_id=
test_dir=$(mktemp -d)

cleanup() {
    status=$?
    trap - EXIT
    if [[ -n "$container_id" ]]; then
        if (( status != 0 )); then
            docker inspect --format '{{json .State}}' "$container_id" >&2 || true
            docker logs --tail 200 "$container_id" >&2 || true
            if [[ -f "$test_dir/body" ]]; then
                cat "$test_dir/body" >&2
            fi
        fi
        docker rm -f -v "$container_id" >/dev/null || true
    fi
    rm -rf "$test_dir"
    exit "$status"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# Проверяем PHP напрямую: служебный вывод entrypoint не участвует в проверке.
docker run --rm -i -e EXPECTED_PHP_VERSION="$version" --entrypoint php "$image" <<'PHP'
<?php
$stderr = fopen('php://stderr', 'w');
$expected = getenv('EXPECTED_PHP_VERSION');
if (PHP_MAJOR_VERSION . '.' . PHP_MINOR_VERSION !== $expected) {
    fwrite($stderr, "Ожидался PHP $expected, получен " . PHP_VERSION . "\n");
    exit(1);
}
$required = array_merge(['Zend OPcache'], explode(' ', 'bz2 calendar ctype curl dom exif fileinfo ftp gd gettext iconv json ldap mbstring mysqlnd mysqli pdo_mysql pspell shmop simplexml sockets sodium tokenizer xml xmlreader xmlwriter mcrypt zip memcache memcached redis imagick rrd imap xlswriter amqp igbinary msgpack apcu lz4 zstd lzf rdkafka intl xsl sysvmsg sysvsem sysvshm ssh2'));
$missing = array_filter($required, static fn($name) => !extension_loaded($name));
if ($missing) {
    fwrite($stderr, 'Отсутствуют расширения: ' . implode(', ', $missing) . "\n");
    exit(1);
}
if (empty(gd_info()['AVIF Support'])) {
    fwrite($stderr, "В GD отсутствует поддержка AVIF\n");
    exit(1);
}
foreach (['xdebug', 'xhprof'] as $name) {
    if (!is_file(ini_get('extension_dir') . '/' . $name . '.so') || extension_loaded($name)) {
        fwrite($stderr, "$name должен существовать и быть выключен по умолчанию\n");
        exit(1);
    }
}
require_once 'DB.php';
if (!class_exists('DB', false)) {
    fwrite($stderr, "Не загружен PEAR DB\n");
    exit(1);
}
echo 'PHP ' . PHP_VERSION . ": расширения, AVIF и PEAR DB проверены\n";
PHP

# index.php исключает скачивание установщика при проверке чистого docroot.
mkdir "$test_dir/www"
chmod 755 "$test_dir/www"
printf '<?php echo "test";\n' > "$test_dir/www/index.php"
chmod 644 "$test_dir/www/index.php"
container_id=$(docker create --name "${name}-$$" \
    -e CHOWN_MODE=skip \
    -p "127.0.0.1:${port}:80" \
    --mount "type=bind,src=${test_dir}/www,dst=/var/www/html" \
    "$image")
docker start "$container_id" >/dev/null
address=$(docker port "$container_id" 80/tcp)
url="http://${address}/health.php"
deadline=$((SECONDS + 120))
while (( SECONDS < deadline )); do
    if [[ $(docker inspect --format '{{.State.Running}}' "$container_id") != true ]]; then
        echo 'Контейнер завершился до готовности Apache' >&2
        exit 1
    fi
    remaining=$((deadline - SECONDS))
    if (( remaining <= 0 )); then break; fi
    request_timeout=5
    if (( remaining < request_timeout )); then request_timeout=$remaining; fi
    if code=$(curl --silent --show-error --noproxy '*' --connect-timeout 2 \
        --max-time "$request_timeout" --output "$test_dir/body" \
        --write-out '%{http_code}' "$url" 2> "$test_dir/curl-error"); then
        if [[ "$code" == 200 ]] && printf OK | cmp -s - "$test_dir/body"; then
            echo 'HTTP 200, тело OK: Apache и PHP готовы'
            exit 0
        fi
    fi
    sleep 1
done
echo 'Apache не вернул HTTP 200 с телом OK за 120 секунд' >&2
cat "$test_dir/curl-error" >&2 || true
exit 1
