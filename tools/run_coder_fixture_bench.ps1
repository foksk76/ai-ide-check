[CmdletBinding()]
param(
    [string[]]$Models = @(
        "qwen3:8b-q4_K_M-ctx40k",
        "granite4.1:8b-ctx32k",
        "gemma4:e4b-ctx128k",
        "ministral-3:8b-ctx32k",
        "gpt-oss:20b-ctx32k"
    ),
    [string[]]$Tasks = @("normalize-tags", "merge-ranges"),
    [string]$StandId = "win11-local-rx6800",
    [string]$Endpoint = "http://localhost:11434",
    [int]$TimeoutSeconds = 900,
    [string]$ArtifactsRoot = ".artifacts\coder-fixture-bench",
    [switch]$RequireFullGpu
)

$ErrorActionPreference = "Stop"
$Models = @($Models | ForEach-Object { $_ -split "," } | Where-Object { $_ })
$Tasks = @($Tasks | ForEach-Object { $_ -split "," } | Where-Object { $_ })

function Convert-ToSafeName {
    param([string]$Value)
    return ($Value -replace "[^A-Za-z0-9._-]", "_")
}

function Convert-ToPowerShellLiteral {
    param([string]$Value)
    return "'" + ($Value -replace "'", "''") + "'"
}

function Write-JsonFile {
    param($Value, [string]$Path)
    $Value | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $Path -Encoding UTF8
}

$repoRoot = (& git rev-parse --show-toplevel).Trim()
$claudeExe = (Get-Command claude -ErrorAction Stop).Source
$pythonExe = (Get-Command python -ErrorAction Stop).Source
$runStamp = Get-Date -Format "yyyyMMddTHHmmss"
$runDirectory = Join-Path (Join-Path $repoRoot $ArtifactsRoot) $runStamp
$taskRoot = Join-Path $repoRoot "fixtures\coder-bench\tasks"
New-Item -ItemType Directory -Path $runDirectory -Force | Out-Null

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
$originalEnvironment = @{}
foreach ($entry in $configuredEnvironment.GetEnumerator()) {
    $originalEnvironment[$entry.Key] = [Environment]::GetEnvironmentVariable($entry.Key, "Process")
    [Environment]::SetEnvironmentVariable($entry.Key, $entry.Value, "Process")
}

$results = @()
try {
    $manifest = [ordered]@{
        captured_at = (Get-Date).ToString("o")
        stand_id = $StandId
        validation_layer = "claude-code-cli-headless-coder-fixture"
        topology_summary = "VS Code, Claude Code CLI, Ollama, models, and AMD Radeon RX 6800 on one Windows host"
        endpoint = $Endpoint
        models = $Models
        tasks = $Tasks
        timeout_seconds = $TimeoutSeconds
        permission_mode = "bypassPermissions"
        require_full_gpu = [bool]$RequireFullGpu
        claude_version = (& $claudeExe --version | Out-String).Trim()
        python_version = (& $pythonExe --version | Out-String).Trim()
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
        [Environment]::SetEnvironmentVariable("ANTHROPIC_MODEL", $model, "Process")
        [Environment]::SetEnvironmentVariable("ANTHROPIC_DEFAULT_SONNET_MODEL", $model, "Process")
        [Environment]::SetEnvironmentVariable("ANTHROPIC_DEFAULT_HAIKU_MODEL", $model, "Process")
        [Environment]::SetEnvironmentVariable("CLAUDE_CODE_SUBAGENT_MODEL", $model, "Process")

        foreach ($task in $Tasks) {
            $template = Join-Path $taskRoot $task
            if (-not (Test-Path -LiteralPath $template)) {
                throw "Unknown task template: $template"
            }

            $caseDirectory = Join-Path $runDirectory "$(Convert-ToSafeName $model)\$task"
            $workspace = Join-Path $caseDirectory "workspace"
            New-Item -ItemType Directory -Path $workspace -Force | Out-Null
            Copy-Item -Path (Join-Path $template "*") -Destination $workspace -Recurse
            Copy-Item -LiteralPath (Join-Path $template "prompt.txt") -Destination (Join-Path $caseDirectory "prompt.txt")

            & git -C $workspace init --quiet
            & git -C $workspace config user.email "coder-bench@localhost"
            & git -C $workspace config user.name "Coder Bench"
            & git -C $workspace add .
            & git -C $workspace commit --quiet -m "fixture baseline"

            $stdoutPath = Join-Path $caseDirectory "stdout.stream.jsonl"
            $stderrPath = Join-Path $caseDirectory "stderr.txt"
            $debugPath = Join-Path $caseDirectory "claude-debug.log"
            $exitCodePath = Join-Path $caseDirectory "exit-code.txt"
            $wrapperPath = Join-Path $caseDirectory "invoke-claude.ps1"
            $promptPath = Join-Path $caseDirectory "prompt.txt"
            $testOutputPath = Join-Path $caseDirectory "unittest.txt"
            $testStdoutPath = Join-Path $caseDirectory "unittest.stdout.txt"
            $testStderrPath = Join-Path $caseDirectory "unittest.stderr.txt"
            $statusPath = Join-Path $caseDirectory "git-status.txt"
            $diffPath = Join-Path $caseDirectory "git-diff.patch"
            $ollamaPsPath = Join-Path $caseDirectory "ollama-ps.txt"

            $arguments = @(
                "--print",
                "--model", $model,
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
                ('& {0} {1}' -f (Convert-ToPowerShellLiteral $claudeExe), ($argumentLiterals -join " "))
                '$claudeExitCode = $LASTEXITCODE'
                'if ($null -eq $claudeExitCode) { $claudeExitCode = 0 }'
                ('Set-Content -LiteralPath {0} -Value $claudeExitCode -Encoding ASCII' -f (Convert-ToPowerShellLiteral $exitCodePath))
                'exit $claudeExitCode'
            ) | Set-Content -LiteralPath $wrapperPath -Encoding UTF8

            $startedAt = Get-Date
            $process = Start-Process `
                -FilePath "powershell.exe" `
                -ArgumentList @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $wrapperPath) `
                -WorkingDirectory $workspace `
                -RedirectStandardInput $promptPath `
                -RedirectStandardOutput $stdoutPath `
                -RedirectStandardError $stderrPath `
                -PassThru `
                -WindowStyle Hidden
            $timedOut = -not $process.WaitForExit($TimeoutSeconds * 1000)
            if ($timedOut) {
                & taskkill.exe /PID $process.Id /T /F | Out-Null
                $process.WaitForExit()
            }
            $endedAt = Get-Date

            $testProcess = Start-Process `
                -FilePath $pythonExe `
                -ArgumentList @("-m", "unittest", "discover", "-s", "tests", "-v") `
                -WorkingDirectory $workspace `
                -RedirectStandardOutput $testStdoutPath `
                -RedirectStandardError $testStderrPath `
                -PassThru `
                -Wait `
                -WindowStyle Hidden
            $testsExitCode = $testProcess.ExitCode
            @(
                Get-Content -LiteralPath $testStdoutPath -Raw
                Get-Content -LiteralPath $testStderrPath -Raw
            ) -join "`r`n" | Set-Content -LiteralPath $testOutputPath -Encoding UTF8
            (& git -C $workspace status --short | Out-String) |
                Set-Content -LiteralPath $statusPath -Encoding UTF8
            (& git -C $workspace diff --binary | Out-String) |
                Set-Content -LiteralPath $diffPath -Encoding UTF8
            (& ollama ps | Out-String) |
                Set-Content -LiteralPath $ollamaPsPath -Encoding UTF8

            $claudeExitCode = if ($timedOut -or -not (Test-Path -LiteralPath $exitCodePath)) {
                $null
            } else {
                [int](Get-Content -LiteralPath $exitCodePath -Raw)
            }
            $ollamaPs = Get-Content -LiteralPath $ollamaPsPath -Raw
            $fullGpuObserved = $ollamaPs.Contains($model) -and $ollamaPs.Contains("100% GPU")
            $changedFiles = @(& git -C $workspace diff --name-only)
            $testsChanged = @($changedFiles | Where-Object { $_ -like "tests/*" }).Count -gt 0
            $passed = (-not $timedOut) -and ($testsExitCode -eq 0) -and (-not $testsChanged)
            if ($RequireFullGpu) {
                $passed = $passed -and $fullGpuObserved
            }

            $result = [ordered]@{
                model = $model
                task = $task
                started_at = $startedAt.ToString("o")
                ended_at = $endedAt.ToString("o")
                elapsed_seconds = [math]::Round(($endedAt - $startedAt).TotalSeconds, 3)
                timeout_seconds = $TimeoutSeconds
                timed_out = $timedOut
                claude_exit_code = $claudeExitCode
                tests_exit_code = $testsExitCode
                tests_changed = $testsChanged
                full_gpu_required = [bool]$RequireFullGpu
                full_gpu_observed = $fullGpuObserved
                changed_files = $changedFiles
                prompt = $promptPath
                validation_command = "python -m unittest discover -s tests -v"
                stdout = $stdoutPath
                stderr = $stderrPath
                git_status = $statusPath
                git_diff = $diffPath
                ollama_ps = $ollamaPsPath
                passed = $passed
            }
            Write-JsonFile $result (Join-Path $caseDirectory "result.json")
            $results += [pscustomobject]$result
        }
    }

    $results | Export-Csv -LiteralPath (Join-Path $runDirectory "summary.csv") -NoTypeInformation -Encoding UTF8
    $markdown = @(
        "# Local Coder Fixture Bench"
        ""
        ('- Captured at: `{0}`' -f (Get-Date -Format o))
        ('- Stand ID: `{0}`' -f $StandId)
        ('- Artifacts: `{0}`' -f $runDirectory)
        ""
        "| Model | Task | Seconds | Claude exit | Tests exit | Tests changed | Full GPU | Passed |"
        "|---|---|---:|---:|---:|---|---|---|"
    )
    foreach ($row in $results) {
        $markdown += "| ``$($row.model)`` | ``$($row.task)`` | ``$($row.elapsed_seconds)`` | ``$($row.claude_exit_code)`` | ``$($row.tests_exit_code)`` | ``$($row.tests_changed)`` | ``$($row.full_gpu_observed)`` | ``$($row.passed)`` |"
    }
    $markdown -join "`r`n" |
        Set-Content -LiteralPath (Join-Path $runDirectory "summary.md") -Encoding UTF8
    $results | Format-Table model, task, elapsed_seconds, tests_exit_code, tests_changed, full_gpu_observed, passed -AutoSize
    Write-Host "Artifacts: $runDirectory"
}
finally {
    foreach ($entry in $configuredEnvironment.GetEnumerator()) {
        [Environment]::SetEnvironmentVariable($entry.Key, $originalEnvironment[$entry.Key], "Process")
    }
}
