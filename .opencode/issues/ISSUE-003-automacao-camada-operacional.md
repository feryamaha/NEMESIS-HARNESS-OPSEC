# ISSUE-003: Camada operacional com automação maior (menos markdown como único enforcement)

## Contexto

O `.hacker/` (gate, orquestrador, agentes, memoria, ledger, rag, templates) é
majoritariamente markdown: contratos, templates, formatos, regras de conduta. O
enforcement real de uma operação ainda depende de o agente ler e obedecer os
arquivos.

O problema é estrutural: templates e contratos descrevem o que deveria
acontecer; não há runbook executável (script) que force a sequência Gate ->
Operacao -> Relatorio -> Ledger, nem validação automática de que a operação só
segue após o gate.

## Problema observável

- `operacoes.md` registrou entradas com HASH fabricado (OP-20260911-001/002/003),
  só detectadas por auditoria humana (reprovação do Fernando).
- A suite `validar-scan-web.sh` (que é execução real) foi adicionada depois e
  precisou ser ampliada para 48+ testes; mostra que havia baixa automação antes.
- O orquestrador não possui ferramenta que o obrigue a despachar só com gate
  GOOD; depende de instrução.

## Objetivo

Evoluir a camada operacional para executar de forma verificável e automatizada,
transformando os "deveria" em scripts/checks reutilizáveis que o orquestrador
roda (e que falham o ciclo se o pré-requisito não existe).

## Escopo e fronteira (versus ISSUE-001)

Esta issue cobre o **runner/CLI de fluxo** que orquestra e valida a sequência
Gate→Operacao→Relatorio→Ledger dentro do `.hacker/`. É a camada do orquestrador:
não faz bloqueio físico de ferramenta (isso é da ISSUE-001, camada de
rede/processo). O runner recusa a operação se o gate não foi executado
(recusa a operação, não a ferramenta). Referência cruzada: ISSUE-001 para
o bloqueio mecânico da ferramenta fora do runner.

## Critérios de aceitação

- [ ] Existe um runner/CLI de operação que valida: escopo definido, gate GOOD,
      template de operação preenchido, ledger append-only antes do fechamento.
- [ ] O runner recusa a operação ("ciclo inválido") se o gate não foi executado
      ou não retornou GOOD (recusa a operação; o bloqueio físico da ferramenta
      fica na ISSUE-001).
- [ ] Mínimo: um script único em `.hacker/scripts/` que orquestra o fluxo
      Gate -> Operacao -> Relatorio -> Ledger com exit codes.
- [ ] Não quebra o fluxo atual; é aditivo e documentado.
- [ ] Referencia cruzada para ISSUE-001 (não duplicar o mecanismo de bloqueio).

## Prioridade

Média. Reduz a dependência de obediência e aumenta repetibilidade.

## Origem

Avaliação sênior de cibersegurança (sessão 2026-09-12). Aprovada por Fernando
para registro como issue.