# ISSUE-005: Refresh do RAG Fable e fonte de CVSS/CWE (conhecimento envelhece)

## Contexto

O `.opencode/rag/fable/` é espelho 1:1 do `Fable_Knowledge_Harness`
(verificado por diff em 2026-09-09, 1596 linhas). Espelho é ótimo para método
estável, mas o conhecimento de TECNOLOGIA (versões, APIs, CVSS, CWE mapping,
NVD) envelhece.

No scan web (`hacker-web-scan-report.md`) o agente precisa de CVSS v3.1 e CWE
por finding. A regra prevê fonte confiável (NVD) ou "unclassified - pending
verification". Mas o harness não possui mecanismo de refresh do conhecimento
externo: o espelho só se mantém íntegro, não se atualiza.

## Problema observável

- `.opencode/rag/fable/` é validado por `build-rag.sh`/diff (integridade), mas
  não há job/periódico de atualização da fonte externa.
- No relatório de 2026-09-12, CVSS CWE vieram de metadados dos templates
  (Nuclei) e da classificação ZAP; sem conferência periódica contra NVD.
- Regra `hacker-web-scan-report.md` diz "consultar fonte confiável" mas não
  define cadência nem como manter a base local atualizada.

## Objetivo

Criar procedimento/check para manter o conhecimento externo do harness atualizado
sem violar a regra de espelho: integridade do espelho continua, mas com cadência
de revisão e atualização da fonte autoritativa (NVD/CWE, docs das ferramentas).

## Critérios de aceitação

- [ ] Procedimento documentado de refresh do RAG externo com cadência (ex.:
      revisão mensal/início de ciclo).
- [ ] Se o espelho vier da origem, o diff de integridade continua sendo a
      verificação; o documento registra data da última sincronização.
- [ ] No scan web: o relatório declara a data da checagem CVSS/CWE e a fonte
      (NVD/CWE) usada; campos sem fonte ficam "unclassified".
- [ ] Não muda o comportamento atual de regras; é aditivo.

## Prioridade

Média. Conhecimento desatualizado gera relatório errado com aparência de correto.

## Origem

Avaliação sênior de cibersegurança (sessão 2026-09-12). Aprovada por Fernando
para registro como issue.