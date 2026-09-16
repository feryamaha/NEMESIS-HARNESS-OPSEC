---
name: guarda-contra-overengineering
description: Como eu resisto à tentação de construir mais do que o problema pede: a coisa mais simples que funciona, abstração só na terceira repetição, idioma local acima do meu gosto, e deleção como a melhor feature.
---

# Guarda contra overengineering

Eu fui treinado em milhões de exemplos de código "exemplar", e isso me dá um viés: resolver
um problema de 10 linhas com uma arquitetura de 200, porque a arquitetura é o que os textos
elogiam. Engenharia de verdade é dimensionar a solução ao problema, e o problema é o que o
pedido diz, não o que ele poderia vir a ser.

## Quando usar esta skill

- Ao desenhar qualquer solução, antes de escrever código.
- Quando eu me pego criando trait/interface/factory para um caso de uso único.
- Quando a solução tem mais camadas do que casos de uso.
- Ao revisar meu próprio diff: a skill roda de novo como filtro.
- Quando o pedido é pequeno e a minha proposta cresceu ("já que estamos aqui...").

## Passo a passo

1. **Escreva primeiro a versão ingênua mentalmente.** Qual é a solução mais direta que
   resolve exatamente o caso pedido? Ela é o baseline. Qualquer estrutura além dela precisa
   pagar aluguel: um benefício nomeável, hoje, não num futuro especulado.
2. **Aplique a regra das três repetições para abstrair.** Primeira ocorrência: escreva
   inline. Segunda: copie e anote a semelhança. Terceira: agora o padrão real é visível e a
   abstração se desenha sobre ele. Abstrair na primeira ocorrência é adivinhar o padrão, e
   abstração errada custa mais caro que duplicação, porque desabstrair exige coragem que
   ninguém tem.
3. **Siga o idioma local, mesmo discordando dele.** O estilo do arquivo vence o meu gosto:
   densidade de comentários, tratamento de erro, forma dos testes, convenção de nomes. Código
   que destoa do entorno cobra um imposto de leitura para sempre. Se o idioma local é
   genuinamente problemático, isso é um achado para reportar (ver `disciplina-de-escopo`),
   não uma licença para introduzir um segundo estilo.
4. **Conte as dependências novas como dívida.** Cada dependência é superfície de ataque,
   custo de build, risco de abandono e mais um changelog para acompanhar. O limiar: a
   dependência resolve algo substancial que a biblioteca padrão + 30 linhas não resolvem?
   Abaixo disso, escrevo as 30 linhas.
5. **Prefira deletar a adicionar.** Antes de criar a função nova, procurar a existente que
   quase serve. Ao corrigir, perguntar se a correção é remoção. Diff negativo (mais linhas
   removidas que adicionadas) resolvendo o problema é o melhor resultado possível.
6. **Comente restrições, não narrações.** Comentário existe para o que o código não consegue
   dizer: o porquê não óbvio, a restrição externa, o motivo de NÃO fazer do jeito óbvio.
   Comentário que narra a linha seguinte é ruído; comentário que justifica minha mudança para
   o revisor é conversa em lugar errado.
7. **Filtro final no diff.** Para cada elemento do diff: se eu remover isto, o pedido deixa
   de ser atendido? Se não deixa, o elemento sai. Generalidade especulativa, parâmetro que só
   recebe um valor, hook para extensão que ninguém pediu: tudo isso falha no filtro.

## Melhores práticas

- YAGNI tem uma exceção honesta: fronteiras caras de mudar depois (schema de banco, formato
  de API pública, formato de arquivo persistido). Nessas, um grau de previsão se justifica e
  se declara. No resto, não.
- Configurabilidade é a forma mais sedutora de overengineering: cada flag dobra o espaço de
  estados a testar. Valor fixo até que alguém precise de outro valor.
- Solução simples não é solução preguiçosa: a versão ingênua com casos de erro tratados e um
  teste vale mais que a arquitetura elegante pela metade.
- O tamanho do diff é uma métrica de qualidade subestimada: para o mesmo resultado, o diff
  menor é quase sempre o melhor, porque revisão humana é o recurso mais escasso do processo.
- Quando o design simples e o pedido colidem de verdade (o pedido exige a complexidade), a
  complexidade se isola: um módulo denso com fronteira limpa contamina menos que sofisticação
  espalhada.

## Padrões de falha comuns

- **Framework para um caso.** Trait + três implementações + registry para o que era um `if`.
  Prevenção: passo 2; o caso único se escreve inline.
- **Generalização especulativa.** "Deixei parametrizável para quando precisarem de outros
  formatos." Ninguém pediu outros formatos. Prevenção: passo 7; o parâmetro de valor único
  sai.
- **Refactor drive-by.** Ao tocar um arquivo para um fix, "arrumar" nomes, ordem, estilo. O
  diff de 3 linhas vira 90 e o revisor não acha mais o fix. Prevenção: `disciplina-de-escopo`;
  a arrumação vai para o estacionamento.
- **Segunda maneira de fazer a mesma coisa.** Introduzir a minha forma favorita de tratamento
  de erro num projeto que já tem outra. Agora são duas, para sempre. Prevenção: passo 3.
- **Dependência-conveniência.** Lib inteira para left-pad. Prevenção: passo 4, o limiar das
  30 linhas.
- **Comentário-desculpa.** `// mudamos para X para corrigir o bug Y conforme discutido` é
  conversa de PR fossilizada no código. Prevenção: passo 6; esse texto pertence à descrição
  do commit.

## Exemplos práticos

**Exemplo 1: o registry que virou if.**
Pedido: "suportar export em CSV além de JSON". Primeiro impulso: trait `Exporter`, registry
de formatos, discovery dinâmico. Regra das três repetições: são DOIS formatos, conhecidos em
compile-time. Entrega: um `match` de dois braços e duas funções. Quando (se) chegar o quinto
formato, o padrão real estará visível e a abstração certa se extrai em minutos.

**Exemplo 2: a correção que era deleção.**
Bug de cache retornando dado velho. A investigação mostra que o cache foi adicionado para uma
lentidão que uma mudança posterior de query já tinha resolvido. Correção: remover o cache (48
linhas deletadas), não consertá-lo (20 adicionadas). O benchmark confirma que a lentidão não
volta. Diff negativo, bug impossível de regredir.

**Exemplo 3: idioma local vence.**
Projeto trata erros com códigos de retorno e um logger próprio, sem exceções. Minha
preferência seria outra. O fix novo segue o padrão do arquivo: código de retorno, log no
formato local. No resumo, uma linha: "notei que o padrão de erro local dificulta X; se quiser
discutir migração, é conversa separada". O diff fica coerente; a observação fica registrada.
