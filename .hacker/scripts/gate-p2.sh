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

if ! awk '
  $0 == "## RESTRICTIONS" { found=1; next }
  found && /^## / { exit }
  found && NF { content=1 }
  END { exit !(found && content) }
' "$SPEC_FILE"; then
  echo "[FAIL] Spec nao possui secao RESTRICTIONS nao vazia"
  exit 1
fi

# CATEGORY deve ser uma categoria conhecida do pipeline.
if ! awk '
  $0 == "## CATEGORY" { found=1; next }
  found && NF { value=tolower($0); exit }
  END { exit !(value ~ /^(bugfix|feature|refactor|infra|docs)$/) }
' "$SPEC_FILE"; then
  echo "[FAIL] CATEGORY ausente ou invalida"
  exit 1
fi

# Paths sensiveis exigem confirmacao duravel e explicita.
if grep -qE '(~/opsec/scripts/|/opsec/scripts/|docker-compose\.yml)' "$SPEC_FILE"; then
  if ! grep -qE '^CONFIRMACAO_FERNANDO:[[:space:]]*SIM[[:space:]]*$' "$SPEC_FILE"; then
    echo "[FAIL] Spec toca area sensivel sem CONFIRMACAO_FERNANDO: SIM"
    exit 1
  fi
fi

echo "[PASS] Gate P2: rule-control validado, areas sensiveis protegidas"
exit 0
