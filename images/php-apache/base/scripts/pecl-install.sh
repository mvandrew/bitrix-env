#!/bin/sh
# pecl-install <пакет> [параметры pecl install]
# Архив содержит package.xml: REST-метаданные канала для установки не нужны.
set -eu

package=${1:?Укажите имя PECL-пакета}
shift
if ! printf '%s\n' "$package" | grep -Eq '^[A-Za-z][A-Za-z0-9_]*$'; then
    echo 'Некорректное имя PECL-пакета' >&2
    exit 2
fi
work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

selector=$(dirname "$0")/pecl-compatible.php
download() {
    # curl не читает stdin: ответы на configure-вопросы получает сам PECL.
    if curl -sSfL --retry 3 --retry-all-errors --retry-delay 5 \
        --connect-timeout 15 --max-time 120 "$1" -o "$2"; then
        return 0
    else
        download_status=$?
    fi

    # Пока переключение включается только в builder PHP 8.2.
    if [ "${PECL_IPV4_FALLBACK:-0}" != 1 ]; then
        return "$download_status"
    fi
    case "$download_status" in
        6|7|18|28|35|52|55|56) ;;
        *) return "$download_status" ;;
    esac
    case "$1" in
        https://pecl.php.net/*) ;;
        *) return "$download_status" ;;
    esac

    echo "PECL: curl завершился с кодом $download_status; получаем актуальные IPv4 pecl.php.net" >&2
    if ! getent ahostsv4 pecl.php.net > "$work_dir/addresses.raw"; then
        echo 'PECL: не удалось получить IPv4-адреса для переключения' >&2
        return "$download_status"
    fi
    awk '!seen[$1]++ { print $1 }' "$work_dir/addresses.raw" > "$work_dir/addresses"
    # fd 3 может быть занят списком релизов; stdin нужен для ответов PECL.
    while IFS= read -r download_ip <&4; do
        echo "PECL: пробуем IPv4 $download_ip для $1" >&2
        # --resolve сохраняет имя хоста, SNI и проверку сертификата.
        if curl -4 -sSfL --resolve "pecl.php.net:443:$download_ip" \
            --connect-timeout 15 --max-time 120 "$1" -o "$2"; then
            echo "PECL: загрузка через $download_ip выполнена" >&2
            return 0
        else
            download_status=$?
            echo "PECL: IPv4 $download_ip, ошибка curl $download_status" >&2
        fi
        case "$download_status" in
            6|7|18|28|35|52|55|56) ;;
            *) return "$download_status" ;;
        esac
    done 4< "$work_dir/addresses"
    echo 'PECL: доступные IPv4-адреса исчерпаны' >&2
    return "$download_status"
}
check_archive() {
    if ! tar -xOf "$work_dir/package.tgz" package2.xml > "$work_dir/package.xml" 2>/dev/null; then
        if ! tar -xOf "$work_dir/package.tgz" package.xml > "$work_dir/package.xml"; then
            echo 'Не удалось прочитать package.xml из архива PECL' >&2
            return 2
        fi
    fi
    php "$selector" check "$work_dir/package.xml" "$package"
}

download "https://pecl.php.net/get/${package}-stable" "$work_dir/package.tgz"
if selected=$(check_archive); then
    pecl install --offline "$@" "$work_dir/package.tgz"
    exit $?
else
    status=$?
    if [ "$status" -ne 1 ]; then exit "$status"; fi
fi

# Список старых релизов нужен только при несовместимом последнем stable.
# Получаем его curl с повторами; сам PECL по-прежнему работает без сети.
rest_package=$(printf '%s' "$package" | tr '[:upper:]' '[:lower:]')
download "https://pecl.php.net/rest/r/${rest_package}/allreleases.xml" "$work_dir/releases.xml"
php "$selector" releases "$work_dir/releases.xml" > "$work_dir/versions"
while IFS= read -r version <&3; do
    if [ "$version" = "$selected" ]; then continue; fi
    download "https://pecl.php.net/get/${package}-${version}" "$work_dir/package.tgz"
    if selected=$(check_archive); then
        # fd 3 занят списком версий; stdin с ответами configure остаётся прежним.
        pecl install --offline "$@" "$work_dir/package.tgz"
        exit $?
    else
        status=$?
        if [ "$status" -ne 1 ]; then exit "$status"; fi
    fi
done 3< "$work_dir/versions"

echo "PECL: нет stable-релиза ${package}, совместимого с текущим PHP" >&2
exit 1
