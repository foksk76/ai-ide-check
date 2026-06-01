# Windows Local Headless Claude Code + Ollama

## Purpose

Use Claude Code CLI headless mode as the primary repeatable validation path for
the single-host Windows stand. Keep VS Code extension runs as a separate
comparison layer.

## Default Matrix

The default matrix keeps the same three positive API-precheck candidates used
on the Linux stand:

1. `gemma4:e4b`
2. `llama3.2:latest`
3. `qwen3:8b-q4_K_M`

Use `-Models` to run any other installed model explicitly.

## Test Stages

Each model receives one run of each stage:

| Stage | Purpose |
|---|---|
| `handshake` | Verify that Claude Code can obtain a minimal model response. |
| `tool` | Verify real Bash tool execution and command-result grounding. |
| `agent` | Verify repository inspection, file creation, command execution, `git status`, and a grounded final response. |

## Isolation And Permissions

The runner creates one detached temporary git worktree per model and invokes
Claude Code with:

```text
--print
--output-format stream-json
--verbose
--no-session-persistence
--dangerously-skip-permissions
--tools default
```

This intentionally gives the tested agent broad permissions inside a disposable
worktree. The main checkout is not used as the agent workspace.

## Run The Default Matrix

```powershell
powershell -ExecutionPolicy Bypass -File tools\run_claude_ollama_headless.ps1
```

The default stand ID is:

```text
win11-local-rx6800
```

Override it when reusing the runner on another registered stand:

```powershell
powershell -ExecutionPolicy Bypass -File tools\run_claude_ollama_headless.ps1 `
  -StandId another-stand-id `
  -Endpoint http://another-host:11434
```

For coder-only runs on `win11-local-rx6800`, reject CPU or RAM spill:

```powershell
powershell -ExecutionPolicy Bypass -File tools\run_claude_ollama_headless.ps1 `
  -RequireFullGpu
```

Run a single diagnostic model:

```powershell
powershell -ExecutionPolicy Bypass -File tools\run_claude_ollama_headless.ps1 `
  -Models llama3.2:latest `
  -Stages handshake,tool,agent `
  -TimeoutSeconds 600
```

## Explicit Ollama Settings

The runner injects these settings into every Claude Code child process:

```text
ANTHROPIC_AUTH_TOKEN=ollama
ANTHROPIC_API_KEY=ollama
ANTHROPIC_BASE_URL=http://localhost:11434
ANTHROPIC_MODEL=<current model>
ANTHROPIC_DEFAULT_SONNET_MODEL=<current model>
ANTHROPIC_DEFAULT_HAIKU_MODEL=<current model>
CLAUDE_CODE_SUBAGENT_MODEL=<current model>
```

Timeout and output-token settings are also explicit.

## Artifacts

Each run is stored under:

```text
.artifacts/claude-ollama-headless/<timestamp>/
```

The directory includes:

- `manifest.json`
- Ollama version, model inventory, and before/after `ollama ps` snapshots
- local Ollama `server.log` tail after the run when available
- per-stage `ollama ps` snapshots and full-GPU placement verdicts
- prompt text for every model and stage
- Claude Code `stream-json` output
- stderr and Claude Code debug logs
- worktree `git status` and patch snapshots
- `summary.md`

Raw artifacts are intentionally ignored by git. Promote a concise finding into
`docs/runbooks/runs/` when a run becomes decision evidence.

The generated `Passed` value is a mechanical verdict based on tool markers,
file state, and required repository reads. Review the final natural-language
answer manually before declaring a model fully suitable: semantic mistakes can
still survive marker checks.

## Anthropic Surface Probe

Run the deeper Ollama Anthropic Messages compatibility probe with:

```powershell
python tools\check_ollama_anthropic_surface.py
```

The probe runs three attempts per selected model and records:

- basic messages
- system prompts
- multi-turn context
- streaming
- structured tool use
- `tool_result` continuation and grounding
- server-level gaps such as missing token counting and batches

See [Ollama Anthropic API Compatibility For Claude Code](../specs/ollama-anthropic-claude-code-compatibility.md).


## VS Code Comparison Layer

After the headless matrix identifies a viable model, run the same bounded agent
task through Claude Code for VS Code. Record that separately: a VS Code failure
must not overwrite a successful CLI result.

## Coder-Only Next Stage

For coding-model selection, continue with:

- [Coder Model Evaluation Runbook](coder-model-evaluation.md)
