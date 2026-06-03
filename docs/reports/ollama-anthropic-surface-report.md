# Ollama Anthropic Messages Surface Report

- Base URL: `http://localhost:11434`
- Models probed: `3`
- Attempts per model: `3`

## Server Surface

| Probe | HTTP status | Result |
|---|---:|---|
| `/v1/messages/count_tokens` | `404` | Not available |
| `/v1/models` | `200` | Available |
| `/v1/messages/batches` | `404` | Not available |
| `metadata` request field | `200` | Accepted; support semantics not observable |
| `cache_control` request block | `200` | Accepted; caching semantics not observable |
| `tool_choice: none` request | `200` | Ignored: model still emitted tool_use |

## Model Behavior

| Model | Basic | System | Multi-turn | Streaming | Structured tool use | Tool result accepted | Tool result grounded | Practical subset |
|---|---|---|---|---|---|---|---|---|---|
| `gemma4:e4b` | `3/3` | `3/3` | `3/3` | `3/3` | `3/3` | `1/3` | `1/3` | `1/3` |
| `llama3.2:latest` | `3/3` | `3/3` | `3/3` | `3/3` | `3/3` | `3/3` | `0/3` | `3/3` |
| `qwen3:8b-q4_K_M` | `3/3` | `1/3` | `2/3` | `3/3` | `3/3` | `3/3` | `0/3` | `1/3` |

## Interpretation

- Server-surface probes are endpoint-level facts and do not vary by model.
- Model cells report successful attempts over total attempts.
- Model checks measure practical behavior through Ollama's supported `/v1/messages` subset.
- `Tool result accepted` means the second request completed with a text answer.
- `Tool result grounded` means the answer preserved the injected `TOOL_RESULT_OK` marker.
- A practical subset pass is not proof of full Anthropic API parity.
