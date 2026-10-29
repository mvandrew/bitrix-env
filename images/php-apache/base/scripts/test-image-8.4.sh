#!/usr/bin/env bash
# Дополнительные проверки PHP 8.4 перед публикацией 8.4/latest.
set -euo pipefail

image=${1:?Укажите образ}
port=${2:-0}
name=${3:-bitrix-php-8.4-test}
scripts_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
bash "$scripts_dir/test-image.sh" "$image" 8.4 "$port" "$name"

test_dir=$(mktemp -d)
container_id=
cleanup() {
    status=$?
    trap - EXIT
    if [[ -n "$container_id" ]]; then
        if (( status != 0 )); then docker logs --tail 100 "$container_id" >&2 || true; fi
        docker rm -f -v "$container_id" >/dev/null || true
    fi
    rm -rf "$test_dir"
    exit "$status"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
chmod 755 "$test_dir"

cat > "$test_dir/check.php" <<'PHP'
<?php
function check(bool $ok, string $message): void {
    if (!$ok) {
        fwrite(STDERR, $message . "\n");
        exit(1);
    }
}
$manifest = json_decode(file_get_contents('/usr/local/share/bitrix/extensions.json'), true, 512, JSON_THROW_ON_ERROR);
check($manifest['php'] === PHP_VERSION, 'Неверная версия PHP в extensions.json');
foreach (get_loaded_extensions() as $extension) {
    check(array_key_exists($extension, $manifest['extensions']), "Нет $extension в extensions.json");
    check($manifest['extensions'][$extension] === phpversion($extension), "Неверная версия $extension в extensions.json");
}
foreach (['xdebug', 'xhprof'] as $extension) {
    check(!empty($manifest['extensions'][$extension]), "Не записана версия $extension");
}
$value = ['text' => 'Проверка PHP 8.4', 'number' => 84];
check(igbinary_unserialize(igbinary_serialize($value)) === $value, 'Ошибка igbinary');
check(msgpack_unpack(msgpack_pack($value)) === $value, 'Ошибка msgpack');
$text = str_repeat('Bitrix PHP 8.4 ', 100);
check(lz4_uncompress(lz4_compress($text)) === $text, 'Ошибка LZ4');
check(lzf_decompress(lzf_compress($text)) === $text, 'Ошибка LZF');
check(zstd_uncompress(zstd_compress($text)) === $text, 'Ошибка Zstandard');
foreach (['SERIALIZER_IGBINARY', 'SERIALIZER_MSGPACK', 'COMPRESSION_LZ4', 'COMPRESSION_LZF', 'COMPRESSION_ZSTD'] as $option) {
    check(defined('Redis::' . $option), "В Redis отсутствует $option");
}
$gd = imagecreatetruecolor(2, 2);
check(imageavif($gd, '/tmp/test.avif'), 'Не удалось записать AVIF');
check(imagecreatefromavif('/tmp/test.avif') !== false, 'Не удалось прочитать AVIF');
$addresses = imap_rfc822_parse_adrlist('test@example.org', 'example.org');
check($addresses[0]->mailbox === 'test', 'Ошибка IMAP');
check(function_exists('pspell_new') && function_exists('pspell_check'), 'Нет API PSpell');
echo "Версии расширений, сериализация, сжатие, Redis, AVIF и IMAP проверены\n";
PHP

docker run --rm --mount "type=bind,src=${test_dir},dst=/checks,readonly" \
    --entrypoint bash "$image" -euo pipefail -c '
    php -m > /tmp/modules 2> /tmp/startup-errors
    test ! -s /tmp/startup-errors || { cat /tmp/startup-errors >&2; exit 1; }
    if grep -Ei "warning|deprecated|fatal|startup" /tmp/modules; then exit 1; fi
    for extension in /usr/local/lib/php/extensions/*/*.so; do
        deps=$(ldd "$extension")
        if printf "%s\n" "$deps" | grep "not found"; then exit 1; fi
    done
    php --ri imap | grep -Ei "SSL Support => enabled"
    php --ri imap | grep -Ei "Kerberos Support => enabled"
    for command in catdoc xls2csv catppt pdftotext aspell msmtp; do command -v "$command"; done
    php /checks/check.php
    cat /usr/local/share/bitrix/extensions.json
    '

# Каждый режим запускается в новом контейнере с обычным entrypoint.
# index.php предотвращает скачивание установщика Битрикс.
mkdir "$test_dir/www"
chmod 755 "$test_dir/www"
cat > "$test_dir/www/index.php" <<'PHP'
<?php
$production = getenv('PHP_INI_TYPE') === 'production';
$checks = [
    PHP_MAJOR_VERSION === 8 && PHP_MINOR_VERSION === 4,
    ini_get('opcache.revalidate_freq') === ($production ? '2' : '0'),
    ini_get('opcache.memory_consumption') === ($production ? '512' : '128'),
    (bool) ini_get('opcache.enable') === (getenv('PHP_EX_OPCACHE_ENABLED') !== '0'),
    extension_loaded('xdebug') === (getenv('XDEBUG_ENABLED') === '1'),
    extension_loaded('xhprof') === (getenv('XHPROF_ENABLED') === '1'),
    ini_get('memory_limit') === '768M',
    date_default_timezone_get() === 'Europe/Moscow',
];
http_response_code(in_array(false, $checks, true) ? 500 : 200);
echo in_array(false, $checks, true) ? 'FAIL' : 'OK';
PHP
chmod 644 "$test_dir/www/index.php"

for mode in development production; do
    for features in default enabled; do
        options=(-e PHP_INI_TYPE="$mode" -e CHOWN_MODE=skip -e MEMORY_LIMIT=768M)
        if [[ "$features" == enabled ]]; then
            options+=(-e XDEBUG_ENABLED=1 -e XDEBUG_MODE=debug -e XHPROF_ENABLED=1
                -e PHP_EX_OPCACHE_ENABLED=0 -e ENABLE_SSL=1 -p 127.0.0.1::443)
        fi
        container_id=$(docker create "${options[@]}" -p 127.0.0.1::80 \
            --mount "type=bind,src=${test_dir}/www,dst=/var/www/html" "$image")
        docker start "$container_id" >/dev/null
        address=$(docker port "$container_id" 80/tcp)
        ready=false
        for (( attempt=0; attempt<60; attempt++ )); do
            if curl --fail --silent --noproxy '*' --connect-timeout 2 --max-time 3 \
                "http://${address}/" > "$test_dir/body" && printf OK | cmp -s - "$test_dir/body"; then
                ready=true
                break
            fi
            if [[ $(docker inspect --format '{{.State.Running}}' "$container_id") != true ]]; then break; fi
            sleep 1
        done
        if [[ "$ready" != true ]]; then
            echo "Ошибка HTTP: $mode/$features" >&2
            cat "$test_dir/body" >&2 || true
            exit 1
        fi
        docker exec "$container_id" apache2ctl -t
        if [[ "$features" == enabled ]]; then
            address=$(docker port "$container_id" 443/tcp)
            curl --fail --silent --insecure --noproxy '*' --connect-timeout 2 --max-time 5 \
                "https://${address}/" > "$test_dir/body"
            printf OK | cmp -s - "$test_dir/body"
        fi
        echo "Режим $mode/$features: HTTP, PHP и настройки проверены"
        docker rm -f -v "$container_id" >/dev/null
        container_id=
    done
done
