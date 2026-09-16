# ISSUE-004: Overprocess / custo de governança em operações simples

> **STATUS: INCORPORADA-SEM-CICLO (decisão de Fernando, 2026-09-12).**
> Não vira ciclo próprio nem spec. Reduzida a uma nota curta de política de
> processo no perfil do repo (`.opencode/rules/hacker-repo-profile.md`):
> classe C sempre full-process; mudança de 1 arquivo sem rede/sudo pode
> pular gates redundantes, registrando no ledger mesmo assim.

## Contexto

O pipeline SDD (`.opencode/commands/hacker-sdd-pipeline-auto.md`) tem 12 skills
e múltiplos gates por ciclo (Skill 0 P1/P2, rule-control, PARADA UNICA, etc.).
Para uma mudança de 1 arquivo (ex.: adicionar um vetor no verificar-vazamento,
editar um template) o processo é legítimo, mas custa alto em latência e tokens.

Na operação real de pentest/scraping, o mesmo peso pode travar o uso: o
orquestrador precisa passar por análise crítica, planos, two-stage review etc.
para tarefas de execução curta.

## Problema observável

- 13 skills + 3 pipelines para uma stack tiny (bash/python3/compose).
- Cada ciclo registra todos os gates no Trust Ledger; para tarefa pequena é muito
  overhead relativo.
- O custo é assumido de forma uniforme, sem distinção de risco da mudança.

## Objetivo

Adicionar um modo "operação rápida" (fast path) com menos gates para mudanças de
baixo risco (docs, template, script não-sensível), mantendo o rigor total para
mudanças classe C ou que tocam a cadeia.

## Critérios de aceitação

- [ ] Definição explícita de quando vale o fast path (ex.: 1 arquivo, sem
      .env, sem scripts de proteção, sem compose, sem rede).
- [ ] O fast path tem ao menos uma validação por atributo (bash -n / compose
      config / grep) e registro no ledger.
- [ ] O fast path NUNCA aplica a mudanças de classe C (Parar e confirmar).
- [ ] Documentar no workflow que o fast path é exceção explícita, nunca default
      para cadeia.

## Prioridade

Baixa. Melhoria de eficiência, não de segurança.

## Origem

Avaliação sênior de cibersegurança (sessão 2026-09-12). Aprovada por Fernando
para registro como issue.