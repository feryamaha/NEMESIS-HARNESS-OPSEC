#!/usr/bin/env bash
set -uo pipefail

# gate-p1.sh — Gate de analise critica (P1)
# Retorna: 0=PASS, 1=FAIL
# Descricao: Validar estrutura minima, analise e fontes rastreaveis da spec

echo "=== GATE-P1 (Critical Analysis) ==="

SPEC_FILE="${1:-}"
if [ -z "$SPEC_FILE" ]; then
  echo "[FAIL] Nenhuma spec fornecida como argumento"
  exit 1
fi

if [ ! -f "$SPEC_FILE" ]; then
  echo "[FAIL] Spec nao encontrada: $SPEC_FILE"
  exit 1
fi

for SECTION in REQUEST CATEGORY PROBLEM CONTEXT REQUIREMENTS "FILES INVOLVED" RESTRICTIONS "EXPECTED DELIVERY"; do
  if ! awk -v section="$SECTION" '
    $0 == "## " section { found=1; next }
    found && /^## / { exit }
    found && NF { content=1 }
    END { exit !(found && content) }
  ' "$SPEC_FILE"; then
    echo "[FAIL] Spec sem secao estruturada e nao vazia: $SECTION"
    exit 1
  fi
done

if ! grep -qi "Fontes consultadas" "$SPEC_FILE"; then
  echo "[FAIL] Spec nao declara fontes consultadas"
  exit 1
fi

if ! grep -qE "https?://" "$SPEC_FILE"; then
  echo "[FAIL] Spec nao possui fonte externa URL"
  exit 1
fi

INTERNAL_PATH=$(grep -Eo '([.]|~|/)[A-Za-z0-9_./-]+\.(md|sh|py|yml|yaml)' "$SPEC_FILE" | sed 's#^\./##' | while IFS= read -r path; do
  expanded="$path"
  case "$expanded" in
    ~/*) expanded="$HOME/${expanded#~/}" ;;
  esac
  if [ -f "$expanded" ]; then
    printf '%s\n' "$path"
    break
  fi
done)
if [ -z "$INTERNAL_PATH" ]; then
  echo "[FAIL] Spec nao possui fonte interna existente"
  exit 1
fi

if ! grep -qiE "hipotese|alternativa|risco" "$SPEC_FILE"; then
  echo "[FAIL] Spec nao registra hipotese alternativa ou risco analisado"
  exit 1
fi

echo "[PASS] Gate P1: estrutura, fontes e analise minima validadas"
exit 0
