# SPEC_017: Integração dos Padrões Graph+Loop na Camada Operacional .hacker/

## REQUEST

Integrar sistematicamente os padrões Graph+Loop (routing, delegação, paralelização, gates, loop evaluator-optimizer) já implementados mecanicamente nos processos de hacking da camada operacional `.hacker/`, com documentação clara, exemplos práticos e integração nos contratos de agentes, orquestrador e pipeline operacional.

## CATEGORY

Feature

## PROBLEM

- Graph+Loop estão implementados mecanicamente (`.hacker/scripts/graph-loop.py` com 8/8 testes PASS) mas não estão integrados de forma sistemática nos processos de hacking da camada `.hacker/`
- Não há documentação clara de como usar graph-loop.py em operações reais (red-team, pentest, scraping, web-scanner)
- Os agentes em `.hacker/agentes/` não referenciam os padrões Graph+Loop em seus contratos
- O orquestrador `.hacker/orquestrador/ORQUESTRADOR.md` não descreve como usar routing, delegação, paralelismo e loop em operações de hacking
- Não há specs/plans que descrevam operações de hacking usando os padrões Graph+Loop
- O pipeline operacional (PIPELINE-COMPLETO.md) não incorpora os nós do Graph de forma explícita

## CONTEXT

**Arquivos afetados:**
- `.hacker/agentes/red-team/AGENTE.md` (modify, adicionar seção Graph+Loop)
- `.hacker/agentes/blue-team/AGENTE.md` (modify, adicionar seção Graph+Loop)
- `.hacker/agentes/pentest/AGENTE.md` (modify, adicionar seção Graph+Loop)
- `.hacker/agentes/scraping/AGENTE.md` (modify, adicionar seção Graph+Loop)
- `.hacker/agentes/web-scanner/AGENTE.md` (modify, adicionar seção Graph+Loop)
- `.hacker/orquestrador/ORQUESTRADOR.md` (modify, adicionar seção Integração Graph+Loop)
- `.hacker/agentes/orquestrador-pipeline/PIPELINE-COMPLETO.md` (modify, integrar nós do Graph)
- `.opencode/specs/SPEC_017_exemplo-operacao-graph-loop.md` (create, spec de exemplo)
- `.opencode/plans/PLAN_017_integracao-graph-loop-camada-operacional.md` (create, plano de implementação)
- `.hacker/scripts/test-graph-loop.sh` (modify, adicionar testes para operações de hacking)

**Executor já implementado:**
- `.hacker/scripts/graph-loop.py` com subcomandos route, delegate, parallel, loop
- Suite de testes `.hacker/scripts/test-graph-loop.sh` com 8/8 PASS
- Loop implementa padrão Anthropic (generator ↔ evaluator com feedback via EVALUATOR_*)
- Delegação dinâmica com WORKERS da spec prevalecendo sobre defaults

**Fontes consultadas:**
- ISSUE-013: `.opencode/issues/ISSUE-013-integracao-graph-loop-camada-operacional-hacker.md`
- Trust Ledger 2026-09-17 (implementação graph-loop concluída)
- Anthropic, "Building Effective Agents", Dez 2024 — https://www.anthropic.com/engineering/building-effective-agents
- `.hacker/scripts/graph-loop.py` (executor local)
- `.hacker/scripts/test-graph-loop.sh` (suite de testes)
- `.hacker/agentes/red-team/AGENTE.md` (contrato atual)
- `.hacker/orquestrador/ORQUESTRADOR.md` (orquestrador atual)
- `.hacker/agentes/orquestrador-pipeline/PIPELINE-COMPLETO.md` (pipeline operacional atual)
- `.opencode/rules/hacker-opsec-canon.md` (canon da cadeia)
- `.opencode/rules/hacker-fable-method.md` (leis F1-F12)
- `.opencode/rules/hacker-epistemic-safety.md` (disciplina epistemica)

**Assumpções:**
- A implementação mecânica de graph-loop.py está completa e funcional (8/8 PASS)
- A integração é puramente documentacional e de processos, não toca código do executor
- As operações de hacking continuam autorizadas (HTB, THM, DVWA, VulnHub, labs próprios)
- O controle humano permanece inalterado (Fernando como DECISOR UNICO)
- Não há necessidade de rede para esta spec (apenas documentação de processos)

**Pre-flight:**
- Nenhuma ação de rede é necessária para esta spec (apenas documentação)
- Não há necessidade de executar `verificar-vazamento.sh` para esta spec

## REQUIREMENTS

1. Atualizar todos os 5 contratos de agentes (`.hacker/agentes/*/AGENTE.md`) para incluir seção "Padrões Graph+Loop" descrevendo uso específico de routing, delegação, paralelismo e loop
2. Atualizar orquestrador (`.hacker/orquestrador/ORQUESTRADOR.md`) para incluir seção "Integração Graph+Loop" com diagrama dos 6 nós e exemplos de comandos graph-loop.py
3. Atualizar pipeline operacional (`.hacker/agentes/orquestrador-pipeline/PIPELINE-COMPLETO.md`) para integrar os 6 nós do Graph no pipeline 5-etapas
4. Criar spec de exemplo (`.opencode/specs/SPEC_017_exemplo-operacao-graph-loop.md`) demonstrando uso de Graph+Loop em operação de hacking
5. Criar plan de implementação (`.opencode/plans/PLAN_017_integracao-graph-loop-camada-operacional.md`) com tarefas atômicas
6. Adicionar testes à suite `.hacker/scripts/test-graph-loop.sh` para validar uso de Graph+Loop em operações de hacking

## FILES INVOLVED

- `.hacker/agentes/red-team/AGENTE.md` (modify)
- `.hacker/agentes/blue-team/AGENTE.md` (modify)
- `.hacker/agentes/pentest/AGENTE.md` (modify)
- `.hacker/agentes/scraping/AGENTE.md` (modify)
- `.hacker/agentes/web-scanner/AGENTE.md` (modify)
- `.hacker/orquestrador/ORQUESTRADOR.md` (modify)
- `.hacker/agentes/orquestrador-pipeline/PIPELINE-COMPLETO.md` (modify)
- `.opencode/specs/SPEC_017_exemplo-operacao-graph-loop.md` (create)
- `.opencode/plans/PLAN_017_integracao-graph-loop-camada-operacional.md` (create)
- `.hacker/scripts/test-graph-loop.sh` (modify)

## RESTRICTIONS

- Regras 1-6 do perfil do repo (linguagem, toolchain, areas sensiveis, escopo, git, artefatos)
- NÃO tocar em `~/opsec/scripts/` (scripts de proteção são classe C)
- NÃO tocar em `~/opsec/docker-compose.yml` (classe C)
- NÃO tocar em IP real, credenciais ou dados sensíveis
- NÃO fazer commits de git (git de escrita é exclusivo do Fernando)
- Preservar controle humano: Fernando permanece como DECISOR UNICO
- Graph+Loop são ferramentas de execução dentro do escopo autorizado, não substituem decisão humana
- Manter compatibilidade com implementação existente de graph-loop.py
- Sem rede, sem IP real, sem credenciais (apenas documentação de processos)

## EXPECTED DELIVERY

- Todos os 5 contratos de agentes têm seção "Padrões Graph+Loop" com uso específico
- Orquestrador tem seção "Integração Graph+Loop" com diagrama dos 6 nós e exemplos
- Pipeline operacional integra os 6 nós do Graph de forma explícita
- Spec de exemplo criada demonstrando uso de Graph+Loop em operação de hacking
- Plan de implementação criado com tarefas atômicas
- Suite de testes estendida com testes para operações de hacking
- bash -n PASS em todos os arquivos bash modificados
- python3 -m py_compile PASS em graph-loop.py (se houver modificação)
- grep zero em/en dash em arquivos tocados
- grep zero IP literal em arquivos tocados
- Trust Ledger atualizado com implementação concluída

## VERIFICATION

```bash
# Verificar sintaxe bash (se houver scripts modificados)
bash -n .hacker/scripts/test-graph-loop.sh

# Verificar sintaxe python3 (se houver modificação)
python3 -m py_compile .hacker/scripts/graph-loop.py

# Verificar ausência de em/en dash
grep -rn '[—–]' .hacker/agentes/ .hacker/orquestrador/ .hacker/agentes/orquestrador-pipeline/

# Verificar ausência de IP literal
grep -rn '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' .hacker/agentes/ .hacker/orquestrador/ .hacker/agentes/orquestrador-pipeline/ | grep -v '127.0.0.1'

# Verificar que seções "Padrões Graph+Loop" foram adicionadas
grep -l 'Padrões Graph+Loop' .hacker/agentes/*/AGENTE.md

# Verificar que seção "Integração Graph+Loop" foi adicionada ao orquestrador
grep -l 'Integração Graph+Loop' .hacker/orquestrador/ORQUESTRADOR.md

# Verificar que nós do Graph foram integrados ao pipeline
grep -l 'ROUTING\|DELEGAÇÃO\|PARALELIZAÇÃO\|GATES\|EXECUÇÃO\|LOOP' .hacker/agentes/orquestrador-pipeline/PIPELINE-COMPLETO.md

# Executar suite de testes
bash .hacker/scripts/test-graph-loop.sh
```
