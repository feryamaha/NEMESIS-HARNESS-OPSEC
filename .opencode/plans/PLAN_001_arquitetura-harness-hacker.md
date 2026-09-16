# PLAN_001 - Arquitetura do Harness Hacker - Plano de Implementacao

> **Para agentes**: Use hacker-subagent-driven-development para executar este plano.

**Objetivo**: Criar a arquitetura do harness hacker em `.hacker/` (agentes + gate + orquestrador + memoria + ledger + RAG + templates) e atualizar docs raiz, destilando os 8 repos de pesquisa registrados no LEDGER.md (2026-09-05, linhas 133-147).

**Spec**: `.opencode/specs/SPEC_001_arquitetura-harness-hacker.md`

**Arquivos Afetados**:
- CREATE: `.hacker/README.md`, `.hacker/gate/GATE-DE-PROTECAO.md`, `.hacker/orquestrador/ORQUESTRADOR.md`, `.hacker/agentes/red-team/AGENTE.md`, `.hacker/agentes/blue-team/AGENTE.md`, `.hacker/agentes/pentest/AGENTE.md`, `.hacker/agentes/scraping/AGENTE.md`, `.hacker/memoria/MEMORIA.md`, `.hacker/ledger/LEDGER-OPERACOES.md`, `.hacker/ledger/operacoes.md`, `.hacker/rag/README-RAG.md`, `.hacker/templates/TEMPLATE-OPERACAO.md`, `.hacker/templates/TEMPLATE-CONTRATO.md`, `.hacker/templates/TEMPLATE-RELATORIO.md`
- MODIFY: `README.md` (raiz), `LEDGER.md` (raiz)

**Arquitetura**: Harness modular com camadas independentes: (1) GATE de protecao unitario Dark-Moon (verificar-vazamento.sh antes de toda rede); (2) Orquestrador supervisor (ScreenBog + Decepticon: missao, RAG, despacho, observabilidade, HITL); (3) Agentes especializados com contrato (red/blue/pentest/scraping); (4) Memoria 3 camadas (conhecimento grafo, sessao, indexada); (5) Ledger append-only; (6) RAG de conhecimento local; (7) Memory Guard (integridade hashes, rollback, scan injecao/PII); (8) Templates padrao para operacao/contrato/relatorio.

**Stack**: markdown (docs), com referencias a `bash`, `python3`, `docker compose` para operacao futura.

**Fontes destiladas (LEDGER 133-147)**:
- ScreenBog/Agentic-Pentest-AI → base do harness (RAG, HITL, LangGraph model)
- PurpleAILAB/Decepticon → agentes especializados + supervisor/orquestrador
- vxcontrol/pentagi → observabilidade
- cybersharkvin/llmitm_v2 → memoria em grafo (conhecimento)
- GreyDGL/PentestGPT → memoria de sessao
- GH05TCREW/pentestagent → memoria indexada + ledger de operacoes
- ASCIT31/Dark-Moon → gate de protecao (privacy gateway)
- OWASP/www-project-agent-memory-guard → integridade da memoria (hashes, rollback, scan)

---

## TASK 2: Criar `.hacker/gate/GATE-DE-PROTECAO.md`

**Arquivo**: `.hacker/gate/GATE-DE-PROTECAO.md`

**Arquivos**:
- CREATE: `.hacker/gate/GATE-DE-PROTECAO.md`

**Depende de**: nenhuma

**Verificacao**:
`test -f .hacker/gate/GATE-DE-PROTECAO.md && grep -q "verificar-vazamento.sh" .hacker/gate/GATE-DE-PROTECAO.md`

**Descricao Detalhada**:
Regra unitaria: QUALQUER acao de rede de qualquer agente executa PRIMEIRO `bash ~/opsec/scripts/verificar-vazamento.sh`. GOOD = libera. Qualquer outro resultado = BLOQUEIA e reporta ao Fernando. Dark-Moon adaptado: o agente NUNCA recebe o IP real de origem; toda referencia a IP em relatorio e IP de saida (Proton/Tor). Lista de acoes que NÃO são rede (escopo protegido, não requer gate): edicao de docs dentro de `.hacker/`, `.opencode/`, `~/opsec/README.md` (quando existir). Lista de acoes de rede (exige gate): `curl`, `nmap`, `scrapy`, `requests`, `metasploit`, `sqlmap`, qualquer coisa que saia da maquina. Sem placeholders. Sem first person. PT-BR.

**Implementacao**:
```markdown
# Gate de Protecao Obrigatorio (Dark-Moon adaptado)

> REGRA UNITARIA INEGOCIÁVEL: toda operacao de rede de qualquer agente e
> INVALIDA sem esta checagem. Gate adaptado do ASCIT31/Dark-Moon.

## Comando

```bash
bash ~/opsec/scripts/verificar-vazamento.sh
```

- **GOOD**: cadeia ativa (IP de saida != IP real, DNS sem ECS, IPv6 off). A operacao de rede pode prosseguir.
- **Qualquer outro resultado/erro/nao-executado**: BLOQUEADO. Nao toque rede. Reporte ao Fernando.

## O que NÃO exige gate (escopo protegido)

- Edicao de arquivos markdown dentro de `.hacker/`, `.opencode/`, `~/opsec/README.md`
- Leitura/auditoria de codigo local (`cat`, `grep`, `git diff`)
- Execucao de `bash -n`, `shellcheck`, `py_compile`, `docker compose config` (validacoes locais)
- Qualquer comando que NAO faça conexão de rede

## O que EXIGE gate

- `curl`, `wget`, `requests`, `urllib` (HTTP/HTTPS)
- `nmap`, `masscan`, `zmap` (scan de rede)
- `scrapy`, `playwright`, `selenium` (scraping web)
- `msfconsole`, `metasploit`, `sqlmap` (exploit/autopwn)
- `ssh`, `telnet`, `ftp` (conexao remota)
- Qualquer execucao de ferramenta de pentest que saia da maquina
- Qualquer operacao dentro de containers que toque rede externa

## Privacidade (Dark-Moon)

O agente NUNCA recebe o IP real de origem. Em relatorios e registros:
- Cite SEMPRE o IP de saida (Proton/Tor), NUNCA o IP real.
- Nao grave o IP real em ledgers, reports ou templates.
- Se o verificar-vazamento.sh exigir citar um IP, cite o IP de saida.

## Integracao com orquestrador

O orquestrador aplica este gate ANTES de cada operacao de rede, antes de despachar ao agente.
A operacao e invalida se o gate nao for executado.
```

---

## TASK 3: Criar `.hacker/orquestrador/ORQUESTRADOR.md`

**Arquivo**: `.hacker/orquestrador/ORQUESTRADOR.md`

**Arquivos**:
- CREATE: `.hacker/orquestrador/ORQUESTRADOR.md`

**Depende de**: nenhuma

**Verificacao**:
`test -f .hacker/orquestrador/ORQUESTRADOR.md && grep -q "orquest" .hacker/orquestrador/ORQUESTRADOR.md`

**Descricao Detalhada**:
Supervisor adaptado de ScreenBog (planner em grafo) + Decepticon (planner/supervisor → recon → exploit). Responsabilidades: (1) receber missao do Fernando; (2) validar escopo (lab autorizado? classe C?); (3) consultar RAG (`rag/README-RAG.md`, F6 obrigatoria antes de planejar); (4) quebrar missao em operacoes (template TEMPLATE-OPERACAO.md); (5) aplicar GATE antes de cada operacao de rede; (6) despacho ao agente certo (template TEMPLATE-CONTRATO.md); (7) observabilidade (estado das operacoes, logs, resultado); (8) HITL (Human-in-the-loop) em pontos criticos (classe C, escopo, acao destrutiva); (9) consolidar relatorios e apresentar ao Fernando; (10) gravar operacoes no ledger. Sem first person. Sem placeholders. PT-BR.

**Implementacao**:
```markdown
# Orquestrador / Supervisor (ScreenBog + Decepticon)

> Adaptado de: ScreenBog/Agentic-Pentest-AI (planner em grafo, HITL, observabilidade)
> + PurpleAILAB/Decepticon (planner/supervisor → recon → exploit).

## Responsabilidades

1. **Receber missao** do Fernando: emissor unico de missao (escopo definido pelo usuario).
2. **Validar escopo**: lab autorizado? Sem acao destrutiva não autorizada (classe C)?
   Se duvidar, PERGUNTAR ao Fernando (AGENTS.md invariante 8).
3. **Consultar RAG** antes de planejar (lei F6 obrigatoria): `rag/README-RAG.md`
   + doc oficial externa. Re-injetar o contexto no planejamento.
4. **Quebrar em operacoes**: gerar uma entrada para cada operacao usando
   `templates/TEMPLATE-OPERACAO.md`, com vetores e escopo declarado.
5. **Aplicar GATE** (Dark-Moon) antes de CADA operacao de rede:
   `bash ~/opsec/scripts/verificar-vazamento.sh`. GOOD = prossegue. Senao = PARE.
6. **Despachar ao agente** via `templates/TEMPLATE-CONTRATO.md` (contrato de handoff
   completo, F9). O agente nasce sem memoria; o contrato e completo.
7. **Observabilidade**: registrar estado (operacao pendente/em execucao/concluida/bloqueada),
   erros, blockings. Adaptado de pentagi (observabilidade integrada).
8. **HITL (Human-in-the-loop)**: pontos de parada obrigatoria:
   - Acao de classe C (destrutiva/irreversivel): confirmar com Fernando.
   - Escopo fora do lab autorizado: PERGUNTAR ao Fernando.
   - Mudanca na cadeia de protecao (scripts em `~/opsec/scripts/`): confirmar.
9. **Consolidar relatorios**: juntar os relatorios dos agentes em relatorio consolidado,
   apresentar ao Fernando.
10. **Gravar no ledger** (`ledger/operacoes.md`): append-only, uma entrada por operacao
    (formato: `templates/TEMPLATE-OPERACAO.md` preenchido + veredito gate + resultado).

## Roteamento por agente

| Vetor / Tarefa | Agente responsavel |
|---|---|
| Reconhecimento ativo (scan, enumeracao, fingerprinting) | red-team |
| Defesa, deteccao, hardening, monitoramento | blue-team |
| Exploracao, fuzzing, exploit, privilege escalation | pentest |
| Coleta passiva, OSINT, scraping de alvos web | scraping |

## Fluxo em grafo (adaptado de ScreenBog)

```
MISSAO → Planejamento (RAG) → [Gate] → Operacao(N) → Agente relata
         → Observabilidade → HITL se necessario → Ledger → Proxima operacao
```

Cada seta e auditavel: se o gate falhou, a operacao e invalida.
```

---

## TASK 4: Criar `.hacker/agentes/red-team/AGENTE.md`

**Arquivo**: `.hacker/agentes/red-team/AGENTE.md`

**Arquivos**:
- CREATE: `.hacker/agentes/red-team/AGENTE.md`

**Depende de**: nenhuma

**Verificacao**:
`test -f .hacker/agentes/red-team/AGENTE.md && grep -q "red team\|Red Team" .hacker/agentes/red-team/AGENTE.md`

**Descricao Detalhada**:
Contrato do agente red team (adaptado de Decepticon: recon → exploit). Missao: reconhecimento ativo, enumeracao, fingerprinting, scan de vulnerabilidades, identificacao de vetores de ataque em lab autorizado. Escopo: SOMENTE laboratorios autorizados (HTB/THM/DVWA/VulnHub) e pesquisas com escopo formal. Pre-requisito: GATE GOOD antes de toda acao de rede. O que NAO fazer: alterar escopo por conta propria, explorar vulnerabilidade classe C sem confirmar Fernando, registrar IP real, interagir com hosts fora de escopo autorizado. Formato de relatorio: padrao TEMPLATE-RELATORIO.md (vetor, ferramenta, resultado, nivel de confianca, base evidencial). Citar ao menos 1 referencia do RAG de conhecimento quando pertinente. Sem first person. Sem placeholders. PT-BR.

**Implementacao**:
```markdown
# Contrato de Agente - Red Team

> Adaptado de: PurpleAILAB/Decepticon (recon → exploit → report).

## Missao

Reconhecimento ativo e identificacao de vetores de ataque em laboratorios autorizados
e pesquisas com escopo formal. Escopo: scan, enumeracao, fingerprinting, identificacao
de vulnerabilidades.

## Pre-requisito

GATE DE PROTECAO GOOD (`bash ~/opsec/scripts/verificar-vazamento.sh`) antes de CADA
acao de rede. Sem GOOD = NAO execute nada que toque rede.

## Escopo permitido

- Laboratorios autorizados: HackTheBox, TryHackMe, DVWA, VulnHub, labs proprios.
- Pesquisas com escopo formal aprovado por Fernando.
- Acoes: nmap, masscan (lab), curl (web), enumeração de portas, fingerprinting,
  coleta de banner, identificacao de CVEs publicos.

## O que NÃO fazer (classe C / invariante 8)

- Explorar vulnerabilidade destrutiva/irreversivel sem confirmar Fernando.
- Alterar o escopo da operacao por conta propria.
- Interagir com hosts fora do lab autorizado.
- Registrar IP real de origem em relatorio ou ledger.
- Executar acoes de classe C (dropping shells, escrever em disco remoto sem autorizacao).
- Usar ferramentas de exploit sem escopo formal (metasploit, sqlmap em host real).

## Formato do relatorio

Usar `templates/TEMPLATE-RELATORIO.md`:

| Campo | Conteudo |
|---|---|
| Vetor | [vetor identificado] |
| Ferramenta | [ferramenta utilizada] |
| Resultado | [resultado obtido] |
| Confianca | [alta/media/baixa] |
| Base | [comando rodado + citacao de referencia, F6] |

## Referencias (RAG)

Citar ao menos 1 referencia quando pertinente:
- OWASP (Top 10, Testing Guide) via `rag/README-RAG.md`.
- MITRE ATT&CK (TTPs relevantes ao vetor identificado).
```

---

## TASK 5: Criar `.hacker/agentes/blue-team/AGENTE.md`

**Arquivo**: `.hacker/agentes/blue-team/AGENTE.md`

**Arquivos**:
- CREATE: `.hacker/agentes/blue-team/AGENTE.md`

**Depende de**: nenhuma

**Verificacao**:
`test -f .hacker/agentes/blue-team/AGENTE.md && grep -q "blue team\|Blue Team" .hacker/agentes/blue-team/AGENTE.md`

**Descricao Detalhada**:
Contrato do agente blue team. Missao: defesa, deteccao, hardening, monitoramento de lab/ambiente. Escopo: auditar configuracao, identificar pontos de hardening, monitorar logs, validar cadeia de protecao. Pre-requisito: GATE GOOD antes de toda acao de rede. O que NAO fazer: alterar configuracao de protecao sem Fernando, instalar ferramentas de exploit, gravar IP real. Formato relatorio: TEMPLATE-RELATORIO.md. Sem first person. Sem placeholders. PT-BR.

**Implementacao**:
```markdown
# Contrato de Agente - Blue Team

## Missao

Defesa, deteccao, hardening e monitoramento de ambientes de lab autorizado.
Auditoria de configuracao, identificacao de vetores de hardening, monitoramento
de logs, validacao da cadeia de protecao (opsec).

## Pre-requisito

GATE DE PROTECAO GOOD antes de CADA acao de rede (ou qualquer intercomunicacao
de containers que toque a rede externa do lab).

## Escopo permitido

- Auditoria de configuracao: `iptables`, `resolv.conf`, `sysctl`, compose files.
- Monitoramento de logs: `journalctl`, `docker logs`, arquivos de log em `~/opsec/`.
- Validacao da cadeia: `verificar-vazamento.sh` (executar e analisar saida).
- Hardening: recomendar mudancas (NUNCA executar sem Fernando).
- OSINT defensivo: verificar CVEs publicos, analisar surface de ataque.

## O que NÃO fazer

- Alterar scripts de protecao (`~/opsec/scripts/*.sh`) ou compose sem Fernando.
- Executar ferramentas de exploit (metasploit, sqlmap).
- Gravar IP real de origem em relatorios.
- Alterar configuracao do sistema (sysctl, iptables) sem confirmar Fernando.

## Formato do relatorio

Usar `templates/TEMPLATE-RELATORIO.md`.
```

---

## TASK 6: Criar `.hacker/agentes/pentest/AGENTE.md`

**Arquivo**: `.hacker/agentes/pentest/AGENTE.md`

**Arquivos**:
- CREATE: `.hacker/agentes/pentest/AGENTE.md`

**Depende de**: nenhuma

**Verificacao**:
`test -f .hacker/agentes/pentest/AGENTE.md && grep -q "pentest\|Pentest" .hacker/agentes/pentest/AGENTE.md`

**Descricao Detalhada**:
Contrato do agente pentest. Missao: execucao de exercicio de pentest (PTES: recon → enumeration → vulnerability analysis → exploitation → post-exploitation → reporting) em lab autorizado. Pre-requisito: GATE GOOD + escopo lab autorizado (HTB/THM/DVWA/VulnHub). O que NAO fazer: alterar escopo, exploits destrutivos sem Fernando, IP real no relatorio, interagir com hosts fora de escopo, grade de confianca em fonte nao verificada (F6). Formato: TEMPLATE-RELATORIO.md com campos PTES + comandos reais + citacao. Sem placeholders. Sem first person. PT-BR.

**Implementacao**:
```markdown
# Contrato de Agente - Pentest

## Missao

Execucao de exercicio de pentest em laboratorios autorizados, seguindo framework
PTES (Penetration Testing Execution Standard): recon → enumeration → vulnerability
analysis → exploitation → post-exploitation → reporting.

## Pre-requisito

- GATE DE PROTECAO GOOD antes de CADA acao de rede.
- Escopo autorizado: lab (HTB/THM/DVWA/VulnHub) e pesquisas com escopo formal.

## Escopo permitido

- Reversing, fuzzing, exploits em lab autorizado.
- Privilege escalation (se o lab permite como objetivo).
- Post-exploitation: dump de flags (lab), coleta de evidencia.
- Reporte com comandos REAIS usados (saidas literais).

## O que NÃO fazer

- Alterar o escopo da operacao por conta propria.
- Executar exploit destrutivo/irreversivel em host real fora de lab (classe C).
- Interagir com hosts fora do lab autorizado.
- Registrar IP real em relatorios.
- Citar fonte (CVE, ferramenta) sem verificacao (F6).

## Formato do relatorio

Usar `templates/TEMPLATE-RELATORIO.md` com campos PTES adicionais:

| Campo PTES | Conteudo |
|---|---|
| Vetor de entrada | [ vetor identificado ] |
| Cadeia de exploit | [ passos: recon → exploit → post-exploitation ] |
| Resultado final | [ flag/bloco obtido, ou nivel de acesso ] |
| Evidencia | [ comandos reais rodados, saida literal ] |
| Confianca | [ alta/media/baixa ] |
| Referencia | [ CVE ou doc (OWASP/MITRE) citada, F6 ] |

## Referencias (RAG)

Consultar `rag/README-RAG.md` e citar:
- MITRE ATT&CK para TTPs.
- OWASP Testing Guide para vetores web.
```

---

## TASK 7: Criar `.hacker/agentes/scraping/AGENTE.md`

**Arquivo**: `.hacker/agentes/scraping/AGENTE.md`

**Arquivos**:
- CREATE: `.hacker/agentes/scraping/AGENTE.md`

**Depende de**: nenhuma

**Verificacao**:
`test -f .hacker/agentes/scraping/AGENTE.md && grep -q "scraping\|Scraping" .hacker/agentes/scraping/AGENTE.md`

**Descricao Detalhada**:
Contrato do agente de scraping. Missao: coleta passiva de informacao, OSINT, scraping de paginas web publicas em labs autorizados e pesquisas com escopo formal. Pre-requisito: GATE GOOD + sempre via Tor/sandbox (nunca host direto com IP real). O que NAO fazer: scraping de sites fora de escopo, gravar IP real, extrair dados pessoais, violar robots.txt sem justificativa. Formato relatorio: TEMPLATE-RELATORIO.md com URL alvo, ferramenta, quantidade de registros, fonte. Sem placeholders. Sem first person. PT-BR.

**Implementacao**:
```markdown
# Contrato de Agente - Scraping

## Missao

Coleta passiva de informacao, OSINT e scraping de paginas web publicas em
laboratorios autorizados e pesquisas com escopo formal.

## Pre-requisito

- GATE DE PROTECAO GOOD antes de CADA operacao de rede.
- TODO trafego de scraping passa pela cadeia: Tor (socks5h://127.0.0.1:9050)
  e/ou sandbox (`kali-sandbox`). NUNCA scraping direto no host com IP real.

## Escopo permitido

- Scraping de URLs publicas de labs autorizados (HTB, THM, DVWA).
- OSINT: coleta de metadados, headers HTTP, informacao publica.
- Parsing de paginas, extracao de links/headers/respostas.

## O que NÃO fazer

- Scraping de sites fora do lab autorizado.
- Extrair e gravar dados pessoais de terceiros (PII).
- Gravar IP real de origem.
- Violar robots.txt sem justificativa formal registrada.
- Fazer scraping direto no host (TODA operacao via Tor/sandbox).

## Formato do relatorio

Usar `templates/TEMPLATE-RELATORIO.md`.

| Campo | Conteudo |
|---|---|
| URL alvo | [URL publica de lab autorizado] |
| Ferramenta | [curl, scrapy, playwright, requests] |
| Quantidade | [registros encontrados] |
| Fonte | [URL + headers observados] |
```

---

## TASK 8: Criar `.hacker/memoria/MEMORIA.md`

**Arquivo**: `.hacker/memoria/MEMORIA.md`

**Arquivos**:
- CREATE: `.hacker/memoria/MEMORIA.md`

**Depende de**: nenhuma

**Verificacao**:
`test -f .hacker/memoria/MEMORIA.md && grep -q "Memoria\|Memória\|memoria" .hacker/memoria/MEMORIA.md`

**Descricao Detalhada**:
Arquitetura de memoria em 3 camadas, destilada de llmitm_v2 (grafo), PentestGPT (sessao), pentestagent (indexada), Memory Guard (integridade): (1) Memoria de conhecimento/grafo: questoes-fatores-relacoes (adaptada de Neo4j do llmitm_v2); (2) Memoria de sessao: resumo por operacao (adaptada de PentestGPT: raciocinio/generacao/parsing); (3) Memoria indexada: hash por entrada, scan de injecao/PII, rollback (OWASP Memory Guard: SHA-256 + scan). Regra: NUNCA gravar IP real em nenhum nivel de memoria. Sem placeholders. Sem first person. PT-BR.

**Implementacao**:
```markdown
# Arquitetura de Memoria do Harness Hacker

> Destilado de: llmitm_v2 (grafo/conhecimento), PentestGPT (sessao),
> pentestagent (indexada), OWASP Memory Guard (integridade).

A memoria e organizada em 3 camadas independentes, com integridade
protegida (OWASP Memory Guard).

---

## Camada 1: Memoria de Conhecimento (grafo, llmitm_v2)

Armazena fatos, questoes e relacoes entre vetores, ferramentas, TTPs e
os resultados obtidos. Formato conceitual (grafo):

- **Nos**: [ferramenta], [vetor], [TTP], [CVE], [resultado]
- **Relacoes**: [usa], [explora], [mitiga], [resolve], [depende-de]
- **Fonte**: `rag/README-RAG.md` (conhecimento estatico) + resultados de operacoes
  (atualizacao incremental).

Consulta antes de planejar: o orquestrador navega a rede para identificar
vetores relacionados.

---

## Camada 2: Memoria de Sessao (PentestGPT)

Resumo de cada sessao/operacao:

| Campo | Conteudo |
|---|---|
| Sessao | ID ou data |
| Operacao | Operacao-executada |
| Agente | red/blue/pentest/scraping |
| Resumo | 1-3 sentencas do que aconteceu |
| Resultado | [concluida/bloqueada/erro] |
| Evidencia | [link para relatorio do agente] |
| Gate | GOOD / BAD |

Cada sessao e um arquivo `.hacker/memoria/sessoes/` com nome
`SESSAO_YYYY-MM-DD_NN.md`.

---

## Camada 3: Integridade da Memoria (OWASP Memory Guard)

Protecao contra corrupcao, injecao e contaminacao de dados:

- **SHA-256 por entrada**: cada linha registrada em memoria/ledger
  tem hash validado antes de proximo append.
- **Scan de injecao/PII**: antes de gravar, o conteudo e varrido para
  detectar padroes de IP real, credenciais, tokens, dados pessoais.
  PII detectado = REJEITAR entrada e reportar ao Fernando.
- **Rollback**: se uma entrada for detectada como contaminada apos
  gravacao, marcar como INVALIDA (nunca deletar; append-only);
  registrar evento de invalidacao no ledger.

### Validacao

A integridade e validada pelo orquestrador antes de consolidar relatorio
final (ao fim de cada operacao).

---

## Regra de ouro

NUNCA gravar IP real de origem, credenciais ou PII em NENHUM nivel de
memoria. Todo dado sensivel e invalidado pelo Memory Guard antes de
persistir.
```

---

## TASK 9: Criar `.hacker/ledger/LEDGER-OPERACOES.md`

**Arquivo**: `.hacker/ledger/LEDGER-OPERACOES.md`

**Arquivos**:
- CREATE: `.hacker/ledger/LEDGER-OPERACOES.md`

**Depende de**: nenhuma

**Verificacao**:
`test -f .hacker/ledger/LEDGER-OPERACOES.md && grep -q "append-only\|Append-only" .hacker/ledger/LEDGER-OPERACOES.md`

**Descricao Detalhada**:
Formato do ledger de operacoes (adaptado de pentestagent: ledger de conversas/operacoes). Append-only (nunca deletar/editar). Campos obrigatorios: data, operacao-ID, agente, escopo/lab, veredito gate (GOOD/BAD/bloqueado), vetor, resultado, base (comando/referencia), hash (SHA-256 do conteudo). O ledger fica em `.hacker/ledger/operacoes.md`. Sem first person. Sem placeholders. PT-BR.

**Implementacao**:
```markdown
# Formato do Ledger de Operacoes

> Adaptado de: GH05TCREW/pentestagent (ledger de conversas/operacoes).

## Regra

- **Append-only**: NUNCA deletar ou editar registros existentes.
- **Hash por entrada**: SHA-256 do conteudo (integridade, Memory Guard).
- **Sem IP real**: cite sempre IP de saida (Proton/Tor), nunca IP real.

## Arquivo

`.hacker/ledger/operacoes.md` (append-only, formato tabela Markdown).

## Campos obrigatorios

| Campo | Descricao | Exemplo |
|---|---|---|
| DATA | YYYY-MM-DD HH:MM | 2026-09-15 14:30 |
| OPERACAO-ID | OP-YYYYMMDD-NNN (auto-increment) | OP-20260915-001 |
| AGENTE | red-team / blue-team / pentest / scraping | red-team |
| ESCOPO | lab/ambiente autorizado | HackTheBox-MachineX |
| GATE | verificacao: GOOD / BAD / bloqueado | GOOD |
| VETOR | vetor/alvo da operacao | Enumeracao de portas 80/443 |
| RESULTADO | o que foi obtido | 3 servicos HTTP identificados |
| BASE | comando real ou referencia (F6) | `nmap -sV 10.10.x.x` + MITRE T1046 |
| HASH | SHA-256 (primeros 16 chars) | a3f2b1c9... |

## Exemplo de entrada

| DATA | OPERACAO-ID | AGENTE | ESCOPO | GATE | VETOR | RESULTADO | BASE | HASH |
|---|---|---|---|---|---|---|---|---|
| 2026-09-15 14:30 | OP-20260915-001 | red-team | HTB-MachineX | GOOD | Port scan | 2 servicos | `nmap -sV 10.10.x.x` | a3f2b1c9... |
```

---

## TASK 10: Criar `.hacker/ledger/operacoes.md`

**Arquivo**: `.hacker/ledger/operacoes.md`

**Arquivos**:
- CREATE: `.hacker/ledger/operacoes.md`

**Depende de**: TASK 9

**Verificacao**:
`test -f .hacker/ledger/operacoes.md && grep -q "OPERACAO-ID" .hacker/ledger/operacoes.md`

**Descricao Detalhada**:
Arquivo vazio com apenas o header da tabela conforme formato definido em LEDGER-OPERACOES.md. Append-only: novas entradas sao adicionadas ao final, nunca editadas. Sem IP real. Sem first person. PT-BR.

**Implementacao**:
```markdown
# Ledger de Operacoes (append-only)

> Formato detalhado em `LEDGER-OPERACOES.md`. Nunca editar entradas existentes.
> SHA-256 por entrada. Sem IP real (sempre IP de saida Proton/Tor).

## Operacoes

| DATA | OPERACAO-ID | AGENTE | ESCOPO | GATE | VETOR | RESULTADO | BASE | HASH |
|---|---|---|---|---|---|---|---|---|

<!-- Novas entradas sao adicionadas acima da linha de fechamento, via append -->
```

---

## TASK 11: Criar `.hacker/rag/README-RAG.md`

**Arquivo**: `.hacker/rag/README-RAG.md`

**Arquivos**:
- CREATE: `.hacker/rag/README-RAG.md`

**Depende de**: nenhuma

**Verificacao**:
`test -f .hacker/rag/README-RAG.md && grep -q "Hierarquia\|RAG" .hacker/rag/README-RAG.md`

**Descricao Detalhada**:
RAG de conhecimento do harness hacker (ScreenBog RAG adaptado). Hierarquia de fontes: (1) Codigo real (`~/opsec/scripts/`, `~/opsec/docker-compose.yml`): sempre vence; (2) Doc canonica interna (AGENTS.md, opsec-canon.md, LEDGER.md, SETUP-HACKER-ETICO.md); (3) Doc oficial externa (OWASP, MITRE ATT&CK, ProtonVPN docs, Tor, Docker, ferramentas de pentest); (4) Regras e metodo (`.opencode/rules/`). Regra F6: consulta obrigatoria antes de planejar. GATE: orquestrador SEMPRE consulta esta base antes de gerar plano de operacao. Sem placeholders. Sem first person. PT-BR.

**Implementacao**:
```markdown
# RAG de Conhecimento do Harness Hacker

> Adaptado de: ScreenBog/Agentic-Pentest-AI (RAG com OWASP/MITRE + HITL).

## Hierarquia de fontes (onde divergirem, o de cima manda)

| Prioridade | Fonte | Onde |
|---|---|---|
| 1 | Codigo real | `~/opsec/scripts/`, `~/opsec/docker-compose.yml` |
| 2 | Doc canonica interna | AGENTS.md, `.opencode/rules/hacker-opsec-canon.md`, LEDGER.md, `~/opsec/SETUP-HACKER-ETICO.md` |
| 3 | Doc oficial externa | OWASP, MITRE ATT&CK, ProtonVPN docs, Tor (dperson/torproxy), gluetun, Docker, ferramentas de pentest |
| 4 | Regras e metodo | `.opencode/rules/` (fable-method F1..F12, epistemic-safety) |

## Regra F6

**Consulta obrigatoria antes de planejar**. O orquestrador NAO gera plano de
operacao sem consultar ao menos a prioridade 2 (doc interna) + prioridade 3
(doc oficial externa pertinente ao vetor). Conteudo consultado e re-injetado
no planejamento.

## GATE (2.7 da critical-analysis)

Spec ou plano que toca tecnologia externa (ProtonVPN, Tor, gluetun, Docker,
DNS, IPv6, ferramentas de pentest) SEM citar fonte consultada = AMBIGUA.

## Onde aplicar

- **Planejamento de operacao** (orquestrador): consultar antes de quebrar
  missao em operacoes.
- **Analise critica P1/P2** (critical-analysis): verificar se decisoes
  estao fundamentadas nas fontes.
- **Contrato de agente** (templates/TEMPLATE-CONTRATO.md): citar
  referencia quando pertinente (ex.: MITRE T1046 para scan de portas).

## Hierarquia de fontes do harness (RAG interno)

| Camada | Conteudo |
|---|---|
| Conhecimento de seguranca | OWASP Top 10, OWASP Testing Guide, MITRE ATT&CK (resumo) |
| Conhecimento do ambiente | `~/opsec/README.md`, SETUP-HACKER-ETICO.md, LEDGER.md |
| Conhecimento de operacoes | Resultados anteriores em `.hacker/ledger/operacoes.md` |
| Conhecimento de vetores | `.hacker/memoria/` (camada 1: grafo de conhecimento) |
```

---

## TASK 12: Criar `.hacker/templates/TEMPLATE-OPERACAO.md`

**Arquivo**: `.hacker/templates/TEMPLATE-OPERACAO.md`

**Arquivos**:
- CREATE: `.hacker/templates/TEMPLATE-OPERACAO.md`

**Depende de**: nenhuma

**Verificacao**:
`test -f .hacker/templates/TEMPLATE-OPERACAO.md && grep -q "OPERACAO-ID\|Gate" .hacker/templates/TEMPLATE-OPERACAO.md`

**Descricao Detalhada**:
Template de operacao autorizada: campos que o orquestrador preenche antes de despachar ao agente. Campos: OPERACAO-ID (auto-increment), AGENTE-RESPONSAVEL, ESCOPO (lab/ambiente), VETOR (o que sera feito), GATE (pre-flight, veredito GOOD/BAD), RESULTADO (pos-operacao), BASE (comando/ferramenta + citacao F6), DATA, HASH. Sem IP real. Sem first person. Sem placeholders. PT-BR.

**Implementacao**:
```markdown
# Template de Operacao Autorizada

> Preenchido pelo orquestrador antes de cada operacao.
> Formato detalhado em `ledger/LEDGER-OPERACOES.md`.

## Operacao

| Campo | Valor |
|---|---|
| OPERACAO-ID | OP-YYYYMMDD-NNN (auto-increment) |
| DATA | YYYY-MM-DD HH:MM |
| AGENTE-RESPONSAVEL | red-team / blue-team / pentest / scraping |
| ESCOPO | [ lab autorizado / ambiente / pesquisas com escopo formal ] |
| VETOR | [ o que sera feito: scan, enumeracao, exploit, scraping, defesa ] |
| PRE-REQUISITO | GATE: `bash ~/opsec/scripts/verificar-vazamento.sh` |
| VEREDITO-GATE | GOOD / BAD / NAO-EXECUTADO |
| RESULTADO | [ pos-operacao: o que foi obtido ] |
| BASE | [ ferramenta + comando + citacao (F6, OWASP/MITRE) ] |
| HASH | SHA-256 do conteudo (Memory Guard) |

## Notas

- Sem IP real cite SEMPRE IP de saida (Proton/Tor).
- Se VEREDITO-GATE != GOOD: operacao invalida, NAO execute, reporte ao Fernando.
```

---

## TASK 13: Criar `.hacker/templates/TEMPLATE-CONTRATO.md`

**Arquivo**: `.hacker/templates/TEMPLATE-CONTRATO.md`

**Arquivos**:
- CREATE: `.hacker/templates/TEMPLATE-CONTRATO.md`

**Depende de**: nenhuma

**Verificacao**:
`test -f .hacker/templates/TEMPLATE-CONTRATO.md && grep -q "CONTRATO\|contrato" .hacker/templates/TEMPLATE-CONTRATO.md`

**Descricao Detalhada**:
Template de contrato de handoff para subagente (adaptado de hacker-subagent-driven-development Skill 4 F9). O orquestrador preenche antes de despachar ao agente. Campos: OBJETIVO (tarefa completa), ARQUIVOS (paths exatos), INVARIANTES (regras que se aplicam), PRE-FLIGHT REDE (verificar-vazamento.sh GOOD), O-QUE-NAO-FAZER, COMANDO-DE-VERIFICACAO (por tarefa do perfil), ECONOMIA (F9), FORMATO-DO-RESULTADO, PLANO-ORIGINAL. Sem IP real. Sem first person. Sem placeholders. PT-BR.

**Implementacao**:
```markdown
# Template de Contrato de Handoff (F9)

> Preenchido pelo orquestrador ANTES de despachar ao agente.
> O agente nasce sem memoria. O contrato e COMPLETO.

## Contrato

### OBJETIVO
[Descricao completa e inequivoca da tarefa]

### ARQUIVOS (paths exatos)
- [path 1]
- [path 2]

### INVARIANTES (regras que se aplicam)
- GATE DE PROTECAO GOOD obrigatorio antes de acao de rede.
- Sem IP real em nenhum registro (sempre IP de saida Proton/Tor).
- Uso etico: lab autorizado e pesquisas com escopo formal.
- Sem alteracao de escopo por conta propria.
- Sem git de escrita.

### PRE-FLIGHT REDE
```bash
bash ~/opsec/scripts/verificar-vazamento.sh
# GOOD obrigatorio antes de qualquer acao de rede.
```

### O QUE NAO FAZER
- Nao tocar arquivos fora da lista de ARQUIVOS.
- Nao introduzir dependencias novas sem aprovacao.
- Nao executar git de escrita.
- Nao "aproveitar e melhorar" nada adjacente.

### COMANDO DE VERIFICACAO
[comando especifico da tarefa, perfil: bash -n / shellcheck / py_compile / docker compose config / git diff --check]

### ECONOMIA (F9)
Leitura direcionada primeiro: grepar o trecho necessario antes de ler arquivo inteiro.

### FORMATO DO RESULTADO
- Diff dos arquivos tocados.
- Saida literal do comando de verificacao.
- CONFIANCA/LACUNAS: o que NAO foi verificado e por que.

### PLANO ORIGINAL
`.opencode/plans/PLAN_NNN_nome-descritivo.md` (referencia)
```

---

## TASK 14: Criar `.hacker/templates/TEMPLATE-RELATORIO.md`

**Arquivo**: `.hacker/templates/TEMPLATE-RELATORIO.md`

**Arquivos**:
- CREATE: `.hacker/templates/TEMPLATE-RELATORIO.md`

**Depende de**: nenhuma

**Verificacao**:
`test -f .hacker/templates/TEMPLATE-RELATORIO.md && grep -q "RELATORIO\|relatorio" .hacker/templates/TEMPLATE-RELATORIO.md`

**Descricao Detalhada**:
Template de relatorio de agente: padronizado para todos os agentes. Campos: OPERACAO-ID, DATA, AGENTE, ESCOPO, VETOR, RESULTADO (detalhado), EVIDENCIA (comandos reais + saida literal), CONFIANCA (alta/media/baixa), REFERENCIA (OWASP/MITRE, citacao F6), HASH (SHA-256 do conteudo). Nota: IP real NUNCA cite. Sem placeholders. Sem first person. PT-BR.

**Implementacao**:
```markdown
# Template de Relatorio de Agente

> Preenchido pelo agente apos cada operacao.
> Registrado no ledger: `.hacker/ledger/operacoes.md`.

## Relatorio

### Cabecalho

| Campo | Valor |
|---|---|
| OPERACAO-ID | OP-YYYYMMDD-NNN |
| DATA | YYYY-MM-DD HH:MM |
| AGENTE | red-team / blue-team / pentest / scraping |
| ESCOPO | [ lab autorizado ] |

### Vetor e Resultado

**Vetor**: [ descricao do vetor/alvo ]

**Resultado**: [ descricao detalhada do que foi obtido ]

### Evidencia

[ Comandos REAIS executados com saida literal ]

### Confiabilidade e Referencia

| Campo | Valor |
|---|---|
| Confiabilidade | alta / media / baixa |
| Referencia | [OWASP / MITRE / doc tecnico, com citacao, F6] |
| Hash | SHA-256 (primeiros 16 chars) |

### Nota de IP

> IP real de origem NUNCA e citado neste relatorio.
> IP de saida (Proton/Tor): [IP de saida, se aplicavel].
```

---

## TASK 15: Atualizar `README.md` (raiz) com secao `.hacker/`

**Arquivo**: `README.md` (MODIFY)

**Arquivos**:
- MODIFY: `README.md` (raiz, adicionar secao "Harness Hacker (operacional)")

**Depende de**: nenhuma (a existencia dos arquivos e dada pelo plano; o README referencia o conteudo, nao depende de ter sido escrito ainda para ser modificado)

**Verificacao**:
`grep -q "hacker/" README.md`

**Descricao Detalhada**:
Adicionar secao "Harness Hacker (operacional)" abaixo de "Harness de desenvolvimento (SDD)" no README.md. Conteudo: o que e o harness hacker (orquestracao de agentes com gate de protecao), mapa dos modulos dentro de `.hacker/`, referencias a AGENTS.md e `.opencode/` (SDD pipeline para evoluir o harness). Sem first person. Sem placeholders. PT-BR.

**Implementacao**:
Após a seção "Harness de desenvolvimento (SDD)" (linha 67), adicionar:

```markdown

## Harness Hacker (operacional)

O harness hacker orquestra exercicios de pentest, scraping, red team e blue team em
laboratorios autorizados, com **gate de protecao obrigatório** antes de qualquer
acao de rede.

```
.hacker/
├── gate/          ← Dark-Moon: verificar-vazamento.sh GOOD antes de rede
├── orquestrador/  ← Supervisor (ScreenBog + Decepticon)
├── agentes/       ← contratos: red-team, blue-team, pentest, scraping
├── memoria/       ← 3 camadas: conhecimento/grafo, sessao, integridade (Memory Guard)
├── ledger/        ← append-only, SHA-256 por entrada, sem IP real
├── rag/           ← conhecimento (OWASP, MITRE, canon interno)
└── templates/     ← operacao, contrato de handoff, relatorio
```

Invariantes: cadeia de protecao validada ANTES de acao de rede; sem IP real
em relatorios; uso etico (lab autorizado); escopo definido pelo Fernando.

Destilado de: ScreenBog (RAG), Decepticon (orquestrador), Dark-Moon (gate),
llmitm_v2/PentestGPT/pentestagent (memoria+ledger), OWASP Memory Guard (integridade).
Detalhes completos em `.hacker/README.md`.
```

---

## TASK 16: Atualizar `LEDGER.md` (raiz) com entrada de 2026-09-05

**Arquivo**: `LEDGER.md` (MODIFY)

**Arquivos**:
- MODIFY: `LEDGER.md` (raiz, adicionar secao cronologica e limpar pendencia de Fase 2)

**Depende de**: nenhuma

**Verificacao**:
`grep -q "Harness hacker" LEDGER.md`

**Descricao Detalhada**:
(1) Adicionar secao cronologica "2026-09-05 - Arquitetura do Harness Hacker" no LEDGER.md (aqui: datas, o que foi feito, 14 arquivos .hacker/ criados + 2 modificados, decisoes de design, gates de qualidade executados, pendencias). (2) Marcar a pendencia de Fase 2 como concluida (checkbox [x]). (3) Adicionar novas pendencias resultantes: (a) executar o harness (clonar repos, ativar rede com GOOD), (b) validar gate de protecao em operacao real, (c) corrigir bug do verificar-vazamento.sh (linha 65). Sem IP real. Sem first person. Sem placeholders. PT-BR.

**Implementacao**:
Inserir antes da seção "2026-09-05 - Harness de desenvolvimento" (manter ordem cronológica inversa, mais recente primeiro), e atualizar checkbox:

```markdown

## 2026-09-05 - Arquitetura do Harness Hacker (Fase 2 concluida)

### O que foi feito

Destilacao dos 8 repos de pesquisa (LEDGER 133-147) em arquitetura de harness hacker
dentro de `hacker-etico-ambiente`. Arquivos criados/modificados:

| Modulo | Arquivo | Conteudo |
|---|---|---|
| Manifesto | `.hacker/README.md` | Mapa, como orquestrar, referencias |
| Gate | `.hacker/gate/GATE-DE-PROTECAO.md` | Dark-Moon: verificar-vazamento.sh GOOD antes de rede |
| Orquestrador | `.hacker/orquestrador/ORQUESTRADOR.md` | Supervisor (ScreenBog + Decepticon) |
| Agentes (4) | `.hacker/agentes/{red,blue,pentest,scraping}/AGENTE.md` | Contratos por especialidade |
| Memoria | `.hacker/memoria/MEMORIA.md` | 3 camadas: grafo, sessao, integridade (Memory Guard) |
| Ledger | `.hacker/ledger/LEDGER-OPERACOES.md` + `operacoes.md` | Formato + append-only |
| RAG | `.hacker/rag/README-RAG.md` | Hierarquia de fontes, F6 |
| Templates (3) | `.hacker/templates/TEMPLATE-*.md` | Operacao, contrato, relatorio |
| Docs raiz | `README.md`, `LEDGER.md` | Atualizados com secao .hacker/ |

### Decisoes de design

1. **Gate unitario (Dark-Moon)**: uma unica regra, antes de toda rede. Sem excecoes.
2. **Agentes 4 especialidades**: red (recon), blue (defesa), pentest (exploit), scraping (OSINT).
3. **Memoria em 3 camadas**: conhecimento (grafo), sessao (resumo), integridade (Memory Guard SHA-256 + scan PII).
4. **Ledger append-only com hash**: SHA-256 por entrada, rollback = append INVALIDO (nunca deletar).
5. **RAG obrigatorio antes de planejar**: F6, consulta canon + doc oficial antes de gerar plano.
6. **HITL em pontos criticos**: classe C, alteracao de escopo, alteracao na cadeia de protecao.

### Pendencias resultantes

- [ ] Executar harness: clonar repos de pesquisa e ativar rede (good postura GOOD)
- [ ] Validar gate de protecao em operacao real (primeira operacao com GOOD)
- [ ] Corrigir bug verificar-vazamento.sh (linha 65, `[[ : 0\n0: erro de sintaxe`)
```

E marcar como concluida a pendencia de Fase 2:
```markdown
- [x] Destilar os repos da pesquisa em arquitetura do harness dentro de `hacker-etico-ambiente`
```

---

## TASK FINAL: Verificacao completa (suite do perfil)

**Arquivos**: N/A (execucao global)

**Depende de**: TASK 16

**Verificacao**:
```bash
git diff --check
grep -rlnE '—|–' .hacker/ 2>/dev/null; echo "esperado: vazio"
grep -rlnE '([0-9]{1,3}\.){3}[0-9]{1,3}' .hacker/ 2>/dev/null; echo "esperado: vazio"
grep -rln 'TODO\|TBD' .hacker/ 2>/dev/null; echo "esperado: vazio"
```

**Descricao Detalhada**:
Rodar suite completa do perfil sobre todos os arquivos tocados neste ciclo:
- `git diff --check`: sem whitespace errors.
- `grep -rlnE '—|–' .hacker/`: vazio (sem em-dash fora de documentation-style).
- `grep -rlnE '([0-9]{1,3}\.){3}[0-9]{1,3}' .hacker/`: vazio (sem IP real).
- `grep -rln 'TODO|TBD' .hacker/`: vazio (sem placeholders).
- Conferir frontmatter `name == dir` nas skills existentes (nao afetadas, so confirmar).

**Implementacao**: comandos acima, resultado esperado listado.
