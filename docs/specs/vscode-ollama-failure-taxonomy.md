# Failure Taxonomy: VS Code Agent + Ollama

## Objective

Provide one shared failure language for IDE validation runs so that each failed run can be triaged quickly and consistently.

Each run should be assigned one primary failure class, even if secondary symptoms also exist.

## Primary Failure Classes

| Class | Meaning | Typical symptom | First checks |
|---|---|---|---|
| `config` | Misconfiguration in VS Code, extension, auth, or endpoint settings | session cannot start or target wrong endpoint/model | verify VS Code config, endpoint variables, selected model |
| `api` | Anthropic-compatible API behavior is missing, malformed, or inconsistent | `/v1/messages` errors, malformed response shape, timeout, reset | rerun compatibility script, inspect server logs |
| `model-tools` | Model answers but does not produce real structured tool use | tool JSON printed as text, no `tool_use`, `does not support tools` | compare `/v1/messages` vs `/api/chat`, review report |
| `workspace-write` | Agent cannot create or modify files in the repo | reads work, but file creation/editing fails | inspect workspace permissions and IDE session behavior |
| `command-exec` | Agent cannot run or correctly interpret required commands | skips command, command errors unexpectedly, misreads output | run command locally, inspect shell access and timeout behavior |
| `final-answer` | Actions occur, but the final response is factually wrong | file exists but agent says it failed, or vice versa | compare transcript, file state, and command result |

## Detailed Taxonomy

### `config`

Definition:

- The environment is not actually targeting the intended validation setup.

Examples:

- wrong base URL
- wrong model selected
- missing extension enablement
- missing session permissions

Signals:

- request goes to unexpected endpoint
- session never reaches the model
- extension opens but tools are unavailable before the model is even tested

Checks:

```bash
curl http://bruter:11434/api/tags
git status --short
ssh root@bruter 'systemctl is-active ollama'
```

### `api`

Definition:

- The transport path between IDE agent and Ollama does not behave as required by Claude-compatible tooling.

Examples:

- `/v1/messages` returns error
- connection reset
- malformed message content shape
- timeout under normal load

Signals:

- compatibility script fails on basic chat or tools test
- same model behaves differently between native and Anthropic-compatible endpoints

Checks:

```bash
python3 tools/check_ollama_model_compat.py
ssh root@bruter 'journalctl -u ollama -n 200 --no-pager'
ssh root@bruter 'tcpdump -i any -s 0 -w /tmp/ollama-agent-debug.pcap port 11434'
```

### `model-tools`

Definition:

- The model is reachable and may even chat correctly, but cannot perform structured tool calling required for agent mode.

Examples:

- prints JSON tool call as plain text
- explains intended tool usage without issuing tool call
- returns `does not support tools`
- asks a clarification question instead of starting a bounded task that already contains enough instructions

Signals:

- negative compatibility result in the report
- IDE chat appears coherent, but no real file or command actions occur
- the reply stays conversational and never transitions into repository reads, file writes, or command execution

Checks:

- review [docs/ollama-model-compatibility-report.md](/home/krl/git/check_sip/docs/ollama-model-compatibility-report.md:1)
- compare candidate model against the positive shortlist

### `workspace-write`

Definition:

- The agent cannot complete the required file mutation step in the workspace.

Examples:

- agent reads files but cannot create `docs/runbooks/ide-agent-smoke-test.md`
- write tool exists but fails in practice

Signals:

- directory listing works
- file creation silently fails or is denied
- final answer claims write success but file is absent

Checks:

```bash
test -d docs && echo docs_ok
git status --short
```

### `command-exec`

Definition:

- The agent cannot complete or interpret the required command execution step.

Examples:

- `python3 tools/check_ollama_model_compat.py` is never run
- command is run but output is ignored or misread
- shell tool timeouts make the run inconclusive

Signals:

- file write succeeds, but the validation command is skipped
- agent hallucinates command success

Checks:

```bash
python3 --version
python3 tools/check_ollama_model_compat.py
```

### `final-answer`

Definition:

- The agent performs some or all required actions, but the concluding report is inaccurate.

Examples:

- says file was created when it was not
- says command failed when it succeeded
- names wrong compatible models

Signals:

- transcript and workspace disagree
- command output and final summary disagree

Checks:

- compare final answer to actual file state
- compare final answer to command output

## Decision Rules

Use these rules to choose the primary class:

1. If the endpoint or session is misconfigured before model behavior is meaningfully tested, use `config`.
2. If the endpoint path itself is broken or malformed, use `api`.
3. If the endpoint works but the model cannot produce structured tool use, use `model-tools`.
4. If tool use exists but file mutation fails, use `workspace-write`.
5. If file mutation works but command execution fails, use `command-exec`.
6. If actions succeed but the final report is wrong, use `final-answer`.

## Known Examples From Current Repo State

| Model | Likely class if used for IDE scenario | Why |
|---|---|---|
| `gemma4:e4b` | none expected | current positive candidate |
| `llama3.2:latest` | none expected | current positive candidate |
| `qwen2.5-coder:7b-instruct-q4_K_M` | `model-tools` | prints tool-call JSON as text |
| `gemma3:12b-it-q4_K_M` | `model-tools` or `api` depending on surface | tools unsupported |

## Evidence Package for Any Failed Run

Collect:

- model name
- endpoint used
- exact start prompt
- IDE transcript or summary
- file state after run
- command output
- primary failure class
- supporting evidence

## Escalation Path

1. Re-run the compatibility precheck.
2. Re-check the environment matrix.
3. Inspect Ollama logs on `bruter`.
4. Capture traffic on `bruter` if behavior is still ambiguous.

Use with:

- [docs/specs/vscode-ollama-environment-matrix.md](/home/krl/git/check_sip/docs/specs/vscode-ollama-environment-matrix.md:1)
- [docs/specs/vscode-ollama-acceptance-scenario.md](/home/krl/git/check_sip/docs/specs/vscode-ollama-acceptance-scenario.md:1)
