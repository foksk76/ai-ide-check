# Ollama Model Compatibility Report

- Checked at base URL: `http://bruter:11434`
- Models installed on server: `5`

## Summary Table

| Model | Installed | Metadata tools capability | Basic chat via /v1/messages | Tools via /v1/messages | Tool call is structured | Tool call printed as text | Claude Code compatible | Recommended role | Notes |
|---|---|---|---|---|---|---|---|---|---|
| qwen2.5-coder:7b-instruct-q4_K_M | Yes | Yes | OK | Text JSON imitation | No | Yes | No | Technical documentation check | metadata tools=yes<br>native /api/chat also prints tool JSON as text<br>tool call is only text, not API-structured |
| gemma3:12b-it-q4_K_M | Yes | No | OK | Error: registry.ollama.ai/library/gemma3:12b-it-q4_K_M does not support tools | No | No | No | User documentation only | metadata tools=no<br>native tools error: registry.ollama.ai/library/gemma3:12b-it-q4_K_M does not support tools<br>/v1/messages tools error: registry.ollama.ai/library/gemma3:12b-it-q4_K_M does not support tools |
| gemma4:e4b | Yes | Yes | OK | Structured tool call | Yes | No | Yes | Claude Code agent / coding | metadata tools=yes |
| llama3.2:latest | Yes | Yes | OK | Structured tool call | Yes | No | Yes | Claude Code agent / coding | metadata tools=yes |
| qwen3:8b-q4_K_M | Yes | Yes | OK /think | Structured tool call | Yes | No | Yes | Claude Code agent / coding | metadata tools=yes |

## Model Notes

### qwen2.5-coder:7b-instruct-q4_K_M

- Size: `4.4 GB`
- Quantization: `Q4_K_M`
- Context length: `32768`
- Metadata capabilities: `completion, tools, insert`
- Native `/api/chat` tools result: `Text JSON imitation`
- Notes: metadata tools=yes; native /api/chat also prints tool JSON as text; tool call is only text, not API-structured

### gemma3:12b-it-q4_K_M

- Size: `7.6 GB`
- Quantization: `Q4_K_M`
- Context length: `n/a`
- Metadata capabilities: `completion, vision`
- Native `/api/chat` tools result: `Error: registry.ollama.ai/library/gemma3:12b-it-q4_K_M does not support tools`
- Notes: metadata tools=no; native tools error: registry.ollama.ai/library/gemma3:12b-it-q4_K_M does not support tools; /v1/messages tools error: registry.ollama.ai/library/gemma3:12b-it-q4_K_M does not support tools

### gemma4:e4b

- Size: `8.9 GB`
- Quantization: `Q4_K_M`
- Context length: `n/a`
- Metadata capabilities: `completion, vision, audio, tools, thinking`
- Native `/api/chat` tools result: `Structured tool call`
- Notes: metadata tools=yes

### llama3.2:latest

- Size: `1.9 GB`
- Quantization: `Q4_K_M`
- Context length: `131072`
- Metadata capabilities: `completion, tools`
- Native `/api/chat` tools result: `Structured tool call`
- Notes: metadata tools=yes

### qwen3:8b-q4_K_M

- Size: `4.9 GB`
- Quantization: `Q4_K_M`
- Context length: `n/a`
- Metadata capabilities: `completion, tools, thinking`
- Native `/api/chat` tools result: `Structured tool call`
- Notes: metadata tools=yes

## Focus Models Not Installed

- `qwen3.5:9b-q4_K_M`
- `qwen2.5:7b-instruct-q4_K_M`
- `llama3.1:8b-instruct-q4_K_M`

## Recommendations

Recommended Claude Code agent model: `gemma4:e4b`
Recommended user documentation model: `gemma3:12b-it-q4_K_M`
Recommended final documentation check model: `qwen2.5-coder:7b-instruct-q4_K_M`
Models to avoid in Claude Code: `qwen2.5-coder:7b-instruct-q4_K_M`, `gemma3:12b-it-q4_K_M`

## Textual Tool Call Imitations

- `qwen2.5-coder:7b-instruct-q4_K_M` returned tool-call JSON as plain text.
