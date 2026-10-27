#!/bin/sh
# Тесты сторожевого хука skill/revref/hooks/guard.sh.
# Запуск: sh scripts/test_guard.sh  (macOS, Linux, Git Bash на Windows). Код возврата 0 — все тесты прошли.
set -u

root=$(cd "$(dirname "$0")/.." && pwd)
guard="$root/skill/revref/hooks/guard.sh"
tmp=$(mktemp -d 2>/dev/null || mktemp -d -t revrefguard)
trap 'rm -rf "$tmp"' EXIT
pass=0; fail=0

json_escape() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }

# check <ожидаемый код: 0 — разрешено, 2 — заблокировано> <каталог> <команда> [имя инструмента]
check() {
    expect=$1; dir=$2; cmd=$3; tool=${4:-Bash}
    payload=$(printf '{"session_id":"t","tool_name":"%s","tool_input":{"command":"%s"},"cwd":"%s"}' \
        "$tool" "$(json_escape "$cmd")" "$(json_escape "$dir")")
    for mode in jq nojq; do
        if [ "$mode" = nojq ]; then
            out=$(printf '%s' "$payload" | REVREF_GUARD_NOJQ=1 sh "$guard" 2>&1); code=$?
        else
            command -v jq >/dev/null 2>&1 || continue
            out=$(printf '%s' "$payload" | sh "$guard" 2>&1); code=$?
        fi
        if [ "$code" = "$expect" ]; then
            pass=$((pass + 1))
        else
            fail=$((fail + 1))
            echo "FAIL [$mode] ожидалось $expect, получено $code: $cmd"
            [ -n "$out" ] && echo "     $out"
        fi
    done
}

g() { git -C "$repo" "$@" >/dev/null 2>&1; }

# --- репозиторий с активным прогоном ---
repo="$tmp/project"
mkdir -p "$repo/.revref/reports" "$repo/src"
git init -q -b main "$repo"
g config user.email t@example.com; g config user.name t
printf -- '- Тип чекпоинта: полный\n' > "$repo/.revref/STATE.md"
printf -- '- Основная ветка: main                     <!-- база -->\n' > "$repo/.revref/CONFIG.md"
echo 'print(1)' > "$repo/src/a.py"
g add -A; g commit -m init
g branch test
g checkout -b revref/2026-10-13

# На ветке прогона: разрешено
check 0 "$repo" 'git status'
check 0 "$repo" 'ls -f'
check 0 "$repo" 'git commit -m "revref(W2): W2-T01 fix rounding"'
check 0 "$repo" 'git merge --no-ff revref/task/W2-T01'
check 0 "$repo" 'git push origin revref/2026-10-13'
check 0 "$repo" 'git push origin test'
check 0 "$repo" 'git branch -d revref/task/W2-T01'
check 0 "$repo" 'git reset --hard HEAD~1'
check 0 "$repo" 'git checkout -- src/a.py'
check 0 "$repo" 'git rebase --abort'
check 0 "$repo" 'git push --follow-tags origin revref/2026-10-13'
check 0 "$repo" 'git log --oneline main..HEAD'
check 0 "$repo" 'git status' PowerShell
# Архивирование прогона (PROTOCOLS.md §12): переименование веток, тег, перенос .revref/ — разрешены.
check 0 "$repo" 'git branch -m revref/2026-10-13 revref/archive/2026-10-13/run'
check 0 "$repo" 'git branch -m revref/pending/D-001 revref/archive/2026-10-13/pending/D-001'
check 0 "$repo" 'git tag revref/2026-10-13/archived'
check 0 "$repo" 'git mv .revref/STATE.md .revref/archive/2026-10-13/STATE.md'
check 2 "$repo" "git for-each-ref --format='%(refname:short)' refs/heads/revref/archive/2026-10-13/ | xargs git branch -D"
# Путь в стиле Windows (C:\...), как его передаёт Claude Code на Windows
if command -v cygpath >/dev/null 2>&1; then
    check 2 "$(cygpath -w "$repo")" 'git push --force'
    check 0 "$(cygpath -w "$repo")" 'git status'
fi

# На ветке прогона: заблокировано
check 2 "$repo" 'git push --force origin revref/2026-10-13'
check 2 "$repo" 'git push -f'
check 2 "$repo" 'git push -uf origin revref/2026-10-13'
check 2 "$repo" 'git push --force-with-lease'
check 2 "$repo" 'git push origin +revref/2026-10-13'
check 2 "$repo" 'git push origin main'
check 2 "$repo" 'git push origin HEAD:main'
check 2 "$repo" 'git push origin --delete test'
check 2 "$repo" 'git push origin :test'
check 2 "$repo" 'git rebase main'
check 2 "$repo" 'git filter-branch --tree-filter true HEAD'
check 2 "$repo" 'git clean -fd'
check 2 "$repo" 'git stash drop'
check 2 "$repo" 'git branch -D revref/task/W2-T01'
check 2 "$repo" 'git checkout -- .'
check 2 "$repo" 'git restore .'
check 2 "$repo" 'git checkout main && git commit -m x'
check 2 "$repo" 'git -C /some/path push --force'
check 2 "$repo" 'git -c core.editor=true push --force'
check 2 "$repo" 'git commit -m "add key sk-abcdefghijklmnopqrstuvwx1234"'
check 2 "$repo" 'git push --force' PowerShell

# Грязное дерево: reset --hard заблокирован
echo 'print(2)' > "$repo/src/a.py"
check 2 "$repo" 'git reset --hard'
g checkout -- src/a.py

# Секрет в добавляемых строках .revref/ — коммит заблокирован; замаскированный — разрешён
printf 'Ключ: AKIAABCDEFGHIJKLMNOP в src/a.py:1\n' > "$repo/.revref/reports/SEC.md"
g add .revref/reports/SEC.md
check 2 "$repo" 'git commit -m "revref(state): отчёт SEC"'
printf 'Ключ: AKIA…OP в src/a.py:1\n' > "$repo/.revref/reports/SEC.md"
g add .revref/reports/SEC.md
check 0 "$repo" 'git commit -m "revref(state): отчёт SEC"'
printf -- '- api_key = "Zx9fQ2pLm8RtYv4K"\n' > "$repo/.revref/reports/SEC.md"
g add .revref/reports/SEC.md
check 2 "$repo" 'git commit -m "revref(state): отчёт SEC"'
g reset -q HEAD .revref/reports/SEC.md; rm -f "$repo/.revref/reports/SEC.md"

# На основной ветке: изменения заблокированы, чтение разрешено
g checkout main
check 2 "$repo" 'git commit -m x'
check 2 "$repo" 'git merge revref/2026-10-13'
check 2 "$repo" 'git pull'
check 2 "$repo" 'git push'
check 2 "$repo" 'git push origin'
check 0 "$repo" 'git push origin revref/2026-10-13'
check 0 "$repo" 'git fetch'
check 0 "$repo" 'git log -1'
g checkout revref/2026-10-13

# Отключение переменной окружения
payload='{"tool_name":"Bash","tool_input":{"command":"git push --force"},"cwd":"'"$(json_escape "$repo")"'"}'
if printf '%s' "$payload" | REVREF_GUARD=off sh "$guard" >/dev/null 2>&1; then pass=$((pass + 1)); else fail=$((fail + 1)); echo "FAIL REVREF_GUARD=off не отключил хук"; fi

# --- worktree: .revref/ не закоммичен, есть только в основном каталоге — хук всё равно активен ---
repo2="$tmp/project2"
mkdir -p "$repo2/.revref"
git init -q -b main "$repo2"
git -C "$repo2" config user.email t@example.com; git -C "$repo2" config user.name t
echo x > "$repo2/f.txt"; git -C "$repo2" add f.txt; git -C "$repo2" commit -qm init
printf -- '- Тип чекпоинта: полный\n' > "$repo2/.revref/STATE.md"
git -C "$repo2" worktree add -q -b revref/task/T1 "$tmp/wt" 2>/dev/null
check 2 "$tmp/wt" 'git push --force'
check 0 "$tmp/wt" 'git commit -m ok'

# --- английский CONFIG.md с другой основной веткой ---
repo4="$tmp/project-en"
mkdir -p "$repo4/.revref"
git init -q -b develop "$repo4"
printf -- '- Checkpoint type: full\n' > "$repo4/.revref/STATE.md"
printf -- '- Main branch: develop                  <!-- base -->\n' > "$repo4/.revref/CONFIG.md"
check 2 "$repo4" 'git push origin develop'
check 0 "$repo4" 'git push origin main'
check 2 "$repo4" 'git commit -m x'
en_msg=$(printf '{"tool_name":"Bash","tool_input":{"command":"git push -f"},"cwd":"%s"}' "$(json_escape "$repo4")" \
    | REVREF_GUARD_NOJQ=1 sh "$guard" 2>&1)
case "$en_msg" in *"command blocked"*) pass=$((pass + 1)) ;; *) fail=$((fail + 1)); echo "FAIL сообщение не на английском: $en_msg" ;; esac

# --- репозиторий без прогона: хук не вмешивается ---
repo3="$tmp/plain"
git init -q -b main "$repo3"
check 0 "$repo3" 'git push --force'
check 0 "$repo3" 'git commit -m x'

echo "guard: пройдено $pass, ошибок $fail"
[ "$fail" -eq 0 ]
