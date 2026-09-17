---
name: hacker-tests
description: >
  Valida a implementacao apos a Skill 4: verificacao por mudanca do perfil (bash -n,
  shellcheck, py_compile, docker compose config, git diff --check), teste SUNSET, reexecucao
  apos fix, verificacao de postura de rede (verificar-vazamento.sh GOOD), e validacao do
  mock/pentest conforme hacker-pentest-harness-execution.md. Fix autonomo com loop
  evaluator-optimizer (max 5 ciclos ate convergencia), com reconciliacao de vereditos no
  Trust Ledger. Cada ciclo gera entrada no Trust Ledger. Ao passar, invoca hacker-doc-sync
  (4.6) automaticamente, sem pausa.
---

# Hacker Tests (Validacao Pos-Execucao)

Executar bateria de testes apos implementacao (Skill 4). Ao passar, invoca a
`hacker-doc-sync` (4.6) automaticamente (sem pausa); a PARADA UNICA do pipeline acontece
no FIM da doc-sync, nao aqui.

> **Texto unico.** Os comandos por fase vem do perfil do repo
> (`.opencode/rules/hacker-repo-profile.md`).

**Anuncio de inicio**: "Estou usando a skill hacker-tests para validar a implementacao."

**Pre-requisito**: Todas as tarefas do PLAN foram completadas (Skill 4 concluida).

## Processo

## Loop Evaluator-Optimizer (Fable Pattern 5)

Para fluxos que exigem verificacao mecanica, usar
`python3 .hacker/scripts/graph-loop.py loop --evaluator <comando> --ledger <arquivo>`.
O comando emite `loop-ciclo=N`, aplica o limite informado e retorna exit code diferente de
zero quando o avaliador nao converge. O stdout, stderr, exit code e SCORE do evaluator sao
entregues ao generator via ambiente `EVALUATOR_*`; a skill define o criterio e o executor aplica o limite.

O fix-loop segue o padrao evaluator-optimizer da Anthropic:
- **Generator**: subagent implementador gera o fix
- **Evaluator**: esta skill executa a bateria completa (bash -n, shellcheck, py_compile, docker compose config, git diff --check, verificar-vazamento.sh)
- **Loop**: se FAIL → re-torna ao generator com o output do evaluator → generator ajusta → evaluator re-testa
- **Critério de parada**: GOOD do `verificar-vazamento.sh` E todos os testes PASS, OU 5 ciclos sem melhoria mensuravel (convergência)
- **Cada iteração gera entrada no Trust Ledger** (evento `loop-ciclo=N | resultado=...`)
- **Ações de classe C (F4)**: independentemente do loop, sempre param e pedem Fernando

### Limites do Loop

- Loop itera maximo 5 ciclos (nao por limite arbitrario, mas por convergência)
- Loop para na PARADA UNICA — o modelo PARA e apresenta o relatorio
- Ações de classe C sempre param para confirmação do Fernando, independentemente do loop
- Se a cadeia muda de GOOD para LEAK durante o Loop → HARNESS GUARDIAN pausa tudo
- Loop nao faz commit de git, nao abre PR, nao decide escopo
- O Loop é ferramenta de execução dentro do escopo autorizado, não operação independente

**Regra geral da skill**: cada comando e executado individualmente. O proximo comando so e
executado se o anterior passou. Se um comando falhar, NAO executar os subsequentes - ir para
Fase 4 (investigacao).

### Fase 1: Verificacao por mudanca (pos-tarefa)

Executar os comandos de verificacao do perfil para todos os arquivos tocados pela mudanca:

```bash
# Scripts:
bash -n ~/opsec/scripts/<script-modificado>.sh
shellcheck ~/opsec/scripts/<script-modificado>.sh 2>/dev/null

# Python3:
python3 -m py_compile <arquivo.py-modificado>

# Docker:
docker compose -f ~/opsec/docker-compose.yml config

# Git:
git diff --check
```

- **PASS**: prosseguir para a Fase 2
- **FAIL**: ir para Fase 4 (investigacao)

### Fase 2: Teste SUNSET

Verificar que nenhum artefato temporario ou intermediario foi deixado para tras:

```bash
# Nao deve haver arquivos .tmp, .bak, ou backups no repo:
git status --short | grep -E '\.(tmp|bak|swp)$' || echo "SUNSET: limpo"
```

- **PASS**: prosseguir para a Fase 3
- **FAIL**: ir para Fase 4 (investigacao)

### Fase 3: Reexecucao apos fix (se houve fix na Fase 4)

Se a Fase 1 falhou e um fix foi aplicado, re-executar desde a Fase 1 completa:

```bash
bash -n ~/opsec/scripts/<script>.sh
shellcheck ~/opsec/scripts/<script>.sh 2>/dev/null
python3 -m py_compile <arquivo.py>
docker compose -f ~/opsec/docker-compose.yml config
git diff --check
```

- **PASS**: prosseguir para a Fase 5
- **FAIL**: Fase 4 com 2a tentativa (se esgotada, parada de emergencia)

### Fase 4: Investigacao de causa raiz + fix autonomo (se qualquer Step falhou)

Se qualquer comando falhou, aplicar o metodo Fable (F2, debugging por hipoteses):

1. **Investigar a causa raiz** - nao tratar sintoma
   - Ler a saida de erro COMPLETA; corrigir o PRIMEIRO erro (os demais costumam ser eco)
   - Identificar o arquivo e linha exata do problema
   - Determinar se e regressao do codigo alterado ou problema pre-existente (baseline:
     a falha existe sem a mudanca? se pre-existente, NAO consertar em silencio: registrar
     no estacionamento e reportar na PARADA UNICA)
   - Confirmar a causa por predicao antes de editar
2. **Fix autonomo** (modo autonomo, default): implementar o fix cirurgico, escopo minimo,
   dentro dos arquivos da spec. **Maximo 2 tentativas por falha.**
3. **Retestar**: apos o fix, re-executar desde a Fase 1
   - Se passar: prosseguir para a proxima Fase (o fix e as tentativas ficam registrados
     para o relatorio da PARADA UNICA)
   - Se falhar apos 2 tentativas: **PARADA DE EMERGENCIA** - reportar ao Fernando com
     comando que falhou, saida completa, causa raiz com evidencia, fixes tentados e
     hipoteses descartadas. Aguardar orientacao.
4. Fix que exigiria sair do escopo da spec = parada de emergencia imediata (sem tentar).
5. **Reconciliacao de vereditos (lei F11)**: se a investigacao concluir que a falha era
   detectavel na spec ou no plano (ou seja, um gate anterior aprovou o que aqui reprovou),
   anotar a reconciliacao para o Trust Ledger: `reconciliacao: gate=[hacker-critical-analysis
   P1|P2|hacker-rule-control] deixou passar [descricao em 1 linha]`. Isso e sinal de
   calibracao do gate, nao culpa; entra no ledger na PARADA UNICA.

### Fase 5: Verificar postura de rede (se houve acao de rede)

Se a mudanca tocou rede (scripts de rede, docker-compose.yml com servicos de rede, etc.):

```bash
bash ~/opsec/scripts/verificar-vazamento.sh
```

- **GOOD**: rede segura, prosseguir para Fase 6
- **Qualquer outro resultado**: PARE. Reportar a Fernando, aguardar orientacao.

### Fase 6: Validar harness (se mudou .opencode/)

Se a mudanca tocou arquivos dentro de `.opencode/`, rodar o procedimento F10
(hacker-harness-integrity.md):

```bash
# Procedimento deterministico de verificacao conforme hacker-harness-integrity.md
```

- **HARNESS INTEGRO**: prosseguir para Fase 7
- **DERIVA**: reportar categorias e reconciliar antes de prosseguir

### Fase 7: Validacao do mock/pentest

Executar a validacao conforme `hacker-pentest-harness-execution.md`:

- Verificar que os vetores de ataque continuam sendo bloqueados (sem regressao)
- Verificar que nenhuma funcionalidade legitima foi quebrada (sem falso-positivo)
- Se houve mudanca em superficie de ataque: validar os novos vetores

- **PASS**: prosseguir para Fase 8
- **FAIL**: ir para Fase 4 (investigacao)

### Fase 8: Handoff automatico para doc-sync (Skill 4.6)

- **Tudo passou**: anotar os vereditos do ciclo (hacker-critical-analysis P1/P2,
  rule-control, resultado desta validacao, reconciliacoes) para a coleta do Trust Ledger,
  e **invocar `hacker-doc-sync` (4.6) SEM PAUSA**. A doc-sync e o ultimo passo autonomo
  do pipeline; a gravacao do Trust Ledger e a PARADA UNICA obrigatoria acontecem no FIM
  dela (depois da doc-sync, antes do finishing). NAO emitir a PARADA UNICA aqui, e NAO
  invocar finishing.
- **Algo falhou e nao foi possivel fixar** (2 tentativas esgotadas): parada de emergencia,
  reportar com evidencia completa (a parada de emergencia tambem e registrada no ledger).

## Saida Esperada

```
VALIDACAO POS-EXECUCAO (perfil: hacker-etico-ambiente):
  [PASS] Fase 1 (bash -n + shellcheck + py_compile + docker config + git diff --check)
  [PASS] Fase 2 (teste SUNSET)
  [PASS] Fase 5 (postura de rede: verificar-vazamento.sh GOOD)
  [PASS] Fase 6 (harness integro)          [se mudou .opencode/]
  [PASS] Fase 7 (mock/pentest)

Validacao verde -> invocando hacker-doc-sync (4.6) sem pausa.
(Trust Ledger e PARADA UNICA acontecem no FIM da doc-sync.)
```

## Integracao

**Skill anterior**: `hacker-subagent-driven-development` (Skill 4)
**Proxima skill (automatica, sem pausa)**: `hacker-doc-sync` (4.6), que roda o Trust Ledger
e emite a PARADA UNICA no fim dela. O `hacker-finishing-branch` (5) so executa com
autorizacao explicita do Fernando na PARADA UNICA.

## Lembrar

- Os comandos sao obrigatorios e sequenciais (1 por vez, proximo so se anterior passou)
- Regra canonica anti-invencao: `.opencode/rules/hacker-epistemic-safety.md`. Verdetos de
  validacao so com a saida literal real de cada comando; teste nao rodado = nao afirmar PASS.
- Postura de rede: verificar-vazamento.sh GOOD obrigatorio se houve acao de rede
- Investigar causa raiz, nao sintoma; reconciliar veredito de gate furado no ledger (F11)
- Fernando aprova qualquer fix que saia do escopo da spec
- Sempre PT-BR

## Hierarquia de verificacao (Fable 05, RAG de metodo)

"PASS" e afirmacao empirica: vem da execucao, nao da leitura do codigo. Quando a Fase 1 passar,
declarar o nivel de evidencia efetivamente alcancado (cada linha e um nivel, o de cima e o mais
forte; linhas abaixo so confirmam quando acompanham um atual nivel):

| Nivel | O que conta como evidencia |
|---|---|
| A | a mudanca executada de ponta a ponta no ambiente real (caso mais forte) |
| B | teste automatizado que falha sem a mudanca e passa com ela (SUNSET real, F7) |
| C | suite + build completos passando (validacao por atributo do perfil) |
| D | type-check/lint passando (bash -n, shellcheck, py_compile, compose config) |
| E | releitura critica do codigo (fraco, nunca sozinho) |

- Verificar a mudanca em si, descendo ao vizinho so quando o contexto pedir (nao re-testar tudo).
- Reportar com honestidade: falhou? o texto diz o que rodou e o que retornou (F3, saida literal).
  Evidencia de nivel baixo declarada como tal, nunca elevada por tom (07, tom por evidencia).
- Se a execucao de ponta a ponta nao for possivel (ex.: sem cadeia GOOD), declarar o limite da
  verificacao substituta e NAO dizer que o e2e passou (epistemic-safety).
