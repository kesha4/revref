<#
.SYNOPSIS
    Установка RevRef для Claude Code — Windows PowerShell 5.1 и PowerShell 7+ (Windows, macOS, Linux).
.DESCRIPTION
    Копирует скилл в <папка конфигурации>/skills/revref и агентов в <папка конфигурации>/agents.
    Папка конфигурации — $env:CLAUDE_CONFIG_DIR, если задана, иначе ~/.claude; с -Project — <путь>/.claude.
    Существующая версия скилла сохраняется рядом с суффиксом .bak-<дата>.
.PARAMETER Project
    Установить (или удалить) только в указанном проекте: <путь>/.claude.
.PARAMETER Lang
    Язык набора: ru (по умолчанию) или en.
.PARAMETER Uninstall
    Удалить скилл и агентов RevRef. Резервные копии *.bak-* не трогаются.
.EXAMPLE
    ./install.ps1
.EXAMPLE
    ./install.ps1 -Project ~/work/my-app
.EXAMPLE
    ./install.ps1 -Lang en
.EXAMPLE
    ./install.ps1 -Uninstall
#>
param(
    [string]$Project,
    [ValidateSet('ru', 'en')]
    [string]$Lang = 'ru',
    [switch]$Uninstall
)

$ErrorActionPreference = 'Stop'
$src = $PSScriptRoot
if ($Lang -eq 'en') {
    $skillSrc = Join-Path (Join-Path $src 'skill-en') 'revref'; $agentsSrc = Join-Path $src 'agents-en'; $changelog = Join-Path $src 'CHANGELOG.en.md'
} else {
    $skillSrc = Join-Path (Join-Path $src 'skill') 'revref'; $agentsSrc = Join-Path $src 'agents'; $changelog = Join-Path $src 'CHANGELOG.md'
}
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

Copy-Item -LiteralPath $skillSrc -Destination $skillDst -Recurse
Copy-Item -LiteralPath $changelog -Destination (Join-Path $skillDst 'CHANGELOG.md')
foreach ($name in $agentNames) {
    Copy-Item -LiteralPath (Join-Path $agentsSrc $name) -Destination $agentsDst -Force
}

# Абсолютный путь к сторожевому хуку во frontmatter скилла и агентов (прямые слеши — хук выполняется через sh).
$skillPath = (Resolve-Path -LiteralPath $skillDst).Path -replace '\\', '/'
$utf8 = New-Object System.Text.UTF8Encoding $false
$files = @(Join-Path $skillDst 'SKILL.md') + ($agentNames | ForEach-Object { Join-Path $agentsDst $_ })
foreach ($f in $files) {
    $text = [System.IO.File]::ReadAllText($f, $utf8).Replace('__REVREF_SKILL_DIR__', $skillPath)
    [System.IO.File]::WriteAllText($f, $text, $utf8)
}

Write-Host "Скилл:   $skillDst (язык: $Lang, версия: $((Get-Content -LiteralPath (Join-Path $skillDst 'VERSION') -TotalCount 1)))"
Write-Host "Агенты:  $agentsDst (revref-reviewer, revref-verifier, revref-fixer)"
Write-Host 'Перезапустите сессию Claude Code и выполните в проекте: /revref init'
