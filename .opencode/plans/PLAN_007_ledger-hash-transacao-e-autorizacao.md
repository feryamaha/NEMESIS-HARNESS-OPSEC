# PLAN_007: Ledger hash transacao e autorizacao

> Autor: sistema OpenCode
> Data: 2026-09-13
> Base: SPEC_007 (existente em .opencode/specs/SPEC_007_ledger-hash-transacao-e-autorizacao.md, REQUIREMENTS linha 72-81)
> Classe: Refatoracao (formato de registro; sem mudanca de comportamento de rede)

## REQUEST

Evoluir o formato do ledger de operacoes e documentos de apoio para:

1. HASH de cada entrada cobrir a transacao (campos DATA a BASE), nao apenas o conteudo do arquivo referenciado na BASE.
2. Campo REF-AUT de autorizacao verificavel inserido nas entradas que tocam rede real.
3. Manter append-only: entradas antigas nao sao editadas nem re-hasheadas.
4. Atualizar documentos de suporte (LEDGER-OPERACOES.md, TEMPLATE-OPERACAO.md) para o novo formato.

## CONTEXT

- Formato atual: `.hacker/ledger/operacoes.md` com 9 colunas (DATA | OPERACAO-ID | AGENTE | ESCOPO | GATE | VETOR | RESULTADO | BASE | HASH).
- HASH atual (OP-20260911-007 e OP-20260911-008) colide: ambos usam `dd8585b689c506cf`, violando lei F12.
- HASH e fragil pois nao vincula a entrada especifica; entradas sem artefato nao tem HASH proprio.
- LEDGER-OPERACOES.md linha 27 documenta HASH como "SHA-256 (primeros 16 chars)" sem definir o que e hasheado.
- TEMPLATE-OPERACAO.md linha 19 tem HASH definido como "SHA-256 do conteudo", mesma ambiguidade.
- operacoes.md termina com newline no final (comportamento correto, corrigido na sessao anterior e formalizado aqui).
- Nenhuma mudanca em scripts da cadeia, compose ou gate; mudanca e somente markdown dentro de .hacker/ e .opencode/.
- REF-AUT em operacoes.md e LEDGER-OPERACOES.md vai entre GATE e VETOR (exatamente como SPEC_007 REQUIREMENTS linha 73 define: "Coluna nova REF-AUT inserida entre GATE e VETOR na tabela do ledger"). Essa eh a mesma ordem do payload canônico do HASH (DATA|OP-ID|AGENTE|ESCOPO|GATE|REF-AUT|VETOR|RESULTADO|BASE).
- REF-AUT em TEMPLATE-OPERACAO.md vai entre VEREDITO-GATE (linha 16) e RESULTADO (linha 17).

## PROBLEM

Sintomas observaveis:

- Operacoes que tocam rede real nao registram autorizacao verificavel (REF-AUT).
- Campo HASH nao e unico por entrada pois nao depende de DATA e OPERACAO-ID so.
- Documentos de apoio nao refletem o novo payload canonico de HASH.
- Formato de HASH ambiguo: "SHA-256 do conteudo" permite reuso/ambiguidade.
- Hashes colidem entre entradas porque o campo nao vincula a entrada especifica.

## REQUERIMENTS

1. **HASH da transacao (entrada canonica):**
   - HASH de toda entrada nova = primeiros 16 hex do sha256 da concatenacao dos valores literais dos campos DATA, OPERACAO-ID, AGENTE, ESCOPO, GATE, REF-AUT, VETOR, RESULTADO e BASE, na ordem, separados por `|`, sem espacos de preenchimento da tabela; o campo HASH fica fora do payload (evita auto-referencia).
   - Comando de referencia para o calculo:
     ```bash
     printf '%s' "DATA|OPERACAO-ID|AGENTE|ESCOPO|GATE|REF-AUT|VETOR|RESULTADO|BASE" | sha256sum | cut -c1-16
     ```
   - Consequencias: hash unico por entrada (depende de DATA e OPERACAO-ID), independe de artefato, cobre comando e resultado registrados (VETOR/RESULTADO/BASE), e vale tambem para operacoes sem artefato.

2. **Campo REF-AUT (autorizacao verificavel):**
   - Posicao no TEMPLATE-OPERACAO.md: inserido entre VEREDITO-GATE (linha 16) e RESULTADO (linha 17).
   - Posicao no LEDGER-OPERACOES.md e operacoes.md: inserido entre GATE (linha 23) e VETOR (linha 24) — exatamente como SPEC_007 REQUIREMENTS linha 73 define ("Coluna nova REF-AUT inserida entre GATE e VETOR na tabela do ledger (10 colunas)"). Essa posicao corresponde a mesma ordem do payload canonico do HASH: DATA|OP-ID|AGENTE|ESCOPO|GATE|REF-AUT|VETOR|RESULTADO|BASE.
   - Obrigatoria para toda operacao que toque rede real (vetor que execute comando da lista "O que EXIGE gate" em GATE-DE-PROTECAO.md, ou qualquer saida da maquina). Sem REF-AUT nesses casos a operacao e INVALIDA (fail-closed), mesmo com GATE GOOD.
   - Formato do valor: `tipo=referencia`, onde `tipo` e um de `contrato`, `issu`/`spec`, `aut-duravel`, seguido de referencia verificavel (path do contrato preenchido, numero da ISSUE/SPEC com escopo, registro de autorizacao no trust ledger) e opcionalmente `; escopo=<alvo>; janela=<inicio a fim>` (intervalo de tempo com a palavra "a" entre os limites, sem traco en dash).
   - Para operacoes que NAO tocam rede (dev/setup), REF-AUT = `N/A`, declarado na entrada.

3. **Append-only inalterado:** entradas existentes (OP-20260911-001 a 009) permanecem inalteradas. Evolucao do formato e registrada como entrada nova de dev. Retratacao continua como entrada nova.

4. **Documentos de suporte atualizados:**
   - `LEDGER-OPERACOES.md`: tabela de campos ganha REF-AUT entre GATE (linha 23) e VETOR (linha 24); descricao e exemplo de HASH atualizados para o novo payload canonico; exemplo de entrada no novo formato.
   - `TEMPLATE-OPERACAO.md`: campo REF-AUT inserido entre VEREDITO-GATE (linha 16) e RESULTADO (linha 17); HASH redefinido (transacao) na linha 19; regra de invalidade sem REF-AUT em operacao de rede.
   - `operacoes.md`: nova coluna REF-AUT entre GATE e VETOR; nova entrada append no final com newline garantido antes de escrever a linha nova.

5. **Entrada de evolucao no ledger:** append de `OP-2026MMDD-001` com ESCOPO dev, sem rede (GATE=N/A, REF-AUT=N/A), descrevendo a adocao do novo formato, com HASH calculado pelo novo padrao (valida de fato o formato apos a mudanca).

6. **Teste SUNSET (F7):** um comando de verificacao determinstico que recompunha o payload da entrada nova, recalcule o sha256 (16 hex) e compare com o HASH gravado; deve falhar sem a entrada nova e passar com ela.

## FILES INVOLVED

- `.hacker/ledger/operacoes.md` (append: entrada nova OP-2026MMDD-001; linhas 1 a 20 intocadas; nova entrada appended apos linha 20 com newline no final do arquivo)
- `.hacker/ledger/LEDGER-OPERACOES.md` (modify: tabela de campos ganha REF-AUT entre GATE (linha 23) e VETOR (linha 24); descricao e exemplo de HASH atualizados)
- `.hacker/templates/TEMPLATE-OPERACAO.md` (modify: campo REF-AUT entre VEREDITO-GATE (linha 16) e RESULTADO (linha 17); HASH redefinido na linha 19; regra de invalidade sem REF-AUT)
- `.opencode/plans/PLAN_007_ledger-hash-transacao-e-autorizacao.md` (novo plano registrando todas as mudancas)

## RESTRICTIONS

- Append-only: nunca editar/remover/re-hashear entradas existentes; correcao = entrada nova.
- Sem IP real de origem em qualquer texto novo (regra 4 do documentation-style; REF-AUT nunca carrega IP real nem credencial, so referencia verificavel).
- Sem traco em dash/en dash em texto novo; usar virgula, dois-pontos, parenteses e a palavra "a" para intervalos.
- Nenhuma mudanca em scripts da cadeia, compose ou gate; mudanca e markdown dentro de .hacker/ (classe B, sem gating de rede).
- Escopo estrito da ISSUE-006: nao alterar ORQUESTRADOR.md, README-RAG.md, gate nem agentes.
- Operacoes.md termina com newline (comportamento correto); garantir newline antes de escrever a nova linha no append.
- Nenhuma edicao em arquivo de producao fora do pipeline (spec -> plano -> revisor independente -> execucao). Correcoes feitas fora do fluxo normal devem ser registradas no trust-ledger.

## TRUST-LEDGER (correcao aplicada fora do fluxo normal)

Entrada pendente de registro no `.opencode/ledger/trust-ledger.md`:
- A correcao do newline final em `operacoes.md` foi aplicada fora do fluxo normal numa sessao anterior (`echo "" >> operacoes.md`), sem dano ao conteudo (apenas um caractere `\n` adicionado). O arquivo agora termina corretamente com newline. Esta correcao esta sendo formalizada aqui no plano. Nenhum conteudo de operacao foi modificado; as linhas 1 a 20 permanecem identicas.

## EXPECTED DELIVERY

- `operacoes.md` com entrada nova no formato de 10 colunas (GATE e REF-AUT presentes entre GATE e VETOR), HASH = sha256(payload DATA..BASE) 16 hex, arquivo terminando com newline.
- `LEDGER-OPERACOES.md` documentando campo REF-AUT entre GATE e VETOR, com descricao e exemplo no novo formato.
- `TEMPLATE-OPERACAO.md` com campo REF-AUT entre VEREDITO-GATE e RESULTADO, HASH redefinido.
- Verificacoes do perfil:
  - Estrutura/diff via leitura literal dos 3 arquivos (repo nao e git; `git diff --check` inaplicavel, conforme pratica corrente do repo).
  - Verificacao deterministica (SUNSET F7): recompilacao do payload da entrada nova via split por `|` + `trim`, `printf '%s' "<payload>" | sha256sum | cut -c1-16` == HASH gravado.
  - grep de estilo no texto novo: `grep -rn "—\|–" <arquivos>`: zero ocorrencias de traco en/em dash no texto novo.
  - `grep -rniE "\b(eu|meu|minha|meus|minhas)\b" <arquivos>`: zero ocorrencias de primeira pessoa do singul no texto novo.
  - Nenhuma entrada antiga modificada: `operacoes.md` mantem linhas 1 a 20 identicas; nova entrada e appended apos linha 20 com newline.

## VERIFICATION

```bash
# 1. bash -n / shellcheck: N/A (somente markdown; nao toca scripts)

# 2. Extrair payload da entrada nova e reconferir HASH (SUNSET F7):
#    (comando determinstico definido no PLAN_007; baseado em split por '|' + sha256sum)

# 3. Conferir append-only preservado: operacoes.md linhas 1 a 20 permanecem inalteradas;
#    nova entrada e appended apos linha 20 com newline no final do arquivo

# 4. Grep de estilo no texto novo (traco en/em dash e primeira pessoa):
#    grep -rn "—\|–" <arquivos>
#    grep -rniE "\b(eu|meu|minha|meus|minhas)\b" <arquivos>
```

## ORIGEM DAS IDEIAS

- Referencia de hash para a entrada canonica: opcao "entrada canonica" da ISSUE-006 (campo `HASH` cobre comando + resultado + operacao porque o payload e o proprio registro).
- Autorizacao verificavel: `TEMPLATE-CONTRATO.md` ja preenche contrato antes de despachar; REF-AUT aponta para esse contrato (path real), para ISSUE/SPEC com escopo, ou para registro de autorizacao duravel no trust ledger (invariante 10 do AGENTS.md).
- Acordo do formato de payload: risco de colisao e nulo porque DATA + OPERACAO-ID sao unicos por append (auto-incremento por dia).
