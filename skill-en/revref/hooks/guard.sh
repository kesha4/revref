#!/bin/sh
# RevRef guard — Claude Code PreToolUse hook for the Bash and PowerShell tools.
# Сторожевой хук RevRef: активен, только пока в репозитории идёт прогон (есть .revref/STATE.md).
#
# Active only while a RevRef run exists in the repository (.revref/STATE.md). Blocks (exit 2, reason on
# stderr) dangerous git commands and committing secrets into .revref/:
#   - any change of the main branch (commit, merge, rebase, reset, cherry-pick, revert, am, pull on it);
#   - pushing the main branch, force-push, deleting remote branches;
#   - rebase, filter-branch / filter-repo (history rewriting);
#   - losing uncommitted work: git clean -f, git stash drop|clear, checkout/restore of the whole tree,
#     git reset --hard with uncommitted changes, git branch -D;
#   - secrets in the commit message and in added lines under .revref/ and docs/revref/.
# Messages follow the run language (CONFIG.md). Disable for a session: REVREF_GUARD=off.
# Requires POSIX sh, git, grep, sed, awk; jq is optional (more precise JSON parsing).

[ "${REVREF_GUARD:-on}" = "off" ] && exit 0

input=$(cat)

# --- tool_input.command and cwd from the hook JSON ---
if [ -z "${REVREF_GUARD_NOJQ:-}" ] && command -v jq >/dev/null 2>&1; then
    cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)
    cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)
else
    # Without jq: a JSON string is everything up to the first unescaped quote.
    cmd=$(printf '%s' "$input" | tr '\n' ' ' \
        | sed -nE 's/.*"command"[[:space:]]*:[[:space:]]*"(([^"\\]|\\.)*)".*/\1/p' | sed 's/\\"/"/g; s/\\\\/\\/g')
    cwd=$(printf '%s' "$input" | tr '\n' ' ' \
        | sed -nE 's/.*"cwd"[[:space:]]*:[[:space:]]*"(([^"\\]|\\.)*)".*/\1/p' | sed 's/\\\\/\//g')
fi
[ -z "$cmd" ] && exit 0

# Fast exit: only git commands matter.
case "$cmd" in *git*) ;; *) exit 0 ;; esac

# --- is a run active? (also from a worktree: look in the main working tree) ---
dir=${cwd:-${CLAUDE_PROJECT_DIR:-$PWD}}
[ -d "$dir" ] || dir=${CLAUDE_PROJECT_DIR:-$PWD}
top=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null) || exit 0
common=$(git -C "$dir" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
main_root=$(dirname "$common" 2>/dev/null)
state=""
for d in "$top" "$main_root"; do
    if [ -f "$d/.revref/STATE.md" ]; then state="$d/.revref"; break; fi
done
[ -z "$state" ] && exit 0

# --- main branch and language from CONFIG.md (ru/en); default: main ---
main_branch=$(grep -E '^- (Основная ветка|Main branch):' "$state/CONFIG.md" 2>/dev/null | head -1 \
    | sed 's/^[^:]*:[[:space:]]*//; s/[[:space:]].*$//' | tr -d '`')
[ -z "$main_branch" ] && main_branch=main
lang=ru
grep -Eq '^- (Main branch|Autonomy level|Report language):' "$state/CONFIG.md" 2>/dev/null && lang=en
current=$(git -C "$dir" symbolic-ref --short -q HEAD 2>/dev/null)

# deny "<ru reason>" "<en reason>"
deny() {
    if [ "$lang" = en ]; then
        echo "RevRef guard: command blocked — $2" >&2
        echo "Rules: POLICY.md of the RevRef kit (section \"Git\"). If this action is really needed, the owner does it manually." >&2
    else
        echo "RevRef guard: команда заблокирована — $1" >&2
        echo "Правила: POLICY.md набора RevRef (раздел «Git»). Если это действие действительно нужно, его выполняет владелец вручную." >&2
    fi
    exit 2
}

# Normalized command: spaces around, tabs and newlines → spaces.
c=" $(printf '%s' "$cmd" | tr '\t\n\r' '   ') "
has() { printf '%s' "$c" | grep -Eq -- "$1"; }
G='(^|[[:space:];&|(])git(([[:space:]]+-[Cc][[:space:]]+[^[:space:]]+)|([[:space:]]+--[a-z-]+(=[^[:space:]]+)?))*[[:space:]]+'
mb=$(printf '%s' "$main_branch" | sed 's/[.[\*^$/]/\\&/g')

# 1. Push: force, main branch, deleting remote branches.
if has "${G}push([[:space:]]|$)"; then
    has '[[:space:]](--force|--force-with-lease|--force-if-includes|-f)([[:space:]=]|$)' \
        && deny "force-push запрещён." "force-push is forbidden."
    has '[[:space:]]-[a-zA-Z]*f[a-zA-Z]*[[:space:]]' \
        && deny "force-push запрещён (флаг -f в связке)." "force-push is forbidden (-f in combined flags)."
    has '[[:space:]]\+[^[:space:]]+' \
        && deny "force-push через refspec с «+» запрещён." "force-push via a '+' refspec is forbidden."
    has '[[:space:]](--delete|-d)([[:space:]]|$)' \
        && deny "удаление удалённых веток запрещено." "deleting remote branches is forbidden."
    has '[[:space:]]:[^[:space:]]+' \
        && deny "удаление удалённой ветки через «:ветка» запрещено." "deleting a remote branch via ':branch' is forbidden."
    has "[[:space:]:/]${mb}([[:space:]]|\$)" \
        && deny "push основной ветки «$main_branch» запрещён: её обновляет владелец вручную." \
                "pushing the main branch '$main_branch' is forbidden: the owner updates it manually."
    if [ "$current" = "$main_branch" ]; then
        # No explicit branch ("git push" or "git push origin") pushes the current one — the main branch.
        nargs=$(printf '%s' "$c" | sed -n 's/.*[[:space:]]push\([[:space:]].*\)$/\1/p' | sed 's/[;&|].*$//' \
            | awk '{n = 0; for (i = 1; i <= NF; i++) if (substr($i, 1, 1) != "-") n++; print n}')
        [ "${nargs:-0}" -le 1 ] \
            && deny "push с основной ветки «$main_branch» без явной ветки отправит основную ветку." \
                    "push from the main branch '$main_branch' without an explicit branch would push the main branch."
    fi
fi

# 2. Changing the main branch.
MUT='(commit|merge|rebase|reset|cherry-pick|revert|am|pull)([[:space:]]|$)'
if has "${G}${MUT}"; then
    [ "$current" = "$main_branch" ] \
        && deny "текущая ветка — основная («$main_branch»); агент её не меняет." \
                "the current branch is the main branch ('$main_branch'); the agent never changes it."
    has "${G}(checkout|switch)[[:space:]]+${mb}([[:space:]]|\$)" \
        && deny "переключение на основную ветку «$main_branch» с последующим изменением запрещено." \
                "switching to the main branch '$main_branch' and then changing it is forbidden."
fi

# 3. Rewriting history.
if has "${G}rebase([[:space:]]|$)"; then
    has '[[:space:]]--(abort|quit)([[:space:]]|$)' \
        || deny "rebase запрещён: синхронизация только через merge." "rebase is forbidden: sync only via merge."
fi
has "${G}filter-(branch|repo)([[:space:]]|$)" \
    && deny "переписывание истории (filter-branch/filter-repo) запрещено." "rewriting history (filter-branch/filter-repo) is forbidden."

# 4. Losing uncommitted work.
has "${G}clean([[:space:]]|$)" && has '[[:space:]]-[a-zA-Z]*f' \
    && deny "git clean -f удаляет неотслеживаемые файлы, которые могут быть чужими." \
            "git clean -f deletes untracked files that may belong to someone else."
has "${G}stash[[:space:]]+(drop|clear)([[:space:]]|$)" \
    && deny "удаление stash запрещено." "dropping stashes is forbidden."
has "${G}branch([[:space:]].*)?[[:space:]](-D|--delete[[:space:]]+--force|--force[[:space:]]+--delete|-[a-zA-Z]*D[a-zA-Z]*)([[:space:]]|$)" \
    && deny "принудительное удаление ветки (-D) запрещено; используйте git branch -d." \
            "force-deleting a branch (-D) is forbidden; use git branch -d."
has "${G}(checkout([[:space:]]+--)?|restore([[:space:]]+--worktree)?)[[:space:]]+\.([[:space:]]|$)" \
    && deny "откат всего рабочего дерева уничтожит незакоммиченные изменения; откатывайте конкретные файлы." \
            "reverting the whole working tree destroys uncommitted changes; revert specific files."
if has "${G}reset([[:space:]].*)?[[:space:]]--hard([[:space:]]|$)"; then
    [ -n "$(git -C "$dir" status --porcelain 2>/dev/null)" ] \
        && deny "git reset --hard при незакоммиченных изменениях уничтожит их." \
                "git reset --hard with uncommitted changes would destroy them."
fi

# 5. Secrets: in the commit command (message) and in added lines under .revref/ and docs/revref/.
SECRETS='AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----|gh[pousr]_[A-Za-z0-9]{36,}|github_pat_[A-Za-z0-9_]{50,}|xox[baprs]-[A-Za-z0-9-]{10,}|sk-[A-Za-z0-9_-]{20,}|sk_(live|test)_[A-Za-z0-9]{16,}|AIza[0-9A-Za-z_-]{35}|eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}|(password|passwd|pwd|secret|token|api[_-]?key|access[_-]?key)["'"'"']?[[:space:]]*[:=][[:space:]]*["'"'"']?[A-Za-z0-9+/=_.-]{12,}'
if has "${G}commit([[:space:]]|$)"; then
    printf '%s' "$cmd" | grep -Eiq -- "$SECRETS" \
        && deny "в команде коммита (сообщении) похоже на секрет; замаскируйте его (sk-l…9f)." \
                "the commit command (message) looks like it contains a secret; mask it (sk-l…9f)."
    leaked=$(git -C "$dir" diff --cached -U0 -- .revref docs/revref 2>/dev/null | grep '^+' | grep -v '^+++' \
        | grep -v -F '…' | grep -v -F '<скрыто>' | grep -v -F '<hidden>' | grep -Ei -- "$SECRETS" | head -3)
    if [ -n "$leaked" ]; then
        files=$(git -C "$dir" diff --cached --name-only -- .revref docs/revref 2>/dev/null | tr '\n' ' ')
        deny "в добавляемых строках .revref/ или docs/revref/ похоже на секрет (файлы: $files). Замаскируйте значение: первые 4 символа, «…», последние 2 — и повторите коммит." \
             "added lines under .revref/ or docs/revref/ look like they contain a secret (files: $files). Mask the value: first 4 characters, '…', last 2 — and commit again."
    fi
fi

exit 0
