# Integração Graph+Loop na Camada Operacional .hacker/ - Plano de Implementação

> **Para agentes**: Use hacker-subagent-driven-development para executar este plano.

**Objetivo**: Integrar sistematicamente os padrões Graph+Loop (routing, delegação, paralelização, gates, loop evaluator-optimizer) já implementados mecanicamente nos processos de hacking da camada operacional `.hacker/`, com documentação clara, exemplos práticos e integração nos contratos de agentes, orquestrador e pipeline operacional.

**Spec**: `.opencode/specs/SPEC_017_integracao-graph-loop-camada-operacional-hacker.md`

## Tarefas

### TASK 1: Adicionar seção "Padrões Graph+Loop" ao contrato red-team
**FILE**: `.hacker/agentes/red-team/AGENTE.md` (MODIFY)
**DEPENDE_DE**: nenhuma
**ACAO**: Adicionar seção "Padrões Graph+Loop" após "Referências (RAG)" descrevendo:
- Routing para operações sensíveis (CATEGORY + FILES INVOLVED)
- Delegação dinâmica com WORKERS explícitos
- Paralelismo de varreduras (nmap, masscan, curl)
- Loop evaluator-optimizer para tuning de payloads
- Referência a graph-loop.py
**VERIFICACAO**: grep -q 'Padrões Graph+Loop' .hacker/agentes/red-team/AGENTE.md

### TASK 2: Adicionar seção "Padrões Graph+Loop" ao contrato blue-team
**FILE**: `.hacker/agentes/blue-team/AGENTE.md` (MODIFY)
**DEPENDE_DE**: nenhuma
**ACAO**: Adicionar seção "Padrões Graph+Loop" após "Formato do relatorio" descrevendo:
- Loop evaluator-optimizer para validação iterativa de remediação
- Routing por CATEGORY (infra/docs/bugfix/feature)
- Delegação dinâmica para sub-tarefas de hardening
- Referência a graph-loop.py
**VERIFICACAO**: grep -q 'Padrões Graph+Loop' .hacker/agentes/blue-team/AGENTE.md

### TASK 3: Adicionar seção "Padrões Graph+Loop" ao contrato pentest
**FILE**: `.hacker/agentes/pentest/AGENTE.md` (MODIFY)
**DEPENDE_DE**: nenhuma
**ACAO**: Adicionar seção "Padrões Graph+Loop" após "Referências (RAG)" descrevendo:
- Routing por CATEGORY com WORKERS explícitos
- Delegação dinâmica para fases PTES (recon → enumeration → exploitation)
- Paralelismo de reconhecimento (nmap, masscan)
- Loop evaluator-optimizer para validação de exploits
- Referência a graph-loop.py
**VERIFICACAO**: grep -q 'Padrões Graph+Loop' .hacker/agentes/pentest/AGENTE.md

### TASK 4: Adicionar seção "Padrões Graph+Loop" ao contrato scraping
**FILE**: `.hacker/agentes/scraping/AGENTE.md` (MODIFY)
**DEPENDE_DE**: nenhuma
**ACAO**: Adicionar seção "Padrões Graph+Loop" após "Formato do relatorio" descrevendo:
- Routing para sources (URL, API, OSINT)
- Delegação por tipo de source (web, API, arquivo)
- Paralelismo de coleta (curl, scrapy, playwright)
- Referência a graph-loop.py
**VERIFICACAO**: grep -q 'Padrões Graph+Loop' .hacker/agentes/scraping/AGENTE.md

### TASK 5: Adicionar seção "Padrões Graph+Loop" ao contrato web-scanner
**FILE**: `.hacker/agentes/web-scanner/AGENTE.md` (MODIFY)
**DEPENDE_DE**: nenhuma
**ACAO**: Adicionar seção "Padrões Graph+Loop" após "Referências (RAG)" descrevendo:
- Routing por tipo de scan (ZAP, Nuclei, ambos)
- Delegação por ferramenta (ZAP API, Nuclei templates)
- Paralelismo de templates Nuclei
- Loop evaluator-optimizer para validação de findings
- Referência a graph-loop.py
**VERIFICACAO**: grep -q 'Padrões Graph+Loop' .hacker/agentes/web-scanner/AGENTE.md

### TASK 6: Adicionar seção "Integração Graph+Loop" ao orquestrador
**FILE**: `.hacker/orquestrador/ORQUESTRADOR.md` (MODIFY)
**DEPENDE_DE**: TASK 1, TASK 2, TASK 3, TASK 4, TASK 5
**ACAO**: Adicionar seção "Integração Graph+Loop" após "Limites de Autoridade" descrevendo:
- Como usar `graph-loop.py route` para classificar specs de operação
- Como usar `graph-loop.py delegate` para despachar agentes dinamicamente
- Como usar `graph-loop.py parallel` para executar varreduras independentes
- Como usar `graph-loop.py loop` para otimização iterativa
- Diagrama do Graph com os 6 nós (routing, delegação, paralelização, gates, execução, loop)
- Exemplos de comandos graph-loop.py para operações reais
- Integração com diagrama de controle existente (Fernando → Gates → Graph+Loop → PARADA UNICA)
**VERIFICACAO**: grep -q 'Integração Graph+Loop' .hacker/orquestrador/ORQUESTRADOR.md

### TASK 7: Integrar nós do Graph no pipeline operacional
**FILE**: `.hacker/agentes/orquestrador-pipeline/PIPELINE-COMPLETO.md` (MODIFY)
**DEPENDE_DE**: TASK 6
**ACAO**: Integrar os 6 nós do Graph no pipeline 5-etapas (scraping → scan → pentest → reconf → blue-team):
- Adicionar subseção "Graph Nodes Integration" após "Tratamento de Falhas"
- Descrever onde cada nó do Graph é aplicado:
  - ROUTING: classificação da operação (reconhecimento, enumeração, exploração, relatório)
  - DELEGAÇÃO: seleção de agentes (red-team, blue-team, pentest, scraping, web-scanner)
  - PARALELIZAÇÃO: scraping e reconhecimento em paralelo
  - GATES: P1, P2, pre-flight F1, HARNESS GUARDIAN
  - EXECUÇÃO: implementador, revisor, preflight-checker, documentador
  - LOOP: otimização iterativa de payloads, configuração, validação de findings
- Adicionar exemplos de specs com WORKERS explícitos para operações de hacking
**VERIFICACAO**: grep -q 'ROUTING\|DELEGAÇÃO\|PARALELIZAÇÃO\|GATES\|EXECUÇÃO\|LOOP' .hacker/agentes/orquestrador-pipeline/PIPELINE-COMPLETO.md

### TASK 8: Criar spec de exemplo usando Graph+Loop
**FILE**: `.opencode/specs/SPEC_017_exemplo-operacao-graph-loop.md` (CREATE)
**DEPENDE_DE**: TASK 6
**ACAO**: Criar spec de exemplo de operação de hacking usando padrões Graph+Loop:
- CATEGORY = "Feature" (ou categoria apropriada)
- FILES INVOLVED com arquivos de .hacker/
- Seção WORKERS declarando agentes específicos (red-team, web-scanner, etc.)
- Descrição de como routing, delegação, paralelismo e loop são usados
- Sem rede, sem IP real, sem credenciais (apenas exemplo conceitual)
- Estrutura completa conforme SPEC_017
**VERIFICACAO**: ls .opencode/specs/SPEC_017_exemplo-operacao-graph-loop.md && grep -q 'WORKERS' .opencode/specs/SPEC_017_exemplo-operacao-graph-loop.md

### TASK 9: Criar plan de implementação (este arquivo)
**FILE**: `.opencode/plans/PLAN_017_integracao-graph-loop-camada-operacional.md` (CREATE)
**DEPENDE_DE**: TASK 1, TASK 2, TASK 3, TASK 4, TASK 5, TASK 6, TASK 7, TASK 8
**ACAO**: Criar este plano de implementação com tarefas atômicas:
- Tarefas específicas para cada contrato de agente
- Tarefas para orquestrador e pipeline operacional
- Tarefas para spec de exemplo
- Validação com comandos do perfil (bash -n, grep, find)
- DEPENDE_DE para permitir paralelismo
**VERIFICACAO**: ls .opencode/plans/PLAN_017_integracao-graph-loop-camada-operacional.md

### TASK 10: Estender suite de testes para operações de hacking
**FILE**: `.hacker/scripts/test-graph-loop.sh` (MODIFY)
**DEPENDE_DE**: TASK 1, TASK 2, TASK 3, TASK 4, TASK 5, TASK 6, TASK 7, TASK 8, TASK 9
**ACAO**: Adicionar testes para validar uso de Graph+Loop em operações de hacking:
- Testar routing com specs de hacking (CATEGORY = feature/bugfix com FILES INVOLVED sensíveis)
- Testar delegação com WORKERS de agentes de hacking
- Testar paralelismo de varreduras independentes
- Testar loop com evaluator-optimizer para validação de findings
- Manter compatibilidade com testes existentes (8/8 PASS)
**VERIFICACAO**: bash -n .hacker/scripts/test-graph-loop.sh && bash .hacker/scripts/test-graph-loop.sh

## Validação Final

Após conclusão de todas as tarefas, executar validação completa:

```bash
# Verificar sintaxe bash
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

## Paralelismo

- **Wave 1**: TASK 1, TASK 2, TASK 3, TASK 4, TASK 5 (arquivos disjuntos, sem dependência)
- **Wave 2**: TASK 6 (depende de Wave 1)
- **Wave 3**: TASK 7, TASK 8 (dependem de TASK 6, arquivos disjuntos)
- **Wave 4**: TASK 9 (depende de TASK 7, TASK 8)
- **Wave 5**: TASK 10 (depende de todas as tarefas anteriores)
