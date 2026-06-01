# Windows Local Stand Snapshot

## Purpose

Record the verified baseline for the new single-host stand before adding
automated Claude Code runs through local Ollama.

## Snapshot Identity

- Captured at: `2026-06-01T18:46:53.8930785+07:00`
- Repository commit: `b4ed5d04945be8f17493792729c3c4bc4387684e`
- Workspace: `C:\Git\ai-ide-check`
- Stand ID: `win11-local-rx6800`
- Hostname: `DESKTOP-5909GN1`
- Host topology: VS Code, Claude Code, Claude Code for VS Code, Ollama, and
  candidate models run on the same Windows host.

## Verified Hardware

| Component | Verified value | Notes |
|---|---|---|
| Mainboard | `Gigabyte Technology Co., Ltd. X670 AORUS ELITE AX` | Local CIM |
| CPU | `AMD Ryzen 7 7700X 8-Core Processor`, `8` cores, `16` logical processors | Local CIM |
| RAM | approximately `32 GB` | Local CIM |
| Discrete GPU | `AMD Radeon RX 6800`, PCI device `VEN_1002&DEV_73BF` | Local CIM |
| Discrete GPU VRAM | `16 GB GDDR6` | [Official AMD specification](https://www.amd.com/en/products/graphics/desktops/radeon/6000-series/amd-radeon-rx-6800.html) |
| Integrated GPU | `AMD Radeon(TM) Graphics` | Local CIM |
| AMD driver | `32.0.12033.1030`, dated `2024-11-27` | Local CIM |
| ROCm directories | `C:\Program Files\AMD\ROCm\6.2`, `C:\Program Files\AMD\ROCm\6.4` | Local filesystem |
| External ROCm selected by shell | `C:\Program Files\AMD\ROCm\6.4\` | `HIP_PATH` |
| Ollama bundled ROCm backend | `C:\Users\user\AppData\Local\Programs\Ollama\lib\ollama\rocm\ggml-hip.dll` | Observed in `server.log` |

`Win32_VideoController.AdapterRAM` reported approximately `4 GB` for the RX
6800. This is not treated as authoritative: AMD specifies `16 GB GDDR6`.

## Verified Component Versions

| Component | Verified version | Notes |
|---|---|---|
| Windows | `Microsoft Windows 11 Pro`, `10.0.26200`, build `26200.8524`, `64-bit` | `Get-CimInstance Win32_OperatingSystem` is the authoritative product-name check for this snapshot. |
| PowerShell | `5.1.26100.8521` | Default shell used for local automation. |
| VS Code | `1.121.0`, commit `f6cfa2ea2403534de03f069bdf160d06451ed282`, `x64` | Installed under `C:\Program Files\Microsoft VS Code`. |
| Claude Code for VS Code | `anthropic.claude-code@2.1.159` | Captured with `code --list-extensions --show-versions`. |
| Claude Code CLI | `2.1.158 (Claude Code)` | Executable: `C:\Users\user\.local\bin\claude.exe`. |
| Ollama | `0.24.0` | Executable: `C:\Users\user\AppData\Local\Programs\Ollama\ollama.exe`. |
| Python | `3.11.9` | Both `python` and `python3` resolve through Windows Apps. |
| Git | `2.54.0.windows.1` | Executable: `C:\Program Files\Git\cmd\git.exe`. |
| curl | `8.19.0` | Windows build using Schannel. |

## Verified Component Locations

| Component | Location |
|---|---|
| VS Code CLI | `C:\Program Files\Microsoft VS Code\bin\code.cmd` |
| Claude Code CLI | `C:\Users\user\.local\bin\claude.exe` |
| Claude Code for VS Code | `C:\Users\user\.vscode\extensions\anthropic.claude-code-2.1.159-win32-x64` |
| Ollama executable | `C:\Users\user\AppData\Local\Programs\Ollama\ollama.exe` |
| Ollama logs | `C:\Users\user\AppData\Local\Ollama` |
| Ollama models | `C:\Users\user\.ollama\models` |
| Python | `C:\Users\user\AppData\Local\Microsoft\WindowsApps\python.exe` |
| Git | `C:\Program Files\Git\cmd\git.exe` |

`OLLAMA_MODELS` was unset at process, user, and machine scope, so the default
Windows model location is active.

## Verified Local Endpoint

- Ollama endpoint: `http://localhost:11434`
- `GET /api/version`: success, returned `0.24.0`
- `GET /api/tags`: success, returned the model inventory below
- `ollama ps`: no model was loaded at snapshot time
- GPU-selection override: `ROCR_VISIBLE_DEVICES` was not set

## Observed GPU Execution

The Ollama server log confirmed that the application used its bundled ROCm
backend and detected:

```text
Device 0: AMD Radeon RX 6800, gfx1030
library=ROCm total="16.0 GiB"
```

During a `qwen3:8b-q4_K_M` run, Ollama reported:

```text
offloaded 37/37 layers to GPU
```

Record processor placement per model: larger models may use a split GPU and CPU
execution path even when the RX 6800 is detected correctly.

## Ollama Model Inventory

| Model | Digest | Size | Parameters | Quantization | Location |
|---|---|---:|---:|---|---|
| `llama3.2:latest` | `a80c4f17acd55265feec403c7aef86be0c25983ab279d83f3bcd3abbcb5b8b72` | `2.0 GB` | `3.2B` | `Q4_K_M` | local |
| `qwen3:8b-q4_K_M` | `500a1f067a9f782620b40bee6f7b0c89e17ae61f686b92c24933e4ca4b2b8b41` | `5.2 GB` | `8.2B` | `Q4_K_M` | local |
| `qwen3-coder:latest` | `06c1097efce0431c2045fe7b2e5108366e43bee1b4603a7aded8f21689e90bca` | `18 GB` | `30.5B` | `Q4_K_M` | local |
| `qwen3.6:latest` | `07d35212591fc27746f0a317c975a6d68754fb38e9053d82e25f06057af28522` | `23 GB` | `36.0B` | `Q4_K_M` | local |
| `gemma4:31b-cloud` | `c382fbfbc73b6fdd08c8549c23caedc6e62eb09933c65a1fb82dbf3398320a4e` | remote | n/a | n/a | `https://ollama.com:443` |
| `glm-5.1:cloud` | `59472abf9d0aab2eb1b0106ba1c1f59266a00ed41f63d2a2b1db082e7346b982` | remote | n/a | n/a | `https://ollama.com:443` |
| `gemma4:26b` | `5571076f3d70050487b26b341705799e0ab29b808164f90d20d4cf84f699d251` | `17 GB` | `25.8B` | `Q4_K_M` | local |
| `gemma4:e4b` | `c6eb396dbd5992bbe3f5cdb947e8bbc0ee413d7c17e2beaae69f5d569cf982eb` | `9.6 GB` | `8.0B` | `Q4_K_M` | local |

## Claude Configuration Observation

- Found user settings file: `C:\Users\user\.claude\settings.json`
- No endpoint, model, or timeout override was present in that file.
- No process-level `ANTHROPIC_*`, `CLAUDE_*`, or `OLLAMA_*` environment
  variables were set when the snapshot was captured.

The automated runner should therefore inject its Ollama connection settings,
model, permission mode, prompt, and artifact paths explicitly for every run.

## Baseline Verification Commands

```powershell
code --version
code --list-extensions --show-versions
claude --version
ollama --version
ollama list
ollama ps
curl.exe --silent --show-error --fail http://localhost:11434/api/version
curl.exe --silent --show-error --fail http://localhost:11434/api/tags
```

## Next Automation Layer

The next test scheme should run Claude Code non-interactively with:

- an explicit local Ollama base URL
- an explicit model per run
- a fresh non-persistent session
- a fixed prompt supplied automatically
- stream JSON output and debug logs saved per run
- preflight and post-run snapshots saved beside the transcript
- an optional VS Code extension comparison run kept as a separate layer
