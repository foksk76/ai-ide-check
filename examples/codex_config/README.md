# Local Codex Configuration Examples

This directory contains examples of how to configure the local development environment for interacting with Codex, specifically tailored for the Hybrid-AI Workflow used in this project (Architect & Builder).

## Overview

To replicate our production-like development environment locally, you need to configure your local model catalog and environment settings. This allows for a clear separation between "Cloud" models (for architecture and high-level planning) and "Local" models (for code generation and implementation).

## Model Configuration (model_catalog.json)

You should maintain a `model_catalog.json` that defines your available models. In our workflow:
- **Architect:** A capable cloud model (e.g., Gemma 4 with high reasoning effort or a larger scale variant) is used for ADR creation and Code Review.
- **Builder:** A local, faster model (e.g., Gemma 4 12B IT QAT via Ollama) is used for executing atomic tasks from the backlog.

Example entry for a local builder model:

```json
{
  "slug": "gemma4:12b-it-qat",
  "display_name": "Gemma 4 12B IT QAT (Local Builder)",
  "description": "Local model served by Ollama for code implementation.",
  "supported_reasoning_levels": [],
  "shell_type": "shell_command",
  "visibility": "list",
  "supported_in_api": true,
  "priority": 0,
  "context_window": 131072,
  "max_context_window": 131072,
  "auto_compact_token_limit": 98304,
  "input_modalities": ["text"],
  "supports_search_tool": false,
  "use_responses_lite": false
}
```

## Environment Configuration (config.toml)

The `config.toml` manages how Codex interacts with these models and the underlying infrastructure. Key sections to configure include:

### Model Providers (e.g., Ollama)
Configure your local inference server:
```toml
[model_providers.remote_ollama]
name = "Ollama on Localhost"
base_url = "http://localhost:11434/v1"
wire_api = "responses"
requires_openai_auth = false
```

### Project Trust Levels
Ensure the repository is recognized as trusted to allow full tool access during development:
```toml
[projects."/path/to/your/repo"]
trust_level = "trusted"
```

## How to Apply Changes
1. Modify your local Codex configuration files (usually in `~/.codex/`).
2. Restart the Codex session or agent to pick up new configurations.
3. Verify that both the Architect and Builder models are correctly detected using the available tools.
