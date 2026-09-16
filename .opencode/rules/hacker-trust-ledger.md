---
trigger: always_on
status: active
scope: canonical
last_updated: 2026-09-09
---

# Hacker Etico: Trust Ledger (vereditos sao artefatos)

> Regra canonica, adaptada do Nemesis (lei F11): veredito de gate e artefato persistente e
> reconciliavel, nao mensagem efemera de conversa. Origem no Nemesis: os gates emitiam vereditos que
> morriam no chat; quando a Skill 4.5 reprovava algo que um gate aprovou, o sinal de calibracao se
> perdia. Aqui o mesmo principio vale, alem de registrar decisoes e mudancas de rumo IMEDIATAMENTE.
> Destinatario: modelos de IA agenticos, nao o humano. Anti-invencao: vereditos e numeros do
> ledger jamais sao inventados, vindo sempre da saida literal (`.opencode/rules/hacker-epistemic-safety.md`).

## O arquivo

- **Path:** `.opencode/ledger/trust-ledger.md` (per-repo; NUNCA espelhado).
- **Rapido para decisoes de sessao:** decisoes e mudancas de rumo importantes tambem entram na
  secao cronologica do `LEDGER.md` da raiz, mas a fonte estruturada dos gates e o Trust Ledger.
- **Append-only:** entradas novas vao ao FIM do arquivo. Nunca editar nem remover entrada existente;
  correcao e uma entrada nova referenciando a anterior.
- **Formato de entrada (uma linha, greppavel):**

```
[data] | ciclo=[SPEC/PLAN/ISSUE ref ou "avulso"] | skill=[emissor] | evento=[tipo] | resultado=[...] | base=[evidencia em 1 linha]
```

## Eventos registrados (tipos)

| evento | emissor | resultado tipico |
|---|---|---|
| `veredito-p1` | hacker-critical-analysis (Ponto 1) | PROSSEGUIR / REJEITAR / AMBIGUA |
| `veredito-p2` | hacker-critical-analysis (Ponto 2) | PROSSEGUIR / REJEITAR / AMBIGUA |
| `veredito-rule-control` | pre-writing-rule-control | PASS / FAIL |
| `validacao` | hacker-tests | PASS / FAIL (com fases) |
| `reconciliacao` | hacker-tests (Fase 4) | gate=[qual] deixou passar [o que] |
| `parada-emergencia` | qualquer skill | motivo em 1 linha |
| `ciclo-redteam` | redteam pipeline da cadeia | 100% protegido / gap / baita / AUTOSSUFICIENTE |
| `postmortem` | hacker-postmortem-to-law | emenda proposta / emenda aplicada / sem emenda |
| `harness` | hacker-harness-sync / gate F10 | INTEGROS / deriva reconciliada |
| `decisao` | qualquer skill | decisao de sessao registrada imediatamente |

## Quando o ledger e escrito

1. **Decisoes e mudancas de rumo: IMEDIATAMENTE** (invariante 11 do AGENTS.md), sem aguardar fim de
   ciclo (entrada `decisao` ou `parada-emergencia`).
2. **Na PARADA UNICA** (fim da doc-sync): a skill `hacker-trust-ledger-update` coleta os vereditos
   do ciclo (anotados por cada gate no proprio veredito) e faz o append de todas as entradas de uma
   vez. Escrita padrao do ciclo.
3. **Em parada de emergencia, fim de ciclo de red team e post-mortem:** imediatamente.

Os numeros e vereditos entram copiados da saida literal da sessao (lei F3/F6), nunca de memoria.

## Para que o ledger serve (e para que NAO serve)

- **Serve** para: reconciliar gate vs desfecho (gate que aprovou o que a validacao reprovou = sinal
  de calibracao); construir o scorecard por skill; fundamentar PROPOSTAS de calibracao.
- **NAO serve** para: graduar autonomia automaticamente. Nenhum modelo tem autonomia total (AGENTS.md
  invariante 8): o ledger fundamenta a proposta; quem gradua ou restringe e o Fernando. Reconciliacao
  e sinal de calibracao, nao culpa.

## Integracao

- Lei: `hacker-fable-method.md` F11. Skill de escrita: `hacker-trust-ledger-update`.
- Os gates anotam os campos da entrada no proprio veredito para a coleta ser copia, nao reconstrucao.
- O relatorio da PARADA UNICA contem a secao Trust Ledger com as entradas do ciclo.