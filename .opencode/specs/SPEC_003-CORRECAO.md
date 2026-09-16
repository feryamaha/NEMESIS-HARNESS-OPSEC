# SPEC_003-CORRECAO: Correcao do Ciclo REPROVADO (Scan de Aplicacoes Web)

- data: 2026-09-11
- ciclo: SPEC_003-CORRECAO
- status: PROPOSTA (aguarda aprovacao do Fernando)
- categoria: Docs (artefato de arquitetura de capability, sem implementacao de ferramentas novas)
- **REVISAO**: Esta SPEC e de CORRECAO do ciclo SPEC_003/PLAN_003, REPROVADO por Fernando e registrado em `.opencode/ledger/trust-ledger.md` [2026-09-11] `parada-emergencia`. A auditoria completa (arquivo `AUDITORIA-SPEC003-PLAN003.md` na raiz) confirmou os defeitos com evidencia literal. Esta SPEC cobre exclusivamente a correcao dos defeitos confirmados, sem redesenhar a arquitetura validada.

## REFERENCIA DE REPROVACAO

- Trust Ledger, entrada [2026-09-11] ciclo=PLAN_003 skill=parada-emergencia: REPROVADO pelo Fernando, com base em grep placeholder em `.hacker` (PLANO-TESTE-PRATICO.md:77-78,84), hashes fabricados (operacoes.md:10-12), scan Nuclei generico sem ZAP.
- Post-mortem F12: `.opencode/ledger/trust-ledger.md` [2026-09-11] skill=hacker-postmortem-to-law (leis F12 registradas).
- Retratacao aplicada: `.hacker/ledger/operacoes.md` OP-20260911-004 e OP-20260911-006.

## ESTADO VALIDADO (NAO REABRIR)

A auditoria confirmou ATENDIDO (nao mexer):

| Requisito da SPEC_003 original | Status |
|---|---|
| R1 Regra `hacker-web-scan-report.md` (1.1 a 1.7) | ATENDIDO |
| R2 Agente `web-scanner/AGENTE.md` (2.1 a 2.7) | ATENDIDO |
| R5 Extensao do Template | ATENDIDO |
| R6 Extensao do Orquestrador | ATENDIDO |

## REQUEST

Corrigir os defeitos confirmados do ciclo SPEC_003/PLAN_003, listados abaixo, sem redesenhar a arquitetura. A correcao cobre: (1) hashes fabricados no ledger, (2) entrada de retratacao, (3) tabela markdown quebrada no RAG, (6) suite de verificacao incompleta, (7) definicao de reexecucao do teste pratico, (8) post-mortem F12 (ja aplicado), mais (4) e (5) conforme decisao do Fernando na Parte 3 do prompt de correcao.

## CATEGORY

Infra | Docs | Correcao de ciclo reprovado (`.hacker/` + `.opencode/specs/` + `.opencode/plans/`)

## PROBLEM

- A implementacao de SPEC_003 foi REPROVADA por apresentar: hashes fabricados no ledger de operacoes, arquivos de teste pratico com placeholder e stub conceitual, teste pratico executado apenas com Nuclei (nunca ZAP) e sem evidencia de gate, suite final T12 que nao cobre `.hacker/scripts/`, e tabela markdown invalida no README-RAG.
- O post-mortem F12 (ja registrado) definiu as leis corretivas; esta SPEC formaliza os requisitos de correcao que as implementam.

## CONTEXT

- Decisao do Fernando (Parte 3 do prompt, 2026-09-11):
  - Item 4 (scrapy/playwright/selenium no gate): MANTER como extensao aprovada retroativamente. Registrado em OP-20260911-005.
  - Item 5 (adendo "em host real" no red-team): REVERTER ao texto original. Reversao aplicada e registrada em OP-20260911-005/006.
- Estado real do filesystem verificado por leitura literal em 2026-09-11:
  - Hashes fabricados: `.hacker/ledger/operacoes.md` linhas 10-12 (a3f2b1c9..., b4c3d2e1..., 7c4d5e6f...).
  - Tabela quebrada: `.hacker/rag/README-RAG.md` linhas 35-46 (secao "Regra F6 para scan web" dentro da tabela; linhas 44-46 orfas).
  - Placeholders: `.hacker/scripts/PLANO-TESTE-PRATICO.md` linha 78 `<chave>`, linhas 77 e 84 "exemplo conceitual".
  - Gate: ocorrencia unica de nuclei/httpx (linha 38); scrapy/playwright/selenium na linha 39 (decidido MANTER).
  - Red-team: linha 31 com adendo "em host real" (decidido REVERTER; reversao ja aplicada, sha256=c8cf2fbe1bcb1775).
  - Suite T12: PLAN_003 linhas 319-321, lista fixa sem `.hacker/scripts/`.

## REQUIREMENTS

### RC1: Ledger operacional com hash real (defeito 1)

- Estabelece como REGRA PERMANENTE: todo campo HASH em entrada do `.hacker/ledger/operacoes.md` DEVE ser os primeiros 16 caracteres da saida literal de `sha256sum <artefato>` referenciado no campo BASE.
- Nenhum valor de hash e aceito se nao vier de saida literal de sha256sum do artefato citado (lei F12 registrada no post-mortem).
- Correcao JÁ aplicada e verificada em OP-20260911-004 e OP-20260911-006. Esta spec documenta a regra para os proximos ciclos e para a reexecucao do teste pratico.

### RC2: Retratacao registrada (defeito 2)

- Entrada de retratacao deve existir no ledger de operacoes refenciando as operacoes reprovadas e permanecendo no historico (append-only). Correcao JÁ aplicada em OP-20260911-004. Verificavel por leitura do arquivo.

### RC3: Tabela markdown valida no RAG (defeito 3)

- O arquivo `.hacker/rag/README-RAG.md` deve ter markdown valido: nenhuma celula de tabela fora do bloco da tabela, nenhuma secao inserida no interior de uma tabela.
- A secao "Regra F6 para scan web" deve estar FORA da tabela "Camada | Conteudo" (entre o fim da tabela e a proxima secao).
- Verificacao substantiva: leitura da estrutura + conferencia de que cada linha com pipes pertence a um bloco de tabela com cabecalho valido.
- Corrigir reorganizando as linhas 35-46 sem perder conteudo (as linhas "Conhecimento do ambiente", "Conhecimento de operacoes", "Conhecimento de vetores" devem ficar dentro da tabela "Camada | Conteudo").

### RC4: Gate e red-team conforme decisao do Fernando (defeitos 4 e 5)

- Item 4: MANTER `scrapy, playwright, selenium (scraping web)` no gate como extensao aprovada. Nenhuma mudanca no arquivo. Documentar a decisao no ledger (ja registrado em OP-20260911-005).
- Item 5: Reverter a linha 31 do `.hacker/agentes/red-team/AGENTE.md` ao texto original sem o adendo "em host real". Correcao já aplicada; verificar que o arquivo esta no estado esperado (sha256=c8cf2fbe1bcb1775).

### RC5: Suite de verificacao cobrindo TODOS os arquivos do ciclo (defeito 6)

- A suite de validacao do ciclo de correcao deve cobrir TODOS os arquivos tocados no ciclo inteiro, INCLUINDO `.hacker/scripts/validar-scan-web.sh` e `.hacker/scripts/PLANO-TESTE-PRATICO.md`, sem lista fixa herdada do plano anterior.
- A suite deve incluir varredura anti-placeholder (grep `<chave>`, "exemplo conceitual", "TBD", "TODO") sobre esses arquivos.
- Remover os placeholders/stubs do plano de teste pratico: o comando ZAP deve ter valor real de API key se usada, ou o arquivo deve registrar como a chave sera obtida de forma executavel (ex.: variavel de ambiente), nunca um placeholder literal `<chave>`.
- O arquivo `validar-scan-web.sh` deve ser atualizado para refletir a contagem real de arquivos `.hacker/` e passar sem WARN de contagem (ou documentar explicitamente o motivo se houver).

### RC6: Reexecucao do teste pratico conforme a SPEC (defeito 7)

O teste pratico DEVE ser reexecutado com o metodo da SPEC_003 original, definido nesta spec:

- **Gate antes do scan**: o comando `bash ~/opsec/scripts/verificar-vazamento.sh` deve ser executado antes de QUALQUER scan de rede e a saida literal colada (GOOD obrigatorio). Para alvo em loopback local (localhost:3000 container), o gate ainda assim deve ser executado e documentado, conforme regra 1.2 de `hacker-web-scan-report.md` (nenhuma conexao externa como justificativa para pular o gate sem evidencia).
- **ZAP obrigatorio**: o scan DEVE incluir ZAP (DAST ativo), nao apenas Nuclei. Comando ZAP com valor real executavel (API key de ambiente ou sessao criada), saida exportada em XML convertida para JSON (regra 1.3).
- **Nuclei complementar**: Nuclei pode ser usado como complemento, com templates direcionados ao alvo (nao troca de templates descartaveis).
- **Sem mudanca de metodo sem autorizacao**: nenhuma troca de ferramenta/template/metodo apos inicio do teste pode ocorrer sem nova confirmacao explicita do Fernando (lei F12). Se ZAP nao estiver disponivel no ambiente, PARAR e reportar a Fernando, sem substituir por alternativa.
- **Relatorio**: seguir `TEMPLATE-RELATORIO.md` e a regra `hacker-web-scan-report.md` (secoes 1.4 a 1.7), com findings reais, CVSS/CWE de fonte confiavel (NVD) ou "unclassified - pending verification".
- **Ledger**: entrada nova em `.hacker/ledger/operacoes.md` com hash real de sha256sum, gate colado, resultados resumidos.

### RC7: Post-mortem F12 (defeito 8)

- Já aplicado: entrada `postmortem` no trust-ledger [2026-09-11] com SINDROME, CAUSA verificada e LEI. Verificavel por leitura do arquivo. Nenhuma acao adicional.

## NAO FAÇO

- Nao redesenhar R1, R2, R5, R6 da SPEC_003 (continuam ATENDIDO).
- Nao adicionar nenhum componente operacional em `.opencode/` (camada de desenvolvimento).
- Nao editar entrada existente do ledger (append-only).
- Nao trocar ferramenta/template sem autorizacao.
- Nao implementar ferramentas novas (ZAP: usar o existente ou reportar indisponibilidade).

## RESULTADO ESPERADO

1. README-RAG.md com tabela valida (defeito 3 corrigido).
2. Red-team/AGENTE.md no estado revertido (defeito 5) e documentado.
3. Placeholders removidos de `.hacker/scripts/` (defeito 6).
4. Suite de validacao cobrindo todos os arquivos do ciclo, PASS com saida literal (defeito 6).
5. Teste pratico reexecutado com gate colado + ZAP + Nuclei (defeito 7), ou BLOQUEADO com reporte se ZAP indisponivel.
6. Ledger atualizado com hash real em cada entrada nova (RC1/RC7).

## ACEITACAO

- [ ] `.hacker/rag/README-RAG.md` com markdown valido (nenhuma celula fora de bloco).
- [ ] `.hacker/agentes/red-team/AGENTE.md` revertido ao texto original na linha 31.
- [ ] Nenhum placeholder (`<chave>`, "exemplo conceitual", "TBD", "TODO") em `.hacker/scripts/`.
- [ ] Suite de validacao cobre `.hacker/scripts/` e termina PASS com saida literal colada.
- [ ] Teste pratico reexecutado com saida literal de `verificar-vazamento.sh` antes do scan e com execucao de ZAP registrada; caso ZAP indisponivel, parada registrada e reportada.
- [ ] Toda entrada nova do ledger com hash real de sha256sum.