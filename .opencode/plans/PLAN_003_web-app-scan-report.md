# PLAN_003: Scan de Aplicações Web + Geração de Relatório Técnico Estruturado

- data: 2026-09-11
- ciclo: PLAN_003
- status: PROSSEGUIR (P1)
- categoria: Docs (artefato de arquitetura de capability, sem implementacao de ferramentas)
- **REVISAO**: Plano gerado a partir da SPEC_003 reescrita (correção de posicionamento arquitetural). Todos os componentes operacionais vivem em `.hacker/`; apenas a regra AI vive em `.opencode/rules/`.

## REQUEST

Converter a SPEC_003 em plano de implementacao com tarefas atomicas para a capability de scan de aplicacoes web automatizado (ZAP + Nuclei) + geracao de relatorio tecnico estruturado (OWASP/PTES), dentro do harness `hacker-etico-ambiente`.

A arquitetura segue o **padrao operacional do `.hacker/`**:
- Agent contract → procedure executavel
- Template → formato de saida
- RAG → conhecimento de seguranca
- Gate → protecao pre-requisito
- Ledger → registro append-only

**Nao inclui implementacao de ferramentas**: nenhum script de scan, nenhum binario, nenhum container sera criado neste ciclo. Apenas o artefato de arquitetura (contrato de agente, regra, extensao de RAG/template/gate).

**Spec de origem**: `.opencode/specs/SPEC_003_web-app-scan-report.md`

## CATEGORY

Infra | Docs | Harness Operacional (`.hacker/` + uma regra em `.opencode/rules/`)

## PROBLEMA

- O harness operacional (`.hacker/`) possui agentes para red-team, blue-team, pentest e scraping, mas **nao tem** agente especializado em scan web automatizado (ZAP + Nuclei) com geracao de relatorio estruturado.
- Lacunas identificadas nos arquivos existentes (ver SPEC_003, seção PROBLEM).

## CONTEXT

- Arquitetura de duas camadas (AGENTS.md Seção 13): `.opencode/` = desenvolvimento; `.hacker/` = operacional.
- Estado atual do `.hacker/`: 14 arquivos existentes (verificado via `find`).
- Arquivos que precisam ser criados: `.opencode/rules/hacker-web-scan-report.md`, `.hacker/agentes/web-scanner/AGENTE.md`, `.hacker/reports/` (diretorio).
- Arquivos que precisam ser estendidos: `.hacker/rag/README-RAG.md`, `.hacker/gate/GATE-DE-PROTECAO.md`, `.hacker/templates/TEMPLATE-RELATORIO.md`, `.hacker/orquestrador/ORQUESTRADOR.md`, `.hacker/agentes/red-team/AGENTE.md`.
- Arquivos que precisam ser atualizados: `.hacker/README.md`, `.hacker/ledger/operacoes.md`.

## ARQUIVOS AFETADOS

### CREATE (novos)
- `.opencode/rules/hacker-web-scan-report.md` (regra de comportamento AI, unica excecao em `.opencode/`)
- `.hacker/agentes/web-scanner/AGENTE.md` (contrato de agente operacional)
- `.hacker/reports/` (diretorio de saida para relatorios operacionais)

### MODIFY (extensoes)
- `.hacker/rag/README-RAG.md` (adicionar fontes de conhecimento para scan web: OWASP Testing Guide, NVD)
- `.hacker/gate/GATE-DE-PROTECAO.md` (adicionar ferramentas de DAST web na seção "O que EXIGE gate")
- `.hacker/templates/TEMPLATE-RELATORIO.md` (adicionar campos de finding com CVSS v3.1 + CWE)
- `.hacker/orquestrador/ORQUESTRADOR.md` (adicionar linha de roteamento para web-scanner)
- `.hacker/agentes/red-team/AGENTE.md` (adicionar DAST web ao escopo permitido, opcional)
- `.hacker/README.md` (atualizar mapa de modulos com web-scanner)
- `.hacker/ledger/operacoes.md` (adicionar entrada de SPEC_003)

### MODIFY (registro)
- `.opencode/ledger/trust-ledger.md` (entrada de plano criado)

## DEPENDENCIAS ENTRE TAREFAS

| Tarefa | Depende de | Tipo |
|---|---|---|
| T1 (regra) | nenhuma | independente |
| T2 (agente web-scanner) | nenhuma | independente |
| T3 (extensão RAG) | nenhuma | independente |
| T4 (extensão gate) | nenhuma | independente |
| T5 (extensão template) | nenhuma | independente |
| T6 (extensão orquestrador) | T2 (precisa do agente existente para referenciar) | depende de T2 |
| T7 (extensão red-team) | nenhuma | independente |
| T8 (diretorio reports) | nenhuma | independente |
| T9 (atualizar README) | T2 (precisa do agente listado) | depende de T2 |
| T10 (entrada ledger) | todas as anteriores | depende de todas |
| T11 (verificação final) | todas as anteriores | depende de todas |

---

## TASKS ATOMICAS

### T1: Criar `.opencode/rules/hacker-web-scan-report.md`

**Arquivo**: `.opencode/rules/hacker-web-scan-report.md` (CREATE)

**Depende de**: nenhuma

**Verificacao**:
```bash
test -f .opencode/rules/hacker-web-scan-report.md && grep -q "hacker-web-scan-report" .opencode/rules/hacker-web-scan-report.md
```

**Descricao Detalhada**:
Criar a unica regra de comportamento AI que vive em `.opencode/` (exceto as 8 regras existentes). Esta regra define como o agente DEVE se comportar ao gerar relatórios web. Conteudo baseado na SPEC_003 seção R1 (1.1 a 1.7): escopo e autorizacao do scan, protecao pré-requisito (verificar-vazamento.sh GOOD), formato de saida de scan (ZAP JSON, Nuclei JSONL), estrutura obrigatoria do relatorio tecnico (6 seções: Cabeçalho, Execução, Escopo, Metodologia, Findings, Conclusão), classificação de severidade com CVSS v3.1, registro no ledger operacional, anti-invencao (F6). Nao duplicar regras existentes em `hacker-pentest-harness-execution.md` nem `hacker-epistemic-safety.md`. Sem first person. Sem placeholders. PT-BR.

**Implementacao**:
Conteudo markdown seguindo o padrao das regras existentes em `.opencode/rules/` (ex.: `hacker-pentest-harness-execution.md`). Estrutura:
- Cabecalho com tipo (regra de comportamento AI)
- Seção 1.1: Escopo e autorização do scan
- Seção 1.2: Proteção pré-requisito (verificar-vazamento.sh GOOD)
- Seção 1.3: Formato de saída de scan (ZAP → JSON, Nuclei → JSONL)
- Seção 1.4: Estrutura obrigatória do relatório técnico (6 seções)
- Seção 1.5: Classificação de severidade e CVSS v3.1
- Seção 1.6: Registro no Ledger Operacional
- Seção 1.7: Anti-invenção (F6)

---

### T2: Criar `.hacker/agentes/web-scanner/AGENTE.md`

**Arquivo**: `.hacker/agentes/web-scanner/AGENTE.md` (CREATE)

**Depende de**: nenhuma

**Verificacao**:
```bash
mkdir -p .hacker/agentes/web-scanner && test -f .hacker/agentes/web-scanner/AGENTE.md && grep -q "web-scanner\|Web Scanner" .hacker/agentes/web-scanner/AGENTE.md
```

**Descricao Detalhada**:
Criar o contrato de agente operacional especializado em scan web e geracao de relatorio estruturado. Segue o padrao dos agentes existentes em `.hacker/agentes/` (ex.: `red-team/AGENTE.md`, `pentest/AGENTE.md`). Conteudo baseado na SPEC_003 seção R2 (2.1 a 2.7): missao (ZAP DAST + Nuclei, parse JSON, enriquecimento CVSS/CWE, relatorio OWASP/PTES), pre-requisito (GATE GOOD + escopo formal), escopo permitido (ZAP API `localhost:8080`, Nuclei `-jsonl`, parse/consolidacao JSON, enriquecimento, geracao de relatorio), o que NÃO fazer (alterar escopo, explorar classe C sem confirmar, interagir com hosts fora do lab, registrar IP real, citacao sem verificacao F6, executar sem gate), fluxo de execução (10 passos de receber missao ao reportar ao orquestrador), formato do relatorio (campos da tabela da SPEC_003), relação com agentes existentes (ORQUESTRADOR, revisor, implementador). Sem first person. Sem placeholders. PT-BR.

**Implementacao**:
Estrutura markdown seguindo o padrao de `.hacker/agentes/pentest/AGENTE.md`:
- Cabecalho com adaptacao de fontes
- Missao
- Pre-requisito (GATE + escopo)
- Escopo permitido (ZAP, Nuclei, parse, enriquecimento, relatorio)
- O que NÃO fazer (classe C / invariante 8)
- Fluxo de execução (10 passos)
- Formato do relatorio (tabela com OPERACAO-ID, DATA, AGENTE, ESCOPO, Vetor, Resultado, Evidencia, Confiabilidade, Referencia, Hash, Findings)
- Relação com agentes existentes

---

### T3: Estender `.hacker/rag/README-RAG.md` com fontes de scan web

**Arquivo**: `.hacker/rag/README-RAG.md` (MODIFY)

**Depende de**: nenhuma

**Verificacao**:
```bash
grep -q "OWASP Testing Guide\|NVD" .hacker/rag/README-RAG.md
```

**Descricao Detalhada**:
Adicionar ao existing `.hacker/rag/README-RAG.md`:
1. Nova entrada na tabela "Hierarquia de fontes do harness" (seção "Conhecimento de seguranca"): incluir OWASP Testing Guide e NVD como fontes de conhecimento para scan web.
2. Nova seção ou expansao da regra F6: "Consulta obrigatoria a OWASP Testing Guide + NVD antes de gerar relatório de scan web" (regra F6 para scan web).
Nao alterar a estrutura existente; apenas adicionar conteudo. Sem first person. Sem placeholders. PT-BR.

---

### T4: Estender `.hacker/gate/GATE-DE-PROTECAO.md` com ferramentas de DAST web

**Arquivo**: `.hacker/gate/GATE-DE-PROTECAO.md` (MODIFY)

**Depende de**: nenhuma

**Verificacao**:
```bash
grep -q "zap-cli\|nuclei" .hacker/gate/GATE-DE-PROTECAO.md
```

**Descricao Detalhada**:
Adicionar à seção "O que EXIGE gate" do existing `.hacker/gate/GATE-DE-PROTECAO.md`:
- `zap-cli`, `zap-api-scan.py`, `java -jar zap.jar` (OWASP ZAP)
- `nuclei`, `httpx` (Nuclei scanner)
- Qualquer ferramenta de DAST que saia da maquina
Nao alterar seções existentes; apenas adicionar items na lista. Sem first person. Sem placeholders. PT-BR.

---

### T5: Estender `.hacker/templates/TEMPLATE-RELATORIO.md` com campos de vulnerabilidade web

**Arquivo**: `.hacker/templates/TEMPLATE-RELATORIO.md` (MODIFY)

**Depende de**: nenhuma

**Verificacao**:
```bash
grep -q "CVSS\|CWE" .hacker/templates/TEMPLATE-RELATORIO.md
```

**Descricao Detalhada**:
Adicionar à seção "### Confiabilidade e Referencia" do existing `.hacker/templates/TEMPLATE-RELATORIO.md`:
- Campos de finding: ID, título, severidade (CVSS v3.1 score), CWE, URL, evidência técnica, impacto, recomendação
- Tabela de findings por severidade (Critical → Informational)
A seção "Nota de IP" existente deve ser preservada. Sem first person. Sem placeholders. PT-BR.

---

### T6: Estender `.hacker/orquestrador/ORQUESTRADOR.md` com roteamento para web-scanner

**Arquivo**: `.hacker/orquestrador/ORQUESTRADOR.md` (MODIFY)

**Depende de**: T2 (agente web-scanner criado)

**Verificacao**:
```bash
grep -q "web-scanner" .hacker/orquestrador/ORQUESTRADOR.md
```

**Descricao Detalhada**:
Adicionar à tabela "Roteamento por agente" do existing `.hacker/orquestrador/ORQUESTRADOR.md`:
- `Scan de aplicações web (ZAP + Nuclei) | web-scanner`
Nao alterar a estrutura da tabela existente; apenas adicionar uma linha. Sem first person. Sem placeholders. PT-BR.

---

### T7: Estender `.hacker/agentes/red-team/AGENTE.md` com DAST web (opcional)

**Arquivo**: `.hacker/agentes/red-team/AGENTE.md` (MODIFY)

**Depende de**: nenhuma

**Verificacao**:
```bash
grep -q "DAST\|ZAP\|Nuclei" .hacker/agentes/red-team/AGENTE.md
```

**Descricao Detalhada**:
Adicionar à seção "Escopo permitido" do existing `.hacker/agentes/red-team/AGENTE.md`:
- Ações de DAST web: ZAP API scan, Nuclei templates scan (complementar às ações de rede existentes: nmap, masscan, curl)
Esta tarefa é OPCIONAL (conforme SPEC_003 seção R7). Se o Fernando não autorizar, registrar como pendencia no trust-ledger. Sem first person. Sem placeholders. PT-BR.

---

### T8: Criar `.hacker/reports/` diretório

**Arquivo**: `.hacker/reports/` (CREATE, diretorio)

**Depende de**: nenhuma

**Verificacao**:
```bash
mkdir -p .hacker/reports && test -d .hacker/reports && echo "diretorio criado"
```

**Descricao Detalhada**:
Criar o diretorio `.hacker/reports/` para receber os relatórios operacionais gerados pelo agente web-scanner. Nao criar arquivo README dentro do diretorio (o README do `.hacker/` ja documenta os diretorios). Este é um diretorio vazio que sera populado pelo agente web-scanner durante operacoes.

---

### T9: Atualizar `.hacker/README.md` com web-scanner no mapa de módulos

**Arquivo**: `.hacker/README.md` (MODIFY)

**Depende de**: T2 (agente web-scanner listado)

**Verificacao**:
```bash
grep -q "web-scanner\|web scanner" .hacker/README.md
```

**Descricao Detalhada**:
Atualizar `.hacker/README.md`:
1. Adicionar `web-scanner` à lista de agentes na seção "Mapa de modulos" (árvore ASCII): `.hacker/agentes/` deve listar red-team, blue-team, pentest, scraping, **web-scanner**.
2. Adicionar breve descrição do web-scanner na seção "Como orquestrar" ou em notas.
3. Opcionalmente adicionar referência à SPEC_003 na seção "Referencias".
Nao alterar a estrutura existente; apenas adicionar conteúdo. Sem first person. Sem placeholders. PT-BR.

---

### T10: Atualizar `.hacker/ledger/operacoes.md` com entrada de SPEC_003

**Arquivo**: `.hacker/ledger/operacoes.md` (MODIFY)

**Depende de**: todas as tarefas anteriores

**Verificacao**:
```bash
grep -q "SPEC_003\|web-scan" .hacker/ledger/operacoes.md
```

**Descricao Detalhada**:
Adicionar uma entrada ao arquivo `.hacker/ledger/operacoes.md` (append-only, na tabela existente):
- DATA: 2026-09-11
- OPERACAO-ID: OP-20260911-001
- AGENTE: orquestrador
- ESCOPO: setup
- GATE: N/A (operacao de docs)
- VETOR: Criacao do agente web-scanner e extensoes de gate/RAG/template/orquestrador
- RESULTADO: SPEC_003 implementada via PLAN_003
- BASE: PLAN_003_web-app-scan-report.md
- HASH: SHA-256 do conteudo
Sem IP real. Sem first person. PT-BR.

---

### T11: Registrar entrada no Trust Ledger

**Arquivo**: `.opencode/ledger/trust-ledger.md` (MODIFY)

**Depende de**: todas as tarefas anteriores

**Verificacao**:
```bash
grep -q "PLAN_003" .opencode/ledger/trust-ledger.md
```

**Descricao Detalhada**:
Adicionar entrada ao Trust Ledger (append-only):
```
[2026-09-11] | ciclo=PLAN_003 | skill=hacker-writing-plans | evento=plan-created | resultado=PROSSEGUIR | base=arquivo .opencode/plans/PLAN_003_web-app-scan-report.md gravado com tarefas atomicas; verificacao por atributo: ls (arquivo presente), grep em/en-dash (zero), grep IP literal (zero)
```
Sem IP real. Sem first person. Sem placeholders. PT-BR.

---

### T12: Verificacao final por atributo (suite do perfil)

**Arquivos**: N/A (execucao global)

**Depende de**: todas as tarefas anteriores

**Verificacao**:
```bash
git diff --check 2>/dev/null || true
grep -rlnE '—|–' .opencode/rules/hacker-web-scan-report.md .hacker/agentes/web-scanner/AGENTE.md .hacker/rag/README-RAG.md .hacker/gate/GATE-DE-PROTECAO.md .hacker/templates/TEMPLATE-RELATORIO.md .hacker/orquestrador/ORQUESTRADOR.md .hacker/agentes/red-team/AGENTE.md .hacker/README.md .hacker/ledger/operacoes.md 2>/dev/null; echo "esperado: vazio"
grep -rlnE '([0-9]{1,3}\.){3}[0-9]{1,3}' .opencode/rules/hacker-web-scan-report.md .hacker/agentes/web-scanner/AGENTE.md .hacker/rag/README-RAG.md .hacker/gate/GATE-DE-PROTECAO.md .hacker/templates/TEMPLATE-RELATORIO.md .hacker/orquestrador/ORQUESTRADOR.md .hacker/agentes/red-team/AGENTE.md .hacker/README.md .hacker/ledger/operacoes.md 2>/dev/null; echo "esperado: vazio (fora URLs citadas)"
grep -rln 'TODO\|TBD' .opencode/rules/hacker-web-scan-report.md .hacker/agentes/web-scanner/AGENTE.md 2>/dev/null; echo "esperado: vazio"
test -f .opencode/rules/hacker-web-scan-report.md && test -f .hacker/agentes/web-scanner/AGENTE.md && test -d .hacker/reports && echo "TODOS OS ARQUIVOS CRIADOS"
```

**Descricao Detalhada**:
Rodar suite completa do perfil sobre todos os arquivos tocados neste ciclo:
- `git diff --check`: sem whitespace errors.
- `grep -rlnE '—|–'`: vazio (sem em dash ou en dash fora de documentation-style)
- `grep -rlnE '([0-9]{1,3}\.){3}[0-9]{1,3}'`: vazio (sem IP real).
- `grep -rln 'TODO|TBD'`: vazio (sem placeholders).
- Conferir que todos os 3 arquivos novos foram criados e os 5 arquivos estendidos contem o conteúdo esperado.
- Regras existentes (hacker-pentest-harness-execution.md, hacker-epistemic-safety.md) NAO foram duplicadas na nova regra.

---

## RESULTADO ESPERADO

Após aprovação e execução deste plano:
1. `.opencode/rules/hacker-web-scan-report.md` criado (regra AI de comportamento para scan web).
2. `.hacker/agentes/web-scanner/AGENTE.md` criado (contrato de agente operacional).
3. `.hacker/reports/` criado (diretorio de saida para relatórios).
4. `.hacker/rag/README-RAG.md` estendido com fontes de scan web (OWASP Testing Guide, NVD).
5. `.hacker/gate/GATE-DE-PROTECAO.md` estendido com ferramentas de DAST web (ZAP, Nuclei).
6. `.hacker/templates/TEMPLATE-RELATORIO.md` estendido com campos de vulnerabilidade web (CVSS v3.1, CWE).
7. `.hacker/orquestrador/ORQUESTRADOR.md` estendido com roteamento para web-scanner.
8. `.hacker/agentes/red-team/AGENTE.md` estendido com DAST web (opcional).
9. `.hacker/README.md` atualizado com web-scanner no mapa de módulos.
10. `.hacker/ledger/operacoes.md` com nova entrada de SPEC_003.
11. Trust Ledger atualizado com entrada deste plano.
12. Suite de verificacao por atributo PASS em todos os arquivos tocados.

## ACEITACAO

- [ ] Todos os arquivos criados seguem o padrão existente do `.hacker/`.
- [ ] A regra em `.opencode/rules/` é uma restrição de comportamento AI (como as outras 8 rules).
- [ ] O agente em `.hacker/agentes/` segue o padrão dos agentes existentes (red-team, blue-team, pentest, scraping).
- [ ] Os templates, gate, RAG e orquestrador existentes foram estendidos (não duplicados).
- [ ] Nenhum componente operacional foi colocado em `.opencode/` (exceto a regra AI).
- [ ] A estrutura do relatório técnico segue o padrão OWASP/PTES consolidado do mercado.
- [ ] A regra `hacker-web-scan-report.md` não duplica regras já existentes em `hacker-pentest-harness-execution.md` nem `hacker-epistemic-safety.md`.
- [ ] O `.hacker/README.md` é atualizado para incluir o novo agente web-scanner no mapa de modulos.
- [ ] Suite de verificacao por atributo PASS (zero em/en dash, zero IP literal, zero placeholders).
