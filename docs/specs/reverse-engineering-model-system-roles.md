# Reverse Engineering Model System Roles

## Status

Working architecture for the current available stands.

The available hardware is asymmetric:

- Windows 11 host with GPU is the current LLM inference stand.
- Proxmox VE 9.2 host has no GPU and is the isolated lab stand.

This means the project should not try to make Proxmox the main local-model
benchmark node yet. The clean split is: Windows thinks, Proxmox checks.

## Stand Roles

| Stand | Primary role | What runs there | What should not run there |
|---|---|---|---|
| Windows 11 + GPU | Local LLM inference and model selection | Ollama, Claude Code CLI, Claude Code for VS Code, local model benchmarks, reverse-engineering reasoning prompts | Unsafe dynamic firmware execution |
| Proxmox VE 9.2 without GPU | Isolated analysis and reproduction lab | LXC for static tooling, VM for dynamic checks, artifact storage, controlled firmware experiments | Heavy local LLM benchmarks |
| Cloud LLM | Escalation for hard branches | Difficult analysis, second opinion, summarization of large evidence bundles | Unconfirmed claims treated as findings |

## Windows GPU Stand

Keep Windows as the only current local GPU inference stand.

Responsibilities:

- run Ollama models that require GPU;
- execute Claude Code CLI headless tests;
- compare Claude Code for VS Code behavior after CLI evidence exists;
- test candidate models for structured tool use;
- evaluate decompiler/refinement model output when the model fits locally;
- generate hypotheses, patch drafts, and next-check plans from Proxmox
  artifacts.

Rules:

- keep `ollama ps -> 100% GPU` as the strict local-model gate unless a run is
  explicitly marked as a CPU/RAM spill experiment;
- store raw model transcripts in `.artifacts/`;
- never treat a model explanation as confirmed without a Proxmox or fixture
  reproduction step.

## Proxmox VE 9.2 Without GPU

Use Proxmox as the isolated lab, not as the main inference host.

Responsibilities:

- host virtual firmware images;
- run isolated dynamic checks in VM snapshots;
- run static analysis and unpacking tasks in LXC;
- keep reproducible evidence bundles;
- provide a clean boundary before any deployment or dynamic test.

Recommended layout:

| Layer | Role | Examples |
|---|---|---|
| LXC | Static analysis and services | `binwalk`, `file`, `strings`, `yara`, Ghidra headless, Python parsers, report builders |
| VM | Dynamic and risky behavior checks | firmware boot tests, service interaction, suspicious behavior reproduction, patch regression |
| Shared artifact store | Evidence transfer | firmware digest, Ghidra exports, logs, model prompts, model answers, test results |

LXC is useful because it is light and easy to automate. VM is required when the
task needs stronger isolation, a separate kernel boundary, snapshots, or
controlled execution of suspicious behavior.

## LXC Requirements

Use LXC for static and service-like work only.

Minimum requirements:

- unprivileged container by default;
- no direct internet access unless a runbook explicitly needs it;
- read-only input mount for firmware samples where practical;
- separate writable output mount for artifacts;
- pinned tool versions recorded in each run manifest;
- no privileged device passthrough as a default pattern;
- no heavy Ollama benchmark workload.

Suggested static-tool container:

```text
re-static-lxc
  tools: file, strings, binwalk, yara, python, ghidra headless
  input: read-only firmware/sample mount
  output: artifact mount
  network: restricted
```

## VM Requirements

Use VM for dynamic checks.

Minimum requirements:

- snapshot before each dynamic run;
- isolated network or controlled test bridge;
- clear sample identity and digest before execution;
- logs exported after each run;
- rollback after each risky branch;
- no direct path to the Windows workstation except controlled artifact
  transfer.

Suggested dynamic VM pattern:

```text
re-dynamic-vm-<case>
  boot from clean snapshot
  import sample or virtual firmware image
  run bounded check
  export logs and observations
  rollback or destroy
```

## Data Flow

```text
Proxmox LXC/VM
  -> collect static and dynamic evidence
  -> export artifact bundle

Windows GPU
  -> run local LLM analysis
  -> create hypotheses, explanations, patch drafts, next checks

Proxmox VM or local fixture
  -> reproduce or reject hypothesis
  -> run regression checks
  -> produce reviewed finding
```

Cloud models may enter only after local analysis is insufficient or the branch
is too complex for the current local models. Record why escalation happened.

## Operating Rule

Before deploying a sample or running a dynamic test on the isolated stand:

```text
REQUEST STAND ACCESS
```

The request should name:

- target VM or LXC;
- sample or firmware digest;
- intended action;
- expected output;
- rollback plan;
- artifact destination.

## Decision

For the current hardware:

1. Use Windows 11 + GPU as the main local LLM stand.
2. Use Proxmox VE 9.2 without GPU as the isolated reverse-engineering lab.
3. Use LXC for static analysis, automation, and artifact preparation.
4. Use VM for dynamic firmware behavior and suspicious-code checks.
5. Do not move heavy Ollama benchmarking to Proxmox until a GPU is added.

