# Claude Code Balanced Statusline

A compact, readable statusline for Claude Code.

👉 [项目主页](https://qipeijun.github.io/claude-code-balanced-statusline/)

It shows the information that usually matters while coding:

```text
claude-code-balanced-statusline  [feature/v1.1.0]*  Ctx: 3%  +1/-0  deepseek-v4-pro  [max]
```

## Features

- Current project directory
- Git branch, with `*` when tracked files are modified
- Context window usage as `Ctx: 3%`
- Session code diff as `+added/-removed`
- Current model, with provider suffixes like `[1m]` hidden
- Effort level when it is not the default `medium`
- Light ANSI colors with risk coloring for context usage

## Requirements

- Claude Code with `statusLine` support
- Bash
- `jq`
- Git, if you want branch and dirty-state display

On macOS:

```bash
brew install jq
```

## Install

Clone the repository, then run:

```bash
./install.sh
```

The installer will:

- copy `statusline.sh` to `~/.claude/statusline.sh`
- back up an existing `~/.claude/statusline.sh` if present
- back up `~/.claude/settings.json`
- merge only this field into `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh"
  }
}
```

Restart Claude Code or trigger the next interaction to refresh the statusline.

## Manual Install

```bash
mkdir -p ~/.claude
cp statusline.sh ~/.claude/statusline.sh
chmod +x ~/.claude/statusline.sh
```

Then add this to `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh"
  }
}
```

If your settings file already has other fields, add only the `statusLine` field.
Do not replace the whole file.

## Options

Environment variables:

```bash
CLAUDE_STATUSLINE_SHOW_HOST=1
```

Shows `user@hostname` before the project name.

```bash
NO_COLOR=1
```

Disables ANSI colors.

```bash
CLAUDE_STATUSLINE_COLOR=0
```

Also disables ANSI colors.

## Color Rules

- Project name: yellow
- Branch: green
- `Ctx:` label: gray
- Context percentage:
  - `< 50%`: cyan
  - `50-79%`: yellow
  - `>= 80%`: red
- Added lines: green
- Removed lines: red
- Model and effort: gray

## Test Locally

```bash
echo '{"model":{"display_name":"deepseek-v4-pro[1m]"},"context_window":{"used_percentage":3},"cost":{"total_lines_added":1,"total_lines_removed":0},"effort":{"level":"max"}}' | ./statusline.sh
```

Plain-text preview:

```bash
echo '{"model":{"display_name":"deepseek-v4-pro[1m]"},"context_window":{"used_percentage":3},"cost":{"total_lines_added":1,"total_lines_removed":0},"effort":{"level":"max"}}' | ./statusline.sh | perl -pe 's/\e\[[0-9;]*m//g'
```

Expected:

```text
claude-code-balanced-statusline  Ctx: 3%  +1/-0  deepseek-v4-pro  [max]
```

When run inside a Git repo, the branch segment will also appear.

## Security

Do not publish your full `~/.claude/settings.json`.

Claude Code settings may contain API tokens, provider URLs, hooks, or local paths.
This project only needs the `statusLine` configuration snippet above.

## License

MIT
