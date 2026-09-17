#!/usr/bin/env bash
set -uo pipefail

# tool-logger.sh — Logging NDJSON para tool calls individuais
# Formato: {"ts":"ISO8601","agent":"...","tool":"...","args":"...","exit_code":N,"output_bytes":N,"target":"...","session":"..."}
# Diretorio: .hacker/logs/ (gitignored)
# Rotacao por sessao: arquivo OP-YYYYMMDD-NNN.ndjson

LOG_DIR=".hacker/logs"

ensure_log_dir() {
    if [ ! -d "$LOG_DIR" ]; then
        mkdir -p "$LOG_DIR"
    fi
}

log_tool_call() {
    local agent="${1:-unknown}"
    local tool="${2:-unknown}"
    local args="${3:-}"
    local exit_code="${4:-0}"
    local output_bytes="${5:-0}"
    local target="${6:-}"
    local session="${7:-avulso}"

    ensure_log_dir

    local ts
    ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    local logfile="${LOG_DIR}/${session}.ndjson"

    printf '{"ts":"%s","agent":"%s","tool":"%s","args":"%s","exit_code":%s,"output_bytes":%s,"target":"%s","session":"%s"}\n' \
        "$ts" "$agent" "$tool" "$args" "$exit_code" "$output_bytes" "$target" "$session" \
        >> "$logfile"
}

log_session_start() {
    local session="${1:-avulso}"
    local agent="${2:-orquestrador}"

    ensure_log_dir

    local ts
    ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    printf '{"ts":"%s","agent":"%s","tool":"SESSION_START","args":"","exit_code":0,"output_bytes":0,"target":"","session":"%s"}\n' \
        "$ts" "$agent" "$session" \
        >> "${LOG_DIR}/${session}.ndjson"
}

log_session_end() {
    local session="${1:-avulso}"
    local agent="${2:-orquestrador}"

    ensure_log_dir

    local ts
    ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    printf '{"ts":"%s","agent":"%s","tool":"SESSION_END","args":"","exit_code":0,"output_bytes":0,"target":"","session":"%s"}\n' \
        "$ts" "$agent" "$session" \
        >> "${LOG_DIR}/${session}.ndjson"
}

# Modo CLI: tool-logger.sh call <agent> <tool> <args> <exit_code> <output_bytes> <target> <session>
# Modo CLI: tool-logger.sh start <session> <agent>
# Modo CLI: tool-logger.sh end <session> <agent>
if [ "${1:-}" = "call" ]; then
    log_tool_call "$2" "$3" "$4" "${5:-0}" "${6:-0}" "${7:-}" "${8:-avulso}"
elif [ "${1:-}" = "start" ]; then
    log_session_start "${2:-avulso}" "${3:-orquestrador}"
elif [ "${1:-}" = "end" ]; then
    log_session_end "${2:-avulso}" "${3:-orquestrador}"
elif [ "${1:-}" = "help" ] || [ "${1:-}" = "--help" ]; then
    echo "Uso: tool-logger.sh <comando> [args]"
    echo ""
    echo "Comandos:"
    echo "  call <agent> <tool> <args> <exit_code> <output_bytes> <target> <session>"
    echo "  start <session> <agent>"
    echo "  end <session> <agent>"
    echo "  help"
fi
