# Run Record: Windows Local Coder Eligibility

## Identity

- Date: `2026-06-01`
- Stand: `win11-local-rx6800`
- Endpoint: `http://localhost:11434`
- Artifacts: `.artifacts/claude-ollama-headless/20260601T193325/`
- Scenario: Claude Code headless `handshake`, `tool`, and `agent`
- Timeout per stage: `1200` seconds

## Mechanical Results

| Model | Handshake | Tool | Agent | Placement observed during run | Coder-track decision |
|---|---:|---:|---:|---|---|
| `qwen3-coder:latest` | Pass, `153s` | Pass, `296s` | Pass, `1069s` | `67%/33% CPU/GPU` | Exclude: CPU/RAM spill |
| `qwen3.6:latest` | Pass, `179s` | Pass, `120s` | Pass, `328s` | `58%/42% CPU/GPU` | Exclude: CPU/RAM spill |
| `gemma4:26b` | Pass, `107s` | Pass, `169s` | Pass, `468s` | `44%/56% CPU/GPU` | Exclude: CPU/RAM spill |

All three models completed the tool loop correctly. They are excluded from the
next coder benchmark stage because this stand now requires full GPU placement.

## Existing Full-GPU Candidates

Earlier local logs confirmed:

| Model | GPU evidence | Coder-track decision |
|---|---|---|
| `qwen3:8b-q4_K_M` | `offloaded 37/37 layers to GPU`, `ollama ps: 100% GPU` | Keep |
| `gemma4:e4b` | `offloaded 43/43 layers to GPU` | Keep |

## Third Candidate

Select:

```text
qwen2.5-coder:14b
```

Rationale:

- coder-specialized model family
- official Ollama tag supports tools
- official Ollama artifact size: approximately `9.0 GB`
- materially more likely to fit the RX 6800 `16 GB` VRAM budget than the
  excluded `17-23 GB` artifacts

Constraint:

- the official Ollama tag advertises a `32K` context window
- use it first for bounded local coder fixtures
- do not promote it until `ollama ps` confirms `100% GPU`
