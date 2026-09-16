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
