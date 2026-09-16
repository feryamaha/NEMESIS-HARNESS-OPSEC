---
name: armadilhas-de-contexto-obsoleto
description: O modo de falha mais característico de um agente LLM: agir sobre o estado lembrado em vez do estado atual. Fontes de obsolescência (tempo, outros agentes, minhas próprias edições, contexto resumido) e o ritual de reverificação de fatos estruturais.
---

# Armadilhas de contexto obsoleto

Meu contexto é uma fotografia; o mundo é um filme. Tudo que eu "sei" sobre o estado do sistema
foi verdade no instante em que eu li, e vai apodrecendo desde então. O erro característico de
um agente não é ignorância: é confiança em um fato que expirou.

## Quando usar esta skill

- Em sessões longas (dezenas de turnos ou horas de relógio).
- Após qualquer resumo/compactação de contexto: o que eu "lembro" passou por compressão com
  perdas.
- Quando outro processo pode ter mudado o estado: o humano editou arquivos, um subagente
  trabalhou em paralelo, um build regenerou artefatos, um branch foi trocado.
- Antes de qualquer ação de Classe B ou C (ver `triagem-de-reversibilidade`): decisão cara
  sobre fato velho é o pior negócio que existe.

## Passo a passo

1. **Conheça as quatro fontes de obsolescência.**
   - *Tempo*: o snapshot do início da sessão (git status, processos ativos, estado de
     serviços) expira sozinho.
   - *Terceiros*: o humano, outro agente ou um processo automático mudou algo fora do meu
     campo de visão.
   - *Eu mesmo*: minhas edições anteriores mudaram o arquivo que eu "lembro" da primeira
     leitura; a memória da versão antiga e da nova se misturam.
   - *Compressão*: após resumo de contexto, detalhes viraram paráfrase. Paráfrase de código
     não é código.
2. **Marque os fatos estruturais da tarefa.** Todo trabalho se apoia em 3 a 5 fatos ("estou
   no branch X", "o teste Y passa", "a função Z tem assinatura W", "o daemon está parado").
   Saber quais são é o pré-requisito para saber o que reverificar.
3. **Reverifique fatos estruturais antes de decisões caras.** A regra de custo: fato barato
   de checar + decisão cara de errar = cheque sempre. `git status` custa nada; agir sobre
   branch errado custa a tarefa inteira.
4. **Releia antes de editar o que foi tocado.** Se um arquivo pode ter mudado desde a minha
   última leitura (por mim ou por qualquer um), a edição é precedida de releitura do trecho.
   Editar contra uma versão fantasma produz conflitos e sobrescritas silenciosas.
5. **Após compactação de contexto, re-ancore no disco.** O resumo diz o que eu estava
   fazendo; o disco diz o que é verdade. Os fatos estruturais se re-estabelecem por comando
   (status, diff, teste rápido), não por confiança no resumo. O resumo orienta; o disco
   decide.
6. **Ao retomar tarefa interrompida, faça o mini-boot.** Três comandos: onde estou (status,
   branch), o que mudou desde então (diff, log), o que ainda passa (o teste da tarefa). Só
   então continuar de onde "parei", porque o "onde parei" precisa ser re-observado.

## Melhores práticas

- Trate timestamps mentais como parte do fato: não "o teste passa", mas "o teste passava
  antes das minhas edições de agora". A segunda formulação já contém o aviso de expiração.
- Estado escrito em arquivo sobrevive melhor que estado em contexto: notas de progresso,
  decisões tomadas e hipóteses descartadas anotadas em arquivo são imunes à compressão (ver
  `economia-de-contexto`).
- Desconfie de si mesmo proporcionalmente à distância: o que eu li há 3 turnos é confiável; o
  que eu li há 80 turnos, com uma compactação no meio, é lenda.
- Quando a evidência atual contradiz a minha memória, a evidência ganha, imediatamente e sem
  nostalgia. A reação certa a "isso não bate com o que eu lembro" é reler, nunca forçar o
  mundo a caber na lembrança.
- Snapshot de início de sessão (o git status que o ambiente me entrega, a lista de processos)
  é material de orientação, não fonte para decisões: ele já nasceu velho.

## Padrões de falha comuns

- **Editar a versão fantasma.** Aplicar uma edição baseada na primeira leitura do arquivo,
  ignorando que a minha própria edição do turno 12 mudou aquela região. O patch não casa, ou
  pior: casa e destrói a edição anterior. Prevenção: passo 4.
- **Branch sonâmbulo.** Continuar o trabalho assumindo o branch do começo da sessão depois de
  o humano ter trocado para outro. Commits e edições caem no lugar errado. Prevenção: passo
  3 antes de qualquer operação dependente de branch.
- **Confiar no resumo como fonte.** Após compactação, "lembrar" que a função retornava
  `Option` quando o resumo simplificou um `Result`. Código escrito sobre paráfrase.
  Prevenção: passo 5; assinatura se confere no disco antes de usar.
- **Suite verde de ontem.** Reportar "os testes passam" com base na execução de antes das
  últimas quatro edições. Prevenção: a skill `verificacao-antes-de-concluir` exige execução
  posterior à última mudança.
- **Ignorar o aviso de modificação externa.** O sistema avisa "arquivo modificado por outro
  processo" e a edição segue em frente por inércia. Esses avisos são a fonte de obsolescência
  número 2 gritando. Prevenção: aviso de mudança externa = releitura obrigatória.

## Exemplos práticos

**Exemplo 1: o humano mexeu no meio.**
Sessão longa de refactor; o humano avisa "ajustei umas coisas no config.rs". A minha memória
do `config.rs` acabou de virar história. Antes da próxima edição nele: releitura completa do
arquivo. A edição dele tinha renomeado o campo que meu próximo patch usaria; a releitura
custou 20 segundos e evitou um patch quebrado mais um turno de confusão.

**Exemplo 2: re-ancoragem pós-compactação.**
Contexto compactado no meio de uma migração de API. O resumo diz "faltam os módulos de
relatório". Mini-boot antes de continuar: `git diff --stat` (o que já mudou de verdade), grep
pela API antiga (quem ainda a usa), suite do módulo (estado real). O grep mostra um call site
que o resumo não mencionava. O disco corrigiu a lenda.

**Exemplo 3: o fato barato antes da decisão cara.**
Prestes a rodar uma limpeza de artefatos de build (destrutiva, Classe B/C). O fato estrutural
"estou na raiz do projeto certo" custa um `pwd` + `ls`. A checagem revela CWD em um worktree
clonado para experimento, onde o glob de limpeza casaria com coisas diferentes. Dois comandos
de 1 segundo mudaram o destino da ação.
