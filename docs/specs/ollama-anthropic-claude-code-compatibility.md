# Ollama Anthropic API Compatibility For Claude Code

## Question

Evaluate this hypothesis:

> Ollama supports the Anthropic API, and Claude Code works only with the
> Anthropic API.

Then test the three selected Ollama models for the Anthropic-compatible surface
needed by the local Claude Code workflow.

## Verdict

The hypothesis is only partially correct.

### Confirmed

- Ollama officially provides an Anthropic Messages API compatibility layer.
- Ollama officially documents Claude Code as a supported integration.
- Claude Code can use Ollama through:

```text
ANTHROPIC_AUTH_TOKEN=ollama
ANTHROPIC_BASE_URL=http://localhost:11434
```

### Refuted Or Narrowed

- Claude Code does not work only with the Anthropic Messages API. Its official
  gateway documentation also supports Bedrock InvokeModel and Vertex
  `rawPredict` formats. The enterprise deployment documentation also lists
  Microsoft Foundry.
- Ollama does not implement the complete Anthropic API.
- Ollama is not a complete Anthropic Messages gateway by Claude Code's strict
  gateway requirements because `/v1/messages/count_tokens` is absent.

The accurate statement is:

> Ollama implements a useful Anthropic-compatible Messages API subset that can
> run Claude Code, but it is not a full Anthropic API implementation and does
> not satisfy every Claude Code gateway requirement.

## Primary Sources

Ollama:

- [Anthropic compatibility](https://docs.ollama.com/api/anthropic-compatibility)
- [Claude Code integration](https://docs.ollama.com/integrations/claude-code)

Claude Code:

- [LLM gateway configuration](https://code.claude.com/docs/en/llm-gateway)
- [Enterprise deployment overview](https://code.claude.com/docs/en/third-party-integrations)

## Source-Based Surface Comparison

Ollama documents `/v1/messages` support for:

- messages
- streaming
- system prompts
- multi-turn conversations
- tools and tool results
- thinking blocks
- images

Ollama also documents these differences from Anthropic API:

- token counts are approximations
- API keys are accepted but not validated
- `anthropic-version` is accepted but not used

Ollama explicitly documents these features as unsupported:

- `/v1/messages/count_tokens`
- forced or disabled `tool_choice`
- request `metadata`
- prompt caching through `cache_control`
- batches
- citations
- PDF document blocks
- server-sent streaming error events

Claude Code's official LLM gateway requirements say that an Anthropic Messages
gateway should provide:

```text
/v1/messages
/v1/messages/count_tokens
```

This is the clearest contract-level gap for the tested local Ollama version.

## Local Probe

Test script:

```powershell
python tools\check_ollama_anthropic_surface.py
```

Reports:

- [Markdown summary](../ollama-anthropic-surface-report.md)
- [Raw JSON evidence](../ollama-anthropic-surface-report.json)

The local probe used:

- endpoint: `http://localhost:11434`
- Ollama: `0.24.0`
- attempts per model: `3`
- models:
  - `gemma4:e4b`
  - `llama3.2:latest`
  - `qwen3:8b-q4_K_M`

## Server-Level Results

These are Ollama endpoint properties, not model properties:

| Probe | Local result | Interpretation |
|---|---|---|
| `/v1/messages` | Available | Main compatibility endpoint works |
| `/v1/models` | `200` | Model discovery endpoint is available |
| `/v1/messages/count_tokens` | `404` | Strict Claude Code Anthropic gateway requirement is missing |
| `/v1/messages/batches` | `404` | Batches API is missing |
| `metadata` | HTTP `200` | Field is accepted, but documented metadata semantics are unsupported |
| `cache_control` | HTTP `200` | Block is accepted, but documented caching semantics are unsupported |
| `tool_choice: none` | HTTP `200`, tool still emitted | Disable-tools instruction is ignored |

## Model-Level Results

| Model | Basic | System | Multi-turn | Streaming | Tool use | Tool result accepted | Tool result grounded |
|---|---|---|---|---|---|---|---|
| `gemma4:e4b` | `3/3` | `3/3` | `3/3` | `3/3` | `3/3` | `1/3` | `1/3` |
| `llama3.2:latest` | `3/3` | `3/3` | `3/3` | `3/3` | `3/3` | `3/3` | `0/3` |
| `qwen3:8b-q4_K_M` | `3/3` | `1/3` | `2/3` | `3/3` | `3/3` | `3/3` | `0/3` |

Definitions:

- `Tool result accepted`: the second `/v1/messages` request completed with a
  text answer after a `tool_result` block.
- `Tool result grounded`: the answer preserved the injected
  `TOOL_RESULT_OK` marker.

## Interpretation

- All three models can emit structured `tool_use` blocks through Ollama.
- API-level structured tool use alone is not enough to predict Claude Code
  agent quality.
- `llama3.2:latest` accepts direct API probes but still returns empty turns in
  real Claude Code headless runs. It should remain rejected for agent mode.
- `qwen3:8b-q4_K_M` remains the strongest practical agent candidate because it
  passed the strict headless tool loop even though direct micro-probes expose
  some response instability.
- `gemma4:e4b` remains a secondary candidate: it executes the headless tool loop
  but shows both micro-probe instability and a final-answer wording defect.

## Boundaries Of This Probe

The local probe intentionally tests the text-and-tools path used by the current
repository workflow. It does not yet test:

- image content blocks
- thinking request blocks
- citations
- PDF document blocks
- server-sent streaming errors
- large-context behavior

Ollama's Claude Code integration documentation recommends at least a `64k`
context window. The observed post-run `ollama ps` snapshot on this stand showed
`40960`, so large-context testing remains a separate required track.
