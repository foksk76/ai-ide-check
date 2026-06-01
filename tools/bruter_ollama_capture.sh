#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  tools/bruter_ollama_capture.sh start [label]
  tools/bruter_ollama_capture.sh stop <remote_pcap_path>

Examples:
  tools/bruter_ollama_capture.sh start llama32
  tools/bruter_ollama_capture.sh stop /tmp/ollama-capture-20260601T170000-llama32.pcap
EOF
}

start_capture() {
  local label="${1:-manual}"
  local timestamp
  timestamp="$(date +%Y%m%dT%H%M%S)"
  local remote_path="/tmp/ollama-capture-${timestamp}-${label}.pcap"
  local remote_pid="/tmp/ollama-capture-${timestamp}-${label}.pid"

  ssh root@bruter \
    "nohup tcpdump -i any -s0 -w '${remote_path}' 'tcp port 11434' >/tmp/tcpdump-${timestamp}-${label}.log 2>&1 & echo \$! > '${remote_pid}'"

  echo "Capture started on bruter"
  echo "pcap: ${remote_path}"
  echo "pidfile: ${remote_pid}"
  echo "stop with: tools/bruter_ollama_capture.sh stop ${remote_path}"
}

stop_capture() {
  local remote_path="${1:-}"
  if [[ -z "${remote_path}" ]]; then
    usage
    exit 1
  fi

  local remote_pid="${remote_path%.pcap}.pid"
  ssh root@bruter \
    "if [ -f '${remote_pid}' ]; then kill \$(cat '${remote_pid}') || true; rm -f '${remote_pid}'; fi; ls -lh '${remote_path}'"
}

main() {
  local cmd="${1:-}"
  case "${cmd}" in
    start)
      shift
      start_capture "${1:-manual}"
      ;;
    stop)
      shift
      stop_capture "${1:-}"
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
