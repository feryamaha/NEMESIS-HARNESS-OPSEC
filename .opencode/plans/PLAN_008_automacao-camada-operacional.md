# Automacao da camada operacional - Plano de Implementacao

> **Para agentes**: Use hacker-subagent-driven-development para executar este plano.

**Objetivo**: Criar um runner/CLI em `.hacker/scripts/runner.sh` que orquestra o fluxo Gate → Operacao → Relatorio → Ledger com exit codes, validando pre-condicoes antes de registrar operacoes.

**Spec**: `.opencode/specs/SPEC_008_automacao-camada-operacional.md`

**Arquivos Afetados**:
- CREATE: `.hacker/scripts/runner.sh`
- MODIFY: `.hacker/README.md`
- MODIFY: `.hacker/gate/GATE-DE-PROTECAO.md`

**Arquitetura**: O runner e um script bash que verifica pre-condicoes (gate GOOD, escopo nao vazio no ledger, hash do ledger consistente) e retorna exit codes. Nao substitui o enforcement fisico da ISSUE-001; complementa-o. Nao quebra o fluxo atual; e aditivo.

**Stack**: bash (scripts), markdown (docs)

---

## TASK 1: Criar .hacker/scripts/runner.sh

**Arquivo**: `.hacker/scripts/runner.sh` (CREATE)

**Arquivos**:
- CREATE: `.hacker/scripts/runner.sh`
- TEST: behavioral (mock gate LEAK e GOOD)

**Depende de**: nenhuma

**Verificacao**:
```bash
bash -n .hacker/scripts/runner.sh && echo "PASS: sintaxe OK"
grep -rn "—\|–" .hacker/scripts/runner.sh || echo "PASS: zero em-dash"
grep -rniE "\b(eu|meu|minha|meus|minhas)\b" .hacker/scripts/runner.sh || echo "PASS: zero primeira pessoa"
```

**Descricao Detalhada**:
O runner.sh e o script principal que valida o ciclo operacional antes de qualquer gravacao no ledger. Implementa tres etapas de verificacao com exit codes:

1. **Etapa 1 — Gate GOOD (detecção precisa)**: Executa `bash ~/opsec/scripts/verificar-vazamento.sh`, captura toda a saida, localiza a linha **após o marcador `[5] RESULTADO FINAL`**, e verifica se essa linha contém `[GOOD]`. O grep generico `grep -q "GOOD"` NAO e usado porque o verificar-vazamento.sh imprime `[GOOD]` e `[LEAK]` em linhas individuais de cada teste; somente a linha após `[5] RESULTADO FINAL` contem o veredito final. Se a linha após o marcador contiver `[LEAK]` ou o marcador nao for encontrado, exit 1.
2. **Etapa 2 | Escopo nao vazio (leitura do ledger)**: Lê a **ultima linha** de `.hacker/ledger/operacoes.md`, extrai o campo ESCOPO (5º campo separado por `|`), e verifica que nao esta vazio e nao e `N/A`. NAO verifica o TEMPLATE-OPERACAO.md estatico | o campo ESCOPO la e apenas o nome do campo, nao um valor preenchido.
3. **Etapa 3 | Hash do ledger (append-only verificado)**: Extrai os campos DATA a BASE da ultima linha de operacoes.md, constroi o payload canonico `DATA|OP-ID|AGENTE|ESCOPO|GATE|REF-AUT|VETOR|RESULTADO|BASE`, calcula `sha256` do payload e compara com o HASH gravado na mesma linha (campo 11). Se o hash recalculado nao bater com o HASH gravado, exit 1 (indica modificacao ou corrucao do ledger).
4. Se todas as validacoes passam, exit 0 ("ciclo valido").
5. Nao executa operacoes de rede diretamente; somente verifica pre-condicoes.
6. Referencia cruzada para ISSUE-001 (SPEC_004) na secao de comentarios: o enforcement fisico (x-bit via gate-enforcement.sh) e responsabilidade da ISSUE-001, nao deste runner.

O script usa `set -euo pipefail`, nao executa git de escrita, nao toca arquivos fora de `.hacker/`. Nao e area sensivel (classe B, sem gating de rede).

**Implementacao**:
```bash
#!/bin/bash
#===============================================================================
# runner.sh | Runner/CLI de automacao da camada operacional
#             Gate → Operacao → Relatorio → Ledger
#===============================================================================
#
# Referencia cruzada: ISSUE-001 (SPEC_004) para enforcement fisico
# (gate-enforcement.sh, x-bit). Este runner valida pre-condicoes
# comportamentais (gate GOOD, escopo no ledger, hash do ledger).
#
# Exit codes:
#   0 = ciclo valido, todas as verificacoes passaram
#   1 = ciclo invalido, alguma verificacao falhou
#
# Nao executa operacoes de rede diretamente. Complementa o enforcement
# fisico da ISSUE-001 sem duplica-lo.
#===============================================================================

set -euo pipefail

GATE_SCRIPT="${GATE_SCRIPT:-$HOME/opsec/scripts/verificar-vazamento.sh}"
LEDGER_FILE=".hacker/ledger/operacoes.md"

echo "[runner] Iniciando verificacao do ciclo operacional..."

# Etapa 1: Verificar gate GOOD (deteccao precisa via marcador)
echo "[runner] Etapa 1: verificando gate..."
if [ ! -x "$GATE_SCRIPT" ]; then
    echo "[runner] ERRO: Script de gate nao encontrado: $GATE_SCRIPT"
    exit 1
fi
GATE_OUTPUT=$(bash "$GATE_SCRIPT" 2>&1 || true)
FINAL_LINE=$(echo "$GATE_OUTPUT" | awk '/\[5\] RESULTADO FINAL/{getline; print; exit}')
if echo "$FINAL_LINE" | grep -q "\[GOOD\]"; then
    echo "[runner] Gate: GOOD | proseguindo."
else
    echo "[runner] ERRO: Gate NAO GOOD. Ciclo invalido. Operacao recusada."
    exit 1
fi

# Etapa 2: Verificar escopo nao vazio (leitura do ultimo registro do ledger)
echo "[runner] Etapa 2: verificando escopo no ledger..."
if [ ! -f "$LEDGER_FILE" ]; then
    echo "[runner] ERRO: Arquivo de ledger nao encontrado: $LEDGER_FILE"
    exit 1
fi
ULTIMA_LINHA=$(tail -1 "$LEDGER_FILE")
ESCOPO=$(echo "$ULTIMA_LINHA" | cut -d'|' -f5 | xargs)
if [ -z "$ESCOPO" ] || [ "$ESCOPO" = "N/A" ]; then
    echo "[runner] ERRO: Campo ESCOPO vazio ou N/A na ultima linha do ledger."
    exit 1
fi
echo "[runner] Escopo: $ESCOPO."

# Etapa 3: Verificar integridade do ledger (hash da ultima entrada)
echo "[runner] Etapa 3: verificando integridade do ledger..."
DATA=$(echo "$ULTIMA_LINHA" | cut -d'|' -f2 | xargs)
OP_ID=$(echo "$ULTIMA_LINHA" | cut -d'|' -f3 | xargs)
AGENTE=$(echo "$ULTIMA_LINHA" | cut -d'|' -f4 | xargs)
GATE_VAL=$(echo "$ULTIMA_LINHA" | cut -d'|' -f6 | xargs)
REF_AUT=$(echo "$ULTIMA_LINHA" | cut -d'|' -f7 | xargs)
VETOR=$(echo "$ULTIMA_LINHA" | cut -d'|' -f8 | xargs)
RESULTADO=$(echo "$ULTIMA_LINHA" | cut -d'|' -f9 | xargs)
BASE=$(echo "$ULTIMA_LINHA" | cut -d'|' -f10 | xargs)
EXPECTED_HASH=$(echo "$ULTIMA_LINHA" | cut -d'|' -f11 | xargs)
PAYLOAD="$DATA|$OP_ID|$AGENTE|$ESCOPO|$GATE_VAL|$REF_AUT|$VETOR|$RESULTADO|$BASE"
COMPUTED_HASH=$(printf '%s' "$PAYLOAD" | sha256sum | cut -c1-16)
if [ "$COMPUTED_HASH" != "$EXPECTED_HASH" ]; then
    echo "[runner] ERRO: Hash do ledger invalido."
    echo "[runner] Esperado: $EXPECTED_HASH"
    echo "[runner] Computado: $COMPUTED_HASH"
    exit 1
fi
echo "[runner] Ledger: hash validado ($COMPUTED_HASH)."

echo "[runner] Todas as verificacoes passaram. Ciclo valido."
echo "[runner] Exit code: 0"
exit 0
```

---

## TASK 2: Atualizar .hacker/README.md

**Arquivo**: `.hacker/README.md` (MODIFY, linhas 29-36)

**Arquivos**:
- MODIFY: `.hacker/README.md` (linha 29-36, secao "Como orquestrar")
- TEST: n/a

**Depende de**: TASK 1 (para referencia ao runner.sh)

**Verificacao**:
```bash
grep -n "runner\|Runner" .hacker/README.md && echo "PASS: referencia ao runner presente"
grep -rn "—\|–" .hacker/README.md || echo "PASS: zero em-dash"
grep -rniE "\b(eu|meu|minha|meus|minhas)\b" .hacker/README.md || echo "PASS: zero primeira pessoa"
```

**Descricao Detalhada**:
Adicionar a secao sobre o runner/CLI na seção "Como orquestrar" do README. O runner e o script `.hacker/scripts/runner.sh` que valida pre-condicoes do ciclo (gate GOOD via marcador [5] RESULTADO FINAL, escopo no ledger, hash do ledger). Referencia cruzada para ISSUE-001 (enforcement fisico).

Adicionar uma linha apos a linha 36 (apos "Consolida relatorios e grava tudo no ledger..."):
```
7. O runner (`.hacker/scripts/runner.sh`) valida o ciclo antes do fechamento: gate GOOD (via marcador [5] RESULTADO FINAL), escopo no ledger, hash do ledger. Referencia cruzada para ISSUE-001 (enforcement fisico via gate-enforcement.sh).
```

**Implementacao**:
Usar `sed` ou `printf` para inserir a linha apos a linha 36. A linha nao contem em-dash, nao contem IP real, nao contem primeira pessoa.

---

## TASK 3: Atualizar .hacker/gate/GATE-DE-PROTECAO.md

**Arquivo**: `.hacker/gate/GATE-DE-PROTECAO.md` (MODIFY, linha 113)

**Arquivos**:
- MODIFY: `.hacker/gate/GATE-DE-PROTECAO.md` (linha 113, secao "Integracao com orquestrador")
- TEST: n/a

**Depende de**: TASK 1 (para referencia ao runner.sh)

**Verificacao**:
```bash
grep -n "runner" .hacker/gate/GATE-DE-PROTECAO.md && echo "PASS: referencia ao runner presente"
grep -rn "—\|–" .hacker/gate/GATE-DE-PROTECAO.md || echo "PASS: zero em-dash"
grep -rniE "\b(eu|meu|minha|meus|minhas)\b" .hacker/gate/GATE-DE-PROTECAO.md || echo "PASS: zero primeira pessoa"
```

**Descricao Detalhada**:
Adicionar uma nota na secao "Integracao com orquestrador" (apos a linha 113) sobre o runner. O runner valida o gate comportamental (verificar-vazamento.sh GOOD via marcador [5] RESULTADO FINAL) antes de registrar no ledger; o enforcement fisico (x-bit) permanece na ISSUE-001 (gate-enforcement.sh).

Adicionar apos a linha 113:
```
O runner (`.hacker/scripts/runner.sh`) valida o gate comportamental antes do fechamento do ciclo. O enforcement fisico (x-bit) e responsabilidade da ISSUE-001.
```

**Implementacao**:
Usar `printf` ou `echo` para append na linha 113. O texto nao contem em-dash, nao contem IP real, nao contem primeira pessoa.

---

## TASK 4: Teste comportamental do runner (verificacao SUNSET F7)

**Arquivo**: `.hacker/scripts/runner.sh` (TEST com mock)

**Arquivos**:
- TEST: `.hacker/scripts/runner.sh` (via scripts mock temporarios em /tmp)
- VERIFICATION: documentada na secao VERIFICATION da spec

**Depende de**: TASK 1 (para o runner existir)

**Verificacao**:
```bash
# Teste LEAK simulado (exit 1):
cat > /tmp/mock-verificar-leak.sh << 'MOCK'
#!/bin/bash
echo "[5] RESULTADO FINAL"
echo "[LEAK] Cadeia nao ativa"
MOCK
chmod +x /tmp/mock-verificar-leak.sh
GATE_SCRIPT=/tmp/mock-verificar-leak.sh bash .hacker/scripts/runner.sh; echo "exit: $?"
# Deve ser exit 1 (ciclo invalido, gate LEAK)

# Teste GOOD simulado (exit 0):
cat > /tmp/mock-verificar-good.sh << 'MOCK'
#!/bin/bash
echo "[5] RESULTADO FINAL"
echo "[GOOD] Cadeia ativa"
MOCK
chmod +x /tmp/mock-verificar-good.sh
GATE_SCRIPT=/tmp/mock-verificar-good.sh bash .hacker/scripts/runner.sh; echo "exit: $?"
# Deve ser exit 0 (ciclo valido, gate GOOD)
```

**Descricao Detalhada**:
Teste comportamental obrigatorio (SUNSET F7). Criar scripts mock que simulam a saida do verificar-vazamento.sh com o marcador `[5] RESULTADO FINAL` seguido de `[LEAK]` ou `[GOOD]`. Rodar o runner com GATE_SCRIPT apontando para o mock. Confirmar exit 1 para LEAK e exit 0 para GOOD. Esse teste garante que a deteccao de gate funciona corretamente (Etapa 1) e que o fluxo de exit codes esta funcional.

**Implementacao**:
Executar os comandos acima. O mock e criado em /tmp (temporario, nao persiste no repo). O GATE_SCRIPT e sobrescrito via variavel de ambiente para apontar para o mock.

---

## CHECKLIST AUTO-REVIEW (Step 7)

- [x] Todos os paths sao exatos e confirmados no disco? (runner.sh nao existe ainda, README.md e GATE-DE-PROTECAO.md confirmados)
- [x] Codigo completo em cada tarefa? (runner.sh tem codigo completo com marcador [5] RESULTADO FINAL, SHA256 hash verification, escopo via operacoes.md)
- [x] Cada tarefa tem o comando de verificacao do perfil? (bash -n, grep estilo)
- [x] Ordem faz sentido? (TASK 1 cria o runner, TASK 2 e 3 referenciam, TASK 4 testa)
- [x] Toda tarefa declara DEPENDE_DE (real)? (TASK 2, 3 e 4 dependem de TASK 1)
- [x] Nenhuma tarefa executa git write operations? (confirmado)
- [x] Verificacao final inclui bash -n e grep estilo? (sim)
- [x] Pre-flight de postura: verificar-vazamento.sh GOOD? (NAO necessario | sem rede, classe B)
- [x] Teste comportamental incluido? (TASK 4 com mock LEAK e GOOD)
- [x] Deteccao de gate via [5] RESULTADO FINAL? (sim, Etapa 1 corrigida)
- [x] Escopo verificado via ultima linha de operacoes.md? (sim, Etapa 2 corrigida)
- [x] Hash verificado via sha256 do payload DATA..BASE? (sim, Etapa 3 corrigida)
- [x] Sem em-dash no texto novo? (sim, verificado)

## VERIFICATION (apos execucao de todas as tasks)

```bash
# 1. Sintaxe bash:
bash -n .hacker/scripts/runner.sh && echo "PASS: sintaxe OK"

# 2. Deteccao precisa de gate (teste LEAK simulado):
cat > /tmp/mock-verificar-leak.sh << 'MOCK'
#!/bin/bash
echo "[5] RESULTADO FINAL"
echo "[LEAK] Cadeia nao ativa"
MOCK
chmod +x /tmp/mock-verificar-leak.sh
GATE_SCRIPT=/tmp/mock-verificar-leak.sh bash .hacker/scripts/runner.sh; echo "exit: $?"
# Deve ser exit 1 (ciclo invalido, gate LEAK)

# 3. Deteccao precisa de gate (teste GOOD simulado):
cat > /tmp/mock-verificar-good.sh << 'MOCK'
#!/bin/bash
echo "[5] RESULTADO FINAL"
echo "[GOOD] Cadeia ativa"
MOCK
chmod +x /tmp/mock-verificar-good.sh
GATE_SCRIPT=/tmp/mock-verificar-good.sh bash .hacker/scripts/runner.sh; echo "exit: $?"
# Deve ser exit 0 (ciclo valido, gate GOOD)

# 4. Extrair payload da entrada nova do ledger (linha 21) e reconferir HASH (SUNSET F7):
printf '%s' "2026-09-13|OP-20260913-001|orquestrador|dev|N/A|N/A|Adocao do novo formato de ledger com hash da transacao e autorizacao verificavel|Novo formato implementado e validado|PLAN_007_ledger-hash-transacao-e-autorizacao.md" | sha256sum | cut -c1-16
# Deve ser: 73e8cf1650cea82f

# 5. Conferir append-only preservado:
grep -n "OP-20260911-008" .hacker/ledger/operacoes.md  # linha 20 intacta

# 6. Grep de estilo no texto novo (traco en/em dash e primeira pessoa):
grep -rn "—\|–" .hacker/scripts/runner.sh .hacker/README.md .hacker/gate/GATE-DE-PROTECAO.md
grep -rniE "\b(eu|meu|minha|meus|minhas)\b" .hacker/scripts/runner.sh .hacker/README.md .hacker/gate/GATE-DE-PROTECAO.md

# 7. Referencia cruzada ISSUE-001:
grep -n "ISSUE-001\|SPEC_004\|gate-enforcement" .hacker/scripts/runner.sh .hacker/README.md .hacker/gate/GATE-DE-PROTECAO.md
```

## CORRECOES DO P2 REVISOR (2026-09-14)

Estas correcoes foram aplicadas ao plano original a pedido do revisor independente:

1. **Etapa 1 — Deteccao de GOOD corrigida**: Substituido `grep -q "GOOD"` (genérico, casa com qualquer linha) por verificacao via marcador `[5] RESULTADO FINAL` com `awk '/\[5\] RESULTADO FINAL/{getline; print; exit}'`. O veredito final do verificar-vazamento.sh esta na linha apos esse marcador, nao em nenhuma ocorrencia espalhada.
2. **Etapa 2 | Escopo corrigido**: Substituido a verificacao de TEMPLATE-OPERACAO.md (que sempre retorna verdadeiro porque ESCOPO e o nome do campo) pela leitura da ultima linha de operacoes.md para verificar que o campo ESCOPO nao esta vazio.
3. **Etapa 3 | Hash implementado de verdade**: Substituido a verificacao de formato de tabela e contagem de linhas pela recomputacao do sha256 do payload canonico (campos DATA a BASE separados por |) e comparacao com o HASH gravado na ultima linha. Se nao bater, exit 1.
4. **Teste comportamental adicionado**: TASK 4 com mock de gate LEAK e GOOD para confirmar exit codes corretos (documentado na secao VERIFICATION).
