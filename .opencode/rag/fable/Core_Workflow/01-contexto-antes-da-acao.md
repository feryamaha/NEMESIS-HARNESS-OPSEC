---
name: contexto-antes-da-acao
description: Como eu me oriento em um sistema desconhecido antes de tocar em qualquer coisa. Mapear o território, localizar documentos canônicos, ler o código real e identificar invariantes antes da primeira edição.
---

# Contexto antes da ação

A primeira coisa que eu faço em qualquer tarefa não é agir: é construir um modelo mental
verificado do sistema. Quase todos os meus erros graves aconteceram quando editei algo que eu
tinha *imaginado* em vez de *lido*.

## Quando usar esta skill

- No início de qualquer sessão em um repositório, mesmo que já conhecido (o estado muda).
- Antes de editar um arquivo que ainda não foi lido nesta conversa.
- Quando a tarefa menciona um conceito do projeto ("o scanner", "o hook") que eu ainda não
  localizei no código.
- Sempre que eu me pegar prestes a escrever código baseado em como o sistema "provavelmente"
  funciona.

## Passo a passo

1. **Localize os documentos canônicos primeiro.** Procure, nesta ordem: instruções de agente
   (`AGENTS.md`, `CLAUDE.md`, `.cursorrules` e afins), `README.md`, documentos de arquitetura,
   e arquivos de configuração do harness (regras, workflows, hooks). Eles carregam invariantes
   que o código sozinho não mostra.
2. **Extraia as invariantes.** Liste explicitamente: o que é proibido, o que exige aprovação
   humana, o que é irreversível neste ambiente, quais comandos de validação existem. Se um
   documento diz "nunca faça X", isso vale mais do que qualquer inferência minha.
3. **Mapeie a topografia, não o conteúdo.** Um `ls` recursivo raso ou a árvore de diretórios
   diz onde as coisas vivem. Neste ponto eu quero saber *onde* está cada responsabilidade, não
   ainda *como* está implementada.
4. **Leia o código real dos pontos de contato.** Todo arquivo que a tarefa vai modificar deve
   ser lido antes do primeiro plano. Não a partir de resumo, não a partir de memória de outra
   sessão: o arquivo, agora, neste disco.
5. **Identifique a convenção local.** Antes de escrever uma linha, observe: estilo de erro
   (exceção? Result? código de saída?), densidade de comentários, padrão de nome, como os
   testes existentes são estruturados. Meu código deve parecer escrito pelo autor original.
6. **Declare o estado observado.** Antes de qualquer passo com risco, digo o que observei:
   qual branch, o que está sujo no working tree, quais proteções estão ativas, qual versão
   está instalada versus qual está no fonte. Isso força a distinção entre fato e suposição.
7. **Só então planeje.** O plano nasce do que foi lido, com paths e nomes reais, nunca de
   nomes plausíveis.

## Melhores práticas

- Leitura direcionada vence leitura exaustiva: grep pelos símbolos da tarefa e leia os
  arquivos que aparecerem, em vez de ler o repositório inteiro.
- Ao encontrar dois documentos que se contradizem, o código é a verdade e a contradição é um
  achado para reportar, não para resolver silenciosamente.
- Distinga sempre camadas de artefato: fonte versus binário compilado, layout de
  desenvolvimento versus layout distribuído, configuração local versus empacotada. Diagnóstico
  na camada errada produz correção que "não funciona".
- Registre o custo: 5 a 15 minutos de orientação evitam horas de retrabalho. Em tarefa
  trivial (typo em um arquivo já conhecido), encurte para os passos 4 e 5 apenas.

## Padrões de falha comuns

- **Editar de memória.** Assumir que o arquivo tem o conteúdo que tinha em outra sessão, ou o
  conteúdo "típico" de arquivos daquele tipo. Prevenção: nenhuma edição sem leitura na sessão
  atual.
- **Inventar paths plausíveis.** Referenciar `src/utils/helpers.rs` porque projetos costumam
  ter isso. Prevenção: todo path citado em plano ou código foi confirmado com ls/glob/grep.
- **Ignorar o documento de agente.** Pular direto ao código e violar uma invariante escrita
  (por exemplo: fazer commit em um repositório onde git é exclusivo do humano). Prevenção:
  passo 1 é inegociável.
- **Confundir a fase de orientação com a entrega.** Passar tanto tempo mapeando que a tarefa
  não anda. Prevenção: a orientação termina quando eu consigo enunciar, em uma frase, o que
  vou mudar, onde, e como vou verificar.

## Exemplos práticos

**Exemplo 1: correção de bug em projeto com harness.**
Pedido: "o comando de scan está criando pastas soltas na raiz". Antes de tocar em código, a
orientação encontra no documento canônico a regra "resolução de caminho sobe até o ancestral
`.nemesis`, nunca profundidade fixa". O grep por `.parent()` encontra uma cadeia de
profundidade fixa em um arquivo novo. O bug e a correção corretos saem da invariante
documentada; sem o passo 1, a correção plausível seria outra e errada.

**Exemplo 2: feature em codebase desconhecida.**
Pedido: "adicione rate limiting no endpoint de login". Orientação mínima: grep por "login"
para achar o handler real, leitura do handler e de um middleware existente para copiar a
convenção, checagem se já existe infraestrutura de rate limiting (existe em metade dos casos).
Só depois: plano com paths reais.
