# Spec: VS Code + Claude Code + Ollama Agent Validation

## Objective

Repurpose this repository into a validation and deployment-support toolkit for an IDE-based AI agent connected to a local deployed model through Ollama.

The current stage focuses on one artifact first:

- a reproducible step-by-step acceptance scenario for `Claude Code + Claude Code for VS Code + VS Code + Ollama`

## Current Validation Question

Can the IDE agent complete a real repository task using a candidate Ollama model with actual tool execution, file modification, command execution, and a correct final answer?

## Scope of This Stage

In scope:

- define the validation contract
- define the validation environment
- define the acceptance criteria for agent mode
- define the git workflow for stage checkpoints
- define the remote diagnostic workflow for API-level debugging
- identify which candidate models are worth testing first

Out of scope:

- building a full installer
- broad multi-IDE support
- automatic provisioning of VS Code profiles on every machine
- automated packet analysis pipeline

## Commands

Compatibility precheck:

```bash
python3 tools/check_ollama_model_compat.py
OLLAMA_BASE_URL=http://bruter:11434 python3 tools/check_ollama_model_compat.py
```

Repository inspection:

```bash
rg --files .
git status --short
```

Stage checkpointing:

```bash
git add CHANGELOG.md docs/ tools/
git commit -m "docs: define vscode ollama validation contract"
```

Remote diagnostics:

```bash
ssh root@bruter 'systemctl is-active ollama'
ssh root@bruter 'journalctl -u ollama -n 200 --no-pager'
ssh root@bruter 'tcpdump -i any -s 0 -w /tmp/ollama-agent-debug.pcap port 11434'
```

## Project Structure

- `tools/` → validation scripts and helper diagnostics
- `docs/contracts/` → integration and acceptance contracts
- `docs/specs/` → current-stage specifications
- `docs/plans/` → ordered implementation plans
- `docs/` → reports, environment notes, and runbooks
- `CHANGELOG.md` → push gate summary of notable changes

## Code Style

Documentation:

- Markdown only
- operationally specific language
- commands must be copy-pasteable
- always prefer exact endpoints, exact file paths, and exact model names

Scripts:

- prefer Python standard library
- avoid adding dependencies unless needed
- report facts separately from conclusions

## Testing Strategy

### Level 1: API Capability Precheck

Use the Ollama compatibility script to verify:

- model availability
- `/api/show` metadata
- basic `/v1/messages` success
- structured tool use versus text imitation
- native `/api/chat` comparison

### Level 2: IDE Acceptance Run

Run a real task inside VS Code with a candidate model and record:

- start prompt
- files read
- files changed
- commands run
- final answer

### Level 3: Failure Diagnosis

If the run fails, classify failure as one of:

- configuration failure
- endpoint compatibility failure
- model tool-calling failure
- file operation failure
- command execution failure
- final answer mismatch

When necessary, gather API traffic on `bruter` for end-to-end inspection.

## Boundaries

Always:

- verify actual tool use, not just chat quality
- keep exact notes on environment, prompt, model, and result
- commit stage boundaries in git
- update `CHANGELOG.md` before any push

Ask first:

- adding dependencies
- changing repo structure beyond validation docs and tooling
- introducing long-running capture services on `bruter`
- exporting traffic captures off the server

Never:

- mark a model as agent-compatible if it only prints JSON tool calls
- treat a plain chat success as an agent-mode success
- hide environment assumptions
- push undocumented changes

## Success Criteria

This stage is complete when:

- the validation contract is documented
- the stage spec is documented
- the implementation plan is documented
- the next artifact to create is a concrete acceptance scenario doc
- the repo workflow includes git stage checkpoints and changelog-before-push
- the remote diagnostic path through `ssh root@bruter` is defined

## Open Questions

- What exact repository task becomes the canonical acceptance scenario?
- Which command becomes the canonical debug-run for the scenario?
- Which VS Code settings are mandatory versus optional for the tested flow?
- Do we need one scenario per model class, or one canonical scenario for all candidates?
