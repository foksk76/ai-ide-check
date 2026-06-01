# Contract: VS Code Agent + Ollama Validation

## Objective

Define the operational contract for validating an IDE-based AI agent workflow backed by a locally deployed model exposed through Ollama.

This contract is for the current validation stage only. It answers one question:

Can `Claude Code + Claude Code for VS Code + VS Code + Ollama` complete a real agent task in the IDE with actual tool use?

## System Under Test

- VS Code running on the operator workstation
- Claude Code CLI available to the extension/runtime
- Claude Code for VS Code installed and enabled
- Ollama reachable through an Anthropic-compatible API base URL
- A candidate local or remote model exposed by Ollama
- A git-backed workspace opened in VS Code

## Primary User

- Operator validating whether a local-model-backed IDE agent is usable for real development work

## Inputs

- Open workspace with a real test repository
- Configured model endpoint
- Start prompt for a real task
- A candidate model selected for the session
- Workspace permissions allowing file read, file write, and command execution

## Required Agent Behavior

The agent must complete the following sequence after the user sends the start prompt:

1. Read repository context from existing files.
2. Identify relevant files without the user manually routing every step.
3. Create or edit at least one file in the workspace.
4. Run at least one debug, test, or validation command in the workspace.
5. Interpret the command result.
6. Return a final answer that matches the actual file changes and command outcome.

## Success Contract

The validation run is a pass only if all conditions below are true:

- The model is reachable through the configured endpoint.
- The agent uses real tool execution rather than plain chat imitation.
- At least one file operation is actually executed.
- At least one shell or debug command is actually executed.
- The final response reflects the real workspace state.
- The user does not need to manually perform the task after providing the initial prompt.

## Failure Contract

The validation run is a fail if any of the following occurs:

- The model cannot answer through the configured endpoint.
- Tool use is unavailable at the API layer.
- The model prints tool calls as JSON text instead of issuing structured tool use.
- The agent can chat but cannot create or modify files.
- The agent can edit files but cannot execute validation commands.
- The agent executes actions, but the final answer misreports the result.
- The operator has to manually copy commands, perform file edits, or recover the workflow.

## Operational Constraints

- The repository must stay under git for every validation stage.
- Each stage should be checkpointed with a commit before moving to the next one.
- `CHANGELOG.md` must be updated before any `git push`.
- Remote diagnostics may use `ssh-agent` login to `root@bruter`.
- End-to-end API diagnostics may capture traffic on `bruter` with `tcpdump` when tool behavior is ambiguous.

## Git Workflow Contract

- Before work: `git status --short`
- After a completed stage: `git add ... && git commit -m "<stage summary>"`
- Before push: update `CHANGELOG.md`, review `git diff --staged`, then push

## Remote Diagnostics Contract

When API behavior is unclear, diagnostics may use:

```bash
ssh root@bruter 'tcpdump -i any -s 0 -w /tmp/ollama-agent-debug.pcap port 11434'
```

Recommended supporting checks:

```bash
ssh root@bruter 'systemctl status ollama --no-pager'
ssh root@bruter 'journalctl -u ollama -n 200 --no-pager'
curl http://bruter:11434/api/tags
```

## Explicit Non-Goals

- Full deployment automation for every workstation
- Universal support for every IDE
- Universal support for every Ollama model
- Production hardening of the final platform

## Pass/Fail Output

Every validation run should produce:

- chosen model
- configured endpoint
- exact start prompt
- files touched
- command(s) executed
- final agent answer summary
- pass or fail verdict
- failure class if failed
