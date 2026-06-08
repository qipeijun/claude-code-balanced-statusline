#!/usr/bin/env bash
# Balanced Claude Code statusline.
set -eu

input=$(cat 2>/dev/null)
[ -z "$input" ] && input="{}"

jq_read() {
    printf '%s' "$input" | jq -r "$1" 2>/dev/null
}

model=$(jq_read '.model.display_name // .model.id // ""')
pct=$(jq_read '.context_window.used_percentage // ""')
effort=$(jq_read '.effort.level // ""')
lines_added=$(jq_read '.cost.total_lines_added // 0')
lines_removed=$(jq_read '.cost.total_lines_removed // 0')

if [ "${NO_COLOR:-}" = "1" ] || [ "${CLAUDE_STATUSLINE_COLOR:-1}" = "0" ]; then
    C_CYAN=""
    C_YELLOW=""
    C_GREEN=""
    C_GRAY=""
    C_RED=""
    C_RESET=""
else
    C_CYAN=$'\033[36m'
    C_YELLOW=$'\033[33m'
    C_GREEN=$'\033[32m'
    C_GRAY=$'\033[90m'
    C_RED=$'\033[31m'
    C_RESET=$'\033[0m'
fi

branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
dirty=""
if [ -n "$branch" ] && [ -n "$(git status --porcelain --untracked-files=no 2>/dev/null)" ]; then
    dirty="*"
fi

cwd=$(pwd)
[ "$cwd" = "$HOME" ] && dir="~" || dir=$(basename "$cwd")

if [ "${CLAUDE_STATUSLINE_SHOW_HOST:-0}" = "1" ]; then
    printf '%s%s@%s%s  ' "$C_CYAN" "$(whoami)" "$(hostname -s)" "$C_RESET"
fi

printf '%s%s%s' "$C_YELLOW" "$dir" "$C_RESET"
[ -n "$branch" ] && printf '  %s[%s]%s%s' "$C_GREEN" "$branch" "$dirty" "$C_RESET"

if [ -n "$pct" ] && [ "$pct" != "null" ]; then
    pct_display=$(printf '%s' "$pct" | sed 's/\.0$//')
    pct_int=$(printf '%s' "$pct_display" | cut -d. -f1)
    pct_color="$C_CYAN"
    if [ "$pct_int" -ge 80 ] 2>/dev/null; then
        pct_color="$C_RED"
    elif [ "$pct_int" -ge 50 ] 2>/dev/null; then
        pct_color="$C_YELLOW"
    fi
    printf '  %sCtx:%s %s%s%%%s' "$C_GRAY" "$C_RESET" "$pct_color" "$pct_display" "$C_RESET"
fi

if [ "${lines_added:-0}" -gt 0 ] 2>/dev/null || [ "${lines_removed:-0}" -gt 0 ] 2>/dev/null; then
    printf '  %s+%s%s/%s-%s%s' "$C_GREEN" "$lines_added" "$C_GRAY" "$C_RED" "$lines_removed" "$C_RESET"
fi

if [ -n "$model" ] && [ "$model" != "null" ]; then
    model_short=$(printf '%s' "$model" | sed 's/\[.*\]//')
    printf '  %s%s%s' "$C_GRAY" "$model_short" "$C_RESET"
fi

if [ -n "$effort" ] && [ "$effort" != "null" ] && [ "$effort" != "medium" ]; then
    printf '  %s[%s]%s' "$C_GRAY" "$effort" "$C_RESET"
fi

echo ""
