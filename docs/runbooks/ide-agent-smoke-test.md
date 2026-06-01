# IDE Agent Smoke Test

## Current Validation Scope

This repository is currently validating whether `Claude Code + Claude Code for VS Code + VS Code + Ollama` can complete a real IDE agent workflow with actual tool use.

The current acceptance target is:

- read repository context
- create or modify a file in the workspace
- run a validation command
- return a correct final answer grounded in real actions

## Best Current Candidates For Claude Code Agent Mode

Based on the current compatibility report, the best current candidates are:

- `gemma4:e4b`
- `llama3.2:latest`
- `qwen3:8b-q4_K_M`

These models currently return structured tool calls through the Anthropic-compatible `/v1/messages` endpoint.

## Known Negative Control

The known negative control is:

- `qwen2.5-coder:7b-instruct-q4_K_M`

It is a negative control because it prints tool-call JSON as plain text instead of returning a real structured tool call.

## Compatibility Precheck Command

Run the compatibility precheck with:

```bash
python3 tools/check_ollama_model_compat.py
```

If you need to force the endpoint explicitly:

```bash
OLLAMA_BASE_URL=http://bruter:11434 python3 tools/check_ollama_model_compat.py
```

## Key Context Files

This runbook is based on the current repository validation docs, especially:

- `docs/contracts/vscode-ollama-agent-contract.md`
- `docs/specs/vscode-ollama-agent-spec.md`
- `docs/specs/vscode-ollama-acceptance-scenario.md`
- `docs/ollama-model-compatibility-report.md`
