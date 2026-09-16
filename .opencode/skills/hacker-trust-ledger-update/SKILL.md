---
name: hacker-trust-ledger-update
description: >
  Registra no Trust Ledger do repo (.opencode/ledger/trust-ledger.md) os vereditos, validacoes,
  reconciliacoes e paradas do ciclo corrente (lei F11). Invocada na PARADA UNICA pela
  hacker-tests, nas paradas de emergencia, ao fim de ciclos de red team e de post-mortems.
  Append-only; numeros copiados da saida literal. Formato: [data] | ciclo= | skill= |
  evento= | resultado= | base=.
---

# Hacker Trust Ledger Update (lei F11)

Persistir os vereditos do ciclo como artefatos e reconcilia-los com o desfecho.

> **Texto unico.** O ledger e `.opencode/ledger/trust-ledger.md` (append-only, nunca
> removido). Formato e eventos:
> `.opencode/rules/hacker-trust-ledger.md` (fonte unica; nao duplicar aqui).

**Anuncio de inicio**: "Estou usando a skill hacker-trust-ledger-update para registrar os vereditos do ciclo no Trust Ledger."

## Quando invocar

1. **PARADA UNICA** (fim da `hacker-tests`, Fase 8): escrita padrao do ciclo completo.
2. **Parada de emergencia**: registrar o evento antes de aguardar o Fernando.
3. **Fim de ciclo de red team** e **fim de post-mortem** (`hacker-postmortem-to-law`).

## Formato de entrada

Cada linha no ledger segue o formato:
```
[data] | ciclo=<ref> | skill=<nome> | evento=<tipo> | resultado=<veredito> | base=<1-linha>
```

## Eventos suportados

- `veredito-p1`: veredito do Ponto 1 da analise critica (spec compliance)
- `veredito-p2`: veredito do Ponto 2 da analise critica (plano)
- `veredito-rule-control`: veredito do pre-writing-rule-control
- `validacao`: resultado da bateria de testes (Skill 4.5)
- `reconciliacao`: gate anterior deixou passar algo que a validacao reprovou
- `parada-emergencia`: parada de emergencia com motivo
- `ciclo-redteam`: fim de ciclo de red team
- `postmortem`: emenda aplicada ou "sem emenda por decisao do Fernando"
- `harness`: verificacao de integridade do harness (F10)
- `decisao`: decisao do Fernando (finalizar, reiniciar, etc.)

## Processo

### Step 1: Coletar os eventos do ciclo (copia, nao reconstrucao)

Reunir da SESSAO atual (lei F3/F6: da saida literal, nunca de memoria):
- vereditos anotados pelos gates (`veredito-p1`, `veredito-p2`, `veredito-rule-control`),
  cada um com veredito, base em 1 linha e ref de spec/plano;
- resultado da validacao (`validacao`) com as fases executadas e o placar literal;
- reconciliacoes apontadas pela Fase 4 da `hacker-tests` (`reconciliacao`);
- paradas de emergencia, ciclos de red team, post-mortens e checks de harness, se houver.

### Step 2: Append no ledger

Abrir `.opencode/ledger/trust-ledger.md` e ACRESCENTAR ao final uma linha por evento, no
formato da regra canonica. NUNCA editar ou remover entradas existentes; correcao e entrada
nova referenciando a anterior.

### Step 3: Scorecard do ciclo (para o relatorio da PARADA UNICA)

Emitir o bloco:

```
Trust Ledger (ciclo [ref]):
- entradas gravadas: N
- gates do ciclo: P1=[veredito], rule-control=[veredito], P2=[veredito]
- validacao: [PASS/FAIL + placar literal]
- reconciliacoes: [nenhuma | lista em 1 linha cada]
- paradas de emergencia: [nenhuma | lista]
```

Este bloco entra no relatorio consolidado da PARADA UNICA.

### Step 4: Proposta de calibracao (somente quando houver sinal)

Se o ledger acumulado mostrar padrao (ex.: mesmo gate furado em 2+ ciclos; gate com muitos
ciclos de precisao total), formular PROPOSTA de calibracao em 1-3 linhas, com as entradas
do ledger como evidencia. **A proposta e apresentada ao Fernando; nada muda sem decisao
dele** (nenhum modelo tem autonomia total; graduacao/restricao e humana).

## Regras duras

- Append-only. Ledger nunca e editado retroativamente.
- Nenhum numero de memoria: so saida literal da sessao.
- Falha registra-se com a mesma proeminencia que sucesso.
- A skill NAO julga o merito dos vereditos; ela os persiste e reconcilia.

## Integracao

**Invocada por**: `hacker-tests` (Fase 8), paradas de emergencia, redteam pipeline,
`hacker-postmortem-to-law`.
**Regra canonica**: `.opencode/rules/hacker-trust-ledger.md` (lei F11).
**Regra anti-invencao**: `.opencode/rules/hacker-epistemic-safety.md` (numeros e vereditos so da
saida literal da sessao; nunca inventar entrada no ledger).
Sempre PT-BR.
