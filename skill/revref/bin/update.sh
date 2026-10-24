#!/bin/sh
# RevRef update — check for and install a new kit version from its source (PROTOCOLS.md §11).
# Проверка и установка новой версии набора из его источника (PROTOCOLS.md §11).
#
#   update.sh --check [--force]              installed and latest version; cached for 24 h unless --force
#   update.sh --prepare [vX.Y.Z]             fetch the release (default: latest), print commit, major, CHANGELOG entries
#   update.sh --apply vX.Y.Z --expect <sha>  install that release with the recorded options — only after the owner's "yes"
#   update.sh                                for a person in a terminal: check, show changes, ask [y/N], install
#
# Installation options come from INSTALL next to VERSION (written by install.sh / install.ps1).
# Only release tags vX.Y.Z of the recorded source are installed, never a branch.
# REVREF_UPDATE_CHECK=off disables the check without --force; REVREF_UPDATE_SOURCE overrides the source.
# Requires POSIX sh, git, sed, awk.

skill=${REVREF_UPDATE_SKILL:-$(cd "$(dirname "$0")/.." && pwd)}
info="$skill/INSTALL"
data=${REVREF_DATA_DIR:-${CLAUDE_CONFIG_DIR:-$HOME/.claude}/revref}
official=https://github.com/kesha4/revref

get() { [ -f "$info" ] && sed -n "s/^$1=//p" "$info" | head -1 | tr -d '\r'; }

lang=$(get lang)
if [ -z "$lang" ]; then
    lang=en; grep -q 'Аргументы вызова' "$skill/SKILL.md" 2>/dev/null && lang=ru
fi
say() { if [ "$lang" = en ]; then printf '%s\n' "$2"; else printf '%s\n' "$1"; fi; }
die() { say "Ошибка: $1" "Error: $2" >&2; exit 1; }

source_url=${REVREF_UPDATE_SOURCE:-$(get source)}
source_url=${source_url:-$official}
scope=$(get scope); target=""; project=""
# Folders come from where the kit lies now, not from INSTALL: a project installation committed to git
# is cloned to other folders and machines, and must update itself there.
case "$skill" in
    */skills/revref) target=${skill%/skills/revref} ;;
esac
if [ -z "$scope" ] && [ -n "$target" ]; then
    # Installed without INSTALL (older installer or a manual copy): infer from the path.
    scope=global
    case "$target" in */.claude) [ "$target" != "${CLAUDE_CONFIG_DIR:-$HOME/.claude}" ] && scope=project ;; esac
fi
if [ "$scope" = project ]; then
    case "$target" in */.claude) project=${target%/.claude} ;; *) scope=unknown ;; esac
fi
[ -n "$target" ] || scope=unknown
installed=$(tr -d '\r\n ' < "$skill/VERSION" 2>/dev/null)

# gt A B — version A is newer than B.
gt() {
    awk -v a="${1#v}" -v b="${2#v}" 'BEGIN { split(a, x, "."); split(b, y, ".")
        for (i = 1; i <= 3; i++) { if (x[i] + 0 > y[i] + 0) exit 0; if (x[i] + 0 < y[i] + 0) exit 1 } exit 1 }'
}

latest_version() {
    git ls-remote --tags --refs "$source_url" 2>/dev/null \
        | sed -n 's|.*refs/tags/v\([0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\)$|\1|p' \
        | sort -t. -k1,1n -k2,2n -k3,3n | tail -1
}

where() {
    case "$scope" in
        project) say "в проекте $project" "in project $project" ;;
        global) say "глобально ($target)" "globally ($target)" ;;
        *) say "в $skill" "in $skill" ;;
    esac
}

check() {
    force=$1
    if [ "$force" -eq 0 ] && [ "${REVREF_UPDATE_CHECK:-on}" = off ]; then echo "status: check disabled (REVREF_UPDATE_CHECK=off)"; return 0; fi
    cache="$data/update-check"
    latest=""
    if [ "$force" -eq 0 ] && [ -f "$cache" ]; then
        checked=$(sed -n 's/^checked_at=//p' "$cache"); csrc=$(sed -n 's/^source=//p' "$cache")
        if [ -n "$checked" ] && [ "$csrc" = "$source_url" ] && [ $(( $(date +%s) - checked )) -lt 86400 ]; then
            latest=$(sed -n 's/^latest=//p' "$cache")
        fi
    fi
    if [ -z "$latest" ]; then
        latest=$(latest_version)
        [ -n "$latest" ] || { echo "installed: $installed ($(where))"; echo "status: unknown (source unavailable: $source_url)"; return 1; }
        mkdir -p "$data" 2>/dev/null && printf 'checked_at=%s\nsource=%s\nlatest=%s\n' "$(date +%s)" "$source_url" "$latest" > "$cache" 2>/dev/null
    fi
    echo "installed: $installed ($(where), $lang)"
    echo "latest: $latest ($source_url)"
    if gt "$latest" "$installed"; then echo "status: update-available"
    elif gt "$installed" "$latest"; then echo "status: ahead"
    else echo "status: up-to-date"; fi
}

valid_tag() { printf '%s' "$1" | grep -Eq '^v[0-9]+\.[0-9]+\.[0-9]+$'; }

# fetch TAG DIR — shallow clone of the release tag; verifies that VERSION matches the tag.
fetch() {
    git -c advice.detachedHead=false clone -q --depth 1 --branch "$1" "$source_url" "$2" >"$2.log" 2>&1 \
        || { cat "$2.log" >&2; die "не удалось получить $1 из $source_url" "cannot fetch $1 from $source_url"; }
    v=$(tr -d '\r\n ' < "$2/skill/revref/VERSION" 2>/dev/null)
    [ "v$v" = "$1" ] || die "в релизе $1 файл VERSION содержит «$v»" "VERSION in release $1 is \"$v\""
    [ -f "$2/install.sh" ] || die "в релизе $1 нет install.sh" "release $1 has no install.sh"
}

changes() {
    log="$1/CHANGELOG.md"; [ "$lang" = en ] && log="$1/CHANGELOG.en.md"
    awk -v inst="$installed" '
        function gt(a, b,  x, y, i) { split(a, x, "."); split(b, y, ".")
            for (i = 1; i <= 3; i++) { if (x[i] + 0 > y[i] + 0) return 1; if (x[i] + 0 < y[i] + 0) return 0 } return 0 }
        /^## [0-9]+\.[0-9]+\.[0-9]+/ { on = gt($2, inst) }
        on { print }' "$log"
}

tmpdir() { mktemp -d 2>/dev/null || mktemp -d -t revrefupd; }

# Temporary folders to remove on exit: the fetched release and this script's own copy.
cleanup=""
trap 'rm -rf $cleanup' EXIT
[ -n "${REVREF_UPDATE_COPY:-}" ] && cleanup=$REVREF_UPDATE_COPY   # mktemp folders: no spaces

prepare() {
    tag=$1
    if [ -z "$tag" ]; then
        latest=$(latest_version); [ -n "$latest" ] || die "источник недоступен: $source_url" "source unavailable: $source_url"
        tag="v$latest"
    fi
    valid_tag "$tag" || die "версия должна иметь вид vX.Y.Z: $tag" "version must look like vX.Y.Z: $tag"
    t=$(tmpdir); cleanup="$cleanup $t"; trap 'rm -rf $cleanup' EXIT   # again: subshells do not inherit traps
    fetch "$tag" "$t/revref"
    new=${tag#v}
    echo "installed: $installed ($(where), $lang)"
    echo "version: $new"
    echo "source: $source_url"
    echo "commit: $(git -C "$t/revref" rev-parse HEAD)"
    if gt "$new" "$installed"; then echo "direction: upgrade"
    elif gt "$installed" "$new"; then echo "direction: downgrade"
    else echo "direction: reinstall"; fi
    [ "${new%%.*}" != "${installed%%.*}" ] && echo "major: yes" || echo "major: no"
    if gt "$new" "$installed"; then echo "--- changes"; changes "$t/revref"; fi
}

apply() {
    tag=$1; expect=$2
    valid_tag "$tag" || die "версия должна иметь вид vX.Y.Z: $tag" "version must look like vX.Y.Z: $tag"
    [ -n "$expect" ] || die "нужен --expect <commit> из --prepare" "--expect <commit> from --prepare is required"
    case "$scope" in global|project) ;; *) die "не удалось определить, куда установлен набор: $skill" "cannot tell where the kit is installed: $skill" ;; esac
    t=$(tmpdir); cleanup="$cleanup $t"; trap 'rm -rf $cleanup' EXIT   # again: subshells do not inherit traps
    fetch "$tag" "$t/revref"
    sha=$(git -C "$t/revref" rev-parse HEAD)
    case "$sha" in "$expect"*) ;; *) die "релиз $tag изменился после проверки: $sha вместо $expect" "release $tag changed after the check: $sha instead of $expect" ;; esac
    cd "$t" || exit 1   # the installer moves the current skill folder aside
    if [ "$scope" = project ]; then
        sh "$t/revref/install.sh" --lang "$lang" --project "$project" || die "установщик завершился с ошибкой" "the installer failed"
    else
        CLAUDE_CONFIG_DIR="$target" sh "$t/revref/install.sh" --lang "$lang" || die "установщик завершился с ошибкой" "the installer failed"
    fi
    rm -f "$data/update-check" 2>/dev/null
    say "RevRef обновлён: $installed → ${tag#v} ($(where)). Перезапустите сессию Claude Code и выполните /revref resume, если идёт прогон." \
        "RevRef updated: $installed → ${tag#v} ($(where)). Restart the Claude Code session and run /revref resume if a run is in progress."
}

# The installer replaces the folder this script lives in: run --apply and the interactive mode from a copy.
case "${1:-}" in
    --apply|"")
        if [ -z "${REVREF_UPDATE_SKILL:-}" ]; then
            copy=$(tmpdir) && cp "$0" "$copy/update.sh" || exit 1
            REVREF_UPDATE_SKILL="$skill" REVREF_UPDATE_COPY="$copy" exec sh "$copy/update.sh" "$@"
        fi ;;
esac

case "${1:-}" in
    --check) [ "${2:-}" = --force ] && check 1 || check 0 ;;
    --prepare) prepare "${2:-}" ;;
    --apply)
        tag=${2:-}; expect=""
        [ "${3:-}" = --expect ] && expect=${4:-}
        apply "$tag" "$expect" ;;
    "")
        out=$(check 1) || { printf '%s\n' "$out"; exit 1; }
        printf '%s\n' "$out"
        printf '%s' "$out" | grep -q 'status: update-available' || exit 0
        latest=$(printf '%s' "$out" | sed -n 's/^latest: \([^ ]*\).*/\1/p')
        info_out=$(prepare "v$latest") || exit 1
        printf '%s\n' "$info_out" | sed -n '/^--- changes/,$p'
        commit=$(printf '%s' "$info_out" | sed -n 's/^commit: //p')
        printf '%s' "$info_out" | grep -q 'major: yes' && say \
            "Мажорная версия: начатый прогон нельзя продолжить без миграции — лучше обновляться между прогонами." \
            "Major version: a run in progress cannot continue without migration — better update between runs."
        if [ -t 0 ]; then
            say "Обновить RevRef $installed → $latest ($(where))? [y/N] " "Update RevRef $installed → $latest ($(where))? [y/N] "
            read -r answer
            case "$answer" in y|Y|yes|д|да|Да) apply "v$latest" "$commit" ;; *) say "Отменено." "Cancelled." ;; esac
        else
            say "Чтобы обновить: sh \"$skill/bin/update.sh\" --apply v$latest --expect $commit" \
                "To update: sh \"$skill/bin/update.sh\" --apply v$latest --expect $commit"
        fi ;;
    -h|--help) sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//' ;;
    *) die "неизвестный параметр: $1 (см. --help)" "unknown option: $1 (see --help)" ;;
esac
