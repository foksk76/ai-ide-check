#!/usr/bin/env bash
set -euo pipefail

stand_id="ubuntu-local-rtx3080"
endpoint="http://localhost:11434"
artifacts_root=".artifacts/linux-phase1-cli-contract"
timeout_seconds=1200
require_full_gpu=false
models=("gpt-oss:20b-ctx32k" "ministral-3:8b-ctx32k")

usage() {
  cat <<'EOF'
Usage: tools/run_linux_phase1_cli_contract.sh [options]

Run the Phase 1 autonomous CLI contract task on a disposable fixture copy.

Options:
  --stand-id ID       Stand identifier (default: ubuntu-local-rtx3080)
  --endpoint URL      Ollama endpoint (default: http://localhost:11434)
  --models CSV        Models to run
  --timeout SECONDS   Per-model timeout (default: 1200)
  --require-full-gpu  Fail runs unless ollama ps reports 100% GPU
  -h, --help          Show this help
EOF
}

while (($#)); do
  case "$1" in
    --stand-id) stand_id="$2"; shift 2 ;;
    --endpoint) endpoint="$2"; shift 2 ;;
    --models) IFS=',' read -r -a models <<<"$2"; shift 2 ;;
    --timeout) timeout_seconds="$2"; shift 2 ;;
    --require-full-gpu) require_full_gpu=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"
for command in claude curl git ollama python3 timeout; do
  command -v "$command" >/dev/null || {
    printf 'Required command is missing: %s\n' "$command" >&2
    exit 1
  }
done

curl --silent --show-error --fail "$endpoint/api/version" >/dev/null
run_stamp="$(date +%Y%m%dT%H%M%S)"
run_dir="$repo_root/$artifacts_root/$run_stamp"
mkdir -p "$run_dir"
curl --silent --show-error --fail "$endpoint/api/version" >"$run_dir/ollama-version.json"
curl --silent --show-error --fail "$endpoint/api/tags" >"$run_dir/ollama-tags.json"
ollama ps >"$run_dir/ollama-ps-before.txt"
for model in "${models[@]}"; do
  if ! python3 - "$run_dir/ollama-tags.json" "$model" <<'PY'
import json
import sys
with open(sys.argv[1], encoding="utf-8") as file:
    names = {model["name"] for model in json.load(file)["models"]}
raise SystemExit(0 if sys.argv[2] in names else 1)
PY
  then
    printf 'Missing local profile: %s\n' "$model" >&2
    printf 'Run tools/prepare_linux_phase1.sh --pull-models first.\n' >&2
    exit 1
  fi
done
printf 'model\tclaude_exit\ttests_exit\tfull_gpu\tread_tool\tvalidation_tool\tstatus_tool\timplementation_changed\tfinal_grounded\tpassed\n' \
  >"$run_dir/summary.tsv"

python3 - "$run_dir/manifest.json" "$stand_id" "$endpoint" "$timeout_seconds" "${models[@]}" <<'PY'
import json
import subprocess
import sys
from datetime import datetime, timezone

output, stand_id, endpoint, timeout_seconds, *models = sys.argv[1:]
manifest = {
    "captured_at": datetime.now(timezone.utc).astimezone().isoformat(),
    "stand_id": stand_id,
    "validation_layer": "claude-code-cli-headless-phase1-contract",
    "endpoint": endpoint,
    "models": models,
    "timeout_seconds": int(timeout_seconds),
    "claude_version": subprocess.check_output(["claude", "--version"], text=True).strip(),
    "repository_commit": subprocess.check_output(
        ["git", "rev-parse", "HEAD"], text=True
    ).strip(),
    "permission_mode": "bypassPermissions",
    "session_persistence": False,
    "environment": {
        "ANTHROPIC_AUTH_TOKEN": "<redacted>",
        "ANTHROPIC_API_KEY": "<redacted>",
        "ANTHROPIC_BASE_URL": endpoint,
        "API_TIMEOUT_MS": str(int(timeout_seconds) * 1000),
        "BASH_DEFAULT_TIMEOUT_MS": str(int(timeout_seconds) * 1000),
        "BASH_MAX_TIMEOUT_MS": str(int(timeout_seconds) * 1000),
        "CLAUDE_CODE_MAX_OUTPUT_TOKENS": "4096",
    },
}
with open(output, "w", encoding="utf-8") as file:
    json.dump(manifest, file, indent=2)
    file.write("\n")
PY

cat >"$run_dir/prompt.txt" <<'EOF'
Work autonomously in this disposable git repository.

The repository contains a small Python tag-normalization task. Inspect the
repository to identify the relevant implementation and tests. Fix the
implementation so that it:

- accepts a list of strings
- strips surrounding whitespace and lowercases each tag
- ignores empty tags after stripping
- removes duplicates while preserving first-seen order
- raises TypeError when the input is not a list or an item is not a string

Run the relevant automated tests. Then run:

git status --short

Finish with a concise report grounded in the actual changed files, git state,
and test result. Include the exact `git status --short` output.
EOF

for model in "${models[@]}"; do
  safe_model="${model//[^A-Za-z0-9._-]/_}"
  case_dir="$run_dir/$safe_model"
  workspace="$case_dir/workspace"
  mkdir -p "$case_dir"
  cp -a fixtures/coder-bench/tasks/normalize-tags "$workspace"
  cp "$run_dir/prompt.txt" "$case_dir/prompt.txt"
  git -C "$workspace" init --quiet
  git -C "$workspace" config user.email coder-bench@localhost
  git -C "$workspace" config user.name "Coder Bench"
  git -C "$workspace" add .
  git -C "$workspace" commit --quiet -m "fixture baseline"

  started_at="$(date --iso-8601=seconds)"
  set +e
  (
    cd "$workspace"
    ANTHROPIC_AUTH_TOKEN=ollama \
    ANTHROPIC_API_KEY=ollama \
    ANTHROPIC_BASE_URL="$endpoint" \
    ANTHROPIC_MODEL="$model" \
    ANTHROPIC_DEFAULT_SONNET_MODEL="$model" \
    ANTHROPIC_DEFAULT_HAIKU_MODEL="$model" \
    CLAUDE_CODE_SUBAGENT_MODEL="$model" \
    API_TIMEOUT_MS="$((timeout_seconds * 1000))" \
    BASH_DEFAULT_TIMEOUT_MS="$((timeout_seconds * 1000))" \
    BASH_MAX_TIMEOUT_MS="$((timeout_seconds * 1000))" \
    CLAUDE_CODE_MAX_OUTPUT_TOKENS=4096 \
    timeout --signal=TERM --kill-after=10 "$timeout_seconds" \
      claude --print \
        --model "$model" \
        --output-format stream-json \
        --verbose \
        --no-session-persistence \
        --dangerously-skip-permissions \
        --tools default \
        --debug-file "$case_dir/claude-debug.log" \
        <"$case_dir/prompt.txt" \
        >"$case_dir/stdout.stream.jsonl" \
        2>"$case_dir/stderr.txt"
  )
  claude_exit=$?
  set -e

  set +e
  (cd "$workspace" && python3 -m unittest discover -s tests -v) \
    >"$case_dir/unittest.txt" 2>&1
  tests_exit=$?
  set -e
  git -C "$workspace" status --short >"$case_dir/git-status.txt"
  git -C "$workspace" diff --binary >"$case_dir/git-diff.patch"
  git -C "$workspace" diff --name-only >"$case_dir/changed-files.txt"
  ollama ps >"$case_dir/ollama-ps.txt"

  full_gpu=false
  if grep -F "$model" "$case_dir/ollama-ps.txt" | grep -Fq "100% GPU"; then
    full_gpu=true
  fi
  tests_changed=false
  if git -C "$workspace" diff --name-only | grep -Eq '^tests/'; then
    tests_changed=true
  fi
  implementation_changed=false
  if grep -Eq '^src/' "$case_dir/changed-files.txt"; then
    implementation_changed=true
  fi
  read_tool_observed=false
  if grep -F '"name":"Read"' "$case_dir/stdout.stream.jsonl" >/dev/null; then
    read_tool_observed=true
  fi
  validation_tool_observed=false
  if grep -F '"name":"Bash"' "$case_dir/stdout.stream.jsonl" | grep -Fq 'unittest'; then
    validation_tool_observed=true
  fi
  status_tool_observed=false
  if grep -F '"name":"Bash"' "$case_dir/stdout.stream.jsonl" | grep -Fq 'git status --short'; then
    status_tool_observed=true
  fi
  final_answer_grounded=false
  if python3 - "$case_dir/stdout.stream.jsonl" "$case_dir/git-status.txt" <<'PY'
import json
import sys

status = open(sys.argv[2], encoding="utf-8").read().strip()
final_answer = ""
for line in open(sys.argv[1], encoding="utf-8"):
    event = json.loads(line)
    if event.get("type") == "result":
        final_answer = event.get("result", "")
raise SystemExit(0 if status and status in final_answer else 1)
PY
  then
    final_answer_grounded=true
  fi
  passed=false
  if [[ "$claude_exit" -eq 0 && "$tests_exit" -eq 0 && "$tests_changed" == false &&
        "$implementation_changed" == true && "$read_tool_observed" == true &&
        "$validation_tool_observed" == true && "$status_tool_observed" == true &&
        "$final_answer_grounded" == true ]]; then
    passed=true
  fi
  if "$require_full_gpu" && [[ "$full_gpu" != true ]]; then
    passed=false
  fi

  ended_at="$(date --iso-8601=seconds)"
  python3 - "$case_dir/result.json" <<PY
import json
import sys
result = {
    "stand_id": ${stand_id@Q},
    "endpoint": ${endpoint@Q},
    "model": ${model@Q},
    "started_at": ${started_at@Q},
    "ended_at": ${ended_at@Q},
    "timeout_seconds": $timeout_seconds,
    "claude_exit_code": $claude_exit,
    "tests_exit_code": $tests_exit,
    "tests_changed": json.loads(${tests_changed@Q}),
    "implementation_changed": json.loads(${implementation_changed@Q}),
    "read_tool_observed": json.loads(${read_tool_observed@Q}),
    "validation_tool_observed": json.loads(${validation_tool_observed@Q}),
    "status_tool_observed": json.loads(${status_tool_observed@Q}),
    "final_answer_grounded": json.loads(${final_answer_grounded@Q}),
    "full_gpu_required": json.loads(${require_full_gpu@Q}),
    "full_gpu_observed": json.loads(${full_gpu@Q}),
    "passed": json.loads(${passed@Q}),
    "validation_command": "python3 -m unittest discover -s tests -v",
}
with open(sys.argv[1], "w", encoding="utf-8") as file:
    json.dump(result, file, indent=2)
    file.write("\\n")
PY
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$model" "$claude_exit" "$tests_exit" "$full_gpu" "$read_tool_observed" \
    "$validation_tool_observed" "$status_tool_observed" "$implementation_changed" \
    "$final_answer_grounded" "$passed" \
    | tee -a "$run_dir/summary.tsv"
done

ollama ps >"$run_dir/ollama-ps-after.txt"
printf 'Phase 1 artifacts: %s\n' "$run_dir"
