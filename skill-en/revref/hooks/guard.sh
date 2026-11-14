#!/bin/sh
# RevRef guard — Claude Code PreToolUse hook for the Bash and PowerShell tools.
# Сторожевой хук RevRef: активен, только пока в репозитории идёт прогон (есть .revref/STATE.md).
#
# Active only while a RevRef run exists in the repository (.revref/STATE.md). Blocks (exit 2, reason on
# stderr) dangerous git commands and committing secrets into .revref/:
#   - any change of the main branch (commit, merge, rebase, reset, cherry-pick, revert, am, pull on it);
#   - pushing the main branch (also --all / --mirror), force-push, deleting remote branches;
#     Exception: merging the result into the main branch and pushing the main branch (an explicitly named
#     ref, e.g. HEAD:main) are allowed only with a fresh .revref/FINISH_CONSENT marker
#     (target=…, action=merge|push, at most 60 minutes old), which the agent writes after the owner's
#     explicit "yes" (PROTOCOLS.md §9); force-push, --delete, --all / --mirror, reset, revert, pull and
#     the rest stay blocked;
#   - rebase, filter-branch / filter-repo (history rewriting);
#   - losing uncommitted work: git clean -f, git stash drop|clear, checkout/restore of the whole tree,
#     git reset --hard with uncommitted changes, git branch -D;
#   - secrets in the commit message and in added lines under .revref/ and docs/revref/.
# The command is split into segments (;, &&, ||, |, newlines, subshells; quotes respected; heredoc and
# PowerShell here-string bodies skipped). Each git call is checked in the folder where it really runs:
# `cd <path>` / Set-Location before it, `git -C <path>`, simple variables (wt=..., $wt = '...'),
# so a worktree of a task or of the run branch is judged by its own branch, not by the session folder.
# Messages follow the run language (CONFIG.md). Disable for a session: REVREF_GUARD=off.
# Requires POSIX sh, git, grep, sed, awk; jq is optional (more precise JSON parsing).

[ "${REVREF_GUARD:-on}" = "off" ] && exit 0

# Two entry points:
#   hook  — Claude Code PreToolUse: JSON on stdin ({tool_input:{command},cwd});
#   --check "<command>" [cwd] — manual pre-flight check for platforms without tool hooks (DSH) and for any
#           shell: exit 0 — allowed, exit 2 — blocked with the reason on stderr. Use it before running a
#           git command that POLICY.md → «Git» protects; cwd defaults to the current folder.
#   --check-env [cwd] — the same, but the command comes from $REVREF_CHECK_COMMAND (no shell quoting);
#           used by hooks/guard.ps1 on Windows.
if [ "${1:-}" = "--check" ]; then
    [ $# -ge 2 ] || { echo "guard.sh: usage: guard.sh --check <command> [cwd]" >&2; exit 2; }
    cmd=$2
    cwd=${3:-$PWD}
elif [ "${1:-}" = "--check-env" ]; then
    cmd=${REVREF_CHECK_COMMAND:-}
    cwd=${2:-$PWD}
else
    input=$(cat)

    # --- tool_input.command and cwd from the hook JSON ---
    if [ -z "${REVREF_GUARD_NOJQ:-}" ] && command -v jq >/dev/null 2>&1; then
        cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)
        cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)
    else
        # Without jq: a JSON string is everything up to the first unescaped quote.
        cmd=$(printf '%s' "$input" | tr '\n' ' ' \
            | sed -nE 's/.*"command"[[:space:]]*:[[:space:]]*"(([^"\\]|\\.)*)".*/\1/p' \
            | awk '{ s = $0; L = length(s); out = ""
                for (i = 1; i <= L; i++) {
                    ch = substr(s, i, 1)
                    if (ch == "\\" && i < L) {
                        i++; ch = substr(s, i, 1)
                        if (ch == "n") ch = "\n"; else if (ch == "t") ch = "\t"; else if (ch == "r") ch = "\r"; else if (ch == "u") ch = "\\u"
                    }
                    out = out ch
                }
                printf "%s", out }')
        cwd=$(printf '%s' "$input" | tr '\n' ' ' \
            | sed -nE 's/.*"cwd"[[:space:]]*:[[:space:]]*"(([^"\\]|\\.)*)".*/\1/p' | sed 's/\\\\/\//g')
    fi
fi
[ -z "$cmd" ] && exit 0

# Fast exit: only git commands matter.
case "$cmd" in *git*) ;; *) exit 0 ;; esac

base=${cwd:-${CLAUDE_PROJECT_DIR:-$PWD}}
[ -d "$base" ] || base=${CLAUDE_PROJECT_DIR:-$PWD}

# --- split into segments; one line per cd and per git call (fields separated by TAB) ---
#   CD  <path or ?>
#   GIT <-C / --work-tree path or .> <subcommand> <arguments separated by \037>
PARSE='
function subst(p,   name, v) {
    while (match(p, /\$\{?[A-Za-z_][A-Za-z0-9_]*\}?/)) {
        name = substr(p, RSTART, RLENGTH); gsub(/[${}]/, "", name)
        if (!(name in vars)) return "?"
        p = substr(p, 1, RSTART - 1) vars[name] substr(p, RSTART + RLENGTH)
    }
    return p
}
function flush_tok() { if (intok) { toks[++n] = tok; tok = ""; intok = 0 } }
function seg_end(   i, k, p, sb, args, cpath, low, prev, m, nest) {
    flush_tok()
    if (n == 0) return
    k = 1
    while (k <= n && toks[k] ~ /^[A-Za-z_][A-Za-z0-9_]*=/) {
        p = index(toks[k], "="); vars[substr(toks[k], 1, p - 1)] = substr(toks[k], p + 1); k++
    }
    if (k + 1 <= n && toks[k] ~ /^\$[A-Za-z_][A-Za-z0-9_]*$/ && toks[k + 1] == "=") {
        vars[substr(toks[k], 2)] = (k + 2 <= n) ? toks[k + 2] : ""
        n = 0; return
    }
    if (k > n) { n = 0; return }
    low = tolower(toks[k])
    if (low == "cd" || low == "pushd" || low == "chdir" || low == "set-location" || low == "push-location" || low == "sl") {
        p = ""
        for (i = k + 1; i <= n; i++) {
            if (tolower(toks[i]) == "-path" || tolower(toks[i]) == "-literalpath") { p = toks[i + 1]; break }
            if (substr(toks[i], 1, 1) != "-") { p = toks[i]; break }
        }
        if (p == "") p = "~"
        print "CD\t" subst(p)
    } else if (low == "popd" || low == "pop-location") {
        print "CD\t?"
    }
    for (i = k; i <= n; i++) {
        low = tolower(toks[i]); sub(/.*[\/\\]/, "", low)
        if (low == "git" || low == "git.exe") break
    }
    if (i <= n) {
        cpath = ""; i++
        while (i <= n && substr(toks[i], 1, 1) == "-") {
            if (toks[i] == "-C" && i < n) { cpath = (cpath == "" ? toks[i + 1] : cpath "/" toks[i + 1]); i += 2; continue }
            if (toks[i] ~ /^--work-tree=/) { cpath = substr(toks[i], 13); i++; continue }
            if ((toks[i] == "-c" || toks[i] == "--work-tree" || toks[i] == "--git-dir" || toks[i] == "--namespace") && i < n) {
                if (toks[i] == "--work-tree") cpath = toks[i + 1]
                i += 2; continue
            }
            i++
        }
        sb = (i <= n) ? toks[i] : ""
        args = ""
        for (i = i + 1; i <= n; i++) args = args (args == "" ? "" : "\037") toks[i]
        print "GIT\t" (cpath == "" ? "." : subst(cpath)) "\t" sb "\t" args
    }
    # Nested commands: bash -c "…", powershell -Command "…", eval "…", "$(…)" inside quotes.
    m = 0
    for (i = k; i <= n; i++) {
        prev = (i > 1) ? toks[i - 1] : ""
        if (toks[i] !~ /(^|[^A-Za-z0-9_.-])git([^A-Za-z0-9_-]|$)/) continue
        if (prev ~ /^-[A-Za-z]*c$/ || tolower(prev) == "-command" || tolower(prev) == "/c" || tolower(toks[k]) == "eval" \
            || toks[i] ~ /\$\(|`/) nest[++m] = toks[i]
    }
    n = 0
    for (i = 1; i <= m; i++) parse(nest[i])
}
function parse(s,   i, L, ch, q) {
    q = ""; L = length(s)
    for (i = 1; i <= L; i++) {
        ch = substr(s, i, 1)
        if (q == "\047") { if (ch == "\047") q = ""; else tok = tok ch; continue }
        if (q == "\"") {
            if (ch == "\\" && substr(s, i + 1, 1) == "\"") { tok = tok "\""; i++; continue }
            if (ch == "\"") q = ""; else tok = tok ch
            continue
        }
        if (ch == "\047" || ch == "\"") { q = ch; intok = 1; continue }
        if (ch == " " || ch == "\t" || ch == "\r") { flush_tok(); continue }
        if (index(";&|(){}`\n", ch)) { seg_end(); continue }
        tok = tok ch; intok = 1
    }
    seg_end()
}
{
    line = $0; sub(/\r$/, "", line)
    if (skip != "") {
        t = line; gsub(/^[ \t]+|[ \t]+$/, "", t)
        if (skip == "@" && t ~ /^[\047"]@/) { skip = ""; text = text substr(t, 3) "\n" }
        else if (t == skip) skip = ""
        next
    }
    if (line ~ /@[\047"][ \t]*$/) { sub(/@[\047"][ \t]*$/, "HERESTRING", line); text = text line "\n"; skip = "@"; next }
    if (match(line, /<<-?[ \t]*[\047"]?[A-Za-z_][A-Za-z0-9_]*[\047"]?/)) {
        skip = substr(line, RSTART, RLENGTH); sub(/^<<-?[ \t]*/, "", skip); gsub(/[\047"]/, "", skip)
    }
    text = text line "\n"
}
END { parse(text) }
'
segs=$(printf '%s\n' "$cmd" | awk "$PARSE" 2>/dev/null)
[ -n "$segs" ] || exit 0

resolve() {   # resolve <base> <path> → existing folder or "?"
    p=$(printf '%s' "$2" | tr '\\' '/')
    case "$p" in "?"|*'$'*) echo "?"; return ;; "~") p=$HOME ;; "~/"*) p="$HOME/${p#\~/}" ;; esac
    [ "$1" = "?" ] && case "$p" in /*|[A-Za-z]:/*|[A-Za-z]:) ;; *) echo "?"; return ;; esac
    case "$p" in /*|[A-Za-z]:/*|[A-Za-z]:) r=$p ;; .) r=$1 ;; *) r="$1/$p" ;; esac
    if [ -d "$r" ]; then printf '%s\n' "$r"; else echo "?"; fi
}

# --- pass 1: the folder of every git call; find an active run ---
TAB=$(printf '\t')
plan=""; d=$base
while IFS= read -r line; do
    case "$line" in
        "CD$TAB"*) d=$(resolve "$d" "${line#CD$TAB}") ;;
        "GIT$TAB"*)
            rest=${line#GIT$TAB}; cpath=${rest%%"$TAB"*}; rest=${rest#*"$TAB"}
            gd=$(resolve "$d" "$cpath")
            plan="$plan$gd$TAB$rest
" ;;
    esac
done <<EOF
$segs
EOF
[ -n "$plan" ] || exit 0

state=""
# .revref of this worktree, of the main working tree (a worktree may not have it committed) or of any other
# worktree of the repository: a run kept in a separate worktree still protects the main branch in the main folder.
find_state() {
    [ "$1" = "?" ] && return 1
    top=$(git -C "$1" rev-parse --show-toplevel 2>/dev/null) || return 1
    common=$(git -C "$1" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
    for s in "$top" "$(dirname "$common" 2>/dev/null)" \
        $(git -C "$1" worktree list --porcelain 2>/dev/null | sed -n 's/^worktree //p' | tr ' ' '\001'); do
        s=$(printf '%s' "$s" | tr '\001' ' ')
        if [ -f "$s/.revref/STATE.md" ]; then state="$s/.revref"; return 0; fi
    done
    return 1
}
find_state "$base" || while IFS="$TAB" read -r gd _rest; do
    find_state "$gd" && break
done <<EOF
$plan
EOF
[ -z "$state" ] && exit 0

# --- main branch and language from CONFIG.md (ru/en); default: main ---
main_branch=$(grep -E '^- (Основная ветка|Main branch):' "$state/CONFIG.md" 2>/dev/null | head -1 \
    | sed 's/^[^:]*:[[:space:]]*//; s/[[:space:]].*$//' | tr -d '`')
[ -z "$main_branch" ] && main_branch=main
lang=ru
grep -Eq '^- (Main branch|Autonomy level|Report language):' "$state/CONFIG.md" 2>/dev/null && lang=en

# --- finish consent marker: .revref/FINISH_CONSENT, fail closed ---
# Written by the orchestrator only right after the owner's explicit "yes" in finish (PROTOCOLS.md §9),
# lives for one step and is removed after it. Format: exactly two lines, target=<main branch> and
# action=merge|push. Accepted only when the file exists, is not older than 60 minutes and target matches
# the main branch from CONFIG.md; no find / no marker / stale / target mismatch — no consent.
consent_target=""; consent_action=""
consent="$state/FINISH_CONSENT"
if [ -f "$consent" ] && [ -n "$(find "$consent" -mmin -60 2>/dev/null)" ]; then
    consent_target=$(sed -n 's/^target=//p' "$consent" 2>/dev/null | head -1 | tr -d '` \r')
    consent_action=$(sed -n 's/^action=//p' "$consent" 2>/dev/null | head -1 | tr -d '` \r')
    [ "$consent_target" = "$main_branch" ] || { consent_target=""; consent_action=""; }
fi

# deny "<ru reason>" "<en reason>"
deny() {
    if [ "$lang" = en ]; then
        echo "RevRef guard: command blocked — $2" >&2
        echo "Rules: POLICY.md of the RevRef kit (section \"Git\"). Do not work around the block with another shell or REVREF_GUARD=off; if this action is really needed, the owner does it manually." >&2
    else
        echo "RevRef guard: команда заблокирована — $1" >&2
        echo "Правила: POLICY.md набора RevRef (раздел «Git»). Не обходите блокировку другой оболочкой или REVREF_GUARD=off; если это действие действительно нужно, его выполняет владелец вручную." >&2
    fi
    exit 2
}

US=$(printf '\037')
has_arg() { case "$US$args$US" in *"$US$1$US"*) return 0 ;; esac; return 1; }
# Short-flag clusters (-uf, -fd) containing the letter $1.
has_short() { printf '%s' "$args" | tr "$US" '\n' | grep -Eq -- "^-[A-Za-z]*$1[A-Za-z]*\$"; }
positional() { printf '%s' "$args" | tr "$US" '\n' | grep -v -- '^-' | grep -v '^$'; }

switched=""   # folder where the command switched to the main branch
while IFS="$TAB" read -r gd sb args; do
    [ -n "$sb" ] || continue
    known=1; where=$gd
    if [ "$gd" = "?" ]; then known=0; where=$base; fi
    current=$(git -C "$where" symbolic-ref --short -q HEAD 2>/dev/null)
    on_main=0
    { [ "$current" = "$main_branch" ] || [ "$switched" = "$where" ]; } && on_main=1

    case "$sb" in
    checkout|switch)
        has_arg "$main_branch" && switched=$where
        if [ "$sb" = checkout ] && has_arg "."; then
            deny "откат всего рабочего дерева уничтожит незакоммиченные изменения; откатывайте конкретные файлы." \
                 "reverting the whole working tree destroys uncommitted changes; revert specific files."
        fi ;;
    restore)
        if has_arg "." && { ! has_arg --staged || has_arg --worktree || has_short W; }; then
            deny "откат всего рабочего дерева уничтожит незакоммиченные изменения; откатывайте конкретные файлы." \
                 "reverting the whole working tree destroys uncommitted changes; revert specific files."
        fi ;;
    push)
        { has_arg --force || has_arg --force-if-includes || has_short f \
            || printf '%s' "$args" | tr "$US" '\n' | grep -q -- '^--force-with-lease'; } \
            && deny "force-push запрещён." "force-push is forbidden."
        { has_arg --delete || has_short d; } && deny "удаление удалённых веток запрещено." "deleting remote branches is forbidden."
        { has_arg --all || has_arg --mirror; } \
            && deny "push --all / --mirror отправит и основную ветку «$main_branch»." \
                    "push --all / --mirror would push the main branch '$main_branch' too."
        refs=$(positional | sed 1d)
        set -f
        for r in $refs; do
            case "$r" in
                +*) deny "force-push через refspec с «+» запрещён." "force-push via a '+' refspec is forbidden." ;;
                :*) deny "удаление удалённой ветки через «:ветка» запрещено." "deleting a remote branch via ':branch' is forbidden." ;;
            esac
            dst=${r##*:}; dst=${dst#refs/heads/}
            [ "$r" = HEAD ] && [ "$on_main" = 1 ] && dst=$main_branch
            [ "$dst" = "$main_branch" ] && [ "$consent_action" != push ] \
                && deny "push основной ветки «$main_branch» запрещён: её обновляет владелец вручную (исключение — слияние и push, которые владелец выбрал в finish: маркер .revref/FINISH_CONSENT, PROTOCOLS.md §9)." \
                        "pushing the main branch '$main_branch' is forbidden: the owner updates it manually (exception: the merge and push the owner chose in finish: the .revref/FINISH_CONSENT marker, PROTOCOLS.md §9)."
        done
        if [ -z "$refs" ] && [ "$on_main" = 1 ]; then
            deny "push с основной ветки «$main_branch» без явной ветки отправит основную ветку (папка: $where)." \
                 "push from the main branch '$main_branch' without an explicit branch would push the main branch (folder: $where)."
        fi ;;
    rebase)
        { has_arg --abort || has_arg --quit; } || deny "rebase запрещён: синхронизация только через merge." "rebase is forbidden: sync only via merge." ;;
    filter-branch|filter-repo)
        deny "переписывание истории (filter-branch/filter-repo) запрещено." "rewriting history (filter-branch/filter-repo) is forbidden." ;;
    clean)
        { has_short f || has_arg --force; } \
            && deny "git clean -f удаляет неотслеживаемые файлы, которые могут быть чужими." \
                    "git clean -f deletes untracked files that may belong to someone else." ;;
    stash)
        first=$(printf '%s' "$args" | tr "$US" '\n' | head -1)
        case "$first" in drop|clear) deny "удаление stash запрещено." "dropping stashes is forbidden." ;; esac ;;
    branch)
        { has_short D || { has_arg --delete && has_arg --force; }; } \
            && deny "принудительное удаление ветки (-D) запрещено; используйте git branch -d." \
                    "force-deleting a branch (-D) is forbidden; use git branch -d." ;;
    esac

    case "$sb" in
    commit|merge|rebase|reset|cherry-pick|revert|am|pull)
        if [ "$on_main" = 1 ]; then
            if { [ "$sb" = merge ] || [ "$sb" = commit ]; } && [ -n "$consent_target" ] && [ "$consent_action" = merge ]; then
                : # finish exception: the owner chose the merge into the main branch, the marker is fresh
            else
                if [ "$known" = 0 ]; then
                    deny "не удалось определить папку команды, а папка сессии — на основной ветке «$main_branch». Укажите папку явно: git -C <путь> $sb … или cd <путь> && git $sb … (путь без переменных оболочки; исключение — слияние и push, которые владелец выбрал в finish: маркер .revref/FINISH_CONSENT, PROTOCOLS.md §9)." \
                         "cannot tell which folder the command runs in, and the session folder is on the main branch '$main_branch'. Name the folder explicitly: git -C <path> $sb … or cd <path> && git $sb … (a path without shell variables; exception: the merge and push the owner chose in finish: the .revref/FINISH_CONSENT marker, PROTOCOLS.md §9)."
                fi
                deny "ветка в папке $where — основная («$main_branch»); агент её не меняет (исключение — слияние и push, которые владелец выбрал в finish: маркер .revref/FINISH_CONSENT, PROTOCOLS.md §9)." \
                     "the branch in folder $where is the main branch ('$main_branch'); the agent never changes it (exception: the merge and push the owner chose in finish: the .revref/FINISH_CONSENT marker, PROTOCOLS.md §9)."
            fi
        fi ;;
    esac

    if [ "$sb" = reset ] && has_arg --hard && [ -n "$(git -C "$where" status --porcelain 2>/dev/null)" ]; then
        deny "git reset --hard при незакоммиченных изменениях уничтожит их." \
             "git reset --hard with uncommitted changes would destroy them."
    fi

    # Secrets: in the commit command (message) and in added lines under .revref/ and docs/revref/.
    if [ "$sb" = commit ]; then
        SECRETS='AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----|gh[pousr]_[A-Za-z0-9]{36,}|github_pat_[A-Za-z0-9_]{50,}|xox[baprs]-[A-Za-z0-9-]{10,}|sk-[A-Za-z0-9_-]{20,}|sk_(live|test)_[A-Za-z0-9]{16,}|AIza[0-9A-Za-z_-]{35}|eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}|(password|passwd|pwd|secret|token|api[_-]?key|access[_-]?key)["'"'"']?[[:space:]]*[:=][[:space:]]*["'"'"']?[A-Za-z0-9+/=_.-]{12,}'
        printf '%s' "$cmd" | grep -Eiq -- "$SECRETS" \
            && deny "в команде коммита (сообщении) похоже на секрет; замаскируйте его (sk-l…9f)." \
                    "the commit command (message) looks like it contains a secret; mask it (sk-l…9f)."
        leaked=$(git -C "$where" diff --cached -U0 -- .revref docs/revref 2>/dev/null | grep '^+' | grep -v '^+++' \
            | grep -v -F '…' | grep -v -F '<скрыто>' | grep -v -F '<hidden>' | grep -Ei -- "$SECRETS" | head -3)
        if [ -n "$leaked" ]; then
            files=$(git -C "$where" diff --cached --name-only -- .revref docs/revref 2>/dev/null | tr '\n' ' ')
            deny "в добавляемых строках .revref/ или docs/revref/ похоже на секрет (файлы: $files). Замаскируйте значение: первые 4 символа, «…», последние 2 — и повторите коммит." \
                 "added lines under .revref/ or docs/revref/ look like they contain a secret (files: $files). Mask the value: first 4 characters, '…', last 2 — and commit again."
        fi
    fi
done <<EOF
$plan
EOF

exit 0
