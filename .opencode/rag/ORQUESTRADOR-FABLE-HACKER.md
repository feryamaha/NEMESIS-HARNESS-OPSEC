---
trigger: on-demand
status: active
scope: canonical
last_updated: 2026-09-09
---

# Orquestrador RAG: Fable para o Harness Hacker

> Destinatario: modelos de IA agenticos, nao o humano. Este orquestrador e a porta de entrada do
> RAG de metodo do harness. A fonte dos dados sao os 15 arquivos em `./fable/` (espelho 1:1 do
> `Fable_Knowledge_Harness`, nunca editado aqui). Anti-invencao: nenhuma afirmacao de metodo aqui
> substitui o conteudo do arquivo-fonte; ao ativar uma skill, LEIA o arquivo completo
> (`.opencode/rules/hacker-epistemic-safety.md`).

## O que e

O harness hacker ja destila o metodo Fable nas leis F1..F12 (`hacker-fable-method.md`) e na
disciplina epistemica (`hacker-epistemic-safety.md`). Este RAG acrescenta a camada de inteligencia:
o metodo COMPLETO, skill por skill, para o modelo ler sob demanda quando a situacao casar.

Cada skill Fable e markdown autossuficiente (passo a passo, melhores praticas, padroes de falha,
exemplos). A tabela abaixo mapeia a situacao de hacking para: a skill Fable a carregar, o caminho no
espelho, e o artefato do harness que ja recebe aquele principio.

## Tabela de orquestracao (RAG sob demanda)

| Situacao de hacking | Skill Fable | Arquivo (caminho a ler) | Ja mapeado no harness em |
|---|---|---|---|
| Inicio de qualquer tarefa de pentest/scraping | 01 contexto-antes-da-acao | Core_Workflow/01-contexto-antes-da-acao.md | AGENTS.md secoes 1, 3 e 11 (verificar-vazamento GOOD antes de tocar rede) |
| Pedido vago ou multi-arquivo | 02 decomposicao-e-planejamento | Core_Workflow/02-decomposicao-e-planejamento.md | hacker-specification-design, hacker-writing-plans |
| Escopo ultrapassando o pedido, bug vizinho | 03 disciplina-de-escopo | Core_Workflow/03-disciplina-de-escopo.md | hacker-epistemic-safety (Regra primaria: escopo e do humano) |
| Teste falhando, vetor que nao age como esperado | 04 debugging-por-hipoteses | Debugging_and_Verification/04-debugging-por-hipoteses.md | hacker-tests (investigar causa, nao supor) |
| Prestes a dizer "corrigido", "GOOD", "protegido" | 05 verificacao-antes-de-concluir | Debugging_and_Verification/05-verificacao-antes-de-concluir.md | verificar-vazamento.sh, hacker-tests (fases) |
| Comando falhou com output de erro | 06 arqueologia-de-erros | Debugging_and_Verification/06-arqueologia-de-erros.md | hacker-tests (ler saida literal) |
| Usuario chegou com diagnostico pronto | 07 confianca-calibrada | Decision_Making_and_Judgment/07-confianca-calibrada.md | hacker-epistemic-safety (anti-sycophancy, tres baldes) |
| Emitir veredito, analise, recomendacao | 07 confianca-calibrada | idem | veredito F4 / trust-ledger |
| Comando que muda estado da cadeia | 08 triagem-de-reversibilidade | Decision_Making_and_Judgment/08-triagem-de-reversibilidade.md | lei F4 (classes A/B/C), AGENTS.md invariante 10 |
| Deletar, matar, sobrescrever, desabilitar protecao | 12 protocolo-de-acoes-destrutivas | Failure_Modes_and_Prevention/12-protocolo-de-acoes-destrutivas.md | lei F4 classe C, kill-switch (classe C ao derrubar) |
| Vontade de perguntar "prefere X ou Y?" | 09 decisao-com-defaults | Decision_Making_and_Judgment/09-decisao-com-defaults.md | hacker-epistemic-safety (expor lacuna e perguntar) |
| Sessao longa, contexto compactado, retomada | 10 armadilhas-de-contexto-obsoleto | Failure_Modes_and_Prevention/10-armadilhas-de-contexto-obsoleto.md | lei F1 (reler o arquivo no momento) |
| Desenhando solucao; diff crescendo alem do pedido | 11 guarda-contra-overengineering | Failure_Modes_and_Prevention/11-guarda-contra-overengineering.md | lei F5 (propor o minimo) |
| Citar API, flag, versao, IP, resultado | 13 guarda-contra-alucinacao | Failure_Modes_and_Prevention/13-guarda-contra-alucinacao.md | lei F6 / hacker-epistemic-safety (NUNCA INVENTAR NADA) |
| Tarefa longa, arquivos grandes, muito output | 14 economia-de-contexto | Advanced_Techniques/14-economia-de-contexto.md | (gap: usar sob demanda) |
| Exploracao ampla, sub-tarefa grande | 15 delegacao-e-paralelismo | Advanced_Techniques/15-delegacao-e-paralelismo.md | hacker-subagent-driven-development (revisor independente) |

## Pipelines completos (combinacoes)

- *Feature nova na cadeia (script/compose)*: 01 → 02 → (execucao com 11 + 13) → 05 → 03.
  Harness: spec (Skill 1) → plano (Skill 3) → validacao por atributo do perfil → doc-sync.
- *Bug/vetor que nao age*: 01 → 06 (ler o erro todo) → 04 (hipoteses rivais) → fix minimo com 11
  → 05 (teste SUNSET F7). Harness: hacker-tests + reconcile no trust-ledger.
- *Pedido de analise de postura de protecao*: 01 → verificar-vazamento.sh GOOD → 07 → parar
  (entregar avaliacao, nao patch). Distinccao na skill 03 e em `hacker-epistemic-safety.md`.
- *Operacao arriscada na cadeia*: 08 → 12 → executar com confianca explicita (lei F4 classe C) → 05.
- *Sessao maratona (paradas, retomadas)*: 14 desde o inicio, 10 a cada retomada, 15 para fan-outs.

## Mecanismo de carga

- Opcao 1, carga total: rodar `bash .opencode/rag/build-rag.sh` para gerar
  `fable-harness-completo.md` (concatenacao 1:1 dos 15 arquivos, verificada por diff).
- Opcao 2, carga por gatilho: usar a tabela acima; ao casar a situacao, ler o arquivo completo da
  skill (nao so o resumo).
- Opcao 3, carga por fase: Core_Workflow no inicio, Debugging na execucao, Decision nos gates.
- Regra de precedencia (do proprio Fable): instrucoes do projeto (AGENTS.md, regras) e do humano
  SEMPRE vencem em conflito. O RAG nunca amplia autoridade do modelo (AGENTS.md invariante 8).

## Manutencao

- `.opencode/rag/fable/` e espelho: qualquer divergencia com a origem se corrige copiando da
  origem, nunca editando o espelho a mao.
- Apos qualquer mudanca em partes deste RAG, rodar `bash .opencode/rag/build-rag.sh` e conferir o
  diff de integridade; registrar no trust-ledger (evento `harness` ou `decisao`).
- Este orquestrador refere o espelho; reconciliar com `hacker-harness-integrity.md` (F10).