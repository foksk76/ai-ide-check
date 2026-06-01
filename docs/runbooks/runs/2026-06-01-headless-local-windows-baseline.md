# Run Record: Windows Local Headless Baseline

## Run Identity

- Date: `2026-06-01`
- Stand: Windows single-host local Ollama
- Repository commit used for disposable worktrees: `b4ed5d04945be8f17493792729c3c4bc4387684e`
- Endpoint: `http://localhost:11434`
- Claude Code CLI: `2.1.158`
- Permission mode: `bypassPermissions`
- Session persistence: disabled
- Attempts per model and stage: `1`

## Purpose

Establish Claude Code CLI headless mode as the primary repeatable test layer
before repeating selected cases through Claude Code for VS Code.

## Default Model Matrix

The baseline used the same API-precheck-positive candidates carried over from
the Linux stand:

1. `gemma4:e4b`
2. `llama3.2:latest`
3. `qwen3:8b-q4_K_M`

## Full Three-Stage Matrix

Raw artifacts:

```text
.artifacts/claude-ollama-headless/20260601T185605/
```

| Model | Handshake | Bash tool | Agent artifact | Initial verdict |
|---|---|---|---|---|
| `gemma4:e4b` | Pass | Pass | Pass | Candidate |
| `llama3.2:latest` | Fail | Fail | Fail | Reject for current Claude Code headless flow |
| `qwen3:8b-q4_K_M` | Pass | Pass | Pass | Candidate |

`llama3.2:latest` returned an empty completed turn with `output_tokens: 1`.
This reproduces the earlier Linux IDE symptom without VS Code in the request
path.

## Scenario Correction

The first agent prompt used:

```text
git diff --stat
```

That command does not show a newly created untracked file. Both successful
models completed the write but inferred more than the command output proved.

The runner was corrected to require:

- `Read` of `CHANGELOG.md`
- file creation
- Python existence check
- `git status --short`
- exact git-status output in the final answer

## Strict Agent Rerun

Raw artifacts:

```text
.artifacts/claude-ollama-headless/20260601T190449/
```

| Model | Read observed | File created | Python marker | Git status marker | Mechanical verdict | Manual final-answer review |
|---|---|---|---|---|---|---|
| `gemma4:e4b` | Yes | Yes | `HEADLESS_AGENT_OK True` | `?? docs/runbooks/headless-agent-proof.md` | Pass | Partial: correctly included the output but called the untracked file staged |
| `llama3.2:latest` | No | No | Missing | Missing | Fail | Empty completed turn with `output_tokens: 1` |
| `qwen3:8b-q4_K_M` | Yes | Yes | `HEADLESS_AGENT_OK True` | `?? docs/runbooks/headless-agent-proof.md` | Pass | Pass: correctly reported the file as untracked |

## Current Interpretation

- `qwen3:8b-q4_K_M` is the strongest local headless candidate from this run.
- `gemma4:e4b` can execute the tool loop but still needs final-answer semantic
  review.
- `llama3.2:latest` is not currently usable in Claude Code headless mode even
  though earlier API-level structured tool checks passed.
- The VS Code extension is no longer required to reproduce the
  `llama3.2:latest` failure.

## Next Comparison Layer

Run the bounded VS Code comparison scenario first with:

1. `qwen3:8b-q4_K_M`
2. `gemma4:e4b`

Keep the IDE outcome separate from the CLI verdict.
