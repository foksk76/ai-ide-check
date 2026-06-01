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
- Recorded live-capture findings for `run-002` and prepared `run-003` for `qwen3:8b-q4_K_M`.
- Recorded failed `run-003` IDE outcome for `qwen3:8b-q4_K_M`.
- Added cross-stand handoff with current state and recommended continuation steps.
- Added a verified Windows single-host stand snapshot with local Ollama endpoint,
  tool versions, Claude configuration observations, and the installed model
  inventory.
- Added the Windows local headless Claude Code runner with disposable worktrees,
  explicit localhost Ollama settings, three-stage validation, and raw artifact
  capture.
- Updated the Ollama compatibility checker to prefer the local Windows endpoint
  before the legacy remote `bruter` endpoints.
- Recorded the first Windows local headless baseline: `qwen3:8b-q4_K_M` passed
  cleanly, `gemma4:e4b` passed the tool loop with a final-answer wording defect,
  and `llama3.2:latest` reproduced its empty-turn failure without VS Code.
- Added an Ollama Anthropic Messages surface probe with three-attempt model
  checks, raw JSON evidence, a Markdown report, and a source-backed
  compatibility analysis for Claude Code.
- Expanded the validation contract into a multi-stand registry, added the
  `win11-local-rx6800` hardware and component-placement profile, and added a
  reusable stand record template.
- Added a coder-only benchmark strategy and runbook covering open benchmark
  sources, exact-model score handling, local candidate ordering, and the next
  repository-editing evaluation ladder.
- Added a strict full-GPU gate for the Windows coder track, recorded the
  expanded eligibility results, excluded split CPU/GPU models, and selected
  `qwen2.5-coder:14b` as the next bounded-fixture candidate.
