# Tools

Operational scripts for local model validation.

| File | Purpose |
|---|---|
| `run_claude_ollama_headless.ps1` | Windows Claude Code + Ollama staged gate: `handshake`, `tool`, `agent`. |
| `run_coder_fixture_bench.ps1` | Windows coder fixture benchmark runner. |
| `check_ollama_anthropic_surface.py` | Probe Ollama's Anthropic-compatible surface. |
| `check_ollama_model_compat.py` | Earlier compatibility checker for model/tool behavior. |
| `prepare_linux_phase1.sh` | Linux stand snapshot and optional model preparation. |
| `run_linux_phase1_cli_contract.sh` | Linux Claude Code CLI contract runner. |
| `generate_readme_charts.ps1` | Manual publication helper: generate report PNG charts. |
| `export_readme_report.py` | Manual publication helper: export a prepared Markdown report to PDF. |
| `modelfiles/` | Reproducible Ollama context profiles. |

The chart and PDF helpers are intentionally outside the mandatory benchmark
path. Automated runs should produce evidence first; human-facing reports are
assembled afterward.
