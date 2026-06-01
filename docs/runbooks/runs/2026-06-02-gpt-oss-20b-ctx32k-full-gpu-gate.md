# Run Record: GPT-OSS 20B `ctx32k` Full-GPU Gate

## Question

Can the unconventional `gpt-oss:20b` Ollama model stay entirely on the RX 6800
and complete the Claude Code headless tool loop?

## Profile

- Date: `2026-06-02`
- Stand: `win11-local-rx6800`
- Endpoint: `http://localhost:11434`
- Upstream model: `gpt-oss:20b`
- Local profile: `gpt-oss:20b-ctx32k`
- Context: `32768`
- Architecture: `gptoss`
- Parameters: `20.9B`
- Quantization: `MXFP4`

Build command:

```powershell
ollama create gpt-oss:20b-ctx32k `
  -f tools\modelfiles\gpt-oss-20b-ctx32k.Modelfile
```

## Result

| Stage | Seconds | Placement | Result |
|---|---:|---|---|
| `handshake` | `52.633` | `100% GPU` | Pass |
| `tool` | `43.841` | `100% GPU` | Pass |
| `agent` | `294.941` | `100% GPU` | Pass |

Runtime evidence:

```text
SIZE       14 GB
PROCESSOR  100% GPU
CONTEXT    32768
offloaded  25/25 layers to GPU
```

The agent stage observed repository read, Bash execution, file creation, and
git-status grounding.

## Artifacts

```text
.artifacts/claude-ollama-headless/20260602T041314/
.artifacts/claude-ollama-headless/20260602T041411/
```

## Decision

Add `gpt-oss:20b-ctx32k` as the fifth working RX 6800 profile. Keep it behind
the lighter profiles until code-quality fixtures show whether its slower
agent pass pays for itself.
