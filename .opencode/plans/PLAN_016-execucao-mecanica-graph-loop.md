# Execucao Mecanica dos Cinco Componentes Graph+Loop, Plano de Implementacao

**Objetivo**: tornar os cinco componentes verificaveis por maquina.

**Spec**: `.opencode/specs/SPEC_016-execucao-mecanica-graph-loop.md`

## TASK 1: Criar executor Graph+Loop

**Arquivo**: `.hacker/scripts/graph-loop.py`

**Depende de**: nenhuma

**Verificacao**: `python3 -m py_compile .hacker/scripts/graph-loop.py`

Criar CLI com route, delegate, parallel e loop. O CLI usa subprocess sem shell, JSON em stdout e
codigos de saida para resultados de jobs e evaluator.

## TASK 2: Endurecer gates semanticos

**Arquivos**: `.hacker/scripts/gate-p1.sh`, `.hacker/scripts/gate-p2.sh`

**Depende de**: nenhuma

**Verificacao**: `bash -n .hacker/scripts/gate-p1.sh .hacker/scripts/gate-p2.sh`

Exigir secoes, conteudo nao vazio, fonte interna que exista e confirmacao humana textual para
paths sensiveis.

## TASK 3: Criar suite local

**Arquivo**: `.hacker/scripts/test-graph-loop.sh`

**Depende de**: TASK 1, TASK 2

**Verificacao**: `bash .hacker/scripts/test-graph-loop.sh`

Criar fixtures temporarias e provar router, delegacao, paralelismo, loop e gates por exit code.

## TASK 4: Vincular o executor ao pipeline

**Arquivos**: `.opencode/commands/hacker-sdd-pipeline-auto.md`, `.opencode/skills/hacker-tests/SKILL.md`, `.opencode/agents/orquestrador.md`

**Depende de**: TASK 1

**Verificacao**: `rg -n 'graph-loop.py' .opencode/commands/hacker-sdd-pipeline-auto.md .opencode/skills/hacker-tests/SKILL.md .opencode/agents/orquestrador.md`

Substituir as alegacoes de execucao apenas textual por chamadas e contratos para o CLI.
