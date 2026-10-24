#!/bin/sh
# Тест bin/update.sh: проверка версии, кэш, подготовка с журналом изменений, установка релиза с проверкой
# коммита, глобальная установка и установка в проект, отказ при подмене релиза. Источник — локальный репозиторий.
# Запуск: sh scripts/test_update.sh  (macOS, Linux, Git Bash на Windows).
set -u
root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d 2>/dev/null || mktemp -d -t revrefupd)
trap 'rm -rf "$tmp"' EXIT
fail=0
ok() { echo "ok   $1"; }
bad() { echo "FAIL $1"; fail=1; }

# Источник: копия набора в отдельном репозитории с релизом текущей версии и следующим релизом.
src="$tmp/src"; mkdir -p "$src"
(cd "$root" && tar cf - --exclude=.git .) | (cd "$src" && tar xf -)
cur=$(tr -d '\r\n' < "$src/skill/revref/VERSION")
next=$(echo "$cur" | awk -F. '{ printf "%d.%d.0", $1, $2 + 1 }')
git -C "$src" init -q -b main && git -C "$src" add -A 2>/dev/null && git -C "$src" commit -q -m base && git -C "$src" tag "v$cur"
git -C "$src" remote add origin "https://user:s3cret@example.invalid/revref.git"
for l in skill skill-en; do printf '%s\n' "$next" > "$src/$l/revref/VERSION"; done
for f in CHANGELOG.md CHANGELOG.en.md; do
    awk -v v="$next" 'done == 0 && /^## [0-9]/ { print "## " v " — test\n\n- test change " v "\n"; done = 1 } { print }' "$src/$f" > "$src/$f.new" && mv "$src/$f.new" "$src/$f"
done
git -C "$src" commit -q -am next 2>/dev/null && git -C "$src" tag "v$next"
sha=$(git -C "$src" rev-parse HEAD)
export REVREF_UPDATE_SOURCE="$src"

for lang in ru en; do
    cfg="$tmp/cfg-$lang"
    export CLAUDE_CONFIG_DIR="$cfg"
    git -C "$src" checkout -q "v$cur"
    sh "$src/install.sh" --lang "$lang" >/dev/null || { bad "[$lang] установка"; continue; }
    git -C "$src" checkout -q main
    skill="$cfg/skills/revref"; u="$skill/bin/update.sh"

    grep -q '^scope=global$' "$skill/INSTALL" && grep -q "^lang=$lang$" "$skill/INSTALL" \
        && ok "[$lang] INSTALL: глобальная установка, язык" || bad "[$lang] INSTALL: $(cat "$skill/INSTALL")"
    grep -q 's3cret' "$skill/INSTALL" && bad "[$lang] токен из URL источника попал в INSTALL" || ok "[$lang] логин и токен из URL источника не сохранены"

    out=$(sh "$u" --check --force)
    case "$out" in *"latest: $next"*"status: update-available"*) ok "[$lang] --check: доступна $next" ;; *) bad "[$lang] --check: $out" ;; esac
    [ -f "$cfg/revref/update-check" ] && ok "[$lang] результат проверки закэширован" || bad "[$lang] нет кэша проверки"
    sed 's/^latest=.*/latest=9.9.9/' "$cfg/revref/update-check" > "$tmp/cache" && cp "$tmp/cache" "$cfg/revref/update-check"
    out=$(sh "$u" --check)
    case "$out" in *"latest: 9.9.9"*) ok "[$lang] --check без --force берёт кэш" ;; *) bad "[$lang] кэш не использован: $out" ;; esac
    out=$(REVREF_UPDATE_SOURCE="$tmp/nowhere" sh "$u" --check)
    case "$out" in *"status: unknown"*) ok "[$lang] другой источник — кэш не используется, недоступность сообщается" ;; *) bad "[$lang] другой источник: $out" ;; esac
    sh "$u" --check --force >/dev/null
    out=$(REVREF_UPDATE_CHECK=off sh "$u" --check)
    case "$out" in *"check disabled"*) ok "[$lang] REVREF_UPDATE_CHECK=off" ;; *) bad "[$lang] отключение проверки: $out" ;; esac

    printf '3.0.1\n' > "$skill/VERSION"   # будто установлена старая версия
    out=$(sh "$u" --prepare)
    case "$out" in *"version: $next"*"commit: $sha"*"direction: upgrade"*"major: no"*"## $next"*"## $cur"*) ok "[$lang] --prepare: коммит и изменения новее установленной" ;; *) bad "[$lang] --prepare: $out" ;; esac
    case "$out" in *"## 3.0.0"*) bad "[$lang] --prepare показал записи старше установленной" ;; *) ok "[$lang] записи старше установленной не показаны" ;; esac
    sh "$u" --prepare v9.9 >/dev/null 2>&1 && bad "[$lang] неверный тег принят" || ok "[$lang] неверный тег отклонён"

    sh "$u" --apply "v$next" --expect 0000000 >/dev/null 2>&1
    [ "$(cat "$skill/VERSION")" = 3.0.1 ] && ok "[$lang] подменённый коммит — установка отклонена" || bad "[$lang] установка при несовпадении коммита"
    sh "$u" --apply "v$next" >/dev/null 2>&1 && bad "[$lang] --apply без --expect принят" || ok "[$lang] --apply без --expect отклонён"

    sh "$u" --apply "v$next" --expect "$sha" >"$tmp/apply.log" 2>&1 || bad "[$lang] --apply: $(cat "$tmp/apply.log")"
    [ "$(tr -d '\r\n' < "$skill/VERSION")" = "$next" ] && ok "[$lang] обновлено до $next" || bad "[$lang] версия после обновления: $(cat "$skill/VERSION")"
    grep -q "^lang=$lang$" "$skill/INSTALL" && grep -q '^scope=global$' "$skill/INSTALL" && ok "[$lang] параметры установки сохранены" || bad "[$lang] INSTALL после обновления"
    grep -q '__REVREF_SKILL_DIR__' "$skill/SKILL.md" "$cfg/agents/revref-fixer.md" && bad "[$lang] плейсхолдер после обновления" || ok "[$lang] путь к хуку подставлен"
    ls -d "$cfg/skills/revref.bak-"* >/dev/null 2>&1 && ok "[$lang] прежняя версия сохранена в .bak" || bad "[$lang] нет резервной копии"
    out=$(sh "$u" --check --force)
    case "$out" in *"status: up-to-date"*) ok "[$lang] после обновления — актуальна" ;; *) bad "[$lang] --check после обновления: $out" ;; esac
done
unset CLAUDE_CONFIG_DIR

# Установка в проект (путь с пробелом): обновление остаётся в проекте, глобальная папка не затрагивается.
proj="$tmp/my proj"; mkdir -p "$proj"; home_cfg="$tmp/home-cfg"
git -C "$src" checkout -q "v$cur"
sh "$src/install.sh" --project "$proj" >/dev/null
git -C "$src" checkout -q main
skill="$proj/.claude/skills/revref"
grep -q '^scope=project$' "$skill/INSTALL" && ok "INSTALL: установка в проект" || bad "INSTALL проекта: $(cat "$skill/INSTALL")"
CLAUDE_CONFIG_DIR="$home_cfg" sh "$skill/bin/update.sh" --apply "v$next" --expect "$sha" >"$tmp/apply.log" 2>&1 || bad "проект --apply: $(cat "$tmp/apply.log")"
[ "$(tr -d '\r\n' < "$skill/VERSION")" = "$next" ] && [ ! -d "$home_cfg/skills" ] \
    && ok "обновление в проекте; глобальная папка не тронута" || bad "обновление в проекте"

# Установка в проект, закоммиченная в git и склонированная в другую папку, обновляется в клоне, а не в исходной.
clone="$tmp/clone"; mkdir -p "$clone"; cp -R "$proj/.claude" "$clone/.claude"
rm -rf "$clone/.claude/skills/revref.bak-"*
printf '3.0.1\n' > "$clone/.claude/skills/revref/VERSION"
baks_before=$(ls -d "$proj/.claude/skills/revref.bak-"* 2>/dev/null | wc -l)
CLAUDE_CONFIG_DIR="$home_cfg" sh "$clone/.claude/skills/revref/bin/update.sh" --apply "v$next" --expect "$sha" >"$tmp/apply.log" 2>&1 || bad "клон --apply: $(cat "$tmp/apply.log")"
baks_after=$(ls -d "$proj/.claude/skills/revref.bak-"* 2>/dev/null | wc -l)
[ "$(tr -d '\r\n' < "$clone/.claude/skills/revref/VERSION")" = "$next" ] && [ "$baks_before" -eq "$baks_after" ] \
    && ls -d "$clone/.claude/skills/revref.bak-"* >/dev/null 2>&1 \
    && ok "клон установки в проект обновляется в клоне, исходная папка не тронута" || bad "клон обновил не ту папку"
[ -f "$skill/.gitattributes" ] && grep -q 'eol=lf' "$skill/.gitattributes" && ok ".gitattributes набора закрепляет LF для скриптов" || bad "нет .gitattributes в наборе"

# Неинтерактивный запуск без аргументов: показывает изменения и команду, но ничего не ставит.
printf '3.0.1\n' > "$skill/VERSION"
out=$(CLAUDE_CONFIG_DIR="$home_cfg" sh "$skill/bin/update.sh" </dev/null)
case "$out" in *"--apply v$next --expect $sha"*) ok "без терминала — только команда для обновления" ;; *) bad "без аргументов: $out" ;; esac
[ "$(cat "$skill/VERSION")" = 3.0.1 ] && ok "без подтверждения ничего не установлено" || bad "установлено без подтверждения"

[ "$fail" -eq 0 ] && echo "update.sh: все проверки пройдены" || echo "update.sh: есть ошибки"
exit "$fail"
