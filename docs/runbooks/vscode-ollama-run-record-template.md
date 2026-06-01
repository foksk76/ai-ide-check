# Run Record Template: VS Code Agent + Ollama

## Run Identity

- Run ID:
- Date:
- Operator:
- Git commit:
- Workspace path:

## Environment Snapshot

- VS Code version:
- Claude Code for VS Code version:
- Claude Code CLI/runtime note:
- Endpoint/base URL:
- Model:
- Preflight status: `pass` / `fail`

## Scenario Reference

- Scenario doc: [docs/specs/vscode-ollama-acceptance-scenario.md](/home/krl/git/check_sip/docs/specs/vscode-ollama-acceptance-scenario.md:1)
- Environment matrix used: [docs/specs/vscode-ollama-environment-matrix.md](/home/krl/git/check_sip/docs/specs/vscode-ollama-environment-matrix.md:1)
- Failure taxonomy used: [docs/specs/vscode-ollama-failure-taxonomy.md](/home/krl/git/check_sip/docs/specs/vscode-ollama-failure-taxonomy.md:1)

## Exact Prompt

```text
Paste the exact prompt used here.
```

## Preflight Checks

- `git status --short`:
- `python3 --version`:
- `curl http://bruter:11434/api/tags`:
- `python3 tools/check_ollama_model_compat.py`:
- `ssh root@bruter 'systemctl is-active ollama'`:
- `ssh root@bruter 'command -v tcpdump'`:

## Agent Actions Observed

- Files read:
- Searches/listings used:
- Files created:
- Files modified:
- Commands executed:

## Expected Artifact Check

- Target file expected: `docs/runbooks/ide-agent-smoke-test.md`
- Was target file created?:
- Did file content reflect repository facts?:
- Did the agent run `python3 tools/check_ollama_model_compat.py`?:

## Command Outcome

- Command exit status:
- Command summary:
- Compatible models observed:
- Any mismatch between output and final answer?:

## Final Answer Check

- Did the final answer mention files used for context?:
- Did the final answer correctly report file creation status?:
- Did the final answer correctly report command success/failure?:
- Did the final answer correctly identify compatible models?:

## Verdict

- Result: `PASS` / `FAIL`
- Primary failure class:
- Secondary notes:

## Diagnostics

- IDE transcript saved:
- Ollama logs checked:
- Traffic capture taken:
- Capture/log paths:

## Notes

- Anything unusual about latency, retries, or operator intervention:
