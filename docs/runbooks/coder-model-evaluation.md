# Coder Model Evaluation Runbook

## Purpose

Evaluate local Ollama models for coding work only.

Use the strategy in:

- [Coder Model Benchmark Strategy](../specs/coder-model-benchmark-strategy.md)

## Phase 1: Headless Eligibility

Pull and verify the third candidate:

```powershell
ollama pull qwen2.5-coder:14b
```

Run the Claude Code CLI baseline for the full-GPU coder shortlist:

```powershell
powershell -ExecutionPolicy Bypass -File tools\run_claude_ollama_headless.ps1 `
  -StandId win11-local-rx6800 `
  -Models qwen3:8b-q4_K_M,gemma4:e4b,qwen2.5-coder:14b `
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
```

They passed the tool loop but used split CPU and GPU placement.

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
