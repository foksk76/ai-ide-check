# Implementation Plan: VS Code + Ollama Agent Validation

## Overview

This plan turns the repository into a validation-first toolkit for proving whether an IDE agent backed by Ollama can do real work in a repository.

The immediate priority is not deployment automation. It is a reliable acceptance workflow with clear pass/fail evidence.

## Architecture Decisions

- Use Ollama compatibility checks as a preflight gate before IDE testing.
- Treat structured tool use through the Anthropic-compatible endpoint as the main compatibility requirement.
- Keep stage artifacts in git and require `CHANGELOG.md` updates before any push.
- Use `ssh-agent` access to `root@bruter` for targeted end-to-end API diagnostics when failures are unclear.
- Separate validation artifacts from future deployment automation.

## Phase 1: Foundation Documents

### Task 1: Define the integration contract

Acceptance:

- contract covers inputs, behavior, outputs, pass/fail, and constraints

Verify:

- review [docs/contracts/vscode-ollama-agent-contract.md](/home/krl/git/check_sip/docs/contracts/vscode-ollama-agent-contract.md:1)

Dependencies:

- None

### Task 2: Define the stage spec

Acceptance:

- spec covers objective, commands, structure, testing strategy, boundaries, and success criteria

Verify:

- review [docs/specs/vscode-ollama-agent-spec.md](/home/krl/git/check_sip/docs/specs/vscode-ollama-agent-spec.md:1)

Dependencies:

- Task 1

### Task 3: Define the stage plan

Acceptance:

- plan breaks the work into ordered stages with verification points

Verify:

- review [docs/plans/vscode-ollama-agent-plan.md](/home/krl/git/check_sip/docs/plans/vscode-ollama-agent-plan.md:1)

Dependencies:

- Task 1
- Task 2

### Checkpoint: Docs Baseline

- commit contract/spec/plan
- update `CHANGELOG.md`
- verify `git status --short` is clean after commit

## Phase 2: Acceptance Scenario Design

### Task 4: Define the canonical IDE task

Acceptance:

- one concrete repository task is chosen for all validation runs
- task requires reading context, editing files, running a command, and returning a final answer

Verify:

- new scenario draft lists exact prompt and expected agent actions

Dependencies:

- Phase 1 complete

### Task 5: Write the acceptance scenario document

Acceptance:

- scenario includes exact start prompt
- scenario includes expected tool classes
- scenario includes pass/fail checklist

Verify:

- a second operator can follow the document without verbal guidance

Dependencies:

- Task 4

### Checkpoint: Scenario Ready

- commit scenario docs
- update `CHANGELOG.md`
- confirm the scenario can be run manually

## Phase 3: Environment Matrix and Failure Taxonomy

### Task 6: Define the environment matrix

Acceptance:

- matrix lists all required components and mandatory properties
- model endpoint, VS Code, extension, and workspace assumptions are explicit

Verify:

- environment matrix can explain what is misconfigured before a run starts

Dependencies:

- Phase 2 complete

### Task 7: Define the failure taxonomy

Acceptance:

- failures are grouped by config, API, model, tool use, file ops, command execution, and final response integrity

Verify:

- any failed run can be placed in exactly one primary failure bucket

Dependencies:

- Task 5

### Checkpoint: Diagnosis Layer Ready

- commit diagnostics docs
- update `CHANGELOG.md`
- review whether tcpdump capture instructions need refinement

## Phase 4: Real Model Validation

### Task 8: Preflight candidate models

Acceptance:

- candidate models are checked with `tools/check_ollama_model_compat.py`
- shortlist and blacklist are updated from factual results

Verify:

- compatibility report exists and is current

Dependencies:

- Phase 3 complete

### Task 9: Run the IDE scenario against shortlisted models

Acceptance:

- each run records model, prompt, files changed, commands executed, and final answer
- pass/fail verdict is documented for every model tested

Verify:

- results can distinguish true agent compatibility from plain chat compatibility

Dependencies:

- Task 8

### Task 10: Use remote traffic capture for ambiguous failures

Acceptance:

- when a run is inconclusive, diagnostic capture can be taken on `bruter`
- capture instructions are tied to the failing time window and port

Verify:

- operator can correlate IDE action timing with server-side traffic

Dependencies:

- Task 9 as needed

### Checkpoint: Validation Evidence Complete

- commit run evidence and conclusions
- update `CHANGELOG.md`
- prepare push only after reviewing staged changes

## Phase 5: Transition Toward Deployment Tooling

### Task 11: Identify reusable automation

Acceptance:

- separate what should remain documentation from what should become scripts or templates

Verify:

- next-stage backlog is written down

Dependencies:

- Phase 4 complete

## Risks and Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Model advertises tools but only prints JSON | High | Keep `/v1/messages` structured tool-use as the real gate |
| VS Code config differs from documented assumptions | High | Create environment matrix before mass testing |
| Remote failures are hard to localize | Medium | Use `ssh root@bruter` checks and targeted `tcpdump` capture |
| Validation scope drifts into deployment work too early | Medium | Keep stage boundaries explicit in docs and commits |

## Recommended Next Action

Create the canonical acceptance scenario document next, then run it first against:

1. `gemma4:e4b`
2. `llama3.2:latest`
3. `qwen2.5-coder:7b-instruct-q4_K_M` as a known negative control
