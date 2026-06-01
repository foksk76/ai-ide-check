# Coder Model Evaluation Runbook

## Purpose

Evaluate local Ollama models for coding work only.

Use the strategy in:

- [Coder Model Benchmark Strategy](../specs/coder-model-benchmark-strategy.md)

## Phase 1: Headless Eligibility

The first proposed third candidate was:

```text
qwen2.5-coder:14b
```

It is excluded: local preflight observed `18%/82% CPU/GPU`, and Claude Code
received printed tool-call JSON instead of structured tool execution.

Run the Claude Code CLI baseline for the current full-GPU coder shortlist:

```powershell
powershell -ExecutionPolicy Bypass -File tools\run_claude_ollama_headless.ps1 `
  -StandId win11-local-rx6800 `
  -Models qwen3:8b-q4_K_M-ctx40k,gemma4:e4b-ctx128k,granite4.1:8b-ctx32k `
  -Stages handshake,tool,agent `
  -RequireFullGpu `
  -TimeoutSeconds 1200
```

Keep:

```text
llama3.2:latest
```

as a negative control only.

Exclude from further coder runs on this stand:

```text
qwen3-coder:latest
qwen3.6:latest
gemma4:26b
qwen2.5-coder:14b
qwen2.5-coder:7b
```

The larger models passed the tool loop but used split CPU and GPU placement.

`qwen2.5-coder:14b` failed both split-placement and real Claude Code tool-loop
gates.

`qwen2.5-coder:7b` passed the full-GPU placement gate with `100% GPU` and
`29/29` layers offloaded. It is still excluded because it printed Bash and
Read requests as plain JSON text instead of executing structured tool calls.

Use the stand-specific Granite profile as the third shortlist candidate:

```powershell
ollama pull granite4.1:8b
ollama create granite4.1:8b-ctx32k `
  -f tools\modelfiles\granite4.1-8b-ctx32k.Modelfile
```

Do not use the upstream `granite4.1:8b` tag directly for this stand. Its
default `131072` token context allocated a `20480 MiB` CPU KV cache, offloaded
`0/41` layers to GPU, and produced `65%/35% CPU/GPU` placement.

The local `granite4.1:8b-ctx32k` profile passed handshake, real Bash tool
execution, repository read, file creation, and git-status grounding at
`100% GPU`. Keep semantic and encoding review enabled: the preflight proof
file contained a mojibake rendering of a non-ASCII hyphen.

### Optional Profile Preflight

Context profiling improved GPU placement for the larger excluded models but
did not return them to the strict shortlist:

```powershell
ollama create qwen3-coder:latest-ctx32k `
  -f tools\modelfiles\qwen3-coder-latest-ctx32k.Modelfile
ollama create qwen3.6:latest-ctx32k `
  -f tools\modelfiles\qwen3.6-latest-ctx32k.Modelfile
ollama create gemma4:26b-ctx32k `
  -f tools\modelfiles\gemma4-26b-ctx32k.Modelfile

powershell -ExecutionPolicy Bypass -File tools\run_claude_ollama_headless.ps1 `
  -StandId win11-local-rx6800 `
  -Models qwen3-coder:latest-ctx32k,qwen3.6:latest-ctx32k,gemma4:26b-ctx32k `
  -Stages handshake `
  -RequireFullGpu `
  -TimeoutSeconds 1200
```

Observed tuned placement:

| Model | Placement | Decision |
|---|---|---|
| `qwen3-coder:latest-ctx32k` | `32%/68% CPU/GPU` | Keep excluded |
| `qwen3.6:latest-ctx32k` | `47%/53% CPU/GPU` | Keep excluded |
| `gemma4:26b-ctx32k` | `29%/71% CPU/GPU` | Keep excluded |

Do not schedule expensive stages after a strict placement failure.

### Favorite-Model Context Profiles

Use an `8192` fixed step and handshake-only sweeps to select placement
profiles. The current results are:

| Model | Selected profile | ctx | Placement | Notes |
|---|---|---:|---|---|
| `qwen3:8b-q4_K_M` | `qwen3:8b-q4_K_M-ctx40k` | `40960` | `100% GPU` | Upstream maximum |
| `gemma4:e4b` | `gemma4:e4b-ctx128k` | `131072` | `100% GPU` | Placement optimum only |
| `granite4.1:8b` | `granite4.1:8b-ctx32k` | `32768` | `100% GPU` | `40960` spills to CPU |

Build the selected local profiles:

```powershell
ollama create qwen3:8b-q4_K_M-ctx40k `
  -f tools\modelfiles\qwen3-8b-q4_K_M-ctx40k.Modelfile
ollama create gemma4:e4b-ctx128k `
  -f tools\modelfiles\gemma4-e4b-ctx128k.Modelfile
ollama create granite4.1:8b-ctx32k `
  -f tools\modelfiles\granite4.1-8b-ctx32k.Modelfile
```

Gemma needs explicit reliability handling: current full-gate controls at both
`32768` and `131072` passed handshake and Bash stages but stopped after the
first `Read` tool in agent stage. This is not a context-size regression.

### Unconventional Candidates

Use the lightweight local profiles:

```powershell
ollama create ministral-3:8b-ctx32k `
  -f tools\modelfiles\ministral-3-8b-ctx32k.Modelfile
ollama create nemotron-3-nano:4b-ctx32k `
  -f tools\modelfiles\nemotron-3-nano-4b-ctx32k.Modelfile
```

`ministral-3:8b-ctx32k` reached a full agent pass on retry at `100% GPU`.
Include it in exploratory coder fixtures and measure repeatability.

`nemotron-3-nano:4b-ctx32k` stayed at `100% GPU` but failed the Claude Code
task flow at every stage. Keep it as a negative control only.

## Phase 2: Local Coder Fixture

Create a deterministic fixture suite before ranking models:

```text
fixtures/coder-bench/
  tasks/
  expected/
  runner/
```

Each task must provide:

- isolated git worktree or copied fixture
- bounded coding prompt
- automated tests
- pass@1 result
- optional one-repair result
- elapsed time
- final-answer review
- `ollama ps` and server-log placement evidence

## Phase 3: External Benchmarks

Use external runners only after local gating:

1. Aider Polyglot for code editing
2. LiveCodeBench subset for generation and self-repair
3. BigCodeBench Instruct for practical code generation
4. SWE-bench Live only for higher-cost repository-agent evaluation

Do not compare external scores unless model identity, benchmark version,
prompting, and scaffold match.

## Required Output

Promote concise evidence into:

```text
docs/runbooks/runs/
```

Keep raw transcripts under:

```text
.artifacts/
```
