#!/usr/bin/env bash
set -uo pipefail

# gate-p2.sh — Gate de regras (P2)
# Retorna: 0=PASS, 1=FAIL
# Descricao: Validar se a rule-control foi executada e se a spec nao toca areas sensiveis sem confirmacao

echo "=== GATE-P2 (Rule Control) ==="

SPEC_FILE="${1:-}"
if [ -z "$SPEC_FILE" ]; then
  echo "[FAIL] Nenhuma spec fornecida"
  exit 1
fi

if [ ! -f "$SPEC_FILE" ]; then
  echo "[FAIL] Spec nao encontrada: $SPEC_FILE"
  exit 1
fi

# Verificar se a spec possui secao RESTRICTIONS
if ! grep -q "RESTRICTIONS" "$SPEC_FILE"; then
  echo "[FAIL] Spec nao possui secao RESTRICTIONS"
  exit 1
fi

# Verificar se nao ha alteracoes em ~/opsec/scripts/ sem flag classe C
if grep -qE "~/.opsec/scripts/.*(MODIFY|MODIFICAR)" "$SPEC_FILE" 2>/dev/null; then
  if ! grep -qE "classe C|confirmacao do Fernando" "$SPEC_FILE"; then
    echo "[FAIL] Spec toca ~/opsec/scripts/ sem confirmacao classe C"
    exit 1
  fi
fi

echo "[PASS] Gate P2: rule-control validado, areas sensiveis protegidas"
exit 0
