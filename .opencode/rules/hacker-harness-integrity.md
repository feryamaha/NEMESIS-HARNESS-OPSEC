---
trigger: always_on
status: active
scope: canonical
last_updated: 2026-09-09
---

# Hacker Etico: Harness Integrity (F10)

> Regra canonica, adaptada do Nemesis para repo unico (sem espelho entre repos). A verificacao de
> atributos do harness e mecanica e de responsabilidade do Fernando: o papel do agente e garantir
> que o procedimento exista e seguir as citacoes literais.
> Destinatario: modelos de IA agenticos, nao o humano. Anti-invencao: as citacoes literais sao
> lidas do arquivo real, nunca fabricadas (`.opencode/rules/hacker-epistemic-safety.md`).

## Origem e principio

No Nemesis, uma auditoria em 2026-07-09 achou divergencia entre scripts/documentos do harness e
forcou a criacao de uma regra escrita (procedimento markdown) com 3 diff commands que emite
`SPELHOS INTEGROS` quando os espelhos estao 1:1 e classifica divergencias (leve/semantica/rotura).
O script verifier daquele repo foi quarentenado como `nemesis_bypass` por julgar por si; por isso o
procedimento e markdown, nao script executavel pelo agente.

AQUI: o harness que governa este repo E o `.opencode/` deste repo (single-canon). Nao ha espelho entre
repos. A verificacao mecanica cobre o que JA existe: coerencia interna do `.opencode/` e citacoes
literais de comandos.

## Manifest do harness (.opencode/)

Estrutura esperada conforme a doc oficial do opencode (opencode.ai/docs: rules, skills, commands,
agents, config). A verificacao confere presenca e coerencia:

```
.opencode/
  agents/         orquestrador.md, implementador.md, revisor.md, documentador.md
  commands/       hacker-sdd-pipeline-auto.md, hacker-sdd-pipeline-manual.md,
                  hacker-redteam-hardening-pipeline.md
  rules/          hacker-*.md (8 regras: documentation-style, epistemic-safety, trust-ledger,
                  fable-method, repo-profile, pentest-harness-execution, harness-integrity, opsec-canon)
  skills/         <nome>/SKILL.md, com frontmatter name == pasta (13 skills)
  ledger/         trust-ledger.md (append-only) + modules/ (ledgers por modulo)
  rag/            ORQUESTRADOR-FABLE-HACKER.md + fable/ (espelho 1:1 do Fable_Knowledge_Harness)
                  + fable-harness-completo.md + build-rag.sh
  specs/          SPEC_NNN_*-descritivo.md (pipeline, Skill 1)
  plans/          PLAN_NNN_*-descritivo.md (pipeline, Skill 3)
  pr/             PR_NNN_*-descritivo.md (propostas de finalizacao, Skill 5, criado no finishing)
```

O opencode carrega: instrucoes via `opencode.json` (`instructions`: AGENTS.md + 8 regras + o
orquestrador RAG do Fable), skills por gatilho via `.opencode/skills/*/SKILL.md`, commands em
`.opencode/commands/*.md`, agents em `.opencode/agents/*.md`. Nao existe `workflows/`: os
pipelines do harness vivem em `commands/` e sao invocados como comandos da TUI (`.opencode/commands/`).

## Procedimento markdown (quando algo no harness muda)

1. `find .opencode -type f | sort`, excluindo da contagem de harness: `node_modules/`
   (dependencias do plugin `@opencode-ai/plugin`), `package.json`/`package-lock.json`/
   `.gitignore` (arquivos de suporte do opencode no repo) e `rag/fable/` (o espelho Fable
   tem checagem propria via `build-rag.sh`). Somar `wc -l` dos arquivos do harness e conferir
   que o count bate com o esperado (nada deletado/duplicado sem entrada no ledger).
2. `grep -rln "Nemesis_Defender_v0\|../Dashboard\|\.claude/skills" .opencode` : zero ocorrencias de
   referencias a espelho/repos externo (repo unico). Entradas historicas que citam o metodo como
   origem (ex.: "adaptado do Nemesis") sao permitidas e nao geram divergencia. Se houver, registrar
   como divergencia-semantica e reconciliar.
3. `grep -rn "IP real\|credencial\|senha" .opencode 2>/dev/null` : conferir que nenhum dado real
   vazou ao repo (regra 4 do documentation-style).
4. Conferir citacoes literais: cada comando de `verificar-vazamento.sh`,
   `docker compose -f ~/opsec/docker-compose.yml config`, `bash -n`, `git diff --check` citado em
   skills/commands/AGENTS existe no arquivo realmente. Divergencia de citacao = divergencia-leve.
5. Conferir sync skills vs project skills quando `.opencode/skills` referencia paths reais de
   `~/opsec/`: os paths citados existem.

Resultado final do procedimento em harness: `HARNESS INTEGRO` ou `DERIVA:<categoria>`. Veredito no
ledger com `base=` mostrando a saida literal do comando de verificacao.

## Categorias de divergencia

- **leve**: path citado errado, comando citado nao existe, licenca de citacao
- **semantica**: conteudo diverge do significado (ex.: citar verificacao de DNS mas outra resolucao)
- **rotura**: arquivo do harness sumiu/alterado sem entrada no ledger

## Quando roda

- no fim da doc-sync (Skill 4.6), se houve mudanca no `.opencode/`;
- dentro da Skill 1.5/Step 1.5 (finishing) antes de abrir PR (gate F10);
- promovido a ponte de emergencia se qualquer skill tiver sua regra de harness tocada.

## Integracao

Lei F10 no `hacker-fable-method.md`; fluxo na `hacker-harness-sync` (Skill 4.5); apos garantir
integros, nao alterar mais nada ate o PR ser aberto e fechado pelo Fernando.