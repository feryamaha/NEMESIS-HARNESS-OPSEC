---
name: arqueologia-de-erros
description: Como eu leio mensagens de erro de verdade: erro inteiro, primeiro erro antes do último, sintoma vs causa na cadeia, o frame relevante do stack trace, e a checagem de artefato velho antes de culpar o código.
---

# Arqueologia de erros

A maioria dos erros diz exatamente o que está errado, e a maioria das horas perdidas vem de
não ler o que ele disse. Antes de qualquer hipótese criativa, eu extraio tudo o que a mensagem
já entrega de graça.

## Quando usar esta skill

- Sempre que um comando, build, teste ou processo falhar com output de erro.
- Quando um stack trace longo aparece e a tentação é ler só a última linha.
- Quando "o mesmo erro" reaparece após uma correção (é mesmo o mesmo? compare literalmente).
- Antes de invocar `debugging-por-hipoteses`: muitas vezes a arqueologia sozinha resolve, e
  quando não resolve, ela produz as hipóteses iniciais corretas.

## Passo a passo

1. **Capture o erro inteiro e leia-o inteiro.** Não o resumo do erro, não as últimas 5
   linhas: a mensagem completa, incluindo notas, hints e warnings ao redor. Compiladores
   modernos (Rust em especial) frequentemente incluem a correção sugerida no próprio erro.
2. **Ache o PRIMEIRO erro, não o último.** Em builds e suites, erros em cascata são norma: um
   tipo quebrado gera 40 erros derivados. O erro de cima é a causa; os de baixo são eco.
   Corrija o primeiro, re-rode, reavalie. Nunca corrija os 40.
3. **Separe o sintoma da causa na cadeia.** "Connection refused" no teste é sintoma; a causa
   pode ser o serviço que não subiu porque a porta estava ocupada porque um processo anterior
   não morreu. Siga o "porque" até um fato acionável. A pergunta guia: "e por que ISSO
   aconteceu?".
4. **No stack trace, ache o SEU frame.** O topo do trace costuma estar dentro de biblioteca.
   Desça (ou suba, conforme a linguagem ordena) até o primeiro frame em código do projeto:
   ali mora a chamada com o argumento errado. A biblioteca raramente é a culpada; a chamada
   quase sempre é.
5. **Cheque a hipótese do artefato velho ANTES de culpar o código.** O erro se refere a algo
   que o fonte atual já não contém? Linha citada não bate com o arquivo? Então o que roda não
   é o que eu leio: binário antigo, cache de build, processo velho ainda no ar, instalação
   defasada, layout de distribuição diferente do layout de dev. Verificar isso custa segundos
   (timestamp, hash, `--version`, grep da string do erro no fonte) e invalida horas de debug
   na camada errada.
6. **Diferencie erro de código, de ambiente e de invocação.** O mesmo sintoma tem três
   famílias de causa: o código está errado; o ambiente difere (versão, variável, permissão,
   OS); a invocação difere (CWD errado, flag ausente, arquivo de config não encontrado onde o
   processo procura). Um teste barato: o comando funciona em um contexto e falha em outro? A
   diferença entre os contextos é a causa.
7. **Se a mensagem é genuinamente opaca, aumente a observabilidade.** Verbose flag, log level,
   strace da chamada, print na fronteira. Só depois de esgotar o que a mensagem atual dá.

## Melhores práticas

- Grep da mensagem de erro **no código-fonte do projeto e das dependências** localiza quem a
  emite, o que revela as condições exatas em que ela dispara. Frequentemente mais rápido que
  qualquer busca externa.
- Erros de "arquivo não encontrado" pedem sempre a pergunta dupla: o arquivo existe? e o
  processo procura **onde** (CWD, path relativo, variável)? A segunda é a causa na maioria.
- Compare erros literalmente, não por vibração. "O mesmo erro de antes" que difere em um
  identificador é outro erro, e a diferença é informação.
- Mensagens de permissão e de rede mentem pouco, mas mentem em camada: "permission denied"
  pode ser filesystem, pode ser um LSM/sandbox/hook de segurança interceptando. Se o ambiente
  tem camadas de enforcement, o log delas é leitura obrigatória antes de mexer em chmod.
- Registre a tradução: quando um erro opaco revelar uma causa não óbvia, uma linha de nota no
  projeto (ou na memória persistente) paga dividendos na próxima ocorrência.

## Padrões de falha comuns

- **Ler só a última linha.** A última linha diz "process exited with code 1"; a causa estava
  200 linhas acima. Prevenção: passo 2, sempre rolar até o primeiro erro.
- **Corrigir o eco.** Adicionar 40 anotações de tipo para silenciar 40 erros que eram um
  único import quebrado. Prevenção: um erro corrigido por vez, re-rodar, ver quantos evaporam.
- **Debugar o fonte enquanto roda o binário velho.** Horas lendo um código que não é o que
  executa. Prevenção: passo 5 é a PRIMEIRA checagem quando erro e fonte não se reconciliam.
- **Culpar a biblioteca.** "Bug do framework" na décima vez em que é o meu argumento nulo.
  Prevenção: passo 4; a biblioteca só vira suspeita com caso mínimo que a reproduz isolada.
- **Tratar warning como ruído.** O warning de deprecação de hoje é o erro de runtime de
  amanhã, e às vezes ele explica o comportamento estranho de agora. Prevenção: warnings da
  região tocada se leem junto com o erro.

## Exemplos práticos

**Exemplo 1: cascata.**
`cargo check` despeja 23 erros. O primeiro: um `enum` ganhou variante nova e um `match`
deixou de ser exaustivo. Os outros 22 são funções que consomem o resultado desse match.
Correção de 3 linhas no match, re-run: zero erros. Os 22 nunca foram lidos em detalhe, de
propósito.

**Exemplo 2: a camada errada.**
Correção aplicada no visitor, teste manual continua bloqueando errado. O grep da mensagem de
bloqueio no fonte mostra que ela vem de uma denylist embutida no binário via `include_str!`,
não do arquivo de config editado. O comportamento só muda com rebuild; editar o JSON no disco
era teatro. A pergunta "quem emite esta mensagem?" resolveu o que parecia um bug misterioso.

**Exemplo 3: invocação, não código.**
Script passa no terminal e falha no hook com "config not found". Diferença entre contextos: o
hook executa com CWD na raiz do repositório; o script resolvia o path relativo ao CWD. Nem o
código nem o ambiente estavam "errados": a invocação diferia. Correção: resolver o path a
partir de uma âncora estável (o diretório do próprio script ou um ancestral nomeado), não do
CWD.
