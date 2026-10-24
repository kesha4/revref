#!/bin/sh
# RevRef usage — команда статусной строки Claude Code и чтение лимитов токенов для оркестратора.
#
# Claude Code передаёт процент использования лимитов (rate_limits.five_hour / seven_day) только
# в команду статусной строки. Этот скрипт сохраняет полученные данные, чтобы оркестратор мог
# проверить лимит между шагами (PIPELINE.md → «Бюджет времени и токенов»).
#
#   (stdin = JSON статусной строки)  — сохранить данные в <папка>/usage.json и вывести строку статусной строки:
#                                      вывод прежней команды из <папка>/statusline-next, если она есть, иначе свой
#   --read                           — вывести последние сохранённые лимиты; код 1, если данных нет
#
# <папка> — $REVREF_USAGE_DIR, иначе ${CLAUDE_CONFIG_DIR:-~/.claude}/revref.
# Нужны POSIX sh, sed, tr, date; jq не нужен.

dir=${REVREF_USAGE_DIR:-${CLAUDE_CONFIG_DIR:-$HOME/.claude}/revref}
data="$dir/usage.json"
next="$dir/statusline-next"

# Значение числового поля <ключ> внутри объекта окна <окно> (five_hour, seven_day).
field() {
    printf '%s' "$1" | tr '\n\r' '  ' \
        | sed -nE "s/.*\"$2\"[[:space:]]*:[[:space:]]*\{[^}]*\"$3\"[[:space:]]*:[[:space:]]*([0-9.]+).*/\1/p"
}

when() {
    date -d "@$1" '+%Y-%m-%d %H:%M %Z' 2>/dev/null || date -r "$1" '+%Y-%m-%d %H:%M %Z' 2>/dev/null || printf '%s' "$1"
}

if [ "${1:-}" = "--read" ]; then
    [ -s "$data" ] || { echo "no data: $data"; exit 1; }
    json=$(cat "$data")
    now=$(date +%s)
    found=0
    for win in seven_day five_hour; do
        pct=$(field "$json" "$win" used_percentage)
        [ -n "$pct" ] || continue
        found=1
        reset=$(field "$json" "$win" resets_at); reset=${reset%%.*}
        label=week; [ "$win" = five_hour ] && label=5h
        if [ -n "$reset" ] && [ "$reset" -le "$now" ]; then
            echo "$label: expired (window reset $(when "$reset"))"
        elif [ -n "$reset" ]; then
            echo "$label: $pct% (resets $(when "$reset"))"
        else
            echo "$label: $pct%"
        fi
    done
    saved=$(printf '%s' "$json" | sed -nE 's/^\{"saved_at":([0-9]+).*/\1/p')
    [ -n "$saved" ] && echo "updated: $((now - saved)) s ago"
    [ "$found" -eq 1 ] || { echo "no rate limits in $data"; exit 1; }
    exit 0
fi

input=$(cat)

# Сохраняем только данные с лимитами: ранние вызовы сессии без rate_limits не затирают прежние.
case "$input" in
    *'"rate_limits"'*)
        if mkdir -p "$dir" 2>/dev/null; then
            tmp="$data.$$"
            printf '{"saved_at":%s,"status":%s}\n' "$(date +%s)" "$input" > "$tmp" 2>/dev/null \
                && mv -f "$tmp" "$data" 2>/dev/null
            rm -f "$tmp" 2>/dev/null
        fi
        ;;
esac

# Прежняя статусная строка владельца, если RevRef встроен перед ней.
if [ -s "$next" ]; then
    printf '%s' "$input" | sh -c "$(tr -d '\r' < "$next")"
    exit $?
fi

week=$(field "$input" seven_day used_percentage)
hour=$(field "$input" five_hour used_percentage)
line=""
[ -n "$week" ] && line="неделя ${week%%.*}%"
[ -n "$hour" ] && line="${line:+$line · }5 ч ${hour%%.*}%"
[ -n "$line" ] && echo "RevRef · лимит: $line"
exit 0
