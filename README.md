# Claude Code Balanced Statusline

把项目、分支、上下文用量、变更量、模型和 effort 档位压进一条高密度状态行。
足够克制，足够醒目，适合一直挂在终端底部。

👉 [项目主页](https://qipeijun.github.io/claude-code-balanced-statusline/)

![终端截图](docs/screenshot.png)

```text
claude-code-balanced-statusline  [feature/v1.1.0]*  Ctx: 3%  +1/-0  deepseek-v4-pro  [max]
```

## 快速开始

GitHub：

```bash
curl -fsSL https://raw.githubusercontent.com/qipeijun/claude-code-balanced-statusline/main/install.sh | bash
```

Gitee 镜像（GitHub 访问不稳定时）：

```bash
curl -fsSL https://gitee.com/qipeijun/claude-code-balanced-statusline/raw/main/install.sh | CLAUDE_STATUSLINE_RAW_BASE=https://gitee.com/qipeijun/claude-code-balanced-statusline/raw/main bash
```

前提：已安装 `jq`。macOS 上 `brew install jq`，其他系统用对应包管理器。Git 可选，没有也不报错。

## 状态栏字段

| 字段 | 颜色 | 说明 |
|------|------|------|
| 项目目录 | 黄 | 当前工作目录名 |
| Git 分支 | 绿 | `*` 表示工作区有未提交修改 |
| Ctx: N% | 青 / 黄 / 红 | 上下文用量：<50% 青，50-79% 黄，≥80% 红 |
| +N/-N | 绿 / 红 | 本轮会话新增与删除行数 |
| 模型名 | 灰 | 自动去掉 `[1m]` 等 provider 尾缀 |
| [effort] | 灰 | 仅非 `medium` 时显示 |

## 安装

**GitHub 一行安装**（推荐）：

```bash
curl -fsSL https://raw.githubusercontent.com/qipeijun/claude-code-balanced-statusline/main/install.sh | bash
```

**Gitee 镜像一行安装**（GitHub 访问不稳定时）：

```bash
curl -fsSL https://gitee.com/qipeijun/claude-code-balanced-statusline/raw/main/install.sh | CLAUDE_STATUSLINE_RAW_BASE=https://gitee.com/qipeijun/claude-code-balanced-statusline/raw/main bash
```

Windows：

```powershell
powershell -c "irm https://raw.githubusercontent.com/qipeijun/claude-code-balanced-statusline/main/install.ps1 | iex"
```

Gitee 镜像：

```powershell
$env:CLAUDE_STATUSLINE_RAW_BASE="https://gitee.com/qipeijun/claude-code-balanced-statusline/raw/main"; irm https://gitee.com/qipeijun/claude-code-balanced-statusline/raw/main/install.ps1 | iex
```

安装器会自动备份旧文件，把脚本安装到稳定的用户数据目录，并只追加 `statusLine` 配置到 Claude Code 的 `settings.json`，不动你已有的其他字段。

### 与 ccswitch / 配置切换器共存

`statusLine` 是 Claude Code 配置的一部分。安装器会写入当前活动的 `~/.claude/settings.json`，但如果你使用 ccswitch、CC Switch 或其他配置切换器，它们在切换 profile 时可能会重写这份文件；目标 profile 里没有 `statusLine` 时，状态栏就会消失。

解决方式二选一：

1. 让配置切换器在切换时保留已有的 `statusLine` 字段。
2. 把下面这段配置加入每一个 Claude Code profile/template：

```json
{
  "statusLine": {
    "type": "command",
    "command": "/Users/你的用户名/.local/share/claude-code-balanced-statusline/statusline.sh"
  }
}
```

每次切换后重新运行安装器只能临时恢复，不是根治方案。

**手动安装**：

```bash
mkdir -p ~/.local/share/claude-code-balanced-statusline
cp statusline.sh ~/.local/share/claude-code-balanced-statusline/statusline.sh
chmod +x ~/.local/share/claude-code-balanced-statusline/statusline.sh
```

然后在 `~/.claude/settings.json` 中加上，`command` 请替换为你的真实绝对路径：

```json
{
  "statusLine": {
    "type": "command",
    "command": "/Users/你的用户名/.local/share/claude-code-balanced-statusline/statusline.sh"
  }
}
```

## 环境变量

| 变量 | 效果 |
|------|------|
| `CLAUDE_STATUSLINE_SHOW_HOST=1` | 在目录名前显示 `user@hostname` |
| `NO_COLOR=1` | 关闭 ANSI 颜色 |
| `CLAUDE_STATUSLINE_COLOR=0` | 同上 |

## 本地测试

```bash
echo '{"model":{"display_name":"deepseek-v4-pro[1m]"},"context_window":{"used_percentage":3},"cost":{"total_lines_added":1,"total_lines_removed":0},"effort":{"level":"max"}}' | ./statusline.sh
```

去掉颜色看纯文本：

```bash
echo '{"model":{"display_name":"deepseek-v4-pro[1m]"},"context_window":{"used_percentage":3},"cost":{"total_lines_added":1,"total_lines_removed":0},"effort":{"level":"max"}}' | ./statusline.sh | perl -pe 's/\e\[[0-9;]*m//g'
```

预期输出：

```text
claude-code-balanced-statusline  Ctx: 3%  +1/-0  deepseek-v4-pro  [max]
```

在 Git 仓库内运行时还会显示分支名。

## License

MIT
