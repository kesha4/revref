#!/bin/sh
# Установка RevRef для Claude Code — macOS, Linux, WSL, Git Bash на Windows.
#   ./install.sh                         — глобально: в $CLAUDE_CONFIG_DIR или ~/.claude (доступно во всех проектах)
#   ./install.sh --project <путь>        — только в указанный проект: <путь>/.claude
#   ./install.sh --uninstall [--project <путь>]  — удалить скилл и агентов RevRef
set -eu

src=$(cd "$(dirname "$0")" && pwd)
agents="revref-reviewer.md revref-verifier.md revref-fixer.md"
project=""
uninstall=0

while [ $# -gt 0 ]; do
    case "$1" in
        --project)
            [ $# -ge 2 ] || { echo "Не указан путь после --project" >&2; exit 1; }
            project=$2; shift 2 ;;
        --uninstall) uninstall=1; shift ;;
        -h|--help) sed -n '2,5p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "Неизвестный параметр: $1 (см. --help)" >&2; exit 1 ;;
    esac
done

if [ -n "$project" ]; then
    [ -d "$project" ] || { echo "Нет такой папки: $project" >&2; exit 1; }
    target="$(cd "$project" && pwd)/.claude"
elif [ -n "${CLAUDE_CONFIG_DIR:-}" ]; then
    target=$CLAUDE_CONFIG_DIR
else
    target="$HOME/.claude"
fi

skill_dst="$target/skills/revref"
agents_dst="$target/agents"

if [ "$uninstall" -eq 1 ]; then
    if [ -d "$skill_dst" ]; then
        rm -rf "$skill_dst"
        echo "Удалён скилл: $skill_dst"
    fi
    for name in $agents; do
        if [ -f "$agents_dst/$name" ]; then
            rm -f "$agents_dst/$name"
            echo "Удалён агент: $agents_dst/$name"
        fi
    done
    echo "RevRef удалён. Резервные копии *.bak-* (если есть) не тронуты."
    exit 0
fi

if [ -d "$skill_dst" ]; then
    backup="$skill_dst.bak-$(date +%Y%m%d-%H%M%S)"
    mv "$skill_dst" "$backup"
    echo "Предыдущая версия скилла сохранена: $backup"
fi

mkdir -p "$target/skills" "$agents_dst"
cp -R "$src/skill/revref" "$skill_dst"
for name in $agents; do
    cp "$src/agents/$name" "$agents_dst/$name"
done

echo "Скилл:   $skill_dst"
echo "Агенты:  $agents_dst (revref-reviewer, revref-verifier, revref-fixer)"
echo "Перезапустите сессию Claude Code и выполните в проекте: /revref init"
