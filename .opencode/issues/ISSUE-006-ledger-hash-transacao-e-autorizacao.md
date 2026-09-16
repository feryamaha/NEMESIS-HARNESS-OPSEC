# ISSUE-006: Ledger com hash da transação e autorização verificável por operação

## Contexto

O ledger de operações (`.hacker/ledger/operacoes.md`) é append-only com SHA-256
por entrada (primeiros 16 hex). O post-mortem F12 de 2026-09-11 fixou que o HASH
deve ser o sha256 do artefato referenciado na BASE, vindo de `sha256sum` literal.

Dois pontos ainda abertos (identificados na avaliação):

1. O hash é do conteúdo do ARQUIVO (relatório/script), não da TRANSAÇÃO (o
   comando + a saída + a operação). Duas operações apontando para o mesmo
   artefato teriam o mesmo hash, e uma operação sem artefato (ex.: "# comando
   falhou") não tem hash próprio da operação.
2. Algumas entradas usam ESCOPO "N/A" ou "setup" sem registro de autorização
   verificável. Para operações que tocam rede real, falta exigir uma referência
   explícita à autorização do Fernando (contrato, janela, alvo).

## Problema observável

- Entradas OP-20260911-007/008: o hash original foi reutilizado de outra entrada
  (erro) e depois corrigido; mostra fragilidade do campo.
- Várias entradas sem campo de autorização formal; o gate GOOD é registrado,
  mas não há "quem autorizou e para quê".

## Objetivo

Evoluir o formato do ledger:
- hash da operação (payload: comando + resultado, ou entrada canônica), não só do
  artefato;
- campo obrigatório de autorização verificável em operações de rede (referência à
  permissão do Fernando: data, escopo, alvo, janela).

## Critérios de aceitação

- [ ] O hash de cada entrada cobre a transação (comando/saída ou a entrada
      canônica), não apenas o arquivo de saída.
- [ ] Operações de rede real exigem campo de autorização (ex.: REF-AUT) com
      referência verificável; sem isso a operação é inválida.
- [ ] Append-only mantido; retratação continua como entrada nova.
- [ ] Template `TEMPLATE-OPERACAO.md` e `LEDGER-OPERACOES.md` atualizados.

## Prioridade

Média. Reforça auditabilidade legal/técnica do registro.

## Origem

Avaliação sênior de cibersegurança (sessão 2026-09-12). Aprovada por Fernando
para registro como issue.