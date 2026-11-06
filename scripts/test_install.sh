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

# --- DSH: установка в DSH-корень, без агентов, с platform=dsh, и установка в проект ---
for lang in ru en; do
    dsh_home="$tmp/dsh-$lang"
    DSH_HOME="$dsh_home" sh "$root/install.sh" --dsh --lang "$lang" >/dev/null || { bad "[$lang] install.sh --dsh завершился с ошибкой"; continue; }
    skill="$dsh_home/skills/revref"
    [ -f "$skill/SKILL.md" ] && ok "[$lang] DSH: скилл установлен" || bad "[$lang] DSH: нет SKILL.md"
    [ -f "$skill/hooks/guard.ps1" ] && ok "[$lang] DSH: guard.ps1 на месте" || bad "[$lang] DSH: нет hooks/guard.ps1"
    [ ! -d "$dsh_home/agents" ] && ok "[$lang] DSH: агенты не устанавливаются" || bad "[$lang] DSH: появился каталог agents"
    grep -q '^platform=dsh$' "$skill/INSTALL" && ok "[$lang] DSH: INSTALL содержит platform=dsh" || bad "[$lang] DSH: INSTALL без platform"
    if grep -q '__REVREF_SKILL_DIR__' "$skill/SKILL.md"; then bad "[$lang] DSH: плейсхолдер не заменён"; else ok "[$lang] DSH: путь к хуку подставлен"; fi
    ( cd "$repo" && sh "$skill/hooks/guard.sh" --check 'git push --force' >/dev/null 2>&1; [ $? -eq 2 ] ) \
        && ok "[$lang] DSH: установленный guard блокирует force-push" || bad "[$lang] DSH: установленный guard не блокирует"
    DSH_HOME="$dsh_home" sh "$root/install.sh" --dsh --uninstall >/dev/null
    [ ! -d "$skill" ] && ok "[$lang] DSH: удаление" || bad "[$lang] DSH: удаление оставило файлы"
done
dsh_proj="$tmp/dsh proj"; mkdir -p "$dsh_proj"
sh "$root/install.sh" --dsh --project "$dsh_proj" >/dev/null 2>"$tmp/dsh-err" \
    && [ -f "$dsh_proj/.dsh/skills/revref/SKILL.md" ] \
    && ok "DSH: установка в проект (<путь>/.dsh/skills)" || bad "DSH: установка в проект: $(cat "$tmp/dsh-err")"

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
