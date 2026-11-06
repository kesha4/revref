# RevRef guard — entry point for platforms without tool hooks (DSH) and for PowerShell sessions.
# Сторожевой хук RevRef для DSH и PowerShell: решает hooks/guard.sh (единственная реализация),
# вызывая его через POSIX-оболочку: sh из Git Bash, WSL или PATH.
#
#   pwsh hooks/guard.ps1 -Command 'git push --force' [-Cwd <путь>]
#   powershell -File hooks/guard.ps1 -Command 'git reset --hard'
#   $env:REVREF_CHECK_COMMAND = 'git commit -m "fix"'; pwsh hooks/guard.ps1 -Cwd <путь>
#
# Коды возврата те же, что у guard.sh: 0 — можно, 2 — запрещено (причина в stderr), 3 — проверить нечем.
# В DSH хук не автоматический: перед каждой защищённой POLICY.md → «Git» командой запускай эту проверку
# (PLATFORMS.md → «Сторожевой хук»). Заблокированную команду не выполняй и не обходи другим способом.
[CmdletBinding()]
param(
    [string]$Command,
    [string]$Cwd = (Get-Location).Path
)

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$guard = Join-Path $here 'guard.sh'
if (-not (Test-Path -LiteralPath $guard)) {
    [Console]::Error.WriteLine("RevRef guard: guard.sh не найден рядом с guard.ps1 ($guard)")
    exit 3
}

# Команда — из -Command или из $env:REVREF_CHECK_COMMAND: переменная избавляет от проблем с кавычками
# при вызове из вложенной оболочки Windows PowerShell 5.1.
$commandText = if (-not [string]::IsNullOrEmpty($Command)) { $Command } elseif ($env:REVREF_CHECK_COMMAND) { $env:REVREF_CHECK_COMMAND } else { '' }
if ([string]::IsNullOrWhiteSpace($commandText)) {
    [Console]::Error.WriteLine('RevRef guard: usage: guard.ps1 -Command "<команда>" [-Cwd <путь>] (или задайте REVREF_CHECK_COMMAND)')
    exit 2
}

$sh = $null
foreach ($name in @('sh', 'bash')) {
    $found = Get-Command $name -ErrorAction SilentlyContinue
    if ($found) { $sh = $found.Source; break }
}
if (-not $sh) {
    $candidates = @()
    foreach ($root in @($env:ProgramFiles, ${env:ProgramFiles(x86)})) {
        if ($root) { $candidates += (Join-Path $root 'Git\bin\sh.exe'); $candidates += (Join-Path $root 'Git\bin\bash.exe') }
    }
    if ($env:LOCALAPPDATA) { $candidates += (Join-Path $env:LOCALAPPDATA 'Programs\Git\bin\sh.exe') }
    $candidates += @('/bin/sh', '/usr/bin/sh')
    foreach ($p in $candidates) {
        if ($p -and (Test-Path -LiteralPath $p)) { $sh = $p; break }
    }
}
if (-not $sh) {
    [Console]::Error.WriteLine('RevRef guard: не найдена POSIX-оболочка (Git Bash, WSL или sh в PATH). Проверить команду нечем: соблюдай правила POLICY.md вручную и сообщи владельцу, что сторожевой хук недоступен.')
    exit 3
}

# Команда передаётся через переменную окружения: так кавычки и пробелы доходят до guard.sh без искажений.
$prevGuardCommand = $env:REVREF_CHECK_COMMAND
$env:REVREF_CHECK_COMMAND = $commandText
# Windows PowerShell 5.1 превращает stderr нативной программы в terminating error при 'Stop'.
$prev = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
& $sh $guard --check-env $Cwd
$code = $LASTEXITCODE
$ErrorActionPreference = $prev
if ($null -eq $prevGuardCommand) { Remove-Item Env:REVREF_CHECK_COMMAND -ErrorAction SilentlyContinue }
else { $env:REVREF_CHECK_COMMAND = $prevGuardCommand }
exit $code
