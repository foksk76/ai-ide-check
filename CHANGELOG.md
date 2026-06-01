# Changelog

## Unreleased

### Added
- Initial validation documentation for `Claude Code + Claude Code for VS Code + VS Code + Ollama`.
- Contract, spec, and implementation plan for IDE agent-mode acceptance testing.
- Git and remote traffic-capture workflow requirements for future diagnostics.
- Canonical VS Code acceptance scenario for end-to-end agent-mode validation.
- Environment matrix and failure taxonomy for IDE agent validation runs.
- Model-by-model run log and reusable E2E run record template.
- Preflight-backed `run-001` record for `gemma4:e4b` and refreshed candidate log with `qwen3:8b-q4_K_M`.
- Recorded failed `run-001` IDE outcome for `gemma4:e4b` and refined failure taxonomy for clarification-only behavior.
- Prepared preflight-backed `run-002` package for `llama3.2:latest`.
- Added `docs/runbooks/ide-agent-smoke-test.md` and refreshed the compatibility report.
- Added server-side `bruter` API debug findings with raw request/response evidence.
- Added reusable live-capture helper and runbook for the next IDE debug run.
