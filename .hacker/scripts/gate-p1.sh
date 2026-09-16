#!/usr/bin/env bash
set -uo pipefail

# gate-p1.sh — Gate de analise critica (P1)
# Retorna: 0=PASS, 1=FAIL
# Descricao: Validar se a critical-analysis foi executada e se fontes F6 foram consultadas

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

# Verificar se a spec possui secao de fontes
if ! grep -q "Fontes consultadas" "$SPEC_FILE"; then
  echo "[FAIL] Spec nao possui secao 'Fontes consultadas' (F6 grounding)"
  exit 1
fi

# Verificar se possui pelo menos uma fonte externa (URL)
if ! grep -qE "https?://" "$SPEC_FILE"; then
  echo "[FAIL] Spec nao possui fonte externa (URL) consultada"
  exit 1
fi

# Verificar se possui pelo menos uma fonte interna (path do arquivo)
if ! grep -qE "\.(md|sh|yml|yaml)" "$SPEC_FILE"; then
  echo "[FAIL] Spec nao possui fonte interna (path do arquivo) consultada"
  exit 1
fi

echo "[PASS] Gate P1: critical-analysis validada, fontes F6 consultadas"
exit 0
