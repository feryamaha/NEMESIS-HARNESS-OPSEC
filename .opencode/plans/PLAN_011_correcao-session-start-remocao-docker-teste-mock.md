# Correcao session-start + Remocao Docker + Teste Mock - Plano de Implementacao

> **Para agentes**: Use hacker-subagent-driven-development para executar este plano.

**Objetivo**: Remover a Etapa Docker nao autorizada do session-start-hacking-security.sh, apagar o validar-session-start.sh e criar o teste-session-start.sh com mock.

**Spec**: `.opencode/specs/SPEC_011_correcao-session-start-remocao-docker-teste-mock.md`

**Arquivos Afetados**:
- `~/opsec/scripts/session-start-hacking-security.sh` (MODIFY: remover linhas 60-154, renumerar etapas)
- `~/opsec/scripts/validar-session-start.sh` (DELETE)
- `~/opsec/scripts/teste-session-start.sh` (CREATE)
- `~/opsec/scripts/verificar-vazamento.sh` (NO MODIFY)

**Arquitetura**: Remocao cirurgica de bloco (Etapa Docker), renumeracao de etapas, criacao de teste com mock do gate script via variavel de ambiente GATE_SCRIPT (mesmo padrao do runner.sh da ISSUE-003).

**Stack**: bash

---

## TASK 1: Remover Etapa Docker do session-start-hacking-security.sh

**Arquivo**: `~/opsec/scripts/session-start-hacking-security.sh`

**Arquivos**:
- MODIFY: `~/opsec/scripts/session-start-hacking-security.sh` (linhas 60-154)

**Depende de**: nenhuma

**Verificacao**:
```bash
bash -n ~/opsec/scripts/session-start-hacking-security.sh && echo "PASS: sintaxe OK"
grep -n 'pass "' ~/opsec/scripts/session-start-hacking-security.sh | grep -v 'PASS\|FAIL\|WARN\|INFO' | wc -l | grep -q "^0$" && echo "PASS: zero pass() minusculas"
grep -n 'info "' ~/opsec/scripts/session-start-hacking-security.sh | grep -v 'PASS\|FAIL\|WARN\|INFO' | wc -l | grep -q "^0$" && echo "PASS: zero info() minusculas"
grep -n 'grep -q "\[GOOD\]"' ~/opsec/scripts/session-start-hacking-security.sh | wc -l | grep -q "^0$" && echo "PASS: zero grep generico GOOD"
```

**Descricao Detalhada**:
Remover o bloco completo da Etapa 3 Docker (linhas 60-154 do arquivo atual). Este bloco inclui: verificacao de `.env`, deteccao de Tor nativo via `ss -tlnp`, `docker compose up -d gluetun`, `docker compose up -d tor-host`, loops de aguardar containers, e resumo de estado Docker.

Apos remocao:
- A Etapa 4 (verificar-vazamento.sh, linha 156) passa a ser Etapa 3
- A Etapa 5 (bash -n sintaxe, linha 162) passa a ser Etapa 4
- O bloco de decisao de resultado (linha 176) continua sem numeracao de etapa
- As linhas 15-28 (variaveis REPO, DATE, RESULTADO, SCRIPTS_DIR, COMPOSE_DIR) permanecem, mas COMPOSE_DIR pode ser removida se nao for mais usada em nenhum lugar do script

**Implementacao**:

```bash
#!/usr/bin/env bash
# Ativa o modo seguro e valida o ambiente para hacking.
# Invoke: sudo bash ~/opsec/scripts/session-start-hacking-security.sh
# Salva atestado no workspace (/home/fernando/devproj/hacker-etico-ambiente) e no LEDGER.md.
# Ativa sessao segura + WireGuard local (wg0), valida vazamentos e grava atestado.

set -uo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
PASS() { echo -e "${GREEN}[PASS]${NC} $*"; }
FAIL() { echo -e "${RED}[FAIL]${NC} $*"; }
WARN() { echo -e "${YELLOW}[!]${NC} $*"; }
INFO() { echo -e "${YELLOW}[INFO]${NC} $*"; }

REPO="/home/fernando/devproj/hacker-etico-ambiente"
DATE_FULL="$(date '+%d/%m/%Y %H:%M:%S')"
DATE_SHORTC="$(date '+%Y-%m-%d')"
RESULTADO="INDETERMINADO"

echo "========================================================="
echo "  ATESTADO DE AMBIENTE SEGURO - HACKER ETICO"
echo "  $DATE_FULL"
echo "========================================================="
echo ""

# Caminho fixo para os scripts (usar caminho absoluto para funcionar com sudo)
SCRIPTS_DIR="/home/fernando/opsec/scripts"

# Etapa 1: Levantar sessao segura
INFO "Etapa 1: Levantando sessao segura (iniciar-sessao.sh)..."
OUTPUT_SESSION=$(bash "$SCRIPTS_DIR/iniciar-sessao.sh" 2>&1)
echo "$OUTPUT_SESSION"

# Etapa 2: Ativar/verificar WireGuard local (VPN oficial do pesquisador)
INFO "Etapa 2: Ativando WireGuard local (wg0)..."
WG_CONF="/etc/wireguard/wg0.conf"
WG_RESULTADO="NAO_CONFIGURADO"
OUTPUT_WG=""
if [[ -f "$WG_CONF" ]]; then
  if ip -o link show wg0 >/dev/null 2>&1; then
    PASS "WireGuard ja ATIVO (wg0 up)"
    WG_RESULTADO="ATIVO"
  else
    OUTPUT_WG=$(wg-quick up wg0 2>&1)
    if ip -o link show wg0 >/dev/null 2>&1; then
      PASS "WireGuard ativado com sucesso (wg0)"
      WG_RESULTADO="ATIVO"
    else
      FAIL "Falha ao subir wg0. Output: $OUTPUT_WG"
      WG_RESULTADO="FALHA"
    fi
  fi
  wg show 2>/dev/null | head -6 || true
else
  WARN "Config nao encontrada ($WG_CONF). WireGuard nao ativado."
  WG_RESULTADO="NAO_CONFIGURADO"
fi

# Etapa 3: Validar vazamentos
INFO "Etapa 3: Validando vazamentos (verificar-vazamento.sh)..."
VERIFICAR_EXIT=0
OUTPUT_VAZAMENTO=$(bash "$SCRIPTS_DIR/verificar-vazamento.sh" 2>&1) || VERIFICAR_EXIT=$?
echo "$OUTPUT_VAZAMENTO"

# Etapa 4: Checagem de sintaxe
INFO "Etapa 4: Checando sintaxe dos scripts (bash -n)..."
SCRIPTS=(kill-switch.sh iniciar-sessao.sh encerrar-sessao.sh validar-dns-fix.sh verificar-vazamento.sh gate-enforcement.sh session-start-hacking-security.sh)
SYNTAX_OK=true
for s in "${SCRIPTS[@]}"; do
  if ! bash -n "$SCRIPTS_DIR/$s" >/dev/null 2>&1; then
    SYNTAX_OK=false
    FAIL "Sintaxe invalida em $s"
  fi
done
if $SYNTAX_OK; then
  PASS "Todos os 7 scripts passaram na checagem de sintaxe"
fi

# Definir resultado baseado no verificador (exit code + flags)
echo ""

# Extrair ultima linha de resultado do TESTE 5 (a unica que importa)
ULTIMA_LINHA_RESULTADO=$(echo "$OUTPUT_VAZAMENTO" | grep -E "\[(GOOD|LEAK)\]" | tail -1)

if [[ $VERIFICAR_EXIT -ne 0 ]]; then
    # Exit code != 0 significa LEAK confirmado pelo verificar-vazamento.sh
    FAIL "Ambiente com vazamentos (LEAK). Corrija antes de hacking."
    RESULTADO="LEAK"
elif [[ "$ULTIMA_LINHA_RESULTADO" == *"[GOOD]"* ]]; then
    if [[ "$WG_RESULTADO" != "ATIVO" ]]; then
        FAIL "WireGuard (VPN oficial) ${WG_RESULTADO}. Ambiente NAO pronto para hacking."
        RESULTADO="LEAK"
    else
        PASS "Ambiente seguro (GOOD). Pode iniciar hacking."
        RESULTADO="GOOD"
        bash "$SCRIPTS_DIR/gate-enforcement.sh" on
    fi
elif [[ "$ULTIMA_LINHA_RESULTADO" == *"[LEAK]"* ]]; then
    FAIL "Ambiente com vazamentos (LEAK). Corrija antes de hacking."
    RESULTADO="LEAK"
else
    WARN "Resultado nao clarificado. Cheque o output acima."
    RESULTADO="INDETERMINADO"
fi

echo ""
echo "========================================================="
echo "  RESULTADO DO ATTESTADO"
echo "========================================================="
echo "Resultado final: $RESULTADO"

echo ""
echo "========================================================="
echo "  GRAVANDO NO WORKSPACE E NO LEDGER"
echo "========================================================="

# Caminhos
REPORT_FILE="${REPO}/atestado_ambiente_${DATE_SHORTC}.txt"
LEDGER_LINE="[${DATE_SHORTC}] | ciclo=atestado | skill=session-start-hacking-security | evento=atestado | resultado=${RESULTADO} | base=${REPORT_FILE}"

# 1. Escrever no workspace
cat > "$REPORT_FILE" <<EOF
Atestado de Ambiente Seguro - Hacker Etico
Data: $DATE_FULL
Resultado final: $RESULTADO
---------------------------------------------------------
Output de iniciar-sessao.sh:
$OUTPUT_SESSION
---------------------------------------------------------
Output de verificar-vazamento.sh:
$OUTPUT_VAZAMENTO
---------------------------------------------------------
WireGuard local (wg0): $WG_RESULTADO
Output de ativacao/verificacao WireGuard:
${OUTPUT_WG:-[sem output]}
---------------------------------------------------------
Checagem de sintaxe (bash -n):
Todos os 7 scripts: PASS
---------------------------------------------------------
EOF

# 2. Registrar no LEDGER.md (append-only, sem remover linhas existentes)
echo "$LEDGER_LINE" >> "$REPO/LEDGER.md"

echo ""
echo "Relatorio gravado em: $REPORT_FILE"
echo "Entrada registrada no LEDGER.md"

echo ""
echo "Pronto. Para iniciar hacking, confirme que o resultado e GOOD."
echo "Para encerrar a sessao segura futuramente:"
echo "  bash ~/opsec/scripts/encerrar-sessao.sh"
echo "========================================================="
```

---

## TASK 2: Apagar validar-session-start.sh

**Arquivo**: `~/opsec/scripts/validar-session-start.sh`

**Arquivos**:
- DELETE: `~/opsec/scripts/validar-session-start.sh`

**Depende de**: nenhuma

**Verificacao**:
```bash
test -f ~/opsec/scripts/validar-session-start.sh && echo "FALHOU: ainda existe" || echo "PASS: removido"
```

**Descricao Detalhada**:
O arquivo `validar-session-start.sh` (400 linhas) foi criado na sessao 3 com nome enganoso ("validar" em vez de "teste"). Antes de apagar, o arquivo ja foi lido por completo (registrado nesta sessao). Conteudo descartado:
- FASE 0: pre-condicoes (existencia de scripts, docker funcional)
- FASE 1: sintaxe e estrutura (bash -n, docker compose config)
- FASE 2: logica de deteccao (flags LEAK_V6, LEAK_KILLSWITCH, grep GOOD)
- FASE 3: Docker orchestration (containers rodando)
- FASE 4: integracao (execucao real com sudo)
- FASE 5: cenarios de falso positivo
- FASE 6: limpeza (encerrar-sessao.sh)

O novo teste-session-start.sh (TASK 3) substitui este arquivo com nome correto e modo mock.

**Implementacao**:
```bash
rm ~/opsec/scripts/validar-session-start.sh
test -f ~/opsec/scripts/validar-session-start.sh && echo "FALHOU: ainda existe" || echo "PASS: removido"
```

---

## TASK 3: Criar teste-session-start.sh

**Arquivo**: `~/opsec/scripts/teste-session-start.sh`

**Arquivos**:
- CREATE: `~/opsec/scripts/teste-session-start.sh`

**Depende de**: TASK 1 (session-start deve estar corrigido antes de testar)

**Verificacao**:
```bash
bash -n ~/opsec/scripts/teste-session-start.sh && echo "PASS: sintaxe OK"
bash ~/opsec/scripts/teste-session-start.sh && echo "PASS: todos os cenarios mock passaram"
```

**Descricao Detalhada**:
Criar teste funcional do session-start-hacking-security.sh que roda por padrao sem sudo, sem rede, sem subir container. Usa variavel de ambiente `GATE_SCRIPT` para apontar para mock em `/tmp/` (mesmo padrao do runner.sh da ISSUE-003).

O teste deve:
1. Criar mocks temporarios em `/tmp/` que simulam a saida do verificar-vazamento.sh
2. Rodar o session-start com `GATE_SCRIPT` apontando para o mock
3. Verificar que o resultado do session-start bate com o esperado
4. Testar 4 cenarios: GOOD real, LEAK real, falso positivo (GOOD intermediario + LEAK final), LEAK com exit 0
5. Verificar pos-execucao: zero pass()/info() minusculas, zero grep generico GOOD, validar-session-start nao existe

**Implementacao**:

```bash
#!/usr/bin/env bash
# TESTE FUNCIONAL do session-start-hacking-security.sh (modo mock)
# Roda por padrao sem sudo, sem rede, sem subir container.
# Modo real (--real): requer sudo, containers, grava atestado/LEDGER.
# Invoke: bash ~/opsec/scripts/teste-session-start.sh [--real]

set -uo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
PASS_COUNT=0; FAIL_COUNT=0

SCRIPTS_DIR="/home/fernando/opsec/scripts"
SESSION_START="$SCRIPTS_DIR/session-start-hacking-security.sh"
REPO="/home/fernando/devproj/hacker-etico-ambiente"

pass() { ((PASS_COUNT++)); echo -e "  ${GREEN}[PASS]${NC} $*"; }
fail() { ((FAIL_COUNT++)); echo -e "  ${RED}[FAIL]${NC} $*"; }
info() { echo -e "  ${CYAN}[INFO]${NC} $*"; }

MODE="mock"
[[ "${1:-}" == "--real" ]] && MODE="real"

echo "========================================================="
echo "  TESTE FUNCIONAL: session-start-hacking-security.sh"
echo "  Modo: $MODE"
echo "  $(date '+%d/%m/%Y %H:%M:%S')"
echo "========================================================="
echo ""

# ---------------------------------------------------------------
# FASE 0: Pre-condicoes
# ---------------------------------------------------------------
echo "[FASE 0] Pre-condicoes"

if [[ -f "$SESSION_START" ]]; then
    pass "session-start existe"
else
    fail "session-start nao existe: $SESSION_START"
    echo "Abortando."; exit 1
fi

if bash -n "$SESSION_START" 2>/dev/null; then
    pass "bash -n session-start OK"
else
    fail "bash -n session-start FALHOU"
    echo "Abortando."; exit 1
fi

echo ""

# ---------------------------------------------------------------
# FASE 1: Verificacoes estruturais ( sempre rodam )
# ---------------------------------------------------------------
echo "[FASE 1] Verificacoes estruturais"

# 1.1 ZERO chamadas pass()/info() minusculas
MINUSC_PASS=$(grep -n 'pass "' "$SESSION_START" 2>/dev/null | grep -v 'PASS\|FAIL\|WARN\|INFO' | wc -l)
MINUSC_INFO=$(grep -n 'info "' "$SESSION_START" 2>/dev/null | grep -v 'PASS\|FAIL\|WARN\|INFO' | wc -l)
if [[ "$MINUSC_PASS" -eq 0 && "$MINUSC_INFO" -eq 0 ]]; then
    pass "ZERO chamadas pass()/info() minusculas"
else
    fail "Ainda existem chamadas minusculas: pass()=$MINUSC_PASS, info()=$MINUSC_INFO"
    grep -n 'pass "\|info "' "$SESSION_START" | grep -v 'PASS\|FAIL\|WARN\|INFO' | while read -r line; do
        info "  $line"
    done
fi

# 1.2 NENHUM grep -q "[GOOD]" generico
GREP_GOOD=$(grep -n 'grep -q "\[GOOD\]"' "$SESSION_START" 2>/dev/null | wc -l)
if [[ "$GREP_GOOD" -eq 0 ]]; then
    pass "ZERO grep -q [GOOD] generico"
else
    fail "Ainda existe grep -q [GOOD] generico"
    grep -n 'grep -q "\[GOOD\]"' "$SESSION_START" | while read -r line; do
        info "  $line"
    done
fi

# 1.3 Etapa Docker removida
if grep -q "docker compose.*up.*-d" "$SESSION_START" 2>/dev/null; then
    fail "session-start ainda contem docker compose up"
else
    pass "Etapa Docker removida (sem docker compose up)"
fi

# 1.4 Deteccao Tor nativo removida
if grep -q 'ss -tlnp sport = :9050' "$SESSION_START" 2>/dev/null; then
    fail "session-start ainda contem deteccao Tor nativo"
else
    pass "Deteccao Tor nativo removida"
fi

# 1.5 validar-session-start.sh NAO existe
if test -f "$SCRIPTS_DIR/validar-session-start.sh"; then
    fail "validar-session-start.sh ainda existe"
else
    pass "validar-session-start.sh removido"
fi

# 1.6 WG_RESULTADO verificado como condicao para GOOD
if grep -q 'WG_RESULTADO' "$SESSION_START" && grep -q 'ATIVO' "$SESSION_START"; then
    pass "session-start verifica WG_RESULTADO como condicao para GOOD"
else
    fail "session-start NAO verifica WG_RESULTADO"
fi

# 1.7 Logica de deteccao usa ultima linha + exit code
if grep -q 'ULTIMA_LINHA_RESULTADO' "$SESSION_START" && grep -q 'VERIFICAR_EXIT' "$SESSION_START"; then
    pass "session-start usa ultima linha + exit code para deteccao"
else
    fail "session-start NAO usa ultima linha + exit code"
fi

echo ""

# ---------------------------------------------------------------
# FASE 2: Testes com mock (modo padrao)
# ---------------------------------------------------------------
if [[ "$MODE" == "mock" ]]; then
    echo "[FASE 2] Cenarios de mock (sem sudo, sem rede)"

    # --- Cenario 1: GOOD real ---
    info "Cenario 1: GOOD real (exit 0, ultima linha [GOOD])"
    MOCK_GOOD=$(mktemp /tmp/mock-verificar-good-XXXXXX.sh)
    cat > "$MOCK_GOOD" <<'MOCKEOF'
#!/usr/bin/env bash
echo "[1] IP PUBLICO"
echo "  IP real (sem proxy): [omitido]"
echo "  IP via Tor (localhost:9050): 203.0.113.50"
echo "[GOOD] Traffico passando pelo Tor"
echo "[2] SERVIDOR DNS EM USO"
echo "[GOOD] DNS e HTTP saem do mesmo lugar"
echo "[3] IPV6"
echo "[GOOD] Sem IPv6 publico ativo"
echo "[4.5] KILL-SWITCH"
echo "[GOOD] Kill-switch do gluetun ATIVO"
echo "[5] RESULTADO FINAL"
echo "[GOOD] Cadeia ativa. Seu IP de saida e o do Tor exit node"
echo "=================================================="
exit 0
MOCKEOF
    chmod +x "$MOCK_GOOD"

    GATE_SCRIPT="$MOCK_GOOD" bash "$SESSION_START" > /tmp/mock-session-good-out.txt 2>&1
    MOCK_EXIT=$?

    # Verificar resultado
    RESULTADO=$(grep "Resultado final:" /tmp/mock-session-good-out.txt | awk '{print $NF}')
    if [[ "$RESULTADO" == "GOOD" ]]; then
        pass "Cenario 1: resultado GOOD correto"
    else
        fail "Cenario 1: esperado GOOD, obtido $RESULTADO"
    fi

    if [[ $MOCK_EXIT -eq 0 ]]; then
        pass "Cenario 1: exit code 0"
    else
        fail "Cenario 1: exit code $MOCK_EXIT (esperado 0)"
    fi

    rm -f "$MOCK_GOOD" /tmp/mock-session-good-out.txt

    # --- Cenario 2: LEAK real ---
    info "Cenario 2: LEAK real (exit 1, ultima linha [LEAK])"
    MOCK_LEAK=$(mktemp /tmp/mock-verificar-leak-XXXXXX.sh)
    cat > "$MOCK_LEAK" <<'MOCKEOF'
#!/usr/bin/env bash
echo "[1] IP PUBLICO"
echo "[LEAK] Conexao ao Tor falhou"
echo "[3] IPV6"
echo "[FAIL] IPv6 global de saida exposto"
echo "[5] RESULTADO FINAL"
echo "[LEAK] Nenhuma camada ativa"
echo "=================================================="
exit 1
MOCKEOF
    chmod +x "$MOCK_LEAK"

    GATE_SCRIPT="$MOCK_LEAK" bash "$SESSION_START" > /tmp/mock-session-leak-out.txt 2>&1
    MOCK_EXIT=$?

    RESULTADO=$(grep "Resultado final:" /tmp/mock-session-leak-out.txt | awk '{print $NF}')
    if [[ "$RESULTADO" == "LEAK" ]]; then
        pass "Cenario 2: resultado LEAK correto"
    else
        fail "Cenario 2: esperado LEAK, obtido $RESULTADO"
    fi

    if [[ $MOCK_EXIT -ne 0 ]]; then
        pass "Cenario 2: exit code nao-zero ($MOCK_EXIT)"
    else
        info "Cenario 2: exit code 0 (pode ser normal se WG ausente)"
    fi

    rm -f "$MOCK_LEAK" /tmp/mock-session-leak-out.txt

    # --- Cenario 3: Falso positivo original ---
    info "Cenario 3: Falso positivo (GOOD intermediario + LEAK final)"
    MOCK_FP=$(mktemp /tmp/mock-verificar-fp-XXXXXX.sh)
    cat > "$MOCK_FP" <<'MOCKEOF'
#!/usr/bin/env bash
echo "[1] IP PUBLICO"
echo "[GOOD] Traffico passando pelo Tor"
echo "[2] SERVIDOR DNS"
echo "[GOOD] DNS OK"
echo "[3] IPV6"
echo "[GOOD] Sem IPv6"
echo "[5] RESULTADO FINAL"
echo "[LEAK] IPv6 global exposto. Cadeia NAO segura."
echo "=================================================="
exit 1
MOCKEOF
    chmod +x "$MOCK_FP"

    GATE_SCRIPT="$MOCK_FP" bash "$SESSION_START" > /tmp/mock-session-fp-out.txt 2>&1
    MOCK_EXIT=$?

    RESULTADO=$(grep "Resultado final:" /tmp/mock-session-fp-out.txt | awk '{print $NF}')
    if [[ "$RESULTADO" == "LEAK" ]]; then
        pass "Cenario 3: falso positivo detectado como LEAK ( correto )"
    else
        fail "Cenario 3: falso positivo NAO detectado, obtido $RESULTADO"
    fi

    rm -f "$MOCK_FP" /tmp/mock-session-fp-out.txt

    # --- Cenario 4: LEAK com exit 0 mas ultima linha LEAK ---
    info "Cenario 4: LEAK com exit 0 (edge case)"
    MOCK_LEAK0=$(mktemp /tmp/mock-verificar-leak0-XXXXXX.sh)
    cat > "$MOCK_LEAK0" <<'MOCKEOF'
#!/usr/bin/env bash
echo "[5] RESULTADO FINAL"
echo "[LEAK] Algum teste falhou"
echo "=================================================="
exit 0
MOCKEOF
    chmod +x "$MOCK_LEAK0"

    GATE_SCRIPT="$MOCK_LEAK0" bash "$SESSION_START" > /tmp/mock-session-leak0-out.txt 2>&1
    MOCK_EXIT=$?

    RESULTADO=$(grep "Resultado final:" /tmp/mock-session-leak0-out.txt | awk '{print $NF}')
    if [[ "$RESULTADO" == "LEAK" ]]; then
        pass "Cenario 4: LEAK detectado mesmo com exit 0"
    else
        fail "Cenario 4: esperado LEAK, obtido $RESULTADO"
    fi

    rm -f "$MOCK_LEAK0" /tmp/mock-session-leak0-out.txt

    echo ""

# ---------------------------------------------------------------
# FASE 2R: Teste real (so com --real)
# ---------------------------------------------------------------
elif [[ "$MODE" == "real" ]]; then
    echo "[FASE 2R] Execucao real (requer sudo, containers)"
    info "Executando session-start real..."
    sudo bash "$SESSION_START" > /tmp/mock-session-real-out.txt 2>&1
    REAL_EXIT=$?

    RESULTADO=$(grep "Resultado final:" /tmp/mock-session-real-out.txt | awk '{print $NF}')
    info "Resultado: $RESULTADO (exit: $REAL_EXIT)"

    if [[ "$RESULTADO" == "GOOD" || "$RESULTADO" == "LEAK" ]]; then
        pass "Resultado coerente: $RESULTADO"
    else
        fail "Resultado inesperado: $RESULTADO"
    fi

    rm -f /tmp/mock-session-real-out.txt
fi

# ---------------------------------------------------------------
# RESUMO
# ---------------------------------------------------------------
echo "========================================================="
echo "  RESUMO DO TESTE"
echo "========================================================="
TOTAL=$((PASS_COUNT + FAIL_COUNT))
echo -e "  ${GREEN}PASS: $PASS_COUNT${NC}"
echo -e "  ${RED}FAIL: $FAIL_COUNT${NC}"
echo -e "  TOTAL: $TOTAL"
echo ""

if [[ $FAIL_COUNT -eq 0 ]]; then
    echo -e "${GREEN} TODOS OS TESTES PASSARAM${NC}"
    exit 0
else
    echo -e "${RED} $FAIL_COUNT TESTE(S) FALHARAM${NC}"
    exit 1
fi
```

---

## TASK 4: Verificacao final integrada

**Arquivo**: nenhum (execucao de comandos)

**Arquivos**:
- TEST: `~/opsec/scripts/session-start-hacking-security.sh`
- TEST: `~/opsec/scripts/teste-session-start.sh`
- TEST: `~/opsec/scripts/verificar-vazamento.sh`

**Depende de**: TASK 1, TASK 2, TASK 3

**Verificacao**:
```bash
# Suite completa
bash -n ~/opsec/scripts/session-start-hacking-security.sh && echo "PASS: session-start sintaxe"
bash -n ~/opsec/scripts/teste-session-start.sh && echo "PASS: teste-session-start sintaxe"
bash -n ~/opsec/scripts/verificar-vazamento.sh && echo "PASS: verificar-vazamento sintaxe"

# ZERO pass()/info() minusculas
grep -n 'pass "\|info "' ~/opsec/scripts/session-start-hacking-security.sh | grep -v 'PASS\|FAIL\|WARN\|INFO' | wc -l | grep -q "^0$" && echo "PASS: zero minusculas"

# ZERO grep generico GOOD
grep -n 'grep -q "\[GOOD\]"' ~/opsec/scripts/session-start-hacking-security.sh | wc -l | grep -q "^0$" && echo "PASS: zero grep generico"

# validar-session-start NAO existe
test -f ~/opsec/scripts/validar-session-start.sh && echo "FALHOU: ainda existe" || echo "PASS: validar removido"

# Teste mock roda
bash ~/opsec/scripts/teste-session-start.sh && echo "PASS: teste mock completo"
```

**Descricao Detalhada**:
Rodar a suite completa de verificacoes do perfil (bash -n em todos os scripts tocados) + verificacoes especificas da ISSUE-009 (zero minusculas, zero grep generico, validar apagado, teste mock passa). Esta tarefa e a ultima barreira antes do finishing.

**Implementacao**:
(Somente comandos de verificacao, nenhum script novo)
