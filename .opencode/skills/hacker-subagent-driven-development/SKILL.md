---
name: hacker-subagent-driven-development
description: >
  Executa plano de implementacao tarefa por tarefa usando subagentes com contexto isolado.
  Pre-flight de postura na entrada (verificar-vazamento.sh GOOD + branch + working tree).
  Two-stage review apos cada tarefa com revisor INDEPENDENTE (spec compliance depois code
  quality, verificacao rodada pelo revisor). Execucao continua sem pausas entre tarefas.
---

# Hacker Subagent-Driven Development

Executar plano de implementacao enviando um agente fresco por tarefa, com two-stage review
independente apos cada um: validacao de spec compliance primeiro, depois validacao de
qualidade de codigo.

> **Texto unico.** Comandos de verificacao e regras de stack vem do perfil do repo
> (`.opencode/rules/hacker-repo-profile.md`).

**Principio core**: Agente fresco por tarefa + two-stage review INDEPENDENTE (spec depois
quality) = qualidade alta, iteracao rapida. Trabalho delegado se verifica de forma
independente antes de integrar (lei F9); julgamento nao se delega.

**Camadas de raciocinio (secao "Distribuicao de modelos" do workflow auto):** o orquestrador
(modelo principal, camada MAIOR) nao implementa nem revisa - dispara implementadores na
camada MEDIA e revisores na camada REVISOR, com o revisor em modelo DISTINTO do implementador
da mesma tarefa. O mapeamento camada->modelo e declarado no pre-flight (Step 0) conforme os
modelos disponiveis no harness; sem selecao de modelo disponivel, todos os subagentes rodam
no modelo da sessao (fallback).

**Execucao continua**: NAO pause para check-in entre tarefas. Execute TODAS as tarefas do
plano sem parar. As unicas razoes para parar sao: BLOQUEADO que voce nao consegue resolver,
ambiguidade que genuinamente impede progresso, ou todas as tarefas completadas.

**Anuncio de inicio**: "Estou usando a skill hacker-subagent-driven-development para executar o plano."

**Pre-requisito**: Um plano aprovado existe em `.opencode/plans/`.

## Processo

### Step 0: Pre-flight de postura (lei F1, obrigatorio)

Antes da primeira tarefa, declarar a postura observada por comando (nao por suposicao),
conforme o perfil:

```bash
# Pre-flight de postura (obrigatorio):
bash ~/opsec/scripts/verificar-vazamento.sh
# GOOD = pode prosseguir; qualquer outro resultado = PARE, nao toque rede

git branch --show-current
git status --short
```

- **Pre-flight de rede**: `bash ~/opsec/scripts/verificar-vazamento.sh` GOOD e obrigatorio
  antes de qualquer acao que toque rede. Qualquer resultado diferente de GOOD = PARE.
- **Branch e working tree**: branch correta, working tree limpa ou com mudancas conhecidas.
  Working tree sujo com mudancas que nao sao suas = parar e reportar antes de tocar em
  qualquer arquivo.

Registrar a postura no rastreamento.

Declarar tambem o **mapeamento camada->modelo** do ciclo (ex.: "implementador=Opus,
revisor=Sonnet" ou "fallback: modelo unico da sessao").

### Step 1: Carregar e Revisar Plano (inclui pre-flight de coerencia)

Ler o arquivo do plano e escanear UMA vez por conflitos internos ANTES da primeira tarefa:
- tarefas que se contradizem entre si, ou que contradizem invariantes/Global Constraints;
- algo que o plano manda fazer e que a rubrica do two-stage review trataria como defeito.

Conflito imaterial: resolver pelo criterio da analise critica (hacker-critical-analysis),
registrar a decisao em 1 linha para o relatorio. Conflito material (muda escopo ou resultado):
PARADA DE EMERGENCIA com TODOS os conflitos num unico reporte em lote - nunca um interrupt por
descoberta no meio da execucao. Scan limpo: prosseguir sem comentario e criar o
rastreamento de tarefas.

### Step 2: Registrar Tarefas e Derivar Waves

Criar lista de rastreamento e derivar as waves de execucao a partir do plano:

- Uma tarefa entra na wave W somente quando TODAS as tarefas do seu DEPENDE_DE estao em
  waves anteriores.
- Tarefas na mesma wave devem ter conjuntos de arquivos DISJUNTOS (CREATE/MODIFY/TEST).
  Intersecao de arquivos = waves sequenciais, mesmo sem DEPENDE_DE declarado (dois
  implementadores no mesmo arquivo corrompem o trabalho um do outro).
- Plano sem DEPENDE_DE (formato antigo) = uma tarefa por wave, execucao sequencial.

```
[ ] WAVE 1: TASK 1, TASK 3   (sem dependencias, arquivos disjuntos)
[ ] WAVE 2: TASK 2 (DEPENDE_DE: 1), TASK 4 (DEPENDE_DE: 3)
...
```

### Step 3: Executar Waves (Continuo, sem Pausas)

Para CADA wave, em ordem: disparar os implementadores de TODAS as tarefas da wave EM
PARALELO (um subagente fresco por tarefa, camada MEDIA); coletar todos os resultados;
disparar os revisores EM PARALELO (camada REVISOR, modelo distinto); a wave so fecha - e a
proxima so abre - quando TODAS as tarefas dela estao PASS no two-stage review. FAIL em uma
tarefa nao cancela as demais da wave: o follow-up dela roda enquanto as outras seguem o
review, mas a proxima wave aguarda.

Para CADA tarefa da wave:

#### Phase 3a: Marcar como in_progress
```
[IN] TASK N: [descricao]
```

#### Phase 3b: Disparar subagente implementador (contrato de handoff COMPLETO, lei F9)

O subagente nasce sem memoria da conversa: o contrato contem tudo.

```
OBJETIVO: [descricao completa da tarefa atomica]
ARQUIVOS (paths exatos): [lista exata de FILES INVOLVED desta tarefa]
CODIGO ESPERADO: [snippet/pseudocodigo do plano, se aplicavel]
INVARIANTES: [regras do perfil que se aplicam: linguagem, areas sensiveis, escopo]
PRE-FLIGHT REDE: bash ~/opsec/scripts/verificar-vazamento.sh GOOD obrigatorio antes de acoes de rede
O QUE NAO FAZER: [nao tocar arquivos fora da lista; nao introduzir dependencia nova;
  nao executar git de escrita; nao "aproveitar e melhorar" nada adjacente]
COMANDO DE VERIFICACAO: [comando por tarefa do perfil]
ECONOMIA (F9): [leitura direcionada primeiro - grep/outline antes de arquivo inteiro;
  ler apenas o trecho necessario dos arquivos grandes]
FORMATO DO RESULTADO: [diff dos arquivos tocados + saida literal da verificacao
  + CONFIANCA/LACUNAS: o que NAO foi verificado e por que]
PLANO ORIGINAL: .opencode/plans/PLAN_NNN_nome-descritivo.md
```

Reporte de subagente (implementador ou revisor) sem evidencia citavel - diff real, saida
literal, achado com arquivo:linha - e REJEITADO e re-disparado UMA vez com a lacuna
apontada; na reincidencia, a tarefa vira FAIL.

#### Phase 3c: Two-Stage Review INDEPENDENTE

O review e feito por um **subagente revisor distinto do implementador**, com contexto
isolado, recebendo: a tarefa do plano, o diff produzido e o contrato acima. O revisor
**RODA ele proprio o comando de verificacao do perfil** (nao confia no relato do
implementador) antes de emitir o parecer.

**Stage 1 - Spec Compliance**:
- A implementacao de fato faz o que a spec/tarefa requer?
- Todos os arquivos afetados?
- Nenhum arquivo fora do scope?

**Stage 2 - Code Quality**:
- Codigo seguro e idiomatico na stack do perfil? (bash: sem erros de sintaxe, posix
  compliance; python3: py_compile OK; docker: compose config valida)
- Segue convencoes do codigo ao redor?
- Comando de verificacao do perfil PASS (rodado pelo revisor)?
- Nenhuma violacao das regras do perfil?
- Areas sensiveis (scripts de protecao, docker-compose.yml com flag opsec_sensitive):
  confirmado que a flag de classe C esta presente e que o Fernando foi consultado?

Todo achado do revisor cita a evidencia por arquivo:linha.

#### Phase 3d: Resultado

- **Se PASS**: Marcar [✅], prosseguir proxima tarefa (sem pause)
- **Se FAIL**: [❌] Disparar follow-up subagent com o contexto de erro E os achados do
  revisor, ate 2 tentativas. Contrato do follow-up (recepcao de review): VERIFICAR cada
  achado contra o codigo antes de aplicar; achado improcedente NAO se aplica - reporta-se
  de volta com a evidencia; proibido acatar por deferencia ("o revisor tem razao") sem
  verificacao; achados ambiguos se esclarecem ANTES de aplicar qualquer um (achados podem
  ser relacionados; entendimento parcial = correcao errada).
- **Se BLOCKED**: [🚫] STOP, reportar a Fernando exatamente o que bloqueou

### Step 4: Verificacao por Mudanca (conforme perfil)

Apos CADA tarefa concluida com PASS, executar a verificacao por mudanca do perfil:
`bash -n` + `shellcheck` para scripts, `python3 -m py_compile` para python, `docker compose -f ~/opsec/docker-compose.yml config` para compose, `git diff --check` para git.

### Step 5: Verificacao Final (Apos TODAS as Tarefas)

Rodar a suite completa do perfil para todos os arquivos tocados:

```bash
bash -n ~/opsec/scripts/*.sh
shellcheck ~/opsec/scripts/*.sh 2>/dev/null
python3 -m py_compile <arquivo.py>
docker compose -f ~/opsec/docker-compose.yml config
git diff --check
```

Todos devem PASS.

### Step 6: Report de Execucao

Apos completar TODAS as tarefas:

```
EXECUCAO CONCLUIDA

Postura (pre-flight): [declarada no Step 0]
Pre-flight rede (verificar-vazamento.sh): GOOD
Tarefas: N/N COMPLETAS
Erros: 0
Bloqueios: 0

Verificacao Final (suite do perfil):
  bash -n: PASS
  shellcheck: PASS
  py_compile: PASS
  docker compose config: PASS
  git diff --check: PASS

Resultado: PRONTO PARA hacker-tests (Skill 4) - invocar sem pausa
```

## Red Flags (Parar Imediatamente)

- Subagent produz codigo violando regras do perfil
- Mesma tarefa falha 2+ vezes
- Subagent nao consegue encontrar arquivos do plano
- Implementacao diverge significativamente do plano
- Subagent modifica arquivos fora do scope da tarefa
- Revisor nao consegue reproduzir o PASS relatado pelo implementador
- verificar-vazamento.sh nao retorna GOOD e acao de rede e inevitavel

## Lembrar

- Pre-flight de postura ANTES da primeira tarefa (F1): verificar-vazamento.sh GOOD + branch + working tree
- Agente fresco por tarefa - contexto isolado, contrato de handoff completo (F9)
- Waves: paralelismo somente entre tarefas com arquivos disjuntos e sem dependencia; a
  proxima wave so abre com TODAS as tarefas da atual em PASS
- Revisor INDEPENDENTE (camada REVISOR, modelo distinto do implementador) roda a
  verificacao ele proprio - nao aceitar relato sem prova
- Execucao continua - NAO pause entre tarefas
- Regra canonica anti-invencao: `.opencode/rules/hacker-epistemic-safety.md`. Cada subagente
  entrega so evidencia observada (saida literal, arquivo lido); nunca inventa resultado.
- Narracao entre tool calls: no maximo 1 linha curta de status - o registro vivo esta no
  rastreamento e nas saidas literais (economia de tokens, F9); nada de resumo intermediario
- PARE somente para blocadores irresoluveis
- Responder SEMPRE em PT-BR

## Integracao

**Skill anterior**: `hacker-writing-plans` (validado pela `hacker-critical-analysis` Ponto 2)
**Proxima skill apos conclusao**: `hacker-tests` (Skill 4), invocada sem pausa
