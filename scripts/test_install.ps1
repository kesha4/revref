# Test of install.ps1: both languages, hook path substitution, the installed hook blocks, uninstall.
# Run: pwsh ./scripts/test_install.ps1  or  powershell -File scripts/test_install.ps1. Exit code 0 — all checks passed.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("revref-ps-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp | Out-Null
$script:fail = 0
function Ok($m) { Write-Host "ok   $m" }
function Bad($m) { Write-Host "FAIL $m"; $script:fail = 1 }
$sh = Get-Command sh -ErrorAction SilentlyContinue
$shPath = if ($sh) { $sh.Source } else { $null }
if (-not $shPath) {
    foreach ($candidate in @("$env:ProgramFiles\Git\bin\sh.exe", "$env:ProgramFiles\Git\bin\bash.exe")) {
        if (Test-Path -LiteralPath $candidate) { $shPath = $candidate; break }
    }
}

# A repository with an active run, to check that the installed hook fires.
$repo = Join-Path $tmp 'project'
New-Item -ItemType Directory -Path (Join-Path $repo '.revref') -Force | Out-Null
git init -q -b main $repo
Set-Content -LiteralPath (Join-Path $repo '.revref/STATE.md') -Value '- Checkpoint type: full'
$repoJson = ($repo -replace '\\', '\\')
$payload = '{"tool_name":"Bash","tool_input":{"command":"git push --force"},"cwd":"' + $repoJson + '"}'

try {
    foreach ($lang in 'ru', 'en') {
        $cfg = Join-Path $tmp "cfg-$lang"
        $env:CLAUDE_CONFIG_DIR = $cfg
        & (Join-Path $root 'install.ps1') -Lang $lang | Out-Null
        $skill = Join-Path (Join-Path $cfg 'skills') 'revref'
        $srcSkill = if ($lang -eq 'en') { Join-Path (Join-Path $root 'skill-en') 'revref' } else { Join-Path (Join-Path $root 'skill') 'revref' }
        $expected = (Get-ChildItem -Recurse -File -LiteralPath $srcSkill).Count + 2   # + CHANGELOG.md, INSTALL
        $actual = (Get-ChildItem -Recurse -File -LiteralPath $skill).Count
        if ($actual -eq $expected) { Ok "[$lang] skill files: $actual" } else { Bad "[$lang] skill files $actual, expected $expected" }
        $files = @(Join-Path $skill 'SKILL.md') + (@('revref-reviewer.md', 'revref-verifier.md', 'revref-fixer.md') | ForEach-Object { Join-Path (Join-Path $cfg 'agents') $_ })
        foreach ($f in $files) {
            $text = [System.IO.File]::ReadAllText($f)
            if ($text.Contains('__REVREF_SKILL_DIR__')) { Bad "[$lang] placeholder not replaced: $f" }
            if ([System.IO.File]::ReadAllBytes($f)[0] -eq 0xEF) { Bad "[$lang] BOM written into $f (breaks frontmatter)" }
            $m = [regex]::Match($text, "(?m)^ *command: '(.*)'\s*$")
            if (-not $m.Success) { Bad "[$lang] no hook command in $f"; continue }
            if ($shPath) {
                # Windows PowerShell 5.1 turns native stderr into a terminating error under 'Stop'.
                $prev = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
                $null = $payload | & $shPath -c $m.Groups[1].Value 2>&1
                $code = $LASTEXITCODE
                $ErrorActionPreference = $prev
                if ($code -eq 2) { Ok "[$lang] hook from $(Split-Path -Leaf $f) blocks force-push" } else { Bad "[$lang] hook from $f returned $code instead of 2" }
            }
        }
        if ((Test-Path (Join-Path $skill 'VERSION')) -and (Test-Path (Join-Path $skill 'CHANGELOG.md'))) { Ok "[$lang] VERSION and CHANGELOG present" } else { Bad "[$lang] VERSION or CHANGELOG missing" }
        & (Join-Path $root 'install.ps1') -Lang $lang | Out-Null
        if (Get-ChildItem -Directory -LiteralPath (Join-Path $cfg 'skills') -Filter 'revref.bak-*') { Ok "[$lang] reinstall kept a backup" } else { Bad "[$lang] no backup on reinstall" }
        & (Join-Path $root 'install.ps1') -Uninstall | Out-Null
        if (-not (Test-Path $skill) -and -not (Test-Path (Join-Path (Join-Path $cfg 'agents') 'revref-fixer.md'))) { Ok "[$lang] uninstall" } else { Bad "[$lang] uninstall left files" }
    }
    # DSH: installs into the DSH home, without agents, with platform=dsh; and into a project.
    foreach ($lang in 'ru', 'en') {
        $dshHome = Join-Path $tmp "dsh-$lang"
        $env:DSH_HOME = $dshHome
        & (Join-Path $root 'install.ps1') -Dsh -Lang $lang | Out-Null
        $skill = Join-Path (Join-Path $dshHome 'skills') 'revref'
        if (Test-Path (Join-Path $skill 'SKILL.md')) { Ok "[$lang] DSH: skill installed" } else { Bad "[$lang] DSH: no SKILL.md" }
        if (Test-Path (Join-Path $skill 'hooks/guard.ps1')) { Ok "[$lang] DSH: guard.ps1 present" } else { Bad "[$lang] DSH: no hooks/guard.ps1" }
        if (-not (Test-Path (Join-Path $dshHome 'agents'))) { Ok "[$lang] DSH: agents are not installed" } else { Bad "[$lang] DSH: agents folder appeared" }
        if ((Get-Content -LiteralPath (Join-Path $skill 'INSTALL') -Raw) -match '(?m)^platform=dsh$') { Ok "[$lang] DSH: INSTALL has platform=dsh" } else { Bad "[$lang] DSH: INSTALL has no platform" }
        if ([System.IO.File]::ReadAllText((Join-Path $skill 'SKILL.md')).Contains('__REVREF_SKILL_DIR__')) { Bad "[$lang] DSH: placeholder not replaced" } else { Ok "[$lang] DSH: hook path substituted" }
        & (Join-Path $root 'install.ps1') -Dsh -Uninstall | Out-Null
        if (-not (Test-Path $skill)) { Ok "[$lang] DSH: uninstall" } else { Bad "[$lang] DSH: uninstall left files" }
    }
    Remove-Item Env:DSH_HOME -ErrorAction SilentlyContinue
    $dshProj = Join-Path $tmp 'dsh proj'
    New-Item -ItemType Directory -Path $dshProj | Out-Null
    & (Join-Path $root 'install.ps1') -Dsh -Project $dshProj | Out-Null
    if (Test-Path (Join-Path $dshProj '.dsh/skills/revref/SKILL.md')) { Ok 'DSH: install into a project (<path>/.dsh/skills)' } else { Bad 'DSH: install into a project' }

    Remove-Item Env:CLAUDE_CONFIG_DIR
    $proj = Join-Path $tmp 'proj dir'
    New-Item -ItemType Directory -Path $proj | Out-Null
    & (Join-Path $root 'install.ps1') -Project $proj | Out-Null
    if (Test-Path (Join-Path $proj '.claude/skills/revref/SKILL.md')) { Ok 'install into a project (path with a space)' } else { Bad 'install into a project' }
    if (-not $shPath) { Write-Host 'note: sh not found — the installed hook command was not executed' }
} finally {
    Remove-Item Env:CLAUDE_CONFIG_DIR -ErrorAction SilentlyContinue
    Remove-Item -Recurse -Force -LiteralPath $tmp -ErrorAction SilentlyContinue
}
if ($script:fail -eq 0) { Write-Host 'install.ps1: all checks passed' } else { Write-Host 'install.ps1: errors found' }
exit $script:fail
