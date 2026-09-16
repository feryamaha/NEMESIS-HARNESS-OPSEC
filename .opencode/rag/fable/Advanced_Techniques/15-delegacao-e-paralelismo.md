---
name: delegacao-e-paralelismo
description: Como eu decido o que delegar a subagentes e o que fazer inline: contratos de handoff autossuficientes (o subagente nasce sem memória), verificação independente do trabalho delegado, paralelismo de chamadas independentes, e o que nunca se delega (julgamento).
---

# Delegação e paralelismo

Um subagente não é um estagiário que assistiu à reunião: ele nasce sem nenhuma memória desta
conversa. Delegar bem é escrever um contrato que sobrevive a essa amnésia; delegar mal é
pagar o custo de dois agentes para obter a confusão de ambos. E nem tudo que pode ser
paralelo deve ser delegado: a ferramenta certa para dois comandos independentes é executá-los
juntos, não contratar alguém.

## Quando usar esta skill

- Quando uma sub-tarefa consumiria muito do meu contexto e só me interessa a conclusão
  (varredura ampla, leitura exploratória de área grande).
- Quando existem sub-tarefas genuinamente independentes que podem correr em paralelo.
- Quando o processo pede revisão com olhos limpos (revisor não contaminado pelas minhas
  decisões).
- NÃO usar por reflexo em tarefa que eu resolvo inline com 3 tool calls: o overhead de
  contratar, contextualizar e verificar supera o ganho.

## Passo a passo

1. **Decida delegação pelo perfil da sub-tarefa, com três testes.**
   - *Teste do contexto*: a sub-tarefa vai gerar muito volume intermediário do qual eu só
     preciso da síntese? Delegue (o contexto queimado é o do subagente).
   - *Teste da independência*: ela depende de decisões que ainda vou tomar nesta conversa?
     Então não delegue ainda; o contrato mudaria no meio.
   - *Teste do julgamento*: ela é essencialmente uma decisão (arquitetura, trade-off, o que
     cortar)? Nunca se delega; julgamento com o contexto do dono da tarefa sou eu quem tem.
2. **Escreva o contrato de handoff completo.** O prompt do subagente contém TUDO: o objetivo
   em uma frase, os paths absolutos, o contexto que ele não tem como saber (convenções do
   projeto, invariantes, decisões já tomadas), o que NÃO fazer, e o formato exato do
   resultado esperado. Regra de ouro: se eu colasse este prompt para um colega novo sem
   nenhum acesso à conversa, ele conseguiria? Se não, o contrato está furado.
3. **Defina o formato da resposta no contrato.** "Investigue X" devolve um ensaio; "devolva a
   lista de arquivos que fazem X, um por linha, com o papel de cada um em até 10 palavras"
   devolve algo que eu integro sem retrabalho. O formato do output é parte do contrato, não
   cortesia.
4. **Dimensione a autonomia do subagente à verificabilidade.** Exploração read-only: rédea
   solta. Escrita de código: tarefa fechada com verificação executável definida por mim
   (teste que deve passar, comando cujo output esperado está no contrato). Subagente sem
   critério verificável de pronto devolve "concluí com sucesso" que não significa nada.
5. **Verifique o trabalho delegado de forma independente.** O relatório do subagente é
   alegação, não fato: para trabalho escrito, eu rodo a verificação eu mesmo (suite, build,
   leitura do diff); para exploração, faço spot-check de 2 ou 3 afirmações contra o disco. O
   resultado do subagente entra no meu reporte com a mesma disciplina de
   `verificacao-antes-de-concluir`.
6. **Paralelismo sem agentes para o caso simples.** Dois comandos independentes, duas
   leituras independentes: dispare juntos na mesma rodada de tool calls. Paralelismo de
   chamadas é grátis; paralelismo de agentes custa contrato + verificação. O barato primeiro.
7. **Ao paralelizar agentes, particione o território sem sobreposição.** Dois agentes
   editando a mesma área produzem conflito ou trabalho duplicado. A partição vai no contrato
   de cada um ("só toque em src/parser/"; "não modifique nada, apenas relate"). Trabalho
   sobreposto de escrita pede isolamento real (worktrees) ou serialização.

## Melhores práticas

- Relate ao usuário o que o subagente concluiu: o resultado dele volta para MIM, não para a
  tela do humano. Repassar a síntese relevante no meu texto final é parte da delegação.
- Delegação em cadeia (subagente contratando subagente) multiplica a perda de contexto como
  telefone sem fio; uma camada de delegação resolve quase tudo que vale resolver.
- O two-stage review é um uso legítimo e barato de subagente: um executa a tarefa, outro (ou
  eu, com o contrato de revisor) confere contra a spec com olhos não contaminados pela
  execução. Executor e revisor no mesmo contexto tendem a aprovar a si mesmos.
- Tarefas com estado compartilhado mutável (o mesmo arquivo de config, o mesmo lockfile) não
  se paralelizam de verdade, por mais independentes que pareçam no enunciado.
- Se estou repetindo o mesmo contrato para o terceiro subagente, o contrato merece virar
  template/nota (ver `economia-de-contexto`, passo 3).

## Padrões de falha comuns

- **Handoff telepático.** Prompt de delegação que referencia "o bug que discutimos" e "a
  abordagem combinada". O subagente não discutiu nem combinou nada; ele inventa o que isso
  significa e executa a invenção. Prevenção: passo 2; o teste do colega novo.
- **Confiar no "missão cumprida".** Integrar o trabalho do subagente sem verificação porque o
  relatório dele soa confiante. Subagentes herdam meus modos de falha, incluindo a conclusão
  performática. Prevenção: passo 5, sempre.
- **Delegar a decisão.** Mandar um subagente "escolher a melhor arquitetura" e acatar. Ele
  tem menos contexto que eu sobre o projeto e o dono; a escolha volta pior e ainda parece
  terceirizada. Prevenção: teste do julgamento; decisões se preparam com exploração delegada,
  mas se tomam aqui.
- **Overhead invertido.** Contratar um agente para achar um símbolo que um grep acha em 2
  segundos. Prevenção: passo 6; a escada é grep → tool calls paralelos → subagente, nessa
  ordem.
- **Dois cozinheiros no mesmo arquivo.** Paralelizar dois agentes de escrita com territórios
  vagos; o merge dos resultados custa mais que a execução serial teria custado. Prevenção:
  passo 7; partição explícita ou serialização.

## Exemplos práticos

**Exemplo 1: exploração delegada, decisão local.**
Preciso decidir onde enganchar validação num monorepo desconhecido. Delego a exploração:
"liste os middlewares de request em [path], com arquivo e ordem de execução; não modifique
nada; formato: tabela path | ordem | papel". Recebo 8 linhas verificáveis, faço spot-check de
duas, e a decisão de onde enganchar (o julgamento) acontece aqui, com o resultado na mesa.

**Exemplo 2: contrato de escrita com verificação embutida.**
Delegação de uma conversão mecânica: "converta os 12 arquivos listados do padrão A para o B;
exemplo real de antes/depois abaixo; não toque em nada fora da lista; ao final rode
`cargo test -p core` e cole a saída". Na volta: leio o diff completo e rodo a suite EU MESMO.
A saída colada pelo subagente é indício; a minha execução é o fato.

**Exemplo 3: paralelismo barato, sem agentes.**
Para um diagnóstico preciso de três fatos independentes (status do git, versão do binário
instalado, se o daemon roda), a resposta não é um subagente: é uma única rodada com três
comandos disparados juntos. Três respostas em um round-trip, contexto mínimo, zero contrato.
