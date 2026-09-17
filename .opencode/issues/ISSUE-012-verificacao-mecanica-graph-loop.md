# ISSUE-012: Execucao Mecanica dos Cinco Componentes Graph+Loop

## Problema

A auditoria de 2026-09-16 demonstrou que loop, routing, paralelismo e delegacao estavam
documentados, mas nao possuíam executor verificavel por maquina. Os gates existiam como
scripts, mas aceitaram uma spec ficticia composta por marcadores textuais.

## Objetivo

Entregar um executor local e testes automatizados para loop, routing, paralelismo, delegacao
dinamica e gates semanticos, sem iniciar operacao de rede durante a validacao.

## Criterios de aceite

- Router determina rota por CATEGORY e FILES INVOLVED com saida estruturada.
- Planejador determina workers por entrada, inclusive docs, rede e complexidade.
- Executor paralelo inicia jobs independentes, aguarda todos e propaga falha por exit code.
- Loop executa avaliador, limita ciclos sem melhoria e emite evento loop-ciclo.
- Gates P1 e P2 rejeitam a spec ficticia da auditoria e validam campos semanticos minimos.
- Suite local exercita os cinco componentes sem chamada de rede.

## Fonte

- /home/fernando/Documentos/AUDITORIA-ISSUE-011-2026-09-16.txt
- .opencode/issues/ISSUE-011-agentic-graph-loop-anthropic-patterns.md
