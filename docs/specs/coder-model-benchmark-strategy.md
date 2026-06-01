# Coder Model Benchmark Strategy

## Scope

Evaluate Ollama models for coder tasks only.

Documentation writing, general chat, image understanding, and broad reasoning
are out of scope for the current stage except when they are required to finish
a coding task correctly.

## Decision Question

Which model should be used as the default coding agent on each registered
stand?

The answer must combine:

1. external benchmark evidence
2. exact local model identity
3. local API and tool-loop compatibility
4. local repository-editing results
5. latency and processor-placement evidence

Do not promote a model from a public leaderboard score alone.

## Why Multiple Benchmarks Are Required

Coder performance is not one capability.

| Capability | Typical task | Required evaluation type |
|---|---|---|
| Function generation | Implement a function from a specification | Code-generation benchmark |
| Practical code generation | Use libraries and APIs from a complex prompt | Software-oriented code-generation benchmark |
| Self-repair | Fix code after test failures | Repair benchmark |
| File editing | Modify existing files while preserving contracts | Editing benchmark |
| Repository agent work | Read context, edit files, run tests, recover from errors | Issue-resolution or local agent benchmark |
| Tool-loop grounding | Interpret shell output and workspace state correctly | Local Claude Code headless benchmark |

A small model can pass simple generation tests and still fail in Claude Code.
The local `llama3.2:latest` results already demonstrate this risk.

## Open Benchmark Map

### Tier A: Repository-Level Agent Evaluation

#### SWE-bench

- Source: [official site](https://www.swebench.com/)
- Repository: [SWE-bench organization](https://github.com/swe-bench)
- Task shape: resolve real GitHub issues in repositories
- Best use here: architecture reference for local repository-level tasks
- Caution: compare agent scaffold, prompt, tool budget, and dataset split before
  comparing scores

#### SWE-bench Live

- Paper: [SWE-bench Goes Live](https://arxiv.org/abs/2505.23419)
- Task shape: fresh repository issues and patches collected over time
- Best use here: contamination-resistant direction for future long-running
  evaluation

### Tier B: Code Editing Evaluation

#### Aider Polyglot

- Leaderboard: [Aider LLM Leaderboards](https://aider.chat/docs/leaderboards/)
- Method note: [polyglot benchmark announcement](https://aider.chat/2024/12/21/polyglot.html)
- Task shape: edit solutions for `225` difficult Exercism tasks
- Languages: C++, Go, Java, JavaScript, Python, Rust
- Useful metrics:
  - percent correct
  - pass rate after repair
  - correct edit format
- Best use here: external reference for editing ability and instruction
  following

### Tier C: Code Generation And Repair Evaluation

#### LiveCodeBench

- Repository: [LiveCodeBench](https://github.com/LiveCodeBench/LiveCodeBench)
- Paper: [LiveCodeBench](https://arxiv.org/abs/2403.07974)
- Task shape:
  - code generation
  - self-repair
  - code execution
  - test-output prediction
- Data source: continuously collected contest tasks
- Best use here: algorithmic coding and repair signal with reduced static-set
  contamination risk

#### BigCodeBench

- Leaderboard: [BigCodeBench](https://bigcode-bench.github.io/)
- Repository: [bigcode-project/bigcodebench](https://github.com/bigcode-project/bigcodebench)
- Task shape: `1140` software-engineering-oriented function-level tasks with
  complex instructions and diverse function calls
- Splits:
  - `Complete`
  - `Instruct`
- Best use here: practical code-generation signal beyond HumanEval-style
  toy functions

## Published Scores And Exact-Match Policy

Only record a public score as a score for a local model when all of these match:

- model family
- parameter count
- instruct or base variant
- quantization or precision when relevant
- benchmark version
- prompt or scaffold
- number of attempts

Otherwise record the score as family context only.

Example:

- a score for `Qwen3-Coder-480B-A35B-Instruct` is not a score for local
  `qwen3-coder:latest` with `30.5B` total parameters and `Q4_K_M`
- a score for Gemma 3 is not a score for local `gemma4:e4b`
- a score for Llama 3.2 3B in a code-generation suite does not override a local
  Claude Code agent failure

## Local Installed Coder Candidate Inventory

Captured from local Ollama `/api/show`:

| Local model | Parameters | Quantization | Capabilities | Public score handling |
|---|---:|---|---|---|
| `llama3.2:latest` | `3.2B` | `Q4_K_M` | completion, tools | Family-level code-generation references may be used cautiously; local Claude Code agent mode is currently rejected |
| `qwen3:8b-q4_K_M` | `8.2B` | `Q4_K_M` | completion, tools, thinking | Treat public Qwen3 family scores as context only unless exact variant matches |
| `qwen3-coder:latest` | `30.5B` | `Q4_K_M` | completion, tools | High-priority local coder candidate; do not import scores from much larger Qwen3-Coder variants |
| `qwen3.6:latest` | `36.0B` | `Q4_K_M` | completion, vision, tools, thinking | High-priority local coder candidate; require local evidence |
| `gemma4:26b` | `25.8B` | `Q4_K_M` | completion, vision, tools, thinking | Secondary local coder candidate; require local evidence |
| `gemma4:e4b` | `8.0B` | `Q4_K_M` | completion, vision, audio, tools, thinking | Existing secondary Claude Code candidate; require local coder-task evidence |

## Current Evidence

Existing local headless evidence covers tool-loop viability, not coding quality:

| Model | Existing headless agent result | Coder-quality conclusion |
|---|---|---|
| `qwen3:8b-q4_K_M` | Pass | Eligible for coder benchmark |
| `gemma4:e4b` | Mechanical pass with final-answer wording defect | Eligible with semantic review |
| `llama3.2:latest` | Empty completed turns | Reject for Claude Code coder agent mode |

The larger local models have not yet completed the same Claude Code headless
baseline.

## Full-GPU Gate For `win11-local-rx6800`

The next coder benchmark stage excludes models with CPU or RAM spill.

Required placement:

```text
ollama ps -> 100% GPU
```

Models excluded after the expanded eligibility run:

| Model | Observed placement | Decision |
|---|---|---|
| `qwen3-coder:latest` | `67%/33% CPU/GPU` | Exclude |
| `qwen3.6:latest` | `58%/42% CPU/GPU` | Exclude |
| `gemma4:26b` | `44%/56% CPU/GPU` | Exclude |

These models passed the tool loop, but they are too large for the selected
single-GPU operating rule.

Keep:

| Model | Full-GPU evidence |
|---|---|
| `qwen3:8b-q4_K_M` | `offloaded 37/37 layers to GPU` |
| `gemma4:e4b` | `offloaded 43/43 layers to GPU` |

Add as the third candidate:

```text
qwen2.5-coder:14b
```

Why:

- official Ollama library tag with tools support
- coder-specific family for generation, reasoning, and code fixing
- approximately `9.0 GB` Ollama artifact size
- better fit for a `16 GB` RX 6800 than the excluded candidates

The official Ollama tag advertises a `32K` context window. Use this candidate
for bounded coder fixtures first. Require a measured `100% GPU` placement before
promotion.

## Local Coder Benchmark Ladder

Run the following levels in order. Stop scheduling expensive levels for models
that fail the previous gate repeatedly.

### Level 0: Runtime Gate

Required:

- API `/v1/messages` response
- structured tool use
- Claude Code headless handshake
- shell tool execution
- file edit
- final-answer grounding

### Level 1: Focused Code Generation

Use small deterministic tasks with tests:

- implement a Python function
- implement validation and edge cases
- interpret failing tests
- repair the implementation

Record:

- pass@1
- pass after one repair
- tests run
- elapsed time

### Level 2: Existing-Code Editing

Use a small repository fixture with:

- multiple files
- one implementation defect
- tests
- a bounded prompt

Require the model to:

- inspect repository context
- modify the correct file
- run tests
- report the real result

### Level 3: Repository Agent Tasks

Use a suite of repository tasks modeled after SWE-bench issue resolution:

- bug fix
- feature addition
- refactor preserving tests
- configuration change
- regression diagnosis

Record:

- task pass@1
- task pass after one repair
- invalid edit rate
- test execution rate
- final-answer accuracy
- wall-clock time
- timeout rate
- GPU, CPU, or split placement

### Level 4: External Benchmark Runner

After local gating:

- run Aider Polyglot for editing comparisons
- run a bounded LiveCodeBench subset for generation and repair
- consider SWE-bench Live only for models and stands that can afford the
  execution cost

## Minimum Reporting Table

| Stand | Model | Task suite | Tasks | Pass@1 | Pass after repair | Invalid edits | Final-answer accuracy | Median seconds | Placement |
|---|---|---|---:|---:|---:|---:|---:|---:|---|

## Recommended Next Model Order

For `win11-local-rx6800`:

1. `qwen3:8b-q4_K_M`
2. `gemma4:e4b`
3. `qwen2.5-coder:14b` after pull and full-GPU verification

Keep `llama3.2:latest` as a negative control only.

Exclude models with CPU or RAM spill from subsequent coder benchmarking.
