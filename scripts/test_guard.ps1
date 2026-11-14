# Tests for hooks/guard.ps1 and hooks/guard.sh --check — the DSH / PowerShell entry points.
# Run: pwsh ./scripts/test_guard.ps1  (Windows, macOS, Linux; sh is optional).
# The exit code is 0 when every check passes.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$guardPs1 = Join-Path (Join-Path (Join-Path $root 'skill') 'revref') 'hooks/guard.ps1'
$guardSh = Join-Path (Join-Path (Join-Path $root 'skill') 'revref') 'hooks/guard.sh'
$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ('revref-guard-ps-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp | Out-Null
$script:fail = 0
function Ok($m) { Write-Host "ok   $m" }
function Bad($m) { Write-Host "FAIL $m"; $script:fail = 1 }

$pwshExe = (Get-Command pwsh -ErrorAction SilentlyContinue).Source
if (-not $pwshExe) { $pwshExe = (Get-Process -Id $PID).Path }
# On Windows, child processes need Bypass under the default execution policy; pwsh on Unix has no such parameter.
$psArgs = @('-NoProfile')
if ($PSVersionTable.PSVersion.Major -lt 6 -or $IsWindows) { $psArgs += @('-ExecutionPolicy', 'Bypass') }
$psArgs += @('-File', $guardPs1)
$shPath = (Get-Command sh -ErrorAction SilentlyContinue).Source
if (-not $shPath) {
    foreach ($candidate in @("$env:ProgramFiles\Git\bin\sh.exe", "$env:ProgramFiles\Git\bin\bash.exe")) {
        if (Test-Path -LiteralPath $candidate) { $shPath = $candidate; break }
    }
}

# The command goes through REVREF_CHECK_COMMAND: a quoted command in -Command breaks when a child
# Windows PowerShell 5.1 process rebuilds its command line.
function Invoke-GuardPs1([string]$Command, [string]$Cwd) {
    $env:REVREF_CHECK_COMMAND = $Command
    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $null = & $pwshExe @psArgs -Cwd $Cwd 2>&1
    $code = $LASTEXITCODE
    $ErrorActionPreference = $prev
    Remove-Item Env:REVREF_CHECK_COMMAND -ErrorAction SilentlyContinue
    return $code
}

try {
    $repo = Join-Path $tmp 'project'
    New-Item -ItemType Directory -Path (Join-Path $repo '.revref') -Force | Out-Null
    git init -q -b main $repo
    git -C $repo config user.email t@example.com
    git -C $repo config user.name t
    Set-Content -LiteralPath (Join-Path $repo '.revref/STATE.md') -Value '- Checkpoint type: full'
    Set-Content -LiteralPath (Join-Path $repo '.revref/CONFIG.md') -Value '- Main branch: main'
    Set-Content -LiteralPath (Join-Path $repo 'a.txt') -Value 'x'
    git -C $repo add -A
    git -C $repo commit -qm init
    git -C $repo checkout -qb revref/2026-11-07

    $code = Invoke-GuardPs1 'git push --force' $repo
    if ($code -eq 2) { Ok 'guard.ps1 blocks force-push' } else { Bad "guard.ps1 force-push returned $code instead of 2" }
    $code = Invoke-GuardPs1 'git status' $repo
    if ($code -eq 0) { Ok 'guard.ps1 allows git status' } else { Bad "guard.ps1 status returned $code instead of 0" }
    $code = Invoke-GuardPs1 'git commit -m "revref(W2): W2-T01"' $repo
    if ($code -eq 0) { Ok 'guard.ps1 allows a commit on the run branch' } else { Bad "guard.ps1 commit returned $code instead of 0" }

    # Finish consent marker (.revref/FINISH_CONSENT, PROTOCOLS.md §9): the main branch opens only for
    # the merge (action=merge) or the push (action=push) the owner chose; a stale or missing marker blocks.
    $consent = Join-Path $repo '.revref/FINISH_CONSENT'
    git -C $repo checkout -q main
    $code = Invoke-GuardPs1 'git merge --no-ff revref/2026-11-07' $repo
    if ($code -eq 2) { Ok 'guard.ps1 blocks a merge on the main branch without the marker' } else { Bad "guard.ps1 merge without the marker returned $code instead of 2" }
    [System.IO.File]::WriteAllText($consent, "target=main`naction=merge`n")
    $code = Invoke-GuardPs1 'git merge --no-ff revref/2026-11-07' $repo
    if ($code -eq 0) { Ok 'guard.ps1 allows a merge on the main branch with action=merge' } else { Bad "guard.ps1 merge with action=merge returned $code instead of 0" }
    $code = Invoke-GuardPs1 'git push origin main' $repo
    if ($code -eq 2) { Ok 'guard.ps1 still blocks pushing the main branch with action=merge' } else { Bad "guard.ps1 push with action=merge returned $code instead of 2" }
    [System.IO.File]::WriteAllText($consent, "target=main`naction=push`n")
    $code = Invoke-GuardPs1 'git push origin main' $repo
    if ($code -eq 0) { Ok 'guard.ps1 allows pushing the main branch with action=push' } else { Bad "guard.ps1 push with action=push returned $code instead of 0" }
    $code = Invoke-GuardPs1 'git merge --no-ff revref/2026-11-07' $repo
    if ($code -eq 2) { Ok 'guard.ps1 blocks a merge with action=push' } else { Bad "guard.ps1 merge with action=push returned $code instead of 2" }
    Remove-Item -LiteralPath $consent -Force
    $code = Invoke-GuardPs1 'git merge --no-ff revref/2026-11-07' $repo
    if ($code -eq 2) { Ok 'guard.ps1 blocks a merge after the marker is removed' } else { Bad "guard.ps1 merge after the marker was removed returned $code instead of 2" }
    git -C $repo checkout -q revref/2026-11-07

    if ($shPath) {
        $prev = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        $null = & $shPath $guardSh --check 'git push --force' $repo 2>&1
        $code = $LASTEXITCODE
        $ErrorActionPreference = $prev
        if ($code -eq 2) { Ok 'guard.sh --check blocks force-push' } else { Bad "guard.sh --check returned $code instead of 2" }
    } else {
        Write-Host 'note: sh not found — guard.sh --check was not executed'
    }

    $plain = Join-Path $tmp 'plain'
    New-Item -ItemType Directory -Path $plain | Out-Null
    git init -q -b main $plain
    $code = Invoke-GuardPs1 'git push --force' $plain
    if ($code -eq 0) { Ok 'guard.ps1 does not interfere without a run' } else { Bad "guard.ps1 without a run returned $code instead of 0" }
} finally {
    Remove-Item -Recurse -Force -LiteralPath $tmp -ErrorAction SilentlyContinue
}
if ($script:fail -eq 0) { Write-Host 'guard.ps1: all checks passed' } else { Write-Host 'guard.ps1: errors found' }
exit $script:fail
