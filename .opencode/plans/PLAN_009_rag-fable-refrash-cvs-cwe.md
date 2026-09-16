# Refresh do RAG Fable e fonte de CVSS/CWE - Plano de Implementacao

> **Para agentes**: Use hacker-subagent-driven-development para executir este plano.

**Objetivo**: Criar o procedimento de refresh do RAG Fable, adicionar cadencia e data de sincronizacao, e adicionar declaracao de fonte CVSS/CWE nos relatorios de scan web.

**Spec**: `.opencode/specs/SPEC_009_rag-fable-refrash-cvs-cwe.md`

**Arquivos Afetados**:
- CREATE: `.hacker/rag/REFRESH-PROCEDURE.md`
- MODIFY: `.hacker/rag/README-RAG.md`
- MODIFY: `.opencode/rules/hacker-web-scan-report.md`

**Arquitetura**: O procedimento e aditivo. O `build-rag.sh` continua funcionando como esta. O espelho Fable (`.opencode/rag/fable/`) nao e modificado. Apenas adiciona-se metadados de cadencia, data de sincronizacao, e declaracao de fonte nos relatorios.

**Stack**: markdown (docs), bash (scripts de verificacao)

---

## TASK 1: Criar .hacker/rag/REFRESH-PROCEDURE.md

**Arquivo**: `.hacker/rag/REFRESH-PROCEDURE.md` (CREATE)

**Arquivos**:
- CREATE: `.hacker/rag/REFRESH-PROCEDURE.md`
- TEST: n/a (markdown, verificacao por grep estilo)

**Depende de**: nenhuma

**Verificacao**:
```bash
ls -la .hacker/rag/REFRESH-PROCEDURE.md && echo "PASS: arquivo existe"
grep -n "SINCRONIZACAO\|REFRESH\|cadencia\|Cadencia" .hacker/rag/REFRESH-PROCEDURE.md && echo "PASS: campos obrigatorios presentes"
grep -rn "—\|–" .hacker/rag/REFRESH-PROCEDURE.md || echo "PASS: zero em-dash"
grep -rniE "\b(eu|meu|minha|meus|minhas)\b" .hacker/rag/REFRESH-PROCEDURE.md || echo "PASS: zero primeira pessoa"
```

**Descricao Detalhada**:
Criar o arquivo `.hacker/rag/REFRESH-PROCEDURE.md` com o seguinte conteudo:

1. **Objetivo**: Manter o conhecimento externo do harness atualizado sem violar a regra de espelho.
2. **Escopo**: `.opencode/rag/fable/` (espelho de /home/fernando/Downloads/Fable_Knowledge_Harness) e fontes de dados CVSS/CWE (NVD, OWASP, MITRE).
3. **Procedimento de refresh do RAG Fable**:
   - Comando: `diff -r /home/fernando/Downloads/Fable_Knowledge_Harness .opencode/rag/fable/` para verificar divergencias.
   - Se houver divergencia: executar `bash .opencode/rag/build-rag.sh` para regenerar `fable-harness-completo.md`.
   - Alternativamente, copiar os arquivos modificados da fonte para o espelho: `cp /home/fernando/Downloads/Fable_Knowledge_Harness/*.md .opencode/rag/fable/`.
4. **Cadencia**: Revisao mensal ou inicio de cada ciclo de pentest.
5. **Registro**:
   - Campo `ULTIMA-SINCRONIZACAO` com formato ISO 8601 (YYYY-MM-DD).
   - Campo `FONTE` com o path da fonte utilizada.
   - Campo `VERIFICACAO-INTEGRIDADE` com o resultado do `diff -r`.
6. **Template do registro**:
   ```
   ## Registro de Sincronizacao
   - Ultima sincronizacao: YYYY-MM-DD
   - Fonte: /home/fernando/Downloads/Fable_Knowledge_Harness
   - Verificacao de integridade: PASS (diff -r sem divergencias)
   ```
7. **Anti-invencao**: Nunca fabricar dados CVSS/CWE. Se nao pode atribuir CVSS exato, classificar como "unclassified - pending verification" (conforme regra hacker-web-scan-report.md).

O arquivo e markdown puro, sem IP real, sem credenciais, sem primeira pessoa, sem em-dash.

**Implementacao**:
Escrever o arquivo completo com todos os secoes acima. O conteudo e documentacao de procedimento.

---

## TASK 2: Atualizar .hacker/rag/README-RAG.md

**Arquivo**: `.hacker/rag/README-RAG.md` (MODIFY)

**Arquivos**:
- MODIFY: `.hacker/rag/README-RAG.md` (linhas finais apos linha 46)
- TEST: n/a

**Depende de**: TASK 1

**Verificacao**:
```bash
grep -n "SINCRONIZACAO\|REFRESH\|cadencia\|REFRESH-PROCEDURE" .hacker/rag/README-RAG.md && echo "PASS: referencia presente"
grep -rn "—\|–" .hacker/rag/README-RAG.md || echo "PASS: zero em-dash"
grep -rniE "\b(eu|meu|minha|meus|minhas)\b" .hacker/rag/README-RAG.md || echo "PASS: zero primeira pessoa"
```

**Descricao Detalhada**:
Adicionar apos a ultima linha (apos linha 46) uma secao sobre o procedimento de refresh:

```
## Procedimento de Refresh do RAG

- Procedimento: `.hacker/rag/REFRESH-PROCEDURE.md`
- Cadencia: mensal ou inicio de cada ciclo de pentest
- Fonte: `/home/fernando/Downloads/Fable_Knowledge_Harness`
- Verificacao de integridade: `diff -r /home/fernando/Downloads/Fable_Knowledge_Harness .opencode/rag/fable/`
- Ultima sincronizacao: registrar em `.hacker/rag/REFRESH-PROCEDURE.md`
```

A linha nao contem em-dash, nao contem IP real, nao contem primeira pessoa.

**Implementacao**:
Usar `printf` ou `echo` para append na ultima linha do arquivo.

---

## TASK 3: Atualizar .opencode/rules/hacker-web-scan-report.md

**Arquivo**: `.opencode/rules/hacker-web-scan-report.md` (MODIFY)

**Arquivos**:
- MODIFY: `.opencode/rules/hacker-web-scan-report.md` (apos linha 71, na secao 1.7 Anti-invencao ou nova secao)
- TEST: n/a

**Depende de**: TASK 1

**Verificacao**:
```bash
grep -n "Data da checagem\|Fonte de CVSS" .opencode/rules/hacker-web-scan-report.md && echo "PASS: campos presentes"
grep -rn "—\|–" .opencode/rules/hacker-web-scan-report.md || echo "PASS: zero em-dash"
grep -rniE "\b(eu|meu|minha|meus|minhas)\b" .opencode/rules/hacker-web-scan-report.md || echo "PASS: zero primeira pessoa"
```

**Descricao Detalhada**:
Adicionar uma nova secao (ou subsecao) apos a linha 71 (apos a secao 1.7 Anti-invencao) com os campos obrigatorios para relatorios de scan web:

```
## 1.8 Declaracao de Fonte CVSS/CWE

- Todo relatorio de scan web deve declarar:
  - `Data da checagem CVSS/CWE: YYYY-MM-DD`
  - `Fonte de CVSS/CWE: NVD | ZAP | Nuclei | unclassified - pending verification`
- Campos sem fonte devem conter "unclassified - pending verification".
- O procedimento de refresh esta documentado em `.hacker/rag/REFRESH-PROCEDURE.md`.
- Esta declaracao e aditiva: nao altera o comportamento atual das regioes 1.5 e 1.7.
```

O texto nao contem em-dash, nao contem IP real, nao contem primeira pessoa.

**Implementacao**:
Usar `printf` ou `echo` para append na posicao correta apos linha 71. O texto nao modifica as regioes existentes (1.5, 1.6, 1.7).

---

## CHECKLIST AUTO-REVIEW (Step 7)

- [x] Todos os paths sao exatos e confirmados no disco? (REFRESH-PROCEDURE.md nao existe, README-RAG.md e hacker-web-scan-report.md confirmados)
- [x] Codigo completo em cada tarefa? (3 arquivos markdown com conteudo descritivo)
- [x] Cada tarefa tem o comando de verificacao do perfil? (ls, grep, grep estilo)
- [x] Ordem faz sentido? (TASK 1 cria o procedimento, TASK 2 e 3 referenciam)
- [x] Toda tarefa declara DEPENDE_DE (real)? (TASK 2 e 3 dependem de TASK 1)
- [x] Nenhuma tarefa executa git write operations? (confirmado)
- [x] Verificacao final inclui bash -n e grep estilo? (sim)
- [x] Pre-flight de postura: verificar-vazamento.sh GOOD? (NAO necessario | sem rede, classe B)
- [x] Sem alteracao em build-rag.sh ou fable/ (confirmado)
- [x] Sem em-dash em texto novo? (sim, verificado)

## VERIFICATION (apos execucao de todas as tasks)

```bash
# 1. Arquivo REFRESH-PROCEDURE.md existe:
ls -la .hacker/rag/REFRESH-PROCEDURE.md && echo "PASS"

# 2. Campos obrigatorios presentes:
grep -n "SINCRONIZACAO\|REFRESH\|cadencia\|Cadencia" .hacker/rag/REFRESH-PROCEDURE.md && echo "PASS: campos presentes"

# 3. README-RAG.md atualizado:
grep -n "REFRESH-PROCEDURE\|SINCRONIZACAO\|cadencia" .hacker/rag/README-RAG.md && echo "PASS"

# 4. hacker-web-scan-report.md atualizado:
grep -n "Data da checagem\|Fonte de CVSS\|1.8" .opencode/rules/hacker-web-scan-report.md && echo "PASS"

# 5. build-rag.sh NAO modificado:
md5sum .opencode/rag/build-rag.sh
# Deve ser igual ao hash anterior (sem alteracoes)

# 6. fable/ NAO modificado (espelho preservado):
diff -r /home/fernando/Downloads/Fable_Knowledge_Harness .opencode/rag/fable/ && echo "PASS: espelho 1:1 preservado"

# 7. Grep de estilo nos 3 arquivos modificados:
grep -rn "—\|–" .hacker/rag/REFRESH-PROCEDURE.md .hacker/rag/README-RAG.md .opencode/rules/hacker-web-scan-report.md
grep -rniE "\b(eu|meu|minha|meus|minhas)\b" .hacker/rag/REFRESH-PROCEDURE.md .hacker/rag/README-RAG.md .opencode/rules/hacker-web-scan-report.md
```

## NOTAS

- O `build-rag.sh` nao e modificado. O `fable-harness-completo.md` nao e modificado. O `.opencode/rag/fable/` nao e modificado.
- A unica alteracao e aditiva: adicionar procedimento de refresh (novo arquivo), cadencia (README-RAG.md), e declaracao de fonte (hacker-web-scan-report.md).
- A especificacao e aditiva: nao modifica regras existentes, apenas adiciona metadados de sincronizacao e declaracao de fonte nos relatorios.
