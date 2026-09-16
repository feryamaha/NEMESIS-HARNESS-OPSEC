# Remoção Proton VPN / WireGuard Única VPN - Plano de Implementação

> **Para agentes**: Use hacker-subagent-driven-development para executar este plano.

**Objetivo**: Remover toda dependência de Proton VPN e gluetun. WireGuard (wg0) é a única VPN. Kill-switch validado via WireGuard.

**Spec**: `.opencode/specs/SPEC_012_remocao-proton-vpn-wireguard-unica-vpn.md`

**Arquivos Afetados**: 11 arquivos em `~/opsec/scripts/`, `~/opsec/docker-compose.yml`, docs

**Arquitetura**: Remove gluetun, tor-on-vpn e kali-sandbox do compose. Kill-switch.sh reescrito para auditar WireGuard (fail-closed do kernel). TESTE 4.5 do verificar-vazamento verifica wg0 em vez de gluetun. Referências a proton0 limpas em todos os scripts.

**Stack**: bash, Docker/Compose

---

## TASK 1: Reescrever kill-switch.sh para WireGuard

**Arquivo**: `~/opsec/scripts/kill-switch.sh`

**Arquivos**:
- MODIFY: `~/opsec/scripts/kill-switch.sh` (arquivo inteiro)

**Depende de**: nenhuma

**Verificacao**: `bash -n ~/opsec/scripts/kill-switch.sh`

**Descricao Detalhada**:
O kill-switch atual audita o netns do gluetun via `nsenter`. Com a remoção do gluetun, o kill-switch deve verificar se o WireGuard (wg0) está ativo. WireGuard no kernel Linux é fail-closed: se o túnel cai, o tráfego para (não roteia pela interface física).

**Implementacao**:
```bash
#!/usr/bin/env bash
set -uo pipefail

RUN_DIR="/home/fernando/opsec/run"
STATE_FILE="$RUN_DIR/kill-switch.netns"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
PASS() { echo -e "${GREEN}[PASS]${NC} $*"; }
WARN() { echo -e "${YELLOW}[!]${NC} $*"; }
FAIL() { echo -e "${RED}[FAIL]${NC} $*"; }

ACTION="${1:-}"

wg_ativo() {
  ip -o link show wg0 >/dev/null 2>&1
}

case "$ACTION" in
  on)
    if wg_ativo; then
      PASS "WireGuard (wg0) ATIVO. Tunel fail-closed: se cair, trafego para."
    else
      WARN "WireGuard (wg0) inativo. Trafego pode nao estar protegido."
    fi
    ;;
  off)
    if [[ -f "$STATE_FILE" ]]; then
      WARN "State do enforcer antigo encontrado e removido."
      rm -f "$STATE_FILE"
    else
      WARN "Modo auditor: nada a restaurar."
    fi
    exit 0
    ;;
  *)
    echo "Uso: sudo bash $0 {on|off}"
    exit 1
    ;;
esac
```

---

## TASK 2: Atualizar TESTE 4.5 em verificar-vazamento.sh

**Arquivo**: `~/opsec/scripts/verificar-vazamento.sh`

**Arquivos**:
- MODIFY: `~/opsec/scripts/verificar-vazamento.sh` (linhas 57-83: TESTE 3 IPv6 e linhas 91-116: TESTE 4.5)

**Depende de**: nenhuma

**Verificacao**: `bash -n ~/opsec/scripts/verificar-vazamento.sh`

**Descricao Detalhada**:
1. No TESTE 3 (IPv6, linhas 64-65): trocar `for v in proton0 wg0 tun0` para `for v in wg0 tun0`
2. No TESTE 3 (linhas 71-73): remover o check de range Proton (`2a02:6ea0`, `2a04:1c80`), manter apenas o check de VPN ativa
3. No TESTE 4.5 (linhas 91-116): substituir toda a lógica de auditoria do gluetun por verificação simples de wg0

**Implementacao** (mudanças no arquivo):

TESTE 3 - linha 65: `for v in proton0 wg0 tun0; do` → `for v in wg0 tun0; do`

TESTE 3 - linhas 71-73: remover o bloco `PROTON_RANGE` e o check de range Proton. Substituir por:
```bash
    if [[ "$VPN_V6" == true ]]; then
        WARN "IPv6 de saida via tunel VPN ativo"
    else
```

TESTE 4.5 - substituir linhas 91-116 por:
```bash
# --- TESTE 4.5: WireGuard (VPN oficial) ---
echo ""
echo "[4.5] WIREGUARD (VPN OFICIAL)"
if ip -o link show wg0 >/dev/null 2>&1; then
    PASS "WireGuard (wg0) ATIVO - trafego protegido pelo tunel"
else
    WARN "WireGuard (wg0) inativo - trafego pode nao estar protegido"
fi
```

---

## TASK 3: Atualizar session-start-hacking-security.sh Etapa 2.5

**Arquivo**: `~/opsec/scripts/session-start-hacking-security.sh`

**Arquivos**:
- MODIFY: `~/opsec/scripts/session-start-hacking-security.sh` (linhas 60-107)

**Depende de**: nenhuma

**Verificacao**: `bash -n ~/opsec/scripts/session-start-hacking-security.sh`

**Descricao Detalhada**:
A Etapa 2.5 deve subir apenas `tor-host` (torproxy-host). Remover gluetun, .env check e referências a Proton.

**Implementacao** (substituir linhas 60-107 por):
```bash
# Etapa 2.5: Subir container Docker (torproxy-host)
INFO "Etapa 2.5: Subindo container Docker (torproxy-host)..."
DOCKER_DISPONIVEL=false
if command -v "$DOCKER_CMD" >/dev/null 2>&1; then
  if "$DOCKER_CMD" compose version >/dev/null 2>&1; then
    DOCKER_DISPONIVEL=true
  fi
fi

if $DOCKER_DISPONIVEL; then
  COMPOSE_FILE="/home/fernando/opsec/docker-compose.yml"
  if [[ -f "$COMPOSE_FILE" ]]; then
    COMPOSE_UP_EXIT=0
    "$DOCKER_CMD" compose -f "$COMPOSE_FILE" up -d tor-host 2>&1 || COMPOSE_UP_EXIT=$?
    if [[ $COMPOSE_UP_EXIT -eq 0 ]]; then
      PASS "Container torproxy-host iniciado"
    else
      WARN "docker compose up falhou (exit $COMPOSE_UP_EXIT). Container pode nao estar rodando."
    fi

    # Aguardar torproxy-host ficar pronto na porta 9050
    INFO "Aguardando torproxy-host na porta 9050 (timeout: 120s)..."
    TOR_TIMEOUT=120
    TOR_INTERVALO=2
    TOR_ESPERADO=0
    for ((i=0; i<TOR_TIMEOUT; i+=TOR_INTERVALO)); do
      if nc -z 127.0.0.1 9050 2>/dev/null; then
        TOR_ESPERADO=1
        break
      fi
      sleep "$TOR_INTERVALO"
    done

    if [[ $TOR_ESPERADO -eq 1 ]]; then
      PASS "torproxy-host pronto na porta 9050"
    else
      WARN "torproxy-host nao respondeu na porta 9050 apos ${TOR_TIMEOUT}s. Verificar-vazamento pode retornar LEAK."
    fi
  else
    WARN "docker-compose.yml nao encontrado em $COMPOSE_FILE. Container nao subira."
  fi
else
  WARN "Docker/docker compose nao encontrado. Container nao subira. Verificar-vazamento pode retornar LEAK."
fi
```

---

## TASK 4: Limpar proton0 em iniciar-sessao.sh

**Arquivo**: `~/opsec/scripts/iniciar-sessao.sh`

**Arquivos**:
- MODIFY: `~/opsec/scripts/iniciar-sessao.sh` (linha 30)

**Depende de**: nenhuma

**Verificacao**: `bash -n ~/opsec/scripts/iniciar-sessao.sh`

**Descricao Detalhada**:
Linha 30: trocar `for v in wg0 tun0 proton0; do` para `for v in wg0 tun0; do`

**Implementacao**:
```bash
for v in wg0 tun0; do
```

---

## TASK 5: Limpar proton0 em verificador-externo.sh

**Arquivo**: `~/opsec/scripts/verificador-externo.sh`

**Arquivos**:
- MODIFY: `~/opsec/scripts/verificador-externo.sh` (linhas 30, 34, 42)

**Depende de**: nenhuma

**Verificacao**: `bash -n ~/opsec/scripts/verificador-externo.sh`

**Descricao Detalhada**:
1. Linha 30: comentario `interface VPN (wg0/proton0)` → `interface VPN (wg0)`
2. Linha 34: `grep -oE '^(wg0|proton0)'` → `grep -oE '^wg0'`
3. Linha 42: `interface VPN (wg0/proton0)` → `interface VPN (wg0)`

**Implementacao**:
Linha 30: `# gate-enforcement) e interface VPN (wg0). Red team involuntario bloqueado:`
Linha 34: `VPN_IFACE=$(ip -br a 2>/dev/null | grep -oE '^wg0' | head -1)`
Linha 42: `GAP "Cadeia nao operacional: interface VPN (wg0) ausente via ip -br a. Fail-closed: sem consulta externa."`

---

## TASK 6: Limpar referências Proton em validar-dns-fix.sh

**Arquivo**: `~/opsec/scripts/validar-dns-fix.sh`

**Arquivos**:
- MODIFY: `~/opsec/scripts/validar-dns-fix.sh` (linhas 11, 104)

**Depende de**: nenhuma

**Verificacao**: `bash -n ~/opsec/scripts/validar-dns-fix.sh`

**Descricao Detalhada**:
1. Linha 11: `VALIDACAO PRE-CONEXAO PROTON  DNS FIX` → `VALIDACAO PRE-CONEXAO DNS FIX`
2. Linha 104: `- Quando Proton subir, ela poe DNS no proton0` → `- Quando VPN subir, ela assume a resolucao DNS`

---

## TASK 7: Atualizar docker-compose.yml

**Arquivo**: `~/opsec/docker-compose.yml`

**Arquivos**:
- MODIFY: `~/opsec/docker-compose.yml` (remover gluetun, tor-on-vpn, kali-sandbox)

**Depende de**: nenhuma

**Verificacao**: `docker compose -f ~/opsec/docker-compose.yml config`

**Descricao Detalhada**:
Remover os serviços `gluetun`, `tor-on-vpn` e `kali-sandbox`. Manter apenas `tor-host`.

**Implementacao**:
```yaml
services:
  tor-host:
    image: dperson/torproxy:latest
    container_name: torproxy-host
    init: true
    ports:
      - "127.0.0.1:9050:9050/tcp"
    cap_add:
      - NET_ADMIN
    restart: unless-stopped
```

---

## TASK 8: Atualizar teste-session-start.sh

**Arquivo**: `~/opsec/scripts/teste-session-start.sh`

**Arquivos**:
- MODIFY: `~/opsec/scripts/teste-session-start.sh` (linhas 139, 375 e outras referências a gluetun)

**Depende de**: TASK 1, TASK 2, TASK 3

**Verificacao**: `bash -n ~/opsec/scripts/teste-session-start.sh`

**Descricao Detalhada**:
1. Linha 139: `echo "[GOOD] Kill-switch do gluetun ATIVO"` → `echo "[GOOD] WireGuard (wg0) ATIVO"`
2. Linhas de cenário 5 e 6: atualizar para testar tor-host em vez de gluetun
3. Linha 375: `grep -c "gluetun\|torproxy"` → `grep -c "torproxy"`
4. Atualizar mensagens de output para refletir nova arquitetura (WireGuard + Tor, sem gluetun)

---

## TASK 9: Atualizar docs (README.md, opsec-canon)

**Arquivos**: `~/opsec/README.md`, `hacker-etico-ambiente/README.md`, `.opencode/rules/hacker-opsec-canon.md`

**Arquivos**:
- MODIFY: `~/opsec/README.md` (remover referências gluetun/Proton)
- MODIFY: `hacker-etico-ambiente/README.md` (atualizar cadeia)
- MODIFY: `.opencode/rules/hacker-opsec-canon.md` (remover módulo gluetun, atualizar kill-switch)

**Depende de**: TASK 1, TASK 2, TASK 3, TASK 7

**Verificacao**: `bash -n` não aplicável (markdown); verificar semântica

**Descricao Detalhada**:
1. `~/opsec/README.md`: Remover seção sobre gluetun, Proton VPN. Atualizar cadeia para WireGuard + Tor.
2. `hacker-etico-ambiente/README.md`: Atualizar descrição da cadeia de proteção (sem gluetun).
3. `.opencode/rules/hacker-opsec-canon.md`: Remover linha do módulo gluetun da tabela canônica. Atualizar módulo kill-switch para WireGuard.

---

## Validação Final

```bash
# Sintaxe de todos os scripts
bash -n ~/opsec/scripts/kill-switch.sh
bash -n ~/opsec/scripts/verificar-vazamento.sh
bash -n ~/opsec/scripts/session-start-hacking-security.sh
bash -n ~/opsec/scripts/iniciar-sessao.sh
bash -n ~/opsec/scripts/verificador-externo.sh
bash -n ~/opsec/scripts/validar-dns-fix.sh
bash -n ~/opsec/scripts/teste-session-start.sh

# Docker compose
docker compose -f ~/opsec/docker-compose.yml config

# Verificar que gluetun/proton foram removidos
grep -r "gluetun\|proton\|PROTON" ~/opsec/scripts/*.sh | grep -v "test" || echo "OK: sem referências"
```
