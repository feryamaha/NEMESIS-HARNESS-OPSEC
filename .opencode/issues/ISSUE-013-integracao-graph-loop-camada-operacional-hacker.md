# ISSUE-013: Integração dos Padrões Graph+Loop na Camada Operacional .hacker/

## Contexto

Os padrões Graph+Loop da Anthropic (routing, delegação, paralelização, gates, loop evaluator-optimizer) já estão implementados mecanicamente no projeto através do executor `.hacker/scripts/graph-loop.py` e da suite de testes `.hacker/scripts/test-graph-loop.sh` (8/8 PASS). Conforme Trust Ledger 2026-09-17:

- **Executor local**: `.hacker/scripts/graph-loop.py` com subcomandos route, delegate, parallel, loop
- **Suite de testes**: 8 testes validando todos os componentes (todos PASS)
- **Integração parcial**: routing no pipeline-auto, delegação no orquestrador, paralelismo para jobs independentes, loop no hacker-tests

No entanto, a **integração completa** desses padrões nos processos de hacking da camada operacional `.hacker/` (red-team, blue-team, pentest, scraping, web-scanner) ainda não está documentada nem operacionalizada de forma sistemática.

## Perguntas de referência (P1, P2, P3)

### P1: O meu projeto ele possui duas camadas: governança-desenvolvimento (.opencode) e a camada mais importante e operacional em .hacker/ nos processos de hacking em .hacker/ graph e loop foram implementados? como esta?

**Resposta:** SIM, graph e loop estão implementados e funcionais na camada operacional .hacker/:
- Executor local: `.hacker/scripts/graph-loop.py` (route, delegate, parallel, loop)
- Suite de testes: `.hacker/scripts/test-graph-loop.sh` (8/8 PASS)
- Integração no pipeline: routing, delegação, paralelismo, loop já conectados
- Loop implementa padrão Anthropic (generator ↔ evaluator com feedback via EVALUATOR_*)
- Delegação dinâmica com WORKERS da spec prevalecendo sobre defaults

### P2: analise a docmentação da natropic sobre graph e loop e me diga a possibildade de implementação na camada de hacking ( .hacker/) graph e loop ou se isso seria ruim por se tratar de processo de hacking seria ideial deixar manual ou pelo contrario seria bom ara adcioanr determinismo e controle!

**Resposta:** É **bom** adicionar determinismo e controle através de graph e loop em .hacker/:
- Routing determinístico garante que operations sensíveis recebam guards reforçados automaticamente
- Loop com feedback permite otimização iterativa controlada (max_cycles, max_stagnant) com ledger de operações
- Delegação dinâmica com WORKERS explícitos na spec evita surpresas de escopo
- Automação NÃO torna atividade ilegal — o escopo é que define legalidade, não o nível de automação
- Graph/loop aplicam-se ao fluxo de trabalho do harness (escolha de agente, delegação, validação), não à execução bruta de exploits

### P3: desenhe um diagrama onde eu consiga enchergar quais ramificações , quais nós, processo de hacking de [.hacker] poderia ser implementado graph e loop para dar determinismo, automação e bloqueio de operações não autorizadas!

**Resposta:** Diagrama desenhado mostrando 6 nós do Graph aplicáveis a processos de hacking em .hacker/:
1. ROUTING (classificação de specs por CATEGORY + FILES INVOLVED)
2. DELEGAÇÃO (seleção de agentes por WORKERS da spec ou defaults)
3. PARALELIZAÇÃO (execução de varreduras independentes em paralelo)
4. GATES (P1, P2, pre-flight F1, HARNESS GUARDIAN)
5. EXECUÇÃO DE WORKERS (implementador, revisor, preflight-checker, documentador)
6. LOOP EVALUATOR-OPTIMIZER (generator ↔ evaluator com feedback iterativo)

## Problema observável

- Graph+Loop estão implementados mecanicamente mas não estão integrados de forma sistemática nos processos de hacking da camada .hacker/
- Não há documentação clara de como usar graph-loop.py em operações reais (red-team, pentest, scraping, web-scanner)
- Os agentes em `.hacker/agentes/` não referenciam os padrões Graph+Loop em seus contratos
- O orquestrador `.hacker/orquestrador/ORQUESTRADOR.md` não descreve como usar routing, delegação, paralelismo e loop em operações de hacking
- Não há specs/plans que descrevam operações de hacking usando os padrões Graph+Loop
- O pipeline operacional (PIPELINE-COMPLETO.md) não incorpora os nós do Graph de forma explícita

## Objetivo

Integrar sistematicamente os padrões Graph+Loop já implementados nos processos de hacking da camada operacional `.hacker/`, com documentação clara, exemplos práticos e integração nos contratos de agentes, orquestrador e pipeline operacional.

## Itens de implementação

### Item 1: Atualizar contratos de agentes para usar Graph+Loop

**Modificar**: Todos os arquivos `.hacker/agentes/*/AGENTE.md`

- Adicionar seção "Padrões Graph+Loop" em cada contrato de agente
- Descrever como cada agente usa routing, delegação, paralelismo e loop
- Para red-team: routing para operações sensíveis, delegação dinâmica, paralelismo de varreduras
- Para blue-team: loop evaluator-optimizer para validação iterativa de remediação
- Para pentest: routing por CATEGORY, delegação com WORKERS explícitos, paralelismo de reconhecimento
- Para scraping: routing para sources, delegação por tipo de source, paralelismo de coleta
- Para web-scanner: routing por tipo de scan, delegação por ferramenta, paralelismo de templates

**Critérios de aceitação**:
- [ ] Todos os 5 contratos de agentes têm seção "Padrões Graph+Loop"
- [ ] Cada contrato descreve uso específico de routing, delegação, paralelismo, loop
- [ ] Referências a graph-loop.py estão presentes nos contratos
- [ ] WORKERS explícitos são mencionados nos contratos quando aplicável

### Item 2: Atualizar orquestrador para usar Graph+Loop

**Modificar**: `.hacker/orquestrador/ORQUESTRADOR.md`

- Adicionar seção "Integração Graph+Loop" descrevendo:
  - Como usar `graph-loop.py route` para classificar specs de operação
  - Como usar `graph-loop.py delegate` para despachar agentes dinamicamente
  - Como usar `graph-loop.py parallel` para executar varreduras independentes
  - Como usar `graph-loop.py loop` para otimização iterativa
- Adicionar diagrama do Graph com os 6 nós aplicáveis a .hacker/
- Adicionar exemplos de comandos graph-loop.py para operações reais
- Integrar com o diagrama de controle já existente (Fernando → Gates → Graph+Loop → PARADA UNICA)

**Critérios de aceitação**:
- [ ] Seção "Integração Graph+Loop" presente no ORQUESTRADOR.md
- [ ] Diagrama do Graph com 6 nós (routing, delegação, paralelização, gates, execução, loop)
- [ ] Exemplos de comandos graph-loop.py para operações de hacking
- [ ] Integração com diagrama de controle existente

### Item 3: Atualizar pipeline operacional para usar Graph+Loop

**Modificar**: `.hacker/agentes/orquestrador-pipeline/PIPELINE-COMPLETO.md`

- Integrar os 6 nós do Graph no pipeline 5-etapas (scraping → scan → pentest → reconf → blue-team)
- Descrever onde cada nó do Graph é aplicado:
  - ROUTING: classificação da operação (reconhecimento, enumeração, exploração, relatório)
  - DELEGAÇÃO: seleção de agentes (red-team, blue-team, pentest, scraping, web-scanner)
  - PARALELIZAÇÃO: scraping e reconhecimento em paralelo
  - GATES: P1, P2, pre-flight F1, HARNESS GUARDIAN
  - EXECUÇÃO: implementador, revisor, preflight-checker, documentador
  - LOOP: otimização iterativa de payloads, configuração, validação de findings
- Adicionar exemplos de specs com WORKERS explícitos para operações de hacking

**Critérios de aceitação**:
- [ ] 6 nós do Graph integrados no pipeline operacional
- [ ] Cada nó do Graph descrito com aplicação específica
- [ ] Exemplos de specs com WORKERS explícitos
- [ ] Fluxo do pipeline mostra onde cada nó é aplicado

### Item 4: Criar spec de exemplo usando Graph+Loop

**Criar**: `.opencode/specs/SPEC_013_exemplo-operacao-graph-loop.md`

- Spec de exemplo de operação de hacking usando padrões Graph+Loop
- CATEGORY = "Feature" (ou categoria apropriada)
- FILES INVOLVED com arquivos de .hacker/
- Seção WORKERS declarando agentes específicos (red-team, web-scanner, etc.)
- Descrição de como routing, delegação, paralelismo e loop são usados
- Sem rede, sem IP real, sem credenciais (apenas exemplo conceitual)

**Critérios de aceitação**:
- [ ] SPEC_013 criada com estrutura completa
- [ ] Seção WORKERS presente com agentes específicos
- [ ] Descrição do uso de Graph+Loop na operação
- [ ] Spec de docs (não toca ~/opsec/, cadeia, containers, .env)

### Item 5: Criar plan de implementação

**Criar**: `.opencode/plans/PLAN_013_integracao-graph-loop-camada-operacional.md`

- Plano com tarefas atômicas para implementar itens 1-4
- Tarefas específicas para cada contrato de agente
- Tarefas para orquestrador e pipeline operacional
- Tarefas para spec de exemplo
- Validação com comandos do perfil (bash -n, grep, find)

**Critérios de aceitação**:
- [ ] PLAN_013 criado com tarefas atômicas
- [ ] Cada item de implementação tem tarefas correspondentes
- [ ] Comandos de validação presentes
- [ ] Plan de docs (não toca ~/opsec/, cadeia, containers, .env)

### Item 6: Validar integração com suite de testes

**Modificar**: `.hacker/scripts/test-graph-loop.sh` (se necessário)

- Adicionar testes para validar uso de Graph+Loop em operações de hacking
- Testar routing com specs de hacking (CATEGORY = feature/bugfix com FILES INVOLVED sensíveis)
- Testar delegação com WORKERS de agentes de hacking
- Testar paralelismo de varreduras independentes
- Testar loop com evaluator-optimizer para validação de findings

**Critérios de aceitação**:
- [ ] Testes adicionados para operações de hacking
- [ ] Routing com specs de hacking validado
- [ ] Delegação com WORKERS de agentes validada
- [ ] Paralelismo de varreduras validado
- [ ] Loop com evaluator-optimizer validado
- [ ] Suite continua 100% PASS

## Prioridade

**Item 1 (Contratos de agentes)**: Alta. Base para integração sistemática.

**Item 2 (Orquestrador)**: Alta. Centraliza a documentação de uso de Graph+Loop.

**Item 3 (Pipeline operacional)**: Alta. Mostra aplicação prática nos processos de hacking.

**Item 4 (Spec de exemplo)**: Média. Serve como template para operações futuras.

**Item 5 (Plan de implementação)**: Alta. Guia a execução sistemática.

**Item 6 (Validação)**: Média. Confirma que a integração funciona.

## Integração com o SDD Pipeline existente

Todos os itens devem seguir o SDD pipeline do projeto:
1. **hacker-specification-design**: gerar spec para a integração
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
- **F5** (propor o mínimo): implementar a integração completa, não pela metade
- **F6** (lembranca/anti-alucinacao): toda fonte citada da Anthropic deve ser verificada
- **F7** (SUNSET): teste util para cada mudança
- **F8** (semente): medir antes de otimizar; estabelecer baseline
- **F9** (trilho): cada item segue o trilho do SDD pipeline
- **F10** (verificacao mecanica): graph-loop.py é verificável por máquina
- **F11** (Trust Ledger): cada operação é registrada no ledger
- **F12** (postmortem-to-law): se a implementação falhar, gera emenda de lei

## Regras do projeto aplicáveis

- `AGENTS.md` seção 7 (processo de desenvolvimento): SDD pipeline
- `hacker-repo-profile.md`: validacao por fase
- `hacker-fable-method.md`: leis F1-F12
- `hacker-epistemic-safety.md`: anti-invencao, auto-auditoria
- `hacker-pentest-harness-execution.md`: anti-recusa
- `hacker-trust-ledger.md`: vereditos sao artefatos

## Diagrama do Graph para .hacker/ (referência)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ ENTRADA: SPEC ou REQUEST DO FERNANDO                                         │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ GRAPH NODE 1: ROUTING (graph-loop.py route)                                 │
│ • Classifica por CATEGORY (docs/infra/bugfix/feature/refactor)             │
│ • Detecta sensibilidade em FILES INVOLVED (~/opsec/scripts/, docker-compose)│
│ • Retorna rota: documentação | padrão | reforçado | orquestrador           │
│ • Retorna guard: nenhum | preflight-f1 | reforçado                         │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                    ┌───────────────┴───────────────┐
                    │                               │
                    ▼                               ▼
┌───────────────────────────────┐   ┌───────────────────────────────────────┐
│ ROTA: documentação            │   │ ROTA: padrão / reforçado / orquestrador│
│ GUARD: nenhum                 │   │ GUARD: preflight-f1 / reforçado       │
└───────────────────────────────┘   └───────────────────────────────────────┘
                    │                               │
                    ▼                               ▼
┌───────────────────────────────┐   ┌───────────────────────────────────────┐
│ WORKER: documentador         │   │ GRAPH NODE 2: DELEGAÇÃO (delegate)    │
│ • Atualiza docs .hacker/      │   │ • Lê WORKERS da spec                 │
│ • Sem rede, sem sensibilidade │   │ • Deriva workers por defaults         │
└───────────────────────────────┘   │ • Complexidade: simples | complexa   │
                                    │ • Retorna payload {route, workers}    │
                                    └───────────────────────────────────────┘
                                                                    │
                                    ┌───────────────────────────────┴───────────────┐
                                    │                                               │
                                    ▼                                               ▼
                    ┌───────────────────────────────┐   ┌───────────────────────────────────────┐
                    │ WORKERS (por defaults)        │   │ WORKERS (da spec WORKERS)             │
                    │ • implementador               │   │ • Customizados por Fernando          │
                    │ • revisor                     │   │ • Escopo explícito no arquivo         │
                    │ • preflight-checker (sensitive)│   │ • Sobrepõem defaults                   │
                    │ • documentador (complexa)     │   └───────────────────────────────────────┘
                    └───────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ GRAPH NODE 3: PARALELIZAÇÃO (parallel)                                      │
│ • Executa workers independentes em paralelo (ThreadPoolExecutor)             │
│ • Jobs: implementador, revisor, preflight-checker, documentador              │
│ • Aguarda todos completar; propaga falhas                                     │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ GRAPH NODE 4: GATES (P1, P2, pre-flight F1)                                  │
│ • Gate P1: validação de estrutura de spec                                    │
│ • Gate P2: validação de regras (areas sensíveis, IPs, travessões)            │
│ • Pre-flight F1: verificação de cadeia (WireGuard wg0, torproxy-host, leak) │
│ • HARNESS GUARDIAN: bloqueio de operações não autorizadas                    │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                    ┌───────────────┴───────────────┐
                    │                               │
                    ▼                               ▼
┌───────────────────────────────┐   ┌───────────────────────────────────────┐
│ FAIL: BLOQUEADO               │   │ PASS: PROSSEGUIR                      │
│ • Registra no Trust Ledger    │   • Registra no Trust Ledger             │
│ • Reporta falha ao Fernando   │   • Continua para execução               │
└───────────────────────────────┘   └───────────────────────────────────────┘
                                                            │
                                                            ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ GRAPH NODE 5: EXECUÇÃO DE WORKERS (delegate --execute)                      │
│ • Implementador: executa tarefa principal (pentest, scraping, scan)          │
│ • Revisor: valida resultado e conformidade                                   │
│ • Preflight-checker: re-verifica cadeia antes de rede (classe C)            │
│ • Documentador: atualiza relatórios em .hacker/reports/                     │
└─────────────────────────────────────────────────────────────────────────────┘
                                                            │
                                                            ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ GRAPH NODE 6: LOOP EVALUATOR-OPTIMIZER (loop)                                │
│ • Generator: produz candidato (payload, configuração, finding)              │
│ • Evaluator: avalia candidato (SCORE, exit_code, stdout/stderr)             │
│ • Feedback: EVALUATOR_* ao generator (iteração)                              │
│ • Condições de parada: evaluator exit=0, melhoria detectada, max_cycles,    │
│   max_stagnant                                                                 │
│ • Ledger opcional: registra cada ciclo                                       │
└─────────────────────────────────────────────────────────────────────────────┘
                    │                               │
                    ▼                               ▼
┌───────────────────────────────┐   ┌───────────────────────────────────────┐
│ LOOP CONCLUIDO                │   │ LOOP PARADO                          │
│ • SCORE satisfatório          │   • max_stagnant atingido               │
│ • Registra em LEDGER-OPERACOES│   • max_cycles atingido                 │
│ • Relatório final             │   • Registra no Trust Ledger             │
└───────────────────────────────┘   └───────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│ SAÍDA: RELATÓRIO EM .hacker/reports/ (OP-YYYYMMDD-XXX.md)                   │
│ • Atestado de conformidade                                                   │
│ • Findings validados                                                         │
│ • Ledger de operações (append-only)                                         │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Critérios de aceitação geral

- [ ] Todos os contratos de agentes têm seção "Padrões Graph+Loop"
- [ ] Orquestrador descreve integração Graph+Loop com diagrama e exemplos
- [ ] Pipeline operacional integra os 6 nós do Graph
- [ ] Spec de exemplo demonstra uso de Graph+Loop em operação de hacking
- [ ] Plan de implementação guia execução sistemática
- [ ] Suite de testes valida integração com operações de hacking
- [ ] Trust Ledger atualizado com implementação concluída

## Origem

Perguntas P1, P2, P3 do Fernando em 2026-09-17 solicitando análise de graph e loop na camada operacional .hacker/ e diagrama de aplicação.

## Fontes citadas (F6 — RAG obrigatorio)

1. Anthropic, "Building Effective Agents", Dez 2024 — https://www.anthropic.com/engineering/building-effective-agents
2. `.hacker/scripts/graph-loop.py` (executor local implementado)
3. `.hacker/scripts/test-graph-loop.sh` (suite de testes 8/8 PASS)
4. Trust Ledger 2026-09-17 (implementação graph-loop concluída)
5. `AGENTS.md` (documento canônico do agente)
6. `.opencode/rules/hacker-fable-method.md` (leis F1-F12)
7. `.opencode/rules/hacker-epistemic-safety.md` (disciplina epistemica)
8. `.hacker/orquestrador/ORQUESTRADOR.md` (orquestrador atual)
9. `.hacker/agentes/*/AGENTE.md` (contratos de agentes atuais)
10. `.hacker/agentes/orquestrador-pipeline/PIPELINE-COMPLETO.md` (pipeline operacional atual)
