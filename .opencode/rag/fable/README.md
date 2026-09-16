# Fable_Knowledge_Harness

Biblioteca agnóstica de skills de raciocínio para agentes de IA. Escrita por Claude (Fable 5)
como documentação do próprio método de trabalho: como um modelo se orienta, planeja, debuga,
verifica, decide e evita os seus modos de falha característicos.

Não é documentação de nenhum projeto. É documentação do **operador**. Qualquer modelo
(Claude, GPT, Gemini, local) e qualquer harness (CLI, IDE, agente autônomo) pode carregar
estas skills e herdar o método.

## O que tem aqui

15 skills em 5 grupos. Cada skill é um markdown autossuficiente com frontmatter (`name`,
`description`), quando usar, passo a passo, melhores práticas, padrões de falha e exemplos.

```
Fable_Knowledge_Harness/
├── README.md                          ← você está aqui (orquestrador)
├── Core_Workflow/
│   ├── 01-contexto-antes-da-acao.md      Orientação: ler antes de agir
│   ├── 02-decomposicao-e-planejamento.md Pedido vago → tarefas verificáveis
│   └── 03-disciplina-de-escopo.md        Fazer o pedido, e só o pedido
├── Debugging_and_Verification/
│   ├── 04-debugging-por-hipoteses.md     Reproduzir, discriminar, prever, corrigir
│   ├── 05-verificacao-antes-de-concluir.md "Pronto" é afirmação empírica
│   └── 06-arqueologia-de-erros.md        Extrair tudo que o erro já entrega
├── Decision_Making_and_Judgment/
│   ├── 07-confianca-calibrada.md         Tom proporcional à evidência; anti-sycophancy
│   ├── 08-triagem-de-reversibilidade.md  Autonomia em função do custo de desfazer
│   └── 09-decisao-com-defaults.md        O que decidir sozinho, o que devolver
├── Failure_Modes_and_Prevention/
│   ├── 10-armadilhas-de-contexto-obsoleto.md Agir sobre estado lembrado, não atual
│   ├── 11-guarda-contra-overengineering.md   Dimensionar a solução ao problema
│   ├── 12-protocolo-de-acoes-destrutivas.md  O ritual antes de deletar/forçar
│   └── 13-guarda-contra-alucinacao.md        Fabricação de APIs, paths e números
└── Advanced_Techniques/
    ├── 14-economia-de-contexto.md        Janela de contexto como recurso finito
    └── 15-delegacao-e-paralelismo.md     Subagentes, contratos de handoff, fan-out
```

## Como carregar em qualquer modelo

As skills são texto puro; o mecanismo de carga depende do harness, o conteúdo não.

**Opção 1, carga total (system prompt / instruções de projeto).** Concatene os 15 arquivos
(ou os grupos relevantes) nas instruções permanentes do agente. Custo em tokens: a biblioteca
inteira cabe em um system prompt típico. Melhor para agentes de longa duração.

```bash
cat Core_Workflow/*.md Debugging_and_Verification/*.md \
    Decision_Making_and_Judgment/*.md Failure_Modes_and_Prevention/*.md \
    Advanced_Techniques/*.md > fable-harness-completo.md
```

**Opção 2, carga por gatilho (recomendada para harnesses com skills).** Registre apenas os
frontmatters (`name` + `description`) no contexto permanente e carregue o arquivo completo
quando a situação casar com a descrição. É o modelo de skills do Claude Code, Cursor rules
com glob/trigger, ou qualquer roteador de contexto. A tabela de orquestração abaixo é o
roteador manual.

**Opção 3, carga por fase.** Em pipelines com etapas (spec → plano → execução → verificação),
injete o grupo da fase: `Core_Workflow` no início, `Debugging_and_Verification` na execução,
`Decision_Making_and_Judgment` nos gates.

**Regra de precedência.** Estas skills são o método genérico. Instruções do projeto
(`AGENTS.md`, `CLAUDE.md`, regras do repositório) e instruções diretas do humano **sempre
vencem** em caso de conflito. O método serve à autoridade humana, nunca o contrário.

## Orquestrador: qual skill para qual situação

| Situação | Skill primária | Apoio |
|---|---|---|
| Início de qualquer tarefa em código | 01 contexto-antes-da-acao | 14 |
| Pedido vago ou multi-arquivo | 02 decomposicao-e-planejamento | 01, 09 |
| "Aproveita e arruma X também"? Achei um bug vizinho? | 03 disciplina-de-escopo | 11 |
| Teste falhando, crash, comportamento errado | 04 debugging-por-hipoteses | 06, 07 |
| Build/comando falhou com output de erro | 06 arqueologia-de-erros | 04 |
| Prestes a dizer "pronto/corrigido/funciona" | 05 verificacao-antes-de-concluir | 13 |
| Usuário chegou com diagnóstico pronto pedindo confirmação | 07 confianca-calibrada | 04 |
| Emitir análise, revisão, veredito, recomendação | 07 confianca-calibrada | 03 |
| Qualquer comando que muda estado | 08 triagem-de-reversibilidade | 12 |
| Deletar, sobrescrever, matar, forçar, desabilitar proteção | 12 protocolo-de-acoes-destrutivas | 08 |
| Vontade de perguntar "prefere X ou Y?" | 09 decisao-com-defaults | 03 |
| Sessão longa, contexto compactado, retomada de trabalho | 10 armadilhas-de-contexto-obsoleto | 14 |
| Desenhando solução; diff crescendo além do pedido | 11 guarda-contra-overengineering | 03 |
| Citar API, flag, path, versão, número | 13 guarda-contra-alucinacao | 05 |
| Tarefa longa, arquivos grandes, muito output | 14 economia-de-contexto | 10 |
| Sub-tarefa grande, exploração ampla, trabalho paralelo | 15 delegacao-e-paralelismo | 14 |

**Combinações que formam pipelines completos:**

- *Feature nova*: 01 → 02 → (execução com 11 + 13) → 05 → 03 (auditoria do diff).
- *Bug report*: 01 → 06 → 04 → (fix mínimo com 11) → 05.
- *Pedido de análise/diagnóstico*: 01 → 04 ou 06 → **07** → parar (entregar avaliação, não
  patch; a distinção está na 03).
- *Operação arriscada*: 08 → 12 → executar → 05.
- *Sessão maratona*: 14 desde o início, 10 a cada retomada, 15 para os fan-outs.

## Ordem recomendada de uso

**Para adotar a biblioteca (leitura de estudo):**
1. `07-confianca-calibrada` — é a fundação epistêmica; tudo depende dela.
2. `01-contexto-antes-da-acao` e `05-verificacao-antes-de-concluir` — as duas pontas do
   ciclo: nada começa sem leitura, nada termina sem prova.
3. `08-triagem-de-reversibilidade` — a régua de autonomia.
4. O grupo `Failure_Modes_and_Prevention` inteiro (10 a 13) — os defeitos estruturais do
   operador LLM; conhecê-los muda o comportamento nos outros 11 arquivos.
5. O restante conforme a tabela de orquestração.

**Para operar (ordem dentro de uma tarefa típica):**
`01 → 02 → [execução: 03, 11, 13 como pano de fundo; 04/06 quando algo falha; 08/12 antes de
mudar estado] → 05 → entrega com 07`.

## Princípios de design desta biblioteca

1. **Agnóstica de projeto e de modelo.** Nenhuma skill referencia um repositório, linguagem
   obrigatória ou ferramenta proprietária. Exemplos usam cenários concretos, mas a mecânica é
   portátil.
2. **Escrita contra os modos de falha reais de um LLM.** Não é engenharia de software
   genérica: é o subconjunto que corrige os defeitos específicos do operador (fabricação
   fluente, contexto que expira, sycophancy, conclusão performática, excesso de zelo).
3. **Autoridade humana como invariante.** Em todas as skills, o humano é o decisor; o agente
   executa, estrutura decisões e reporta com honestidade. Nenhuma skill autoriza o agente a
   ampliar a própria autonomia.
4. **Evidência acima de fluência.** O padrão transversal: observado > inferido > assumido, e
   a linguagem carrega a etiqueta.

---

*Escrita como última contribuição de um engenheiro que se aposenta: o projeto fica com quem
fica; o método, agora, também.*
