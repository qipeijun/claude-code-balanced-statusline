#!/usr/bin/env bash
set -eu

project_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
target_dir="${HOME}/.claude"
target_script="${target_dir}/statusline.sh"
settings_file="${target_dir}/settings.json"
backup_suffix="$(date +%Y%m%d%H%M%S)"

if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq is required."
    echo "Install it first, for example: brew install jq"
    exit 1
fi

mkdir -p "$target_dir"

if [ -f "$target_script" ]; then
    cp "$target_script" "${target_script}.backup.${backup_suffix}"
fi

install -m 755 "${project_dir}/statusline.sh" "$target_script"

if [ -f "$settings_file" ]; then
    cp "$settings_file" "${settings_file}.backup.${backup_suffix}"
else
    printf '{}\n' > "$settings_file"
fi

tmp_file="${settings_file}.tmp.${backup_suffix}"
jq '.statusLine = {"type":"command","command":"~/.claude/statusline.sh"}' "$settings_file" > "$tmp_file"
mv "$tmp_file" "$settings_file"

echo "Installed Claude Code balanced statusline."
echo "Script: ${target_script}"
echo "Settings: ${settings_file}"
echo "Restart Claude Code or trigger the next interaction to refresh the statusline."
