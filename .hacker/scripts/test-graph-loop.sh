#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PYTHON_BIN="${PYTHON_BIN:-python3}"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT
PASS=0

pass() {
  printf '[PASS] %s\n' "$1"
  PASS=$((PASS + 1))
}

expect_fail() {
  if "$@" >/dev/null 2>&1; then
    printf '[FAIL] comando deveria falhar: %s\n' "$*" >&2
    exit 1
  fi
}

cat > "$WORK_DIR/docs.md" <<'EOF'
## REQUEST
Atualizar documento local.
## CATEGORY
Docs
## PROBLEM
Documento precisa de ajuste verificavel.
## CONTEXT
Fontes consultadas: https://example.invalid/documentacao
Fonte interna: .opencode/commands/hacker-sdd-pipeline-auto.md
Risco: a rota poderia ser interpretada incorretamente.
## REQUIREMENTS
Gerar rota deterministica.
## FILES INVOLVED
- .opencode/commands/hacker-sdd-pipeline-auto.md
## RESTRICTIONS
Sem rede e sem area sensivel.
## EXPECTED DELIVERY
Exit code zero.
## WORKERS
analista-local: revisar fixture
EOF

cat > "$WORK_DIR/fake.md" <<'EOF'
Fontes consultadas
https://exemplo.test/arquivo.md
RESTRICTIONS
EOF

cat > "$WORK_DIR/sensitive.md" <<'EOF'
## REQUEST
Alterar script protegido.
## CATEGORY
Feature
## PROBLEM
Teste local de rota sensivel.
## CONTEXT
Fontes consultadas: https://example.invalid/protecao
Fonte interna: .hacker/scripts/gate-p2.sh
Risco: exige confirmacao humana.
## REQUIREMENTS
Classificar a rota reforcada.
## FILES INVOLVED
- ~/opsec/scripts/verificar-vazamento.sh
## RESTRICTIONS
Nao executar rede.
## EXPECTED DELIVERY
Falha sem confirmacao.
EOF

if bash "$REPO_ROOT/.hacker/scripts/gate-p1.sh" "$WORK_DIR/docs.md" >/dev/null; then
  pass "gate P1 aceita spec estruturada"
else
  printf '[FAIL] gate P1 rejeitou spec estruturada\n' >&2
  exit 1
fi
expect_fail bash "$REPO_ROOT/.hacker/scripts/gate-p1.sh" "$WORK_DIR/fake.md"
expect_fail bash "$REPO_ROOT/.hacker/scripts/gate-p2.sh" "$WORK_DIR/fake.md"
expect_fail bash "$REPO_ROOT/.hacker/scripts/gate-p2.sh" "$WORK_DIR/sensitive.md"
pass "gates rejeitam spec ficticia da auditoria"

ROUTE="$($PYTHON_BIN "$REPO_ROOT/.hacker/scripts/graph-loop.py" route --spec "$WORK_DIR/docs.md")"
printf '%s' "$ROUTE" | grep -q '"route": "documentacao"'
pass "routing retorna rota documentacao"

SENSITIVE_ROUTE="$($PYTHON_BIN "$REPO_ROOT/.hacker/scripts/graph-loop.py" route --spec "$WORK_DIR/sensitive.md")"
printf '%s' "$SENSITIVE_ROUTE" | grep -q '"guard": "reforcado"'
pass "routing identifica area sensivel e guarda reforcada"

DELEGATE="$($PYTHON_BIN "$REPO_ROOT/.hacker/scripts/graph-loop.py" delegate --spec "$WORK_DIR/docs.md")"
printf '%s' "$DELEGATE" | grep -q '"analista-local"'
pass "delegacao deriva worker a partir da entrada"

$PYTHON_BIN "$REPO_ROOT/.hacker/scripts/graph-loop.py" delegate --spec "$WORK_DIR/docs.md" \
  --execute --job "analista-local=/bin/true" > "$WORK_DIR/delegate-executed.json"
grep -q '"executed"' "$WORK_DIR/delegate-executed.json"
pass "delegacao executa worker explicitamente autorizado"

$PYTHON_BIN "$REPO_ROOT/.hacker/scripts/graph-loop.py" parallel \
  --job "primeiro=$PYTHON_BIN -c 'print(1)'" \
  --job "segundo=$PYTHON_BIN -c 'print(2)'" > "$WORK_DIR/parallel.json"
grep -q '"primeiro"' "$WORK_DIR/parallel.json"
grep -q '"segundo"' "$WORK_DIR/parallel.json"
pass "executor paralelo aguarda jobs independentes"

$PYTHON_BIN "$REPO_ROOT/.hacker/scripts/graph-loop.py" loop \
  --evaluator "$PYTHON_BIN -c 'import sys; sys.exit(0)'" \
  --ledger "$WORK_DIR/loop-ledger.txt" > "$WORK_DIR/loop-ok.txt"
grep -q 'loop-ciclo=1' "$WORK_DIR/loop-ok.txt"
grep -q 'loop-ciclo=1' "$WORK_DIR/loop-ledger.txt"
FEEDBACK_FILE="$WORK_DIR/feedback.json"
GENERATOR_FEEDBACK="$WORK_DIR/generator-feedback"
export GENERATOR_FEEDBACK
$PYTHON_BIN "$REPO_ROOT/.hacker/scripts/graph-loop.py" loop \
  --evaluator "$PYTHON_BIN -c 'import sys; print(\"SCORE=1\"); sys.exit(1)'" \
  --generator "$PYTHON_BIN -c 'import os, pathlib; pathlib.Path(os.environ[\"GENERATOR_FEEDBACK\"]).write_text(os.environ[\"EVALUATOR_SCORE\"])'" \
  --feedback-file "$FEEDBACK_FILE" --max-cycles 1 >/dev/null || true
grep -q '"score": 1.0' "$FEEDBACK_FILE"
grep -q '^1.0$' "$GENERATOR_FEEDBACK"
if $PYTHON_BIN "$REPO_ROOT/.hacker/scripts/graph-loop.py" loop \
  --evaluator "$PYTHON_BIN -c 'import sys; sys.exit(1)'" \
  --max-cycles 2 --max-stagnant 1 > "$WORK_DIR/loop-fail.txt"; then
  printf '[FAIL] loop deveria parar com falha\n' >&2
  exit 1
fi
grep -q 'loop-parado=sem-melhoria' "$WORK_DIR/loop-fail.txt"
pass "loop registra ciclos e para sem melhoria"

# --- Testes para operacoes de hacking (ISSUE-013 TASK 10) ---

cat > "$WORK_DIR/hacking-pentest.md" <<'EOF'
## REQUEST
Pentest autorizado em alvo web em lab HTB.
## CATEGORY
Feature
## PROBLEM
Explorar vulnerabilidades em aplicacao web autorizada.
## CONTEXT
Fontes consultadas: https://cheatsheetseries.owasp.org/
Fonte interna: .hacker/agentes/pentest/AGENTE.md
Escopo: lab autorizado HTB
## REQUIREMENTS
Reconhecimento, exploracao, relatorio
## FILES INVOLVED
- .hacker/agentes/pentest/AGENTE.md
- .hacker/agentes/web-scanner/AGENTE.md
## RESTRICTIONS
Sem rede fora do escopo autorizado.
## EXPECTED DELIVERY
Relatorio de pentest com findings validados.
## WORKERS
red-team: reconhecimento ativo
pentest: exploracao e exploit
web-scanner: scan automatizado
EOF

HACKING_ROUTE="$($PYTHON_BIN "$REPO_ROOT/.hacker/scripts/graph-loop.py" route --spec "$WORK_DIR/hacking-pentest.md")"
printf '%s' "$HACKING_ROUTE" | grep -q '"route": "padrao"'
pass "routing com CATEGORY=Feature retorna padrao"
printf '%s' "$HACKING_ROUTE" | grep -q '"guard": "nenhum"'
pass "routing com CATEGORY=Feature sem arquivos sensiveis retorna guard nenhum"

HACKING_DELEGATE="$($PYTHON_BIN "$REPO_ROOT/.hacker/scripts/graph-loop.py" delegate --spec "$WORK_DIR/hacking-pentest.md")"
printf '%s' "$HACKING_DELEGATE" | grep -q '"red-team"'
pass "delegacao com WORKERS de hacking inclui red-team"
printf '%s' "$HACKING_DELEGATE" | grep -q '"pentest"'
pass "delegacao com WORKERS de hacking inclui pentest"
printf '%s' "$HACKING_DELEGATE" | grep -q '"web-scanner"'
pass "delegacao com WORKERS de hacking inclui web-scanner"

$PYTHON_BIN "$REPO_ROOT/.hacker/scripts/graph-loop.py" parallel \
  --job "nmap_scan=$PYTHON_BIN -c 'print(\"nmap_result\")'" \
  --job "nuclei_scan=$PYTHON_BIN -c 'print(\"nuclei_result\")'" \
  --job "curl_probe=$PYTHON_BIN -c 'print(\"curl_result\")'" > "$WORK_DIR/hacking-parallel.json"
grep -q '"nmap_scan"' "$WORK_DIR/hacking-parallel.json"
grep -q '"nuclei_scan"' "$WORK_DIR/hacking-parallel.json"
grep -q '"curl_probe"' "$WORK_DIR/hacking-parallel.json"
pass "paralelismo de varreduras de hacking executa tres jobs independentes"

$PYTHON_BIN "$REPO_ROOT/.hacker/scripts/graph-loop.py" loop \
  --evaluator "$PYTHON_BIN -c 'import sys; print(\"SCORE=1\"); sys.exit(0)'" \
  --generator "$PYTHON_BIN -c 'import os,pathlib; pathlib.Path(os.environ[\"GENERATOR_FEEDBACK\"]).write_text(os.environ[\"EVALUATOR_SCORE\"])'" \
  --feedback-file "$WORK_DIR/hacking-feedback.json" \
  --max-cycles 1 --max-stagnant 1 > "$WORK_DIR/hacking-loop.txt"
grep -q 'loop-ciclo=1' "$WORK_DIR/hacking-loop.txt"
grep -q '"score": 1.0' "$WORK_DIR/hacking-feedback.json"
pass "loop evaluator-optimizer para validacao de findings funciona com operacoes de hacking"

printf 'RESULTADO: %s testes PASS\n' "$PASS"
