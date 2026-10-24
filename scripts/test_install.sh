#!/bin/sh
# Тест install.sh: установка обеих языковых версий, подстановка пути к хуку, работа хука, удаление.
# Запуск: sh scripts/test_install.sh  (macOS, Linux, Git Bash на Windows).
set -u
root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d 2>/dev/null || mktemp -d -t revrefinst)
trap 'rm -rf "$tmp"' EXIT
fail=0
ok() { echo "ok   $1"; }
bad() { echo "FAIL $1"; fail=1; }

# Репозиторий с активным прогоном — для проверки, что установленный хук срабатывает.
repo="$tmp/project"
mkdir -p "$repo/.revref"
git init -q -b main "$repo"
printf -- '- Тип чекпоинта: полный\n' > "$repo/.revref/STATE.md"
payload=$(printf '{"tool_name":"Bash","tool_input":{"command":"git push --force"},"cwd":"%s"}' "$repo")

for lang in ru en; do
    cfg="$tmp/cfg-$lang"
    src_skill="$root/skill/revref"; [ "$lang" = en ] && src_skill="$root/skill-en/revref"
    CLAUDE_CONFIG_DIR="$cfg" sh "$root/install.sh" --lang "$lang" >/dev/null || { bad "[$lang] install.sh завершился с ошибкой"; continue; }
    skill="$cfg/skills/revref"
    expected=$(( $(find "$src_skill" -type f | wc -l) + 2 ))   # + CHANGELOG.md, INSTALL
    actual=$(find "$skill" -type f | wc -l)
    [ "$actual" -eq "$expected" ] && ok "[$lang] файлов скилла: $actual" || bad "[$lang] файлов скилла $actual, ожидалось $expected"
    for f in "$skill/SKILL.md" "$cfg/agents/revref-reviewer.md" "$cfg/agents/revref-verifier.md" "$cfg/agents/revref-fixer.md"; do
        if grep -q '__REVREF_SKILL_DIR__' "$f"; then bad "[$lang] плейсхолдер не заменён: $f"; fi
        hook_cmd=$(sed -n "s/^ *command: '\(.*\)'\$/\1/p" "$f" | head -1)
        [ -n "$hook_cmd" ] || { bad "[$lang] нет команды хука в $f"; continue; }
        printf '%s' "$payload" | sh -c "$hook_cmd" >/dev/null 2>&1; code=$?
        [ "$code" -eq 2 ] && ok "[$lang] хук из $(basename "$f") блокирует force-push" || bad "[$lang] хук из $f вернул $code вместо 2"
    done
    # Хук должен работать и с CRLF-копией guard.sh (git с core.autocrlf=true перепишет её при checkout).
    sed 's/$/\r/' "$skill/hooks/guard.sh" > "$skill/hooks/guard.crlf" && mv "$skill/hooks/guard.crlf" "$skill/hooks/guard.sh"
    hook_cmd=$(sed -n "s/^ *command: '\(.*\)'\$/\1/p" "$skill/SKILL.md" | head -1)
    printf '%s' "$payload" | sh -c "$hook_cmd" >/dev/null 2>&1; code=$?
    [ "$code" -eq 2 ] && ok "[$lang] хук работает с CRLF-копией guard.sh" || bad "[$lang] CRLF-копия guard.sh: код $code вместо 2"
    [ -f "$skill/CHANGELOG.md" ] && [ -f "$skill/VERSION" ] && ok "[$lang] VERSION и CHANGELOG на месте" || bad "[$lang] нет VERSION или CHANGELOG"
    CLAUDE_CONFIG_DIR="$cfg" sh "$root/install.sh" --lang "$lang" >/dev/null && ls -d "$cfg/skills/revref.bak-"* >/dev/null 2>&1 \
        && ok "[$lang] переустановка сохранила резервную копию" || bad "[$lang] нет резервной копии при переустановке"
    CLAUDE_CONFIG_DIR="$cfg" sh "$root/install.sh" --uninstall >/dev/null
    { [ ! -d "$skill" ] && [ ! -f "$cfg/agents/revref-fixer.md" ]; } && ok "[$lang] удаление" || bad "[$lang] удаление оставило файлы"
done

proj="$tmp/proj dir"; mkdir -p "$proj"
if sh "$root/install.sh" --project "$proj" >/dev/null 2>"$tmp/err" && [ ! -s "$tmp/err" ] \
    && [ -f "$proj/.claude/skills/revref/SKILL.md" ] \
    && ! grep -q '__REVREF_SKILL_DIR__' "$proj/.claude/skills/revref/SKILL.md" "$proj/.claude/agents/"*.md; then
    ok "установка в проект (путь с пробелом), путь к хуку подставлен везде"
else
    bad "установка в проект с пробелом в пути: $(cat "$tmp/err")"
fi
sh "$root/install.sh" --lang xx >/dev/null 2>&1 && bad "неизвестный язык принят" || ok "неизвестный язык отклонён"

[ "$fail" -eq 0 ] && echo "install.sh: все проверки пройдены" || echo "install.sh: есть ошибки"
exit "$fail"
