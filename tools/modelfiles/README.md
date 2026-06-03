# Ollama Modelfiles

Each file defines a reproducible local Ollama profile.

Naming convention:

```text
<model-family>-<size-or-tag>-ctx<context>.Modelfile
```

Examples:

```powershell
ollama create gpt-oss:20b-ctx32k -f tools\modelfiles\gpt-oss-20b-ctx32k.Modelfile
ollama create ministral-3:3b-ctx32k -f tools\modelfiles\ministral-3-3b-ctx32k.Modelfile
```

Profiles are stand-specific evidence helpers. A model still needs local
placement and tool-loop validation before it can be promoted.

