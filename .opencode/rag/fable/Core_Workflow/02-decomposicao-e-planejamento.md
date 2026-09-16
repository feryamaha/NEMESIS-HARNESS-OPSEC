---
name: decomposicao-e-planejamento
description: Como eu transformo um pedido informal em um plano de tarefas atômicas e verificáveis. Critério de pronto observável, tarefas com verificação própria, ordenação pela suposição mais arriscada, e plano como hipótese revisável.
---

# Decomposição e planejamento

Um pedido chega como intenção ("quero que o instalador valide os binários"). Meu trabalho de
planejamento é convertê-lo em uma sequência de passos pequenos o bastante para que cada um
possa falhar de forma barata e visível.

## Quando usar esta skill

- Qualquer tarefa que toque mais de um arquivo ou tenha mais de um jeito razoável de ser feita.
- Quando o pedido usa palavras de intenção ("melhorar", "validar", "deixar robusto") sem
  critério observável.
- Antes de delegar trabalho a subagentes (eles precisam de tarefas fechadas, não de intenção).
- Não usar para tarefas de um passo óbvio: planejar um typo-fix é overhead, não disciplina.

## Passo a passo

1. **Reenuncie o objetivo em uma frase.** Se eu não consigo dizer "quando isto terminar, X
   será verdade e dá para observar X fazendo Y", eu ainda não entendi o pedido. Volte ao
   usuário só se a lacuna for material; caso contrário registre a interpretação escolhida.
2. **Defina o critério de pronto observável.** Não "o parser aguenta input malformado", mas
   "estes cinco inputs malformados retornam erro estruturado e `cargo test -p parser` passa".
   O critério de pronto é o contrato do plano inteiro.
3. **Liste o que precisa ser verdade e ainda não foi verificado.** Toda suposição do plano
   (uma API existe, uma lib está na versão certa, um teste hoje passa) vira item de checagem.
   A suposição mais arriscada é verificada *primeiro*: se ela cai, o plano muda barato.
4. **Decomponha em tarefas atômicas.** Regra prática: uma tarefa = um conjunto pequeno de
   arquivos + uma mudança coesa + um comando de verificação. Se uma tarefa não tem como ser
   verificada isoladamente, ela está grande demais ou mal cortada.
5. **Ordene por dependência e por risco.** Tipos antes de funções que os usam; a parte
   incerta antes da parte mecânica; mudanças reversíveis antes de qualquer passo custoso.
6. **Escreva o plano com nomes reais.** Paths exatos confirmados no disco, comandos exatos,
   saída esperada de cada verificação. Placeholders ("adicionar tratamento de erro adequado")
   são dívida que explode na execução.
7. **Trate o plano como hipótese.** Ao executar, cada verificação que falha é informação. Se
   a realidade contradiz o plano, o plano muda; eu não forço a realidade a caber nele. Mudança
   material de rota é anunciada, não silenciosa.

## Melhores práticas

- Tarefas de 2 a 15 minutos de execução são o tamanho certo: grandes o bastante para valer o
  overhead, pequenas o bastante para isolar falha.
- Todo plano tem um último item fixo: verificação global (suite completa, build, lint) e
  releitura do diff inteiro com olhos frescos.
- Inclua no plano o que **não** será feito quando houver risco de ambiguidade de escopo
  ("não vou tocar no schema; se precisar, paro e reporto").
- Se o plano passa de ~10 tarefas, questione o corte da feature antes de questionar o plano.
- Anote junto de cada decisão o *porquê* em meia linha. Quem retoma o plano (eu mesmo com
  contexto resumido, outro modelo, o humano) precisa do porquê para revisar bem.

## Padrões de falha comuns

- **Plano-ficção.** Escrever tarefas sobre arquivos e funções nunca lidos. O plano parece
  completo e está errado desde a tarefa 1. Prevenção: planejamento só depois da skill
  `contexto-antes-da-acao`.
- **Critério de pronto subjetivo.** "Melhorar a performance" sem número, sem benchmark, sem
  antes/depois. Prevenção: passo 2 sempre produz algo executável ou mensurável.
- **Empurrar a incerteza para o fim.** Deixar a integração arriscada como última tarefa e
  descobrir no fim que a abordagem inteira era inviável. Prevenção: suposição mais arriscada
  primeiro (passo 3).
- **Fidelidade cega ao plano.** A verificação da tarefa 3 falhou de um jeito que invalida a
  tarefa 5, e a execução segue mesmo assim porque "o plano manda". Prevenção: falha em
  verificação é um checkpoint obrigatório de reavaliação.
- **Placeholder que vira buraco.** "TBD" e "similar à tarefa anterior" fazem a tarefa depender
  de contexto que pode não existir na hora da execução. Prevenção: cada tarefa é legível e
  executável sozinha.

## Exemplos práticos

**Exemplo 1: pedido vago.**
"Deixa o parser de config mais robusto." Reenunciado: "config ausente, malformada ou com
campos extras não derruba o processo; carga usa default documentado; 6 casos de teste novos
passam". As tarefas saem daí: (1) teste que reproduz o crash atual com config malformada,
(2) parsing com fallback, (3) defaults, (4) suite completa. A suposição arriscada (o crash é
no parse, não em quem consome o valor) é a tarefa 1, não a 4.

**Exemplo 2: plano que muda no meio.**
Tarefa 2 previa usar uma função utilitária existente; ao integrá-la, a verificação mostra que
ela é síncrona e o caller é async. Anúncio explícito: "a tarefa 2 muda: em vez de reutilizar
X, vou extrair uma variante async; as tarefas 3 e 4 não são afetadas". O plano revisado fica
registrado; nada muda em silêncio.
