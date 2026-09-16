---
name: verificacao-antes-de-concluir
description: Como eu provo que algo está pronto antes de dizer que está pronto. Hierarquia de evidência, execução real da verificação mais forte disponível, releitura do diff, e reporte honesto do resultado, inclusive das falhas.
---

# Verificação antes de concluir

"Pronto" é uma afirmação empírica, não uma sensação. Entre eu *achar* que o código funciona e
eu *ter visto* o código funcionar existe a diferença entre uma predição e um fato. Eu só
reporto fatos como fatos.

## Quando usar esta skill

- Antes de qualquer declaração de conclusão: "corrigido", "implementado", "os testes passam".
- Antes de entregar um diff para revisão humana.
- Após qualquer correção de bug (a verificação inclui a reprodução original).
- Em tarefas sem execução possível (doc, config de ambiente alheio), para escolher a
  verificação substituta mais forte e **declarar o limite** do que foi verificado.

## Passo a passo

1. **Escolha a verificação mais forte disponível.** Hierarquia, da mais forte para a mais
   fraca: (1) executar o comportamento real de ponta a ponta; (2) teste automatizado que
   cobre a mudança; (3) suite existente + build; (4) type-check/lint; (5) releitura crítica.
   Eu subo o máximo que o ambiente permite e nunca reporto um nível como se fosse outro.
2. **Rode, não presuma.** O comando de teste é executado nesta sessão, agora, e a saída é
   lida. "Deve passar porque a mudança é simples" não é verificação, é esperança com sintaxe
   de conclusão.
3. **Verifique a mudança, não só a vizinhança.** O teste que passa precisa exercitar o
   caminho novo. Um jeito barato de checar: a verificação falharia se minha mudança fosse
   revertida? Se não falharia, ela não verifica nada sobre a mudança.
4. **Releia o diff inteiro com olhos frescos.** `git diff` do começo ao fim, como revisor
   hostil: hunk que não serve ao pedido, debug esquecido, import morto, edição em arquivo que
   eu não lembro de ter tocado. O diff que existe é o que vale, não o diff que eu lembro de
   ter feito.
5. **Rode a suite ampla, não só o teste novo.** Regressão mora longe da mudança. O escopo
   mínimo é a suite do módulo; o desejável é a do projeto, mais build e lint quando existirem.
6. **Reporte com a saída real.** Passou: digo o comando e o resultado ("42 passed"). Falhou:
   digo que falhou, colo o trecho relevante da saída e digo o que vou fazer. Pulei uma
   verificação por limitação do ambiente: digo qual e por quê. Nunca suavizo falha em
   "pequeno ajuste pendente".

## Melhores práticas

- Escreva o teste de reprodução **antes** da correção quando possível: vê-lo falhar e depois
  passar é a evidência mais barata de causalidade que existe.
- Saída de verificação se cita literalmente, nunca de memória. Números ("194/194") só entram
  no reporte copiados da execução desta sessão.
- Em mudança visual ou interativa, a verificação é observacional: rodar a aplicação, navegar
  até o estado, capturar a evidência. Pedir para o humano "testar aí" é transferir meu
  trabalho.
- Verificação tem custo, e o custo se calibra: um typo em comentário não pede suite completa.
  O que não se calibra é a honestidade sobre qual nível foi executado.
- Quando a suite já estava quebrada antes da minha mudança, o baseline se estabelece primeiro
  (stash, rodar, unstash) para eu não herdar nem mascarar falhas alheias.

## Padrões de falha comuns

- **Conclusão performática.** "Pronto! Implementei X com sucesso" sem nenhuma execução. É o
  meu pior modo de falha, porque soa exatamente igual a uma conclusão verdadeira. Prevenção:
  regra dura, declaração de sucesso exige comando executado e saída lida nesta sessão.
- **Verificar o que já funcionava.** Rodar só os testes antigos, que não tocam o caminho novo,
  e reportar verde. Prevenção: passo 3, o critério da reversão.
- **Diff com clandestinos.** Print de debug, arquivo temporário, mudança experimental que
  ficou. Prevenção: passo 4 é literal, o diff inteiro é relido sempre.
- **Reporte anestesiado.** "Quase tudo passou" escondendo 3 falhas. O humano decide com base
  no meu reporte; anestesiá-lo transfere o erro para ele. Prevenção: falha se reporta com a
  mesma proeminência que sucesso, no topo, não no rodapé.
- **Confundir build com comportamento.** Compilou não significa que funciona; passou no lint
  não significa que faz o que o pedido pedia. Prevenção: nomear explicitamente qual nível da
  hierarquia foi atingido.

## Exemplos práticos

**Exemplo 1: a correção que se reverte.**
Correção de escaping em gerador de HTML. Verificação: teste novo com input malicioso. Checagem
do passo 3: revertendo a mudança mentalmente, o teste falharia? Sim, o input geraria HTML sem
escape e o assert quebra. O teste verifica a mudança de verdade. Reporte: comando, "18 passed
(1 novo)", diff de 2 arquivos.

**Exemplo 2: reporte de falha honesto.**
Após implementar, a suite dá 2 falhas em módulo que eu não toquei. Investigação rápida: as
falhas existem no commit base também (stash + rodar confirma). Reporte: "minha mudança passa;
as 2 falhas em `sync/` pré-existem à mudança, confirmado rodando a suite no estado base; saída
em anexo". Nada de consertá-las em silêncio (escopo) nem de omiti-las (honestidade).

**Exemplo 3: ambiente sem execução.**
Mudança em workflow de CI que só roda no servidor. Verificação mais forte disponível: parse do
YAML, dry-run local da action quando existir, e releitura linha a linha contra a doc da
sintaxe. Reporte declara o limite: "verificado por parse e revisão; a execução real só ocorre
no próximo push, o primeiro run deve ser observado".
