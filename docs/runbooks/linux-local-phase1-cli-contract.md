# Linux Local Phase 1 CLI Contract

## Purpose

Prepare and run the Phase 1 full CLI contract for the current leaders on the
local Ubuntu CUDA stand.

## Stand

Use:

```text
ubuntu-local-rtx3080
```

The verified baseline is:

- [Ubuntu Local Stand Snapshot](ubuntu-local-stand-2026-06-02.md)

## Preflight

Capture current endpoint, host, accelerator, service settings, model
inventory, and tool versions without starting inference:

```bash
tools/prepare_linux_phase1.sh
```

Artifacts are written under:

```text
.artifacts/linux-phase1-preflight/
```

## Create Leader Profiles

Download the upstream leaders and create the local `ctx32k` profiles:

```bash
tools/prepare_linux_phase1.sh --pull-models
```

This can be a large download. Profile creation does not prove that either
model fits in GPU memory on this stand.

## Run Phase 1

Run the autonomous repository-editing contract with the strict placement
gate:

```bash
tools/run_linux_phase1_cli_contract.sh --require-full-gpu
```

The runner tests:

1. autonomous repository inspection without naming the implementation file
2. relevant-file selection
3. implementation editing
4. test execution by the agent
5. independent test execution after the agent returns
6. unchanged tests
7. explicit `git status --short` execution and grounded final answer
8. final git state, transcript, debug log, and `ollama ps` capture

Raw artifacts are written under:

```text
.artifacts/linux-phase1-cli-contract/
```

## Placement Review

Review each model's:

```text
ollama-ps.txt
result.json
stdout.stream.jsonl
unittest.txt
git-status.txt
git-diff.patch
```

If a leader spills to CPU or does not fit, retain the failure evidence and
profile a smaller context or alternate candidate before scheduling repeated
runs.

## Next Candidate Queue

The RTX 3080 stand has `10 GiB` VRAM. Test the next profiles in this order:

1. `granite4.1:8b-ctx32k`
2. `qwen3.5:9b-q4_K_M-ctx32k`
3. `gemma4:e2b-ctx32k`

Create the local profiles:

```bash
ollama create qwen3:8b-q4_K_M-ctx32k \
  -f tools/modelfiles/qwen3-8b-q4_K_M-ctx32k.Modelfile
ollama pull granite4.1:8b
ollama create granite4.1:8b-ctx32k \
  -f tools/modelfiles/granite4.1-8b-ctx32k.Modelfile
ollama pull qwen3.5:9b-q4_K_M
ollama create qwen3.5:9b-q4_K_M-ctx32k \
  -f tools/modelfiles/qwen3.5-9b-q4_K_M-ctx32k.Modelfile
ollama pull gemma4:e2b
ollama create gemma4:e2b-ctx32k \
  -f tools/modelfiles/gemma4-e2b-ctx32k.Modelfile
```

Run downloads one at a time and review available disk space first. Keep
`gpt-oss:20b-ctx32k` out of the strict queue on this stand: its observed
placement was `36%/64% CPU/GPU`.

## Ubuntu RTX 3080 Results

The grounded-contract run captured under
`.artifacts/linux-phase1-cli-contract/20260602T152656/` produced:

| Model | Placement | External tests | Grounded final | Verdict |
|---|---|---|---|---|
| `ministral-3:8b-ctx32k` | `100% GPU` | `4/4` pass | Pass | Promote to reliability runs |
| `qwen3:8b-q4_K_M-ctx32k` | `100% GPU` | Fail | Fail | Keep as negative quality control |

`qwen3:8b-q4_K_M-ctx32k` repeatedly wrote an unterminated docstring, left the
fixture with a Python `SyntaxError`, and returned manual repair advice instead
of completing the task.

## Reliability Pass

Three grounded-contract attempts per promoted profile were captured under:

```text
.artifacts/linux-phase1-cli-contract/20260602T182113/
.artifacts/linux-phase1-cli-contract/20260602T182526/
.artifacts/linux-phase1-cli-contract/20260602T183041/
```

| Model | Pass rate | Full GPU | External tests | Grounded final | Seconds | Median |
|---|---:|---:|---:|---:|---|---:|
| `ministral-3:8b-ctx32k` | `2/3` | `3/3` | `2/3` | `3/3` | `157`, `150`, `373` | `157` |
| `granite4.1:8b-ctx32k` | `2/3` | `3/3` | `2/3` | `3/3` | `96`, `165`, `132` | `132` |

The first Granite attempt is counted as a reviewed pass. It ran
`python3 tests/test_tag_tools.py` and passed `4/4`, but the original mechanical
detector only recognized commands containing `unittest`. The runner now also
recognizes direct test-file and `pytest` execution.

Observed reliability failures:

- Ministral preserved an empty normalized tag in one attempt.
- Granite wrote literal `\n` sequences into Python source in one attempt,
  leaving a `SyntaxError`.

Both profiles remain in the candidate set, but neither is reliable enough to
promote from a single attractive pass.
