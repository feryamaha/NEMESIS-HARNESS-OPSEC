#!/bin/bash
#===============================================================================
# runner.sh | Runner/CLI de automacao da camada operacional
#             Gate → Operacao → Relatorio → Ledger
#===============================================================================
#
# Referencia cruzada: ISSUE-001 (SPEC_004) para enforcement fisico
# (gate-enforcement.sh, x-bit). Este runner valida pre-condicoes
# comportamentais (gate GOOD, escopo no ledger, hash do ledger).
#
# Exit codes:
#   0 = ciclo valido, todas as verificacoes passaram
#   1 = ciclo invalido, alguma verificacao falhou
#
# Nao executa operacoes de rede diretamente. Complementa o enforcement
# fisico da ISSUE-001 sem duplica-lo.
#===============================================================================

set -euo pipefail

GATE_SCRIPT="${GATE_SCRIPT:-$HOME/opsec/scripts/verificar-vazamento.sh}"
LEDGER_FILE=".hacker/ledger/operacoes.md"

echo "[runner] Iniciando verificacao do ciclo operacional..."

# Etapa 1: Verificar gate GOOD (deteccao precisa via marcador)
# ISSUE-001 (SPEC_004): enforcement fisico e responsabilidade da ISSUE-001
# nao sao duplicadas por este runner, que valida apenas pre-condicoes comportamentais.
echo "[runner] Etapa 1: verificando gate..."
if [ ! -x "$GATE_SCRIPT" ]; then
    echo "[runner] ERRO: Script de gate nao encontrado: $GATE_SCRIPT"
    exit 1
fi
GATE_OUTPUT=$(bash "$GATE_SCRIPT" 2>&1 || true)
FINAL_LINE=$(echo "$GATE_OUTPUT" | awk '/\[5\] RESULTADO FINAL/{getline; print; exit}')
if echo "$FINAL_LINE" | grep -qF '[LEAK]'; then
    echo "[runner] ERRO: Gate com LEAK detectado. Ciclo invalido. Operacao recusada."
    exit 1
elif echo "$FINAL_LINE" | grep -qF '[GOOD]'; then
    echo "[runner] Gate: GOOD | proseguindo."
else
    echo "[runner] ERRO: Gate NAO GOOD ou marcador nao encontrado. Ciclo invalido."
    exit 1
fi

# Etapa 2: Verificar escopo nao vazio (leitura do ultimo registro do ledger)
# Nao verificar TEMPLATE-OPERACAO.md.
echo "[runner] Etapa 2: verificando escopo no ledger..."
if [ ! -f "$LEDGER_FILE" ]; then
    echo "[runner] ERRO: Arquivo de ledger nao encontrado: $LEDGER_FILE"
    exit 1
fi
ULTIMA_LINHA=$(tail -1 "$LEDGER_FILE")
ESCOPO=$(echo "$ULTIMA_LINHA" | cut -d'|' -f5 | xargs)
if [ -z "$ESCOPO" ] || [ "$ESCOPO" = "N/A" ]; then
    echo "[runner] ERRO: Campo ESCOPO vazio ou N/A na ultima linha do ledger."
    exit 1
fi
echo "[runner] Escopo: $ESCOPO."

# Etapa 3: Verificar integridade do ledger (hash da ultima entrada)
# Extrair campos DATA (f2) a BASE (f10), comparar HASH (f11).
echo "[runner] Etapa 3: verificando integridade do ledger..."
DATA=$(echo "$ULTIMA_LINHA" | cut -d'|' -f2 | xargs)
OP_ID=$(echo "$ULTIMA_LINHA" | cut -d'|' -f3 | xargs)
AGENTE=$(echo "$ULTIMA_LINHA" | cut -d'|' -f4 | xargs)
# ESCOPO ja definido na Etapa 2 (linha 54)
GATE_VAL=$(echo "$ULTIMA_LINHA" | cut -d'|' -f6 | xargs)
REF_AUT=$(echo "$ULTIMA_LINHA" | cut -d'|' -f7 | xargs)
VETOR=$(echo "$ULTIMA_LINHA" | cut -d'|' -f8 | xargs)
RESULTADO=$(echo "$ULTIMA_LINHA" | cut -d'|' -f9 | xargs)
BASE=$(echo "$ULTIMA_LINHA" | cut -d'|' -f10 | xargs)
EXPECTED_HASH=$(echo "$ULTIMA_LINHA" | cut -d'|' -f11 | xargs)
PAYLOAD="$DATA|$OP_ID|$AGENTE|$ESCOPO|$GATE_VAL|$REF_AUT|$VETOR|$RESULTADO|$BASE"
COMPUTED_HASH=$(printf '%s' "$PAYLOAD" | sha256sum | cut -c1-16)
if [ "$COMPUTED_HASH" != "$EXPECTED_HASH" ]; then
    echo "[runner] ERRO: Hash do ledger invalido."
    echo "[runner] Esperado: $EXPECTED_HASH"
    echo "[runner] Computado: $COMPUTED_HASH"
    exit 1
fi
echo "[runner] Ledger: hash validado ($COMPUTED_HASH)."

echo "[runner] Todas as verificacoes passaram. Ciclo valido."
echo "[runner] Exit code: 0"
exit 0
