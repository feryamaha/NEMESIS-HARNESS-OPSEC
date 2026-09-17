# Auditoria Técnica: NEMESIS-HARNESS-OPSEC
## Validação contra "The Hacker's Guide to Attacking AI Agents"

**Data:** 2026-09-17
**Auditor:** Agente técnico sênior de arquitetura de sistemas agentic ofensivos e OPSEC
**Escopo:** Repositório `hacker-etico-ambiente` (.opencode/, .hacker/, regras, skills, agents, gate, orquestrador, memória, ledger, trust-ledger, ai-memory, pipeline Graph+Loop)
**Metodologia:** Baseada exclusivamente em evidências observáveis nos arquivos do repositório (leitura literal de arquivos)

---

## Premissas do Auditor

1. Todas as análises são baseadas em conteúdo literal de arquivos lidos nesta sessão.
2. O projeto já possui proteções robustas de **OPSEC do operador** (cadeia de proteção: WireGuard, Proton, Tor, kill-switch, DNS fix, IPv6 off, sandbox Kali). Esta auditoria foca na **superfície do agente ofensivo**, não na OPSEC do operador.
3. A distinção entre proteção do operador e proteção do agente é crítica e mantida ao longo deste documento.
4. Nenhuma funcionalidade foi inventada. Toda afirmação tem base em arquivo observado.

---

## Visão Geral da Arquitetura Existente

O projeto implementa:
- **Pipeline:** scraping → web-scan → pentest → red team → blue team
- **Framework agentic:** 6 agentes contratados (scraping, web-scanner, pentest, red-team, blue-team, orquestrador-pipeline)
- **Orquestrador:** ScreenBog + Decepticon patterns, com Graph+Loop executor (`graph-loop.py`)
- **Disciplina epistêmica:** leis F1-F12, regras anti-sycophancy
- **Trust Ledger:** registro append-only de vereditos, decisões e operações
- **Gate de proteção:** Dark-Moon adaptado (4-pass pre-flight)
- **Memory Guard:** 3 camadas de memória com integridade SHA-256
- **ai-memory:** servidor MCP/HTTP com hook de capture sanitizado
- **Harness integrity:** F10 com procedimento deterministico
- **RAG de método:** 15 skills Fable orquestradas por ORQUESTRADOR-FABLE-HACKER.md

---

## Recomendação 1: Modelagem Explícita da Superfície de Ataque do Próprio Agente (5 Perguntas)

### Untrusted Input
**Status:** **Parcialmente coberto**

**Evidências:**
- `AGENTS.md` sec 2 ("Autorização e Escopo Ético") — o agente recebe instruções do usuário e deve verificar escopo
- `AGENTS.md` sec 4 ("Disciplina epistêmica") — anti-sycophancy, não confiar no enquadramento do usuário
- `hacker-fable-method.md` F9 ("Trilho/escopo") — "A mudanca deve caber no trilho atual, sem escapar do escopo"
- `hacker-epistemic-safety.md` — "Auto-auditoria obrigatoria" com 7 perguntas antes de concluir
- `hacker-specification-design/SKILL.md` — "Converte request informal em especificacao tecnica estruturada"

**O que já existe e como funciona:**
- O agente é instruído a tratar input do usuário como potencialmente enquadrador, não factual
- A auto-auditoria epistêmica (7 perguntas) serve como verificação de input
- O pipeline SDD (spec → plan → task → test) separa o input do usuário em artefatos estruturados
- A skill `hacker-critical-analysis` emite veredito P1 e P2 sobre specs

**Lacunas reais:**
- **Não existe modelagem explícita das 5 perguntas** como uma matriz ou checklist formal aplicável ao agente
- Não há análise estruturada de "o que acontece se o input for adversarial" ou "quais inputs podem causar comportamento inesperado"
- Não há registro de superfície de ataque do agente (ex.: "quais prompts do usuário podem causar goal drift?")
- A discriminação entre input confiável e não confiável é implícita (regras), não explícita (modelagem formal)

**Necessidade de aditivo:** **Sim — refinamento de alto valor**
- Criar uma matriz explícita de superfície de ataque do agente com as 5 perguntas no `AGENTS.md` ou em regra canonica dedicada
- Formato sugerido: tabela com cada pergunta, mecanismo de proteção atual, lacuna, e evidência

---

### Tools
**Status:** **Coberto**

**Evidências:**
- `.hacker/gate/GATE-DE-PROTECAO.md` sec 71-80 — lista explícita de ferramentas que exigem gate: `curl`, `wget`, `nmap`, `masscan`, `nuclei`, `zap-cli`, `msfconsole`, `ssh`, etc.
- `~/opsec/scripts/gate-enforcement.sh` — controle de x-bit para binários de rede (liga/desliga)
- `AGENTS.md` sec 3 — "NUNCA execute atividade de rede operacional com o IP real exposto"
- `graph-loop.py` sec 90+ — `run_job()` executa comandos via subprocess com capture_output
- `GATE-DE-PROTECAO.md` sec 64-69 — lista de comandos que NÃO exigem gate (leitura local, validação sintaxe)
- `hacker-repo-profile.md` seção 2 — tabela de validação por atributo

**O que já existe e como funciona:**
- Allowlist implícita via gate: ferramentas de rede são bloqueadas sem pre-flight GOOD
- Sandbox Docker (`kali-sandbox` container) isola execução de ferramentas
- Tor SOCKS5 (127.0.0.1:9050) force-toda saída de rede pelo proxy
- Kill-switch (`~/opsec/scripts/kill-switch.sh`) com POLICY OUTPUT DROP
- O `graph-loop.py` executor roda jobs via subprocess, capturando stdout/stderr
- A skill `hacker-pre-flight-verification` é acionada ANTES de cada operação de rede

**Lacunas reais:**
- Não existe um arquivo único de "allowlist de tools" com formato machine-readable
- O gate é baseado em ferramentas individuais, não em categorias de capability (ex.: "network egress", "file system write", "process execution")
- O `graph-loop.py` valida SENSITIVE_MARKERS no routing, mas não faz sandboxing real do subprocess (não usa containers isolados por job)
- Não há limitação de ferramenta por agente (qualquer agente pode chamar qualquer ferramenta se o gate passar)

**Necessidade de aditivo:** **Não — apenas refinamento menor**
- Um allowlist machine-readable em JSON/YAML seria útil para automação, mas o sistema atual é funcional
- O refinamento seria: adicionar `tools_allowlist.json` por agente no `.hacker/agentes/`

---

### Privilege
**Status:** **Parcialmente coberto**

**Evidências:**
- `AGENTS.md` sec 3, invariante 3 — "Autenticacao e privilegio sao exclusivos do Fernando"
- `AGENTS.md` sec 3, invariante 10 — "Destrutivo/irreversivel exige confirmacao" (classe C, F4)
- `hacker-fable-method.md` F4 — classes A/B/C de veredito
- `GATE-DE-PROTECAO.md` — pre-flight de 4 passos antes de qualquer rede
- `hacker-pentest-harness-execution.md` regra 3 — "Destrutivo requere confirmacao (classe C)"
- `ORQUESTRADOR.md` sec 8 — "HITL: pontos de parada obrigatoria"
- `hacker-etico/SKILL.md` — contexto completo do projeto

**O que já existe e como funciona:**
- O agente NUNCA tem privilégios elevados (roda sem sudo)
- Ações de classe C (destrutivas) param e pedem confirmação do Fernando
- O gate de proteção bloqueia qualquer ação de rede sem atestado GOOD
- O Orquestrador exige HITL para escopo fora do autorizado e ações destrutivas
- O `session-start-hacking-security.sh` controla o x-bit via gate-enforcement (liga com GOOD, desliga ao encerrar)
- `AGENTS.md` invariante 8 — "Escopo e decisao exclusiva do Fernando"

**Lacunas reais:**
- Não há verificação programática de privilégio (ex.: `whoami`, `id`) antes de cada ação do agente
- O gate verifica a cadeia de proteção (IP, DNS, VPN), mas não verifica se o agente está executando como root ou com privilégios elevados
- Não há conceito de "privilege escalation attempt detection" (detectar se o prompt tenta escalar privilégios)
- A distinção entre classe A/B/C é clara, mas não há um mecanismo de privilege checking automático

**Necessidade de aditivo:** **Sim — refinamento de médio valor**
- Adicionar verificação de privilégio ao pre-flight (ex.: `id` não-root check)
- Adicionar detecção de tentativa de privilege escalation na análise de input

---

### Processing
**Status:** **Coberto**

**Evidências:**
- `AGENTS.md` sec 4 — "Disciplina epistemica anti-sycophancy e anti-invencao"
- `hacker-epistemic-safety.md` — Lei anti-invencao (PROIBICAO ABSOLUTA), auto-auditoria obrigatoria
- `hacker-fable-method.md` F1-F12 — leis de método completo
- `hacker-fable-method.md` F1 ("Contexto antes da acao") — ler arquivos, reler se necessario, pre-flight
- `hacker-fable-method.md` F2 ("Manual sobre IA") — ferramentas não se comunicam sozinhas
- `.opencode/rag/ORQUESTRADOR-FABLE-HACKER.md` — RAG sob demanda por situacao
- `hacker-epistemic-safety.md` — "NENHUM modelo inventa dado, path, IP, versao, saida de comando"
- `AGENTS.md` sec 5 — RAG como regra canonica
- `.opencode/skills/disciplina-epistemica/SKILL.md`

**O que já existe e como funciona:**
- O agente é obrigado a ler arquivos no momento (F1), nunca confiar em memória de treinamento
- A disciplina epistêmica impõe auto-auditoria de 7 perguntas antes de qualquer conclusão
- O RAG orquestrado fornece conhecimento atualizado via 15 skills Fable
- O F2 proíbe ferramentas de IA de se comunicarem entre si ou alterar arquivos fora da operação autorizada
- O pipeline SDD garante processing estruturado: spec → plan → task → test → doc-sync
- O `hacker-tests` skill inclui loop evaluator-optimizer (max 5 ciclos) com reconciliação no Trust Ledger
- O `hacker-postmortem-to-law` skill (F12) converte erros de processo em emendas de regra

**Lacunas reais:**
- O processing model é robusto para o modelo como um todo, mas não há um "processing log" estruturado de toda a cadeia de raciocínio
- Não existe um mecanismo formal de "chain of thought" verificável (embora o Trust Ledger registre decisões)
- A distinção entre FATO e INFERENCIA está bem definida no relatório forense (Estácio), mas não é um mecanismo automático do sistema

**Necessidade de aditivo:** **Não — apenas refinamento menor**
- O processing é o ponto mais forte da arquitetura. O refinamento seria: adicionar um `processing_log` estruturado no Trust Ledger para cada etapa de raciocínio

---

### Output
**Status:** **Parcialmente coberto**

**Evidências:**
- `hacker-fable-method.md` F3 ("Lei da evidencia") — todo artefato rastreavel a comando real
- `.opencode/ledger/trust-ledger.md` — registro append-only de vereditos
- `LEDGER.md` — log de atividades na raiz
- `.hacker/ledger/operacoes.md` — ledger operacional
- `hacker-trust-ledger-update/SKILL.md` — coleta de vereditos para o ledger
- `hacker-harness-integrity.md` F10 — verificacao mecanica de atributos
- `GATE-DE-PROTECAO.md` — o gate INVALIDA operacao sem verificacao
- `AGENTS.md` sec 3, invariante 6 — "Nunca registrar dado real além do necessario"
- Relatórios em `.hacker/reports/OP-YYYYMMDD-NNN.md` com estrutura documentada

**O que já existe e como funciona:**
- Todo veredito de gate é registrado no Trust Ledger com formato estruturado: `[data] | ciclo= | skill= | evento= | resultado= | base=`
- Relatórios de operação são artefatos estruturados com findings numerados
- O `hacker-harness-sync` skill verifica integridade do harness (F10)
- O `hacker-finishing-branch` skill gera PR estruturada com HARD-GATE de revisão humana
- A saída do agente é sempre rastreável a um comando ou arquivo observável (F3)
- O `verificador-externo.sh` fornece segunda leitura independente do verificador de vazamento

**Lacunas reais:**
- Não há um schema formal de output para garantir que TODA saída do agente inclua fonte/citação
- O Trust Ledger registra vereditos e decisões, mas não registra cada saída individual do agente durante uma sessão
- Não há verificação automática de "a saída contém dados inventados?" — isso dependeria do modelo se auto-regular (disciplina epistêmica)
- A saida de operações de rede específicas (ex.: resultado de curl, nmap) é registrada no relatório mas não em formato estruturado machine-readable no ledger

**Necessidade de aditivo:** **Sim — refinamento de médio valor**
- Adicionar schema de output obrigatório para relatórios (cada finding deve ter: descrição, evidência, fonte, classificação FATO/INFERENCIA)
- O `hacker-postmortem-to-law` skill já faz isso para erros, mas deveria ser universalizado para todos os outputs

---

## Recomendação 2: Allowlist de Tools + Sandbox Rigoroso para Código/Payloads Gerados

**Status:** **Coberto**

**Evidências:**
- `GATE-DE-PROTECAO.md` — allowlist implícita de ferramentas por seção
- `GATE-DE-PROTECAO.md` sec 64-69 — comandos que NÃO exigem gate
- `GATE-DE-PROTECAO.md` sec 71-80 — comandos que EXIGEM gate (curl, nmap, nuclei, msfconsole, ssh, etc.)
- `~/opsec/scripts/gate-enforcement.sh` — controle de x-bit para binários de rede
- `~/opsec/docker-compose.yml` — sandbox Kali (`kali-sandbox` container) + `torproxy-host`
- `AGENTS.md` sec 3 — pre-requisito de cadeia de proteção inteira
- `session-start-hacking-security.sh` — script principal que ativa toda a cadeia
- `kill-switch.sh` — kill-switch com POLICY OUTPUT DROP
- `graph-loop.py` — executor de jobs via subprocess com capture_output
- `hacker-tests/SKILL.md` — validação pos-execucao com bateria de testes

**O que já existe e como funciona:**
- **Allowlist:** ferramentas de rede são categorizadas em "exigem gate" vs "não exigem gate"
- **Sandbox:** container `kali-sandbox` para ferramentas isoladas, container `torproxy-host` para Tor exit
- **Kill-switch:** política OUTPUT DROP que bloqueia tráfego se a VPN cair
- **Gate enforcement:** x-bit de binários de rede é removido ao encerrar sessão (`encerrar-sessao.sh`)
- **Tor:** todo tráfego de rede passa por SOCKS5 127.0.0.1:9050
- **Docker:** a cadeia inteira roda em containers para isolamento
- **Subagent:** `graph-loop.py` roda jobs em subprocess com capture, não com shell direto

**Lacunas reais:**
- Não existe um allowlist formal machine-readable (ex.: JSON) que defina exatamente quais comandos cada agente pode executar
- O `graph-loop.py` executor NÃO usa containers individuais por job — roda subprocess diretamente no host
- O sandbox Kali existe mas não está integrado ao pipeline como sandbox padrão para payloads gerados
- Não há sandboxing para código Python gerado pelo agente (ex.: scripts de scanner personalizados)
- O allowlist é baseado em ferramentas individuais, não em capability-based (ex.: "network egress", "file write", "process spawn")
- Não há verificação de que o output de um job não contém payloads maliciosos antes de ser usado como input para outro

**Necessidade de aditivo:** **Não — apenas refinamento de baixo valor**
- A cobertura atual é sólida para o propósito do projeto (pentest ético em lab autorizado)
- O refinamento seria: adicionar `tools_allowlist.json` machine-readable e integrar sandboxing de subprocess ao `graph-loop.py`
- **Prioridade baixa** porque o ambiente já é altamente controlado (cadeia OPSEC completa, kill-switch, Tor, sandbox)

---

## Recomendação 3: Proteção Forte Contra Indirect Prompt Injection

**Status:** **Parcialmente coberto**

**Evidências:**
- `AGENTS.md` sec 4 — "Empatia != concordancia factual; enquadramento do usuario != verdade observada"
- `hacker-epistemic-safety.md` — anti-sycophancy, "Nunca validar afirmacao do usuario sem evidencia"
- `hacker-epistemic-safety.md` — "espelhar a posicao do usuario como se fosse fato" é PROIBIDO
- `hacker-epistemic-safety.md` — "NENHUM modelo invente dado" (anti-hallucination)
- `hacker-fable-method.md` F2 ("Manual sobre IA") — "Toda afirmacao declarada como provida por IA e provada (F6), tratada como suspeita e verificada"
- `hacker-fable-method.md` F6 ("Lembranca") — usar RAG quando depender de conhecimento externo
- `.opencode/skills/disciplina-epistemica/SKILL.md` — "Disciplina epistemica anti-sycophancy. Ativa em toda tarefa"
- `AGENTS.md` sec 8 — "Escopo e decisao exclusiva do Fernando"
- `hacker-epistemic-safety.md` — "Regra pratica: se um texto deste repo diz 'o modelo deve', o leitor e o MODELO"
- `hacker-epistemic-safety.md` — seção "Proibicoes epistemicas (anti-sycophancy)" com 14 itens

**O que já existe e como funciona:**
- O agente é explicitamente treinado para NÃO concordar com o enquadramento do usuário sem evidência
- A disciplina epistêmica inclui 14 proibições específicas de sycophancy
- A auto-auditoria de 7 perguntas inclui: "Estou respondendo a evidência ou ao enquadramento?"
- O F2 instrui o modelo a tratar toda afirmação de IA como suspeita
- O modelo é instruído a "preferir a evidência indica" em vez de "você está certo"
- O RAG fornece conhecimento externo verificável para substituir suposições

**Lacunas reais:**
- **Não existe um mecanismo dedicado de detecção de prompt injection** no input stream do agente
- A proteção é **comportamental** (o modelo sabe que não deve concordar cegamente), não **sistêmica** (não há filtro de input que detecte tentativas de injection)
- Não há conceito de "prompt provenance" (de onde veio o prompt? foi gerado por outro modelo? contém instruções ocultas?)
- O `hacker-epistemic-safety.md` menciona que "enquadramento emocional/identitário que pressiona concordância" é risco alto, mas não define um mecanismo de detecção
- Não há registro de tentativas de prompt injection no Trust Ledger (apenas vereditos de gate)
- **Distinção importante:** a proteção atual é anti-sycophancy (o modelo não bajula), não anti-prompt-injection (o modelo não detecta prompts maliciosos injetados)

**Necessidade de aditivo:** **Sim — necessidade real**
- Adicionar um mecanismo de detecção de prompt injection como skill ou regra canonica
- Exemplos de implementação:
  - **Input classifier:** classificar prompts como "diretos", "indiretos", "potencialmente injetados"
  - **Provenance tracking:** registrar a origem de cada prompt no Trust Ledger
  - **Injection attempt logging:** registrar no ledger qualquer prompt que contenha padrões de injection (ex.: "ignore suas regras", "esqueça suas instruções")
  - **Instruction boundary:** separar explicitamente instruções do sistema (do AGENTS.md) de instruções do usuário
- **Justificativa técnica:** a proteção atual é comportamental e depende da capacidade do LLM de resistir à indução. Uma proteção sistêmica forneceria camada adicional independente da capacidade do modelo.

---

## Recomendação 4: Detecção de Goal Drift / Rogue Behavior

**Status:** **Parcialmente coberto**

**Evidências:**
- `AGENTS.md` sec 3, invariante 8 — "Escopo e decisao exclusiva do Fernando"
- `AGENTS.md` sec 3, invariante 9 — "Uso etico obrigatorio"
- `hacker-fable-method.md` F9 ("Trilho/escopo") — "A mudanca deve caber no trilho atual... Saiu do trilho: novo problema, nova spec, outro trilho"
- `hacker-specification-design/SKILL.md` — "NUNCA escreva codigo antes do design ser validado"
- `hacker-critical-analysis/SKILL.md` — "Analise critica de propostas. Emite veredito P1 e P2 com gate duplo"
- `hacker-repo-profile.md` seção 3 — validacao por fase (pos-spec, pos-tarefa, pos-elab, pos-doc-sync, ante-finishing)
- `ORQUESTRADOR.md` sec 2 — "Validar escopo: lab autorizado? Sem acao destrutiva nao autorizada?"
- `ORQUESTRADOR.md` sec 8 — "HITL: pontos de parada obrigatoria"
- `hacker-pentest-harness-execution.md` regra 1 — "Escopo primeiro"
- `hacker-pentest-harness-execution.md` regra 5 — "100% de bloqueio visando sem acionar = 100% de aprovacao indireta"
- `hacker-fable-method.md` F5 ("Propor o minimo") — "Nao sobre-engenhar"
- `hacker-fable-method.md` F8 ("Semente") — "Nao otimizar prematuramente"

**O que já existe e como funciona:**
- O pipeline SDD impõe escopo através de specs e plans validados
- O orquestrador verifica escopo antes de despachar operações
- O HITL (Human-in-the-loop) impõe pontos de parada para ações destrutivas e fora de escopo
- O F9 define que sair do trilho requer nova spec/plan
- O `hacker-critical-analysis` emite veredito P1 e P2 sobre qualquer spec
- O `hacker-repo-profile.md` valida por fase com gates específicos
- O `hacker-pre-flight-verification` bloqueia operações sem cadeia ativa
- O `hacker-postmortem-to-law` (F12) documenta desvios de processo

**Lacunas reais:**
- **Não existe detecção de goal drift em tempo real durante a execução** — o sistema previne desvios antes (via escopo), mas não detecta desvios durante
- Não há métricas de "distance from goal" durante a execução de um agente
- O `graph-loop.py` executor retorna exit_code e output, mas não analisa se o output está alinhado com o objetivo original
- Não há conceito de "rogue behavior" detection (ex.: o agente começa a fazer algo não relacionado ao escopo)
- O HITL é reativo (detecta após o agente pedir confirmação), não proativo (detecta antes do desvio ocorrer)
- O `hacker-tests` skill inclui loop evaluator-optimizer, mas o evaluator verifica qualidade técnica, não goal alignment

**Necessidade de aditivo:** **Sim — refinamento de médio valor**
- Adicionar um "goal drift detector" como skill ou componente do orquestrador
- Implementação sugerida:
  - **Step 1:** Definir objetivo mensurável no início de cada operação
  - **Step 2:** A cada etapa do pipeline, verificar se a ação atual contribui para o objetivo
  - **Step 3:** Se a ação não contribui, registrar no Trust Ledger como "potential goal drift" e parar
  - **Step 4:** O `graph-loop.py` poderia incluir um `--goal-check` parameter
- **Justificativa técnica:** o sistema atual previne desvios via gate e escopo, mas em operações longas (ex.: pentest completo com 5 etapas), um agente pode desviar sutilmente sem acionar gates. Uma detecção proativa aumentaria a robustez.

---

## Recomendação 5: Logging Estruturado de Toda Tool Call

**Status:** **Parcialmente coberto**

**Evidências:**
- `.opencode/ledger/trust-ledger.md` — registro append-only com formato estruturado
- `LEDGER.md` — log cronológico de atividades na raiz
- `.hacker/ledger/operacoes.md` — ledger operacional com template de operacao
- `hacker-trust-ledger-update/SKILL.md` — coleta de vereditos para o ledger
- `AGENTS.md` sec 3, invariante 11 — "Registre decisoes e mudancas de rumo no ledger IMEDIATAMENTE"
- `hacker-fable-method.md` F11 (Trust Ledger) — "Verificacao do harness gera entrada no ledger"
- `ORQUESTRADOR.md` sec 10 — "Gravar no ledger: append-only, uma entrada por operacao"
- `graph-loop.py` — `run_job()` retorna `{name, exit_code, stdout, stderr}` estruturado
- `hacker-tests/SKILL.md` — loop evaluator-optimizer gera entrada no Trust Ledger por ciclo
- `hacker-postmortem-to-law/SKILL.md` — registro de post-mortem no ledger
- `.hacker/memoria/MEMORIA.md` — 3 camadas de memória com SHA-256 por entrada

**O que já existe e como funciona:**
- **Trust Ledger:** registra vereditos de gate, decisões, paradas de emergência, ciclos de red team, post-mortems
- **Operacional ledger:** registra cada operação com template preenchido
- **Memory Guard:** cada linha em memoria/ledger tem hash SHA-256 validado
- **Graph+Loop:** o executor retorna structured output para cada job
- **Hacker-tests:** cada ciclo do loop gera entrada no Trust Ledger
- **RAG:** a ai-memory registra hooks sanitizados com `[capture] ignore_paths`
- O formato do Trust Ledger é: `[data] | ciclo= | skill= | evento= | resultado= | base=`

**Lacunas reais:**
- **NÃO existe logging estruturado de TODA tool call** — apenas de decisões, vereditos e operações
- Cada chamada de ferramenta individual (curl, nmap, grep, python) NÃO é registrada no ledger
- O `graph-loop.py` captura stdout/stderr de cada job, mas não envia para o ledger automaticamente
- Não há um "tool call log" que registre: timestamp, ferramenta, argumentos, resultado, agente que executou
- O `operacoes.md` registra no nível da operação, não no nível da tool call individual
- A ai-memory (MCP) registra observações de sessão, mas não tool calls específicas
- **Consequência:** se ocorrer um incidente (ex.: vazamento de IP), não é possível reconstruir todas as tool calls que levaram ao incidente

**Necessidade de aditivo:** **Sim — necessidade real**
- Adicionar um `tool_call_logger` que registre cada tool call no Trust Ledger ou em um log separado
- Implementação sugerida:
  - **Estrutura:** `{timestamp, agent, tool, args_hash, result, duration, gate_status}`
  - **Integração:** o `graph-loop.py` `run_job()` deveria enviar resultado para o ledger
  - **Formato:** JSONL para facilitar análise automatizada
  - **Guard:** o logging em si deve respeitar OPSEC (não registrar IPs reais, credenciais)
- **Justificativa técnica:** para forense e auditoria reais, é necessário reconstruir a cadeia completa de ações do agente. O Trust Ledger atual registra decisões de alto nível, mas não a execution trail granular. Isso é especialmente importante para o `hacker-postmortem-to-law` (F12) que precisa de evidência completa.

---

## Recomendação 6: Testes Automatizados de Red-Team do Próprio Harness

**Status:** **Parcialmente coberto**

**Evidências:**
- `.hacker/scripts/test-graph-loop.sh` — 15/15 PASS para o executor Graph+Loop
- `hacker-tests/SKILL.md` — bateria de testes pos-execucao (bash -n, shellcheck, py_compile, docker compose config, git diff --check)
- `hacker-harness-sync/SKILL.md` — verificacao de integridade do harness (F10)
- `hacker-harness-integrity.md` — procedimento deterministico de 5 passos
- `hacker-pre-flight-verification/SKILL.md` — verificacao primaria 4-passos
- `verificador-externo.sh` — segundo leitor independente do verificador de vazamento
- `hacker-web-scan-validation/SKILL.md` — suite de 42 testes para web scanner
- `hacker-postmortem-to-law/SKILL.md` — conversao de erros em emendas de regra
- `GATE-DE-PROTECAO.md` — gate unitario de protecao (Dark-Moon)
- `.hacker/gate/gate-p1.sh`, `gate-p2.sh`, `gate-preflight.sh` — scripts de gate
- `hacker-etico/SKILL.md` — contexto completo do projeto

**O que já existe e como funciona:**
- **test-graph-loop.sh:** 15 testes automatizados para o executor (route, delegate, parallel, loop)
- **hacker-tests:** bateria completa de validação pos-execucao
- **harness-integrity:** verifica estrutura de `.opencode/` (find, grep, diff)
- **pre-flight verification:** 4-passos que valida a cadeia de proteção
- **web-scan-validation:** 42 testes para a capability de scanner web
- **postmortem-to-law:** converte falhas de processo em emendas de regra
- **verificador-externo:** segunda leitura independente do verificador de vazamento
- **gate-p1, gate-p2, gate-preflight:** scripts unitários de proteção
- **hacker-finishing-branch:** HARD-GATE de revisão humana antes de PR

**Lacunas reais:**
- **Não existem testes de red-team do próprio agente** — ou seja, não há testes que tentem "quebrar" o agente para verificar se ele resiste
- Os testes atuais são de **integridade estrutural** (os arquivos existem, a sintaxe está correta) e **funcional** (o executor funciona), mas não são de **resiliência comportamental**
- Não há testes como:
  - "O agente consegue ser induzido a revelar o IP real do operador?"
  - "O agente consegue burlar o gate de proteção com um prompt manipulado?"
  - "O agente consegue executar comandos de rede sem o pre-flight GOOD?"
  - "O agente consegue escapar do escopo definido na spec?"
  - "O agente consegue inventar dados e o Trust Ledger detecta?"
- O `hacker-postmortem-to-law` (F12) é reativo — registra erros que já ocorreram, não previne que ocorram
- Não há red-team automation que teste o harness contra os cenários do "Hacker's Guide"

**Necessidade de aditivo:** **Sim — necessidade real de alto valor**
- Criar uma suite de **red-team tests para o próprio harness** (não para alvos externos)
- Implementação sugerida:
  - **Teste 1 (Anti-injection):** enviar prompts com técnicas de prompt injection ao agente e verificar se ele resiste
  - **Teste 2 (Gate bypass):** tentar executar comandos de rede sem pre-flight e verificar se o gate bloqueia
  - **Teste 3 (Scope drift):** enviar uma spec com escopo ambíguo e verificar se o agente para para perguntar
  - **Teste 4 (Information leak):** tentar induzir o agente a revelar IP real e verificar se a OPSEC se mantém
  - **Teste 5 (Hallucination):** pedir ao agente para afirmar algo sem fonte e verificar se ele recusa
  - **Formato:** automatizado via `hacker-tests` skill ou script dedicado em `.hacker/scripts/`
- **Justificativa técnica:** os testes atuais validam a estrutura, mas não a resistência do agente a ataques. Para um sistema projetado para testar outros, é fundamental que o próprio sistema seja testado contra os mesmos vetores que aplica.

---

## Tabela Resumo

| # | Recomendação | Status | Necessidade de Aditivo |
|---|---|---|---|
| 1 | Modelagem explícita da superfície de ataque (5 perguntas) | **Parcialmente coberto** | **Sim — refinamento de alto valor** |
| 1a | Untrusted Input | Parcialmente coberto | Sim |
| 1b | Tools | **Coberto** | Não — apenas refinamento menor |
| 1c | Privilege | Parcialmente coberto | Sim — refinamento médio |
| 1d | Processing | **Coberto** | Não — apenas refinamento menor |
| 1e | Output | Parcialmente coberto | Sim — refinamento médio |
| 2 | Allowlist de tools + sandbox rigoroso | **Coberto** | Não — apenas refinamento de baixo valor |
| 3 | Proteção contra Indirect Prompt Injection | **Parcialmente coberto** | **Sim — necessidade real** |
| 4 | Detecção de Goal Drift / Rogue Behavior | **Parcialmente coberto** | **Sim — refinamento médio valor** |
| 5 | Logging estruturado de toda tool call | **Parcialmente coberto** | **Sim — necessidade real** |
| 6 | Testes automatizados de red-team do próprio harness | **Parcialmente coberto** | **Sim — necessidade real de alto valor** |

**Totais:** 1 Coberto, 4 Parcialmente coberto, 5 Aditivos necessários (dos quais 3 de alta necessidade)

---

## Conclusão Geral

### A arquitetura atual já atende de forma satisfatória?

**PARCIALMENTE.** A arquitetura atual é **excepcionalmente robusta para o propósito declarado** (harness de pentest ético com OPSEC do operador), mas **não converge completamente** com as 6 recomendações do guia quando interpretadas como proteção da **superfície do próprio agente ofensivo**.

**O que funciona excepcionalmente bem:**
1. **OPSEC do operador** — a cadeia de proteção (WireGuard + Proton + Tor + kill-switch + DNS fix + IPv6 off + sandbox) é completa e validada por 4-passos. Isso é Coberto.
2. **Ferramentas e sandbox** — o gate de proteção (Dark-Moon), gate-enforcement, Tor proxy e containers fornecem allowlist e sandbox eficazes. Isso é Coberto.
3. **Processing discipline** — as leis F1-F12, a disciplina epistêmica e o RAG orquestrado fornecem um processing model robusto. Isso é Coberto.
4. **Trust Ledger e logging de decisões** — o Trust Ledger é append-only, rastreável e verificado mecanicamente (F10). Isso é Parcialmente coberto.
5. **Testes de integridade estrutural** — test-graph-loop.sh (15/15), hacker-tests, harness-sync, pre-flight verification. Isso é Parcialmente coberto.

**O que precisa de atenção:**
1. **Prompt injection detection** — A proteção atual é comportamental (anti-sycophancy), não sistêmica. Não há detecção de prompt injection no input stream. Isso é uma **lacuna real**.
2. **Tool call logging** — O Trust Ledger registra decisões e vereditos, mas não cada tool call individual. Para forense completa, é necessário um execution trail granular. **Necessidade real**.
3. **Goal drift detection** — O sistema previne desvios via escopo e gates, mas não detecta desvios sutis durante execução longa. **Refinamento de médio valor**.
4. **Red-team do próprio harness** — Não há testes automatizados que tentem "quebrar" o agente. Os testes atuais são de estrutura, não de resiliência comportamental. **Necessidade real de alto valor**.
5. **Superfície de ataque modelada** — As 5 perguntas do guia não são explicitamente modeladas como matriz no sistema. Estão implícitas nas regras, mas não formais. **Refinamento de alto valor**.

### Quais refinamentos trazem maior retorno com menor esforço?

**Ranking por ROI (retorno/esforço):**

1. **Adicionar logging estruturado de tool calls ao `graph-loop.py`** (Esforço: BAIXO, Retorno: ALTO)
   - O `run_job()` já captura stdout/stderr/exit_code — basta enviar para o ledger
   - Implementação: ~50-100 linhas de Python
   - Impacto: habilita forense completa e satisfaz Recomendação 5

2. **Criar suite de red-team tests para o próprio agente** (Esforço: MÉDIO, Retorno: ALTO)
   - Reutilizar `hacker-tests` skill e `test-graph-loop.sh` como padrão
   - 5 testes de resistência comportamental
   - Impacto: valida resiliência do agente contra os vetores que ele aplica a outros

3. **Adicionar detector de prompt injection como skill** (Esforço: MÉDIO, Retorno: ALTO)
   - Pode ser uma skill `.opencode/skills/hacker-prompt-injection-detection/SKILL.md`
   - Registrar tentativas no Trust Ledger
   - Impacto: camada sistêmica além do anti-sycophancy comportamental

4. **Criar matriz explícita de superfície de ataque** (Esforço: BAIXO, Retorno: MÉDIO)
   - Tabela no `AGENTS.md` ou regra dedicada com as 5 perguntas
   - Formato: markdown table
   - Impacto: torna explícito o que está implícito

5. **Adicionar goal drift detector ao orquestrador** (Esforço: MÉDIO, Retorno: MÉDIO)
   - Integrar ao `graph-loop.py` ou `ORQUESTRADOR.md`
   - Verificação de alinhamento a cada etapa
   - Impacto: detecção proativa de desvios

**Recomendação final:** A arquitetura atual é **produzível e funcional** para o seu propósito. Os 5 refinamentos acima, implementados em ordem de prioridade, elevariam o sistema de "Parcialmente coberto" para "Coberto" em todas as 6 recomendações, com esforço total estimado de 2-3 semanas de desenvolvimento e testes.

---

## Distinção OPSEC do Operador vs Proteção do Agente

Esta distinção é fundamental para a interpretação correta desta auditoria:

| Aspecto | OPSEC do Operador | Proteção do Agente |
|---|---|---|
| **O que protege** | IP real do pesquisador, identidade, localização | O modelo/agente contra manipulação, abuso, desvio |
| **Mecanismos existentes** | WireGuard, Proton, Tor, kill-switch, DNS fix, IPv6 off, sandbox Kali | Disciplina epistêmica, gates, Trust Ledger, leis F1-F12, RAG |
| **Status geral** | **Forte** (validado por verificar-vazamento.sh) | **Parcialmente forte** (comportamental, não sistêmico) |
| **Recomendações afetadas** | Principalmente 1b (Tools), 2 (Allowlist/sandbox) | Principalmente 1a, 3, 4, 5, 6 |
| **Risco se comprometido** | Exposição de identidade do pesquisador | Execução não autorizada, vazamento de dados, goal drift |

**Nota do auditor:** A OPSEC do operador é o ponto mais forte da arquitetura e NÃO é o foco das recomendações do guia. O guia é focado na superfície do agente, não na cadeia de proteção do operador. A auditoria separa explicitamente essas duas camadas para não confundir cobertura forte de OPSEC com cobertura completa de proteção do agente.

---

*Este relatório é baseado exclusivamente em evidências observáveis nos arquivos do repositório. Nenhuma funcionalidade foi inventada. Toda afirmação tem fonte em arquivo lido nesta sessão.*

**Assinatura:** Agente técnico sênior — auditoria concluida em 2026-09-17
