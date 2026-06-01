# Run Record: Favorite-Model Context Sweep

## Question

Does each favored model need a different Ollama context profile on
`win11-local-rx6800`?

## Method

- Date: `2026-06-01`
- Stand: `win11-local-rx6800`
- Endpoint: `http://localhost:11434`
- Models:
  - `qwen3:8b-q4_K_M`
  - `gemma4:e4b`
  - `granite4.1:8b`
- Fixed context step: `8192`
- Starting context: `32768`
- Cheap sweep stage: `handshake`
- Gate: successful marker and `ollama ps -> 100% GPU`

The sweep stops after the first CPU spill or the upstream model context limit.
This minimizes test time while preserving a common fixed step.

Primary artifacts:

```text
.artifacts/claude-ollama-headless/20260601T215233/
.artifacts/claude-ollama-headless/20260601T220032/
.artifacts/claude-ollama-headless/20260601T220152/
.artifacts/claude-ollama-headless/20260601T220310/
.artifacts/claude-ollama-headless/20260601T220436/
.artifacts/claude-ollama-headless/20260601T220554/
```

## Common Sweep

| Model | Requested ctx | Effective ctx | Placement | Runtime size | Seconds | Verdict |
|---|---:|---:|---|---:|---:|---|
| `qwen3:8b-q4_K_M` | `32768` | `32768` | `100% GPU` | `10 GB` | `54.221` | Pass |
| `qwen3:8b-q4_K_M` | `40960` | `40960` | `100% GPU` | `11 GB` | `80.846` | Pass |
| `qwen3:8b-q4_K_M` | `49152` | `40960` | `100% GPU` | `11 GB` | `56.515` | Upstream cap reached |
| `gemma4:e4b` | `32768` | `32768` | `100% GPU` | `11 GB` | `32.785` | Pass |
| `gemma4:e4b` | `40960` | `40960` | `100% GPU` | `11 GB` | `34.640` | Pass |
| `gemma4:e4b` | `49152` | `49152` | `100% GPU` | `11 GB` | `32.924` | Pass |
| `granite4.1:8b` | `32768` | `32768` | `100% GPU` | `14 GB` | `47.215` | Pass |
| `granite4.1:8b` | `40960` | `40960` | `9%/91% CPU/GPU` | `16 GB` | `51.057` | Fail |
| `granite4.1:8b` | `49152` | `49152` | `21%/79% CPU/GPU` | `18 GB` | `55.558` | Fail |

## Gemma Extension

Gemma retained `100% GPU` placement across the remainder of its advertised
context range:

| Requested ctx | Placement | Runtime size | Seconds |
|---:|---|---:|---:|
| `57344` | `100% GPU` | `11 GB` | `31.369` |
| `65536` | `100% GPU` | `11 GB` | `35.182` |
| `73728` | `100% GPU` | `11 GB` | `29.468` |
| `81920` | `100% GPU` | `12 GB` | `33.217` |
| `90112` | `100% GPU` | `12 GB` | `34.868` |
| `98304` | `100% GPU` | `12 GB` | `34.336` |
| `106496` | `100% GPU` | `12 GB` | `32.206` |
| `114688` | `100% GPU` | `12 GB` | `33.326` |
| `122880` | `100% GPU` | `12 GB` | `34.509` |
| `131072` | `100% GPU` | `13 GB` | `35.523` |

## Selected Profiles

| Model | Placement optimum | Why |
|---|---:|---|
| `qwen3:8b-q4_K_M-ctx40k` | `40960` | Maximum effective context exposed by the upstream tag; stays at `100% GPU` |
| `gemma4:e4b-ctx128k` | `131072` | Maximum advertised context; stays at `100% GPU` |
| `granite4.1:8b-ctx32k` | `32768` | Next fixed step introduces CPU spill |

## Agent Qualification

Granite already passed the full `handshake,tool,agent` gate at `ctx32k`.
Qwen previously passed the full gate with its effective `40960` context.

Gemma needs a separate reliability decision. Full-gate controls at both ends
of its sweep showed the same behavior:

| Gemma profile | Handshake | Tool | Agent |
|---|---|---|---|
| `gemma4:e4b-ctx32k` | Pass | Pass | Fail after `Read`; no edit |
| `gemma4:e4b-ctx128k` | Pass | Pass | Fail after `Read`; no edit |

The Gemma failure is not caused by context size. Its placement optimum is
`131072`, but it does not currently have an agent-qualified profile.

Control artifacts:

```text
.artifacts/claude-ollama-headless/20260601T220724/
.artifacts/claude-ollama-headless/20260601T221011/
```

## Conclusion

The hypothesis is confirmed: optimal context is model-specific.

Use placement-optimal profiles for bounded coder benchmarks, while keeping
agent qualification as a separate gate. Do not infer agent reliability from
VRAM placement alone.
