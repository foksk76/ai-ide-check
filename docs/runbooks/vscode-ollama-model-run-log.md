# VS Code + Ollama Model Run Log

## Purpose

This log is the central registry of IDE validation runs for candidate Ollama models.

Use it together with:

- [docs/specs/vscode-ollama-acceptance-scenario.md](/home/krl/git/check_sip/docs/specs/vscode-ollama-acceptance-scenario.md:1)
- [docs/specs/vscode-ollama-environment-matrix.md](/home/krl/git/check_sip/docs/specs/vscode-ollama-environment-matrix.md:1)
- [docs/specs/vscode-ollama-failure-taxonomy.md](/home/krl/git/check_sip/docs/specs/vscode-ollama-failure-taxonomy.md:1)
- [docs/runbooks/vscode-ollama-run-record-template.md](/home/krl/git/check_sip/docs/runbooks/vscode-ollama-run-record-template.md:1)

## Status Summary

| Model | Preflight API status | IDE run status | Result | Primary failure class | Notes |
|---|---|---|---|---|---|
| `gemma4:e4b` | Pass | Not run yet | Pending | n/a | First positive candidate |
| `llama3.2:latest` | Pass | Not run yet | Pending | n/a | Second positive candidate |
| `qwen2.5-coder:7b-instruct-q4_K_M` | Fail for structured tools | Not run yet | Pending negative control | `model-tools` expected | Should print tool JSON as text |
| `gemma3:12b-it-q4_K_M` | Fail for tools support | Not scheduled | Pending | `model-tools` or `api` | Documentation-only reference |

## Run Order

Execute IDE runs in this order:

1. `gemma4:e4b`
2. `llama3.2:latest`
3. `qwen2.5-coder:7b-instruct-q4_K_M`

Only schedule `gemma3:12b-it-q4_K_M` if there is a specific reason to document a non-agent-compatible run.

## Run Table

| Run ID | Date | Model | Endpoint | Preflight | IDE Result | Failure Class | Target File Created | Command Ran | Final Answer Accurate | Evidence Link | Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|
| `run-001` | pending | `gemma4:e4b` | `http://bruter:11434` | pending | pending | n/a | pending | pending | pending | pending | First positive candidate |
| `run-002` | pending | `llama3.2:latest` | `http://bruter:11434` | pending | pending | n/a | pending | pending | pending | pending | Second positive candidate |
| `run-003` | pending | `qwen2.5-coder:7b-instruct-q4_K_M` | `http://bruter:11434` | pending | pending | expected `model-tools` | pending | pending | pending | pending | Negative control |

## Recording Rules

- Create one detailed run record from the template for every IDE run.
- Update this table immediately after the run ends.
- If the run fails, assign exactly one primary failure class.
- If the run is ambiguous, mark `IDE Result` as `inconclusive` until diagnostics complete.
- If logs or captures were taken, note the artifact path in `Evidence Link`.

## Success Condition For This Log

This log becomes decision-ready when:

- both positive candidates have completed at least one IDE run
- the negative control has completed one IDE run
- every run has a linked detailed record
- pass/fail outcomes are stable enough to recommend a default IDE model

## Recommended Next Step

For the first real IDE execution:

1. Copy [docs/runbooks/vscode-ollama-run-record-template.md](/home/krl/git/check_sip/docs/runbooks/vscode-ollama-run-record-template.md:1) into a dated run note.
2. Run the acceptance scenario with `gemma4:e4b`.
3. Update this log immediately after the run.
