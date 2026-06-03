# Ubuntu Local Stand Snapshot

## Purpose

Record the baseline for the local Ubuntu CUDA stand before Phase 1 CLI
contract runs.

## Snapshot Identity

- Captured at: `2026-06-02T13:06:01+07:00`
- Repository commit: `702e420c6a8b47e6182529012b7012a993e56c3f`
- Workspace: `/home/krl/ai-ide-check`
- Stand ID: `ubuntu-local-rtx3080`
- Hostname: `kb-brootforce`
- Host topology: VS Code remote server, Claude Code CLI, Ollama, and candidate
  models run on the same Ubuntu host.

## Verified Hardware

| Component | Verified value | Notes |
|---|---|---|
| CPU | `11th Gen Intel(R) Core(TM) i7-11700KF @ 3.60GHz`, `8` cores, `16` logical processors | Local `lscpu` |
| RAM | approximately `62 GiB` | Local `free -h` |
| Discrete GPU | `NVIDIA GeForce RTX 3080` | Local `nvidia-smi` and `lspci` |
| Discrete GPU VRAM | `10240 MiB` | Local `nvidia-smi` |
| NVIDIA driver | `595.71.05` | Local `nvidia-smi` |
| CUDA version reported by driver | `13.2` | Local `nvidia-smi` |

This stand has less VRAM than `win11-local-rx6800`. Treat the Windows
placement results as candidate-selection input only. Record fresh
`ollama ps` placement evidence on this stand before promoting any profile.

## Verified Component Versions

| Component | Verified version | Notes |
|---|---|---|
| Ubuntu | `24.04.4 LTS`, kernel `6.8.0-117-generic`, `x86_64` | Local `/etc/os-release` and `uname -a` |
| Bash | `/bin/bash` | Active shell |
| VS Code remote server | `1.122.1`, commit `8761a5560cfd65fdd19ce7e2bd18dab5c0a4d84e` | Local `code --version` |
| Claude Code for VS Code | `anthropic.claude-code@2.1.160` | Local `code --list-extensions --show-versions` |
| Claude Code CLI | `2.1.160 (Claude Code)` | Executable: `/home/krl/.local/bin/claude` |
| Ollama | `0.24.0` | Executable: `/usr/local/bin/ollama` |
| Python | `3.12.3` | Executable: `/usr/bin/python3` |
| Git | `2.43.0` | Executable: `/usr/bin/git` |
| curl | `8.5.0` | Executable: `/usr/bin/curl` |

## Verified Local Endpoint

- Ollama endpoint: `http://localhost:11434`
- `GET /api/version`: success, returned `0.24.0`
- `GET /api/tags`: success
- `ollama ps`: no model was loaded at snapshot time
- GPU-selection override: no `CUDA_*`, `OLLAMA_*`, `ROCR_*`, or `HIP_*`
  override was exported in the operator shell

The systemd service has explicit Ollama settings:

```text
OLLAMA_HOST=0.0.0.0
OLLAMA_CONTEXT_LENGTH=8192
OLLAMA_FLASH_ATTENTION=1
OLLAMA_KV_CACHE_TYPE=q8_0
OLLAMA_NUM_PARALLEL=1
OLLAMA_MAX_LOADED_MODELS=1
OLLAMA_KEEP_ALIVE=15m
OLLAMA_MAX_QUEUE=16
```

## Initial Model Inventory

| Model | Parameters | Quantization | Phase 1 role |
|---|---:|---|---|
| `qwen3:8b-q4_K_M` | `8.2B` | `Q4_K_M` | Existing local candidate |
| `gemma4:e4b` | `8.0B` | `Q4_K_M` | Existing local candidate |
| `gemma3:12b-it-q4_K_M` | `12.2B` | `Q4_K_M` | Existing local model |
| `qwen2.5-coder:7b-instruct-q4_K_M` | `7.6B` | `Q4_K_M` | Existing local model |
| `llama3.2:latest` | `3.2B` | `Q4_K_M` | Existing negative control |

The Phase 1 leader profiles `gpt-oss:20b-ctx32k` and
`ministral-3:8b-ctx32k` were not installed at snapshot time.

## Phase 1 Preparation

Use:

```bash
tools/prepare_linux_phase1.sh
tools/prepare_linux_phase1.sh --pull-models
tools/run_linux_phase1_cli_contract.sh --require-full-gpu
```

The first command captures a cheap preflight. The second command performs the
large model downloads and creates the local profiles. The third command runs
the autonomous full-contract task in disposable fixture copies and preserves
raw artifacts under `.artifacts/`.

## Known Deviations

- This CUDA stand is separate from the Windows ROCm reference stand.
- The RTX 3080 has `10 GiB` VRAM, so a strict `100% GPU` gate may reject
  profiles that passed on the `16 GiB` RX 6800.
- `python` is not installed as an alias; Linux scripts use `python3`.
- Ollama service logs were not available to the operator through
  `journalctl -u ollama` during the initial snapshot.
