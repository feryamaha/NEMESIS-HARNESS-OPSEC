---
name: hacker-doc-sync
description: >
  Trata documentacao como FEATURE. APOS a validacao (Skill 4.5) e ANTES do finishing (Skill 5),
  analisa o git diff da mudanca e decide se a superficie de doc do perfil (README.md, LEDGER.md,
  AGENTS.md, skills decididas por role) precisa ser atualizada. Se nao, segue o fluxo. Se sim,
  reconcilia (codigo = verdade, sem inserir por inserir). Roda automaticamente como ultimo passo
  autonomo; a PARADA UNICA obrigatoria (HARD-GATE humano) acontece no FIM dela, antes do finishing.
  Garante que a PR sempre contenha a documentacao sincronizada.
---

# Hacker Doc Sync (documentacao como feature)

> **Texto unico.** A superficie de doc vem do perfil: `README.md`, `LEDGER.md`,
> `AGENTS.md`, skills decididas por role. Specs ficam em `.opencode/specs/`.

## ULTIMO PASSO AUTONOMO (roda automaticamente, e a PARADA UNICA vem no fim dela)

Esta skill **faz parte da fase autonoma do pipeline** (modo auto): a `hacker-tests` (4.5)
a invoca automaticamente, sem pausa. **A PARADA UNICA obrigatoria acontece no FIM desta
skill** (Fase 4), depois da doc-sync e antes do finishing. E nesse ponto que o Fernando
revisa o relatorio consolidado (incluindo as mudancas de doc, se houver) e decide entre
finalizar a entrega (`hacker-finishing-branch`) ou gerar novas issues e reiniciar o ciclo
(PDCA). Apenas a `hacker-finishing-branch` exige autorizacao explicita dele.

**Anuncio de inicio**: "Estou usando a skill hacker-doc-sync para verificar se a mudanca exige atualizar a documentacao."

**Pre-requisito**: Skill 4.5 (`hacker-tests`) concluida - codigo validado, suite do perfil
verde.

## Por que existe

Documentacao errada deixa o codigo em **check-mate**: o usuario confia na doc, nao no codigo.
Por isso a doc e tratada como **feature** e tem um passo proprio no pipeline, **apos a
validacao e antes do finishing**, rodando automaticamente - assim a **PR sempre inclui a
atualizacao de doc**, e nunca mais "atualiza codigo e esquece a documentacao".

## Processo

### Fase 1: Coletar o que mudou (git diff real)
```bash
git diff --stat
git diff
```

Read-only (git de escrita e exclusivo do Fernando). O diff e a fonte do que mudou.

### Fase 2: GATE DE DECISAO - a mudanca afeta a documentacao publica?

Confronte o diff contra o que a superficie de doc do perfil DOCUMENTA. Checklist de itens
documentados que podem ser afetados:
- **Scripts citados:** nomes de scripts em `~/opsec/scripts/`, comportamento, dependencias.
- **Docker:** servicos, portas, volumes, flags `opsec_sensitive`.
- **Postura de protecao:** fluxo de verificar-vazamento.sh, pre-flight de rede.
- **Comandos de validacao:** bash -n, shellcheck, py_compile, docker compose config.
- **Nomes de arquivos/comandos user-facing** (scripts, docker-compose.yml, LEDGER.md).
- **Feature nova ou comportamento mudado** que o usuario percebe.
- **Harness (F10):** a mudanca tocou arquivos do harness (`.opencode/`)? Se sim, rodar o
  procedimento de `hacker-harness-integrity.md` e reportar o resultado.

Para CADA item afetado, emita um veredito:
- **NAO PRECISA** - o diff nao toca nada documentado, OU a doc ja reflete. Justifique em 1 linha.
- **PRECISA** - liste exatamente o que ficou divergente (doc vs codigo), com `arquivo:linha`.

> **Regra dura: nao inserir doc por inserir.** Bugfix interno, refactor, mudanca de teste etc.
> geralmente NAO exigem atualizacao. So atualize o que a mudanca tornou divergente.

### Fase 3a: Veredito NAO PRECISA
Reporte "a doc ja reflete a mudanca; nada a atualizar" e siga para a Fase 4 (PARADA UNICA).

### Fase 3b: Veredito PRECISA - reconciliar (codigo = verdade)

Atualize a superficie de doc do perfil com disciplina:
- **Codigo e a fonte de verdade.** Verifique cada numero/fato no codigo antes de escrever
  (nao invente).
- **Sem numero fragil:** prefira descrever por modulo/camada + gate a cravar um total que
  a proxima mudanca defasa.
- **Cirurgico:** mude so o que ficou divergente; nao reescreva secoes inteiras sem
  necessidade.

Apresente o diff das mudancas de doc.

### Fase 4: PARADA UNICA obrigatoria (HARD-GATE humano, fim da fase autonoma)

Esta e a **PARADA UNICA do pipeline**: depois da doc-sync, antes do finishing. Passos:

1. **Trust Ledger (lei F11):** invocar `hacker-trust-ledger-update` para gravar todos os
   vereditos do ciclo (gates da Skill 0 P1/P2, rule-control, resultado da Skill 4.5,
   reconciliacoes) e o veredito desta doc-sync (PRECISA/NAO PRECISA), append-only em
   `.opencode/ledger/trust-ledger.md`.
2. **Relatorio consolidado:** emitir o relatorio da PARADA UNICA no formato do workflow
   (`hacker-sdd-pipeline-auto.md`): spec, plano, git diff real, tabela de validacao com
   saidas literais, decisoes tomadas, achados fora de escopo, veredito da doc-sync (e o diff
   das mudancas de doc, se houve), secao Trust Ledger, gate F10 (harness).
3. **BLOQUEAR e aguardar o Fernando.** Documentacao e feature: as mudancas de doc (se
   houve) sao revisadas por ele aqui, junto do resto. **NAO invocar `hacker-finishing-branch`
   automaticamente** - ela so executa com autorizacao explicita dele. Respostas validas para
   avancar ao finishing: "sim", "pode", "aprovado", "ok", "prossiga".

## Saida

- Veredito (PRECISA / NAO PRECISA) e, se PRECISA, as mudancas de doc aplicadas,
  apresentadas na PARADA UNICA para revisao do Fernando.
- Resultado do check de espelhamento do harness, quando aplicavel.
- Trust Ledger do ciclo gravado; relatorio consolidado emitido; pipeline PARADO aguardando
  o Fernando decidir entre finishing ou reiniciar o ciclo (PDCA).

## Integracao

- **Skill anterior**: `hacker-tests` (4.5), que invoca esta skill automaticamente (sem pausa).
- **Proxima skill (SO com autorizacao explicita do Fernando na PARADA UNICA)**:
  `hacker-finishing-branch` (5) - a PR ja inclui a documentacao sincronizada no git diff.

## Lembrar

- Documentacao = feature. Doc errada = check-mate.
- Regra canonica anti-invencao: `.opencode/rules/hacker-epistemic-safety.md`. Nunca inventar
  dados, paths, mudancas aplicadas nem citacoes; afirmar so o verificado no diff/arquivo.
- Roda automaticamente apos a Skill 4.5; a PARADA UNICA vem no FIM desta skill (Fase 4).
- GATE de decisao ANTES de editar (nao inserir por inserir).
- Codigo = verdade; doc do perfil sincronizada.
- Mudanca em harness = rodar o procedimento de espelhamento (F10).
- Validacao PASS = SEMPRE registrar no ledger.
- Git e exclusivo do Fernando. Finishing so com autorizacao explicita do Fernando.
- Sempre PT-BR.
