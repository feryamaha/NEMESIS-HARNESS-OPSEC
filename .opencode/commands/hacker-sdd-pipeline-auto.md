---
description: Roda o pipeline SDD automatico do harness hacker. Dispara o fluxo integral do input ate a PARADA UNICA, sem paradas intermediarias. Use quando Fernando pedir para executar/prosseguir/rodar o pipeline automatico.
agent: build
---

# Hacker Etico SDD Pipeline Auto (Specification-Driven Development)

## Overview

O Hacker Etico SDD Pipeline Auto e um workflow sequencial de skills que governa o
desenvolvimento de forma deterministica e auditavel. **100% automatico: o modelo executa
todas as skills do input ate a Skill 4.6 (doc-sync) sem parar para aprovacao intermediaria.**
A unica parada e antes da Skill 5 (finishing): o modelo apresenta o relatorio consolidado e
o Fernando decide se autoriza o finishing.

## Modo

**100% automatico.** O modelo executa do input ate a conclusao da Skill 4.6 sem pausar para
aprovacao. Gates automaticos (Skill 0, Skill 2) bloqueiam se falharem, mas nao pedem
aprovacao humana. Apos a Skill 4.6, o modelo PARA na **PARADA UNICA** e apresenta o relatorio
consolidado. So o `finishing-branch` (Skill 5) exige autorizacao explicita do Fernando, que
decide finalizar ou abrir novas issues (PDCA).

## Pre-requisito obrigatorio: postura de protecao (F1)

Toda mudanca que tocar rede exige a postura de protecao GOOD como pre-flight, de forma literal:

```bash
bash ~/opsec/scripts/verificar-vazamento.sh
```

- GOOD: cadeia ativa (IP de saida != IP real, DNS sem ECS, IPv6 off, kill-switch coerente).
  Pode prosseguir com acao de rede.
- Outros/erro/nao executado: BLOQUEADO. Nao toque rede. Reportar ao Fernando.

## Fluxo (modelo executa as skills em ordem, sem pausas intermediarias)

1. **Skill 1: hacker-specification-design** - Step 1 (contexto); Step 1.5 RAG RETRIEVAL
   obrigatorio (lei F6: canon interno + doc oficial externa; GATE: spec sem fonte consultada
   = AMBIGUA); Step 2 especificacao + Step 2.5 leitura do codigo real em `~/opsec/`.
   OUTPUT: spec gerada, nao gravada ainda.
2. **Skill 0: hacker-critical-analysis (PONTO 1, pre-spec)** - inclui secao 2.7 (grounding
   RAG). GATE AUTOMATICO: PROSSEGUIR grava a spec; REJEITAR ajusta; segundo veredito
   negativo vira PARADA DE EMERGENCIA.
3. **Skill 1 (gravacao)** - SPEC gravada em `.opencode/specs/`.
4. **Skill 2: pre-writing-rule-control** - spec contra as regras do projeto. GATE AUTOMATICO:
   PASS prossegue; FAIL ajusta e revalida.
5. **Skill 3: hacker-writing-plans** - PLAN com tarefas atomicas, gravado em `.opencode/plans/`.
6. **Skill 0: hacker-critical-analysis (PONTO 2, pre-execucao)** - analise critica do plano.
   GATE AUTOMATICO: PROSSEGUIR executa; REJEITAR ajusta.
7. **Skill 4: hacker-subagent-driven-development** - execucao tarefa a tarefa (two-stage review); sem pausa entre tarefas.
8. **Skill 4.5: hacker-tests** - validacoes do perfil (bash/python3/compose/git) + cadeia.
    PASS: segue. FAIL: loop evaluator-optimizer (max 5 ciclos ate convergencia); se persistir sem melhoria, PARADA DE EMERGENCIA logada no Trust Ledger e reporte ao Fernando.
9. **Skill 4.6: hacker-doc-sync** - escrita automatica ao fim: se a mudanca toca docs/README
    do harness, reconcilia (codigo = verdade, perfil como fonte); senao veredito "nada a
    atualizar".
10. **⛔ PARADA UNICA** - o modelo apresenta o relatorio consolidado (formato abaixo) e PARA.
    Nenhuma skill pos-validacao (5) executa sem autorizacao. HARD-GATE: Fernando decide.
11. **Skill 5: hacker-finishing-branch** - so com autorizacao explicita do Fernando. Suite
    completa do perfil + PR documentada em `.opencode/pr/`. Disposicao do Fernando: finalizar
    ou abrir novas issues, PDCA.

## Routing Condicional

O gate binário (PROSSEGUIR/REJEITAR) é substituído por routing condicional baseado no tipo de spec:

| CATEGORY da Spec | Rota | Observações |
|---|---|---|
| "Infra" + arquivos em `~/opsec/scripts/` | Gate reforçado (classe C, Fernando confirma) + pre-flight reforçado | Toca cadeia de proteção |
| "Docs" | Route direto para documentador (sem gate de security) | Sem risco de segurança |
| "Bugfix" | Gate padrão + pre-flight F1 | Fluxo normal |
| "Feature" + toca cadeia | Orquestrador + gate reforçado | Escopo ampliado |
| "Feature" + não toca cadeia | Route padrão | Fluxo normal |

Cada categoria de spec tem rota definida e executável. O routing é verificado pelo F10 (harness-integrity).

## Diagrama de Controle

```
FERNANDO (DECISOR) → GATES (gate-preflight.sh, gate-p1.sh, gate-p2.sh) → GRAPH + LOOP (executores) → PARADA UNICA → FERNANDO
```

- Fernando autoriza → Gates executáveis (código de saída: 0=PASS, 1=FAIL, 2=BLOQUEADO) → Loop itera (max 5 ciclos) → PARADA UNICA → Fernando decide
- O Loop itera automaticamente dentro de limites definidos, mas para na PARADA UNICA
- Ações de classe C sempre param para confirmação do Fernando
- HARNESS GUARDIAN: se a cadeia quebra, Loop e Graph são pausados automaticamente

## Regras Fundamentais

1. **Autonomia ate a PARADA UNICA, nunca alem dela.** Entre o input e o fim da Skill 4.6 nao
    ha pausas para aprovacao. A PARADA UNICA e inegociavel: nenhuma skill pos-validacao (5)
    e invocada automaticamente, nem "por conveniencia".
2. **Gates automaticos nao sao decorativos.** A analise critica (Skill 0) e o rule control
    (Skill 2) substituem a aprovacao humana intermediaria; por isso os vereditos deles
    BLOQUEIAM de verdade. Os gates agora sao scripts executaveis (.hacker/scripts/gate-*.sh)
    com codigo de saida: 0=PASS, 1=FAIL, 2=BLOQUEADO. Veredito negativo permite UM ciclo de
    ajuste + re-analise; o segundo veredito negativo vira PARADA DE EMERGENCIA.
3. **Loop Evaluator-Optimizer (Fable Pattern 5)**. O fix-loop itera automaticamente até convergência
    (GOOD + todos PASS) ou 5 ciclos sem melhoria mensurável. Cada ciclo gera entrada no Trust Ledger.
    Ações de classe C sempre param para confirmação do Fernando.
4. **Paradas de emergencia** (alem da PARADA UNICA): bloqueio persistente apos correcao;
    loop de evaluator-optimizer sem convergencia apos 5 ciclos; escopo real materialmente maior
    que a spec; qualquer acao irreversivel ou de rede nao prevista no plano (classe C, F4);
    ambiguidade que genuinamente impede progresso. Nesses casos: STOP, reportar o bloqueador
    exato com evidencia, aguardar o Fernando.
5. **Evidencia real sempre.** git diff/log reais (referencia apenas; git de escrita e do
    Fernando); numeros copiados da saida literal dos comandos desta sessao; falha reportada
    com a mesma proeminencia que sucesso.
6. **Fernando governa as decisoes humanas.** A PARADA UNICA, o finishing e a disposicao da
    branch sao dele. Git de escrita e exclusivamente dele. So ele decide finalizar ou abrir
    novas issues (PDCA).
7. **Pre-flight e Trust Ledger (leis F1 e F11).** A Skill 4 abre com o pre-flight de postura
    declarado por comando (Step 0 da skill e F1 deste workflow). Cada gate (Skill 0 P1/P2,
    Skill 2) anota os campos do veredito; na PARADA UNICA a `hacker-trust-ledger-update`
    grava todas as entradas do ciclo (append-only em `.opencode/ledger/trust-ledger.md`) e o
    relatorio consolidado inclui a secao Trust Ledger.
8. **Gate de harness (lei F10).** Se o git diff do ciclo toca arquivos do harness
    (`.opencode/`, `AGENTS.md`), o procedimento de `hacker-harness-integrity.md` precisa
    retornar HARNESS INTEGRO antes do finishing (Step 1.5 da Skill 5); deriva reconcilia-se
    via `hacker-harness-sync`.
9. **Distribuicao por camadas de raciocinio.** O pipeline e executado por um ORQUESTRADOR
    (o modelo principal da sessao) que distribui fases a subagentes dedicados. Julgamento,
    gates, PARADA UNICA e Trust Ledger NUNCA se delegam. (Secao "Distribuicao de modelos".)
10. **Roteamento por modulo (pre-flight).** No pre-flight, o orquestrador deriva dos paths da
    spec o(s) modulo(s) da cadeia no canon (`.opencode/rules/hacker-opsec-canon.md`) e carrega
    as guardas no contrato de handoff. Modulos sensiveis (scripts de protecao,
    `docker-compose.yml`, classe C) recebem atencao reforcada: tocar a cadeia exige
    confirmacao do Fernando.
11. **RAG (lei F6).** O Step 1.5 da Skill 1 e obrigatorio: consultar (a) a doc canonica
    interna (`hacker-opsec-canon.md`, `~/opsec/README.md`) e (b) a doc oficial externa das
     tecnologias (WireGuard, ProtonVPN, Tor, gluetun, Docker, Systemd-resolved, ferramentas de pentest),
    com re-injecao no CONTEXT da spec. Hierarquia de fontes (onde divergirem, o de cima
    manda): codigo real em `~/opsec/scripts/` e compose; doc canonica interna; doc oficial
    externa; regras e metodo. Ver `hacker-opsec-canon.md` e `hacker-fable-method.md` F6.

12. **Gates programaticos (F10)**. Os gates agora sao scripts executaveis: `gate-preflight.sh`,
    `gate-p1.sh`, `gate-p2.sh` em `.hacker/scripts/`. O pipeline os chama, nao verifica texto.
    Cada gate retorna codigo de saida: 0=PASS, 1=FAIL, 2=BLOQUEADO.

## Distribuicao de modelos por camada de raciocinio (orquestracao de subagentes)

A atribuicao de modelo e por CAMADA DE RACIOCINIO relativa, nunca por nome fixo: no inicio
de cada ciclo o orquestrador mapeia as camadas relativas aos modelos disponiveis na IDE.

| Camada | Papel | Fases | Regra de mapeamento |
|---|---|---|---|
| MAIOR | Investigacao, analise de causa, spec, analises criticas, plano, orquestracao | Skills 1, 0 (P1/P2), 2, 3 + Trust Ledger | O modelo principal da sessao (maior raciocinio). NUNCA delegar. |
| MEDIA | Executor fiel do plano | Skill 4, implementadores | Um degrau abaixo do orquestrador (ou o proprio) |
| REVISOR | Review independente, testes, validacoes | Skill 4 revisores; Skill 4.5 | Media-para-baixo; DISTINTO do implementador da mesma tarefa |
| LEVE | doc-sync e preparacao do finishing | Skill 4.6; Skill 5 (texto da PR) | Modelo mais leve confiavel, menor custo |

**Regras de orquestracao:**

1. **O que NUNCA se delega:** vereditos das analises criticas (Skill 0), HARD-GATEs, PARADA
   UNICA, escrita do Trust Ledger e relatorio consolidado. Subagente prepara e executa; o
   orquestrador confere, julga e apresenta.
2. **Sincronizacao por dependencia (gate de fase):** um subagente so e disparado quando o
   artefato de que depende existe e esta validado. Ordem inviolavel: implementacao (4) ->
   validacao (4.5) -> doc-sync (4.6). doc-sync NUNCA dispara antes da validacao PASS.
3. **Paralelismo so DENTRO da Skill 4, por waves:** tarefas sem dependencia (DEPENDE_DE) e
   com arquivos disjuntos executam em paralelo; intersecao de arquivos ou dependencia =
   waves sequenciais.
4. **Contrato de handoff completo (lei F9):** todo subagente nasce sem memoria da conversa;
   o disparo carrega o contrato integral (objetivo, arquivos exatos, invariantes de protecao,
   o-que-nao-fazer, comando de verificacao, formato do resultado).
5. **Fallback obrigatorio:** se a IDE nao oferece selecao de modelo por subagente, o pipeline
   executa com subagentes no modelo da sessao. A distribuicao e otimizacao, nunca condicao.

## Entradas e Saidas

| Fase | Entrada | Saida | Gate |
|---|---|---|---|
| 1: specification-design | Input informal / ISSUE | Spec gerada | automatico (Skill 0 P1) |
| 0 (P1): critical-analysis | Request + spec | PROSSEGUIR/REJEITAR | automatico |
| (gravacao) | Spec aprovada | SPEC_NNN.md em .opencode/specs/ | nenhum |
| 2: pre-writing-rule-control | SPEC_NNN.md | PASS/FAIL | automatico |
| 3: writing-plans | SPEC validada | PLAN_NNN.md em .opencode/plans/ | automatico (Skill 0 P2) |
| 0 (P2): critical-analysis | SPEC + PLAN | PROSSEGUIR/REJEITAR | automatico |
| 4: subagent-driven-development | PLAN validado | Tarefas completas | continuo |
| 4.5: hacker-tests | Workspace atualizado | Validacao completa | automatico |
| 4.6: doc-sync | git diff da mudanca | Doc sincronizada | automatico |
| ⛔ PARADA UNICA | Tudo acima | Relatorio consolidado | **Fernando** |
| 5: finishing-branch | Autorizacao explicita | PR_NNN.md em .opencode/pr/ | **Fernando** |

## Relatorio da PARADA UNICA (formato obrigatorio)

```
PIPELINE CONCLUIDO ATE A VALIDACAO - aguardando Fernando

Spec:   [caminho da spec]
Plano:  [caminho do plano]
Postura de protecao (verificar-vazamento.sh): [GOOD | BLOQUEADO + evidencia]
Diff real (git diff --stat, referencia):
[saida literal]
Validacao:
| Comando | Resultado | Observacao |
[tabela com saidas literais: bash -n, shellcheck, py_compile, compose config, diff --check]
Decisoes tecnicas tomadas (com justificativa em 1 linha cada):
[lista]
Achados fora de escopo (estacionamento - sem acao tomada):
[lista com arquivo:linha, ou "nenhum"]
Doc-sync: [veredito PRECISA/NAO PRECISA + o que foi atualizado]
Trust Ledger (ciclo [ref]):
- entradas gravadas: N
- gates do ciclo: P1=[veredito], rule-control=[veredito], P2=[veredito]
- validacao: [PASS/FAIL + placar literal]
- reconciliacoes: [nenhuma | lista]
- gate F10 (harness): [nao se aplica | INTEGRO | deriva reconciliada]
Proximos passos possiveis:
(a) autorizar finishing  (b) abrir novas issues (PDCA)  (c) ajustar  (d) descartar
```

## Como Usar

Fernando descreve a necessidade (ex.: "Preciso adicionar um novo vetor no verificar-vazamento.sh para detectar DoH bypass") e invoca `/hacker-sdd-pipeline-auto`.

O modelo executa tudo automaticamente ate a Skill 4.6, apresenta o relatorio da PARADA UNICA
e PARA. Fernando decide o proximo passo. Respostas validas para avancar: "sim", "pode",
"aprovado", "ok", "prossiga".

## Comandos de Validacao

> Fonte canonica dos comandos e fases por stack: o perfil deste repo,
> `.opencode/rules/hacker-repo-profile.md`. Resumo abaixo.

```bash
bash -n <script>                                          # sintaxe bash
shellcheck <script>                                       # lint bash (quando disponivel)
python3 -m py_compile <arquivo.py>                        # sintaxe python3
docker compose -f ~/opsec/docker-compose.yml config       # sintaxe compose
git diff --check                                          # whitespace git
bash ~/opsec/scripts/verificar-vazamento.sh               # cadeia GOOD (rede, F1)
```

## Convencoes de Nomenclatura

- **Specs**: SPEC_NNN_nome-descritivo.md (em .opencode/specs/)
- **Plans**: PLAN_NNN_nome-descritivo.md (em .opencode/plans/)
- **PRs**: PR_NNN_nome-descritivo.md (em .opencode/pr/)
- **Numero**: auto-increment verificado com `ls` antes de gravar (nunca assumir)

## Cross-reference

Este workflow e um dos tres do harness deste repo:
- `hacker-sdd-pipeline-auto.md` (este, default)
- `hacker-sdd-pipeline-manual.md`
- `hacker-redteam-hardening-pipeline.md` (loop de melhoria continua)

## Suporte

Se bloqueado: (1) consultar `AGENTS.md`; (2) consultar a skill especifica em `.opencode/skills/`;
(3) reportar o bloqueador exato ao Fernando e aguardar.