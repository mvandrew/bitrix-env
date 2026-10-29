#!/bin/sh
# Повторяем запросы PECL, сохраняя ответы для каждой попытки.
set -eu

input=$(mktemp)
trap 'rm -f "$input"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
cat > "$input"

attempt=1
delay=5
while :; do
    if pecl "$@" < "$input"; then
        exit 0
    else
        status=$?
    fi
    if [ "$attempt" -ge 4 ]; then
        echo "PECL: ошибка после ${attempt} попыток (код ${status})" >&2
        exit "$status"
    fi
    echo "PECL: попытка ${attempt} не удалась; повтор через ${delay} с" >&2
    sleep "$delay"
    attempt=$((attempt + 1))
    delay=$((delay * 2))
done
