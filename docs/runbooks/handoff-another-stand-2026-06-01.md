# Handoff For Continuation On Another Stand

## Current Goal

Validate the real IDE agent chain:

- `Claude Code`
- `Claude Code for VS Code`
- `VS Code`
- `Ollama`
- remote endpoint on `bruter`

The key question is not basic API reachability. It is whether this stack can complete a real agent workflow in the IDE:

- read repo context
- write the correct file
- run a command
- return a grounded final answer

## Current Repository State

This repository already contains:

- contract: [docs/contracts/vscode-ollama-agent-contract.md](/home/krl/git/check_sip/docs/contracts/vscode-ollama-agent-contract.md:1)
- stage spec: [docs/specs/vscode-ollama-agent-spec.md](/home/krl/git/check_sip/docs/specs/vscode-ollama-agent-spec.md:1)
- acceptance scenario: [docs/specs/vscode-ollama-acceptance-scenario.md](/home/krl/git/check_sip/docs/specs/vscode-ollama-acceptance-scenario.md:1)
- environment matrix: [docs/specs/vscode-ollama-environment-matrix.md](/home/krl/git/check_sip/docs/specs/vscode-ollama-environment-matrix.md:1)
- failure taxonomy: [docs/specs/vscode-ollama-failure-taxonomy.md](/home/krl/git/check_sip/docs/specs/vscode-ollama-failure-taxonomy.md:1)
- model run log: [docs/runbooks/vscode-ollama-model-run-log.md](/home/krl/git/check_sip/docs/runbooks/vscode-ollama-model-run-log.md:1)
- compatibility checker: [tools/check_ollama_model_compat.py](/home/krl/git/check_sip/tools/check_ollama_model_compat.py:1)
- live capture helper: [tools/bruter_ollama_capture.sh](/home/krl/git/check_sip/tools/bruter_ollama_capture.sh:1)

## Current Proven Facts

### Endpoint

- `bruter` is reachable on `http://bruter:11434`
- Ollama is healthy on the server
- server-side transport is functioning
- `tcpdump` capture on `bruter` works

### API Precheck

Current structured-tool precheck winners:

- `gemma4:e4b`
- `llama3.2:latest`
- `qwen3:8b-q4_K_M`

Known negative control:

- `qwen2.5-coder:7b-instruct-q4_K_M`

The precheck report is in:

- [docs/ollama-model-compatibility-report.md](/home/krl/git/check_sip/docs/ollama-model-compatibility-report.md:1)

### IDE Reality So Far

`run-001` on `gemma4:e4b`

- failed
- model asked a clarifying question instead of starting the bounded task

`run-002` on `llama3.2:latest`

- failed
- live capture proved the IDE sent the full task-bearing request with tools
- response ended almost immediately and did not become a useful agent action

`run-003` on `qwen3:8b-q4_K_M`

- failed
- model attempted `Write test.txt`
- then fell into generic `EACCES` advice about `/home/user`

Detailed records:

- [run-001](/home/krl/git/check_sip/docs/runbooks/runs/2026-06-01-run-001-gemma4-e4b.md)
- [run-002](/home/krl/git/check_sip/docs/runbooks/runs/2026-06-01-run-002-llama3.2-latest.md)
- [run-003](/home/krl/git/check_sip/docs/runbooks/runs/2026-06-01-run-003-qwen3-8b-q4_K_M.md)

## Strongest Current Interpretation

The main blocker is no longer believed to be:

- network connectivity
- Ollama server health
- basic Anthropic-compatible endpoint support

The strongest current suspects are:

1. model behavior under the real IDE request envelope
2. polluted IDE request context
3. session orchestration inside `Claude Code for VS Code`

Important evidence:

- the IDE sends title-generation requests first with `tools: []`
- later it sends a much larger task-bearing request
- stale `ide_selection` context was observed in capture
- at least one captured request referenced `run-001` while testing `run-003`

## Best Next Step On Another Stand

Do a clean-room rerun instead of just switching models again.

### Clean-Room Conditions

- new machine or fresh VS Code profile
- no prior Claude Code session history in the panel
- no active text selection in the editor
- no old run record open as selected text
- open only the repo root and the active run document needed for the test

### Minimal Execution Plan

1. Confirm preflight:
   - `python3 tools/check_ollama_model_compat.py`
   - `curl http://bruter:11434/api/tags`
2. Start live capture:
   - `tools/bruter_ollama_capture.sh start <label>`
3. Use the exact acceptance prompt from:
   - [docs/specs/vscode-ollama-acceptance-scenario.md](/home/krl/git/check_sip/docs/specs/vscode-ollama-acceptance-scenario.md:1)
4. Prefer testing only one candidate first in the new clean room:
   - `qwen3:8b-q4_K_M`
5. Stop live capture:
   - `tools/bruter_ollama_capture.sh stop <pcap-path>`
6. Record the run in a fresh run note based on:
   - [docs/runbooks/vscode-ollama-run-record-template.md](/home/krl/git/check_sip/docs/runbooks/vscode-ollama-run-record-template.md:1)

## Recommended Priority On Another Stand

1. `qwen3:8b-q4_K_M`
   Reason: most recent candidate with real tool attempt, even though it was mis-grounded
2. `llama3.2:latest`
   Reason: useful comparison if clean-room conditions remove context pollution
3. `qwen2.5-coder:7b-instruct-q4_K_M`
   Reason: negative control, only if a contrast run is needed

## What To Watch Closely

During the next capture, inspect:

- whether the IDE still sends stale `ide_selection`
- whether the task-bearing request still contains unrelated session baggage
- whether the model writes to the requested target path
- whether the model uses repo-grounded context instead of generic fallback text

## Success Criteria For The New Stand

Treat the new stand as successful only if one model:

- creates `docs/runbooks/ide-agent-smoke-test.md`
- uses repository facts
- runs `python3 tools/check_ollama_model_compat.py`
- reports the real result correctly

If none of the models can do that under clean-room conditions, the working conclusion should be:

- the current IDE integration/request envelope is not reliable for local Ollama-backed agent mode on this stack

## Recommended First Files To Read After Handoff

1. [docs/runbooks/bruter-api-debug-2026-06-01.md](/home/krl/git/check_sip/docs/runbooks/bruter-api-debug-2026-06-01.md:1)
2. [docs/runbooks/vscode-ollama-model-run-log.md](/home/krl/git/check_sip/docs/runbooks/vscode-ollama-model-run-log.md:1)
3. [docs/specs/vscode-ollama-acceptance-scenario.md](/home/krl/git/check_sip/docs/specs/vscode-ollama-acceptance-scenario.md:1)
4. [docs/runbooks/bruter-live-capture.md](/home/krl/git/check_sip/docs/runbooks/bruter-live-capture.md:1)
