# Contract: Claude Code + Ollama Stand Validation

## Objective

Define the operational contract for validating Claude Code agent workflows
backed by Ollama across multiple stands.

The contract answers two questions:

1. Can Claude Code CLI complete a real agent task through the selected Ollama
   endpoint with actual tool execution?
2. Does Claude Code for VS Code preserve that behavior when the IDE extension
   is added to the request path?

## Validation Layers

| Layer | Required | Purpose |
|---|---|---|
| API surface | Yes | Verify Ollama endpoint availability and the supported Anthropic-compatible Messages subset. |
| Claude Code CLI headless | Yes | Primary repeatable agent validation path. |
| Claude Code for VS Code | Comparison | Detect IDE extension, session, and selected-editor-context regressions separately from CLI behavior. |

A model must not be marked agent-compatible from API tool use alone.

## Stand Model

Every validation run must name one registered stand by stable `stand_id`.

A stand is a versioned operational profile containing:

- topology
- host identity and operating system
- accelerator inventory
- component versions and executable locations
- Ollama endpoint and model-storage location
- diagnostics path
- model inventory snapshot
- known deviations from the default contract

Hostname, IP address, and endpoint may change without changing `stand_id`.
Create a new `stand_id` when the hardware topology or ownership boundary
changes enough that results are no longer directly comparable.

## Registered Stands

| `stand_id` | Topology | Ollama endpoint | Accelerator | Primary use |
|---|---|---|---|---|
| `linux-bruter-remote` | Operator workstation and remote Linux Ollama server | `http://bruter:11434` | Record from the Linux stand when refreshing its snapshot | Historical Linux IDE comparison and remote diagnostics |
| `win11-local-rx6800` | VS Code, Claude Code, Ollama, and models on one Windows host | `http://localhost:11434` | `AMD Radeon RX 6800`, `16 GB GDDR6` | Primary Windows CLI headless validation and VS Code comparison |
| `ubuntu-local-rtx3080` | VS Code remote server, Claude Code CLI, Ollama, and models on one Ubuntu host | `http://localhost:11434` | `NVIDIA GeForce RTX 3080`, `10240 MiB` | Local Ubuntu CUDA CLI contract validation |

Current detailed Windows snapshot:

- [Windows Local Stand Snapshot](../runbooks/windows-local-stand-2026-06-01.md)

Current detailed Ubuntu snapshot:

- [Ubuntu Local Stand Snapshot](../runbooks/ubuntu-local-stand-2026-06-02.md)

Use the reusable record when adding a stand:

- [Stand Record Template](stand-record-template.md)

## System Under Test

The complete system under test may include:

- VS Code on the operator workstation
- Claude Code CLI
- Claude Code for VS Code
- Ollama exposing an Anthropic-compatible Messages API subset
- one or more local or remote models
- a git-backed disposable workspace
- a GPU, integrated accelerator, or CPU execution path

Not every layer has to run on the same host. The selected stand topology must
make component placement explicit.

## Stand: `win11-local-rx6800`

### Topology

```text
DESKTOP-5909GN1
  |-- VS Code
  |-- Claude Code for VS Code
  |-- Claude Code CLI
  |-- Ollama API: http://localhost:11434
  |-- Ollama model storage: C:\Users\user\.ollama\models
  `-- AMD Radeon RX 6800
```

### Hardware Contract

| Item | Verified value | Source |
|---|---|---|
| Hostname | `DESKTOP-5909GN1` | Local `hostname` |
| Mainboard | `Gigabyte Technology Co., Ltd. X670 AORUS ELITE AX` | Local CIM |
| CPU | `AMD Ryzen 7 7700X 8-Core Processor`, `8` cores, `16` logical processors | Local CIM |
| RAM | approximately `32 GB` | Local CIM |
| Discrete GPU | `AMD Radeon RX 6800` | Local CIM |
| Discrete GPU PCI ID | `VEN_1002&DEV_73BF` | Local CIM |
| Discrete GPU VRAM | `16 GB GDDR6` | [AMD product specification](https://www.amd.com/en/products/graphics/desktops/radeon/6000-series/amd-radeon-rx-6800.html) |
| Integrated GPU | `AMD Radeon(TM) Graphics` | Local CIM |
| AMD driver | `32.0.12033.1030`, driver date `2024-11-27` | Local CIM |
| ROCm directories | `C:\Program Files\AMD\ROCm\6.2`, `C:\Program Files\AMD\ROCm\6.4` | Local filesystem |

`Win32_VideoController.AdapterRAM` reported approximately `4 GB` for the
discrete RX 6800. Do not use that legacy field as authoritative VRAM evidence:
the official RX 6800 specification is `16 GB GDDR6`.

Ollama officially lists `AMD Radeon RX 6800` as supported on Windows through
ROCm:

- [Ollama Hardware Support](https://docs.ollama.com/gpu)

### Component Placement

| Component | Location |
|---|---|
| Workspace | `C:\Git\ai-ide-check` |
| VS Code CLI | `C:\Program Files\Microsoft VS Code\bin\code.cmd` |
| Claude Code CLI | `C:\Users\user\.local\bin\claude.exe` |
| Claude Code for VS Code | `C:\Users\user\.vscode\extensions\anthropic.claude-code-2.1.159-win32-x64` |
| Ollama executable | `C:\Users\user\AppData\Local\Programs\Ollama\ollama.exe` |
| Ollama logs | `C:\Users\user\AppData\Local\Ollama` |
| Ollama models | `C:\Users\user\.ollama\models` |
| External ROCm selected by shell | `C:\Program Files\AMD\ROCm\6.4\` through `HIP_PATH` |
| Ollama bundled ROCm backend | `C:\Users\user\AppData\Local\Programs\Ollama\lib\ollama\rocm\ggml-hip.dll` |
| Python | `C:\Users\user\AppData\Local\Microsoft\WindowsApps\python.exe` |
| Git | `C:\Program Files\Git\cmd\git.exe` |

`OLLAMA_MODELS` is unset at process, user, and machine scope. The model-storage
path therefore uses the default Windows Ollama location documented in:

- [Ollama For Windows](https://docs.ollama.com/windows)

### Multi-GPU Note

The host exposes both discrete and integrated AMD GPUs. No
`ROCR_VISIBLE_DEVICES` override was set during snapshot collection.

Record `ollama ps` after inference. A valid accelerated run must state whether
the model used GPU, CPU, or a split execution path. Use
`ROCR_VISIBLE_DEVICES` only as an explicit per-stand override and record it in
the run evidence.

For the current coder-only track on `win11-local-rx6800`, split placement is a
blocking condition. Continue coder benchmarking only when:

```text
ollama ps -> 100% GPU
```

### Observed Ollama GPU Evidence

The local Ollama `server.log` confirmed the active inference path:

```text
Device 0: AMD Radeon RX 6800, gfx1030
library=ROCm total="16.0 GiB"
offloaded 37/37 layers to GPU
```

The observed full-layer offload was for `qwen3:8b-q4_K_M`. Keep model-specific
processor placement in individual run records because larger models may use a
split GPU and CPU path.

## Inputs

Every run must define:

- `stand_id`
- validation layer
- workspace or disposable worktree
- endpoint
- model
- exact prompt
- timeout
- permission mode
- relevant environment overrides

## Required Agent Behavior

After the start prompt, the agent must:

1. Read repository context from existing files.
2. Identify relevant files without manual routing.
3. Create or edit at least one file in the disposable workspace.
4. Run at least one debug, test, or validation command.
5. Interpret the real command result.
6. Return a final answer matching the file state and command outcome.

## Success Contract

A run is a pass only if all conditions are true:

- the selected stand is registered or has an attached stand record
- the endpoint and selected model are reachable
- real tool execution occurs
- at least one file operation occurs
- at least one shell or debug command occurs
- the final response reflects the actual workspace state
- processor placement is recorded after inference when GPU behavior matters
- no manual recovery is required after the start prompt

## Failure Contract

A run is a fail if any of the following occurs:

- endpoint or model is unreachable
- API structured tool use is unavailable
- tool calls are printed as text instead of emitted structurally
- the agent can chat but cannot use files
- the agent edits files but cannot run validation commands
- the final answer misreports command output or workspace state
- processor placement is ambiguous in a GPU-specific investigation
- the operator has to complete intermediate steps manually

## Operational Constraints

- Keep the repository under git.
- Use a disposable git worktree for aggressive headless runs.
- Update `CHANGELOG.md` before push.
- Preserve raw transcripts outside git unless promoted as concise evidence.
- Record stand-specific diagnostics without assuming SSH or Linux tools exist.

## Diagnostics By Topology

### Local Windows Ollama

```powershell
curl.exe --silent --show-error --fail http://localhost:11434/api/version
curl.exe --silent --show-error --fail http://localhost:11434/api/tags
ollama ps
Get-Content "$env:LOCALAPPDATA\Ollama\server.log" -Tail 200
```

### Remote Linux Ollama On `bruter`

```bash
curl http://bruter:11434/api/tags
ssh root@bruter 'systemctl status ollama --no-pager'
ssh root@bruter 'journalctl -u ollama -n 200 --no-pager'
ssh root@bruter 'tcpdump -i any -s 0 -w /tmp/ollama-agent-debug.pcap port 11434'
```

## Git Workflow Contract

- Before work: `git status --short`
- After a completed stage: `git add ... && git commit -m "<stage summary>"`
- Before push: update `CHANGELOG.md`, review `git diff --staged`, then push

## Adding A New Stand

1. Copy [Stand Record Template](stand-record-template.md).
2. Assign a stable lowercase `stand_id`.
3. Record topology, OS, GPU or CPU path, component versions, paths, endpoint,
   model storage, and diagnostics.
4. Add one row to **Registered Stands**.
5. Run API surface preflight.
6. Run one CLI headless baseline.
7. Add a VS Code comparison only when IDE behavior is in scope.

## Explicit Non-Goals

- universal support for every IDE
- universal support for every Ollama model
- production hardening of the final platform
- assuming that API-level tool use proves agent reliability

## Coder-Only Evaluation Track

The current next-stage evaluation scope is coder tasks only.

Use:

- [Coder Model Benchmark Strategy](../specs/coder-model-benchmark-strategy.md)
- [Coder Model Evaluation Runbook](../runbooks/coder-model-evaluation.md)

Published leaderboard scores are context, not local verdicts. Promote a model
only after local repository-editing tasks pass on the registered stand.

## Pass/Fail Output

Every run record must include:

- `stand_id`
- topology summary
- chosen model
- configured endpoint
- relevant versions
- accelerator and processor placement
- exact prompt
- files touched
- commands executed
- final answer summary
- pass or fail verdict
- failure class if failed
