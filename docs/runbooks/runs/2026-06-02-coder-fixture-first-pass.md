# Run Record: Local Coder Fixture First Pass

## Question

Which of the five full-GPU RX 6800 profiles can solve a small coder-only task
set when the final result is checked by tests outside the model session?

## Method

- Date: `2026-06-02`
- Stand: `win11-local-rx6800`
- Endpoint: `http://localhost:11434`
- Gate: `ollama ps -> 100% GPU`
- Tasks:
  - `normalize-tags`: implement a function with validation and edge cases
  - `merge-ranges`: repair sorting, validation, and touching-range behavior
- Model attempts: one per task
- External check: `python -m unittest discover -s tests -v`

The first matrix run generated all ten isolated solutions. The initial runner
invoked its independent test replay from the wrong directory. The generated
workspaces were preserved, the runner was corrected, and the tests were
replayed against those exact workspaces without asking the models to generate
new code.

Primary artifacts:

```text
.artifacts/coder-fixture-bench/20260602T043714/
```

Runner-control artifact after the fix:

```text
.artifacts/coder-fixture-bench/20260602T052904/
.artifacts/coder-fixture-bench/20260602T053133/
```

## Replayed Result

| Model | `normalize-tags` | `merge-ranges` | Score | Seconds | Placement |
|---|---|---|---:|---:|---|
| `gpt-oss:20b-ctx32k` | Pass | Pass | `2/2` | `293.846` | `100% GPU` |
| `ministral-3:8b-ctx32k` | Pass | Pass | `2/2` | `817.652` | `100% GPU` |
| `gemma4:e4b-ctx128k` | Pass | Pass | `2/2` | `298.284` | `100% GPU` |
| `granite4.1:8b-ctx32k` | Pass | Fail | `1/2` | `374.293` | `100% GPU` |
| `qwen3:8b-q4_K_M-ctx40k` | Fail | Fail | `0/2` | `1252.961` | `100% GPU` |

## Failure Notes

Granite and Qwen both left the touching-range defect in place:

```python
start <= merged[-1][1]
```

The required behavior needs adjacent integer ranges to merge too.

For `normalize-tags`, Qwen repeatedly attempted an `Edit` operation with text
that did not match the file, reran failing tests, and then incorrectly reported
success without changing the source file.

## Repeatability Control

After correcting the runner, `gemma4:e4b-ctx128k` received a second
`normalize-tags` attempt. It emitted a textual pseudo-`Read` action instead of
executing the structured tool call and left the file unchanged. The external
tests failed.

Treat Gemma's `2/2` score as a useful capability signal, not a reliability
claim.

The final runner control used `gpt-oss:20b-ctx32k` on `normalize-tags`. The
corrected runner recorded `Passed=True`, test exit code `0`, unchanged tests,
and `100% GPU`. The repeated task took `720.705` seconds versus `133.784`
seconds in the first matrix. Treat single latency samples as indicative only.

## Decision

Use `gpt-oss:20b-ctx32k` as the leading profile for the next coder fixture
stage. Keep `ministral-3:8b-ctx32k` as the second reliable candidate. Expand
the suite and add repeated attempts before making a final default-model
decision.

## Contract Cross-Check

This fixture is a coder-quality `Level 1` run. Its `Pass` value means that the
external tests passed, the tests were not edited, and the model stayed at
`100% GPU`. It is not a standalone pass for the full agent contract in:

- [Claude Code + Ollama Stand Validation](../../contracts/vscode-ollama-agent-contract.md)

The full contract also requires autonomous repository discovery, relevant-file
selection without manual routing, command-result interpretation, and a final
answer matching the real workspace state. This fixture names the source file
in its prompt, so it deliberately does not test autonomous file selection.

| Contract input or behavior | Evidence in this run | Status |
|---|---|---|
| Registered `stand_id` | `win11-local-rx6800` | Covered |
| Validation layer | Claude Code CLI headless coder fixture | Covered |
| Endpoint | `http://localhost:11434` in `manifest.json` | Covered |
| Model | Exact profile recorded per result | Covered |
| Exact prompt | Saved beside every case | Covered |
| Timeout | `900` seconds in `manifest.json` | Covered |
| Permission mode | Runner uses `--dangerously-skip-permissions` | Covered |
| Relevant environment overrides | Runner injects local Anthropic variables | Covered by runner, not copied into the manifest |
| Disposable git workspace | Fresh fixture repository per model and task | Covered |
| Read existing context | Structured `Read` observed in the primary matrix | Covered |
| Identify relevant files autonomously | Source file named in prompt | Not tested |
| Edit at least one file | Source diff captured for successful primary cases | Covered |
| Run a validation command | Model transcript and independent replay captured | Covered |
| Interpret real command result | Transcript review required per case | Partially covered |
| Final answer matches state and command output | Transcript review required per case | Partially covered |
| Processor placement | `ollama ps` captured per case | Covered |
| VS Code comparison | CLI fixture only | Out of scope |

The promoted run record is still missing some fields required by the generic
contract output: topology summary, full component versions, a concise
per-case file list, command list, final-answer summary, and failure class.
Those remain available partly in raw artifacts, but the next runner revision
should promote them automatically. The runner has now been extended to record
the topology summary, validation layer, permission mode, redacted environment,
prompt path, validation command, transcript paths, diff path, and
processor-placement snapshot in future artifacts.

## Contract-Level Findings

Do not label all five profiles agent-compatible from this fixture alone.
Combine this coder-quality evidence with the earlier `Level 0` headless gate.

| Model | Fixture signal | Contract observation | Primary failure class when applicable |
|---|---|---|---|
| `gpt-oss:20b-ctx32k` | `2/2` and positive runner control | Best candidate for the next full contract run | none observed |
| `ministral-3:8b-ctx32k` | `2/2` | Keep candidate status; repeatability was already a concern in Level 0 | none in this fixture |
| `gemma4:e4b-ctx128k` | `2/2`, then failed repeat | Repeat emitted textual pseudo-`Read` and made no edit | `model-tools` |
| `granite4.1:8b-ctx32k` | `1/2` | Reported a correction after a failing run without applying it | `final-answer` |
| `qwen3:8b-q4_K_M-ctx40k` | `0/2` | Claimed success for `normalize-tags` although the file was unchanged and tests failed | `final-answer` |

The next comparison should run the full contract scenario for GPT-OSS and
Ministral, then add repeated coder tasks. A VS Code run remains a separate
comparison layer rather than a substitute for the CLI evidence.
