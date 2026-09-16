# SPEC_003: Scan de Aplicações Web + Geração de Relatório Técnico Estruturado

- data: 2026-09-11
- ciclo: SPEC_003 (REESCRITA — correção de posicionamento arquitetural)
- status: PROSSEGUIR (P1)
- categoria: Docs (artefato de arquitetura de capability, sem implementacao de ferramentas)
- **REVISAO**: Esta SPEC foi reescrita para corrigir posicionamento incorreto de camada. A versão anterior posicionava componentes operacionais em `.opencode/` (camada de desenvolvimento), violando a arquitetura de duas camadas definida em SPEC_001. Todos os componentes operacionais agora vivem em `.hacker/`.

## REQUEST

Projetar a capability de **scan de aplicações web automatizado + geração de relatório técnico estruturado** dentro do harness `hacker-etico-ambiente`. A capability permite ao Fernando (ou agentes) executar scans automatizados de aplicações web (ZAP API + Nuclei), parsear resultados em JSON estruturado, enriquecer com CVSS/CWE, e gerar relatórios técnicos no padrão OWASP/PTES.

A arquitetura segue o **padrão operacional do `.hacker/`** (não o padrão SDD do `.opencode/`):
- Agent contract → procedure executável
- Template → formato de saída
- RAG → conhecimento de segurança
- Gate → proteção pré-requisito
- Ledger → registro append-only

**Não inclui implementação de ferramentas**: nenhum script de scan, nenhum binário, nenhum container será criado neste ciclo. Apenas o artefato de arquitetura (contrato de agente, regra, extensão de RAG/template/gate) que orquestra ferramentas existentes.

## CATEGORY

Infra | Docs | Harness Operacional (`.hacker/`)

## PROBLEM

- Atual: o harness operacional (`.hacker/`) possui agentes para red-team, blue-team, pentest e scraping, mas **não tem** um agente especializado em scan web automatizado (ZAP + Nuclei) com geração de relatório estruturado.
- Esperado: capability completa de scanner web (ZAP + Nuclei), parse de JSON estruturado, enriquecimento com CVSS/CWE, e relatório técnico no padrão OWASP/PTES, orquestrada por agente especializado dentro de `.hacker/`.
- Lacunas identificadas nos agentes existentes:
  1. `.hacker/agentes/red-team/AGENTE.md` menciona "scan" mas apenas no contexto de nmap/masscan/curl — não inclui ZAP API ou Nuclei templates.
  2. `.hacker/agentes/pentest/AGENTE.md` cobre PTES mas não inclui DAST automatizado com ZAP/Nuclei.
  3. `.hacker/templates/TEMPLATE-RELATORIO.md` não tem estrutura de relatório técnico de vulnerabilidades web (sem campos CVSS v3.1, CWE, URL, evidência técnica).
  4. `.hacker/rag/README-RAG.md` não inclui fontes de conhecimento específicas para scan web (OWASP Testing Guide, NVD).
  5. `.hacker/gate/GATE-DE-PROTECAO.md` não lista explicitamente ferramentas de DAST web (ZAP, Nuclei) na seção "O que EXIGE gate".

## CONTEXT

### Arquitetura de duas camadas (documentada em AGENTS.md Seção 10, mas SEM definição explícita)

**A fronteira entre `.opencode/` e `.hacker/` é a separação mais importante do harness. AGENTS.md NÃO a define explicitamente.** Esta SPEC a define como contexto obrigatório para evitar erros recorrentes:

| Camada | Diretório | Função | O que vive lá |
|---|---|---|---|
| **Desenvolvimento / Governança** | `.opencode/` | Desenvolver e evoluir o harness | rules, skills, commands, agents (SDD), specs, plans, RAG de método, trust-ledger |
| **Operacional** | `.hacker/` | **O produto que o Fernando opera** | gate, orquestrador, agentes, memoria, ledger, rag de segurança, templates |

**Evidência literal:**
- `.hacker/README.md` (linha 3): "Manifesto do harness operacional. **Complementa o harness de desenvolvimento em `.opencode/`**."
- `.hacker/gate/GATE-DE-PROTECAO.md` (linha 28): lista `.hacker/` e `.opencode/` como escopo protegido — são pastas separadas.
- `.hacker/rag/README-RAG.md` (prioridade 4): referencia `.opencode/rules/` como fonte de regras/método — `.opencode/` é fonte de método para `.hacker/`.
- SPEC_001 Requirement 10 (linha 79-80): "as operacoes de melhoria do proprio harness hacker seguem o pipeline SDD (**.opencode/**); o **hacker hacker e o 'produto' operado pelo Fernando**."

### Fontes consultadas (RAG interno + pesquisa GitHub)

**Soluções maduras de mercado analisadas:**
1. **OWASP ZAP** — API REST (`localhost:8080`), `zap-api-scan.py`, Docker container. Saída: XML/JSON/HTML/HAR. Padrão ouro para automação de DAST.
2. **Nuclei** — Scanner de templates YAML, saída JSON (`-jsonl`, `-je`). Amplamente usado em bug bounty.
3. **NucleiReporter** (python) — Parse de JSON do Nuclei → Markdown com CVSS/CWE/metações. Prova o padrão JSON→relatório.
4. **ZEVS** — Scanner async (httpx) com CVSS v3.1 calculator + HTML reports.
5. **Bug Bounty Report Generator** — Parse de Nuclei/Dalfox output → HackerOne-formatted reports.
6. **Pentelligence** — Claude AI agent loop que lê output de scanner, categoriza, gera relatório.
7. **autopentest-ai** — Roles especializados (Scout/Analyzer/Exploiter/Reporter) com quality gates.
8. **pentest-report-skill** — Parsers → draft findings → compliance check → render.
9. **VirtueWebAgent** — Agente autônomo para web app pentest com reflexão.

**Padrão consolidado do mercado:**
- **Scan → JSON estruturado → Parse/Enrich → Render Report** é o pipeline unânime.
- Nuclei JSON é o formato intermediário mais versátil (JSONL/JSON).
- ZAP XML é convertido para JSON via `zap-cli` ou parse manual.
- CVSS v3.1 + CWE são os padrões de enriquecimento.
- Relatórios seguem estrutura: Cabeçalho → Execução → Escopo → Metodologia → Findings → Conclusão.

### Estado atual do `.hacker/` no filesystem

Todos os seguintes arquivos existem no filesystem (verificado via `find`):
- `.hacker/README.md` — manifesto operacional
- `.hacker/gate/GATE-DE-PROTECAO.md` — gate Dark-Moon
- `.hacker/orquestrador/ORQUESTRADOR.md` — supervisor
- `.hacker/agentes/red-team/AGENTE.md` — contrato red-team
- `.hacker/agentes/blue-team/AGENTE.md` — contrato blue-team
- `.hacker/agentes/pentest/AGENTE.md` — contrato pentest (PTES)
- `.hacker/agentes/scraping/AGENTE.md` — contrato scraping
- `.hacker/memoria/MEMORIA.md` — 3 camadas com Memory Guard
- `.hacker/ledger/LEDGER-OPERACOES.md` — formato do ledger
- `.hacker/ledger/operacoes.md` — ledger vazio (append-only)
- `.hacker/rag/README-RAG.md` — hierarquia de fontes
- `.hacker/templates/TEMPLATE-OPERACAO.md` — template de operacao
- `.hacker/templates/TEMPLATE-CONTRATO.md` — template de handoff
- `.hacker/templates/TEMPLATE-RELATORIO.md` — template de relatorio

### Regras existentes aproveitadas (NÃO duplicar)

- `.hacker/gate/GATE-DE-PROTECAO.md` → cobre proteção pré-requisito, lista de ações que exigem gate, privacidade Dark-Moon. **Já existe.**
- `.opencode/rules/hacker-pentest-harness-execution.md` → cobre escopo primeiro, proteção pre-requisito, anti-censura, vetores non-routable, classe C. **Já existe.**
- `.opencode/rules/hacker-epistemic-safety.md` → cobre anti-invenção, F6. **Já existe.**
- `.opencode/rules/hacker-documentation-style.md` → cobre formatação de documentação geral. Pode ser extendida.
- `.hacker/agentes/pentest/AGENTE.md` → cobre PTES mas não DAST automatizado. **Extendível.**
- `.hacker/agentes/red-team/AGENTE.md` → cobre scan de rede mas não DAST web. **Extendível.**

## REQUIREMENTS

### R1 — Nova Regra de Comportamento AI: `.opencode/rules/hacker-web-scan-report.md`

Criar `.opencode/rules/hacker-web-scan-report.md` — a ÚNICA exceção que vive em `.opencode/`, porque é uma **restrição de comportamento do modelo de IA** (como as outras 8 rules). Esta regra define como o agente DEVE se comportar ao gerar relatórios web.

**1.1 Escopo e autorização do scan**
- Todo scan web requer escopo formal definido (alvo, URL, limite de tempo) pelo Fernando.
- Escopo fora de escopo formal = nunca executar (regra de segurança, não censura).
- Anti-censura mantida: dentro do escopo autorizado E protegido, o agente não recusa analisar ou executar vetores web.

**1.2 Proteção pré-requisito**
- Antes de QUALQUER scan de rede: `bash ~/opsec/scripts/verificar-vazamento.sh` GOOD.
- Se GOOD → prossegue. Se não → PARA e reporta.
- Scan nunca roda diretamente no host sem cadeia.

**1.3 Formato de saída de scan**
- ZAP: saída XML convertida para JSON via `zap-cli` ou parse manual.
- Nuclei: saída JSON via `-jsonl` ou `-je` (formato intermediário obrigatório).
- Todo scan deve gerar JSON estruturado como artefato intermediário.

**1.4 Estrutura obrigatória do relatório técnico**
O relatório gerado deve seguir esta estrutura:
```
1. Cabeçalho (data, alvo, escopo, agente, ferramenta)
2. Execução (metodologia, ferramentas usadas, parâmetros)
3. Escopo (definição do que foi e não foi scaneado)
4. Metodologia (approach, fases)
5. Findings (por severidade: Critical, High, Medium, Low, Informational)
   - Cada finding: ID, título, severidade (CVSS v3.1), CWE, URL, evidência, impacto, recomendação
6. Conclusão (resumo geral, riscos residuais, próximos passos)
```

**1.5 Classificação de severidade e CVSS v3.1**
- Toda vulnerabilidade encontrada deve ter CVSS v3.1 score (base, temporal, environmental se aplicável).
- Se o scanner não fornecer CVSS, o agente deve consultar fonte confiável (NVD) ou classificar conservadoramente.
- CWE obrigatório para cada finding.

**1.6 Registro no Ledger Operacional**
- Cada execução de scan gera entrada em `.hacker/ledger/operacoes.md` com: data, alvo, escopo, ferramentas, gate (GOOD/bloqueado), resultados resumidos.

**1.7 Anti-invenção (F6)**
- Nunca fabricar findings. Se o scan não encontra nada, reporte "0 findings detectados" com evidência literal da saída do scanner.
- Nunca inventar CVSS/CWE sem fonte. Se não pode atribuir CVSS exato, classificar como "unclassified - pending verification".

### R2 — Novo Agente Operacional: `.hacker/agentes/web-scanner/AGENTE.md`

Criar `.hacker/agentes/web-scanner/AGENTE.md` como contrato de agente especializado em scan web e geração de relatório estruturado. Segue o padrão dos agentes existentes em `.hacker/agentes/`.

**2.1 Missão**
Execução automatizada de scan de aplicações web (OWASP ZAP DAST + Nuclei templates), parse de resultados JSON, enriquecimento com CVSS v3.1/CWE, e geração de relatório técnico estruturado no padrão OWASP/PTES.

**2.2 Pre-requisito**
- GATE DE PROTECAO GOOD (`bash ~/opsec/scripts/verificar-vazamento.sh`) antes de CADA acao de rede. Sem GOOD = NAO execute nada que toque rede.
- Escopo formal definido pelo Fernando (alvo, URL, limite de tempo).

**2.3 Escopo permitido**
- Aplicações web em alvos autorizados (labs HTB/THM/DVWA/VulnHub, pesquisas com escopo formal).
- ZAP API scan (`localhost:8080` ou container Docker).
- Nuclei scan com templates relevantes (`-jsonl` output).
- Parse e consolidação JSON.
- Enriquecimento CVSS v3.1/CWE.
- Geração de relatório técnico estruturado.

**2.4 O que NÃO fazer**
- Alterar o escopo da operacao por conta propria.
- Explorar vulnerabilidade destrutiva/irreversivel sem confirmar Fernando (classe C).
- Interagir com hosts fora do lab autorizado.
- Registrar IP real de origem em relatorio ou ledger.
- Citar fonte (CVE, ferramenta) sem verificacao (F6).
- Executar scan sem gate GOOD.

**2.5 Fluxo de execução**
1. Recebe do orquestrador: alvo, escopo, limite de tempo (via `templates/TEMPLATE-OPERACAO.md`).
2. Valida gate: `bash ~/opsec/scripts/verificar-vazamento.sh` GOOD.
3. Executa ZAP scan (se disponível) → exporta JSON.
4. Executa Nuclei scan → exporta JSONL.
5. Consolida resultados em JSON estruturado unificado.
6. Parse e enriquecimento: extrai fields, mapeia CVSS/CWE, deduplica.
7. Gera relatório técnico estruturado (seção 1.4 de R1).
8. Salva relatório em `.hacker/reports/`.
9. Registra entrada em `.hacker/ledger/operacoes.md`.
10. Reporta ao orquestrador.

**2.6 Formato do relatório**
Usar `templates/TEMPLATE-RELATORIO.md` estendido com campos de vulnerability web:

| Campo | Conteúdo |
|---|---|
| OPERACAO-ID | OP-YYYYMMDD-NNN |
| DATA | YYYY-MM-DD HH:MM |
| AGENTE | web-scanner |
| ESCOPO | [ lab autorizado ] |
| Vetor | [ descrição do vetor/alvo ] |
| Resultado | [ descrição detalhada ] |
| Evidencia | [ comandos reais + saida literal ] |
| Confiabilidade | alta / media / baixa |
| Referencia | [OWASP / MITRE / NVD, com citacao, F6] |
| Hash | SHA-256 (primeiros 16 chars) |
| Findings | [ tabela por severidade com CVSS v3.1 + CWE ] |

**2.7 Relação com agentes existentes**
- `.hacker/orquestrador/ORQUESTRADOR.md` (Tabela de roteamento): adicionar linha `Scan de aplicações web (ZAP + Nuclei) | web-scanner`.
- `.hacker/orquestrador/ORQUESTRADOR.md` pode despachar `web-scanner` como agente operacional (via `templates/TEMPLATE-CONTRATO.md`).
- `.hacker/agentes/revisor/AGENTE.md` pode revisar o relatório gerado.
- `.hacker/agentes/implementador/AGENTE.md` pode implementar correções baseadas no relatório.

### R3 — Extensão do RAG: `.hacker/rag/README-RAG.md`

Adicionar ao existing `.hacker/rag/README-RAG.md`:
- **Nova prioridade**: fontes de conhecimento para scan web: OWASP Testing Guide, OWASP Top 10 (para referência de classes de vulnerabilidade), NVD (para CVSS/CWE mapping).
- **Regra F6 para scan web**: consulta obrigatoria a OWASP Testing Guide + NVD antes de gerar relatório.

### R4 — Extensão do Gate: `.hacker/gate/GATE-DE-PROTECAO.md`

Adicionar à seção "O que EXIGE gate" do existing `.hacker/gate/GATE-DE-PROTECAO.md`:
- `zap-cli`, `zap-api-scan.py`, `java -jar zap.jar` (OWASP ZAP)
- `nuclei`, `httpx` (Nuclei scanner)
- Qualquer ferramenta de DAST que saia da maquina

### R5 — Extensão do Template de Relatório: `.hacker/templates/TEMPLATE-RELATORIO.md`

Adicionar à seção "### Confiabilidade e Referencia" do existing `.hacker/templates/TEMPLATE-RELATORIO.md`:
- Campos de finding: ID, título, severidade (CVSS v3.1 score), CWE, URL, evidência técnica, impacto, recomendação
- Tabela de findings por severidade (Critical → Informational)

### R6 — Extensão do Orquestrador: `.hacker/orquestrador/ORQUESTRADOR.md`

Adicionar à tabela "Roteamento por agente" do existing `.hacker/orquestrador/ORQUESTRADOR.md`:
- `Scan de aplicações web (ZAP + Nuclei) | web-scanner`

### R7 — Extensão do Agente Red-Team (opcional): `.hacker/agentes/red-team/AGENTE.md`

Adicionar à seção "Escopo permitido" do existing `.hacker/agentes/red-team/AGENTE.md`:
- Ações de DAST web: ZAP API scan, Nuclei templates scan (complementar às ações de rede existentes: nmap, masscan, curl)

## ONDE OS NOVOS COMPONENTES VIVEM (resumo)

| Componente | Local | Tipo |
|---|---|---|
| Regra AI (comportamento) | `.opencode/rules/hacker-web-scan-report.md` | Regra de comportamento do modelo |
| Agente operacional | `.hacker/agentes/web-scanner/AGENTE.md` | Contrato de agente |
| Extensão RAG | `.hacker/rag/README-RAG.md` | Conhecimento de segurança |
| Extensão Gate | `.hacker/gate/GATE-DE-PROTECAO.md` | Proteção operacional |
| Extensão Template | `.hacker/templates/TEMPLATE-RELATORIO.md` | Formato de saída |
| Extensão Orquestrador | `.hacker/orquestrador/ORQUESTRADOR.md` | Roteamento |
| Relatórios operacionais | `.hacker/reports/` (diretorio a criar) | Artefato de saída |
| Ledger | `.hacker/ledger/operacoes.md` | Registro append-only |

**O que NÃO vai em `.opencode/`:**
- NENHUM agente operacional em `.opencode/agents/` (os agents lá são do SDD pipeline: orquestrador, implementador, revisor, documentador)
- NENHUMA skill operacional em `.opencode/skills/` (as skills lá são procedimentos de desenvolvimento)
- NENHUM diretório de relatórios em `.opencode/` (relatórios operacionais vão em `.hacker/reports/`)

## NÃO FAÇO

- **Não implemento ferramentas**: nenhum script de scan, nenhum binário, nenhum container será criado.
- **Não coloco componentes operacionais em `.opencode/`**: `.opencode/` é para desenvolvimento do harness, não para execução de operações.
- **Não modifico regras existentes em `.opencode/rules/`**: apenas adiciono a nova rule `hacker-web-scan-report.md`.
- **Não modifico `.opencode.json`**: a nova regra `.opencode/rules/hacker-web-scan-report.md` será adicionada às instructions se o Fernando aprovar.
- **Não crio agentes em `.opencode/agents/`**: o agente web-scanner vai em `.hacker/agentes/`.
- **Não implemento o pipeline de execução**: apenas o artefato arquitetural (SPEC).

## RESULTADO ESPERADO

Após aprovação deste SPEC:
1. Arquivo `.opencode/rules/hacker-web-scan-report.md` criado (regra AI).
2. Arquivo `.hacker/agentes/web-scanner/AGENTE.md` criado (contrato de agente operacional).
3. `.hacker/rag/README-RAG.md` estendido com fontes de scan web.
4. `.hacker/gate/GATE-DE-PROTECAO.md` estendido com ferramentas de DAST web.
5. `.hacker/templates/TEMPLATE-RELATORIO.md` estendido com campos de vulnerability web.
6. `.hacker/orquestrador/ORQUESTRADOR.md` estendido com roteamento para web-scanner.
7. `.hacker/reports/` criado (diretorio de saida para relatórios operacionais).
8. `.hacker/ledger/operacoes.md` com nova entrada de SPEC.
9. Trust Ledger atualizado com entrada desta spec.

## ACEITAÇÃO

- [ ] Todos os arquivos criados seguem o padrão existente do `.hacker/`.
- [ ] A regra em `.opencode/rules/` é uma restrição de comportamento AI (como as outras 8 rules).
- [ ] O agente em `.hacker/agentes/` segue o padrão dos agentes existentes (red-team, blue-team, pentest, scraping).
- [ ] Os templates, gate, RAG e orquestrador existentes foram estendidos (não duplicados).
- [ ] Nenhum componente operacional foi colocado em `.opencode/` (exceto a regra AI).
- [ ] A estrutura do relatório técnico segue o padrão OWASP/PTES consolidado do mercado.
- [ ] A regra `hacker-web-scan-report.md` não duplica regras já existentes em `hacker-pentest-harness-execution.md`.
- [ ] O `.hacker/README.md` é atualizado para incluir o novo agente web-scanner no mapa de modulos.
