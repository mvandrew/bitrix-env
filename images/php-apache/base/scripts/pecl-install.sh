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
    curl -sSfL --retry 3 --retry-all-errors --retry-delay 5 \
        --connect-timeout 15 --max-time 120 "$1" -o "$2"
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
