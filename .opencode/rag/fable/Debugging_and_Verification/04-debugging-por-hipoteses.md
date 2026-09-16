---
name: debugging-por-hipoteses
description: Como eu debugo: reproduzir primeiro, formular hipóteses rivais, escolher a observação mais barata que as discrimina, confirmar a causa-raiz por predição antes de corrigir, e mudar uma variável por vez.
---

# Debugging por hipóteses

Debugging não é procurar o erro; é reduzir o espaço de possibilidades com a observação mais
barata disponível, até que reste uma causa que eu consiga **prever** antes de corrigir. A
correção é a última etapa, e a mais fácil, quando as anteriores foram feitas.

## Quando usar esta skill

- Qualquer comportamento inesperado: teste falhando, crash, output errado, lentidão.
- Especialmente quando existe um diagnóstico pronto e tentador (do usuário, de um log
  ambíguo, do meu próprio palpite) pedindo só confirmação.
- Não usar quando o erro é autoexplicativo (mensagem aponta linha e causa exatas): aí a
  skill é `arqueologia-de-erros`, e a correção pode ser direta.

## Passo a passo

1. **Reproduza antes de teorizar.** Um bug que eu não reproduzo é um bug que eu não corrijo:
   qualquer "correção" seria fé. Capture o comando exato, o input exato, a saída exata. Se a
   reprodução é intermitente, a primeira sub-tarefa é torná-la determinística (fixar seed,
   isolar concorrência, reduzir o input).
2. **Reduza o caso ao mínimo.** Corte metades: metade do input, metade das flags, metade do
   pipeline. Cada corte que mantém o sintoma elimina um mundo de causas. Minimizar custa
   minutos e economiza horas.
3. **Enumere hipóteses rivais, no plural.** Antes de investigar a favorita, escreva 2 a 4
   causas plausíveis. Uma hipótese sozinha vira túnel: eu passo a coletar evidência que a
   confirma. Inclua sempre a hipótese chata: ambiente errado, artefato velho, versão
   diferente, eu olhando o arquivo errado.
4. **Escolha a observação mais barata que discrimina.** Para cada par de hipóteses, qual
   observação de 30 segundos dá resultado diferente sob cada uma? Um print, um `git log` do
   arquivo, um teste com input alterado, uma checagem de timestamp de binário. Rode essa
   observação antes de qualquer investigação cara.
5. **Bisseção quando o espaço é linear.** Sintoma novo em código velho: `git bisect` (ou
   bisseção manual de commits). Pipeline longo: corte no meio e olhe o estado intermediário.
   Input grande: metades. A bisseção é o algoritmo, não a intuição.
6. **Confirme a causa por predição.** Antes de corrigir, formule: "se a causa é X, então ao
   fazer Y devo observar Z". Rode Y. Se Z não aparece, a causa não era X, e a correção teria
   sido teatro. Só uma causa que prevê corretamente merece patch.
7. **Corrija uma variável por vez.** Uma mudança, uma re-execução da reprodução. Duas
   mudanças simultâneas que "resolvem" deixam para trás uma mudança supersticiosa que
   ninguém sabe se era necessária.
8. **Feche o ciclo.** A reprodução original passa; a suite completa passa; a reprodução vira
   teste de regressão quando o custo permitir. Registre em uma linha a causa real: o próximo
   leitor (ou eu, com contexto resumido) não deve rederivar isso.

## Melhores práticas

- Mantenha um log curto do que já foi **descartado** e por qual evidência. Em sessões longas
  isso evita revisitar hipótese morta, e é ouro para quem retomar o debug.
- Leia o código da região suspeita de verdade, linha a linha, com a pergunta "o que este
  código *faz*", não "o que ele *deveria* fazer". A maioria dos bugs mora nessa diferença.
- Desconfie de coincidências temporais: "quebrou depois do deploy X" é correlação, vira causa
  só com bisseção ou mecanismo demonstrado.
- Quando duas camadas podem conter o bug (fonte vs binário publicado, dev vs distro, cache vs
  origem), determine **em qual camada o sintoma vive** antes de debugar o conteúdo. Metade
  dos "bugs impossíveis" são a camada errada.
- Se após 2 ou 3 ciclos de hipótese nada discrimina, o meu modelo do sistema está errado em
  algo mais fundo: volte à skill `contexto-antes-da-acao` e releia o caminho do dado inteiro.

## Padrões de falha comuns

- **Corrigir o sintoma no lugar da causa.** O teste espera 5 e vem 4, então mudo o teste para
  4. Prevenção: a pergunta "por que 4?" tem que ter resposta mecânica antes de qualquer edição.
- **Túnel na primeira hipótese.** Três horas instrumentando o parser quando um `ls -la` do
  binário mostraria que o build era de ontem. Prevenção: passo 3 obriga rivais; passo 4
  obriga a observação barata primeiro.
- **Debug por tentativa.** Mudar coisas "para ver se resolve", sem predição. Quando resolve,
  ninguém sabe por quê; quando não resolve, o estado acumulou mudanças não relacionadas.
  Prevenção: passos 6 e 7; e working tree limpo entre tentativas.
- **Confirmar o enquadramento recebido.** O usuário diz "deve ser o cache" e toda a
  investigação orbita o cache. O relato do usuário é sintoma observado (valioso) mais
  diagnóstico inferido (hipótese entre outras). Prevenção: reclassificar o diagnóstico
  recebido como hipótese número N, não como fato.
- **Declarar vitória sem re-executar a reprodução original.** A correção passa no caso
  mínimo, mas o caso original tinha uma segunda causa sobreposta. Prevenção: passo 8.

## Exemplos práticos

**Exemplo 1: a hipótese chata vence.**
Sintoma: correção já mergeada "não funciona" na máquina de um usuário. Hipóteses: (a) fix
incompleto, (b) condição não coberta, (c) o usuário roda binário antigo. Observação mais
barata: comparar versão/hash do binário instalado com o release. Resultado: instalação
defasada; nenhuma linha de código precisava mudar. Sem o passo 3, horas seriam gastas em (a).

**Exemplo 2: predição antes do patch.**
Sintoma: arquivo de log criado na raiz do projeto em instalações distribuídas, mas não em dev.
Hipótese: resolução de path por profundidade fixa de `.parent()`, que ultrapassa a âncora no
layout distribuído (mais raso). Predição: "se é isso, rodar o binário a partir do layout
distribuído com path de âncora logado deve mostrar o path acima da raiz". Confirma. A correção
(subir até o ancestral pelo nome, não por profundidade) vem depois da predição, não antes.

**Exemplo 3: bisseção mecânica.**
Suite passa no commit de sexta, falha hoje, 40 commits no meio. Nada de ler os 40 diffs:
`git bisect run <comando-do-teste>` encontra o commit culpado em ~6 execuções. A leitura fina
começa só no diff culpado.
