#!/bin/sh
# Установка RevRef для Claude Code и DSH (DeepSeek Harness) — macOS, Linux, WSL, Git Bash на Windows.
#   ./install.sh                         — Claude Code, глобально: $CLAUDE_CONFIG_DIR или ~/.claude
#   ./install.sh --project <путь>        — Claude Code, только в проект: <путь>/.claude
#   ./install.sh --dsh [--project <путь>] — DSH: глобально ${DSH_HOME:-~/.dsh} или <путь>/.dsh
#   ./install.sh --uninstall [--project <путь>] [--dsh]  — удалить скилл (и агентов Claude Code)
#   ./install.sh --lang en               — английская версия набора (по умолчанию ru)
set -eu

src=$(cd "$(dirname "$0")" && pwd)
agents="revref-reviewer.md revref-verifier.md revref-fixer.md"
project=""
uninstall=0
lang=ru
platform=claude

while [ $# -gt 0 ]; do
    case "$1" in
        --project)
            [ $# -ge 2 ] || { echo "Не указан путь после --project" >&2; exit 1; }
            project=$2; shift 2 ;;
        --uninstall) uninstall=1; shift ;;
        --dsh) platform=dsh; shift ;;
        --lang)
            [ $# -ge 2 ] || { echo "Не указан язык после --lang (ru или en)" >&2; exit 1; }
            lang=$2; shift 2 ;;
        -h|--help) sed -n '2,7p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "Неизвестный параметр: $1 (см. --help)" >&2; exit 1 ;;
    esac
done

case "$lang" in
    ru) skill_src="$src/skill/revref"; agents_src="$src/agents"; changelog="$src/CHANGELOG.md" ;;
    en) skill_src="$src/skill-en/revref"; agents_src="$src/agents-en"; changelog="$src/CHANGELOG.en.md" ;;
    *) echo "Неизвестный язык: $lang (ru или en)" >&2; exit 1 ;;
esac

if [ "$platform" = dsh ]; then
    # DSH читает навыки из <папка конфигурации>/skills и <корень проекта>/.dsh/skills.
    # Именованных файлов агентов у DSH нет: роли передаются субагентам текстом из roles/.
    if [ -n "$project" ]; then
        [ -d "$project" ] || { echo "Нет такой папки: $project" >&2; exit 1; }
        target="$(cd "$project" && pwd)/.dsh"
    elif [ -n "${DSH_HOME:-}" ]; then
        target=$DSH_HOME
    else
        target="$HOME/.dsh"
    fi
    agents_dst=""
else
    if [ -n "$project" ]; then
        [ -d "$project" ] || { echo "Нет такой папки: $project" >&2; exit 1; }
        target="$(cd "$project" && pwd)/.claude"
    elif [ -n "${CLAUDE_CONFIG_DIR:-}" ]; then
        target=$CLAUDE_CONFIG_DIR
    else
        target="$HOME/.claude"
    fi
    agents_dst="$target/agents"
fi

skill_dst="$target/skills/revref"

if [ "$uninstall" -eq 1 ]; then
    if [ -d "$skill_dst" ]; then
        rm -rf "$skill_dst"
        echo "Удалён скилл: $skill_dst"
    fi
    if [ -n "$agents_dst" ]; then
        for name in $agents; do
            if [ -f "$agents_dst/$name" ]; then
                rm -f "$agents_dst/$name"
                echo "Удалён агент: $agents_dst/$name"
            fi
        done
    fi
    echo "RevRef удалён. Резервные копии *.bak-* (если есть) не тронуты."
    exit 0
fi

if [ -d "$skill_dst" ]; then
    backup="$skill_dst.bak-$(date +%Y%m%d-%H%M%S)"
    mv "$skill_dst" "$backup"
    echo "Предыдущая версия скилла сохранена: $backup"
fi

mkdir -p "$target/skills"
cp -R "$skill_src" "$skill_dst"
cp "$changelog" "$skill_dst/CHANGELOG.md"
if [ -n "$agents_dst" ]; then
    mkdir -p "$agents_dst"
    for name in $agents; do
        cp "$agents_src/$name" "$agents_dst/$name"
    done
fi

# Абсолютный путь к сторожевому хуку во frontmatter скилла и агентов.
esc=$(printf '%s' "$skill_dst" | sed 's/[&|\\]/\\&/g')
set_hook_path() {
    sed "s|__REVREF_SKILL_DIR__|$esc|g" "$1" > "$1.tmp"
    mv "$1.tmp" "$1"
}
set_hook_path "$skill_dst/SKILL.md"
if [ -n "$agents_dst" ]; then
    for name in $agents; do
        set_hook_path "$agents_dst/$name"
    done
fi

# Сведения для bin/update.sh: откуда и с какими параметрами установлен набор. Логин и токен из URL не сохраняются.
# Папки update.sh берёт из расположения набора: установка в проект переживает клонирование.
origin=""
command -v git >/dev/null 2>&1 && origin=$(git -C "$src" remote get-url origin 2>/dev/null | sed 's|://[^/@]*@|://|') || true
scope=global; [ -n "$project" ] && scope=project
cat > "$skill_dst/INSTALL" <<EOF
# RevRef: сведения об установке для bin/update.sh. Пишет установщик.
source=${origin:-https://github.com/kesha4/revref}
lang=$lang
scope=$scope
platform=$platform
installed_at=$(date '+%Y-%m-%d %H:%M')
EOF

echo "Скилл:   $skill_dst (язык: $lang, версия: $(cat "$skill_dst/VERSION"), платформа: $platform)"
if [ "$platform" = dsh ]; then
    echo "Агенты:  не устанавливаются: DSH сам управляет субагентами, роли — в $skill_dst/roles/"
    echo "Обновление: /revref update в DSH или sh \"$skill_dst/bin/update.sh\" в терминале"
    echo "Откройте новый сеанс DSH и выполните в проекте: /revref init"
else
    echo "Агенты:  $agents_dst (revref-reviewer, revref-verifier, revref-fixer)"
    echo "Обновление: /revref update в Claude Code или sh \"$skill_dst/bin/update.sh\" в терминале"
    echo "Перезапустите сессию Claude Code и выполните в проекте: /revref init"
fi
