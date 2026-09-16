# SPEC_008: Runner/CLI de automacao da camada operacional (Gate-Operacao-Relatorio-Ledger)

> Origem: `.opencode/issues/ISSUE-003-automacao-camada-operacional.md` (aprovada por Fernando para registro como issue, 2026-09-12).
> Base: ISSUE-001 (enforcement mecanico, SPEC_004/PLAN_004 concluidos) e ISSUE-006 (ledger hash, SPEC_007/PLAN_007 concluidos).

## REQUEST

Evoluer a camada operacional para executar de forma verificavel e automatizada, criando um runner/CLI em `.hacker/scripts/runner.sh` que orquestra o fluxo Gate → Operacao → Relatorio → Ledger com exit codes. O runner verifica pre-condicoes comportamentais antes de registrar operacoes, sem duplicar o enforcement fisico da ISSUE-001.

## CATEGORY

Feature (novo funcionalidade; aditivo, nao substitui fluxo atual).

## PROBLEM

Sintomas observaveis:

- `.hacker/orquestrador/ORQUESTRADOR.md` descreve responsabilidades em markdown (linhas 6-29) mas nao e executavel: o orquestrador nao possui ferramenta que o obrigue a despachar somente apos gate GOOD; depende de instrucao.
- `operacoes.md` registrou entradas com HASH fabricado (OP-20260911-001/002/003), detectadas somente por auditoria humana (reprovação do Fernando).
- `.hacker/scripts/` contem apenas `validar-scan-web.sh` e `PLANO-TESTE-PRATICO.md`; nao existe runner de fluxo geral.
- O gate (GATE-DE-PROTECAO.md) e o ledger (LEDGER-OPERACOES.md) estao em formato markdown; nao ha verificacao automatizada de que o gate foi executado antes de registrar no ledger.

## CONTEXT

- Orquestrador: `.hacker/orquestrador/ORQUESTRADOR.md` (linhas 6-29) | responsabilidades em markdown, nao executavel.
- Gate: `.hacker/gate/GATE-DE-PROTECAO.md` (linhas 1-114) | define o que exige gate e o que nao exige.
- Ledger: `.hacker/ledger/LEDGER-OPERACOES.md` (linhas 1-34) | formato de 10 colunas com REF-AUT, HASH = sha256(payload DATA..BASE, 16 hex).
- Template: `.hacker/templates/TEMPLATE-OPERACAO.md` (linhas 1-25).
- Scripts existentes: `~/opsec/scripts/verificar-vazamento.sh` (gate), `~/opsec/scripts/gate-enforcement.sh` (enforcement), `.hacker/scripts/validar-scan-web.sh`.
- ISSUE-001 (enforcement mecanico): COMPLETADA.
- ISSUE-006 (ledger hash): COMPLETADA.

**RAG interno (fonte #1):**
- `~/opsec/scripts/verificar-vazamento.sh` — linha 120: `echo "[5] RESULTADO FINAL"`; apos esse marcador, a proxima linha contem `[GOOD]` (PASS) ou `[LEAK]` (FAIL). O veredito FINAL esta na linha apres do marcador, nao em nenhuma ocorrencia espalhada.
- `~/opsec/scripts/gate-enforcement.sh` — enforcement de x-bit em binarios de rede.
- `.hacker/gate/GATE-DE-PROTECAO.md` — lista O que EXIGE gate e O que NAO EXIGE gate.
- `.hacker/orquestrador/ORQUESTRADOR.md` — fluxo em grafo: `MISSAO → Planejamento (RAG) → [Gate] → Operacao(N) → Agente relata → Observabilidade → HITL → Ledger → Proxima operacao`.
- `.hacker/ledger/LEDGER-OPERACOES.md` — campos obrigatorios com REF-AUT e HASH canonico.
- `.hacker/ledger/operacoes.md` — 21 linhas, ultima linha contem dados de operacao (linha 21).
- `.hacker/scripts/validar-scan-web.sh` — exemplo de script executavel.

**Assumcoes:**
- O runner nao substitui o enforcement fisico da ISSUE-001; complementa-o.
- O runner funciona como verificador de pre-condicoes e registrador; nao executa operacoes de rede diretamente.
- O runner e aditivo: o fluxo atual continua funcionando; o runner e uma camada adicional de verificacao automatizada.
- O campo ESCOPO nao existe como arquivo de operacao por instancia; a verificacao de escopo deve ler a ultima linha de operacoes.md, nao o template estatico TEMPLATE-OPERACAO.md.

## REQUIREMENTS

1. **Runner/CLI de operacao** (`runner.sh` em `.hacker/scripts/`):
   - Validar: gate GOOD, escopo nao vazio no ledger, hash do ledger consistente.
   - Recusar a operacao ("ciclo invalido") se o gate nao retornou GOOD ou se a integridade do ledger esta comprometida.
   - Um script unico em `.hacker/scripts/` com exit codes (0 = ciclo valido, 1 = ciclo invalido).
   - Comando de gate: `bash ~/opsec/scripts/verificar-vazamento.sh` (conforme GATE-DE-PROTECAO.md linha 9-21).

2. **Etapa 1 | Gate GOOD (detecção precisa):**
   - Executar `bash ~/opsec/scripts/verificar-vazamento.sh 2>&1`.
   - Capturar a saida completa e localizar a linha **após o marcador `[5] RESULTADO FINAL`**.
   - Verificar se essa linha contém `[GOOD]`. Se a linha contiver `[LEAK]` ou nenhuma marcador for encontrado, exit 1.
   - O grep generico `grep -q "GOOD"` NAO deve ser usado; ele casa com qualquer linha que contenha a palavra GOOD, mesmo que o veredito final seja LEAK.
   - Comando de referencia:
     ```bash
     OUTPUT=$(bash ~/opsec/scripts/verificar-vazamento.sh 2>&1 || true)
     FINAL_LINE=$(echo "$OUTPUT" | awk '/\[5\] RESULTADO FINAL/{getline; print; exit}')
     echo "$FINAL_LINE" | grep -q "\[GOOD\]"
     ```

3. **Etapa 2 | Escopo nao vazio (leitura do ledger):**
   - Verificar que `.hacker/ledger/operacoes.md` existe e tem pelo menos 21 linhas.
   - Ler a **ultima linha de dados** (linha 21, a entrada OP-20260913-001).
   - Extrair o campo ESCOPO da ultima linha (separando por `|`).
   - Verificar que o campo ESCOPO nao esta vazio (nao e apenas espacos ou string vazia).
   - NAO verificar o TEMPLATE-OPERACAO.md estatico | o campo ESCOPO la e sempre o nome do campo, nao um valor preenchido.
   - Comando de referencia:
     ```bash
     LAST_LINE=$(tail -1 .hacker/ledger/operacoes.md)
     ESCOPO=$(echo "$LAST_LINE" | cut -d'|' -f5 | xargs)
     [ -n "$ESCOPO" ] && [ "$ESCOPO" != "N/A" ]
     ```

4. **Etapa 3 | Hash do ledger (append-only verificado):**
   - Extrair os campos DATA a BASE da ultima linha de operacoes.md (separando por `|`).
   - Construir o payload canonico: `DATA|OP-ID|AGENTE|ESCOPO|GATE|REF-AUT|VETOR|RESULTADO|BASE`.
   - Calcular `printf '%s' "$PAYLOAD" | sha256sum | cut -c1-16`.
   - Comparar com o HASH gravado na mesma ultima linha (campo 10).
   - Se o hash recalculado nao bater com o HASH gravado, exit 1 (indica que o ledger foi modificado ou a entrada esta corrompida).
   - Comando de referencia:
     ```bash
     LAST_LINE=$(tail -1 .hacker/ledger/operacoes.md)
     DATA=$(echo "$LAST_LINE" | cut -d'|' -f2 | xargs)
     OP_ID=$(echo "$LAST_LINE" | cut -d'|' -f3 | xargs)
     AGENTE=$(echo "$LAST_LINE" | cut -d'|' -f4 | xargs)
     ESCOPO=$(echo "$LAST_LINE" | cut -d'|' -f5 | xargs)
     GATE=$(echo "$LAST_LINE" | cut -d'|' -f6 | xargs)
     REF_AUT=$(echo "$LAST_LINE" | cut -d'|' -f7 | xargs)
     VETOR=$(echo "$LAST_LINE" | cut -d'|' -f8 | xargs)
     RESULTADO=$(echo "$LAST_LINE" | cut -d'|' -f9 | xargs)
     BASE=$(echo "$LAST_LINE" | cut -d'|' -f10 | xargs)
     PAYLOAD="$DATA|$OP_ID|$AGENTE|$ESCOPO|$GATE|$REF_AUT|$VETOR|$RESULTADO|$BASE"
     EXPECTED_HASH=$(echo "$LAST_LINE" | cut -d'|' -f11 | xargs)
     COMPUTED_HASH=$(printf '%s' "$PAYLOAD" | sha256sum | cut -c1-16)
     [ "$COMPUTED_HASH" = "$EXPECTED_HASH" ]
     ```
   Nota: os campos DATA a BASE estao nos campos 2-10 da linha (campo 1 e o separador `|` inicial), e HASH esta no campo 11.

5. **Exit codes e fluxo:**
   - Exit 0: todas as validacoes passaram, ciclo valido.
   - Exit 1: alguma validacao falhou, ciclo invalido (recusar operacao).
   - Nao quebra o fluxo atual; e aditivo e documentado.

6. **Referencia cruzada para ISSUE-001:**
   - O runner nao duplica o mecanismo de bloqueio fisico (SPEC_004, gate-enforcement.sh).
   - O runner valida o gate comportamental (verificar-vazamento.sh GOOD); o enforcement fisico (x-bit) e responsabilidade da ISSUE-001.

7. **Teste comportamental:**
   - O runner deve ser testado com saida FALSA de gate simulando LEAK e GOOD.
   - Mock via variavel de ambiente ou arquivo temporario: criar um script ficticio que imprime `[5] RESULTADO FINAL` seguido de `[LEAK]` ou `[GOOD]`.
   - Confirmar exit 1 quando o gate simula LEAK; confirmar exit 0 quando o gate simula GOOD.
   - Documentar na secao VERIFICATION.

8. **Documentacao:**
   - Documentar no `.hacker/README.md` ou em arquivo dedicado como o runner funciona.
   - Referenciar GATE-DE-PROTECAO.md e ISSUE-001.

## FILES INVOLVED

- `.hacker/scripts/runner.sh` (create: novo script runner/CLI)
- `.hacker/README.md` (modify: adicionar secao sobre o runner)
- `.hacker/gate/GATE-DE-PROTECAO.md` (modify: adicionar referencia ao runner)
- `.opencode/specs/SPEC_008_automacao-camada-operacional.md` (gravar spec)

## RESTRICTIONS

- Append-only: nunca editar/remover/re-hashear entradas existentes no ledger.
- Sem IP real de origem em qualquer texto novo (regra 4 do documentation-style).
- Sem traco em dash/en dash em texto novo; usar virgula, dois-pontos, parenteses e a palavra "a" para intervalos.
- Nenhuma mudanca em scripts da cadeia (`~/opsec/scripts/`), `docker-compose.yml`, ou gate (GATE-DE-PROTECAO.md); mudanca e markdown/script em `.hacker/` (classe B, sem gating de rede).
- Escopo estrito da ISSUE-003: nao alterar ORQUESTRADOR.md, agentes, memoria, templates existentes.
- O runner nao duplica o enforcement fisico da ISSUE-001 (gate-enforcement.sh).
- Stack: bash (scripts), conforme perfil do repo.
- Validacao por atributo: `bash -n .hacker/scripts/runner.sh` (sintaxe bash), `grep -rn "—\|–"` (sem em-dash).

## EXPECTED DELIVERY

- `.hacker/scripts/runner.sh` criado com: deteccao precisa de gate via `[5] RESULTADO FINAL`, verificacao de escopo via ultima linha de operacoes.md, verificacao de hash via sha256 do payload DATA..BASE.
- `.hacker/README.md` atualizado com secao sobre o runner.
- `bash -n .hacker/scripts/runner.sh`: PASS.
- `grep -rn "—\|–" .hacker/scripts/runner.sh .hacker/README.md`: zero ocorrencias de traco en/em dash no texto novo.
- `grep -rniE "\b(eu|meu|minha|meus|minhas)\b" .hacker/scripts/runner.sh .hacker/README.md`: zero ocorrencias de primeira pessoa do singular no texto novo.
- Teste comportamental: runner retorna exit 1 com gate LEAK simulado, exit 0 com gate GOOD simulado.
- Nenhuma entrada antiga do ledger modificada: `operacoes.md` mantem linhas 1 a 21 identicas.
- Referencia cruzada para ISSUE-001 presente no script e na documentacao.

## VERIFICATION

```bash
# 1. Sintaxe bash:
bash -n .hacker/scripts/runner.sh && echo "PASS: sintaxe OK"

# 2. Deteccao precisa de gate (teste LEAK simulado):
cat > /tmp/mock-verificar-leak.sh << 'MOCK'
#!/bin/bash
echo "[5] RESULTADO FINAL"
echo "[LEAK] Cadeia nao ativa"
MOCK
chmod +x /tmp/mock-verificar-leak.sh
# Substituir o path do gate no runner para apontar para o mock:
GATE_SCRIPT=/tmp/mock-verificar-leak.sh bash .hacker/scripts/runner.sh; echo "exit: $?"
# Deve ser exit 1 (ciclo invalido, gate LEAK)

# 3. Deteccao precisa de gate (teste GOOD simulado):
cat > /tmp/mock-verificar-good.sh << 'MOCK'
#!/bin/bash
echo "[5] RESULTADO FINAL"
echo "[GOOD] Cadeia ativa"
MOCK
chmod +x /tmp/mock-verificar-good.sh
GATE_SCRIPT=/tmp/mock-verificar-good.sh bash .hacker/scripts/runner.sh; echo "exit: $?"
# Deve ser exit 0 (ciclo valido, gate GOOD)

# 4. Extrair payload da entrada nova do ledger (linha 21).e reconferir HASH (SUNSET F7):
printf '%s' "2026-09-13|OP-20260913-001|orquestrador|dev|N/A|N/A|Adocao do novo formato de ledger com hash da transacao e autorizacao verificavel|Novo formato implementado e validado|PLAN_007_ledger-hash-transacao-e-autorizacao.md" | sha256sum | cut -c1-16
# Deve ser: 73e8cf1650cea82f

# 5. Conferir append-only preservado:
grep -n "OP-20260911-008" .hacker/ledger/operacoes.md  # linha 20 intacta

# 6. Grep de estilo no texto novo (traco en/em dash e primeira pessoa):
grep -rn "—\|–" .hacker/scripts/runner.sh .hacker/README.md
grep -rniE "\b(eu|meu|minha|meus|minhas)\b" .hacker/scripts/runner.sh .hacker/README.md

# 7. Referencia cruzada ISSUE-001:
grep -n "ISSUE-001\|SPEC_004\|gate-enforcement" .hacker/scripts/runner.sh .hacker/README.md
```

## ORIGEM E IDEIAS DO FORMATO NOVO

- O orquestrador atual (ORQUESTRADOR.md linhas 6-29) define responsabilidades em markdown, mas nao e executavel: o enforcement depende do agente ler e obedecer.
- A ISSUE-001 (SPEC_004) ja fornece o enforcement fisico (x-bit via gate-enforcement.sh); o runner complementa com validacao comportamental (gate GOOD).
- A ISSUE-006 (SPEC_007) ja estabeleceu o formato canonico do ledger; o runner utiliza esse formato para validar o append-only via recomputacao de hash.
- Acordo do formato de validacao: o runner e um script bash que verifica pre-condicoes e registrador do ciclo; nao executa operacoes de rede diretamente.
- Rastreabilidade: cada ciclo do runner e registrado no ledger com REF-AUT e HASH, conforme o formato canonico da ISSUE-006.
- A verificacao de escopo le a ultima linha do ledger (onde o operacao foi registrada), nao o template estatico que apenas define nomes de campos.
