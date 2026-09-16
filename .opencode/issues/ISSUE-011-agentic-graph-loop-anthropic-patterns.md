# ISSUE-011: Implementação dos Padrões Graph + Loop da Anthropic

## Contexto

O projeto hacker-etico-ambiente já implementa 4 dos 5 padrões centrais de agentes eficazes descritos na documentação oficial da Anthropic ("Building Effective Agents", Dez 2024):

1. **Prompt chaining** — SDD pipeline (Skill 1 → 0 → 2 → 3 → 0 → 4 → 4.5 → 4.6)
2. **Routing** — Gates P1/P2 (PROSSEGUIR/REJEITAR)
3. **Parallelization** — Waves na Skill 4 (parcial, arquivos disjuntos)
4. **Orchestrator-workers** — `.opencode/agents/orquestrador.md` + subagentes implementador/revisor/documentador
5. **Evaluator-optimizer** — **NÃO IMPLEMENTADO**

O padrão 5 (Evaluator-optimizer / Loop) é o que falta para completar a arquitetura Anthropic. Além disso, os 4 padrões existentes precisam ser elevados ao nível que a documentação recomenda (gates programáticos, routing condicional, paralelismo real entre etapas, delegação dinâmica).

Fonte: `https://www.anthropic.com/engineering/building-effective-agents`

## O que a Anthropic recomenda explicitamente

### Evaluator-Optimizer (Loop)
> *"One LLM call generates a response while another provides evaluation and feedback in a loop."*
>
> *"Particularly effective when we have clear evaluation criteria, and when iterative refinement provides measurable value."*
>
> *"Complex search tasks that require multiple rounds of searching and analysis to gather comprehensive information, where the evaluator decides whether further searches are warranted."*

**Aplicação ao projeto**: O `hacker-tests` + `verificar-vazamento.sh` têm critérios claros (GOOD/FAIL). O loop deve iterar automaticamente até convergência, sem depender de limite arbitrário de tentativas.

### Routing
> *"Routing classifies an input and directs it to a specialized followup task."*
>
> *"Routing works well for complex tasks where there are distinct categories that are better handled separately."*

**Aplicação ao projeto**: O gate atual é binário (PROSSEGUIR/REJEITAR). Specs de tipos diferentes (cadeia, docs, enforcement, bugfix) precisam de rotas condicionais.

### Parallelization
> *"Sectioning: Breaking a task into independent subtasks run in parallel."*
>
> *"Effective when the divided subtasks can be parallelized for speed."*

**Aplicação ao projeto**: O pipeline 5-etapas operacional (scraping → scan → pentest → reconf → blue-team) é sequencial. Scraping e reconhecimento de rede são independentes e podem rodar em paralelo.

### Orchestrator-Workers
> *"A central LLM dynamically breaks down tasks, delegates them to worker LLMs, and synthesizes their results."*
>
> *"Well-suited for complex tasks where you can't predict the subtasks needed."*
>
> *"Subtasks aren't pre-defined, but determined by the orchestrator based on the specific input."*

**Aplicação ao projeto**: O orquestrador delega para subagentes pré-definidos no plano. A delegação deveria ser dinâmica baseada no tipo de task.

### Prompt Chaining com Gates Programáticos
> *"You can add programmatic checks (see 'gate') on any intermediate steps to ensure that the process is still on track."*

**Aplicação ao projeto**: Os gates do pipeline são descritos em texto. Deveriam ser scripts executáveis com código de saída PASS/FAIL.

## Problema observável

- O pipeline SDD para `hacker-tests` para por limite arbitrário (max 2 tentativas de fix) em vez de convergência real
- O pipeline 5-etapas operacional é 100% sequencial (scraping e scan não rodam em paralelo)
- O gate é binário (PASS/FAIL) sem routing condicional por tipo de spec
- O orquestrador despacha subagentes pré-definidos, não dinamicamente
- Os gates são verificações textuais, não scripts executáveis com código de saída
- O projeto já segue a estrutura de Skills da Anthropic (`anthropics/skills`, 177k stars) mas não segue todos os padrões de workflow

## Objetivo

Implementar os padrões Graph (topologia de workflows) e Loop (autonomia iterativa) da Anthropic no projeto hacker-etico-ambiente, completando o 5º padrão (Evaluator-optimizer) e elevando os 4 existentes ao nível recomendado pela documentação.

## Itens de implementação

### Item 1: Evaluator-Optimizer (Loop) — NECESSÁRIO AGORA

**Modificar**: `.opencode/skills/hacker-tests/SKILL.md`

- Substituir o fix-loop atual (max 2 tentativas arbitrário) por um loop evaluator-optimizer:
  - **Generator**: subagent implementador gera o fix
  - **Evaluator**: `hacker-tests` executa a bateria completa (bash -n, shellcheck, py_compile, docker compose config, git diff --check, verificar-vazamento.sh)
  - **Loop**: se FAIL → re-torna ao generator com o output do evaluator → generator ajusta → evaluator re-testa
  - **Critério de parada**: GOOD do `verificar-vazamento.sh` E todos os testes PASS, OU 5 ciclos sem melhoria mensurável (convergência)
  - **Cada iteração gera entrada no Trust Ledger** (evento `loop-ciclo=N | resultado=...`)
  - **Ações de classe C (F4)**: independentemente do loop, sempre param e pedem Fernando

**Critérios de aceitação**:
- [ ] `hacker-tests` itera automaticamente até GOOD + todos PASS
- [ ] Loop para por convergência (5 ciclos sem melhoria), não por limite arbitrário
- [ ] Cada ciclo gera entrada no Trust Ledger
- [ ] Ações de classe C sempre param para confirmação do Fernando
- [ ] SUNSET test (F7) para o loop-evaluator

### Item 2: Routing Condicional

**Modificar**: `.opencode/commands/hacker-sdd-pipeline-auto.md` e `.opencode/skills/hacker-specification-design/SKILL.md`

- Substituir gate binário (PROSSEGUIR/REJEITAR) por routing condicional baseado no tipo de spec:
  - `spec CATEGORY = "Infra"` E arquivos incluem `~/opsec/scripts/` → route para gate reforçado (classe C, Fernando confirma) + pre-flight reforçado
  - `spec CATEGORY = "Docs"` → route direto para documentador (sem gate de security)
  - `spec CATEGORY = "Bugfix"` → route para gate padrão + pre-flight F1
  - `spec CATEGORY = "Feature"` E toca cadeia → route para orquestrador + gate reforçado
  - `spec CATEGORY = "Feature"` nao toca cadeia → route padrão

**Critérios de aceitação**:
- [ ] Tabela de routing condicional definida no pipeline auto
- [ ] Cada categoria de spec tem rota definida
- [ ] Routing é executável (não apenas textual)
- [ ] F10 (harness-integrity) verifica a tabela de routing

### Item 3: Parallelization entre etapas do pipeline

**Modificar**: `.hacker/orquestrador/ORQUESTRADOR.md` e `.hacker/agentes/orquestrador-pipeline/PIPELINE-COMPLETO.md`

- Pipeline 5-etapas operacional: scraping e reconhecimento de rede executam em paralelo
- O merge point é o ponto onde web-scanner recebe resultados de ambos
- Etapas 3 (pentest) e 4 (reconfirmação) permanecem sequenciais (dependência de dados)
- Etapa 5 (blue-team) inicia quando ambas as entradas (pentest + reconfirmação) estão prontas
- Waves de paralelismo: tarefas com arquivos disjuntos e sem dependência executam simultaneamente

**Critérios de aceitação**:
- [ ] Scraping e reconhecimento de rede em paralelo no pipeline
- [ ] Merge point definido para web-scanner
- [ ] Etapas dependentes permanecem sequenciais
- [ ] Paralelismo verificado com SUNSET test

### Item 4: Delegação Dinâmica do Orquestrador

**Modificar**: `.opencode/agents/orquestrador.md`

- O orquestrador lê o input do usuário
- Dinamicamente determina quais subagentes são necessários baseado no tipo de task:
  - Se spec requer rede → despacha implementador + revisor + pre-flight checker
  - Se spec é apenas docs → despacha apenas documentador
  - Se spec é complexa (múltiplos arquivos, múltiplas skills) → despacha múltiplos workers em paralelo
- Sintetiza os resultados de todos os workers no relatório consolidado
- Delegação baseada no input, não no plano pré-definido

**Critérios de aceitação**:
- [ ] Lógica de delegação dinâmica implementada no orquestrador
- [ ] Orquestrador determina workers baseado no input do usuário
- [ ] Sintetização dos resultados em relatório consolidado
- [ ] Sunsetting do mecanismo de delegação

### Item 5: Gates Programáticos

**Criar**: `.hacker/scripts/gate-p1.sh`, `.hacker/scripts/gate-p2.sh`, `.hacker/scripts/gate-preflight.sh`

- **gate-preflight.sh**: executa verificar-vazamento.sh, verifica wg0, verifica torproxy-host, retorna PASS/FAIL com código de saída
- **gate-p1.sh**: executa critical-analysis automatizado, verifica se fontes F6 foram consultadas, retorna PASS/FAIL
- **gate-p2.sh**: executa rule-control, verifica se spec não toca áreas sensíveis sem confirmação, retorna PASS/FAIL

**Modificar**: `.opencode/commands/hacker-sdd-pipeline-auto.md`
- Substituir verificações textuais de gate por chamadas executáveis aos scripts gate-*.sh
- Cada gate retorna código de saída: 0 = PASS, 1 = FAIL, 2 = BLOQUEADO

**Critérios de aceitação**:
- [ ] gate-preflight.sh executável com código de saída
- [ ] gate-p1.sh executável com código de saída
- [ ] gate-p2.sh executável com código de saída
- [ ] Pipeline chama os scripts, não verifica texto
- [ ] bash -n PASS em todos os scripts gate
- [ ] SUNSET test para cada gate

## Prioridade

**Item 1 (Loop/Evaluator-optimizer)**: Máxima. É o padrão central que falta e a Anthropic endossa explicitamente.

**Item 2 (Routing)**: Alta. Melhora o fluxo do pipeline imediatamente.

**Item 3 (Parallelization)**: Alta. Reduz tempo de execução do pipeline operacional.

**Item 4 (Delegação dinâmica)**: Média. Melhora a flexibilidade do orquestrador.

**Item 5 (Gates programáticos)**: Média. Dá verificação mecanica aos gates (F10).

## Integração com o SDD Pipeline existente

Todos os itens devem seguir o SDD pipeline do projeto:
1. **hacker-specification-design**: gerar spec para cada item
2. **hacker-critical-analysis**: P1 + P2
3. **pre-writing-rule-control**: validar contra regras do projeto
4. **hacker-writing-plans**: plano de implementação com tarefas atômicas
5. **hacker-subagent-driven-development**: implementação
6. **hacker-tests**: validação com SUNSET test
7. **hacker-doc-sync**: atualização de documentação
8. **PARADA UNICA**: relatório consolidado

## Regras aplicáveis

- **F1** (contexto antes da ação): pre-flight de proteção antes de cada mudança
- **F2** (manual sobre IA): operações fora da autorização do Fernando são proibidas
- **F3** (evidência): todo resultado deve ter saída literal de comando
- **F4** (veredito, classes A/B/C): ações de classe C exigem confirmação do Fernando
- **F5** (propor o mínimo): implementar o padrão completo, não pela metade
- **F6** (lembranca/anti-alucinacao): toda fonte citada da Anthropic deve ser verificada
- **F7** (SUNSET): teste util para cada mudança
- **F8** (semente): medir antes de otimizar; estabelecer baseline
- **F9** (trilho): cada item segue o trilho do SDD pipeline
- **F10** (verificacao mecanica): gates programáticos são verificaveis por máquina
- **F11** (Trust Ledger): cada entrada do loop é registrada no ledger
- **F12** (postmortem-to-law): se a implementação falhar, gera emenda de lei

## Regras do projeto aplicáveis

- `AGENTS.md` seção 7 (processo de desenvolvimento): SDD pipeline
- `hacker-repo-profile.md`: validacao por fase
- `hacker-fable-method.md`: leis F1-F12
- `hacker-epistemic-safety.md`: anti-invencao, auto-auditoria
- `hacker-pentest-harness-execution.md`: anti-recusa
- `hacker-trust-ledger.md`: vereditos sao artefatos

## PRESERVAÇÃO DO CONTROLE HUMANO — DOCUMENTAÇÃO OBRIGATÓRIA PÓS-IMPLEMENTAÇÃO

### Princípio inegociável

**Fernando permanece como DECISOR e ARQUITETO UNICO.** O Graph e o Loop são ferramentas de execução dentro do escopo que o Fernando autoriza. Eles não tomam decisões de escopo, não autorizam ações de classe C, não fazem commits de git, nem abrem PRs. O modelo é executor. O humano é decisor. Essa relação é a base de todo o harness e não muda com nenhuma melhoria.

### O que deve ser atualizado na documentação após a implementação

Todas as implementações desta issue exigem atualização das seguintes documentações para refletir explicitamente o estado de controle:

#### 1. AGENTS.md

- **Invariante 8** (Escopo e decisão exclusiva do Fernando): reafirmar explicitamente que o Graph/Loop executa dentro do escopo autorizado e não altera a autoridade de decisão
- **Seção 8** (Como agir ao ajudar neste repositório): adicionar nota de que o Loop itera automaticamente dentro de limites definidos, mas para na PARADA UNICA
- **Seção 11** (Postura de protecao): atualizar para refletir o HARNESS GUARDIAN como camada adicional de proteção

#### 2. .opencode/rules/hacker-epistemic-safety.md

- **Regra principal**: reafirmar "USUARIO = DECISOR E ARQUITETO UNICO / AGENTE = EXECUTOR, NAO CONDUTOR" no contexto do Loop/Graph
- **Auto-auditoria**: adicionar pergunta "O Loop/Grafo está executando dentro do escopo autorizado?" como verificação obrigatória antes de qualquer conclusão

#### 3. .opencode/rules/hacker-fable-method.md

- **F4 (Veredito)**: adicionar classe explícita para ações do Loop: "Ações iteradas pelo Loop que tocam a cadeia de proteção (classe C) sempre param e confirmam com o Fernando"
- **F2 (Manual sobre IA)**: reafirmar que o Loop é ferramenta dentro da operação autorizada, não operação independente

#### 4. .opencode/commands/hacker-sdd-pipeline-auto.md

- Adicionar diagrama de controle mostrando: Fernando → PARADA UNICA → decisão → modelo executa dentro do escopo → Loop itera → PARADA UNICA → Fernando
- Registrar explicitamente que o Loop é limitado a 5 ciclos e que ações de classe C sempre param para confirmação

#### 5. .hacker/orquestrador/ORQUESTRADOR.md

- Adicionar seção "Limites de Autoridade" explicitando:
  - O orquestrador delega, mas não decide escopo
  - O Loop itera, mas não autoriza ações de classe C
  - O Routing direciona, mas não altera o escopo definido pelo Fernando
  - O HARNESS GUARDIAN pode parar tudo se a cadeia quebrar

#### 6. .hacker/gate/GATE-DE-PROTECAO.md

- Adicionar regra: "O HARNESS GUARDIAN é a camada final de proteção do controle humano. Se a cadeia quebra, o Loop e o Graph são pausados automaticamente. Nenhum mecanismo de automação sobrepõe o gate."

#### 7. .opencode/skills/hacker-tests/SKILL.md (após modificação do Loop)

- Adicionar seção "Limites do Loop":
  - Loop itera máximo 5 ciclos
  - Loop para na PARADA UNICA
  - Ações de classe C sempre param para Fernando
  - Se a cadeia muda de GOOD para LEAK durante o Loop → HARNESS GUARDIAN pausa tudo
  - Loop não faz commit de git, não abre PR, não decide escopo

#### 8. .hacker/scripts/harness-guardian.sh (após criação)

- Adicionar comentário de cabecalho: "Este script é a camada de proteção que garante que o controle humano nunca é sobreposto pela automação. Se a cadeia quebra, nada executa — nem Loop, nem Graph, nem orquestrador."

#### 9. .hacker/agentes/orquestrador-pipeline/AGENTE.md

- Adicionar seção "Limites de Autoridade do Pipeline":
  - O pipeline executa operações autorizadas
  - O pipeline não define escopo
  - O pipeline não autoriza ações de classe C
  - O pipeline para se o gate falhar

#### 10. .opencode/specs/ ou .hacker/README.md

- Atualizar manifesto para refletir que o Graph/Loop são ferramentas de execução dentro do controle humano
- Registrar explicitamente a arquitetura de controle: humano → gates → Loop/Graph → PARADA UNICA → humano

### Diagrama de controle final (deve aparecer em AGENTS.md e ORQUESTRADOR.md)

```
┌─────────────────────────────────────────────────────────┐
│                    FERNANDO (DECISOR)                     │
│  Escopo │ Git │ Classe C │ PARADA UNICA │ Finalização    │
└──────────────────┬──────────────────────────────────────┘
                   │ autoriza
                   ▼
┌─────────────────────────────────────────────────────────┐
│                    GATES (programáticos)                  │
│  Gate F1 (verificar-vazamento.sh)                         │
│  Gate P1/P2 (critical-analysis)                           │
│  Gate HARNESS GUARDIAN (cadeia GOOD)                      │
└──────────────────┬──────────────────────────────────────┘
                   │ APROVADO
                   ▼
┌─────────────────────────────────────────────────────────┐
│                  GRAPH + LOOP (EXECUTORES)                │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐                  │
│  │ Routing │→ │  Loop   │→ │ Parallel │                  │
│  │ Condic. │  │(até 5x) │  │  Execu.  │                  │
│  └─────────┘  └────┬────┘  └─────────┘                  │
│                     │                                    │
│              PARADA UNICA (modelo PARA)                   │
└──────────────────┬──────────────────────────────────────┘
                   │ apresenta relatorio
                   ▼
┌─────────────────────────────────────────────────────────┐
│              FERNANDO DECIDE (FINISHING)                  │
│  Autorizar │ Abrir issues │ Descartar                     │
└─────────────────────────────────────────────────────────┘
```

### Registro no Trust Ledger (F11)

Após a implementação completa, registrar entrada:
```
[data] | ciclo=ISSUE-011 | skill=hacker-tests+hacker-specification-design | evento=implementacao-concluida | resultado=Graph+Loop implementados, documentacao de controle atualizada em AGENTS.md, ORQUESTRADOR.md, GATE-DE-PROTECAO.md, hacker-tests/SKILL.md | base=documentação atualizada com diagrama de controle e limites de autoridade
```

## Critérios de aceitação — Preservação de controle (OBRIGATÓRIO)

- [ ] AGENTS.md reafirma Fernando como DECISOR UNICO com Graph/Loop implementados
- [ ] Cada skill modificada inclui seção "Limites do Loop" ou "Limites de Autoridade"
- [ ] Diagrama de controle presente em AGENTS.md e ORQUESTRADOR.md
- [ ] HARNESS GUARDIAN documentado como camada final de proteção do controle humano
- [ ] Nenhuma documentação sugere que o Loop ou Graph substitui a decisão humana
- [ ] Trust Ledger atualizado com o evento de implementação concluída

## Origem

Auditoria completa da arquitetura do projeto usando a taxonomia Anthropic (Graph + Loop), realizada em 2026-09-16. Documentação da Anthropic lida integralmente:
- `https://www.anthropic.com/engineering/building-effective-agents`
- `https://github.com/anthropics/anthropic-cookbook`
- `https://github.com/anthropics/skills`
- `https://github.com/anthropics/claude-code`

## Fontes citadas (F6 — RAG obrigatorio)

1. Anthropic, "Building Effective Agents", Dez 2024 — https://www.anthropic.com/engineering/building-effective-agents
2. Anthropic, "Claude Cookbooks" — https://github.com/anthropics/anthropic-cookbook
3. Anthropic, "Skills" — https://github.com/anthropics/skills
4. Anthropic, "Claude Code" — https://github.com/anthropics/claude-code
5. `AGENTS.md` do repositório (documento canônico do agente)
6. `.opencode/rules/hacker-fable-method.md` (leis F1-F12)
7. `.opencode/rules/hacker-epistemic-safety.md` (disciplina epistemica)
