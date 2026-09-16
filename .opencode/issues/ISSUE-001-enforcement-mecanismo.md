# ISSUE-001: Enforcement mecânico da cadeia (fail-closed) além de regra comportamental

## Contexto

A cadeia de proteção (WireGuard + Proton + gluetun + Tor + kill-switch + DNS sem
ECS + IPv6 off) é validada por `~/opsec/scripts/verificar-vazamento.sh`. Porém o
enforcement de "não rodar scanner/pentest/scraping sem gate GOOD" hoje é
exclusivamente comportamental: o agente DEVE obedecer as regras do harness
(`AGENTS.md`, `hacker-pentest-harness-execution.md`, `GATE-DE-PROTECAO.md`). Nada
no sistema bloqueia fisicamente um scanner rodando com a cadeia apagada.

## Problema observável

- Os incidentes de 2026-09-08 (gate GOOD com IPv6 real vazando, kill-switch
  inativo por `$HOME` sob sudo, WireGuard NAO_CONFIGURADO) e de 2026-09-11
  (hashes fabricados, placeholder, scan sem gate) mostram que a dependência de
  um agente "bem-comportado" já falhou múltiplas vezes.
- O verificador é self-auditing: ele é a medida da cadeia e ao mesmo tempo o
  objeto que já foi burlado. Validação crítica de anonimato não deveria depender
  de código que se auto-atesta.

## Objetivo

Mover o enforcement de "regra comportamental" para "mecanismo de sistema"
(fail-closed), sem quebrar o fluxo autorizado nem exigir sudo do agente.

## Escopo e fronteira (versus ISSUE-003)

Esta issue cobre o **bloqueio físico na camada de rede/processo**: camera
fail-closed que impede a execução de uma ferramenta de rede com o gate
não-GOOD, independente do orquestrador. Isto é MECANISMO de sistema, fora do
runner de fluxo. O que envolve orquestrar/validar a sequência
Gate→Operacao→Relatorio→Ledger pertence à ISSUE-003 (runner). Não duplicar
aqui a despacho via runner; referência cruzada: ISSUE-003.

## Critérios de aceitação

- [ ] Ferramenta de rede (nmap, masscan, curl, zap, nuclei, sqlmap, scrapy,
      msfconsole, ssh, etc.) bloqueada quando o gate não está GOOD (mecanismo
      de camada de rede/processo; exit/refuse).
- [ ] O bloqueio é por mecanismo (exit/refuse), não por instrução.
- [ ] O agente não precisa de sudo para o fluxo autorizado (gate GOOD volta a
      liberar).
- [ ] Não bloqueia edição de markdown, leitura de código, `bash -n`,
      `docker compose config` (escopo protegido do gate).
- [ ] Mecanismo funciona com o kill-switch como pré-requisito físico (não
      substituível por regra comportamental).
- [ ] Documentar a mudança em `GATE-DE-PROTECAO.md`, no canon e na fronteira
      com a ISSUE-003.

## Ideia de abordagem (decidida 2026-09-12)

Controle de permissão de execução nos próprios binários de rede (chmod):
`session-start-hacking-security.sh` (roda com sudo do Fernando, já faz o GOOD
completo) concede `+x` ao usuário ao final; `encerrar-sessao.sh` remove (`-x`)
ao encerrar. Sem cadeia GOOD ativa, os binários não são executáveis pelo
usuário, por qualquer caminho ou forma de chamada (enforcement do kernel via
execve, não convenção de shell; sem estado "stale"). Especificação em
`.opencode/specs/SPEC_004_enforcement-mecanico-cadeia.md`. Descartadas como
falhas do propósito: wrapper por precedência de PATH (contornável por caminho
absoluto/subprocess) e marcador por timestamp (novo self-audit com prazo de
validade).

## Prioridade

Alta. É o controle que restaria se um agente desobedecer.

## Origem

Avaliação sênior de cibersegurança (sessão 2026-09-12). Aprovada por Fernando
para registro como issue.