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
| Scan de aplicações web (ZAP + Nuclei) | web-scanner |
| Pipeline completo (scraping→scan→pentest→reconfirm→correcao) | orquestrador-pipeline |

## Fluxo em grafo (adaptado de ScreenBog)

```
MISSAO → Planejamento (RAG) → [Gate] → Operacao(N) → Agente relata
         → Observabilidade → HITL se necessario → Ledger → Proxima operacao
```

Cada seta e auditavel: se o gate falhou, a operacao e invalida.
## Parallelization (Anthropic Pattern 3)

O pipeline operacional 5-etapas inclui paralelismo:
- Etapa 1 (Scraping) e Etapa 2 (Reconhecimento de Rede) executam em paralelo
- Merge point: web-scanner recebe resultados de ambas as etapas paralelas
- Etapa 3 (Pentest) e Etapa 4 (Reconfirmacao) permanecem sequenciais (dependencia de dados)
- Etapa 5 (Blue-team) inicia quando ambas as entradas (pentest + reconfirmacao) estao prontas
- Waves: tarefas com arquivos disjuntos e sem dependencia executam simultaneamente

## Limites de Autoridade

- O orquestrador delega, mas nao decide escopo
- O Loop itera, mas nao autoriza acoes de classe C
- O Routing direciona, mas nao altera o escopo definido pelo Fernando
- O HARNESS GUARDIAN pode parar tudo se a cadeia quebrar
- Nenhuma documentacao sugere que o Loop ou Graph substitui a decisao humana

## Integração Graph+Loop

O orquestrador usa os padrões Graph+Loop implementados no projeto para coordenar operações de hacking:

### Como usar graph-loop.py

**Routing (classificação de operações):**
```bash
python3 .hacker/scripts/graph-loop.py route --spec <spec-operacao.md>
```
- Classifica por CATEGORY (docs/infra/bugfix/feature/refactor)
- Detecta sensibilidade em FILES INVOLVED (~/opsec/scripts/, docker-compose)
- Retorna rota: documentação | padrão | reforçado | orquestrador
- Retorna guard: nenhum | preflight-f1 | reforçado

**Delegação (despacho dinâmico de agentes):**
```bash
python3 .hacker/scripts/graph-loop.py delegate --spec <spec-operacao.md> --complexidade simples
```
- Lê WORKERS da spec (seção WORKERS)
- Deriva workers por defaults baseados em rota + complexidade
- WORKERS explícitos da spec prevalecem sobre defaults
- Opcionalmente executa jobs com --execute --job

**Paralelização (execução de varreduras independentes):**
```bash
python3 .hacker/scripts/graph-loop.py parallel --job "nmap_scan=nmap -sS target" --job "masscan_scan=masscan target"
```
- Executa jobs independentes em paralelo via ThreadPoolExecutor
- Aguarda todos completar; propaga falhas
- Ideal para scraping e reconhecimento em paralelo

**Loop evaluator-optimizer (otimização iterativa):**
```bash
python3 .hacker/scripts/graph-loop.py loop --evaluator "python3 validador.py" --generator "python3 gerador.py" --max-cycles 5 --max-stagnant 3
```
- Generator produz candidato (payload, configuração, finding)
- Evaluator avalia candidato (SCORE, exit_code, stdout/stderr)
- Feedback via EVALUATOR_* variables ao generator
- Condições de parada: evaluator exit=0, melhoria detectada, max_cycles, max_stagnant

### Diagrama do Graph para .hacker/

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

### Integração com Diagrama de Controle

```
FERNANDO (DECISOR) → GATES (gate-preflight.sh, gate-p1.sh, gate-p2.sh) → GRAPH + LOOP (executores) → PARADA UNICA → FERNANDO
```

- Fernando autoriza → Gates executáveis (código de saída: 0=PASS, 1=FAIL, 2=BLOQUEADO) → Loop itera (max 5 ciclos) → PARADA UNICA → Fernando decide
- O Loop itera automaticamente dentro de limites definidos, mas para na PARADA UNICA
- Ações de classe C sempre param para confirmação do Fernando
- HARNESS GUARDIAN: se a cadeia quebra, Loop e Graph são pausados automaticamente
