# ISSUE-002: Validação externa e independente da cadeia (sair do self-audit)

## Contexto

O `~/opsec/scripts/verificar-vazamento.sh` é a medida de verdade da cadeia de
anonimato. Ele grava atestado, atualiza o ledger e é o gate de tudo. Porém ele é
também o componente que já falhou como sensor:

- 2026-09-08: imprimiu GOOD com IPv6 real vazando (teste 3) e WireGuard
  NAO_CONFIGURADO.
- 2026-09-08: imprimiu "Sessao segura ATIVA" com kill-switch INATIVO (por
  `$HOME` apontando para `/root` sob sudo).
- 2026-09-11: espec (SPEC_003) deixou o gate burlar por falta de cobertura da
  suite e por hash fabricado.

Um verificador único e auto-atestado não é auditável de forma independente. Se o
próprio verificador for corrompido ou tiver bug, nenhuma outra camada detecta.

## Problema observável

- O que "GOOD" significa depende de uma única execução de um único script.
- Não há segundo leitor (ex.: verificação por outro caminho, por hash do
  atestado, por conferência externa do IP de saída) que valide o atestado.

## Objetivo

Introduzir uma segunda leitura independente/verificável do estado da cadeia, de
forma que "GOOD" seja uma afirmação corroborada, não só auto-declarada.

## Critérios de aceitação

Reescritos em termos funcionais do próprio projeto, sem depender de
capacidade comprovada de terceiros (ver Referências inspiracionais no rodapé):

- [ ] Um segundo leitor determinístico, independente de `verificar-vazamento.sh`,
      roda localmente (sem LLM, sem chamada externa obrigatória) após o atestado
      GOOD e confere ao menos uma amostra dos vetores (IP de saída, DNS-ECS,
      IPv6, Tor), emitindo GOOD corroborado ou GAP, com saída literal.
- [ ] O segundo leitor usa caminho próprio de verificação (ex.: `ip -br a` +
      resolução DNS + teste de saída), distinto do código do verificador, para
      que um bug compartilhado não corrompa as duas leituras.
- [ ] O segundo leitor cobre WebRTC/DNS de forma automática, sem abrir navegador
      (fecha o TESTE 4 hoje manual no `verificar-vazamento.sh`).
- [ ] Proteção do dado do operador: o IP real só é usado/endereçado localmente
      no instante da execução da verificação; nenhum valor real sai da máquina,
      não chega a LLM e não é gravado no atestado/ledger além do necessário.
- [ ] A cadeia em si não é alterada (classe C): a verificação é aditiva e
      documentada.
- [ ] Se o segundo leitor divergir do atestado: reconciliação registrada no
      Trust Ledger (entrada nova, append-only, com a saída literal do GAP).

## Absorção do estado-da-arte (pesquisa 2026-09-12)

O problema desta issue (self-audit e falta de segunda leitura) foi cruzado
com o estado-da-arte de agentes de pentest e ferramentas de leak-test,
apenas como pista de direção. A especificação desta issue NÃO depende de
nenhum desses projetos entregar o que o README deles declara; o escopo é
definido em termos dos critérios de aceitação acima (funcionais, do próprio
projeto).

Direções de design derivadas (não vinculadas a capacidade comprovada de
terceiros):
1. Segunda leitura determinística independente do código do verificador
   (caminho de verificação próprio), sem LLM, sem chamada externa obrigatória.
2. WebRTC/DNS como parte da segunda leitura automática (fecha o TESTE 4 manual).
3. Rehidratação do dado real apenas no instante da execução local, nunca em
   logs/ledger/LLM (princípio de privacidade do dado do operador).

## Referências inspiracionais

> Referências inspiracionais: ASCIT31/Dark-Moon (Privacy Gateway), xalgorix/
> xalgorix (verificador independente, offline/air-gap), jason5ng32/MyIP (motor
> de leak local) — capacidade declarada em README, NÃO auditada em código; usar
> apenas como pista de direção, não como especificação.

## Prioridade

Alta. Reforça a confiança no gatilho central.

## Origem

Avaliação sênior de cibersegurança (sessão 2026-09-12). Aprovada por Fernando
para registro como issue.