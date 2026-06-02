#!/usr/bin/env bash
set -euo pipefail

stand_id="ubuntu-local-rtx3080"
endpoint="http://localhost:11434"
artifacts_root=".artifacts/linux-phase1-preflight"
pull_models=false

usage() {
  cat <<'EOF'
Usage: tools/prepare_linux_phase1.sh [options]

Capture a Linux stand preflight without running inference.

Options:
  --stand-id ID       Stand identifier (default: ubuntu-local-rtx3080)
  --endpoint URL      Ollama endpoint (default: http://localhost:11434)
  --artifacts-root P  Artifact directory (default: .artifacts/linux-phase1-preflight)
  --pull-models       Pull leaders and create their ctx32k profiles
  -h, --help          Show this help
EOF
}

while (($#)); do
  case "$1" in
    --stand-id) stand_id="$2"; shift 2 ;;
    --endpoint) endpoint="$2"; shift 2 ;;
    --artifacts-root) artifacts_root="$2"; shift 2 ;;
    --pull-models) pull_models=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"
run_stamp="$(date +%Y%m%dT%H%M%S)"
run_dir="$artifacts_root/$run_stamp"
mkdir -p "$run_dir"

for command in curl git ollama python3; do
  command -v "$command" >/dev/null || {
    printf 'Required command is missing: %s\n' "$command" >&2
    exit 1
  }
done

capture() {
  local output="$1"
  shift
  "$@" >"$run_dir/$output" 2>&1 || true
}

curl --silent --show-error --fail "$endpoint/api/version" >"$run_dir/ollama-version.json"
curl --silent --show-error --fail "$endpoint/api/tags" >"$run_dir/ollama-tags-before.json"
capture hostname.txt hostname
capture uname.txt uname -a
capture os-release.txt cat /etc/os-release
capture cpu.txt lscpu
capture memory.txt free -h
capture pci-display.txt bash -c "lspci -nn | grep -Ei 'vga|3d|display'"
capture nvidia-smi.txt nvidia-smi
capture ollama-ps-before.txt ollama ps
capture ollama-service.txt systemctl show ollama -p FragmentPath -p User -p Environment
capture tool-versions.txt bash -c '
  code --version 2>/dev/null || true
  claude --version 2>/dev/null || true
  ollama --version 2>/dev/null || true
  python3 --version 2>/dev/null || true
  git --version
  curl --version | sed -n "1p"
'
env | grep -E '^(OLLAMA|ROCR|HIP|CUDA|ANTHROPIC|CLAUDE)_' \
  >"$run_dir/relevant-environment.txt" || true

if "$pull_models"; then
  ollama pull gpt-oss:20b | tee "$run_dir/pull-gpt-oss-20b.txt"
  ollama create gpt-oss:20b-ctx32k \
    -f tools/modelfiles/gpt-oss-20b-ctx32k.Modelfile \
    | tee "$run_dir/create-gpt-oss-20b-ctx32k.txt"
  ollama pull ministral-3:8b | tee "$run_dir/pull-ministral-3-8b.txt"
  ollama create ministral-3:8b-ctx32k \
    -f tools/modelfiles/ministral-3-8b-ctx32k.Modelfile \
    | tee "$run_dir/create-ministral-3-8b-ctx32k.txt"
fi

curl --silent --show-error --fail "$endpoint/api/tags" >"$run_dir/ollama-tags-after.json"
capture ollama-ps-after.txt ollama ps

python3 - "$run_dir/manifest.json" "$stand_id" "$endpoint" "$pull_models" <<'PY'
import json
import platform
import subprocess
import sys
from datetime import datetime, timezone

output, stand_id, endpoint, pull_models = sys.argv[1:]
manifest = {
    "captured_at": datetime.now(timezone.utc).astimezone().isoformat(),
    "stand_id": stand_id,
    "endpoint": endpoint,
    "hostname": platform.node(),
    "platform": platform.platform(),
    "architecture": platform.machine(),
    "shell": "bash",
    "repository_commit": subprocess.check_output(
        ["git", "rev-parse", "HEAD"], text=True
    ).strip(),
    "profiles_requested": [
        "gpt-oss:20b-ctx32k",
        "ministral-3:8b-ctx32k",
    ],
    "model_pull_requested": pull_models == "true",
    "inference_started": False,
}
with open(output, "w", encoding="utf-8") as file:
    json.dump(manifest, file, indent=2)
    file.write("\n")
PY

printf 'Preflight artifacts: %s\n' "$run_dir"
if ! "$pull_models"; then
  printf 'Profiles were not downloaded. Re-run with --pull-models when ready.\n'
fi
