#!/usr/bin/env bash
# Claude Code Balanced Statusline 安装器
# 两种用法：
#   1. 本地 clone 后运行：  ./install.sh
#   2. 远端一键安装：      curl -fsSL <raw-url> | bash
set -eu

REPO="qipeijun/claude-code-balanced-statusline"
BRANCH="main"
RAW_BASE="${CLAUDE_STATUSLINE_RAW_BASE:-https://raw.githubusercontent.com/${REPO}/${BRANCH}}"

target_dir="${HOME}/.claude"
target_script="${target_dir}/statusline.sh"
settings_file="${target_dir}/settings.json"
backup_suffix="$(date +%Y%m%d%H%M%S)"

# ---- 颜色 ----
RED='\033[31m'; GREEN='\033[32m'; YELLOW='\033[33m'; CYAN='\033[36m'; GRAY='\033[90m'; RESET='\033[0m'
ok()  { printf "${GREEN}✓${RESET} %s\n" "$1"; }
warn(){ printf "${YELLOW}⚠${RESET} %s\n" "$1" >&2; }
err() { printf "${RED}✗${RESET} %s\n" "$1" >&2; exit 1; }
info(){ printf "${GRAY}→${RESET} %s\n" "$1"; }

# ---- 前置检查 ----
if ! command -v jq >/dev/null 2>&1; then
    printf "${RED}缺少 jq。${RESET}\n\n" >&2
    printf "macOS 用户：  ${CYAN}brew install jq${RESET}\n"
    printf "Ubuntu/Debian: ${CYAN}sudo apt install jq${RESET}\n"
    printf "Fedora/CentOS: ${CYAN}sudo dnf install jq${RESET}\n"
    printf "Arch:          ${CYAN}sudo pacman -S jq${RESET}\n"
    exit 1
fi

# ---- 创建 ~/.claude/ ----
if ! mkdir -p "$target_dir" 2>/dev/null; then
    err "无法创建 ${target_dir}。请检查目录权限：ls -ld ${HOME}"
fi

# ---- 获取 statusline.sh ----
if [ "$0" != "bash" ] && [ -f "$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)/statusline.sh" ]; then
    # 本地模式：从同目录复制
    src="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)/statusline.sh"
    info "从本地仓库安装"
else
    # 远端模式：从 RAW_BASE 下载
    src="${target_script}.download.${backup_suffix}"
    info "下载 statusline.sh"
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "${RAW_BASE}/statusline.sh" -o "$src" || err "下载失败，请检查网络连接"
    elif command -v wget >/dev/null 2>&1; then
        wget -q "${RAW_BASE}/statusline.sh" -O "$src" || err "下载失败，请检查网络连接"
    else
        err "需要 curl 或 wget。请先安装其中之一。"
    fi
fi

# ---- 安装脚本 ----
if [ -f "$target_script" ]; then
    cp "$target_script" "${target_script}.backup.${backup_suffix}" || warn "备份旧脚本失败，继续安装"
    ok "已备份旧脚本 → ${target_script}.backup.${backup_suffix}"
fi

if ! install -m 755 "$src" "$target_script" 2>/dev/null; then
    rm -f "$src"
    err "写入 ${target_script} 失败。请检查目录权限：ls -ld ${target_dir}"
fi
ok "脚本 → ${target_script}"

# 清理下载的临时文件
[ "$src" != "${target_dir}/statusline.sh" ] && rm -f "$src"

# ---- 写入 settings.json ----
if [ -f "$settings_file" ]; then
    cp "$settings_file" "${settings_file}.backup.${backup_suffix}" || warn "备份旧配置失败，继续安装"
    ok "已备份旧配置 → ${settings_file}.backup.${backup_suffix}"
else
    printf '{}\n' > "$settings_file" || err "无法创建 ${settings_file}"
fi

# 写入前再做一次 JSON 合法性检查
if ! jq empty "$settings_file" 2>/dev/null; then
    warn "settings.json 格式异常，将重置为空配置"
    printf '{}\n' > "$settings_file"
fi

tmp_file="${settings_file}.tmp.${backup_suffix}"
if ! jq '.statusLine = {"type":"command","command":"~/.claude/statusline.sh"}' "$settings_file" > "$tmp_file" 2>/dev/null; then
    err "写入 settings.json 失败，请检查文件是否可写。"
fi
mv "$tmp_file" "$settings_file"
ok "配置 → ${settings_file}"

echo ""
printf "${CYAN}安装完成！${RESET} 重启 Claude Code 即可看到状态栏。\n"
echo ""
printf "${GRAY}提示:${RESET}\n"
printf "${GRAY}  export CLAUDE_STATUSLINE_SHOW_HOST=1   # 显示 user@host 前缀${RESET}\n"
printf "${GRAY}  NO_COLOR=1                              # 关闭 ANSI 颜色${RESET}\n"
