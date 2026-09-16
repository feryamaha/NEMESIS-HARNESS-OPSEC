#!/bin/bash
#===============================================================================
# validar-scan-web.sh — Suite de Validacao SPEC_003 / PLAN_003
#                          Scan de Aplicacoes Web + Relatorio Tecnico
#===============================================================================
# Descricao: Valida a integridade e consistencia dos artefatos da capability
#            de Scan Web + Geracao de Relatorio Tecnico.
# Autor:     PLAN_003_web-app-scan-report.md
# Uso:       bash .hacker/scripts/validar-scan-web.sh
#===============================================================================
# Registrado em: .opencode/ledger/trust-ledger.md, .hacker/ledger/operacoes.md
#===============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
cd "$REPO_ROOT" || { echo "ERRO: nao foi possivel cd para $REPO_ROOT"; exit 1; }
PASS=0
FAIL=0
WARN=0

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_pass()  { echo -e "  ${GREEN}[PASS]${NC} $1"; PASS=$((PASS+1)); }
log_fail()  { echo -e "  ${RED}[FAIL]${NC} $1"; FAIL=$((FAIL+1)); }
log_warn()  { echo -e "  ${YELLOW}[WARN]${NC} $1"; WARN=$((WARN+1)); }

echo "==============================================================================="
echo "  VALIDACAO SPEC_003 / PLAN_003 — Scan de Aplicacoes Web + Relatorio Tecnico"
echo "  Data: $(date '+%Y-%m-%d %H:%M')"
echo "==============================================================================="

cd "$REPO_ROOT"

#-------------------------------------------------------------------------------
# FASE 1: EXISTENCIA E INTEGRIDADE DOS ARQUIVOS
#-------------------------------------------------------------------------------
echo ""
echo "FASE 1: EXISTENCIA E INTEGRIDADE DOS ARQUIVOS"
echo "-------------------------------------------------------------------------------"

test -f .opencode/rules/hacker-web-scan-report.md && log_pass ".opencode/rules/hacker-web-scan-report.md existe" || log_fail "REGRA AI nao encontrada"
test -f .hacker/agentes/web-scanner/AGENTE.md && log_pass ".hacker/agentes/web-scanner/AGENTE.md existe" || log_fail "Agente web-scanner nao encontrado"
test -d .hacker/reports && log_pass ".hacker/reports/ existe" || log_fail "Diretorio reports nao encontrado"
test -f .hacker/rag/README-RAG.md && log_pass ".hacker/rag/README-RAG.md existe" || log_fail "RAG nao encontrado"
test -f .hacker/gate/GATE-DE-PROTECAO.md && log_pass ".hacker/gate/GATE-DE-PROTECAO.md existe" || log_fail "Gate nao encontrado"
test -f .hacker/templates/TEMPLATE-RELATORIO.md && log_pass ".hacker/templates/TEMPLATE-RELATORIO.md existe" || log_fail "Template de relatorio nao encontrado"
test -f .hacker/orquestrador/ORQUESTRADOR.md && log_pass ".hacker/orquestrador/ORQUESTRADOR.md existe" || log_fail "Orquestrador nao encontrado"
test -f .hacker/ledger/operacoes.md && log_pass ".hacker/ledger/operacoes.md existe" || log_fail "Ledger de operacoes nao encontrado"

COUNT=$(find .hacker -type f | wc -l)
test $COUNT -eq 19 && log_pass "Contagem de arquivos .hacker/ = 19" || log_warn "Contagem de arquivos .hacker/ = $COUNT (esperado 19)"

#-------------------------------------------------------------------------------
# FASE 2: CONSISTENCIA ENTRE COMPONENTES
#-------------------------------------------------------------------------------
echo ""
echo "FASE 2: CONSISTENCIA ENTRE COMPONENTES"
echo "-------------------------------------------------------------------------------"

grep -q 'web-scanner' .hacker/orquestrador/ORQUESTRADOR.md && log_pass "Orquestrador menciona web-scanner" || log_fail "Orquestrador NAO menciona web-scanner"
grep -q 'zap-cli\|nuclei\|httpx' .hacker/gate/GATE-DE-PROTECAO.md && log_pass "Gate menciona ferramentas DAST web" || log_fail "Gate NAO menciona ZAP/Nuclei"
grep -q 'NVD' .hacker/rag/README-RAG.md && log_pass "RAG menciona NVD" || log_fail "RAG NAO menciona NVD"
grep -q 'OWASP Testing Guide' .hacker/rag/README-RAG.md && log_pass "RAG menciona OWASP Testing Guide" || log_fail "RAG NAO menciona OWASP Testing Guide"
grep -q 'CVSS' .hacker/templates/TEMPLATE-RELATORIO.md && log_pass "Template tem campo CVSS" || log_fail "Template NAO tem campo CVSS"
grep -q 'CWE' .hacker/templates/TEMPLATE-RELATORIO.md && log_pass "Template tem campo CWE" || log_fail "Template NAO tem campo CWE"
grep -q 'web-scanner' .hacker/README.md && log_pass "README menciona web-scanner" || log_fail "README NAO menciona web-scanner"

#-------------------------------------------------------------------------------
# FASE 3: LOGICA DO FLUXO (Gate → Scan → Parse → Relatorio → Ledger)
#-------------------------------------------------------------------------------
echo ""
echo "FASE 3: LOGICA DO FLUXO"
echo "-------------------------------------------------------------------------------"

grep -q 'verificar-vazamento.sh' .hacker/agentes/web-scanner/AGENTE.md && log_pass "Agente tem pre-requisito de Gate" || log_fail "Agente NAO tem pre-requisito de Gate"
grep -q 'TEMPLATE-OPERACAO' .hacker/agentes/web-scanner/AGENTE.md && log_pass "Agente usa TEMPLATE-OPERACAO" || log_fail "Agente NAO usa TEMPLATE-OPERACAO"
grep -q 'TEMPLATE-RELATORIO' .hacker/agentes/web-scanner/AGENTE.md && log_pass "Agente usa TEMPLATE-RELATORIO" || log_fail "Agente NAO usa TEMPLATE-RELATORIO"
grep -q '\.hacker/reports/' .hacker/agentes/web-scanner/AGENTE.md && log_pass "Agente salva em .hacker/reports/" || log_fail "Agente NAO salva em .hacker/reports/"
grep -q 'operacoes.md' .hacker/agentes/web-scanner/AGENTE.md && log_pass "Agente registra no ledger" || log_fail "Agente NAO registra no ledger"
grep -q 'Cabeçalho' .opencode/rules/hacker-web-scan-report.md && log_pass "Regra tem seccao Cabeçalho" || log_fail "Regra NAO tem seccao Cabeçalho"
grep -q 'Findings' .opencode/rules/hacker-web-scan-report.md && log_pass "Regra tem seccao Findings" || log_fail "Regra NAO tem seccao Findings"
grep -q 'Conclusão' .opencode/rules/hacker-web-scan-report.md && log_pass "Regra tem seccao Conclusão" || log_fail "Regra NAO tem seccao Conclusão"

#-------------------------------------------------------------------------------
# FASE 4: COMPLETUDE DO TEMPLATE DE RELATORIO
#-------------------------------------------------------------------------------
echo ""
echo "FASE 4: COMPLETUDE DO TEMPLATE DE RELATORIO"
echo "-------------------------------------------------------------------------------"

grep -q 'FIND' .hacker/templates/TEMPLATE-RELATORIO.md && log_pass "Template tem campo ID/FINDING" || log_fail "Template NAO tem campo ID/FINDING"
grep -q 'Titulo' .hacker/templates/TEMPLATE-RELATORIO.md && log_pass "Template tem campo Titulo" || log_fail "Template NAO tem campo Titulo"
grep -q 'Severidade' .hacker/templates/TEMPLATE-RELATORIO.md && log_pass "Template tem campo Severidade" || log_fail "Template NAO tem campo Severidade"
grep -q 'CWE' .hacker/templates/TEMPLATE-RELATORIO.md && log_pass "Template tem campo CWE" || log_fail "Template NAO tem campo CWE"
grep -q 'Evidencia' .hacker/templates/TEMPLATE-RELATORIO.md && log_pass "Template tem campo Evidencia" || log_fail "Template NAO tem campo Evidencia"
grep -q 'Impacto' .hacker/templates/TEMPLATE-RELATORIO.md && log_pass "Template tem campo Impacto" || log_fail "Template NAO tem campo Impacto"
grep -q 'Recomendacao' .hacker/templates/TEMPLATE-RELATORIO.md && log_pass "Template tem campo Recomendacao" || log_fail "Template NAO tem campo Recomendacao"
grep -q 'Critical\|High\|Medium\|Low\|Informational' .hacker/templates/TEMPLATE-RELATORIO.md && log_pass "Template tem severidades Critical→Informational" || log_fail "Template NAO tem todas as severidades"
grep -q 'CVSS v3.1' .opencode/rules/hacker-web-scan-report.md && log_pass "Regra menciona CVSS v3.1" || log_fail "Regra NAO menciona CVSS v3.1"

#-------------------------------------------------------------------------------
# FASE 5: AUSENCIA DE ARQUIVOS ORFANOS E CONTRADICOES
#-------------------------------------------------------------------------------
echo ""
echo "FASE 5: AUSENCIA DE ARQUIVOS ORFANOS E CONTRADICOES"
echo "-------------------------------------------------------------------------------"

test $(find .opencode/agents -name 'web*' 2>/dev/null | wc -l) -eq 0 && log_pass "Nenhum agente operacional em .opencode/agents/" || log_fail "Agente operacional encontrado em .opencode/agents/"
test $(find .hacker -name 'hacker-*.md' 2>/dev/null | wc -l) -eq 0 && log_pass "Nenhuma regra AI em .hacker/" || log_fail "Regra AI encontrada em .hacker/"
test $(find .hacker -name '*.tmp' -o -name '*.bak' 2>/dev/null | wc -l) -eq 0 && log_pass "Nenhum arquivo temporario" || log_fail "Arquivo temporario encontrado"
grep -q 'em dash\|—' .hacker/agentes/web-scanner/AGENTE.md 2>/dev/null && log_warn "Possivel em-dash encontrado no agente" || log_pass "Sem em-dash no agente"
grep -qE '([0-9]{1,3}\.){3}[0-9]{1,3}' .hacker/agentes/web-scanner/AGENTE.md 2>/dev/null && log_warn "Possivel IP literal encontrado" || log_pass "Sem IP literal no agente"

#-------------------------------------------------------------------------------
# FASE 6: SEPARACAO DE CAMADAS
#-------------------------------------------------------------------------------
echo ""
echo "FASE 6: SEPARACAO DE CAMADAS (.opencode/ vs .hacker/)"
echo "-------------------------------------------------------------------------------"

test $(find .opencode/agents -name 'web*' 2>/dev/null | wc -l) -eq 0 && log_pass ".opencode/agents/ sem agentes operacionais" || log_fail "Agente operacional em .opencode/agents/"
test $(find .hacker/skills -type d 2>/dev/null | wc -l) -eq 0 && log_pass ".hacker/ sem skills de desenvolvimento" || log_fail ".hacker/skills/ existe (violacao de camada)"
test $(find .hacker/commands -type d 2>/dev/null | wc -l) -eq 0 && log_pass ".hacker/ sem commands de desenvolvimento" || log_fail ".hacker/commands/ existe"
grep -q '.opencode/rules/' .hacker/README.md && log_pass ".hacker/README.md referencia .opencode/rules/" || log_fail "README nao referencia .opencode/rules/"

#-------------------------------------------------------------------------------
# FASE 7: ARQUIVOS DE SCRIPT (.hacker/scripts/)
#-------------------------------------------------------------------------------
echo ""
echo "FASE 7: ARQUIVOS DE SCRIPT (.hacker/scripts/)"
echo "-------------------------------------------------------------------------------"

test -f .hacker/scripts/validar-scan-web.sh && log_pass ".hacker/scripts/validar-scan-web.sh existe" || log_fail "validar-scan-web.sh nao encontrado"
test -f .hacker/scripts/PLANO-TESTE-PRATICO.md && log_pass ".hacker/scripts/PLANO-TESTE-PRATICO.md existe" || log_fail "PLANO-TESTE-PRATICO.md nao encontrado"
bash -n .hacker/scripts/validar-scan-web.sh && log_pass "bash -n validar-scan-web.sh OK" || log_fail "bash -n validar-scan-web.sh FALHOU"
if grep -q '<chave>\|TBD\|TODO' .hacker/scripts/PLANO-TESTE-PRATICO.md; then log_fail "PLANO-TESTE-PRATICO.md contem placeholder"; else log_pass "PLANO-TESTE-PRATICO.md sem placeholder"; fi
if grep -q 'exemplo conceitual\|Exemplo conceitual' .hacker/scripts/PLANO-TESTE-PRATICO.md; then log_fail "PLANO-TESTE-PRATICO.md contem stub conceitual"; else log_pass "PLANO-TESTE-PRATICO.md sem stub conceitual"; fi
if grep -q '—\|–' .hacker/scripts/PLANO-TESTE-PRATICO.md; then log_fail "PLANO-TESTE-PRATICO.md contem travessao"; else log_pass "PLANO-TESTE-PRATICO.md sem travessao"; fi
grep -q 'verificar-vazamento.sh' .hacker/scripts/PLANO-TESTE-PRATICO.md && log_pass "PLANO-TESTE-PRATICO.md referencia verificar-vazamento.sh" || log_fail "PLANO-TESTE-PRATICO.md NAO referencia verificar-vazamento.sh"

#-------------------------------------------------------------------------------
# RESULTADO FINAL
#-------------------------------------------------------------------------------
echo ""
echo "==============================================================================="
echo "  RESULTADO FINAL"
echo "==============================================================================="
echo "  Passou: $PASS | Falhou: $FAIL | Aviso: $WARN"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "  ${GREEN}STATUS: TODOS OS TESTES PASSARAM${NC}"
    echo "  A capability esta como documentacao arquitetural."
    echo "  Para execucao pratica, executar o fluxo com ambiente vulneravel."
else
    echo -e "  ${RED}STATUS: $FAIL FALHA(S) DETECTADA(S)${NC}"
    echo "  Revisar as falhas acima antes de continuar."
fi

echo ""
echo "==============================================================================="
echo "  FIM DA VALIDACAO"
echo "==============================================================================="
