#!/bin/sh
# Тест hooks/usage.sh: сохранение лимитов из JSON статусной строки, --read, цепочка с прежней статусной
# строкой и команда для settings.json из PIPELINE.md. Обе языковые версии.
# Запуск: sh scripts/test_usage.sh  (macOS, Linux, Git Bash на Windows).
set -u
root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d 2>/dev/null || mktemp -d -t revrefusage)
trap 'rm -rf "$tmp"' EXIT
fail=0
ok() { echo "ok   $1"; }
bad() { echo "FAIL $1"; fail=1; }

now=$(date +%s); future=$((now + 3600)); past=$((now - 60))
compact='{"model":{"display_name":"Opus"},"rate_limits":{"five_hour":{"used_percentage":23.5,"resets_at":'$future'},"seven_day":{"used_percentage":41.2,"resets_at":'$future'}}}'
pretty=$(printf '{\n  "rate_limits": {\n    "seven_day": {\n      "used_percentage": 96,\n      "resets_at": %s\n    }\n  }\n}' "$past")

for lang in ru en; do
    s="$root/skill/revref/hooks/usage.sh"; [ "$lang" = en ] && s="$root/skill-en/revref/hooks/usage.sh"
    export REVREF_USAGE_DIR="$tmp/$lang"

    REVREF_USAGE_DIR="$tmp/$lang-none" sh "$s" --read >/dev/null; code=$?
    [ "$code" -eq 1 ] && ok "[$lang] --read без данных: код 1" || bad "[$lang] --read без данных вернул $code"

    out=$(printf '%s' "$compact" | sh "$s")
    case "$out" in *41%*23%*) ok "[$lang] своя статусная строка: $out" ;; *) bad "[$lang] статусная строка: '$out'" ;; esac
    out=$(sh "$s" --read)
    case "$out" in *"week: 41.2%"*"5h: 23.5%"*"updated:"*) ok "[$lang] --read после сохранения" ;; *) bad "[$lang] --read: $out" ;; esac

    printf '{"model":{"display_name":"Opus"}}' | sh "$s" >/dev/null
    sh "$s" --read | grep -q "week: 41.2%" && ok "[$lang] JSON без rate_limits не затирает данные" || bad "[$lang] данные затёрты JSON без лимитов"

    printf '%s' "$pretty" | sh "$s" >/dev/null
    out=$(sh "$s" --read)
    case "$out" in *"week: expired"*) ok "[$lang] многострочный JSON, прошедший сброс — expired" ;; *) bad "[$lang] expired: $out" ;; esac

    printf 'echo "prev:$(cat | wc -c | tr -d " ")"\r\n' > "$REVREF_USAGE_DIR/statusline-next"
    out=$(printf '%s' "$compact" | sh "$s")
    case "$out" in prev:*) ok "[$lang] прежняя статусная строка (CRLF) получает тот же JSON" ;; *) bad "[$lang] цепочка: '$out'" ;; esac
    sh "$s" --read | grep -q "week: 41.2%" && ok "[$lang] в цепочке данные тоже сохраняются" || bad "[$lang] цепочка не сохранила данные"
    rm -f "$REVREF_USAGE_DIR/statusline-next"

    # Команда из PIPELINE.md → «Подключение»: JSON-строка, раскодированная так, как её прочитает Claude Code.
    pipeline="$(dirname "$s")/../PIPELINE.md"
    cmd=$(sed -n 's/^  "command": "\(.*\)"$/\1/p' "$pipeline" | head -1 | sed 's/\\"/"/g; s/\\\\/\\/g')
    [ -n "$cmd" ] || { bad "[$lang] нет команды статусной строки в PIPELINE.md"; continue; }
    skill_dir=$(cd "$(dirname "$s")/.." && pwd)
    cmd=$(printf '%s' "$cmd" | sed "s|<[^>]*>|$skill_dir|")
    crlf="$tmp/$lang-crlf"; mkdir -p "$crlf/hooks"; sed 's/$/\r/' "$s" > "$crlf/hooks/usage.sh"
    out=$(printf '%s' "$compact" | sh -c "$cmd")
    case "$out" in *41%*) ok "[$lang] команда для settings.json работает" ;; *) bad "[$lang] команда для settings.json: '$out' ($cmd)" ;; esac
    out=$(printf '%s' "$compact" | sh -c "$(printf '%s' "$cmd" | sed "s|$skill_dir|$crlf|")")
    case "$out" in *41%*) ok "[$lang] команда работает с CRLF-копией usage.sh" ;; *) bad "[$lang] CRLF-копия usage.sh: '$out'" ;; esac
done

[ "$fail" -eq 0 ] && echo "usage.sh: все проверки пройдены" || echo "usage.sh: есть ошибки"
exit "$fail"
