# RAG de Conhecimento do Harness Hacker

> Adaptado de: ScreenBog/Agentic-Pentest-AI (RAG com OWASP/MITRE + HITL).

## Hierarquia de fontes (onde divergirem, o de cima manda)

| Prioridade | Fonte | Onde |
|---|---|---|
| 1 | Codigo real | `~/opsec/scripts/`, `~/opsec/docker-compose.yml` |
| 2 | Doc canonica interna | AGENTS.md, `.opencode/rules/hacker-opsec-canon.md`, LEDGER.md, `~/opsec/SETUP-HACKER-ETICO.md` |
| 3 | Doc oficial externa | OWASP, MITRE ATT&CK, WireGuard docs, ProtonVPN docs, Tor (dperson/torproxy), gluetun, Docker, ferramentas de pentest |
| 4 | Regras e metodo | `.opencode/rules/` (fable-method F1..F12, epistemic-safety) |

## Regra F6

**Consulta obrigatoria antes de planejar**. O orquestrador NAO gera plano de
operacao sem consultar ao menos a prioridade 2 (doc interna) + prioridade 3
(doc oficial externa pertinente ao vetor). Conteudo consultado e re-injetado
no planejamento.

## GATE (2.7 da critical-analysis)

Spec ou plano que toca tecnologia externa (WireGuard, ProtonVPN, Tor, gluetun, Docker,
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
| Conhecimento de seguranca | OWASP Top 10, OWASP Testing Guide, NVD, MITRE ATT&CK (resumo) |
| Conhecimento do ambiente | `~/opsec/README.md`, SETUP-HACKER-ETICO.md, LEDGER.md |
| Conhecimento de operacoes | Resultados anteriores em `.hacker/ledger/operacoes.md` |
| Conhecimento de vetores | `.hacker/memoria/` (camada 1: grafo de conhecimento) |

## Regra F6 para scan web

**Consulta obrigatoria a OWASP Testing Guide + NVD antes de gerar relatorio de scan web.** O agente `web-scanner` NAO gera relatorio sem consultar ao menos a prioridade 3 (doc oficial externa pertinente ao vetor web). Conteudo consultado e re-injetado no relatorio.

## Procedimento de Refresh do RAG

- Procedimento: `.hacker/rag/REFRESH-PROCEDURE.md`
- Cadencia: mensal ou inicio de cada ciclo de pentest
- Fonte: `/home/fernando/Downloads/Fable_Knowledge_Harness`
- Verificacao de integridade: `diff -r /home/fernando/Downloads/Fable_Knowledge_Harness .opencode/rag/fable/`
- Ultima sincronizacao: registrar em `.hacker/rag/REFRESH-PROCEDURE.md`