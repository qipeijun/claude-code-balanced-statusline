# Claude Code Balanced Statusline - Windows 安装器
# 用法: powershell -ExecutionPolicy Bypass -File install.ps1
# 一键: powershell -c "irm https://raw.githubusercontent.com/qipeijun/claude-code-balanced-statusline/main/install.ps1 | iex"

$ErrorActionPreference = "Stop"

$Repo = "qipeijun/claude-code-balanced-statusline"
$Branch = "main"
$RawBase = "https://raw.githubusercontent.com/$Repo/$Branch"

$ClaudeDir = Join-Path $env:USERPROFILE ".claude"
$TargetScript = Join-Path $ClaudeDir "statusline.sh"
$SettingsFile = Join-Path $ClaudeDir "settings.json"
$BackupSuffix = Get-Date -Format "yyyyMMddHHmmss"

# ---- 检查前置依赖 ----
$missing = @()
if (-not (Get-Command "git" -ErrorAction SilentlyContinue)) { $missing += "git" }
if (-not (Get-Command "jq" -ErrorAction SilentlyContinue)) { $missing += "jq" }

if ($missing.Count -gt 0) {
    Write-Host "缺少以下依赖: $($missing -join ', ')" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Git Bash 用户:" -ForegroundColor Cyan
    Write-Host "  jq 放在 Git Bash 的 /usr/bin/ 下即可，不需要装在 PowerShell PATH 里。"
    Write-Host "  下载: https://github.com/jqlang/jq/releases"
    Write-Host ""
    Write-Host "或者用包管理器:" -ForegroundColor Cyan
    Write-Host "  winget install Git.Git jqlang.jq"
    Write-Host "  scoop install git jq"
    Write-Host ""
    Write-Host "装好后重新运行本脚本即可。" -ForegroundColor Gray
    exit 1
}

# ---- 创建 .claude 目录 ----
if (-not (Test-Path $ClaudeDir)) {
    New-Item -ItemType Directory -Path $ClaudeDir -Force | Out-Null
    Write-Host "✓ 创建 $ClaudeDir" -ForegroundColor Green
}

# ---- 下载 statusline.sh ----
$TempScript = Join-Path $env:TEMP "statusline.sh.download.$BackupSuffix"
Write-Host "→ 下载 statusline.sh ..." -ForegroundColor Gray
try {
    Invoke-WebRequest -Uri "$RawBase/statusline.sh" -OutFile $TempScript -ErrorAction Stop
} catch {
    Write-Host "下载失败: $_" -ForegroundColor Red
    Write-Host "请检查网络连接，或手动从 GitHub 下载。" -ForegroundColor Yellow
    exit 1
}

# ---- 备份旧脚本 ----
if (Test-Path $TargetScript) {
    $BackupScript = "$TargetScript.backup.$BackupSuffix"
    Copy-Item $TargetScript $BackupScript
    Write-Host "✓ 已备份旧脚本 → $BackupScript" -ForegroundColor Green
}

# ---- 安装脚本 ----
Copy-Item $TempScript $TargetScript -Force
Remove-Item $TempScript -Force
Write-Host "✓ 脚本 → $TargetScript" -ForegroundColor Green

# ---- 更新 settings.json ----
# 注意：使用 PSCustomObject 而非 -AsHashtable，以兼容 Windows PowerShell 5.1
$settings = New-Object PSObject
if (Test-Path $SettingsFile) {
    $BackupSettings = "$SettingsFile.backup.$BackupSuffix"
    Copy-Item $SettingsFile $BackupSettings
    Write-Host "✓ 已备份旧配置 → $BackupSettings" -ForegroundColor Green
    try {
        $content = Get-Content $SettingsFile -Raw -Encoding UTF8
        if ($content.Trim()) {
            $settings = $content | ConvertFrom-Json
        }
    } catch {
        Write-Host "settings.json 格式有误，将覆盖写入。" -ForegroundColor Yellow
        $settings = New-Object PSObject
    }
}

$statusLine = [PSCustomObject]@{
    type    = "command"
    command = "~/.claude/statusline.sh"
}
$settings | Add-Member -MemberType NoteProperty -Name "statusLine" -Value $statusLine -Force

$settings | ConvertTo-Json -Depth 10 | Set-Content $SettingsFile -Encoding UTF8
Write-Host "✓ 配置 → $SettingsFile" -ForegroundColor Green

Write-Host ""
Write-Host "安装完成！重启 Claude Code 即可看到状态栏。" -ForegroundColor Cyan
Write-Host ""
Write-Host "运行时依赖:" -ForegroundColor Gray
Write-Host "  jq  — JSON 解析（状态栏脚本内部使用）" -ForegroundColor Gray
Write-Host "  git — 分支名和修改状态展示（可选）" -ForegroundColor Gray
