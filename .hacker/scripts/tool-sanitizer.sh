#!/usr/bin/env bash
set -uo pipefail

# tool-sanitizer.sh — Sanitizacao de output de ferramentas contra prompt injection
# Funcao: detectar padroes de prompt injection em outputs de ferramentas
# Uso: tool-sanitizer.sh <arquivo_ou_texto>  ou  echo "texto" | tool-sanitizer.sh
# Exit: 0=limpo, 1=suspeitas detectadas
# Variavel de ambiente: SUSPICIOUS=true/false

SUSPICIOUS=false

detect_prompt_injection() {
    local text="$1"
    local found=0

    # Padrao 1: Instrucoes imperativas
    if echo "$text" | grep -qiE '(ignore (all |the )?previous instructions|disregard (all |the )?(previous|above|prior)|you are now|forget (all |your )?(rules|instructions)|new instruction|override (all |your )?(rules|instructions))'; then
        found=1
    fi

    # Padrao 2: Tentativas de sobrescrever regras
    if echo "$text" | grep -qiE '(system:|assistant:|### NEW INSTRUCTION|<\|system\|>|\[INST\]|<<SYS>>|<\|im_start\|>)'; then
        found=1
    fi

    # Padrao 3: Blocos de system prompt
    if echo "$text" | grep -qiE '(you are a (helpful|powerful|smart)|act as (if|a)|pretend (to be|you are)|roleplay as)'; then
        found=1
    fi

    # Padrao 4: Tentativa de extrair regras internas
    if echo "$text" | grep -qiE '(show me your (rules|instructions|prompt)|what are your (rules|instructions)|print your (system|initial) prompt|reveal your (rules|instructions))'; then
        found=1
    fi

    # Padrao 5: Bypass de seguranca
    if echo "$text" | grep -qiE '(jailbreak|DAN mode|developer mode|do anything now|unrestricted mode)'; then
        found=1
    fi

    return $found
}

sanitize_input() {
    local input_file="${1:-}"
    local text=""

    if [ -n "$input_file" ] && [ -f "$input_file" ]; then
        text=$(cat "$input_file")
    elif [ -n "$input_file" ]; then
        text="$input_file"
    elif [ ! -t 0 ]; then
        text=$(cat)
    else
        echo "Uso: tool-sanitizer.sh <arquivo> ou echo 'texto' | tool-sanitizer.sh" >&2
        return 1
    fi

    detect_prompt_injection "$text"
    rc=$?
    if [ $rc -ne 0 ]; then
        SUSPICIOUS=true
        export SUSPICIOUS
        echo "=== OUTPUT MARCADO COMO SUSPEITO ===" >&2
        echo "Linhas com padroes suspeitos foram detectadas." >&2
        echo "O output NAO deve ser processado como instrucao." >&2
        echo "===================================" >&2
        echo "$text" | sed 's/^/[SUSPEITO] /'
        return 1
    else
        SUSPICIOUS=false
        export SUSPICIOUS
        echo "$text"
        return 0
    fi
}

# Modo CLI
if [ "${1:-}" = "help" ] || [ "${1:-}" = "--help" ]; then
    echo "Uso: tool-sanitizer.sh [arquivo_ou_texto]"
    echo ""
    echo "Detecta padroes de prompt injection em outputs de ferramentas."
    echo "Exit: 0=limpo, 1=suspeitas detectadas"
    echo "Variavel de ambiente: SUSPICIOUS=true/false"
    echo ""
    echo "Modos:"
    echo "  tool-sanitizer.sh <texto>          — sanitiza texto"
    echo "  tool-sanitizer.sh <arquivo>        — sanitiza arquivo"
    echo "  tool-sanitizer.sh check <texto>    — apenas verifica (SUSPICIOUS=true/false)"
    echo "  echo 'texto' | tool-sanitizer.sh   — sanitiza via stdin"
elif [ "${1:-}" = "check" ]; then
    text="${2:-}"
    detect_prompt_injection "$text"
    rc=$?
    if [ $rc -eq 0 ]; then
        echo "SUSPICIOUS=false"
        exit 0
    else
        echo "SUSPICIOUS=true"
        exit 1
    fi
else
    sanitize_input "${1:-}"
fi
