---
description: Roda o pipeline SDD manual do harness hacker. A cada skill, para e aguarda aprovacao explicita de Fernando antes de avancar. Use quando Fernando pedir para executar o pipeline passo a passo / manual / com parada em cada etapa.
agent: build
---

# Hacker Etico SDD Pipeline Manual (Specification-Driven Development)

## Overview

O Hacker Etico SDD Pipeline Manual e um workflow sequencial de skills que governa o
desenvolvimento de forma deterministica e auditavel. **Cada etapa exige parada obrigatoria
e aprovacao explicita do Fernando antes de avancar.** Nenhuma skill executa a proxima sem
aprovacao humana.

## Modo

**100% manual.** O modelo executa uma skill, apresenta o resultado, PARA e aguarda aprovacao
explicita do Fernando. So avanca para a proxima skill apos receber "sim", "pode", "aprovado",
"ok" ou "prossiga".

## Pre-requisito obrigatorio: postura de protecao (F1)

Toda mudanca que tocar rede exige a postura de protecao GOOD como pre-flight, de forma literal:

```bash
bash ~/opsec/scripts/verificar-vazamento.sh
```

- GOOD: cadeia ativa (IP de saida != IP real, DNS sem ECS, IPv6 off, kill-switch coerente).
  Pode prosseguir com acao de rede.
- Outros/erro/nao executado: BLOQUEADO. Nao toque rede. Reportar ao Fernando.

## Fluxo (cada skill BLOQUEIA aguardando aprovacao explicita do Fernando)

1. **Skill 1: hacker-specification-design** - Step 1 (contexto); Step 1.5 RAG RETRIEVAL
   obrigatorio (lei F6: canon interno + doc oficial externa; GATE: spec sem fonte =
   AMBIGUA); Step 2/2.5 (spec gerada + leitura do codigo real). **PARADA**: Fernando revisa
   a spec gerada.
2. **Skill 0: hacker-critical-analysis (PONTO 1, pre-spec)** - inclui secao 2.7 (grounding
   RAG). OUTPUT: PROSSEGUIR (gravar) ou REJEITAR (ajustar). **PARADA**: Fernando revisa o
   veredito.
3. **Skill 1 (gravacao)** - SPEC gravada em `.opencode/specs/`. **PARADA**: Fernando confirma
   a gravacao.
4. **Skill 2: pre-writing-rule-control** - spec contra as regras do projeto. OUTPUT:
   PASS/FAIL. **PARADA**: Fernando revisa o resultado.
5. **Skill 3: hacker-writing-plans** - PLAN com tarefas atomicas, gravado em `.opencode/plans/`.
   **PARADA**: Fernando revisa e aprova o plano.
6. **Skill 0: hacker-critical-analysis (PONTO 2, pre-execucao)** - analise do plano. OUTPUT:
   PROSSEGUIR/REJEITAR. **PARADA**: Fernando revisa o veredito.
7. **Skill 4: hacker-subagent-driven-development** - execucao tarefa a tarefa (two-stage
   review). **PARADA**: Fernando revisa o resultado da execucao.
8. **Skill 4.5: hacker-tests** - validacoes do perfil + cadeia. FAIL: investigar causa,
   corrigir, retestar (max 2 ciclos; senao PARADA DE EMERGENCIA logada no Trust Ledger).
   **PARADA**: Fernando aprova o resultado da validacao.
9. **Skill 4.6: hacker-doc-sync** - reconcilia docs se a mudanca tocar docs/README do
   harness (codigo = verdade). **PARADA**: Fernando aprova as mudancas de doc.
10. **Skill 5: hacker-finishing-branch** - suite final do perfil + PR em `.opencode/pr/`. So
    roda com autorizacao explicita do Fernando; disposicao dele: finalizar ou abrir issues
    (PDCA).

## Regras Fundamentais

1. **Cada skill tem parada obrigatoria.** O modelo apresenta o resultado e PARA. Nao avanca
   sem aprovacao explicita do Fernando.
2. **NUNCA escrever codigo antes do design ser aprovado.** Skill 1 tem parada; so grava
   apos o Fernando aprovar a spec e a analise critica (Skill 0 P1) passar.
3. **NUNCA executar antes do plano ser aprovado.** Skill 3 tem parada; so executa apos o
   Fernando aprovar o plano e a analise critica (Skill 0 P2) passar.
4. **Loop de correcao da Skill 4.5 limitado.** O fix de teste tem no maximo **2 ciclos**; se
   o teste continua FAIL, PARADA DE EMERGENCIA: registro no Trust Ledger e reporte ao
   Fernando com a evidencia literal.
5. **Evidencia real sempre.** git diff/log reais (referencia apenas; git de escrita e do
   Fernando); numeros copiados da saida literal dos comandos desta sessao; falha reportada
   com a mesma proeminencia que sucesso. NUNCA fabricar evidencias.
6. **Fernando governa todas as decisoes.** Todas as paradas sao dele. O `finishing-branch`
   exige autorizacao explicita dele; quem decide finalizar ou abrir novas issues (PDCA) e
   ele.
7. **Pre-flight e Trust Ledger (leis F1 e F11).** A Skill 4 abre com o pre-flight de postura
   declarado por comando (Step 0 da skill e F1 deste workflow). Cada gate anota os campos do
   veredito; na parada da Skill 4.5 a `hacker-trust-ledger-update` grava as entradas do ciclo
   (append-only em `.opencode/ledger/trust-ledger.md`) e o relatorio inclui a secao Trust Ledger.
8. **Gate de harness (lei F10).** Se o git diff toca arquivos do harness (`.opencode/`,
   `AGENTS.md`), o procedimento de `hacker-harness-integrity.md` precisa retornar HARNESS
   INTEGRO antes do finishing (Step 1.5 da Skill 5); deriva reconcilia-se via
   `hacker-harness-sync`.
9. **Roteamento por modulo (canon).** No pre-flight da Skill 4, o modelo deriva dos paths da
   spec o(s) modulo(s) da cadeia e consulta o canon (`.opencode/rules/hacker-opsec-canon.md`)
   para carregar contexto e guardas ANTES de implementar; modulos sensiveis (scripts de
   protecao, `docker-compose.yml`, classe C) exigem confirmacao do Fernando antes de tocar a
   cadeia. A doc-sync (4.6) anexa o historico em `.opencode/ledger/modules/<modulo>.md`.
10. **RAG (lei F6).** O Step 1.5 da Skill 1 e obrigatorio: consultar (a) a doc canonica
    interna (`hacker-opsec-canon.md`, `~/opsec/README.md`) e (b) a doc oficial externa das
    tecnologias, com re-injecao no CONTEXT da spec. Hierarquia de fontes (onde divergirem,
    o de cima manda): (1) codigo real em `~/opsec/scripts/` e compose; (2) doc canonica
    interna; (3) doc oficial externa; (4) regras e metodo. Ver `hacker-opsec-canon.md` e
    `hacker-fable-method.md` F6.

## Entradas e Saidas

| Skill | Entrada | Saida | Gate |
|---|---|---|---|
| 1: specification-design | Request informal | Spec gerada | Fernando |
| 0 (P1): critical-analysis | Request + spec | PROSSEGUIR/REJEITAR | Fernando |
| (gravacao) | Spec aprovada | SPEC_NNN.md em .opencode/specs/ | Fernando |
| 2: pre-writing-rule-control | SPEC_NNN.md | PASS/FAIL | Fernando |
| 3: writing-plans | SPEC validada | PLAN_NNN.md em .opencode/plans/ | Fernando |
| 0 (P2): critical-analysis | SPEC + PLAN | PROSSEGUIR/REJEITAR | Fernando |
| 4: subagent-driven-development | PLAN validado | Tarefas completas | Fernando |
| 4.5: hacker-tests | Workspace atualizado | Validacao completa | Fernando |
| 4.6: doc-sync | git diff da mudanca | Doc sincronizada | Fernando |
| 5: finishing-branch | Workspace validado | PR_NNN.md em .opencode/pr/ | Fernando |

## Como Usar

Fernando descreve a necessidade, ex.:

```
"Preciso adicionar um novo vetor no verificar-vazamento.sh para detectar ECS via TLS"
```

Invocar: `/hacker-sdd-pipeline-manual`

O modelo executa Skill 1, apresenta a spec e PARA. Fernando aprova. O modelo executa Skill 0
P1, apresenta o veredito e PARA. Fernando aprova. E assim por diante em todas as etapas.

Respostas validas para avancar: "sim", "pode", "aprovado", "ok", "prossiga".

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
- `hacker-sdd-pipeline-auto.md`
- `hacker-sdd-pipeline-manual.md` (este)
- `hacker-redteam-hardening-pipeline.md` (loop de melhoria continua)

## Suporte

Se bloqueado: (1) consultar `AGENTS.md`; (2) consultar a skill especifica em `.opencode/skills/`;
(3) reportar o bloqueador exato ao Fernando e aguardar.