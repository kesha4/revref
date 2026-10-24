#!/bin/sh
# RevRef usage — Claude Code status line command and token limit reader for the orchestrator.
#
# Claude Code passes limit usage (rate_limits.five_hour / seven_day) only to the status line
# command. This script saves that data so the orchestrator can check the limit between steps
# (PIPELINE.md → "Time and token budget").
#
#   (stdin = status line JSON)  — save the data to <folder>/usage.json and print the status line:
#                                 the output of the previous command from <folder>/statusline-next if present, else its own
#   --read                      — print the last saved limits; exit code 1 if there is no data
#
# <folder> — $REVREF_USAGE_DIR, else ${CLAUDE_CONFIG_DIR:-~/.claude}/revref.
# Requires POSIX sh, sed, tr, date; jq is not needed.

dir=${REVREF_USAGE_DIR:-${CLAUDE_CONFIG_DIR:-$HOME/.claude}/revref}
data="$dir/usage.json"
next="$dir/statusline-next"

# Value of numeric field <key> inside window object <window> (five_hour, seven_day).
field() {
    printf '%s' "$1" | tr '\n\r' '  ' \
        | sed -nE "s/.*\"$2\"[[:space:]]*:[[:space:]]*\{[^}]*\"$3\"[[:space:]]*:[[:space:]]*([0-9.]+).*/\1/p"
}

when() {
    date -d "@$1" '+%Y-%m-%d %H:%M %Z' 2>/dev/null || date -r "$1" '+%Y-%m-%d %H:%M %Z' 2>/dev/null || printf '%s' "$1"
}

if [ "${1:-}" = "--read" ]; then
    [ -s "$data" ] || { echo "no data: $data"; exit 1; }
    json=$(cat "$data")
    now=$(date +%s)
    found=0
    for win in seven_day five_hour; do
        pct=$(field "$json" "$win" used_percentage)
        [ -n "$pct" ] || continue
        found=1
        reset=$(field "$json" "$win" resets_at); reset=${reset%%.*}
        label=week; [ "$win" = five_hour ] && label=5h
        if [ -n "$reset" ] && [ "$reset" -le "$now" ]; then
            echo "$label: expired (window reset $(when "$reset"))"
        elif [ -n "$reset" ]; then
            echo "$label: $pct% (resets $(when "$reset"))"
        else
            echo "$label: $pct%"
        fi
    done
    saved=$(printf '%s' "$json" | sed -nE 's/^\{"saved_at":([0-9]+).*/\1/p')
    [ -n "$saved" ] && echo "updated: $((now - saved)) s ago"
    [ "$found" -eq 1 ] || { echo "no rate limits in $data"; exit 1; }
    exit 0
fi

input=$(cat)

# Save only data with limits: early calls of a session without rate_limits do not overwrite the previous data.
case "$input" in
    *'"rate_limits"'*)
        if mkdir -p "$dir" 2>/dev/null; then
            tmp="$data.$$"
            printf '{"saved_at":%s,"status":%s}\n' "$(date +%s)" "$input" > "$tmp" 2>/dev/null \
                && mv -f "$tmp" "$data" 2>/dev/null
            rm -f "$tmp" 2>/dev/null
        fi
        ;;
esac

# The owner's previous status line, if RevRef is placed in front of it.
if [ -s "$next" ]; then
    printf '%s' "$input" | sh -c "$(tr -d '\r' < "$next")"
    exit $?
fi

week=$(field "$input" seven_day used_percentage)
hour=$(field "$input" five_hour used_percentage)
line=""
[ -n "$week" ] && line="week ${week%%.*}%"
[ -n "$hour" ] && line="${line:+$line · }5h ${hour%%.*}%"
[ -n "$line" ] && echo "RevRef · limit: $line"
exit 0
