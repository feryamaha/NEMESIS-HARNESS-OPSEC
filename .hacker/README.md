# .hacker/ - Harness Hacker Etico (operacional)

> Manifesto do harness operacional. Complementa o harness de desenvolvimento em `.opencode/`.
> Destilado de: ScreenBog, Decepticon, pentagi, llmitm_v2, PentestGPT, pentestagent,
> Dark-Moon e OWASP Memory Guard (registro em `LEDGER.md`).

## O que e

O harness hacker orquestra exercicios autorizados de pentest, scraping, red team,
blue team e scan de aplicacoes web em laboratorios autorizados (HTB, THM, DVWA,
VulnHub) e pesquisas com escopo formal, com **gate de protecao obrigatorio**
antes de qualquer acao de rede e protecao do IP de origem do pesquisador em
todos os artefatos.

## Mapa de modulos

```
.hacker/
├── gate/          ← Dark-Moon: verificar-vazamento.sh GOOD antes de rede
├── orquestrador/  ← Supervisor (ScreenBog + Decepticon) + Pipeline Completo
├── agentes/       ← contratos: red-team, blue-team, pentest, scraping, web-scanner,
│                     orquestrador-pipeline
├── memoria/       ← 3 camadas: conhecimento/grafo, sessao, integridade (Memory Guard)
├── ledger/        ← append-only, SHA-256 por entrada, sem IP real
├── rag/           ← conhecimento (OWASP, MITRE, canon interno)
├── templates/     ← operacao, contrato de handoff, relatorio
└── reports/       ← relatorios operacionais de scan web
```

## Como orquestrar

1. O orquestrador recebe a missao do Fernando (emissor unico de escopo).
2. Consulta o RAG (hierarquia de fontes, F6) antes de planejar.
3. Quebra a missao em operacoes (`templates/TEMPLATE-OPERACAO.md`).
4. Aplica o gate de protecao antes de CADA operacao de rede.
5. Despacha ao agente certo via contrato de handoff (`templates/TEMPLATE-CONTRATO.md`).
6. Consolida relatorios e grava tudo no ledger (append-only, sem IP real).
7. O runner (`.hacker/scripts/runner.sh`) valida o ciclo antes do fechamento: gate GOOD (via marcador [5] RESULTADO FINAL), escopo no ledger, hash do ledger. Referencias cruzada para ISSUE-001 (enforcement fisico via gate-enforcement.sh).

## Invariantes

- Cadeia de protecao validada ANTES de acao de rede (`verificar-vazamento.sh` GOOD).
- Sem IP real de origem em relatorios, ledger, memoria ou templates (sempre IP de saida).
- Uso etico: apenas lab autorizado e pesquisas com escopo formal.
- Escopo definido pelo Fernando; HITL em pontos criticos (classe C, escopo, cadeia).
- Git de escrita: exclusivo do Fernando.

## Referencias

- Regras e metodo: `.opencode/rules/` (fable-method F1..F12, epistemic-safety, doc-style).
- Registro cronologico: `LEDGER.md` (raiz) e `.opencode/ledger/trust-ledger.md`.
- Especificacao da arquitetura: `.opencode/specs/SPEC_001_arquitetura-harness-hacker.md`.
- Plano de implementacao: `.opencode/plans/PLAN_001_arquitetura-harness-hacker.md`.
- Scan web: `.opencode/specs/SPEC_003_web-app-scan-report.md`, `.opencode/plans/PLAN_003_web-app-scan-report.md`.