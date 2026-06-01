[CmdletBinding()]
param(
    [string[]]$Models = @(
        "gemma4:e4b",
        "llama3.2:latest",
        "qwen3:8b-q4_K_M"
    ),
    [string[]]$Stages = @("handshake", "tool", "agent"),
    [string]$Endpoint = "http://localhost:11434",
    [int]$TimeoutSeconds = 600,
    [string]$ArtifactsRoot = ".artifacts\claude-ollama-headless",
    [switch]$KeepWorktrees
)

$ErrorActionPreference = "Stop"
$Models = @($Models | ForEach-Object { $_ -split "," } | Where-Object { $_ })
$Stages = @($Stages | ForEach-Object { $_ -split "," } | Where-Object { $_ })
$validStages = @("handshake", "tool", "agent")
foreach ($stage in $Stages) {
    if ($stage -notin $validStages) {
        throw "Unknown stage '$stage'. Valid stages: $($validStages -join ', ')."
    }
}

function Convert-ToSafeName {
    param([string]$Value)
    return ($Value -replace "[^A-Za-z0-9._-]", "_")
}

function Write-JsonFile {
    param(
        [Parameter(Mandatory = $true)]$Value,
        [Parameter(Mandatory = $true)][string]$Path
    )
    $Value | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $Path -Encoding UTF8
}

function Convert-ToPowerShellLiteral {
    param([string]$Value)
    return "'" + ($Value -replace "'", "''") + "'"
}

function Get-StagePrompt {
    param([string]$Stage)
    switch ($Stage) {
        "handshake" {
            return @"
Reply with exactly:
HEADLESS_HANDSHAKE_OK

Do not use tools. Do not add explanation.
"@
        }
        "tool" {
            return @"
Use the Bash tool to run this command in the current workspace:
python -c "print('HEADLESS_TOOL_OK')"

Then report whether the command succeeded and include its exact output.
"@
        }
        "agent" {
            return @"
Work autonomously in this disposable git worktree. Inspect the repository, then:

1. Use the Read tool to read CHANGELOG.md.
2. Create docs/runbooks/headless-agent-proof.md.
3. In that file, state that this is a Claude Code headless Ollama smoke-test artifact.
4. Include the local endpoint http://localhost:11434.
5. Use the Bash tool to run:
   python -c "from pathlib import Path; print('HEADLESS_AGENT_OK', Path('docs/runbooks/headless-agent-proof.md').exists())"
6. Use the Bash tool to run:
   git status --short
7. Return a concise final answer grounded in the actual command results. Include the exact git status output.

You have permission to inspect files, modify this disposable worktree, and run commands as needed.
"@
        }
    }
}

function Invoke-ClaudeStage {
    param(
        [string]$ClaudeExe,
        [string]$Model,
        [string]$Stage,
        [string]$Worktree,
        [string]$StageDirectory,
        [int]$Timeout
    )

    New-Item -ItemType Directory -Path $StageDirectory -Force | Out-Null
    $promptPath = Join-Path $StageDirectory "prompt.txt"
    $stdoutPath = Join-Path $StageDirectory "stdout.stream.jsonl"
    $stderrPath = Join-Path $StageDirectory "stderr.txt"
    $debugPath = Join-Path $StageDirectory "claude-debug.log"
    $exitCodePath = Join-Path $StageDirectory "exit-code.txt"
    $wrapperPath = Join-Path $StageDirectory "invoke-claude.ps1"
    Get-StagePrompt $Stage | Set-Content -LiteralPath $promptPath -Encoding UTF8

    $arguments = @(
        "--print",
        "--model", $Model,
        "--output-format", "stream-json",
        "--verbose",
        "--no-session-persistence",
        "--dangerously-skip-permissions",
        "--tools", "default",
        "--debug-file", $debugPath
    )
    $argumentLiterals = $arguments | ForEach-Object { Convert-ToPowerShellLiteral $_ }
    @(
        '$ErrorActionPreference = "Continue"'
        ('& {0} {1}' -f (Convert-ToPowerShellLiteral $ClaudeExe), ($argumentLiterals -join " "))
        '$claudeExitCode = $LASTEXITCODE'
        'if ($null -eq $claudeExitCode) { $claudeExitCode = 0 }'
        ('Set-Content -LiteralPath {0} -Value $claudeExitCode -Encoding ASCII' -f (Convert-ToPowerShellLiteral $exitCodePath))
        'exit $claudeExitCode'
    ) | Set-Content -LiteralPath $wrapperPath -Encoding UTF8

    $startedAt = Get-Date
    $process = Start-Process `
        -FilePath "powershell.exe" `
        -ArgumentList @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $wrapperPath) `
        -WorkingDirectory $Worktree `
        -RedirectStandardInput $promptPath `
        -RedirectStandardOutput $stdoutPath `
        -RedirectStandardError $stderrPath `
        -PassThru `
        -WindowStyle Hidden

    $timedOut = -not $process.WaitForExit($Timeout * 1000)
    if ($timedOut) {
        & taskkill.exe /PID $process.Id /T /F | Out-Null
        $process.WaitForExit()
    } else {
        $process.WaitForExit()
    }
    $process.Refresh()

    $endedAt = Get-Date
    $targetPath = Join-Path $Worktree "docs\runbooks\headless-agent-proof.md"
    $gitStatusPath = Join-Path $StageDirectory "git-status.txt"
    $gitDiffPath = Join-Path $StageDirectory "git-diff.patch"
    $targetArtifactPath = Join-Path $StageDirectory "target-file.md"
    (& git -C $Worktree status --short | Out-String) |
        Set-Content -LiteralPath $gitStatusPath -Encoding UTF8
    (& git -C $Worktree diff --binary | Out-String) |
        Set-Content -LiteralPath $gitDiffPath -Encoding UTF8
    if (Test-Path -LiteralPath $targetPath) {
        Copy-Item -LiteralPath $targetPath -Destination $targetArtifactPath
    }

    $exitCode = if ($timedOut -or -not (Test-Path -LiteralPath $exitCodePath)) {
        $null
    } else {
        [int](Get-Content -LiteralPath $exitCodePath -Raw)
    }
    $transcript = Get-Content -LiteralPath $stdoutPath -Raw
    $expectedMarker = switch ($Stage) {
        "handshake" { "HEADLESS_HANDSHAKE_OK" }
        "tool" { "HEADLESS_TOOL_OK" }
        "agent" { "HEADLESS_AGENT_OK True" }
    }
    $markerObserved = $transcript.Contains($expectedMarker)
    $passed = (-not $timedOut) -and ($exitCode -eq 0) -and $markerObserved
    if ($Stage -eq "agent") {
        $readObserved = $transcript.Contains('"name":"Read"') -and $transcript.Contains("CHANGELOG.md")
        $statusObserved = $transcript.Contains("?? docs/runbooks/headless-agent-proof.md")
        $passed = $passed -and (Test-Path -LiteralPath $targetPath) -and $readObserved -and $statusObserved
    } else {
        $readObserved = $null
        $statusObserved = $null
    }
    $result = [ordered]@{
        stage = $Stage
        model = $Model
        started_at = $startedAt.ToString("o")
        ended_at = $endedAt.ToString("o")
        elapsed_seconds = [math]::Round(($endedAt - $startedAt).TotalSeconds, 3)
        timeout_seconds = $Timeout
        timed_out = $timedOut
        exit_code = $exitCode
        expected_marker = $expectedMarker
        marker_observed = $markerObserved
        repository_read_observed = $readObserved
        git_status_marker_observed = $statusObserved
        passed = $passed
        target_file_exists = Test-Path -LiteralPath $targetPath
        prompt = $promptPath
        stdout = $stdoutPath
        stderr = $stderrPath
        debug_log = $debugPath
        exit_code_file = $exitCodePath
        wrapper = $wrapperPath
        git_status = $gitStatusPath
        git_diff = $gitDiffPath
        target_file_artifact = if (Test-Path -LiteralPath $targetArtifactPath) { $targetArtifactPath } else { $null }
    }
    Write-JsonFile $result (Join-Path $StageDirectory "result.json")
    return $result
}

$repoRoot = (& git rev-parse --show-toplevel).Trim()
if (-not $repoRoot) {
    throw "Run this script from inside the ai-ide-check git repository."
}

$claudeExe = (Get-Command claude -ErrorAction Stop).Source
$runStamp = Get-Date -Format "yyyyMMddTHHmmss"
$artifactsBase = Join-Path $repoRoot $ArtifactsRoot
$runDirectory = Join-Path $artifactsBase $runStamp
$worktreeBase = Join-Path ([System.IO.Path]::GetTempPath()) "ai-ide-check-headless-$runStamp"
New-Item -ItemType Directory -Path $runDirectory -Force | Out-Null
New-Item -ItemType Directory -Path $worktreeBase -Force | Out-Null

$originalEnvironment = @{}
$configuredEnvironment = [ordered]@{
    ANTHROPIC_AUTH_TOKEN = "ollama"
    ANTHROPIC_API_KEY = "ollama"
    ANTHROPIC_BASE_URL = $Endpoint
    ANTHROPIC_MODEL = ""
    ANTHROPIC_DEFAULT_SONNET_MODEL = ""
    ANTHROPIC_DEFAULT_HAIKU_MODEL = ""
    CLAUDE_CODE_SUBAGENT_MODEL = ""
    API_TIMEOUT_MS = [string]($TimeoutSeconds * 1000)
    BASH_DEFAULT_TIMEOUT_MS = [string]($TimeoutSeconds * 1000)
    BASH_MAX_TIMEOUT_MS = [string]($TimeoutSeconds * 1000)
    CLAUDE_CODE_MAX_OUTPUT_TOKENS = "4096"
}

foreach ($entry in $configuredEnvironment.GetEnumerator()) {
    $originalEnvironment[$entry.Key] = [Environment]::GetEnvironmentVariable($entry.Key, "Process")
    [Environment]::SetEnvironmentVariable($entry.Key, $entry.Value, "Process")
}

$summaryRows = @()
try {
    & curl.exe --silent --show-error --fail "$Endpoint/api/version" |
        Set-Content -LiteralPath (Join-Path $runDirectory "ollama-version.json") -Encoding UTF8
    & curl.exe --silent --show-error --fail "$Endpoint/api/tags" |
        Set-Content -LiteralPath (Join-Path $runDirectory "ollama-tags.json") -Encoding UTF8
    & ollama ps |
        Set-Content -LiteralPath (Join-Path $runDirectory "ollama-ps-before.txt") -Encoding UTF8

    $manifest = [ordered]@{
        captured_at = (Get-Date).ToString("o")
        repository = $repoRoot
        repository_commit = (& git -C $repoRoot rev-parse HEAD).Trim()
        endpoint = $Endpoint
        models = $Models
        stages = $Stages
        timeout_seconds = $TimeoutSeconds
        claude_executable = $claudeExe
        claude_version = (& $claudeExe --version | Out-String).Trim()
        permission_mode = "bypassPermissions"
        session_persistence = $false
        artifact_root = $runDirectory
        environment = [ordered]@{
            ANTHROPIC_AUTH_TOKEN = "<redacted>"
            ANTHROPIC_API_KEY = "<redacted>"
            ANTHROPIC_BASE_URL = $Endpoint
            API_TIMEOUT_MS = $configuredEnvironment.API_TIMEOUT_MS
            BASH_DEFAULT_TIMEOUT_MS = $configuredEnvironment.BASH_DEFAULT_TIMEOUT_MS
            BASH_MAX_TIMEOUT_MS = $configuredEnvironment.BASH_MAX_TIMEOUT_MS
            CLAUDE_CODE_MAX_OUTPUT_TOKENS = $configuredEnvironment.CLAUDE_CODE_MAX_OUTPUT_TOKENS
        }
    }
    Write-JsonFile $manifest (Join-Path $runDirectory "manifest.json")

    foreach ($model in $Models) {
        $safeModel = Convert-ToSafeName $model
        $modelDirectory = Join-Path $runDirectory $safeModel
        $worktree = Join-Path $worktreeBase $safeModel
        New-Item -ItemType Directory -Path $modelDirectory -Force | Out-Null

        & git -C $repoRoot worktree add --detach $worktree HEAD |
            Set-Content -LiteralPath (Join-Path $modelDirectory "worktree-add.txt") -Encoding UTF8
        try {
            [Environment]::SetEnvironmentVariable("ANTHROPIC_MODEL", $model, "Process")
            [Environment]::SetEnvironmentVariable("ANTHROPIC_DEFAULT_SONNET_MODEL", $model, "Process")
            [Environment]::SetEnvironmentVariable("ANTHROPIC_DEFAULT_HAIKU_MODEL", $model, "Process")
            [Environment]::SetEnvironmentVariable("CLAUDE_CODE_SUBAGENT_MODEL", $model, "Process")

            foreach ($stage in $Stages) {
                $stageDirectory = Join-Path $modelDirectory $stage
                $result = Invoke-ClaudeStage $claudeExe $model $stage $worktree $stageDirectory $TimeoutSeconds
                $summaryRows += [pscustomobject]$result
            }
        }
        finally {
            if (-not $KeepWorktrees) {
                $resolvedWorktreeBase = [System.IO.Path]::GetFullPath($worktreeBase)
                $resolvedWorktree = [System.IO.Path]::GetFullPath($worktree)
                if (-not $resolvedWorktree.StartsWith($resolvedWorktreeBase, [System.StringComparison]::OrdinalIgnoreCase)) {
                    throw "Refusing to remove worktree outside expected temp root: $resolvedWorktree"
                }
                & git -C $repoRoot worktree remove --force $resolvedWorktree
            }
        }
    }

    & ollama ps |
        Set-Content -LiteralPath (Join-Path $runDirectory "ollama-ps-after.txt") -Encoding UTF8

    $markdown = @(
        "# Claude Code Headless Ollama Run"
        ""
        ('- Captured at: `{0}`' -f (Get-Date -Format o))
        ('- Endpoint: `{0}`' -f $Endpoint)
        ('- Artifacts: `{0}`' -f $runDirectory)
        '- Permission mode: `bypassPermissions`'
        "- Session persistence: disabled"
        ""
        "| Model | Stage | Exit | Timed out | Seconds | Target file exists | Passed |"
        "|---|---|---:|---|---:|---|---|"
    )
    foreach ($row in $summaryRows) {
        $markdown += "| ``$($row.model)`` | ``$($row.stage)`` | ``$($row.exit_code)`` | ``$($row.timed_out)`` | ``$($row.elapsed_seconds)`` | ``$($row.target_file_exists)`` | ``$($row.passed)`` |"
    }
    $markdown -join "`r`n" |
        Set-Content -LiteralPath (Join-Path $runDirectory "summary.md") -Encoding UTF8
    $summaryRows | Format-Table model, stage, exit_code, timed_out, elapsed_seconds, target_file_exists, passed -AutoSize
    Write-Host "Artifacts: $runDirectory"
}
finally {
    foreach ($entry in $configuredEnvironment.GetEnumerator()) {
        [Environment]::SetEnvironmentVariable($entry.Key, $originalEnvironment[$entry.Key], "Process")
    }
}
