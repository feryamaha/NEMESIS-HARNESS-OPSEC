# Implementacao dos Padrões Graph + Loop da Anthropic - Plano de Implementacao

> **Para agentes**: Use hacker-subagent-driven-development para executar este plano.

**Objetivo**: Implementar os padrones Graph e Loop da Anthropic ("Building Effective Agents", Dez 2024) no projeto hacker-etico-ambiente, completando o padrao 5 (Evaluator-optimizer) e elevando os 4 existentes ao nivel recomendado.

**Spec**: `.opencode/specs/SPEC_015_antropic-graph-loop-patterns.md`

**Arquivos Afetados**: `.opencode/skills/hacker-tests/SKILL.md`, `.opencode/commands/hacker-sdd-pipeline-auto.md`, `.opencode/skills/hacker-specification-design/SKILL.md`, `.opencode/agents/orquestrador.md`, `.hacker/orquestrador/ORQUESTRADOR.md`, `.hacker/agentes/orquestrador-pipeline/PIPELINE-COMPLETO.md`, `.hacker/scripts/gate-preflight.sh`, `.hacker/scripts/gate-p1.sh`, `.hacker/scripts/gate-p2.sh`, `.hacker/gate/GATE-DE-PROTECAO.md`, `AGENTS.md`, `.opencode/rules/hacker-epistemic-safety.md`, `.opencode/rules/hacker-fable-method.md`

**Arquitetura**: 5 itens de implementacao executados em ondas de paralelismo. Item 1 (Loop) e Item 5 (Gates) sao os mais criticos e independentes. Item 2 (Routing), Item 3 (Parallelization) e Item 4 (Delegacao) modificam arquivos de orquestracao e podem rodar em paralelo entre si. Atualizacoes de documentacao sao a ultima onda.

**Stack**: bash (gate scripts), markdown (skills, commands, agents, docs)

---

## Ondas de Execucao

### ONDA 1: Gates Programáticos + Evaluator-Optimizer + Delegação Dinâmica (PARALELO)

Tarefas sem dependencia entre si, com arquivos disjuntos.

## TASK 1: Criar gate-preflight.sh

**Arquivo**: `.hacker/scripts/gate-preflight.sh` (CREATE)

**Arquivos**:
- CREATE: `.hacker/scripts/gate-preflight.sh`
- TEST: nao se aplica

**Depende de**: nenhuma

**Verificacao**:
```bash
bash -n .hacker/scripts/gate-preflight.sh && echo "PASS: sintaxe ok"
```

**Descricao Detalhada**:
Script gate programavel que executa verificar-vazamento.sh, verifica wg0 ativo, verifica torproxy-host rodando. Retorna codigo de saida: 0=PASS, 1=FAIL, 2=BLOQUEADO. Sem dependencia de docker, usa `ss -tlnp | grep 9050` para verificar Tor e `ip -o link show wg0` para WireGuard. Inclui funcao `main()` com log informativo.

**Implementacao**:
```bash
#!/usr/bin/env bash
set -uo pipefail

# gate-preflight.sh — Gate programavel de pre-flight
# Retorna: 0=PASS, 1=FAIL, 2=BLOQUEADO

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
```

---

## TASK 2: Criar gate-p1.sh

**Arquivo**: `.hacker/scripts/gate-p1.sh` (CREATE)

**Arquivos**:
- CREATE: `.hacker/scripts/gate-p1.sh`

**Depende de**: nenhuma

**Verificacao**:
```bash
bash -n .hacker/scripts/gate-p1.sh && echo "PASS: sintaxe ok"
```

**Descricao Detalhada**:
Script gate que valida se a critical-analysis foi executada e se fontes F6 foram consultadas. Verifica que a spec possui secao "Fontes consultadas" com pelo menos uma fonte externa (URL) e uma fonte interna (path do arquivo). Retorna 0=PASS, 1=FAIL.

**Implementacao**:
```bash
#!/usr/bin/env bash
set -uo pipefail

# gate-p1.sh — Gate de analise critica (P1)
# Retorna: 0=PASS, 1=FAIL

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

# Verificar se possui pelo menos uma fonte interna (path)
if ! grep -qE "\.(md|sh|yml|yaml)\" "$SPEC_FILE" && ! grep -qE "\`" "$SPEC_FILE"; then
  echo "[FAIL] Spec nao possui fonte interna (path do arquivo) consultada"
  exit 1
fi

echo "[PASS] Gate P1: critical-analysis validada, fontes F6 consultadas"
exit 0
```

---

## TASK 3: Criar gate-p2.sh

**Arquivo**: `.hacker/scripts/gate-p2.sh` (CREATE)

**Arquivos**:
- CREATE: `.hacker/scripts/gate-p2.sh`

**Depende de**: nenhuma

**Verificacao**:
```bash
bash -n .hacker/scripts/gate-p2.sh && echo "PASS: sintaxe ok"
```

**Descricao Detalhada**:
Script gate que valida se a rule-control foi executado e se a spec nao toca areas sensiveis sem confirmacao. Verifica que a spec possui seção RESTRICTIONS e que nenhuma alteracao em `~/opsec/scripts/` ou `docker-compose.yml` foi feita sem flag classe C. Retorna 0=PASS, 1=FAIL.

**Implementacao**:
```bash
#!/usr/bin/env bash
set -uo pipefail

# gate-p2.sh — Gate de regras (P2)
# Retorna: 0=PASS, 1=FAIL

echo "=== GATE-P2 (Rule Control) ==="

SPEC_FILE="${1:-}"
if [ -z "$SPEC_FILE" ]; then
  echo "[FAIL] Nenhuma spec fornecida"
  exit 1
fi

if [ ! -f "$SPEC_FILE" ]; then
  echo "[FAIL] Spec nao encontrada: $SPEC_FILE"
  exit 1
fi

# Verificar se a spec possui secao RESTRICTIONS
if ! grep -q "RESTRICTIONS" "$SPEC_FILE"; then
  echo "[FAIL] Spec nao possui secao RESTRICTIONS"
  exit 1
fi

# Verificar se nao ha alteracoes em ~/opsec/scripts/ sem flag classe C
if grep -qE "~/.opsec/scripts/.*(MODIFY|MODIFICAR)" "$SPEC_FILE" 2>/dev/null; then
  if ! grep -qE "classe C|confirmacao do Fernando" "$SPEC_FILE"; then
    echo "[FAIL] Spec toca ~/opsec/scripts/ sem confirmacao classe C"
    exit 1
  fi
fi

echo "[PASS] Gate P2: rule-control validado, areas sensiveis protegidas"
exit 0
```

---

## TASK 4: Modificar hacker-tests/SKILL.md — Loop Evaluator-Optimizer

**Arquivo**: `.opencode/skills/hacker-tests/SKILL.md` (MODIFY)

**Arquivos**:
- MODIFY: `.opencode/skills/hacker-tests/SKILL.md`

**Depende de**: nenhuma

**Verificacao**:
```bash
bash -n .opencode/skills/hacker-tests/SKILL.md 2>/dev/null; echo "exit: $?"
grep -n "pass \"" .opencode/skills/hacker-tests/SKILL.md || echo "PASS: zero chamadas pass() minusculas"
```

**Descricao Detalhada**:
Substituir o fix-loop atual (max 2 tentativas arbitrario) por um loop evaluator-optimizer:
- Generator: subagent implementador gera o fix
- Evaluator: hacker-tests executa a bateria completa (bash -n, shellcheck, py_compile, docker compose config, git diff --check, verificar-vazamento.sh)
- Loop: se FAIL → re-torna ao generator com o output do evaluator → generator ajusta → evaluator re-testa
- Critério de parada: GOOD do verificar-vazamento.sh E todos os testes PASS, OU 5 ciclos sem melhoria mensuravel (convergência)
- Cada iteração gera entrada no Trust Ledger (evento `loop-ciclo=N | resultado=...`)
- Ações de classe C (F4): independentemente do loop, sempre param e pedem Fernando

Adicionar seção "Limites do Loop":
- Loop itera maximo 5 ciclos
- Loop para na PARADA UNICA
- Ações de classe C sempre param para Fernando
- Se a cadeia muda de GOOD para LEAK durante o Loop → HARNESS GUARDIAN pausa tudo
- Loop nao faz commit de git, nao abre PR, nao decide escopo

---

## TASK 5: Modificar orquestrador.md — Delegação Dinâmica

**Arquivo**: `.opencode/agents/orquestrador.md` (MODIFY)

**Arquivos**:
- MODIFY: `.opencode/agents/orquestrador.md`

**Depende de**: nenhuma

**Verificacao**:
```bash
bash -n .opencode/agents/orquestrador.md 2>/dev/null; echo "exit: $?"
```

**Descricao Detalhada**:
Adicionar lógica de delegação dinâmica ao orquestrador:
- O orquestrador lê o input do usuário
- Dinamicamente determina quais subagentes são necessários baseado no tipo de task:
  - Se spec requer rede → despacha implementador + revisor + pre-flight checker
  - Se spec é apenas docs → despacha apenas documentador
  - Se spec é complexa (múltiplos arquivos, múltiplas skills) → despacha múltiplos workers em paralelo
- Sintetiza os resultados de todos os workers no relatório consolidado
- Delegação baseada no input, não no plano pré-definido
- Adicionar seção "Limites de Autoridade": orquestrador delega, mas não decide escopo; não autoriza ações de classe C

---

### ONDA 2: Routing + Parallelization (PARALELO entre si, dependem da ONDA 1 para consistência)

## TASK 6: Modificar hacker-sdd-pipeline-auto.md — Routing + Gates Programáticos

**Arquivo**: `.opencode/commands/hacker-sdd-pipeline-auto.md` (MODIFY)

**Arquivos**:
- MODIFY: `.opencode/commands/hacker-sdd-pipeline-auto.md`

**Depende de**: TASK 1, TASK 2, TASK 3 (gate scripts criados)

**Verificacao**:
```bash
bash -n .opencode/commands/hacker-sdd-pipeline-auto.md 2>/dev/null; echo "exit: $?"
```

**Descricao Detalhada**:
1. Adicionar tabela de routing condicional:
   - spec CATEGORY = "Infra" E arquivos incluem ~/opsec/scripts/ → gate reforçado + pre-flight
   - spec CATEGORY = "Docs" → route direto para documentador
   - spec CATEGORY = "Bugfix" → gate padrão + pre-flight F1
   - spec CATEGORY = "Feature" E toca cadeia → orquestrador + gate reforçado
   - spec CATEGORY = "Feature" nao toca cadeia → route padrão
2. Substituir verificações textuais de gate por chamadas executáveis aos scripts gate-*.sh
3. Cada gate retorna codigo de saída: 0=PASS, 1=FAIL, 2=BLOQUEADO
4. Adicionar diagrama de controle mostrando: Fernando → Gates → Loop/Graph → PARADA UNICA → Fernando

---

## TASK 7: Modificar hacker-specification-design/SKILL.md — Routing Condicional

**Arquivo**: `.opencode/skills/hacker-specification-design/SKILL.md` (MODIFY)

**Arquivos**:
- MODIFY: `.opencode/skills/hacker-specification-design/SKILL.md`

**Depende de**: TASK 6 (tabela de routing definida no pipeline)

**Verificacao**:
```bash
bash -n .opencode/skills/hacker-specification-design/SKILL.md 2>/dev/null; echo "exit: $?"
```

**Descricao Detalhada**:
Adicionar routing condicional por categoria de spec ao processo da skill:
- Na Step 2, antes de gerar a especificacao, determinar a rota baseada na CATEGORY
- Cada categoria tem comportamento diferente (gate reforçado, docs direto, etc.)
- Routing é executável (baseado em categoria da spec, não textual)

---

## TASK 8: Modificar ORQUESTRADOR.md — Parallelization

**Arquivo**: `.hacker/orquestrador/ORQUESTRADOR.md` (MODIFY)

**Arquivos**:
- MODIFY: `.hacker/orquestrador/ORQUESTRADOR.md`

**Depende de**: nenhuma (independente)

**Verificacao**:
```bash
bash -n .hacker/orquestrador/ORQUESTRADOR.md 2>/dev/null; echo "exit: $?"
```

**Descricao Detalhada**:
1. Modificar o "Fluxo em grafo" para incluir paralelismo:
   - Scraping e reconhecimento de rede executam em paralelo
   - Merge point definido para web-scanner
   - Etapas dependentes (pentest → reconfirmação) permanecem sequenciais
   - Etapa 5 (blue-team) inicia quando ambas as entradas estão prontas
2. Adicionar seção "Limites de Autoridade":
   - O orquestrador delega, mas não decide escopo
   - O Loop itera, mas não autoriza ações de classe C
   - O Routing direciona, mas não altera o escopo definido pelo Fernando
   - O HARNESS GUARDIAN pode parar tudo se a cadeia quebrar

---

## TASK 9: Modificar PIPELINE-COMPLETO.md — Parallelization

**Arquivo**: `.hacker/agentes/orquestrador-pipeline/PIPELINE-COMPLETO.md` (MODIFY)

**Arquivos**:
- MODIFY: `.hacker/agentes/orquestrador-pipeline/PIPELINE-COMPLETO.md`

**Depende de**: TASK 8 (estrutura de parallelismo definida no ORQUESTRADOR.md)

**Verificacao**:
```bash
bash -n .hacker/agentes/orquestrador-pipeline/PIPELINE-COMPLETO.md 2>/dev/null; echo "exit: $?"
```

**Descricao Detalhada**:
1. Modificar o fluxo 5-etapas para incluir paralelismo entre Scraping e Reconhecimento de Rede
2. Definir merge point para web-scanner
3. Manter Etapas 3 (pentest) e 4 (reconfirmação) sequenciais
4. Etapa 5 (blue-team) inicia quando ambas as entradas estão prontas
5. Adicionar mecanismo de waves para tarefas com arquivos disjuntos

---

### ONDA 3: Documentação de Controle (DEPENDE de todas as ondas anteriores)

## TASK 10: Atualizar AGENTS.md — Diagrama de Controle

**Arquivo**: `AGENTS.md` (MODIFY)

**Arquivos**:
- MODIFY: `AGENTS.md`

**Depende de**: TASK 4, TASK 5, TASK 6, TASK 7, TASK 8, TASK 9

**Verificacao**:
```bash
bash -n AGENTS.md 2>/dev/null; echo "exit: $?"
git diff --check 2>/dev/null || echo "sem whitespace errors"
```

**Descricao Detalhada**:
1. Adicionar diagrama de controle no final do arquivo (ou na seção relevante):
   ```
   FERNANDO (DECISOR) → GATES → GRAPH + LOOP → PARADA UNICA → FERNANDO
   ```
2. Invariante 8: reafirmar que o Graph/Loop executa dentro do escopo autorizado
3. Seção 8: adicionar nota de que o Loop itera automaticamente dentro de limites, mas para na PARADA UNICA
4. Seção 11: atualizar para refletir o HARNESS GUARDIAN como camada adicional

---

## TASK 11: Atualizar hacker-epistemic-safety.md — Contexto Loop/Graph

**Arquivo**: `.opencode/rules/hacker-epistemic-safety.md` (MODIFY)

**Arquivos**:
- MODIFY: `.opencode/rules/hacker-epistemic-safety.md`

**Depende de**: TASK 4, TASK 10

**Verificacao**:
```bash
bash -n .opencode/rules/hacker-epistemic-safety.md 2>/dev/null; echo "exit: $?"
```

**Descricao Detalhada**:
1. Regra principal: reafirmar "USUARIO = DECISOR E ARQUITETO UNICO / AGENTE = EXECUTOR, NAO CONDUTOR" no contexto do Loop/Graph
2. Auto-auditoria: adicionar pergunta "O Loop/Grafo está executando dentro do escopo autorizado?" como verificação obrigatória antes de qualquer conclusão

---

## TASK 12: Atualizar hacker-fable-method.md — F4 e F2 com Loop

**Arquivo**: `.opencode/rules/hacker-fable-method.md` (MODIFY)

**Arquivos**:
- MODIFY: `.opencode/rules/hacker-fable-method.md`

**Depende de**: TASK 4, TASK 10

**Verificacao**:
```bash
bash -n .opencode/rules/hacker-fable-method.md 2>/dev/null; echo "exit: $?"
```

**Descricao Detalhada**:
1. F4 (Veredito): adicionar classe explícita para ações do Loop: "Ações iteradas pelo Loop que tocam a cadeia de proteção (classe C) sempre param e confirmam com o Fernando"
2. F2 (Manual sobre IA): reafirmar que o Loop é ferramenta dentro da operação autorizada, não operação independente

---

## TASK 13: Atualizar GATE-DE-PROTECAO.md — HARNESS GUARDIAN

**Arquivo**: `.hacker/gate/GATE-DE-PROTECAO.md` (MODIFY)

**Arquivos**:
- MODIFY: `.hacker/gate/GATE-DE-PROTECAO.md`

**Depende de**: TASK 1, TASK 10

**Verificacao**:
```bash
bash -n .hacker/gate/GATE-DE-PROTECAO.md 2>/dev/null; echo "exit: $?"
```

**Descricao Detalhada**:
1. Adicionar regra: "O HARNESS GUARDIAN é a camada final de proteção do controle humano. Se a cadeia quebra, o Loop e o Graph são pausados automaticamente. Nenhum mecanismo de automação sobrepõe o gate."
2. Adicionar referencia aos scripts gate-*.sh criados na ONDA 1
3. Registrar no .hacker/scripts/ como componente do gate

---

## ONDA 4: VALIDACAO E TESTES

## TASK 14: Validacao completa do pipeline

**Arquivo**: nao cria arquivo novo

**Depende de**: TASK 1-13 (todas as tarefas anteriores)

**Verificacao**:
```bash
# 1. Sintaxe dos scripts gate criados
bash -n .hacker/scripts/gate-preflight.sh
bash -n .hacker/scripts/gate-p1.sh
bash -n .hacker/scripts/gate-p2.sh

# 2. Scripts gate são executáveis
ls -la .hacker/scripts/gate-*.sh

# 3. Gate executa e retorna código de saída
bash .hacker/scripts/gate-preflight.sh; echo "exit: $?"

# 4. Verificar-vazamento.sh inalterado
bash -n ~/opsec/scripts/verificar-vazamento.sh

# 5. SUNSET test
git status --short | grep -E '\.(tmp|bak|swp)$' || echo "SUNSET: limpo"

# 6. Verificar postura de rede
bash ~/opsec/scripts/verificar-vazamento.sh
```

---

## Informacoes de Contexto

### Pre-flight verificado
- `verificar-vazamento.sh` retorna GOOD (cadeia ativa)
- WireGuard wg0 ATIVO
- Tor na porta 9050 ativo
- Branch: `issue-011-anthropic-graph-loop`

### Fontes RAG consultadas (F6)
1. Anthropic, "Building Effective Agents", Dez 2024 — https://www.anthropic.com/engineering/building-effective-agents
2. Codigo real do projeto (todos os arquivos listados em FILES INVOLVED)
3. `.opencode/rules/hacker-repo-profile.md`
4. `.opencode/rules/hacker-fable-method.md`
5. `.opencode/rules/hacker-opsec-canon.md`

### Regras de protecao
- Nenhuma alteracao em `~/opsec/scripts/` existentes
- Nenhuma alteracao em `~/opsec/docker-compose.yml`
- Scripts gate criados em `.hacker/scripts/` (não é area sensivel da cadeia)
- Git de escrita é exclusivo do Fernando
- Ações de classe C sempre param para confirmação do Fernando
- O Loop itera maximo 5 ciclos

### Preservação do controle humano
- Fernando permanece como DECISOR E ARQUITETO UNICO
- O Loop/Graph são ferramentas de execução dentro do escopo autorizado
- Nenhuma documentacao sugere que o Loop ou Graph substitui a decisão humana
- HARNESS GUARDIAN documentado como camada final de proteção do controle humano
