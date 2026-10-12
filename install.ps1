# Установка RevRef v3 для Claude Code.
#   .\install.ps1                      — глобально, в ~/.claude (доступно во всех проектах)
#   .\install.ps1 -Project <путь>      — только в указанный проект, в <путь>/.claude
param(
    [string]$Project
)

$ErrorActionPreference = 'Stop'
$src = $PSScriptRoot

if ($Project) {
    $target = Join-Path (Resolve-Path $Project) '.claude'
} else {
    $target = Join-Path $HOME '.claude'
}

$skillDst  = Join-Path $target 'skills\revref'
$agentsDst = Join-Path $target 'agents'

if (Test-Path $skillDst) {
    $backup = "$skillDst.bak-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Move-Item $skillDst $backup
    Write-Host "Предыдущая версия скилла сохранена: $backup"
}

New-Item -ItemType Directory -Force (Split-Path $skillDst) | Out-Null
New-Item -ItemType Directory -Force $agentsDst | Out-Null

Copy-Item (Join-Path $src 'skill\revref') $skillDst -Recurse
Copy-Item (Join-Path $src 'agents\*.md') $agentsDst -Force

Write-Host "Скилл:   $skillDst"
Write-Host "Агенты:  $agentsDst (revref-reviewer, revref-verifier, revref-fixer)"
Write-Host "Перезапустите сессию Claude Code и выполните в проекте: /revref init"
