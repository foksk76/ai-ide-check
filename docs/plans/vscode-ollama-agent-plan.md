# Implementation Plan: Local Claude Code + Ollama Validation

## Objective

Select practical local models for `win11-local-rx6800` with evidence from real
Claude Code tool loops, repository edits, tests, and processor placement.

Use Claude Code CLI headless mode as the primary repeatable path. Keep Claude
Code for VS Code as a separate comparison layer.

The coder-only ranking remains the first track. A parallel reverse-engineering
learning track now evaluates models by role: specialized decompilation, routine
analysis, deeper local analysis, and tool-driven quest orchestration.

## Current Position

Completed foundations:

- multi-stand validation contract
- Windows 11 single-host stand snapshot
- Ollama Anthropic Messages surface probe
- Claude Code CLI headless runtime gate
- strict `ollama ps -> 100% GPU` rule for coder tasks
- model-specific context profiling
- two-task coder fixture suite with independent tests
- first coder-quality pass and contract cross-check

Current preliminary coder-quality order:

1. `gpt-oss:20b-ctx32k`
2. `ministral-3:8b-ctx32k`
3. `gemma4:e4b-ctx128k`, capability observed but repeatability unresolved
4. `granite4.1:8b-ctx32k`
5. `qwen3:8b-q4_K_M-ctx40k`, retained as a control after its `0/2` fixture result

Evidence:

- [Agent validation contract](../contracts/vscode-ollama-agent-contract.md)
- [Coder benchmark strategy](../specs/coder-model-benchmark-strategy.md)
- [First coder fixture pass](../runbooks/runs/2026-06-02-coder-fixture-first-pass.md)
- [Reverse-engineering evaluation idea](../specs/reverse-engineering-model-evaluation-idea.md)

## Decision Rules

A model advances only when all applicable gates pass:

| Gate | Required evidence |
|---|---|
| Placement | `ollama ps -> 100% GPU` on `win11-local-rx6800` |
| Runtime | Real structured tools, file operation, shell command, grounded final answer |
| Coder quality | External tests pass; fixture tests remain unchanged |
| Reliability | Repeated attempts are measured; one attractive pass is not enough |
| IDE comparison | VS Code result is recorded separately from CLI evidence |

Do not treat a fixture score as a full agent-contract verdict. The current
fixtures name the source file explicitly and do not prove autonomous
repository discovery.

## Phase 1: Full CLI Contract For The Leaders

Status: next.

Run the complete CLI headless contract scenario for:

1. `gpt-oss:20b-ctx32k`
2. `ministral-3:8b-ctx32k`

The prompt must require:

- repository context reads
- autonomous relevant-file selection without naming the implementation file
- at least one edit
- test execution
- interpretation of the real test result
- final answer matching Git state and command output

Record:

- exact prompt
- versions and endpoint
- environment overrides
- files read and changed
- commands executed
- `ollama ps`
- final answer summary
- pass or fail
- primary failure class when failed

Acceptance:

- both leaders receive at least one full-contract attempt
- GPT-OSS remains the default candidate only if its final answer is grounded
- Ministral remains in the race only if its retry behavior is measured, not
  hand-waved away

## Phase 2: Reliability Pass

Status: after Phase 1.

Extend `tools/run_coder_fixture_bench.ps1` with repeated attempts and promoted
contract metadata.

Minimum run:

- `3` attempts per task
- `gpt-oss:20b-ctx32k`
- `ministral-3:8b-ctx32k`
- `gemma4:e4b-ctx128k` as an instability control

Record per model:

- pass rate
- median and spread of elapsed time
- timeout rate
- structured-tool failure rate
- final-answer mismatch rate
- full-GPU placement rate

Acceptance:

- ranking is based on repeated results
- latency is reported as a distribution, not a single stopwatch reading
- Gemma is promoted only if its textual pseudo-tool regression stops

## Phase 3: Broader Local Coder Suite

Status: after Phase 2.

Add small deterministic fixtures for:

- multi-file bug fix
- one repair attempt after a failing test
- configuration edit
- regression diagnosis
- refactor preserving tests

Keep fixtures dependency-free where practical. Prefer Python standard library
tests for the first expansion.

Acceptance:

- at least one task requires discovering the relevant implementation file
- at least one task requires interpreting and repairing a failed test
- external checks verify code state independently from the model response

## Phase 4: VS Code Comparison

Status: after one CLI leader is stable.

Run the bounded comparison through Claude Code for VS Code with the same local
Ollama endpoint.

Start with:

1. CLI winner
2. CLI runner-up

Record VS Code evidence separately:

- VS Code version
- Claude Code extension version
- selected model
- exact prompt
- files read and changed
- commands executed
- final answer
- pass or fail
- failure class

Acceptance:

- IDE behavior can be compared with CLI behavior without overwriting it
- IDE-only failures are classified as configuration, orchestration, or
  extension-path regressions

## Phase 5: External Benchmarks

Status: only after local gates.

Use external benchmarks as supporting evidence:

1. Aider Polyglot for editing
2. bounded LiveCodeBench subset for generation and repair
3. BigCodeBench Instruct for practical function-level work
4. SWE-bench Live only when runtime cost is acceptable

Do not import public scores as local scores unless model identity, precision,
benchmark version, prompt, scaffold, and attempt count match.

## Parallel Track: Reverse-Engineering Learning Quest

Status: first model preflight completed; static fixture next.

Use the Windows RX 6800 host as the local-model evaluation stand. The Proxmox
VE environment remains the isolated quest stand. Do not deploy firmware or run
dynamic tests until access to that stand is explicitly requested and granted.

Keep the model roles separate:

| Role | Model | Current decision |
|---|---|---|
| Quest orchestration, bounded tool use, patch assistance | `gpt-oss:20b-ctx32k` | Baseline leader: passed the Windows full-GPU gate, coder fixtures, and complete headless contract |
| Fast routine analysis | `rnj-1:8b` | Deferred: `100% GPU`, but the current Ollama path produced invalid output and a sampler panic |
| Lightweight comparison point | `ministral-3:8b-ctx32k` | Keep with limits: coder fixture `2/2`; the full agent step skipped the required repository read |
| Deeper local analysis | `ministral-3:14b-ctx32k` | Deferred on RX 6800: `12%/88% CPU/GPU`, `40/41` layers on GPU |
| Ghidra pseudo-code refinement and assembly-to-C comparison | `llm4decompile:6.7b-v2-q4_K_M` | Import GGUF separately; do not treat as a Claude Code agent |

Keep these as an experimental reserve after the first local matrix:

| Model | Why defer |
|---|---|
| `deepseek-coder-v2:16b` | Useful low-level-code comparison, but Claude Code structured-tool behavior is not yet proven |
| `devstral:24b` | Relevant agentic model, but its `14 GB` artifact leaves little RX 6800 headroom for context |
| `granite4.1:8b-ctx32k` | Existing structured-tool control; coder fixture result was only `1/2` |

Models deferred from the current stand are tracked in
[Prospective Model Configurations](prospective-model-configurations.md).

Recorded preflight results:

| Profile | Placement | Result | Decision |
|---|---|---|---|
| `rnj-1:8b` | `100% GPU`, `33/33` layers | Invalid numeric output and Ollama sampler panic | Retry only after Ollama or template change |
| `ministral-3:14b-ctx32k` | `12%/88% CPU/GPU`, `40/41` layers on GPU | Strict full-GPU gate failed | Retry with lower context or larger VRAM |
| `gpt-oss:20b-ctx32k` | `100% GPU` | Passed `handshake`, `tool`, and `agent` | Keep as full-contract baseline |
| `ministral-3:8b-ctx32k` | `100% GPU` | Passed `handshake` and `tool`; agent skipped required repository read | Keep as limited routine comparator |

Advance a model only when:

- `ollama ps` reports `100% GPU`
- Claude Code executes structured tools instead of printing pseudo-tool JSON
- the final answer matches observed tool output
- analysis claims remain hypotheses until external reproduction

The raw comparison artifacts are retained locally under
`.artifacts/claude-ollama-headless/20260602T201108/`,
`.artifacts/claude-ollama-headless/20260602T195846/`, and
`.artifacts/claude-ollama-headless/20260602T200758/`.

After preflight, add a small static-analysis fixture before touching the
Proxmox VE quest stand:

1. compare raw and refined Ghidra pseudo-code
2. explain the suspected behavior and cite evidence
3. rank the next bounded checks by probability and cost
4. propose a defensive patch
5. run independent regression checks where practical

Only then continue to the isolated firmware quest:

```text
REQUEST STAND ACCESS
```

## Automation Backlog

Improve `tools/run_coder_fixture_bench.ps1`:

- add an attempt-count parameter
- calculate aggregated pass rate and latency distribution
- promote final-answer review markers
- record failure class
- add an autonomous-discovery fixture mode
- retain raw transcripts under `.artifacts/`

Keep concise decision evidence under:

```text
docs/runbooks/runs/
```

## Checkpoints

After each completed phase:

1. Update `CHANGELOG.md`.
2. Review `git diff --staged`.
3. Commit the stage boundary.
4. Push only after explicit review or request.

## Immediate Next Action

Keep the coder-track next action:

```text
gpt-oss:20b-ctx32k
ministral-3:8b-ctx32k
```

The fixture must not name the implementation file. It should force repository
inspection, edit the discovered file, run tests, and report the actual result.

In parallel, run the first static local reverse-engineering fixture with the
accepted profiles. Keep deferred profiles in
[Prospective Model Configurations](prospective-model-configurations.md) until
their matching stand or runtime configuration is available.

Do not request Proxmox VE access yet. The first reverse-engineering artifact
should be a static local fixture and a recorded model-selection result.
