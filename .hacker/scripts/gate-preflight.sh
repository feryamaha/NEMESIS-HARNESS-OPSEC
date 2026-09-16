#!/usr/bin/env bash
set -uo pipefail

# gate-preflight.sh — Gate programavel de pre-flight
# Retorna: 0=PASS, 1=FAIL, 2=BLOQUEADO
# Descricao: Executa verificar-vazamento.sh, verifica wg0 ativo, verifica Tor na porta 9050

echo "=== GATE-PREFLIGHT ==="

# Verificar verificar-vazamento.sh
VAZAMENTO=$(bash ~/opsec/scripts/verificar-vazamento.sh 2>&1 || true)
if echo "$VAZAMENTO" | grep -q "Resultado final:.*LEAK"; then
  echo "[FAIL] Cadeia com LEAK detectado"
  exit 1
fi

# Verificar WireGuard wg0
if ! ip -o link show wg0 >/dev/null 2>&1; then
  echo "[FAIL] WireGuard wg0 nao ativo"
  exit 1
fi

# Verificar Tor na porta 9050
if ! ss -tlnp 2>/dev/null | grep -q 9050; then
  echo "[FAIL] Tor nao esta na porta 9050"
  exit 1
fi

echo "[PASS] Pre-flight completo: cadeia ativa"
exit 0
