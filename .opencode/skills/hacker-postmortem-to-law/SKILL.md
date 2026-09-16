---
name: hacker-postmortem-to-law
description: >
  Composto de processo (lei F12): converte um erro de PROCESSO com custo material em
  post-mortem minimo (sintoma, causa verificada, lei violada ou ausente) e em proposta de
  emenda a regra/skill correspondente, com HARD-GATE humano. Registra no ledger (evento
  postmortem). Referenciar .opencode/rules/hacker-fable-method.md F12.
---

# Hacker Postmortem-to-Law (lei F12)

Transformar falha de processo em lei, com trilho padronizado e decisao humana.

> **Texto unico.** Paths de processo vem do perfil
> (`.opencode/rules/hacker-repo-profile.md`).

**Anuncio de inicio**: "Estou usando a skill hacker-postmortem-to-law para converter uma falha de processo em proposta de emenda."

## Quando invocar

- Erro de processo com custo material: uma lei existente (F1..F12, invariante do AGENTS.md,
  regra de skill/workflow) foi violada, OU uma situacao mostrou que falta uma lei.
- Bypass cuja causa raiz e o PROCESSO/instrucoes (nao o codigo): o post-mortem roteia
  para ca alem da remediacao tecnica.
- NAO invocar para: erro trivial sem custo, falha de produto (essa vai para ISSUE + SDD),
  ou achado especulativo sem incidente concreto.

## Processo

### Step 1: Post-mortem minimo (3 campos, com evidencia)

```
SINTOMA OBSERVADO: [o que aconteceu, com a evidencia literal da sessao (saida, diff, log)]
CAUSA VERIFICADA:  [verificada no artefato, nao inferida; se nao verificavel, declarar]
LEI: [violada: qual lei/invariante/regra, citada por ID] OU [ausente: que lei faltou]
```

Disciplina epistemica integral (regra canonica: `.opencode/rules/hacker-epistemic-safety.md`):
sem causa-raiz por inferencia; hipotese rival considerada; se a evidencia e ambigua, o
post-mortem diz isso. NENHUM sintoma, saida, diff ou log do post-mortem pode ser inventado:
tudo vem da sessao literal.

### Step 2: Proposta de emenda

- **Arquivo alvo:** a regra/skill/workflow onde a lei vive (ou deveria viver). Lei de
  trabalho do modelo → `hacker-fable-method.md`; regra compartilhada → o arquivo
  correspondente; regra de stack → o perfil do repo.
- **Texto proposto:** a emenda exata (diff minimo), incluindo o campo **origem** (o
  incidente que a gerou; leis carregam a propria historia).
- **Racionalizacao prevista:** a desculpa mais provavel que um agente usaria para contornar
  a emenda ("so desta vez", "meu caso e obviamente diferente", "estou confiante") e a
  contra-resposta que o texto da emenda incorpora. Emenda que nao resiste a propria
  racionalizacao volta para reescrita antes do gate.
- **Efeito colateral:** o que a emenda pode restringir de legitimo (analogo ao FP).

### Step 2.5: Teste de pressao da emenda (o RED ja existe; provar o GREEN)

O incidente do post-mortem E o teste RED: a falha observada SEM a emenda. Antes do
HARD-GATE, quando o cenario e reproduzivel a custo baixo (simulacao com subagente que
recebe o mesmo contexto do incidente + a emenda proposta), rodar o cenario e anexar o
desfecho literal a proposta (GREEN comprovado, ou emenda insuficiente - que volta para o
Step 2). Cenario caro ou irreproduzivel: declarar isso explicitamente na proposta; o
Fernando decide com essa informacao.

### Step 3: HARD-GATE humano (inegociavel)

Regras sao autoridade: **so o Fernando emenda lei**. Apresentar post-mortem + proposta e
BLOQUEAR ate decisao explicita. Respostas validas: "sim", "pode", "aprovado", "ok",
"prossiga" (ou a recusa dele, que tambem e desfecho valido e registravel).

### Step 4: Aplicar (somente apos aprovacao)

1. Aplicar a emenda no arquivo alvo.
2. Se o arquivo e compartilhado: verificar se precisa de propagacao e rodar o procedimento
   de espelhamento (`hacker-harness-integrity.md`, lei F10) na mesma sessao.
3. Registrar no Trust Ledger (`hacker-trust-ledger-update`, evento `postmortem`):
   emenda aplicada, ou "sem emenda por decisao do Fernando".

## Formato de saida

```
## Post-mortem -> Lei (F12)

SINTOMA OBSERVADO: [...]
CAUSA VERIFICADA:  [...]
LEI: [violada F#/invariante N | ausente]

### Proposta de emenda
Arquivo alvo: [path]
Texto proposto: [diff minimo, com origem]
Racionalizacao prevista: [desculpa + contra-resposta incorporada]
Teste de pressao: [GREEN comprovado com evidencia | nao rodado: motivo declarado]
Efeito colateral possivel: [...]

HARD-GATE: aguardando decisao do Fernando.
```

## Lembrar

- So processo; falha de produto segue o trilho ISSUE -> SDD -> Parte no pentest.
- Emenda sem HARD-GATE humano = violacao (a autoridade sobre as leis e do Fernando).
- Emenda em arquivo compartilhado exige verificacao de espelhamento + check F10 na mesma sessao.
- Registrar o desfecho no ledger SEMPRE (inclusive "sem emenda").
- Referenciar `.opencode/rules/hacker-fable-method.md` F12.
- Sempre PT-BR.

## Integracao

**Invocada por**: qualquer skill que detecte violacao de lei com custo material,
ou o Fernando diretamente.
**Skills relacionadas**: `hacker-trust-ledger-update` (registro), `hacker-harness-sync`
(propagacao de emenda).
