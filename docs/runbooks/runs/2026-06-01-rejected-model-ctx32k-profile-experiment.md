# Run Record: Rejected-Model `ctx32k` Profile Experiment

## Question

Can stand-specific context profiling improve previously rejected models on
`win11-local-rx6800`?

## Scope

- Date: `2026-06-01`
- Stand: `win11-local-rx6800`
- Endpoint: `http://localhost:11434`
- Profiles: `PARAMETER num_ctx 32768`
- Artifacts: `.artifacts/claude-ollama-headless/20260601T213929/`
- Runner stages: `handshake`
- Runner option: `-RequireFullGpu`

The cheap handshake stage is sufficient for the placement preflight. Tool and
agent stages were not scheduled after a model failed the strict `100% GPU`
gate.

## Why `ctx32k`

The rejected larger models advertise `262144` token context windows. The
Claude Code runtime also sends a large system prompt, so reducing the profile
far below `32768` would no longer test the intended headless agent workflow
fairly.

## Profiles

| Local profile | Upstream model | Modelfile |
|---|---|---|
| `qwen3-coder:latest-ctx32k` | `qwen3-coder:latest` | `tools/modelfiles/qwen3-coder-latest-ctx32k.Modelfile` |
| `qwen3.6:latest-ctx32k` | `qwen3.6:latest` | `tools/modelfiles/qwen3.6-latest-ctx32k.Modelfile` |
| `gemma4:26b-ctx32k` | `gemma4:26b` | `tools/modelfiles/gemma4-26b-ctx32k.Modelfile` |

## Result

| Model | Upstream placement | `ctx32k` placement | `ctx32k` offload | Full-GPU verdict |
|---|---|---|---|---|
| `qwen3-coder:latest` | `67%/33% CPU/GPU` | `32%/68% CPU/GPU` | `33/49` layers on GPU | Fail |
| `qwen3.6:latest` | `58%/42% CPU/GPU` | `47%/53% CPU/GPU` | `23/41` layers on GPU | Fail |
| `gemma4:26b` | `44%/56% CPU/GPU` | `29%/71% CPU/GPU` | `24/31` layers on GPU | Fail |

All handshake prompts returned successfully. All three tuned profiles improved
GPU placement, but none reached `100% GPU`.

## Conclusion

The hypothesis is partially confirmed.

Context profiling can substantially improve an already rejected model. It
fully recovered `granite4.1:8b` when its default `131072` context caused a
large CPU KV cache. For the larger models in this experiment, profiling
reduced spill but could not overcome their model-size requirements on a
single RX 6800.

Context profiling also does not address structured tool-use failures.
`qwen2.5-coder:7b` already fits at `100% GPU` and still prints tool requests as
plain text. The `qwen2.5-coder:14b` upstream profile is already bounded to
`32768`, so this experiment does not provide a context-only recovery path for
that variant.
