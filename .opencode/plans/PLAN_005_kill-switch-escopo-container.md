# Escopar kill-switch ao namespace do container (Opcao A) - Plano de Implementacao

> **Para agentes**: Use hacker-subagent-driven-development para executar este plano.

**Objetivo**: o kill-switch deixa de APLICAR regras de saida (nem no HOST nem no netns) e vira
AUDITOR do firewall fail-closed do proprio gluetun (FIREWALL=on) no netns do container
`gluetun` (namespace onde vive o trafego de ataque: kali e tor-on-vpn usam
`network_mode: service:gluetun`). O `on` verifica via nsenter (somente leitura) se a policy
OUTPUT do netns e DROP e se existe a regra ACCEPT do servidor VPN via interface fisica
(motivo: essa regra permite o handshake/reconexao da VPN; ver issue qdm12/gluetun#2038).
Host intacto e nenhuma regra propria inserida; container ausente: WARN (nada a auditar).

**Spec**: `.opencode/specs/SPEC_005_kill-switch-escopo-container.md`

**Arquivos Afetados**:
- MODIFY: `~/opsec/scripts/kill-switch.sh`
- MODIFY: `~/opsec/scripts/verificar-vazamento.sh` (TESTE 4.5)
- MODIFY: `.opencode/rules/hacker-opsec-canon.md` (linha modulo kill-switch)
- MODIFY: `.hacker/gate/GATE-DE-PROTECAO.md` (mencao escopo kill-switch)
- TEST: comando sudo do Fernando, sem rede, com/sem gluetun

**Arquitetura**: `kill-switch.sh on` AUDITA (somente leitura, via `nsenter -t <PID_gluetun>
-n -- iptables -S OUTPUT`) a policy OUTPUT DROP e a regra ACCEPT do endpoint criada pelo
proprio gluetun; PASS/FAIL sem tocar em regras. State file legacy
(`/home/fernando/opsec/run/kill-switch.netns`) so e usado pelo `off` para limpeza do desenho
antigo. Verificar-vazamento TESTE 4.5 faz a mesma auditoria no netns do gluetun (nsenter) e
nao na OUTPUT do host.

**Stack**: bash (perfil do repo). Sem dependencias novas.

**Autenticao**: sudo somente pelo Fernando; o agente nao roda sudo nem toca iptables.

> **ATENCAO (evidencia runtime 2026-09-12)**: os containers da cadeia NAO estao em
> execucao hoje (imagens ausentes, `.env` vazio). O caminho real e implementar o script de
> forma que, SEM gluetun, `on` emita WARN e nao toque em nada (host continua funcional), e
> o teste de netns (auditoria com gluetun ativo) fica pendente ate a cadeia operacional existir.

---

## TASK 1: kill-switch.sh vira auditor do fail-closed do gluetun no netns

**Arquivo**: `~/opsec/scripts/kill-switch.sh`

**Depende de**: nenhuma

**Verificacao**:
```bash
bash -n ~/opsec/scripts/kill-switch.sh
```

**Descricao Detalhada**:
Reescrever o nucleo do script para AUDITAR (somente leitura) o firewall fail-closed do proprio
gluetun no netns do container via `nsenter -t <PID> -n -- iptables -S OUTPUT`: policy OUTPUT
DROP presente E regra ACCEPT do servidor VPN via interface fisica presente. Nenhuma
insercao/flush/mudanca de policy propria. Se o container gluetun nao existir, `on` emite WARN e
exit 0 (nada a auditar). `off` e informativo (nada proprio a restaurar; limpa state legacy do
desenho antigo).

**Implementacao** (estado real no disco, fiel):

```bash
#!/usr/bin/env bash
set -uo pipefail

GLUETUN="gluetun"
RUN_DIR="/home/fernando/opsec/run"
STATE_FILE="$RUN_DIR/kill-switch.netns"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
PASS() { echo -e "${GREEN}[PASS]${NC} $*"; }
WARN() { echo -e "${YELLOW}[!]${NC} $*"; }
FAIL() { echo -e "${RED}[FAIL]${NC} $*"; }

ACTION="${1:-}"

pid_gluetun() {
  docker inspect -f '{{.State.Pid}}' "$GLUETUN" 2>/dev/null || echo ""
}

netns_up() {
  local pid="$1"
  [ -d "/proc/$pid/ns/net" ] || return 1
  # Confirma acesso ao netns do container (nao e o do host)
  nsenter -t "$pid" -n -- iptables -L OUTPUT -n >/dev/null 2>&1
}

iface_fisica_netns() {
  local pid="$1"
  nsenter -t "$pid" -n -- ip -o link show 2>/dev/null \
    | awk -F': ' '{print $2}' \
    | tr -d ' ' \
    | grep -Ev '^(lo|tun[0-9]+|wg[0-9]+|proton[0-9]+)$' \
    | head -1
}

# Modo AUDITOR: verifica se o firewall fail-closed do proprio gluetun (FIREWALL=on)
# esta de pe no netns do container. NUNCA toca nas regras (sem flush, sem policy
# propria, sem ACCEPT proprio). A barreira real de saida e o kill-switch interno do
# gluetun (regra ACCEPT para o servidor VPN via interface fisica + policy DROP).
auditar_netns() {
  local pid="$1" iface out out6 policy_ok=false endpoint_ok=false
  iface="$(iface_fisica_netns "$pid")"
  iface="${iface:-eth0}"

  out="$(nsenter -t "$pid" -n -- iptables -S OUTPUT 2>/dev/null || true)"
  if printf '%s\n' "$out" | grep -Eq '^-P OUTPUT DROP'; then
    policy_ok=true
  fi
  if printf '%s\n' "$out" \
      | grep '^-A OUTPUT' \
      | grep -- "-o ${iface}" \
      | grep -- '--dport' \
      | grep -- '-j ACCEPT' >/dev/null 2>&1; then
    endpoint_ok=true
  fi

  out6="$(nsenter -t "$pid" -n -- ip6tables -S OUTPUT 2>/dev/null || true)"
  if [[ -n "$out6" && "$out6" == *"OUTPUT"* ]]; then
    if ! printf '%s\n' "$out6" | grep -Eq '^-P OUTPUT DROP'; then
      WARN "policy OUTPUT IPv6 no netns nao e DROP; cobertura v6 fica por conta do IPv6 off global."
    fi
  else
    WARN "ip6tables indisponivel no netns; cobertura IPv6 fica por conta do IPv6 off global."
  fi

  if [[ "$policy_ok" == true && "$endpoint_ok" == true ]]; then
    PASS "Auditoria fail-closed do gluetun: policy OUTPUT DROP + regra ACCEPT do servidor VPN (via ${iface}) presentes no netns (pid $pid)."
  else
    FAIL "Auditoria fail-closed do gluetun: policy OUTPUT DROP=${policy_ok}, regra ACCEPT servidor VPN via ${iface}=${endpoint_ok}. Se a VPN cair, trafego de ataque pode vazar."
    return 1
  fi
}

case "$ACTION" in
  on)
    PID=$(pid_gluetun)
    if [[ -z "$PID" ]]; then
      WARN "Container $GLUETUN nao esta ativo. Sem trafego de ataque em runtime; auditoria nao aplicada (host e netns intactos)."
      exit 0
    fi
    if ! netns_up "$PID"; then
      FAIL "Netns do $GLUETUN nao acessivel/invalido (pid $PID)."
      exit 1
    fi
    auditar_netns "$PID"
    ;;
  off)
    if [[ -f "$STATE_FILE" ]]; then
      WARN "State do enforcer antigo (T1/SPEC_005) encontrado e removido; nenhuma regra propria a restaurar (netns do container morre junto com o container e o gluetun re-instala o firewall no start)."
      rm -f "$STATE_FILE"
    else
      WARN "Modo auditor: nenhuma regra propria foi aplicada; nada a restaurar."
    fi
    exit 0
    ;;
  *)
    echo "Uso: sudo bash $0 {on|off}"
    exit 1
    ;;
esac
```

**Nota de design honesta**: a auditoria NAO substitui a barreira: a protecao real de saida e o
firewall fail-closed do proprio gluetun (FIREWALL=on), que cria a regra ACCEPT do endpoint e a
policy DROP. Evidencia (issue qdm12/gluetun#2038 e codigo-fonte) mostrou que injetar
DROP/ACCEPT proprios quase derruba a VPN: um `-F OUTPUT` apagaria a excecao do endpoint que
permite o handshake pela interface fisica, e ESTABLISHED/RELATED nao cobre fluxo NEW. Por isso
o kill-switch vira auditor; o gluetun continua sendo o enforcer de fluxo.

---

## TASK 2: Adaptar verificar-vazamento.sh TESTE 4.5 ao novo escopo

**Arquivo**: `~/opsec/scripts/verificar-vazamento.sh`

**Depende de**: TASK 1

**Verificacao**:
```bash
bash -n ~/opsec/scripts/verificar-vazamento.sh
```

**Descricao Detalhada**:
No bloco TESTE 4.5, o criterio deixa de ser "regra propria no netns" e passa a AUDITAR o
fail-closed do proprio gluetun: policy OUTPUT DROP + regra ACCEPT do servidor VPN via interface
fisica, via nsenter, quando o container existir e o script rodar com privilegio. Quando nao
existir, reporta neutro (nao conta como LEAK nem como PASS falso).

**Implementacao** (estado real no disco, fiel):

```bash
# --- TESTE 4.5: kill-switch (auditoria do fail-closed do proprio gluetun) ---
echo ""
echo "[4.5] KILL-SWITCH"
GLUETUN_PID=$(docker inspect -f '{{.State.Pid}}' gluetun 2>/dev/null || echo "")
if [[ -z "$GLUETUN_PID" || "$GLUETUN_PID" == "0" ]]; then
    INFO "Container gluetun nao ativo; kill-switch de ataque nao se aplica neste momento."
    LEAK_KILLSWITCH=false
elif [[ $EUID -eq 0 ]]; then
    IFACE_FISICA=$(nsenter -t "$GLUETUN_PID" -n -- ip -o link show 2>/dev/null \
        | awk -F': ' '{print $2}' | tr -d ' ' \
        | grep -Ev '^(lo|tun[0-9]+|wg[0-9]+|proton[0-9]+)$' | head -1)
    IFACE_FISICA="${IFACE_FISICA:-eth0}"
    KS_OUT=$(nsenter -t "$GLUETUN_PID" -n -- iptables -S OUTPUT 2>/dev/null || echo "")
    KS_POLICY=false; KS_ENDPOINT=false
    printf '%s\n' "$KS_OUT" | grep -Eq '^-P OUTPUT DROP' && KS_POLICY=true
    printf '%s\n' "$KS_OUT" | grep '^-A OUTPUT' | grep -- "-o ${IFACE_FISICA}" \
        | grep -- '--dport' | grep -- '-j ACCEPT' >/dev/null 2>&1 && KS_ENDPOINT=true
    if [[ "$KS_POLICY" == true && "$KS_ENDPOINT" == true ]]; then
        PASS "Kill-switch do gluetun ATIVO (auditoria): policy OUTPUT DROP + ACCEPT servidor VPN via ${IFACE_FISICA}"
    else
        FAIL "Kill-switch do gluetun NAO ativo (auditoria): policy DROP=${KS_POLICY}, ACCEPT servidor VPN via ${IFACE_FISICA}=${KS_ENDPOINT}! Se a VPN cair, trafego de ataque pode vazar."
        LEAK_KILLSWITCH=true
    fi
else
    INFO "Executando sem privilegio: kill-switch do gluetun nao checado (requer root)"
fi
```

---

## TASK 3: Atualizar canon (linha modulo kill-switch)

**Arquivo**: `.opencode/rules/hacker-opsec-canon.md`

**Depende de**: TASK 1

**Verificacao**:
```bash
grep -n "kill-switch" .opencode/rules/hacker-opsec-canon.md
```

**Descricao Detalhada**:
Alterar a linha da tabela (hoje linha 34) para refletir a abordagem AUDITOR: o kill-switch
nao injeta regras proprias; audita o fail-closed do proprio gluetun (FIREWALL=on) no netns.

**Implementacao** (estado real no disco, fiel):

```md
| kill-switch | auditoria do firewall fail-closed do proprio gluetun (FIREWALL=on) no netns do container `gluetun` (namespace do trafego de ataque: kali/tor-on-vpn usam `network_mode: service:gluetun`): verifica policy OUTPUT DROP e regra ACCEPT do servidor VPN via interface fisica; nao injeta regra propria nem toca o host de admin | AUDITADO no netns do `gluetun` durante sessao segura (se container ativo): PASS exige policy OUTPUT DROP + ACCEPT do endpoint; sem container, WARN e nao aplica nada; `off` informativo (nada proprio a restaurar) | `~/opsec/scripts/kill-switch.sh` |
```

---

## TASK 4: Atualizar GATE-DE-PROTECAO.md (escopo do kill-switch)

**Arquivo**: `.hacker/gate/GATE-DE-PROTECAO.md`

**Depende de**: TASK 1

**Verificacao**:
```bash
grep -n "kill-switch\|OUTPUT DROP" .hacker/gate/GATE-DE-PROTECAO.md
```

**Descricao Detalhada**:
Na secao de limite honesto, registrar que o kill-switch AUDITA o fail-closed do proprio
gluetun no netns (nao injeta regras) e que o host fica intacto.

**Implementacao** (estado real no disco, fiel; bullets no bloco "Limites honestos da camada"):

```md
- O kill-switch nao injeta regras proprias: AUDITA o firewall fail-closed do proprio gluetun
  (FIREWALL=on) no netns do container `gluetun`, onde vive o trafego de ataque; o host de
  administracao (OpenCode, navegador) nao e afetado (SPEC_005).
- Enquanto o container `gluetun` nao estiver operacional, o kill-switch emite WARN e nao
  aplica nada; a barreira do host fora de sessao e a nao-execucao dos binarios (SPEC_004).
```

---

## TASK 5: Teste SUNSET (F7) via Fernando, sem rede

**Arquivo**: comando de execucao; rodado com sudo pelo Fernando

**Depende de**: TASKS 1-4

**Verificacao**:
```bash
# Requer sudo do Fernando (classe C). Sem rede. Valida o comportamento SEM gluetun ativo:
sudo bash ~/opsec/scripts/kill-switch.sh on
# esperado: WARN "...nao esta ativo... auditoria nao aplicada (host e netns intactos)" e exit 0 (NAO derruba nada).
sudo bash ~/opsec/scripts/verificar-vazamento.sh 2>&1 | grep -A1 "4.5" || true
# esperado: TESTE 4.5 INFO neutra ("container gluetun nao ativo...").
sudo bash ~/opsec/scripts/kill-switch.sh off
# esperado: WARN "Modo auditor: nenhuma regra propria foi aplicada..." e exit 0.
```

**Descricao Detalhada**:
Testar o caminho com container ausente (estado atual do ambiente) de forma idempotente:
`on` nao toca em nada (WARN, exit 0), `verificar-vazamento` TESTE 4.5 neutro, `off`
informativo (nada proprio a restaurar). O caminho com gluetun ativo (auditoria PASS com
policy DROP + ACCEPT do endpoint, e FAIL se faltar) sera validado posteriormente quando a
cadeia estiver operacional, com a mesma suite (documentada).

---

## Verificacao final (suite do perfil, ante-finishing)

```bash
bash -n ~/opsec/scripts/kill-switch.sh ~/opsec/scripts/verificar-vazamento.sh
grep -n "kill-switch" .opencode/rules/hacker-opsec-canon.md .hacker/gate/GATE-DE-PROTECAO.md
bash ~/opsec/scripts/verificar-vazamento.sh  # GOOD obrigatorio antes de QUALQUER acao de rede
git diff --check   # se repo git; aqui repo nao e git, usar whitespace check manual se aplicavel
```