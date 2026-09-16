# SPEC_009: Refresh do RAG Fable e fonte de CVSS/CWE (conhecimento envelhece)

> Origem: `.opencode/issues/ISSUE-005-rag-fable-refrash-e-cvs-cwe.md` (aprovada por Fernando para registro como issue, 2026-09-12).
> Base: ISSUE-005 criteria de aceitacao — procedimento de refresh, data de sincronizacao, declaracao de fonte no scan web, aditivo.

## REQUEST

Criar procedimento/check para manter o conhecimento externo do harness atualizado sem violar a regra de espelho: integridade do espelho continua, mas com cadencia de revisao e atualizacao da fonte autoritativa (NVD/CWE, docs das ferramentas). Adicionar declaracao de data e fonte de CVSS/CWE nos relatorios de scan web.

## CATEGORY

Feature (aditivo; nao muda comportamento atual de regras; adiciona procedimento e documentacao).

## PROBLEM

Sintomas observaveis:

- `.opencode/rag/fable/` e espelho 1:1 de `/home/fernando/Downloads/Fable_Knowledge_Harness` (verificado por diff em 2026-09-09, 1596 linhas). O espelho e integro, mas nao possui mecanismo de atualizacao.
- `build-rag.sh` (fonte: `/home/fernando/Downloads/Fable_Knowledge_Harness`) concatena os 15 arquivos fable em `fable-harness-completo.md` (1465 linhas). O script existe, mas nao e executado periodicamente.
- `hacker-web-scan-report.md` (linha 55-59) exige CVSS v3.1 e CWE para cada finding, dizendo "consultar fonte confiavel (NVD) ou classificar conservadoramente", mas nao define cadencia nem como manter a base local atualizada.
- `.hacker/rag/README-RAG.md` (linha 39) lista NVD, OWASP, MITRE ATT&CK como fontes de conhecimento de seguranca, mas nao registra quando foram consultadas pela ultima vez.
- No relatorio de 2026-09-12 (PLAN_003-CORRECAO), CVSS/CWE vieram de metadados dos templates (Nuclei) e da classificacao ZAP, sem conferencia contra NVD.
- Nenhum artefato do repo registra a data da ultima sincronizacao do RAG ou a versao dos dados CVSS/CWE utilizados.

## CONTEXT

- **RAG source**: `/home/fernando/Downloads/Fable_Knowledge_Harness` (fonte original, 1596 linhas, 15 arquivos .md).
- **RAG mirror**: `.opencode/rag/fable/` (espelho 1:1, verificado por diff, 1465 linhas do fable-harness-completo.md).
- **build-rag.sh**: `.opencode/rag/build-rag.sh` — gera `fable-harness-completo.md` via concatenacao dos arquivos fable/.
- **RAG documentation**: `.hacker/rag/README-RAG.md` — hierarquia de fontes (OWASP, NVD, MITRE ATT&CK, etc.), regra F6 para scan web.
- **Web scan rule**: `.opencode/rules/hacker-web-scan-report.md` (linhas 53-71) — exige CVSS v3.1 e CWE; diz consultar NVD; define "unclassified - pending verification" para fontes desconhecidas.
- **Anti-invencao**: `.opencode/rules/hacker-epistemic-safety.md` — regra F6 exige verificar APIs, versoes, paths, numeros antes de citar.
- **Guarda contra alucinacao**: `.opencode/rag/fable/Failure_Modes_and_Prevention/13-guarda-contra-alucinacao.md` — fala sobre citar APIs, flags, paths, versoes, e a importancia do lockfile do projeto como verdade sobre versoes.

**RAG interno (fonte #1):**
- `.opencode/rag/fable/` — 15 arquivos .md, espelho de Fable_Knowledge_Harness
- `.opencode/rag/build-rag.sh` — gera fable-harness-completo.md
- `.opencode/rag/fable-harness-completo.md` — concatenacao dos 15 arquivos (1465 linhas)
- `.opencode/rag/ORQUESTRADOR-FABLE-HACKER.md` — orquestrador de situacoes
- `.opencode/rules/hacker-web-scan-report.md` — regra de scan web (CVSS/CWE/NVD)
- `.hacker/rag/README-RAG.md` — documentacao do RAG (fontes, hierarquia)

**Assumcoes:**
- O espelho Fable (metodo/processo) e estavel — nao precisa de refresh frequente.
- O conhecimento de TECNOLOGIA (CVSS, CWE, NVD, versoes de ferramentas) envelhece e precisa de cadencia de revisao.
- O procedimento e aditivo: nao muda o comportamento atual das regras existentes.
- A atualizacao do RAG e feita manualmente ou via script; nao ha auto-update automatizado.

## REQUIREMENTS

1. **Procedimento documentado de refresh do RAG Fable:**
   - Criar procedimento que descreva como e quando atualizar `.opencode/rag/fable/` a partir de `/home/fernando/Downloads/Fable_Knowledge_Harness`.
   - O procedimento e aditivo: `build-rag.sh` continua existindo e funcionando; o novo procedimento adiciona a cadencia e a verificacao.
   - Documentar no `.hacker/rag/README-RAG.md` (secao nova) ou em arquivo dedicado `.hacker/rag/REFRESH-PROCEDURE.md`.

2. **Cadencia de revisao definida:**
   - Definir cadencia: revisao mensal ou inicio de cada ciclo de pentest.
   - O documento de procedimento registra: data da ultima sincronizacao, fonte utilizada, diff verificado.
   - Se o espelho vier da origem, o diff de integridade (via `diff -r` ou `build-rag.sh`) continua sendo a verificacao.

3. **Registro de data de sincronizacao:**
   - Adicionar campo `DATA-SINCRONIZACAO` no `.hacker/rag/README-RAG.md` ou em `.opencode/rag/REFRESH-PROCEDURE.md`.
   - Formato: ISO 8601 (YYYY-MM-DD).
   - Exemplo: `Ultima sincronizacao: 2026-09-14`.

4. **Declaracao de fonte CVSS/CWE nos relatorios de scan web:**
   - Modificar `.opencode/rules/hacker-web-scan-report.md` para adicionar na secao de findings:
     - `Data da checagem CVSS/CWE: YYYY-MM-DD`
     - `Fonte de CVSS/CWE: NVD | ZAP | Nuclei | unclassified - pending verification`
   - Campos sem fonte ficam "unclassified - pending verification" (comportamento atual preservado).
   - Nao muda o comportamento atual das regras; e aditivo.

5. **Nao muda comportamento atual:**
   - O procedimento e aditivo: nao modifica as regras de scan web existentes.
   - A regra `hacker-web-scan-report.md` continua funcionando como esta.
   - O refresh e documentado como procedimento operacional, nao como mudança de regra.

## FILES INVOLVED

- CREATE: `.hacker/rag/REFRESH-PROCEDURE.md` (novo arquivo com o procedimento de refresh)
- MODIFY: `.hacker/rag/README-RAG.md` (adicionar secao de cadencia e data de sincronizacao)
- MODIFY: `.opencode/rules/hacker-web-scan-report.md` (adicionar declaracao de data e fonte CVSS/CWE)
- `.opencode/rag/build-rag.sh` — NAO MODIFICAR (continua funcionando como esta)
- `.opencode/rag/fable/` — NAO MODIFICAR (continua como espelho 1:1)
- `.opencode/rag/fable-harness-completo.md` — NAO MODIFICAR (gerado por build-rag.sh)

## RESTRICTIONS

- O espelho Fable (1:1 com /home/fernando/Downloads/Fable_Knowledge_Harness) e integridade sao preservados.
- `build-rag.sh` nao e modificado.
- As regras de scan web existentes nao sao quebradas; o procedimento e aditivo.
- Sem IP real de origem em qualquer texto novo (regra 4 do documentation-style).
- Sem traco em dash/en dash em texto novo; usar virgula, dois-pontos, parenteses.
- O arquivo REFRESH-PROCEDURE.md nao contem credenciais, tokens, ou dados pessoais.
- Classe B (markdown + regras), sem gating de rede, sem sudo.

## EXPECTED DELIVERY

- `.hacker/rag/REFRESH-PROCEDURE.md` criado com: procedimento de refresh, cadencia definida, formato de registro de data, comando de verificacao de integridade.
- `.hacker/rag/README-RAG.md` atualizado com: secao de cadencia, data da ultima sincronizacao, referencia ao REFRESH-PROCEDURE.md.
- `.opencode/rules/hacker-web-scan-report.md` atualizado com: campos obrigatorios `Data da checagem CVSS/CWE` e `Fonte de CVSS/CWE` nos relatorios de scan.
- `bash -n .hacker/rag/REFRESH-PROCEDURE.md` (markdown validado).
- `grep -rn "—\|–" .hacker/rag/REFRESH-PROCEDURE.md .hacker/rag/README-RAG.md .opencode/rules/hacker-web-scan-report.md`: zero ocorrencias de traco en/em dash em texto novo.
- `grep -rniE "\b(eu|meu|minha|meus|minhas)\b"`: zero ocorrencias de primeira pessoa.

## VERIFICATION

```bash
# 1. Verificar arquivo criado existe e esta completo:
ls -la .hacker/rag/REFRESH-PROCEDURE.md
wc -l .hacker/rag/REFRESH-PROCEDURE.md

# 2. Verificar README-RAG.md atualizado:
grep -n "SINCRONIZACAO\|REFRESH\|cadencia\|Cadencia" .hacker/rag/README-RAG.md

# 3. Verificar hacker-web-scan-report.md atualizado:
grep -n "Data da checagem\|Fonte de CVSS" .opencode/rules/hacker-web-scan-report.md

# 4. Verificar build-rag.sh NAO modificado:
md5sum .opencode/rag/build-rag.sh
# Deve ser igual ao hash anterior (sem alteracoes)

# 5. Verificar fable/ NAO modificado:
diff -r /home/fernando/Downloads/Fable_Knowledge_Harness .opencode/rag/fable/ && echo "Espelho 1:1 preservado"

# 6. Grep de estilo:
grep -rn "—\|–" .hacker/rag/REFRESH-PROCEDURE.md .hacker/rag/README-RAG.md .opencode/rules/hacker-web-scan-report.md
grep -rniE "\b(eu|meu|minha|meus|minhas)\b" .hacker/rag/REFRESH-PROCEDURE.md .hacker/rag/README-RAG.md .opencode/rules/hacker-web-scan-report.md

# 7. Verificar procedimento de refresh e funcional:
cat .hacker/rag/REFRESH-PROCEDURE.md
# Deve conter: comando de sincronizacao, cadencia, formato de data, verificacao de integridade
```

## ORIGEM E IDEIAS DO FORMATO NOVO

- O espelho Fable e estavel (metodo de raciocinio nao envelhece rapidamente); o conhecimento de tecnologia (CVSS, CWE, NVD, versoes) envelhece.
- O build-rag.sh ja existe e funciona como gerador do fable-harness-completo.md; o novo procedimento complementa com cadencia e registro.
- A regra hacker-web-scan-report.md ja exige CVSS/CWE/NVD; o novo procedimento adiciona a declaracao de data e fonte.
- A integridade do espelho e verificada por `diff -r` (mesmo metodo do build-rag.sh); o novo procedimento registra essa verificacao.
- A atualizacao e aditiva: nao substitui o comportamento atual; adiciona metadados de sincronizacao.
