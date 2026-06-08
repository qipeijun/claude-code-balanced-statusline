# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

这是一个 Claude Code 的自定义状态栏脚本项目，用 Bash 编写。脚本从 stdin 读取 JSON 输入，解析后输出一段带 ANSI 颜色的紧凑状态行。

## 项目结构

```
statusline.sh   ← 核心脚本，Claude Code 通过 statusLine 设置调用
install.sh      ← 安装器，复制脚本到 ~/.claude/ 并修改 settings.json
examples/
  sample-input.json           ← statusline.sh 的典型输入样例
  statusline.settings.json    ← Claude Code settings.json 中需要的配置片段
```

## 数据流

1. Claude Code 调用 `statusLine.command` 指向的脚本
2. Claude Code 通过 stdin 传入当前会话状态的 JSON
3. `statusline.sh` 用 `jq` 解析 JSON 并提取：model、context_window.used_percentage、effort.level、cost.total_lines_added/removed
4. 通过 `git rev-parse` / `git status --porcelain` 获取当前目录的 Git 分支和修改状态
5. 用 `pwd` 取当前目录名
6. 按固定格式输出带 ANSI 颜色的状态行

## 关键技术约定

- 必须是纯 Bash，依赖 `jq` 做 JSON 解析，Git（可选）做分支展示
- 脚本使用 `set -eu`，任何未定义变量或命令失败都会退出
- 颜色支持通过 `NO_COLOR=1` 或 `CLAUDE_STATUSLINE_COLOR=0` 环境变量禁用
- 显示 `user@hostname` 前缀通过 `CLAUDE_STATUSLINE_SHOW_HOST=1` 启用
- 上下文使用率 >= 80% 红色、50-79% 黄色、<50% 青色
- effort 为 `medium` 时不显示，其他值（如 `max`）显示为 `[max]`
- model 名中 `[1m]` 等方括号后缀会被 `sed 's/\[.*\]//'` 去掉
- 所有 `jq` 读取都使用了 `2>/dev/null` 容错，不同字段缺失时静默跳过对应片段

## 常用命令

```bash
# 本地测试：用样例 JSON 管道传入脚本
cat examples/sample-input.json | ./statusline.sh

# 去掉 ANSI 颜色查看纯文本输出
cat examples/sample-input.json | ./statusline.sh | perl -pe 's/\e\[[0-9;]*m//g'

# 用 echo 传入自定义 JSON
echo '{"model":{"display_name":"claude-sonnet-4-6"},"context_window":{"used_percentage":85}}' | ./statusline.sh

# 运行安装器
./install.sh
```
