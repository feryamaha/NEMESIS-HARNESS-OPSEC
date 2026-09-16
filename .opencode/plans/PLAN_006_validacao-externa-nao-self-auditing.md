# Verificador Externo (segunda leitura) - Plano de Implementacao

> **Para agentes**: Use hacker-subagent-driven-development para executar este plano.

**Objetivo**: Criar segundo leitor deterministico e independente do `verificar-vazamento.sh`, com
caminho proprio por vetor, veredito `[GOOD]`/`[GAP]`, fail-closed e sem gravar IP real.

**Spec**: `.opencode/specs/SPEC_006_validacao-externa-nao-self-auditing.md`

**Arquivos Afetados**:
- CREATE: `~/opsec/scripts/verificador-externo.sh`
- MODIFY: `.hacker/gate/GATE-DE-PROTECAO.md` (adicionar secao "Segunda Leitura Independente")
- MODIFY: `.opencode/rules/hacker-opsec-canon.md` (linha na tabela, apos gate-enforcement)

**Arquitetura**: Script novo em bash, autocontido, que roda apos o atestado GOOD. Antes de
qualquer consulta externa, pre-cheque local via `ss` na porta 9050; se Tor nao estiver
ouvindo, emite `[GAP]` imediato sem tocar rede (fail-closed). Cada vetor (IP de saida,
DNS-ECS, IPv6, Tor, WebRTC/DNS pre-condicoes) usa fonte e parsing distintos do verificador
original (endpoints B, resolvedor Quad9, IPv6 por estado local em vez de curl, Tor por
regex sem jq). Pre-condicao classe C (opsec_sensitive, pasta de protecao).

**Stack**: bash (perfil do repo). Sem dependencias novas.

---

## TASK 1: Criar o verificador externo

**Arquivo**: `~/opsec/scripts/verificador-externo.sh`

**Arquivos**:
- CREATE: `~/opsec/scripts/verificador-externo.sh`

**Depende de**: nenhuma

**Verificacao**:
```bash
bash -n ~/opsec/scripts/verificador-externo.sh
```

**Descricao Detalhada**:
Script autocontido em bash, `set -uo pipefail`, que emite `[GOOD]`/`[GAP]` com prefixo
`[VERIF-EXT]` (greppavel). Fail-closed em 3 marcadores ANTES de qualquer consulta externa:
(1) `ss -ltn 'sport = :9050'` Tor listening, senao exit 0 com `[GAP]` sem rede; (2) curl
localizavel E executavel via `command -v` + `[ -x ... ]` (fronteira da sessao, x-bit do
gate-enforcement), senao exit 0 com `[GAP]`; (3) interface VPN `wg0`/`proton0` presente via
`ip -br a` (red team involuntario bloqueado: sem estes marcadores o script NAO executa
dig/curl pela rota default com IP real). 5 vetores: (1) IP de saida via icanhazip.com
direto e via `-x socks5h://127.0.0.1:9050`, comparacao local exigindo AMBOS nao-vazios (senao
GAP) e IP da rota default omitido da saida; (2) DNS-ECS via `dig @9.9.9.9` (Quad9) com
parse `sed -nE` distinto do `grep -oE` do verificador, comparacao mascarada com /24 do exit
node; sem IP de saida para comparar e ECS presente = GAP explicito; (3) IPv6 por
`/proc/sys/net/ipv6/conf/all/disable_ipv6` e `ip -6 addr show scope global` (estado local,
sem rede; contador de matches com `|| true` para nao quebrar sob pipefail quando zero); (4)
Tor via `docker ps --format` torproxy + `curl --socks5-hostname check.torproject.org/api/ip`
com `grep -qo '"IsTor":true'` (sem jq, regex propria); (5) WebRTC/DNS pre-condicoes:
variaveis `http_proxy`/`https_proxy`/`all_proxy` com socks5h e IPv6 global ausente (ja obtido
no vetor 3). IP real nunca impresso (privacidade R4); IP de saida (exit node) pode ser
citado, consistente com o verificador. Saída final: `[GOOD] VERIFICACAO INDEPENDENTE:
CORROBORADO` ou `[GAP] VERIFICACAO INDEPENDENTE: X vetor(es) NAO corroboraram` com instrucao
de registrar no Trust Ledger.

Correcoes do revisor P2 aplicadas (ciclo 1, C1 a C4): contador IPv6 com `|| true` (C1);
vetor 1 exige `-n` em IP_PROXY e IP_DIRETO (C2); vetor 2 com ECS presente e IP_PROXY vazio =
GAP (C3); pre-cheque estendido com curl executavel + interface VPN (C4).

**Implementacao** (o codigo do disco, fiel):
```bash
#!/usr/bin/env bash
# verificador-externo.sh - segundo leitor independente da cadeia (SPEC_006)
# Deterministico, sem LLM, sem libs novas; roda localmente apos o atestado GOOD.
# Repete amostra dos vetores por meios e fontes DISTINTOS do verificar-vazamento.sh.
# Fail-closed: sem Tor local (ss 9050) nao toca rede e emite [GAP].
# Nao grava IP real; IP de saida (exit node) pode ser citado (consistente com o verificador).
set -uo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
GOOD() { echo -e "${GREEN}[GOOD]${NC} [VERIF-EXT] $*"; }
GAP()  { echo -e "${RED}[GAP]${NC} [VERIF-EXT] $*"; }
WARN() { echo -e "${YELLOW}[!]${NC} [VERIF-EXT] $*"; }
INFO() { echo -e "${YELLOW}[INFO]${NC} [VERIF-EXT] $*"; }

echo "=================================================="
echo "  VERIFICADOR EXTERNO - SEGUNDA LEITURA"
echo "  $(date '+%d/%m/%Y %H:%M:%S')"
echo "=================================================="

# --- PRE-CHEQUE: fail-closed, sem rede ---
TOR_UP=false
ss -ltn 'sport = :9050' 2>/dev/null | grep -q ':9050' && TOR_UP=true
if [[ "$TOR_UP" == false ]]; then
    GAP "Cadeia nao operacional: Tor (porta 9050) nao detectado via ss. Nenhuma consulta externa realizada (fail-closed)."
    echo "=================================================="
    exit 0
fi

# Fail-closed total: alem do Tor, exige curl executavel (fronteira da sessao via
# gate-enforcement) e interface VPN (wg0/proton0). Red team involuntario bloqueado:
# sem estes marcadores, o script NAO executa dig/curl pela rota default com IP real.
CURL_PATH=""
command -v curl >/dev/null 2>&1 && [ -x "$(command -v curl)" ] && CURL_PATH="$(command -v curl)"
VPN_IFACE=$(ip -br a 2>/dev/null | grep -oE '^(wg0|proton0)' | head -1)

if [[ -z "$CURL_PATH" ]]; then
    GAP "Cadeia nao operacional: curl nao localizavel/executavel (x-bit revogado pelo gate-enforcement?). Fail-closed: sem consulta externa."
    echo "=================================================="
    exit 0
fi
if [[ -z "$VPN_IFACE" ]]; then
    GAP "Cadeia nao operacional: interface VPN (wg0/proton0) ausente via ip -br a. Fail-closed: sem consulta externa."
    echo "=================================================="
    exit 0
fi

VETORES_GAP=0

# --- VETOR 1: IP de saida (fonte icanhazip.com, parser proprio) ---
echo ""
INFO "VETOR 1: IP de saida (fonte B: icanhazip.com)"
IP_PROXY=$(curl -s4 --max-time 15 -x socks5h://127.0.0.1:9050 https://icanhazip.com 2>/dev/null | tr -d '[:space:]')
IP_DIRETO=$(curl -s4 --max-time 10 https://icanhazip.com 2>/dev/null | tr -d '[:space:]')

if [[ -n "$IP_PROXY" && -n "$IP_DIRETO" && "$IP_PROXY" != "$IP_DIRETO" ]]; then
    GOOD "IP via Tor ($IP_PROXY) difere do IP da rota default (omitido por privacidade); saida anonima confirmada."
elif [[ -n "$IP_PROXY" && -n "$IP_DIRETO" ]]; then
    GAP "IP via Tor ($IP_PROXY) e identico ao IP da rota default (omitido); saida anonima NAO confirmada."
    VETORES_GAP=$((VETORES_GAP+1))
elif [[ -z "$IP_PROXY" ]]; then
    GAP "Falha ao obter IP via Tor (icanhazip.com); conexao Tor possivelmente bloqueada."
    VETORES_GAP=$((VETORES_GAP+1))
else
    GAP "Falha ao obter IP da rota default (curl direto vazio); nao e possivel comparar saida anonima."
    VETORES_GAP=$((VETORES_GAP+1))
fi

# --- VETOR 2: DNS-ECS (Quad9 9.9.9.9, parser sed proprio, distinto do verificador) ---
echo ""
INFO "VETOR 2: DNS-ECS (resolvedor 9.9.9.9 Quad9)"
ECS_RAW=$(dig +short +time=5 +tries=1 TXT o-o.myaddr.l.google.com @9.9.9.9 2>/dev/null | tr -d '"')
ECS_SUBNET=$(echo "$ECS_RAW" | sed -nE 's/.*([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\/[0-9]{1,2}).*/\1/p' | head -1)

if [[ -z "$ECS_RAW" ]]; then
    GAP "Consulta ECS via Quad9 (9.9.9.9) falhou ou retornou vazio."
    VETORES_GAP=$((VETORES_GAP+1))
elif [[ "$ECS_SUBNET" =~ ^(172\.|10\.|127\.) ]]; then
    GOOD "Resolver Quad9 sem subnet ECS publica; sua origem nao e revelada."
elif [[ -n "$ECS_SUBNET" && -z "$IP_PROXY" ]]; then
    GAP "ECS via Quad9 respondeu subnet ($ECS_SUBNET) e o IP de saida nao foi obtido; sem comparacao possivel (possivel leak)."
    VETORES_GAP=$((VETORES_GAP+1))
elif [[ -n "$ECS_SUBNET" && -n "$IP_PROXY" ]]; then
    PROXY_PREFIX=$(echo "$IP_PROXY" | sed -E 's/\.[0-9]+$/\.0\/24/')
    if [[ "$ECS_SUBNET" == "$PROXY_PREFIX" ]]; then
        GOOD "ECS Quad9 e coerente com o IP de saida (mesmo /24 mascarado)."
    else
        GAP "ECS Quad9 ($ECS_SUBNET) difere do /24 do IP de saida (mascarado); possivel leak."
        VETORES_GAP=$((VETORES_GAP+1))
    fi
else
    GOOD "ECS detectado sem subnet publica visivel; sem leak aparente."
fi

# --- VETOR 3: IPv6 (estado local, sem rede) ---
echo ""
INFO "VETOR 3: IPv6 (estado local, sem rede)"
DISABLE_ALL=$(cat /proc/sys/net/ipv6/conf/all/disable_ipv6 2>/dev/null || echo "0")
IP6_GLOBAL=$(ip -6 addr show scope global 2>/dev/null | grep -c 'inet6' || true)

if [[ "$DISABLE_ALL" == "1" && "$IP6_GLOBAL" -eq 0 ]]; then
    GOOD "IPv6 global desativado (disable=1, enderecos globais=0); sem risco de vazamento v6."
elif [[ "$IP6_GLOBAL" -gt 0 ]]; then
    GAP "IPv6 global detectado ($IP6_GLOBAL endereco(s)); risco de vazamento via WebRTC/STUN."
    VETORES_GAP=$((VETORES_GAP+1))
else
    WARN "IPv6 parcialmente ativo (disable=$DISABLE_ALL, globais=$IP6_GLOBAL); revisar configuracao."
    VETORES_GAP=$((VETORES_GAP+1))
fi

# --- VETOR 4: Tor (docker ps + check.torproject.org sem jq, regex propria) ---
echo ""
INFO "VETOR 4: Tor (servico local + saida HTTP)"
DOCKER_TOR=$(docker ps --format '{{.Names}} {{.Status}}' 2>/dev/null | grep -i torproxy | head -1)
if [[ -n "$DOCKER_TOR" ]]; then
    GOOD "Container torproxy detectado: $DOCKER_TOR"
else
    WARN "Container torproxy nao encontrado em docker ps; tentando verificacao via HTTP."
fi

TOR_CHECK=$(curl -s4 --max-time 15 --socks5-hostname localhost:9050 https://check.torproject.org/api/ip 2>/dev/null)
if echo "$TOR_CHECK" | grep -qo '"IsTor":true'; then
    GOOD "Saida via Tor confirmada (check.torproject.org, parse regex proprio)."
elif [[ -n "$TOR_CHECK" ]]; then
    GAP "Resposta do check.torproject.org indica saida NAO-Tor: $(echo "$TOR_CHECK" | tr -d '[:space:]')"
    VETORES_GAP=$((VETORES_GAP+1))
else
    GAP "Falha ao conectar check.torproject.org via Tor."
    VETORES_GAP=$((VETORES_GAP+1))
fi

# --- VETOR 5: WebRTC/DNS (pre-condicoes locais, sem rede) ---
echo ""
INFO "VETOR 5: WebRTC/DNS (pre-condicoes locais)"
SHELL_PROXY="${http_proxy:-}${https_proxy:-}${all_proxy:-}"
if echo "$SHELL_PROXY" | grep -q 'socks5h://127.0.0.1:9050'; then
    GOOD "Proxy SOCKS5 configurado no ambiente do shell (http_proxy/https_proxy/all_proxy)."
else
    WARN "Proxy SOCKS5 nao detectado nas variaveis do shell. Navegadores podem nao usar o Tor."
fi
if [[ "$DISABLE_ALL" == "1" && "$IP6_GLOBAL" -eq 0 ]]; then
    GOOD "Pre-condicao WebRTC-DNS satisfeita: sem IPv6 global (STUN v6 nao vaza via SOCKS)."
else
    GAP "Pre-condicao WebRTC-DNS NAO satisfeita: IPv6 global pode vazar via STUN."
    VETORES_GAP=$((VETORES_GAP+1))
fi

# --- VEREDITO FINAL ---
echo ""
echo "=================================================="
if [[ "$VETORES_GAP" -eq 0 ]]; then
    GOOD "VERIFICACAO INDEPENDENTE: CORROBORADO (todos os vetores passaram)."
else
    GAP "VERIFICACAO INDEPENDENTE: $VETORES_GAP vetor(es) NAO corroboraram. Reconciliar com atestado e registrar no Trust Ledger (append-only)."
fi
echo "=================================================="
```

---

## TASK 2: Documentar a segunda leitura no gate

**Arquivo**: `.hacker/gate/GATE-DE-PROTECAO.md`

**Arquivos**:
- MODIFY: `.hacker/gate/GATE-DE-PROTECAO.md` (inserir apos linha 71, antes de "## Privacidade")

**Depende de**: TASK 1

**Verificacao**:
```bash
grep -n "Segunda Leitura\|verificador-externo" .hacker/gate/GATE-DE-PROTECAO.md
```

**Descricao Detalhada**:
Inserir nova secao nivel 2 documentando o segundo leitor independente. Incluir comando de
uso, resultado esperado, os 3 marcadores do fail-closed (Tor 9050, curl executavel,
interface VPN) e limitacao do WebRTC. Sem travessao; sem primeira pessoa.

**Implementacao** (inserir entre a linha 71 e a linha 73):
```md
## Segunda Leitura Independente (SPEC_006)

Alem do `verificar-vazamento.sh`, uma segunda leitura deterministica e independente
esta disponivel: `~/opsec/scripts/verificador-externo.sh`.

Comando (executar apos o atestado GOOD, com sudo):

```bash
bash ~/opsec/scripts/verificador-externo.sh
```

Resultado esperado:
- `[GOOD] VERIFICACAO INDEPENDENTE: CORROBORADO` se todos os vetores passaram.
- `[GAP] VERIFICACAO INDEPENDENTE: X vetor(es) NAO corroboraram` se houver divergencia.
  Nesse caso, reconciliar com o atestado e registrar no Trust Ledger (append-only, saida
  literal do GAP).

Fail-closed em 3 marcadores, todos checados ANTES de qualquer consulta externa:
- Tor local ouvindo na porta 9050 (`ss -ltn 'sport = :9050'`);
- `curl` localizavel e executavel (`command -v` + x-bit; fronteira da sessao via
  gate-enforcement, GATE acima);
- interface VPN `wg0`/`proton0` presente (`ip -br a`).
Sem qualquer um deles, o script emite `[GAP] Cadeia nao operacional` imediato
sem executar dig/curl (sem vazamento de IP real pela rota default).

Limitacao declarada: WebRTC real so e mensuravel dentro de navegador; o verificador
externo cobre as PRE-CONDICOES (IPv6 global ausente e proxy SOCKS5 configurado no shell)
mas nao substitui o teste manual no navegador (`https://browserleaks.com/webrtc`).

Fonte: `.opencode/specs/SPEC_006_validacao-externa-nao-self-auditing.md`.
```

---

## TASK 3: Adicionar modulo no canon da cadeia

**Arquivo**: `.opencode/rules/hacker-opsec-canon.md`

**Arquivos**:
- MODIFY: `.opencode/rules/hacker-opsec-canon.md` (adicionar linha na tabela, apos linha 41)

**Depende de**: TASK 1

**Verificacao**:
```bash
grep -c "verificador-externo" .opencode/rules/hacker-opsec-canon.md
```

**Descricao Detalhada**:
Adicionar linha na tabela "Cadastro canonico por modulo" entre o `gate-enforcement` (linha 41)
e a secao "Hierarquia de decisao" (linha 43). Estado esperado: `[GOOD]` corroborado quando
todos os vetores independentes passam; `[GAP]` quando um ou mais divergem do atestado.

**Implementacao** (inserir como nova linha 42, antes de `## Hierarquia`):
```md
| verificador-externo (segunda leitura) | segundo leitor independente do verificar-vazamento.sh; valida uma amostra dos vetores (IP de saida, DNS-ECS, IPv6, Tor, WebRTC/DNS pre-condicoes) por meios e fontes DISTINTOS; emite `[GOOD]` corroborado ou `[GAP]`; fail-closed (sem Tor local = sem rede, GAP imediato) | `[GOOD]` quando todos os vetores passam; `[GAP]` com saída literal dos vetores que falharam; divergencia do atestado registrada no Trust Ledger (append-only) | `~/opsec/scripts/verificador-externo.sh` |
```

---

## TASK 4: Validacao final (suite do perfil)

**Arquivo**: verificacao pos-implementation

**Arquivos**: NENHUM

**Depende de**: TASK 1, TASK 2, TASK 3

**Verificacao**:
```bash
bash -n ~/opsec/scripts/verificador-externo.sh && echo "PASS: sintaxe"
grep -c "VERIF-EXT\|\[GAP\]\|\[GOOD\]" ~/opsec/scripts/verificador-externo.sh && echo "PASS: saida greppavel"
grep -n "Segunda Leitura\|verificador-externo" .hacker/gate/GATE-DE-PROTECAO.md | head -5 && echo "PASS: gate"
grep -c "verificador-externo" .opencode/rules/hacker-opsec-canon.md && echo "PASS: canon"
grep -c '—\|–' ~/opsec/scripts/verificador-externo.sh .hacker/gate/GATE-DE-PROTECAO.md .opencode/rules/hacker-opsec-canon.md .opencode/specs/SPEC_006*.md && echo "Travessao (esperado 0)" || echo "PASS: sem travessao"
```

**Descricao Detalhada**:
Rodar os comandos de verificacao do perfil e conferir que todos PASS. Em seguida, rodar
`bash ~/opsec/scripts/verificador-externo.sh` sem rede (fora de sessao): resultado esperado
e um `[GAP] Cadeia nao operacional` do pre-cheque com exit 0 e ZERO consulta externa. No
estado atual do ambiente, Tor pode estar escutando na 9050 sem sessao; o marcador que
dispara e o curl nao executavel (x-bit revogado) OU a ausencia de interface VPN, conforme a
ordem do pre-cheque. Essa e a validacao do modo fail-closed (SUNSET F7). Teste com cadeia
viva (GOOD corroborado) fica pendente ate a cadeia operacional.

**Implementacao** (comandos de execucao):
```bash
# 1. Validacao estatica
bash -n ~/opsec/scripts/verificador-externo.sh
grep -c "VERIF-EXT\|\[GAP\]\|\[GOOD\]" ~/opsec/scripts/verificador-externo.sh
grep -n "Segunda Leitura\|verificador-externo" .hacker/gate/GATE-DE-PROTECAO.md | head -5
grep -c "verificador-externo" .opencode/rules/hacker-opsec-canon.md

# 2. Teste SUNSET F7 (sem rede, sem sudo): fail-closed esperado
bash ~/opsec/scripts/verificador-externo.sh
# Esperado: [GAP] [VERIF-EXT] Cadeia nao operacional: <marcador que falhou>...
#   (curl executavel | interface VPN | Tor 9050), say quando o ambiente estiver fora de sessao
# Exit code: 0
# Garantia: nenhum dig/curl real executado (fail-closed total)
```
