# Procedimento de Refresh do RAG Fable e Fontes CVSS/CWE

## Objetivo

Manter o conhecimento externo do harness atualizado sem violar a regra de espelho.
O espelho Fable em `.opencode/rag/fable/` e as fontes CVSS/CWE (NVD, OWASP, MITRE)
devem ser sincronizados de forma controlada e registrada.

## Escopo

- `.opencode/rag/fable/` (espelho de `/home/fernando/Downloads/Fable_Knowledge_Harness`)
- Fontes de dados CVSS/CWE: NVD, OWASP, MITRE
- Arquivo gerado `fable-harness-completo.md` em `.opencode/rag/`

## Procedimento de Refresh do RAG Fable

### Passo 1: Verificacao de integridade

Executar o comando de comparacao entre a fonte original e o espelho:

```bash
diff -r /home/fernando/Downloads/Fable_Knowledge_Harness .opencode/rag/fable/
```

Se a saida for vazia, o espelho esta sincronizado. Se houver divergencias, prosseguir
para o Passo 2.

### Passo 2: Regeneracao ou copia

Duas opcoes para resolver divergencias:

1. **Regeneracao completa**: executar `bash .opencode/rag/build-rag.sh` para
   regenerar `fable-harness-completo.md` e verificar a integridade do espelho.
2. **Copia seletiva**: copiar os arquivos modificados da fonte para o espelho:
   ```bash
   cp /home/fernando/Downloads/Fable_Knowledge_Harness/*.md .opencode/rag/fable/
   ```
   Apos a copia, executar `bash .opencode/rag/build-rag.sh` para validar.

### Passo 3: Validacao pos-refresh

Após qualquer operacao de refresh, confirmar que:
- `fable-harness-completo.md` foi regenerado
- O espelho `.opencode/rag/fable/` esta 1:1 com a fonte
- Nenhum arquivo de `build-rag.sh` ou `fable/` foi modificado

## Cadencia

- Revisao mensal do espelho Fable
- Revisao no inicio de cada ciclo de pentest
- Sempre apos mudanca em tecnologias externas (OWASP, MITRE, NVD atualizacoes)

## Registro de SINCRONIZACAO

Toda operacao de refresh deve ser registrada com os seguintes campos:

```
## Registro de Sincronizacao
- Ultima sincronizacao: YYYY-MM-DD
- Fonte: /home/fernando/Downloads/Fable_Knowledge_Harness
- Verificacao de integridade: resultado do diff -r (PASS ou DIVERGENTE)
```

### Template completo

```
## Registro de Sincronizacao
- Ultima sincronizacao: YYYY-MM-DD
- Fonte: /home/fernando/Downloads/Fable_Knowledge_Harness
- Verificacao de integridade: PASS (diff -r sem divergencias)
- Operacao realizada: regeneracao / copia seletiva / nenhuma
- Artefatos verificados: fable-harness-completo.md, espelho .opencode/rag/fable/
```

O campo `Ultima sincronizacao` usa formato ISO 8601 (YYYY-MM-DD).

## Anti-invencao para Dados CVSS/CWE

- Nunca fabricar dados CVSS ou CWE. Toda atribuicao de pontuacao CVSS deve ter
  fonte verificavel (NVD, OWASP, MITRE).
- Se nao e possivel atribuir CVSS exato, classificar como:
  `unclassified - pending verification`
- O campo `Fonte de CVSS/CWE` em relatorios deve conter: `NVD`, `ZAP`, `Nuclei`,
  ou `unclassified - pending verification`.
- O procedimento de refresh esta documentado neste arquivo.

## Restricoes

- Nao modificar `build-rag.sh`, `fable/`, ou `fable-harness-completo.md`
- Nao usar IP real, credenciais, ou dados pessoais
- Markdown puro, sem scripts executaveis
- Nenhum dado de CVSS/CWE pode ser inventado
