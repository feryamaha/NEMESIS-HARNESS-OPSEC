# SPEC_007: Ledger de Operacoes com hash da transacao e autorizacao verificavel

> Origem: `.opencode/issues/ISSUE-006-ledger-hash-transacao-e-autorizacao.md` (aprovada por Fernando, 2026-09-12).

## REQUEST

Evoluir o formato do ledger de operacoes (`.hacker/ledger/operacoes.md`) e seus documentos de
suporte (`LEDGER-OPERACOES.md`, `TEMPLATE-OPERACAO.md`) para:

1. HASH de cada entrada cobrir a TRANSACAO (o registro da operacao: campos DATA a BASE), nao apenas
   o conteudo do arquivo referenciado na BASE.
2. Operacoes que tocam rede real exigirem campo de autorizacao verificavel (REF-AUT), com referencia
   explicita a permissao do Fernando (contrato, escopo, alvo, janela).
3. Manter o append-only: retratacao continua como entrada nova, entradas antigas nao sao editadas.

## CATEGORY

Refactor (formato de registro; sem mudanca de comportamento de rede ou de scripts).

## PROBLEM

Sintomas observaveis:

- `operacoes.md` linha 19 (OP-20260911-007) e linha 20 (OP-20260911-008): o campo HASH da OP-007
  foi preenchido com o mesmo valor da OP-006 (`dd8585b689c506cf`), erro sinalizado pelo post-mortem
  F12 de 2026-09-11. O campo e fragil porque nao vincula a entrada especifica; duas entradas que
  referenciam o mesmo artefato colidem no mesmo HASH, e uma operacao sem artefato (ex.: relato de
  comando que falhou) nao tem HASH proprio da operacao.
- `LEDGER-OPERACOES.md` linha 27: documenta HASH como "SHA-256 (primeros 16 chars)" do conteudo, sem
  definir o que e "o conteudo" a hashear, permitindo reuso/ambiguidade.
- `operacoes.md`: entradas de setup/dev com ESCOPO "N/A" ou "setup" nao registram autorizacao; nao
  ha ler "quem autorizou e para que" alem do gate GOOD.
- `TEMPLATE-OPERACAO.md` linha 19: HASH definido como "SHA-256 do conteudo", mesma ambiguidade; nao
  ha campo de autorizacao.

## CONTEXT

- Ponto de contato principal (F1/F6, lido em 2026-09-13): `.hacker/ledger/operacoes.md` (20 linhas),
  formato tabela markdown de 9 colunas: DATA | OPERACAO-ID | AGENTE | ESCOPO | GATE | VETOR |
  RESULTADO | BASE | HASH. Append-only; HASH real calculado com `sha256sum` (16 hex). Erratas de
  hash gravadas em OP-20260911-004 e OP-20260911-006.
- Formato detalhado: `.hacker/ledger/LEDGER-OPERACOES.md` (33 linhas), campos obrigatorios da linha
  17 a 27; exemplo de entrada nas linhas 31 a 33.
- Template de operacao: `.hacker/templates/TEMPLATE-OPERACAO.md` (24 linhas), campos na linha 8 a 19;
  regra "Se VEREDITO-GATE != GOOD: operacao invalida" na linha 24.
- Template de contrato (controle de autorizacao existente): `.hacker/templates/TEMPLATE-CONTRATO.md`
  (46 linhas): OBJETIVO, ARQUIVOS, INVARIANTES, PRE-FLIGHT REDE; o orquestrador preenche antes de
  despachar ao agente. Servira de referencia verificavel para REF-AUT.
- Regra de gate (o que exige gate): `.hacker/gate/GATE-DE-PROTECAO.md` secoes "O que EXIGE gate"
  (linhas 33 a 44) e "Enforcement fisico (SPEC_004)"; "Edicao de arquivos markdown dentro de `.hacker/`,
  `.opencode/`" declarada na linha 28 como NAO exigindo gate (mudanca desta spec e classe B).
- Fonte normativa do formato atual de HASH: post-mortem F12 de 2026-09-11 (trust ledger) fixou HASH =
  sha256 do artefato referenciado na BASE via `sha256sum` literal. A ISSUE-006 evolui esse formato.
- Assumpcao: entradas antigas (9 colunas) permanecem intocadas (append-only). O novo formato vale
  para entradas novas (10 colunas). A tabela pode coexistir com larguras diferentes.
- Pre-flight: a mudanca nao toca rede; nenhum comando de rede e executado na implementacao.

## REQUIREMENTS

1. **HASH da transacao (entrada canonica):**
   - HASH de toda entrada nova = primeiros 16 hex do sha256 da concatencacao dos valores literais
     dos campos DATA, OPERACAO-ID, AGENTE, ESCOPO, GATE, REF-AUT, VETOR, RESULTADO e BASE, na
     ordem, separados por `|`, sem espacos de preenchimento da tabela; o campo HASH fica fora do
     payload (evita auto-referencia).
   - Comando de referencia para o calculo:
     ```bash
     printf '%s' "DATA|OP-ID|AGENTE|ESCOPO|GATE|REF-AUT|VETOR|RESULTADO|BASE" | sha256sum | cut -c1-16
     ```
   - Consequencias: hash unico por entrada (depende de DATA e OPERACAO-ID), independe de artefato,
     cobre comando e resultado registrados (VETOR/RESULTADO/BASE), e vale tambem para operacoes sem
     artefato.
2. **Campo REF-AUT (autorizacao verificavel):**
   - Coluna nova `REF-AUT` inserida entre GATE e VETOR na tabela do ledger (10 colunas).
   - Obrigatoria para toda operacao que toque rede real (vetor que execute comando da lista "O que
     EXIGE gate" em `GATE-DE-PROTECAO.md`, ou qualquer saida da maquina). Sem REF-AUT nesses casos a
     operacao e INVALIDA (fail-closed), mesmo com GATE GOOD.
   - Formato do valor: `tipo=referencia`, onde `tipo` e um de `contrato`, `issu`/`spec`, `aut-duravel`,
     seguido de referencia verificavel (path do contrato preenchido, numero da ISSUE/SPEC com escopo,
     registro de autorizacao no trust ledger) e opcionalmente `; escopo=<alvo>; janela=<inicio>`
     (intervalo de tempo com a palavra "a" entre os limites, sem traco en dash).
   - Para operacoes que NAO tocam rede (dev/setup), REF-AUT = `N/A`, declarado na entrada.
3. **Append-only inalterado:** entradas existentes nao sao editadas nem re-hasheadas; evolucao do
   formato e registrada como entrada nova de dev. Retratacao continua como entrada nova.
4. **Documentos de suporte atualizados:**
   - `LEDGER-OPERACOES.md`: tabela de campos ganha REF-AUT; descricao e exemplo de HASH atualizados
     para o novo payload canonico; exemplo de entrada no novo formato.
   - `TEMPLATE-OPERACAO.md`: linha REF-AUT na tabela; HASH redefinido (transacao); regra de
     invalidade sem REF-AUT em operacao de rede.
5. **Entrada de evolucao no ledger:** append de `OP-2026MMDD-001` com ESCOPO dev, sem rede
   (GATE=N/A, REF-AUT=N/A), descrevendo a adocao do novo formato, com HASH calculado pelo novo
   padrao (valida de fato o formato apos a mudanca).
6. **Teste SUNSET (F7):** um comando de verificacao determinstico que recompunha o payload da entrada
   nova, recalcule o sha256 (16 hex) e compare com o HASH gravado; deve falhar sem a entrada nova e
   passar com ela.

## FILES INVOLVED

- `.hacker/ledger/operacoes.md` (append: entrada nova OP-2026MMDD-001; entradas existentes intocadas)
- `.hacker/ledger/LEDGER-OPERACOES.md` (modify: tabela de campos, descricao e exemplo de HASH, exemplo com REF-AUT)
- `.hacker/templates/TEMPLATE-OPERACAO.md` (modify: campo REF-AUT, HASH novo, regra de invalidade)

## RESTRICTIONS

- Append-only: nunca editar/remover/re-hashear entradas existentes; correcao = entrada nova.
- Sem IP real de origem em qualquer texto novo (regra 4 do documentation-style; REF-AUT nunca
  carrega IP real nem credencial, so referencia verificavel).
- Sem traco em dash/en dash em texto novo; usar virgula, dois-pontos, parenteses e a palavra "a"
  para intervalos.
- Sem mudanca em scripts da cadeia, compose ou gate; mudanca e markdown dentro de `.hacker/`
  (classe B, sem gating de rede).
- Escopo estrito da ISSUE-006: nao alterar ORQUESTRADOR.md, README-RAG.md, gate nem agentes.

## EXPECTED DELIVERY

- `operacoes.md` com entrada nova no formato de 10 colunas (GATE e REF-AUT presentes), HASH =
  sha256(payload DATA..BASE) 16 hex, conferido por `printf ... | sha256sum | cut -c1-16`.
- `LEDGER-OPERACOES.md` documentando campo REF-AUT e novo HASH, com exemplo no novo formato.
- `TEMPLATE-OPERACAO.md` com campo REF-AUT e regra de operacao invalida sem REF-AUT em rede.
- Verificacoes do perfil:
  - Estrutura/diff via leitura literal dos 3 arquivos (repo nao e git; `git diff --check`
    inaplicavel, conforme pratica corrente do repo).
  - Verificacao deterministica (SUNSET F7): recompilacao do payload da entrada nova via split por
    `|` + `trim`, `printf '%s' "<payload>" | sha256sum | cut -c1-16` == HASH gravado.
  - `grep -rn "—\|–\|eu\|meu"` sobre texto novo: zero ocorrencias de traco en/em dash e de primeira
    pessoa do singular.
  - Nenhuma entrada antiga modificada: `operacoes.md` mantem linhas 1 a 17 e linhas 18 a 20
    identicas (append-only).

## VERIFICATION

```bash
# 1. bash -n / shellcheck: N/A (sem script touchado; ```mudanca e somente markdown)

# 2. Extrair payload da entrada nova e reconferir HASH (SUNSET F7), apos a mudanca:
#    (comando determinstico definido no PLAN_007; baseado em awk split por '|' + sha256sum)

# 3. Conferir append-only preservado: entradas OP-20260911-001 a 009 permanecem com os mesmos
#    campos (somente append da entrada nova)

# 4. Grep de estilo no texto novo (traco en/em dash e primeira pessoa):
#    grep -rn "—\|–" <arquivos>
#    grep -rniE "\b(eu|meu|minha|meus|minhas)\b" <arquivos>
```

## ORIGEM E IDEIAS DO FORMATO NOVO

- Referencia de hash para a entrada canonica: opcao "entrada canonica" da ISSUE-006 (campo
  `HASH` cobre comando + resultado + operacao porque o payload e o proprio registro).
- Autorizacao verificavel: `TEMPLATE-CONTRATO.md` ja preenche contrato antes de despachar; REF-AUT
  aponta para esse contrato (path real), para ISSUE/SPEC com escopo, ou para registro de autorizacao
  duravel no trust ledger (invariante 10 do AGENTS.md).
- Acordo do formato de payload: risco de colisao e nulo porque DATA + OPERACAO-ID sao unicos por
  append (autoincremento por dia).