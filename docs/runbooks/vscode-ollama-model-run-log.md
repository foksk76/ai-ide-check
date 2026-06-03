# VS Code + Ollama Model Run Log

## Purpose

This log is the central registry of IDE validation runs for candidate Ollama models.

Use it together with:

- [docs/archive/early-vscode-validation/vscode-ollama-acceptance-scenario.md](../archive/early-vscode-validation/vscode-ollama-acceptance-scenario.md)
- [docs/archive/early-vscode-validation/vscode-ollama-environment-matrix.md](../archive/early-vscode-validation/vscode-ollama-environment-matrix.md)
- [docs/archive/early-vscode-validation/vscode-ollama-failure-taxonomy.md](../archive/early-vscode-validation/vscode-ollama-failure-taxonomy.md)
- [docs/runbooks/vscode-ollama-run-record-template.md](../runbooks/vscode-ollama-run-record-template.md)

## Status Summary

| Model | Preflight API status | IDE run status | Result | Primary failure class | Notes |
|---|---|---|---|---|---|
| `gemma4:e4b` | Pass | Completed | Fail | `model-tools` | Asked clarifying question and performed no actions in IDE |
| `llama3.2:latest` | Pass | Completed | Fail | `model-tools` | Live capture proved the full task was sent, but no useful agent action followed |
| `qwen3:8b-q4_K_M` | Pass | Completed | Fail | `workspace-write` | Attempted wrong-path write (`test.txt`) and then gave generic permission advice |
| `qwen2.5-coder:7b-instruct-q4_K_M` | Fail for structured tools | Not run yet | Pending negative control | `model-tools` expected | Should print tool JSON as text |
| `gemma3:12b-it-q4_K_M` | Fail for tools support | Not scheduled | Pending | `model-tools` or `api` | Documentation-only reference |

## Run Order

Execute IDE runs in this order:

1. `gemma4:e4b`
2. `llama3.2:latest`
3. `qwen3:8b-q4_K_M`
4. `qwen2.5-coder:7b-instruct-q4_K_M`

Only schedule `gemma3:12b-it-q4_K_M` if there is a specific reason to document a non-agent-compatible run.

## Run Table

| Run ID | Date | Model | Endpoint | Preflight | IDE Result | Failure Class | Target File Created | Command Ran | Final Answer Accurate | Evidence Link | Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|
| `run-001` | 2026-06-01 | `gemma4:e4b` | `http://bruter:11434` | pass | fail | `model-tools` | no | no | no | `docs/runbooks/runs/2026-06-01-run-001-gemma4-e4b.md` | Asked clarification question instead of starting the bounded task |
| `run-002` | 2026-06-01 | `llama3.2:latest` | `http://bruter:11434` | pass | fail | `model-tools` | no | no | no | `docs/runbooks/runs/2026-06-01-run-002-llama3.2-latest.md` | Live capture showed the full task-bearing request was sent, but the response ended without useful action |
| `run-003` | 2026-06-01 | `qwen3:8b-q4_K_M` | `http://bruter:11434` | pass | fail | `workspace-write` | no | no | no | `docs/runbooks/runs/2026-06-01-run-003-qwen3-8b-q4_K_M.md` | Attempted `Write test.txt`, failed, then gave generic `EACCES` advice |
| `run-004` | pending | `qwen2.5-coder:7b-instruct-q4_K_M` | `http://bruter:11434` | pending | pending | expected `model-tools` | pending | pending | pending | pending | Negative control |

## Recording Rules

- Create one detailed run record from the template for every IDE run.
- Update this table immediately after the run ends.
- If the run fails, assign exactly one primary failure class.
- If the run is ambiguous, mark `IDE Result` as `inconclusive` until diagnostics complete.
- If logs or captures were taken, note the artifact path in `Evidence Link`.

## Success Condition For This Log

This log becomes decision-ready when:

- both positive candidates have completed at least one IDE run
- any additional positive candidate has been either validated or explicitly deprioritized
- the negative control has completed one IDE run
- every run has a linked detailed record
- pass/fail outcomes are stable enough to recommend a default IDE model

## Recommended Next Step

For the next real IDE execution:

1. Copy [docs/runbooks/vscode-ollama-run-record-template.md](../runbooks/vscode-ollama-run-record-template.md) into a dated run note.
2. Use a fresh record for the negative control `qwen2.5-coder:7b-instruct-q4_K_M` if you want a final contrast run.
3. Otherwise, treat the current evidence as sufficient to conclude that positive API precheck does not predict successful IDE agent behavior.
4. Update this log immediately after any additional run.
