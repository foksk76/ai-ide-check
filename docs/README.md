# Documentation Index

This directory is organized by how the information is used.

Start here when the repository is too large to read end to end.

## Current Entry Points

| Need | Read |
|---|---|
| Current project state and next work | [Current Roadmap](plans/current-roadmap.md) |
| Model retry queue and deferred candidates | [Model Retry Backlog](plans/model-retry-backlog.md) |
| Claude Code + Ollama validation rules | [Stand Validation Contract](contracts/vscode-ollama-agent-contract.md) |
| Coder-model evaluation strategy | [Coder Model Benchmark Strategy](specs/coder-model-benchmark-strategy.md) |
| Reverse-engineering project idea | [Reverse Engineering Evaluation Idea](specs/reverse-engineering-model-evaluation-idea.md) |
| Reverse-engineering stand roles | [Reverse Engineering System Roles](specs/reverse-engineering-model-system-roles.md) |

## Directory Roles

| Directory | Content |
|---|---|
| `assets/` | Images used by reports and README. |
| `archive/` | Historical material kept for traceability, not current guidance. |
| `contracts/` | Stable validation contracts and reusable templates. |
| `plans/` | Living roadmap and future work queues. |
| `releases/` | Release notes. |
| `reports/` | Human-readable reports and raw report evidence. |
| `runbooks/` | How to run checks and dated run records. |
| `specs/` | Design notes, evaluation ideas, and project hypotheses. |
| `stands/` | Stand snapshots and environment descriptions. |

## Search Hints

- Use `docs/plans/current-roadmap.md` for the next action.
- Use `docs/runbooks/runs/` for dated evidence.
- Use `docs/reports/` for summaries intended for humans.
- Use `docs/archive/` only when checking how an older decision was made.
- Raw local transcripts usually live under `.artifacts/` and are intentionally
  not committed.

