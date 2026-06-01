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
- Recorded the failed `qwen2.5-coder:14b` full-GPU preflight and tightened the
  headless runner so printed tool-call JSON cannot pass as real Bash execution.
- Selected the smaller `qwen2.5-coder:7b` Ollama tag as the pending replacement
  third coder candidate for full-GPU and structured-tool verification.
- Recorded that `qwen2.5-coder:7b` fits fully in GPU memory but still fails the
  Claude Code structured tool loop by printing Bash and Read JSON as text.
- Added a reproducible `granite4.1:8b-ctx32k` Ollama profile after the upstream
  `131072` context default forced CPU KV-cache placement on the RX 6800.
- Recorded the tuned Granite profile as the third full-GPU coder candidate:
  it passed handshake, structured Bash execution, repository read, file
  creation, and git-status grounding with `41/41` layers on GPU.
- Added `ctx32k` placement profiles for the larger rejected models and recorded
  that context tuning reduced CPU spill without returning them to the strict
  RX 6800 full-GPU shortlist.
- Added a fixed-step context sweep for the three favored models and selected
  model-specific placement profiles: Qwen `40960`, Gemma `131072`, and Granite
  `32768`.
- Recorded that Gemma's current multi-step agent failure reproduces at both
  `ctx32k` and `ctx128k`, so its placement optimum is not an agent-qualified
  default.
- Added two unconventional rising Ollama candidates: `ministral-3:8b-ctx32k`
  reached a full agent pass on retry, while `nemotron-3-nano:4b-ctx32k`
  failed to follow the Claude Code task flow despite its small GPU footprint.
- Added a Russian project README with a concise narrative report and generated
  PNG charts for GPU footprint, first-attempt stage completion, and successful
  file-work latency.
- Continued the unconventional-model search after the Nemotron rejection and
  selected `gpt-oss:20b-ctx32k` as the fifth working RX 6800 profile: it passed
  handshake, structured tool use, and repository editing at `100% GPU`.
- Refined the README charts to include working profiles only, added explanatory
  labels, and added a selected-context-window chart.
