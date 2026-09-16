# ISSUE-010: Remoção da Etapa Docker deixou o session-start sem caminho para GOOD

> **STATUS: ABERTA (2026-09-14).**
> Consequência direta da ISSUE-009: a decisão de remover a Etapa Docker (correta
> quanto ao código bugado e não autorizado) não previu que nada mais no pipeline
> sobe os containers gluetun/tor-host, tornando GOOD inalcançável sem passo manual.

## Contexto

A ISSUE-009 determinou remover a Etapa Docker do session-start-hacking-security.sh
por ela ter sido adicionada sem autorização e conter um bug (pass()/info() minúsculo).
A remoção foi aplicada corretamente conforme especificado. Efeito colateral não
identificado antes da decisão: sem essa etapa, nada no pipeline sobe os containers
gluetun/torproxy-host; verificar-vazamento.sh sempre retorna LEAK; o gate nunca
abre.

Fail-closed confirmado: gate-enforcement.sh (ISSUE-001) só libera +x com GOOD,
então não houve exposição de IP em nenhum momento — o efeito foi indisponibilidade
total do fluxo de hacking/pentest/scraping, não vazamento.

## Decisão a tomar (Fernando)

Reimplementar a etapa de orquestração Docker, desta vez pelo pipeline SDD completo
(spec → critical-analysis P1 → rule-control → plano → critical-analysis P2 →
aprovação explícita → execução → hacker-tests → trust-ledger), cobrindo:

1. Subir gluetun e torproxy-host (ou detectar Tor nativo, se essa capacidade for
   mantida) de forma correta, sem o bug de case-sensitivity (usar PASS/FAIL/WARN/
   INFO maiúsculos, consistente com o resto do script).
2. Aguardar os containers ficarem prontos antes de chamar verificar-vazamento.sh,
   com timeout e mensagem de erro clara se não ficarem prontos.
3. teste-session-start.sh (já criado na ISSUE-009) precisa cobrir também este
   cenário: mock de containers não subindo a tempo → resultado LEAK esperado;
   mock de containers OK → caminho para GOOD.
4. Documentar em README.md e ~/opsec/README.md se a subida de containers é
   automática (dentro do session-start) ou manual (pré-requisito antes de rodar
   o session-start) — a ambiguidade atual não pode continuar.
5. Confirmar explicitamente, com evidência, que gate-enforcement.sh continua
   fail-closed durante todo o processo (nenhuma ferramenta de rede liberada
   antes de GOOD real).

## Critérios de aceitação

- [ ] session-start-hacking-security.sh consegue chegar a GOOD de ponta a ponta,
      com containers subindo corretamente dentro do próprio fluxo (ou com
      pré-requisito manual claramente documentado, se essa for a decisão).
- [ ] Nenhuma chamada a pass()/info() minúsculas (mesmo bug da ISSUE-009 não pode
      reaparecer).
- [ ] teste-session-start.sh atualizado cobrindo o caminho de subida de
      containers, mockado, sem sudo/rede real.
- [ ] Confirmação por evidência de que gate-enforcement.sh permanece fail-closed
      durante todo o ciclo.
- [ ] README.md e ~/opsec/README.md atualizados refletindo o fluxo real.
- [ ] Diff completo apresentado antes de qualquer edição em scripts de proteção
      (classe C).

## Prioridade

Alta. Harness está inutilizável para o propósito real (hacking/pentest/scraping
protegido) até isso ser resolvido — mesmo sem risco de exposição.

## Origem

Sessão 4 (2026-09-14), registro-sessão-opencode4.txt. Contradição identificada
pelo próprio Fernando após execução completa do ciclo ISSUE-009.
