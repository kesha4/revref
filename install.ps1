# Установка RevRef для Claude Code — Windows PowerShell 5.1 и PowerShell 7+ (Windows, macOS, Linux).
#   ./install.ps1                       — глобально: в $env:CLAUDE_CONFIG_DIR или ~/.claude (доступно во всех проектах)
#   ./install.ps1 -Project <путь>       — только в указанный проект: <путь>/.claude
#   ./install.ps1 -Uninstall [-Project <путь>]  — удалить скилл и агентов RevRef
param(
    [string]$Project,
    [switch]$Uninstall
)

$ErrorActionPreference = 'Stop'
$src = $PSScriptRoot
$agentNames = @('revref-reviewer.md', 'revref-verifier.md', 'revref-fixer.md')

if ($Project) {
    $target = Join-Path (Resolve-Path -LiteralPath $Project).Path '.claude'
} elseif ($env:CLAUDE_CONFIG_DIR) {
    $target = $env:CLAUDE_CONFIG_DIR
} else {
    $target = Join-Path $HOME '.claude'
}

$skillDst  = Join-Path (Join-Path $target 'skills') 'revref'
$agentsDst = Join-Path $target 'agents'

if ($Uninstall) {
    if (Test-Path -LiteralPath $skillDst) {
        Remove-Item -LiteralPath $skillDst -Recurse -Force
        Write-Host "Удалён скилл: $skillDst"
    }
    foreach ($name in $agentNames) {
        $path = Join-Path $agentsDst $name
        if (Test-Path -LiteralPath $path) {
            Remove-Item -LiteralPath $path -Force
            Write-Host "Удалён агент: $path"
        }
    }
    Write-Host 'RevRef удалён. Резервные копии *.bak-* (если есть) не тронуты.'
    return
}

if (Test-Path -LiteralPath $skillDst) {
    $backup = "$skillDst.bak-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Move-Item -LiteralPath $skillDst -Destination $backup
    Write-Host "Предыдущая версия скилла сохранена: $backup"
}

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $skillDst) | Out-Null
New-Item -ItemType Directory -Force -Path $agentsDst | Out-Null

Copy-Item -LiteralPath (Join-Path (Join-Path $src 'skill') 'revref') -Destination $skillDst -Recurse
foreach ($name in $agentNames) {
    Copy-Item -LiteralPath (Join-Path (Join-Path $src 'agents') $name) -Destination $agentsDst -Force
}

Write-Host "Скилл:   $skillDst"
Write-Host "Агенты:  $agentsDst (revref-reviewer, revref-verifier, revref-fixer)"
Write-Host 'Перезапустите сессию Claude Code и выполните в проекте: /revref init'
