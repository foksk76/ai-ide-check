# Environment Matrix: VS Code Agent + Ollama

## Objective

Define the minimum environment contract that must be true before running the IDE acceptance scenario.

This document is a preflight matrix. If any required row is not satisfied, the run should be blocked or explicitly marked as invalid.

## Validation Layers

| Layer | Component | Required | Why it matters | How to verify |
|---|---|---|---|---|
| Editor | VS Code | Yes | Host environment for the tested agent workflow | Open repository workspace in VS Code |
| Extension | Claude Code for VS Code | Yes | Provides the IDE agent session being validated | Confirm extension is installed and enabled |
| CLI/runtime | Claude Code CLI integration | Yes | Supports command and workspace operations expected by the agent | Start a fresh Claude Code session in the IDE |
| API endpoint | Ollama Anthropic-compatible endpoint | Yes | Main transport path for agent requests | `curl http://bruter:11434/api/tags` |
| Model | Candidate Ollama model | Yes | Determines actual tool-calling behavior | `python3 tools/check_ollama_model_compat.py` |
| Workspace | Git-backed local repository | Yes | Gives the agent real context and files to modify | `git rev-parse --show-toplevel` |
| Permissions | File read/write and command execution | Yes | Required for agent-mode validation | Run the acceptance scenario and observe tool execution |
| Python runtime | `python3` | Yes | Required for the compatibility precheck command | `python3 --version` |
| Remote diagnostics | SSH access to `root@bruter` | Strongly recommended | Required for end-to-end API diagnosis on ambiguous failures | `ssh root@bruter 'echo connected'` |
| Traffic capture | `tcpdump` on `bruter` | Recommended | Lets us inspect API behavior when logs are insufficient | `ssh root@bruter 'command -v tcpdump'` |

## Endpoint Matrix

| Item | Expected value | Required | Verify |
|---|---|---|---|
| Primary base URL | `http://bruter:11434` | Yes | `curl http://bruter:11434/api/tags` |
| Fallback base URL | `http://bruter` | Optional | only if primary path changes |
| API type | Anthropic-compatible `/v1/messages` | Yes | compatibility script or manual curl |
| Native API | Ollama `/api/chat` and `/api/show` | Yes | compatibility script |

## Model Matrix

| Model | Current status | Intended use in validation | Notes |
|---|---|---|---|
| `gemma4:e4b` | Positive candidate | First IDE run | Structured tool call observed in `/v1/messages` |
| `llama3.2:latest` | Positive candidate | Second IDE run | Structured tool call observed in `/v1/messages` |
| `qwen2.5-coder:7b-instruct-q4_K_M` | Negative control | Third IDE run | Prints tool-call JSON as text |
| `gemma3:12b-it-q4_K_M` | Not agent-compatible | Optional documentation-only reference | API reports tools unsupported |

## Workstation Matrix

| Item | Requirement | Verify |
|---|---|---|
| Repository opened in VS Code | Required | repo root visible in Explorer |
| Fresh agent session | Required | new Claude Code session started |
| No manual helper actions after prompt | Required | operator only pastes prompt and observes |
| Network route to `bruter` | Required | endpoint curl succeeds from workstation |
| Local shell from IDE session | Required | agent can execute shell command in workspace |

## VS Code Configuration Expectations

These settings do not need to be identical on every machine, but the following properties must hold:

| Capability | Required | Notes |
|---|---|---|
| Model requests routed to Ollama endpoint | Yes | must point at intended base URL |
| Session can access workspace files | Yes | otherwise file-write failures are not meaningful |
| Session can execute local commands | Yes | otherwise command-exec failures are invalid |
| Timeout long enough for model + command run | Yes | avoid false negatives on slow models |

## Server Matrix

| Item | Expected state | Verify |
|---|---|---|
| Host | `bruter` reachable | `ssh root@bruter 'hostname'` |
| Ollama service | active | `ssh root@bruter 'systemctl is-active ollama'` |
| Models installed | candidate models present | `curl http://bruter:11434/api/tags` |
| Logs available | yes | `ssh root@bruter 'journalctl -u ollama -n 50 --no-pager'` |
| Packet capture available | yes | `ssh root@bruter 'command -v tcpdump'` |

## Preflight Checklist

Run these checks before an IDE validation session:

```bash
git status --short
python3 --version
curl http://bruter:11434/api/tags
python3 tools/check_ollama_model_compat.py
ssh root@bruter 'systemctl is-active ollama'
ssh root@bruter 'command -v tcpdump'
```

## Blocking Conditions

Do not count a run as valid if any of the following is true:

- the endpoint is unreachable
- the intended model is not installed
- `python3` is unavailable
- the IDE session cannot write files
- the IDE session cannot execute shell commands
- the workstation cannot reach `bruter`

## Recording Requirements

For every validation run, record:

- workstation context
- endpoint used
- model used
- whether preflight passed
- any deviations from the expected environment

## Next Use

Use this matrix immediately before following [docs/specs/vscode-ollama-acceptance-scenario.md](/home/krl/git/check_sip/docs/specs/vscode-ollama-acceptance-scenario.md:1).
