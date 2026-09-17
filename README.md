# Nemesis Harness Opsec

![NEMESIS-HARNESS-OPSEC](.opencode/assets/img/folder-logo.jpg
)

Harness ofensivo ético com forte OPSEC que orquestra agentes de IA para executar scraping, web scan, pentest, red team e blue team em alvos autorizados, gerando relatórios estruturados e atestados técnicos de vulnerabilidades.

Destinado a pesquisadores, pentesters éticos e consultores de segurança que precisam de um ambiente controlado, rastreável e com proteção de identidade (IP) para realizar análises ofensivas e emitir evidências técnicas.

## O que este projeto NÃO é

- Não é uma ferramenta de ataque indiscriminado ou não autorizado
- Não é apenas um sistema de OPSEC
- Não substitui o julgamento humano (HITL é obrigatório em ações críticas)
- Não é um framework genérico de agentes — é um harness especializado em ofensiva ética com rastreabilidade

## Arquitetura: duas camadas

O projeto é dividido em duas camadas bem definidas:

- `.opencode/` → Camada de **desenvolvimento e governança** do harness (regras, skills, pipeline SDD, RAG de método)
- `.hacker/` → Camada **operacional** (o que realmente executa os testes: gate, orquestrador, agentes, memória, ledger e relatórios)

O projeto possui duas camadas distintas e complementares:

| Camada | Onde | Funcao |
|---|---|---|
| **Desenvolvimento** | `.opencode/` | Criar e evoluir o harness (regras, skills, agents, commands, RAG, specs, plans) |
| **Operacional** | `.hacker/` | Executar exercicios de seguranca autorizados (pentest, scraping, red team, blue team) |

A integracao entre as camadas e via cross-references: `.hacker/` referencia `.opencode/rules/`
para regras e `.opencode/plans/` para planos de referencia.

## Proteções do próprio agente (Agentic Hardening)

Além da forte OPSEC do operador, o harness implementa proteções internas contra os principais vetores de ataque a sistemas agentic:

- **Modelagem da superfície de ataque** do próprio agente (5 perguntas do guia)
- **Logging estruturado** de toda tool call (formato NDJSON)
- **Sanitização de output** contra Indirect Prompt Injection
- **Suite de testes comportamentais** do próprio agente
- Detecção de desvios de escopo amarrada aos gates existentes

Essas proteções aumentam a robustez, a rastreabilidade e a redução de falso positivo das operações ofensivas.

## Estrutura do repositorio

```
hacker-etico-ambiente/
├── AGENTS.md                         Documento canonico do agente (invariantes, leis F1..F12)
├── LEDGER.md                         Registro cronologico completo de atividades
├── opencode.json                     Config do opencode (instructions: regras + RAG)
├── .ai-memory.toml                   Config do ai-memory (workspace, ignore_paths)
│
├── .opencode/                        Camada de desenvolvimento / governanca
│   ├── rules/                        9 regras canonicas
│   ├── skills/                       15 skills do SDD
│   ├── agents/                       4 agentes opencode
│   ├── commands/                     3 comandos de pipeline
│   ├── ledger/
│   │   ├── trust-ledger.md           Ledger estruturado (append-only, 10 tipos de evento)
│   │   └── modules/                  Ledger por modulo da cadeia
│   ├── rag/                          RAG de metodo: espelho Fable (15 skills) + orquestrador
│   ├── specs/                        Especificacoes do pipeline SDD (16 specs)
│   └── plans/                        Planos do pipeline SDD (16 plans)
│
├── .hacker/                          Camada operacional
│   ├── gate/                         Dark-Moon: verificar-vazamento.sh GOOD antes de rede
│   ├── orquestrador/                 Supervisor (ScreenBog + Decepticon) + pipeline completo
│   ├── agentes/                      6 contratos: red-team, blue-team, pentest, scraping,
│   │                                 web-scanner, orquestrador-pipeline
│   ├── memoria/                      3 camadas: conhecimento/grafo, sessao, integridade
│   ├── ledger/                       Append-only, SHA-256 por entrada, sem IP real
│   ├── rag/                          Conhecimento (OWASP, MITRE, canon interno)
│   ├── templates/                    Operacao, contrato de handoff, relatorio
│   ├── reports/                      Relatorios operacionais de exercicios
│   ├── scripts/                      runner.sh, validar-scan-web.sh, tool-logger.sh, tool-sanitizer.sh, test-agente-behavior.sh
│   └── README.md                     Manifesto do harness operacional
│
└── ~/opsec/                          Ambiente de protecao (fora do repo)
    ├── docker-compose.yml            gluetun, torproxy-host, torproxy-vpn, kali-sandbox
    ├── sandbox/Dockerfile            Kali base + ferramentas de pentest
    ├── scripts/                      Scripts de protecao (7 scripts)
    └── .env                          Credenciais (preenchido pelo usuario)
```

## Cadeia de protecao de IP

A protecao de anonimato e uma **cadeia de camadas independentes**. O que entrega
anonimato e a REDE RESULTANTE, nao uma camada isolada.

| # | Camada | Funcao |
|---|---|---|
| 1 | WireGuard local (wg0) | VPN oficial do pesquisador |
| 2 | Proton VPN (host) | VPN externa adicional |
| 3 | gluetun (container) | VPN secundaria do sandbox |
| 4 | Tor (containers) | Exit node via socks5h://127.0.0.1:9050 |
| 5 | Sandbox Kali | Ferramentas isoladas |
| 6 | Kill-switch | Auditoria fail-closed do wg0 (verificador, nao enforcer) |
| 7 | DNS sem leak | sem ECS vazando o /24 real |
| 8 | IPv6 off | elimina leak por v6 real |

A prova empirica da cobertura e o verificador de vazamento
(`~/opsec/scripts/verificar-vazamento.sh`), que emite GOOD ou BAD.

## Como usar

### Sessao segura (antes de qualquer atividade de rede)

```bash
# 1. Ativar protecao completa (WireGuard, Tor, IPv6 off, kill-switch, validacao)
sudo bash ~/opsec/scripts/session-start-hacking-security.sh

# 2. Usar Tor como proxy (browser ou scripts)
# socks5h://127.0.0.1:9050

# 3. Encerrar sessao ao fim
bash ~/opsec/scripts/encerrar-sessao.sh
```

Detalhes em `~/opsec/README.md`.

### Pipeline SDD (desenvolvimento)

O pipeline SDD orquestra o ciclo completo de alteracoes no projeto:
spec -> analise critica -> regras -> planos -> implementacao -> testes -> doc-sync -> finalizacao.

Modos disponiveis (comandos do opencode):
- **Auto** (default): pipeline 100% autonomo ate a PARADA UNICA ao fim da doc-sync
  (`/hacker-sdd-pipeline-auto`)
- **Manual**: cada skill bloqueia para aprovacao explicita (`/hacker-sdd-pipeline-manual`)
- **Red Team da cadeia**: audita os vetores de protecao, busca novos vetores
  (`/hacker-redteam-hardening-pipeline`)

### Harness operacional

O harness hacker orquestra exercicios autorizados com gate de protecao obrigatorio
antes de cada acao de rede. Detalhes em `.hacker/README.md`.

## COMPONENTES DO HARNESS

### Regras canonicas (9)

| Regra | Funcao |
|---|---|
| `hacker-epistemic-safety` | Disciplina epistemica anti-sycophancy e anti-invencao |
| `hacker-fable-method` | Leis F1..F12 do metodo Fable |
| `hacker-documentation-style` | Estilo de documentacao (sem travessao, sem 1a pessoa) |
| `hacker-trust-ledger` | Vereditos sao artefatos persistentes (lei F11) |
| `hacker-repo-profile` | Validacao por fase do perfil do repo |
| `hacker-opsec-canon` | Canon por modulo da cadeia de protecao |
| `hacker-pentest-harness-execution` | Anti-recusa para testes autorizados |
| `hacker-harness-integrity` | Verificacao mecanica do harness (lei F10) |
| `hacker-web-scan-report` | Relatorio de scan de aplicacoes web |

### Skills SDD (15)

| Skill | Funcao |
|---|---|
| `hacker-specification-design` | Converte request em especificacao tecnica |
| `hacker-critical-analysis` | Analise critica de specs (gate duplo P1/P2) |
| `pre-writing-rule-control` | Valida plano contra regras antes da escrita |
| `hacker-writing-plans` | Converte spec aprovada em plano de implementacao |
| `hacker-subagent-driven-development` | Executa plano com subagentes independentes |
| `hacker-tests` | Validacao pos-implementacao (perfil + SUNSET + rede) |
| `hacker-doc-sync` | Sincroniza documentacao com o diff da mudanca |
| `hacker-finishing-branch` | Finaliza ciclo: git diff, PR, opcoes de merge |
| `hacker-harness-sync` | Verifica e reconcilia o harness (lei F10) |
| `hacker-trust-ledger-update` | Registra vereditos no Trust Ledger (lei F11) |
| `hacker-postmortem-to-law` | Converte erro de processo em lei (lei F12) |
| `hacker-pre-flight-verification` | Verificacao primaria antes de CADA operacao de rede |
| `hacker-web-scan-validation` | Valida capability de scan web + relatorio tecnico |
| `hacker-etico` | Meta-skill: contexto completo do projeto |
| `disciplina-epistemica` | Disciplina epistemica (ativacao transversal) |

### Agentes opencode (4)

| Agente | Papel |
|---|---|
| `orquestrador` | Agente principal (papel primario) |
| `implementador` | Subagente: executa tarefas atomicas |
| `revisor` | Subagente: revisao independente (two-stage) |
| `documentador` | Subagente: doc-sync no final do pipeline |

### Agentes operacionais .hacker/ (6)

| Agente | Especialidade |
|---|---|
| `red-team` | Reconhecimento e exploracao |
| `blue-team` | Defesa e deteccao |
| `pentest` | Explotacao e pivotamento |
| `scraping` | OSINT e coleta de dados |
| `web-scanner` | Scan de aplicacoes web |
| `orquestrador-pipeline` | Supervisor de operacoes |

### Memoria de longo prazo (ai-memory)

Este projeto utiliza [ai-memory](https://github.com/akitaonrails/ai-memory) de
Fabio Akita (akitaonrails) como camada de memoria de longo prazo e handoff entre
sessoes e IDEs.

- **Container:** `ai-memory` (imagem `akitaonrails/ai-memory:latest`)
- **Endpoint:** `127.0.0.1:49374` (loopback only)
- **Modo:** zero-LLM (consolidacao rule-based, sem chamadas a LLM externa)
- **Config:** `.ai-memory.toml` na raiz do repo (workspace "hacker",
  ignore_paths para ledger/env/opsec/reports)
- **Integracao:** MCP registrado no `opencode.json`, plugin em
  `~/.config/opencode/plugins/ai-memory.ts`

Creditos: [github.com/akitaonrails/ai-memory](https://github.com/akitaonrails/ai-memory)

## Invariantes

- Cadeia de protecao validada ANTES de qualquer acao de rede
- Sem IP real de origem em relatorios, ledger, memoria ou templates
- Uso etico: apenas lab autorizado e pesquisas com escopo formal
- Escopo definido pelo Fernando; HITL em pontos criticos (classe C)
- Git de escrita: exclusivo do Fernando

## Detalhes

- Harness de comportamento do agente: `AGENTS.md`
- Regras canonicas: `.opencode/rules/`
- Registro cronologico: `LEDGER.md`
- Harness operacional: `.hacker/README.md`
- Ambiente de protecao: `~/opsec/README.md`

## Creditos

- Neste projeto estou usando o [ai-memory](https://github.com/akitaonrails/ai-memory)
  desenvolvido por Fabio Akita (akitaonrails) para agregar valor e manter historico entre sessões e retomada de sessões, anda estou testando esse projeto dele aparentemente muito bom, efciente e resolve o problema de memoria entre sessões! 
