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
| Agente | red/blue/pentest/scraping/web-scanner |
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