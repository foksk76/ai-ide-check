# Technical Work Environment: Remote Ollama + Claude Code for VS Code

## Purpose

This document defines the project AI-assisted development environment.

The environment uses:

- a remote Ollama server;
- Claude Code for VS Code;
- separate VS Code profiles for coding, user documentation, and technical documentation validation;
- two local Ollama models selected for stable work with GeForce RTX 3080 10 GB.

## Target Architecture

```text
VS Code workstation
  └─ Claude Code for VS Code
       └─ Anthropic-compatible API
            └─ Remote Ollama
                 ├─ qwen2.5-coder:7b-instruct-q4_K_M
                 └─ gemma3:12b-it-q4_K_M
```

## Remote Ollama Endpoint

```text
http://10.179.254.250:11434
```

## Selected Models

| Role | Model | Usage |
|---|---|---|
| Coding and development documentation | `qwen2.5-coder:7b-instruct-q4_K_M` | Python, Airflow, SSH, AD collector, tests, `AGENTS.md`, developer documentation |
| User-readable documentation | `gemma3:12b-it-q4_K_M` | `README.md`, `user-guide.md`, `admin-guide.md`, FAQ, troubleshooting |
| Final technical documentation check | `qwen2.5-coder:7b-instruct-q4_K_M` | Validation of commands, file paths, environment variables, and code references |

## Prepare Remote Ollama on Ubuntu

Install or update Ollama using the standard Ollama installation procedure.

Pull required models:

```bash
ollama pull qwen2.5-coder:7b-instruct-q4_K_M
ollama pull gemma3:12b-it-q4_K_M
ollama list
```

Edit the systemd service drop-in:

```bash
sudo systemctl edit ollama.service
```

Add the following configuration:

```ini
[Service]
Environment="OLLAMA_HOST=0.0.0.0"
Environment="OLLAMA_CONTEXT_LENGTH=8192"
Environment="OLLAMA_FLASH_ATTENTION=1"
Environment="OLLAMA_KV_CACHE_TYPE=q8_0"
Environment="OLLAMA_NUM_PARALLEL=1"
Environment="OLLAMA_MAX_LOADED_MODELS=1"
Environment="OLLAMA_KEEP_ALIVE=15m"
Environment="OLLAMA_MAX_QUEUE=16"
```

Apply changes:

```bash
sudo systemctl daemon-reload
sudo systemctl restart ollama.service
sudo systemctl status ollama.service
```

Check Ollama availability from the VS Code workstation:

```bash
curl http://10.179.254.250:11434/api/tags
```

Check model placement and context on the Ollama server:

```bash
ollama ps
```

Expected stable state:

```text
PROCESSOR    CONTEXT
100% GPU     8192
```

If a model is partially loaded into CPU/RAM, reduce the context length:

```ini
Environment="OLLAMA_CONTEXT_LENGTH=4096"
```

## VS Code Requirements

The workstation must have:

- VS Code;
- Claude Code CLI;
- Claude Code for VS Code extension.

Create three VS Code profiles:

```text
Claude Code - Qwen Code
Claude Code - Gemma Docs
Claude Code - Qwen Doc Check
```

After switching a profile, reload the VS Code window:

```text
Command Palette -> Developer: Reload Window
```

## VS Code Profile: Claude Code - Qwen Code

Profile purpose:

```text
coding
tests
refactoring
Airflow DAGs
SSH transport
AD collector
AGENTS.md
README-dev.md
technical runbooks
```

`settings.json` fragment:

```json
{
    "claudeCode.preferredLocation": "panel",
    "claudeCode.environmentVariables": [
        {
            "name": "ANTHROPIC_AUTH_TOKEN",
            "value": "ollama"
        },
        {
            "name": "ANTHROPIC_API_KEY",
            "value": "ollama"
        },
        {
            "name": "ANTHROPIC_BASE_URL",
            "value": "http://10.179.254.250:11434"
        },
        {
            "name": "ANTHROPIC_MODEL",
            "value": "qwen2.5-coder:7b-instruct-q4_K_M"
        },
        {
            "name": "ANTHROPIC_DEFAULT_SONNET_MODEL",
            "value": "qwen2.5-coder:7b-instruct-q4_K_M"
        },
        {
            "name": "ANTHROPIC_DEFAULT_HAIKU_MODEL",
            "value": "qwen2.5-coder:7b-instruct-q4_K_M"
        },
        {
            "name": "CLAUDE_CODE_SUBAGENT_MODEL",
            "value": "qwen2.5-coder:7b-instruct-q4_K_M"
        },
        {
            "name": "API_TIMEOUT_MS",
            "value": "1200000"
        },
        {
            "name": "BASH_DEFAULT_TIMEOUT_MS",
            "value": "300000"
        },
        {
            "name": "BASH_MAX_TIMEOUT_MS",
            "value": "1200000"
        },
        {
            "name": "CLAUDE_CODE_MAX_OUTPUT_TOKENS",
            "value": "4096"
        }
    ]
}
```

## VS Code Profile: Claude Code - Gemma Docs

Profile purpose:

```text
user-facing README.md
user-guide.md
admin-guide.md
install.md
troubleshooting.md
faq.md
plain user instructions
usage scenario descriptions
```

`settings.json` fragment:

```json
{
    "claudeCode.preferredLocation": "panel",
    "claudeCode.environmentVariables": [
        {
            "name": "ANTHROPIC_AUTH_TOKEN",
            "value": "ollama"
        },
        {
            "name": "ANTHROPIC_API_KEY",
            "value": "ollama"
        },
        {
            "name": "ANTHROPIC_BASE_URL",
            "value": "http://10.179.254.250:11434"
        },
        {
            "name": "ANTHROPIC_MODEL",
            "value": "gemma3:12b-it-q4_K_M"
        },
        {
            "name": "ANTHROPIC_DEFAULT_SONNET_MODEL",
            "value": "gemma3:12b-it-q4_K_M"
        },
        {
            "name": "ANTHROPIC_DEFAULT_HAIKU_MODEL",
            "value": "gemma3:12b-it-q4_K_M"
        },
        {
            "name": "CLAUDE_CODE_SUBAGENT_MODEL",
            "value": "gemma3:12b-it-q4_K_M"
        },
        {
            "name": "API_TIMEOUT_MS",
            "value": "1200000"
        },
        {
            "name": "BASH_DEFAULT_TIMEOUT_MS",
            "value": "300000"
        },
        {
            "name": "BASH_MAX_TIMEOUT_MS",
            "value": "1200000"
        },
        {
            "name": "CLAUDE_CODE_MAX_OUTPUT_TOKENS",
            "value": "4096"
        }
    ]
}
```

Recommended prompt discipline:

```text
Write user-facing documentation only.
Do not change source code.
Do not change commands, file names, configuration parameters, or environment variables.
If a technical detail is unclear, mark it as TODO for Qwen technical check.
```

## VS Code Profile: Claude Code - Qwen Doc Check

Profile purpose:

```text
final technical documentation validation
checking README/user-guide/admin-guide against the code
checking startup commands
checking environment variables
checking file paths
checking Airflow DAG / SSH / AD collector references
```

Use the same model configuration as the `Claude Code - Qwen Code` profile.

Recommended prompt discipline:

```text
Check documentation against the actual repository.
Do not rewrite style.
Validate only technical correctness:
- commands;
- environment variables;
- configuration parameters;
- file paths;
- module names;
- Airflow DAG names;
- SSH transport behavior;
- AD collector behavior;
- tests.

Return findings as:
file -> issue -> recommended fix.
```

## Basic Security Notes

Do not expose Ollama directly to untrusted networks.

Access to port `11434` must be restricted by firewall or VPN.

UFW example:

```bash
sudo ufw allow from <VS_CODE_CLIENT_IP> to any port 11434 proto tcp
sudo ufw deny 11434/tcp
sudo ufw status numbered
```

## Recommended Project Placement

```text
docs/stands/remote-ollama-vscode-work-environment.en.md
```

## Operating Rule

```text
Qwen Code profile:
  code, tests, development technical documentation

Gemma Docs profile:
  user-facing documentation

Qwen Doc Check profile:
  final technical documentation validation before commit
```
