# Acceptance Scenario: VS Code Agent + Ollama End-to-End

## Objective

Define one canonical end-to-end scenario for validating whether `Claude Code + Claude Code for VS Code + VS Code + Ollama` can complete a real repository task with actual tool use.

This scenario is intentionally small, repeatable, and safe for repeated execution.

## Canonical Task

The agent must:

1. read the existing repository context
2. create one new runbook document
3. run the Ollama compatibility check command
4. interpret the command result
5. return a final answer grounded in real file changes and command output

## Why This Task

This task exercises the full minimum agent loop without needing production code changes:

- repository discovery
- file creation
- content synthesis from local docs
- local command execution
- factual final reporting

## Preconditions

The operator must confirm all of the following before starting:

- VS Code is open on this repository
- Claude Code for VS Code is enabled
- the model is configured through the intended Ollama endpoint
- the agent session has file read, file write, and command execution permissions
- `python3` is available in the environment
- `tools/check_ollama_model_compat.py` exists

Recommended candidate order:

1. `gemma4:e4b`
2. `llama3.2:latest`
3. `qwen3:8b-q4_K_M`
4. `qwen2.5-coder:7b-instruct-q4_K_M` as negative control

## Operator Actions

The operator may do only the following:

1. Open VS Code on the repository.
2. Select the intended model/configuration.
3. Start a fresh Claude Code session.
4. Paste the exact start prompt below.
5. Observe.

The operator must not manually help the agent with commands, file names, or intermediate decisions after the prompt is sent.

## Exact Start Prompt

Use this exact prompt:

```text
Read the repository context and create a new file at docs/runbooks/ide-agent-smoke-test.md.

The file must briefly explain:
1. what this repository is validating right now;
2. which models are currently the best candidates for Claude Code agent mode;
3. which model is a known negative control and why;
4. how to run the compatibility precheck command.

Base the content only on files already present in the repository.

After writing the file, run:
python3 tools/check_ollama_model_compat.py

Then give a final answer that includes:
- which files you used for context;
- whether the file was created successfully;
- whether the command succeeded or failed;
- which models appear Claude Code compatible from the command result.
```

## Expected Tool Classes

The agent is expected to use these classes of actions:

- file read
- directory listing or search
- file create or file write
- shell command execution
- final natural-language response

## Expected Repository Reads

The exact reads may vary, but the agent should consult some subset of:

- [docs/contracts/vscode-ollama-agent-contract.md](/home/krl/git/check_sip/docs/contracts/vscode-ollama-agent-contract.md:1)
- [docs/specs/vscode-ollama-agent-spec.md](/home/krl/git/check_sip/docs/specs/vscode-ollama-agent-spec.md:1)
- [docs/plans/vscode-ollama-agent-plan.md](/home/krl/git/check_sip/docs/plans/vscode-ollama-agent-plan.md:1)
- [docs/ollama-model-compatibility-report.md](/home/krl/git/check_sip/docs/ollama-model-compatibility-report.md:1)
- [tools/check_ollama_model_compat.py](/home/krl/git/check_sip/tools/check_ollama_model_compat.py:1)

## Expected File Outcome

The agent should create:

- `docs/runbooks/ide-agent-smoke-test.md`

Expected content characteristics:

- concise runbook style
- mentions the current validation purpose
- names `gemma4:e4b` and `llama3.2:latest` as current positive candidates if the report still says so
- names `qwen2.5-coder:7b-instruct-q4_K_M` as a negative control because it prints tool-call JSON as text
- includes the compatibility precheck command

## Expected Command Outcome

Expected command:

```bash
python3 tools/check_ollama_model_compat.py
```

Expected success shape:

- command exits successfully
- output includes a table
- output identifies at least one Claude Code compatible model

If the command fails because the remote endpoint is unavailable, the run is not an automatic pass. It must be classified separately.

## Pass Criteria

Mark the run as `PASS` only if all statements below are true:

- the agent read repository context without being hand-held
- the agent created `docs/runbooks/ide-agent-smoke-test.md`
- the created file reflects repository facts rather than generic filler
- the agent ran `python3 tools/check_ollama_model_compat.py`
- the final answer correctly states whether the command succeeded
- the final answer correctly identifies the compatible models from the actual command result
- the interaction relied on real tool execution, not printed JSON imitation

## Fail Criteria

Mark the run as `FAIL` if any of the following happens:

- the model answers only in plain chat and does not use tools
- the model prints a tool call as JSON text
- the agent cannot find or create the target file
- the agent skips the command run
- the agent invents command results
- the final answer contradicts the real file state or command result
- the user has to take over after the prompt is sent

## Evidence to Record

For every run, capture:

- date/time
- model name
- endpoint/base URL
- exact prompt
- files read
- files changed
- command run
- final answer summary
- pass/fail verdict
- failure class if failed

## Failure Classification

Use one primary failure class:

- `config`: VS Code, extension, auth, or endpoint configuration issue
- `api`: Anthropic-compatible API behavior is broken or incomplete
- `model-tools`: model does not produce structured tool use
- `workspace-write`: agent cannot create or modify files
- `command-exec`: agent cannot run or interpret the command
- `final-answer`: actions happened, but the answer is inaccurate

## Diagnostic Escalation

If the run is ambiguous:

1. save the exact IDE transcript if available
2. repeat the API precheck outside VS Code
3. if still unclear, capture traffic on `bruter`

Example capture command:

```bash
ssh root@bruter 'tcpdump -i any -s 0 -w /tmp/ollama-agent-debug.pcap port 11434'
```

Recommended supporting checks:

```bash
ssh root@bruter 'journalctl -u ollama -n 200 --no-pager'
curl http://bruter:11434/api/tags
```

## Verification Checklist

- [ ] The prompt was pasted exactly as written
- [ ] The agent created the runbook file
- [ ] The agent ran the compatibility command
- [ ] The final answer matched the actual outcome
- [ ] The run was recorded with a pass/fail verdict

## Next Document After This One

After this scenario is accepted, create:

- environment matrix
- failure taxonomy reference
- model-by-model run log
