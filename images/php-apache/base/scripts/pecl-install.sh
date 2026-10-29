#!/bin/sh
# pecl-install <пакет[-версия|состояние]> [параметры pecl install]
# Архив содержит package.xml: REST-метаданные канала для установки не нужны.
set -eu

package=${1:?Укажите имя PECL-пакета}
shift
if ! printf '%s\n' "$package" | grep -Eq '^[A-Za-z][A-Za-z0-9_]*(-[A-Za-z0-9.]+)?$'; then
    echo 'Некорректное имя PECL-пакета' >&2
    exit 2
fi
case "$package" in
    *-*) release=$package ;;
    *) release=${package}-stable ;;
esac

work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# curl не читает stdin: ответы на configure-вопросы получает сам PECL.
curl -sSfL --retry 3 --retry-all-errors --retry-delay 5 \
    --connect-timeout 15 --max-time 120 \
    "https://pecl.php.net/get/${release}" -o "$work_dir/package.tgz"

# Не обращаемся к каналам, но сохраняем проверки package.xml и зависимостей.
pecl install --offline "$@" "$work_dir/package.tgz"
