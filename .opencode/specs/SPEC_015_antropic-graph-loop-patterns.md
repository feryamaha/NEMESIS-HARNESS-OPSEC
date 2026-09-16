# SPEC_015: Implementacao dos Padrões Graph + Loop da Anthropic

> Referencia: ISSUE-011-agentic-graph-loop-anthropic-patterns.md

## REQUEST

Implementar os padrones Graph (topologia de workflows) e Loop (autonomia iterativa) da documentacao oficial da Anthropic ("Building Effective Agents", Dez 2024) no projeto hacker-etico-ambiente, completando o padrao 5 (Evaluator-optimizer) que falta e elevando os 4 padroes existentes ao nivel recomendado pela documentacao.

## CATEGORY

Feature

## PROBLEM

- O projeto ja implementa 4 dos 5 padrones centrais de agentes eficazes da Anthropic (Prompt chaining, Routing, Parallelization, Orchestrator-workers), mas o padrao 5 (Evaluator-optimizer/Loop) nao existe.
- O pipeline SDD para `hacker-tests` para por limite arbitrario (max 2 tentativas de fix) em vez de convergencia real via loop evaluator-optimizer.
- O pipeline 5-etapas operacional e 100% sequencial (scraping e scan nao rodam em paralelo).
- O gate e binario (PROSSEGUIR/REJEITAR) sem routing condicional por tipo de spec.
- O orquestrador despacha subagentes pre-definidos no plano, nao dinamicamente baseado no input.
- Os gates sao verificacoes textuais, nao scripts executaveis com codigo de saida.

## CONTEXT

### Fontes consultadas (RAG)

1. **Anthropic, "Building Effective Agents", Dez 2024** — https://www.anthropic.com/engineering/building-effective-agents
   - Padrao 5 (Evaluator-optimizer): "one LLM call generates a response while another provides evaluation and feedback in a loop"
   - Padrao 2 (Routing): "classifies an input and directs it to a specialized followup task"
   - Padrao 3 (Parallelization): "Sectioning: Breaking a task into independent subtasks run in parallel"
   - Padrao 4 (Orchestrator-workers): "a central LLM dynamically breaks down tasks, delegates them to worker LLMs"
   - Padrao 1 (Prompt chaining): "add programmatic checks (see 'gate') on any intermediate steps"
2. **Codigo real do projeto** (fonte #1):
   - `.opencode/skills/hacker-tests/SKILL.md` (200 linhas, lido por completo) — contem fix-loop com max 2 tentativas arbitrario
   - `.opencode/commands/hacker-sdd-pipeline-auto.md` (222 linhas, lido por completo) — gate binario, pipeline sequencial
   - `.opencode/agents/orquestrador.md` (50 linhas, lido por completo) — despacho pre-definido
   - `.hacker/orquestrador/ORQUESTRADOR.md` (48 linhas, lido por completo) — roteamento estatico por tabela
   - `.opencode/skills/hacker-specification-design/SKILL.md` (206 linhas, lido por completo) — sem routing condicional
   - `.hacker/agentes/orquestrador-pipeline/PIPELINE-COMPLETO.md` — pipeline 5-etapas sequencial
   - `~/opsec/scripts/` — scripts de protecao (listados, nao modificados nesta spec)
   - `~/opsec/docker-compose.yml` — servicos de protecao (torproxy-host, gluetun, etc.)
3. **Regras do projeto**: `.opencode/rules/hacker-repo-profile.md`, `.opencode/rules/hacker-fable-method.md`, `.opencode/rules/hacker-opsec-canon.md`
4. **Skills existentes**: `.opencode/skills/hacker-critical-analysis/SKILL.md` — gates P1/P2 textuais

### Estado atual do projeto (observacoes)

- `verificar-vazamento.sh` retorna GOOD (cadeia ativa, Tor exit 185.220.101.130, DNS sem ECS, IPv6 off, wg0 ATIVO) — confirmado via comando
- WireGuard wg0 ativo — confirmado via `ip -o link show wg0`
- Tor na porta 9050 ativo — confirmado via `ss -tlnp | grep 9050`
- Container torproxy-host nao rodando como Docker (Tor ativo diretamente)
- Atesado: nenhum arquivo de atestado encontrado no filesystem atual (glob falhou)
- Branch `issue-011-anthropic-graph-loop` criada e check-out realizado

### Premissas

- A implementacao dos padrao Graph e Loop e uma mudanca na camada de habilidades/orquestracao (`.opencode/skills/`, `.opencode/commands/`, `.opencode/agents/`, `.hacker/orquestrador/`), nao na cadeia de protecao (`~/opsec/scripts/`)
- A modificacao de `hacker-tests/SKILL.md` e `hacker-sdd-pipeline-auto.md` nao e considerada area sensivel da cadeia de protecao (nao sao scripts de protecao)
- A criacao de scripts gate em `.hacker/scripts/` e a modificacao de `.hacker/orquestrador/` sao area sensivel do harness operacional
- O pre-flight de protecao (verificar-vazamento.sh GOOD) e requerido se a mudanca tocar rede

## REQUIREMENTS

### Item 1: Evaluator-Optimizer (Loop) — NECESSARIO AGORA

**Modificar**: `.opencode/skills/hacker-tests/SKILL.md`

- Substituir o fix-loop atual (max 2 tentativas arbitrario) por um loop evaluator-optimizer:
  - **Generator**: subagent implementador gera o fix
  - **Evaluator**: `hacker-tests` executa a bateria completa (bash -n, shellcheck, py_compile, docker compose config, git diff --check, verificar-vazamento.sh)
  - **Loop**: se FAIL → re-torna ao generator com o output do evaluator → generator ajusta → evaluator re-testa
  - **Critério de parada**: GOOD do `verificar-vazamento.sh` E todos os testes PASS, OU 5 ciclos sem melhoria mensuravel (convergência)
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
  - `spec CATEGORY = "Feature"` não toca cadeia → route padrão

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

## PRESERVAÇÃO DO CONTROLE HUMANO (OBRIGATÓRIO)

### Diagrama de controle final (deve aparecer em AGENTS.md e ORQUESTRADOR.md)

```
┌─────────────────────────────────────────────────────────┐
│                    FERNANDO (DECISOR)                     │
│  Escopo │ Git │ Classe C │ PARADA UNICA │ Finalização    │
└──────────────────┬──────────────────────────────────────┘
                   │ autoriza
                   ▼
┌─────────────────────────────────────────────────────────┐
│                  GATES (programáticos)                  │
│  Gate F1 (verificar-vazamento.sh)                         │
│  Gate P1/P2 (critical-analysis)                           │
│  Gate HARNESS GUARDIAN (cadeia GOOD)                    │
└──────────────────┬──────────────────────────────────────┘
                   │ APROVADO
                   ▼
┌─────────────────────────────────────────────────────────┐
│                GRAPH + LOOP (EXECUTORES)                │
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

### O que deve ser atualizado na documentação após a implementação

Todas as implementações desta issue exigem atualização das seguintes documentações:

1. **AGENTS.md** — reafirmar Fernando como DECISOR UNICO; adicionar nota de que o Loop itera automaticamente dentro de limites definidos, mas para na PARADA UNICA
2. **.opencode/rules/hacker-epistemic-safety.md** — reafirmar "USUARIO = DECISOR E ARQUITETO UNICO / AGENTE = EXECUTOR, NAO CONDUTOR" no contexto do Loop/Graph
3. **.opencode/rules/hacker-fable-method.md** — F4: adicionar classe para ações do Loop; F2: reafirmar que o Loop é ferramenta dentro da operação autorizada
4. **.opencode/commands/hacker-sdd-pipeline-auto.md** — adicionar diagrama de controle; registrar limites do Loop (5 ciclos, classe C para Fernando)
5. **.hacker/orquestrador/ORQUESTRADOR.md** — adicionar seção "Limites de Autoridade"
6. **.hacker/gate/GATE-DE-PROTECAO.md** — adicionar regra do HARNESS GUARDIAN
7. **.opencode/skills/hacker-tests/SKILL.md** (após modificação) — adicionar seção "Limites do Loop"
8. **Trust Ledger** — registrar evento de implementação concluída

## FILES INVOLVED

- `.opencode/skills/hacker-tests/SKILL.md` (MODIFY: Loop evaluator-optimizer)
- `.opencode/commands/hacker-sdd-pipeline-auto.md` (MODIFY: Routing condicional + Gates programáticos)
- `.opencode/skills/hacker-specification-design/SKILL.md` (MODIFY: Routing condicional)
- `.opencode/agents/orquestrador.md` (MODIFY: Delegação dinâmica)
- `.hacker/orquestrador/ORQUESTRADOR.md` (MODIFY: Parallelization + Limites de Autoridade)
- `.hacker/agentes/orquestrador-pipeline/PIPELINE-COMPLETO.md` (MODIFY: Parallelization)
- `.hacker/scripts/gate-preflight.sh` (CREATE: gate executável)
- `.hacker/scripts/gate-p1.sh` (CREATE: gate executável)
- `.hacker/scripts/gate-p2.sh` (CREATE: gate executável)
- `.hacker/gate/GATE-DE-PROTECAO.md` (MODIFY: HARNESS GUARDIAN)
- `AGENTS.md` (MODIFY: diagrama de controle + limites)
- `.opencode/rules/hacker-epistemic-safety.md` (MODIFY: contexto Loop/Graph)
- `.opencode/rules/hacker-fable-method.md` (MODIFY: F4 Loop + F2 Loop)

## RESTRICTIONS

- Regras do perfil do repo: bash scripts com `set -uo pipefail`, sem em-dash, sem primeira pessoa
- Areas sensiveis (classe C): scripts de protecao em `~/opsec/scripts/` e `docker-compose.yml` nao sao tocados (exceto criacao de novos scripts gate em `.hacker/scripts/`)
- Nao tocar em `~/opsec/scripts/` existentes (kill-switch.sh, verificar-vazamento.sh, iniciar-sessao.sh, encerrar-sessao.sh, validar-dns-fix.sh, session-start-hacking-security.sh, gate-enforcement.sh)
- Nao tocar em `~/opsec/docker-compose.yml`
- Operacoes de classe C (modificacao de scripts de protecao): exigir confirmacao do Fernando
- O Loop itera maximo 5 ciclos e para na PARADA UNICA
- Ações de classe C sempre param para confirmação do Fernando, independentemente do Loop
- Nenhuma documentacao sugere que o Loop ou Graph substitui a decisão humana
- Git de escrita é exclusivo do Fernando

## EXPECTED DELIVERY

1. `.opencode/skills/hacker-tests/SKILL.md`: loop evaluator-optimizer com critério de convergência (5 ciclos), cada ciclo gera entrada no Trust Ledger
2. `.opencode/commands/hacker-sdd-pipeline-auto.md`: tabela de routing condicional + chamadas executáveis aos scripts gate-*.sh
3. `.opencode/skills/hacker-specification-design/SKILL.md`: routing condicional por categoria de spec
4. `.opencode/agents/orquestrador.md`: delegação dinâmica baseada no input do usuário
5. `.hacker/orquestrador/ORQUESTRADOR.md`: pipeline paralelo (scraping + scan em paralelo) + seção Limites de Autoridade
6. `.hacker/agentes/orquestrador-pipeline/PIPELINE-COMPLETO.md`: merge point definido para web-scanner
7. `.hacker/scripts/gate-preflight.sh`, `gate-p1.sh`, `gate-p2.sh`: scripts executáveis com código de saída (PASS/FAIL/BLOQUEADO)
8. `.hacker/gate/GATE-DE-PROTECAO.md`: HARNESS GUARDIAN documentado
9. `AGENTS.md`: diagrama de controle + limites de autoridade do Loop/Graph
10. `.opencode/rules/hacker-epistemic-safety.md`: contexto Loop/Graph na regra principal
11. `.opencode/rules/hacker-fable-method.md`: F4 e F2 atualizados com Loop
12. `bash -n PASS` em todos os scripts gate criados
13. Trust Ledger atualizado com o evento de implementação concluída

## VERIFICATION

```bash
# 1. Sintaxe dos scripts gate criados
bash -n ~/opsec/scripts/gate-preflight.sh 2>/dev/null || echo "Nao existe ainda"
bash -n .hacker/scripts/gate-preflight.sh
bash -n .hacker/scripts/gate-p1.sh
bash -n .hacker/scripts/gate-p2.sh

# 2. Scripts gate são executáveis
ls -la .hacker/scripts/gate-*.sh

# 3. Gate executa e retorna código de saída
bash .hacker/scripts/gate-preflight.sh; echo "exit: $?"
bash .hacker/scripts/gate-p1.sh; echo "exit: $?"
bash .hacker/scripts/gate-p2.sh; echo "exit: $?"

# 4. Verificar-vazamento.sh inalterado
bash -n ~/opsec/scripts/verificar-vazamento.sh

# 5. bash -n nos arquivos .opencode modificados
bash -n .opencode/skills/hacker-tests/SKILL.md 2>/dev/null || echo "MD nao e bash"

# 6. SUNSET test: nenhum artefato temporario deixado para trás
git status --short | grep -E '\.(tmp|bak|swp)$' || echo "SUNSET: limpo"

# 7. Verificar postura de rede (se houve acao de rede)
bash ~/opsec/scripts/verificar-vazamento.sh
```

## Integracao com o SDD Pipeline existente

Todos os itens devem seguir o SDD pipeline do projeto:
1. **hacker-specification-design**: gerar spec (STEPE 1-4 desta skill)
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
- **F10** (verificacao mecanica): gates programáticos são verificáveis por máquina
- **F11** (Trust Ledger): cada entrada do loop é registrada no ledger
- **F12** (postmortem-to-law): se a implementação falhar, gera emenda de lei

## Origem

Auditoria completa da arquitetura do projeto usando a taxonomia Anthropic (Graph + Loop), realizada em 2026-09-16. Documentação da Anthropic lida integralmente.

## Fontes citadas (F6 — RAG obrigatorio)

1. Anthropic, "Building Effective Agents", Dez 2024 — https://www.anthropic.com/engineering/building-effective-agents
2. Anthropic, "Claude Cookbooks" — https://github.com/anthropics/anthropic-cookbook
3. Anthropic, "Skills" — https://github.com/anthropics/skills
4. Anthropic, "Claude Code" — https://github.com/anthropics/claude-code
5. `AGENTS.md` do repositório (documento canônico do agente)
6. `.opencode/rules/hacker-fable-method.md` (leis F1-F12)
7. `.opencode/rules/hacker-epistemic-safety.md` (disciplina epistemica)
8. `.opencode/rules/hacker-repo-profile.md` (validacao por fase)
9. `.opencode/rules/hacker-opsec-canon.md` (canon por modulo da cadeia)
