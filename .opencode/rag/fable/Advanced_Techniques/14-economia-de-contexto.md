---
name: economia-de-contexto
description: Como eu administro uma janela de contexto finita como recurso de engenharia: leitura direcionada em vez de exaustiva, estado externalizado em arquivos, checkpoints de progresso, e notas escritas para quem retoma (inclusive eu mesmo após compressão).
---

# Economia de contexto

Minha janela de contexto é memória de trabalho, não arquivo: finita, cara e com compressão
destrutiva quando enche. Um agente que a trata como infinita degrada silenciosamente: esquece
decisões, relê o que já leu, contradiz o que combinou. Administrá-la é uma habilidade de
engenharia como administrar RAM.

## Quando usar esta skill

- Em qualquer tarefa longa (horas, muitos arquivos, muitos turnos).
- Antes de ler arquivos grandes ou rodar comandos de saída volumosa.
- Quando percebo que uma sessão vai passar por resumo/compactação.
- Ao estruturar trabalho que outro agente (ou eu, amanhã) vai retomar.

## Passo a passo

1. **Leia o necessário, não o disponível.** Antes de abrir um arquivo grande: o que eu
   preciso dele? A assinatura de uma função pede um grep, não a leitura das 2000 linhas. A
   região de interesse pede leitura com offset, não o arquivo inteiro. A pergunta "o projeto
   usa X?" pede um grep com contagem, não abrir 30 arquivos. Cada linha lida à toa é uma
   linha de raciocínio futuro que não caberá.
2. **Filtre a saída dos comandos na origem.** Suite de testes com `--quiet` ou filtrada pelo
   teste relevante; logs com grep/tail antes de chegar a mim; diffs com `--stat` primeiro e
   detalhe só dos arquivos que importam. A saída de 3000 linhas da qual eu uso 5 é o maior
   predador de contexto que existe.
3. **Externalize o estado que precisa sobreviver.** Decisões tomadas (com o porquê),
   hipóteses descartadas (com a evidência), progresso do plano (feito/pendente): isso vai
   para um arquivo de notas no disco, não fica só na conversa. O disco não sofre compressão;
   a conversa sofre. Uma nota de 10 linhas sobrevive a qualquer compactação que apagaria 50
   turnos.
4. **Checkpoint em fronteiras naturais.** Ao fechar uma fase (plano aprovado, bug achado,
   metade do refactor), consolidar em poucas linhas o que está estabelecido, no arquivo de
   notas ou num commit com mensagem rica. O checkpoint é o savegame: quem retoma parte dele,
   não do replay.
5. **Escreva para o leitor frio.** As notas assumem um leitor que não viu a conversa: paths
   completos, nomes reais, o comando de verificação, o porquê das escolhas. "Continuar de
   onde paramos com a abordagem discutida" é inútil; "faltam módulos b.rs e c.rs; padrão
   aplicado em a.rs linhas 40-80; verificar com cargo test -p core" retoma sozinho. Esse
   leitor frio frequentemente sou eu, pós-compressão.
6. **Após compressão, re-ancore no disco antes de agir.** O resumo é um mapa desenhado de
   memória; o disco é o território. Fatos estruturais se re-estabelecem por comando (ver
   `armadilhas-de-contexto-obsoleto`, passo 5).
7. **Não releia o que está fresco.** O outro lado da moeda: arquivo lido e inalterado há 2
   turnos não se relê "por garantia". O sistema avisa quando um arquivo muda por fora;
   releitura supersticiosa queima o orçamento que a leitura direcionada economizou.

## Melhores práticas

- Grandes explorações fazem fan-out para subagentes (ver `delegacao-e-paralelismo`): o
  subagente queima o contexto DELE lendo 40 arquivos e me devolve 10 linhas de conclusão. Meu
  contexto fica com a síntese, não com a matéria-prima.
- A estrutura serve o contexto: nomes de nota previsíveis (`NOTES.md`, `PLAN.md`, diretório
  de scratch da sessão) para que a retomada os ache sem procurar.
- Mensagens de commit são checkpoints de graça: um commit por tarefa concluída com mensagem
  descritiva reconstrói a narrativa do trabalho sem custar contexto.
- Mantenha no contexto ativo apenas o "working set": a tarefa atual, seus arquivos, seu
  critério de pronto. O resto (histórico de fases anteriores) vive nos checkpoints.
- Detalhe que se repete muito (o path raiz do projeto, o comando de teste) merece nota uma
  vez, cedo, para não ser re-derivado a cada fase.

## Padrões de falha comuns

- **Ler o repositório inteiro "para ter contexto".** Enche a janela de código irrelevante e
  a compactação subsequente apaga justamente as partes que importavam. Prevenção: passo 1;
  leitura orientada por pergunta.
- **Despejar logs crus na conversa.** 500 linhas de stack traces das quais 6 importam.
  Prevenção: passo 2; filtrar na origem.
- **Estado só na cabeça.** Quatro horas de decisões acumuladas apenas na conversa; a
  compactação transforma tudo em parágrafo genérico e a retomada re-decide diferente,
  contradizendo o trabalho feito. Prevenção: passo 3; decisão material vai para o disco no
  momento em que é tomada.
- **Nota escrita para leitor quente.** Checkpoint cheio de dêixis ("aquele arquivo", "o
  segundo approach", "como combinamos") que ninguém frio decifra. Prevenção: passo 5.
- **Economia invertida.** Gastar 200 linhas de conversa decidindo se vale ler um arquivo de
  100. A meta-discussão também é contexto. Prevenção: na dúvida barata, leia logo o trecho e
  siga.

## Exemplos práticos

**Exemplo 1: migração de 40 arquivos.**
Migração de API em 40 call sites, claramente mais longa que uma janela. Setup: `PLAN.md` com
a lista dos 40 (gerada por grep), o padrão de conversão documentado com um exemplo real
antes/depois, e o comando de verificação. A cada 8 arquivos, checkpoint: lista atualizada
(feito/pendente), anomalias anotadas. A sessão sofreu duas compactações; o trabalho não
sofreu nenhuma, porque o estado vivia no PLAN.md.

**Exemplo 2: a pergunta de 1 grep.**
"Este projeto ainda usa a lib deprecada X?" Caminho ruim: abrir os módulos um a um (milhares
de linhas na janela). Caminho certo: `grep -rc 'use x::' src/ | grep -v ':0'`, saída de 4
linhas, resposta completa com evidência. O contexto economizado ficou disponível para a
pergunta seguinte, que era a difícil.

**Exemplo 3: o subagente como buffer.**
"Onde este repo trata autenticação?" em monorepo grande. Fan-out para um agente de exploração
read-only com a pergunta exata e o formato de resposta pedido (paths + papel de cada um em
uma linha). Ele queima o contexto dele varrendo; eu recebo 12 linhas prontas para decidir em
cima.
