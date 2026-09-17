# SPEC_016: Execucao Mecanica dos Cinco Componentes Graph+Loop

## REQUEST

Completar os cinco componentes auditados da ISSUE-011 com mecanismos executaveis e verificaveis.

## CATEGORY

Feature

## PROBLEM

- A Parte 2 da auditoria nao encontrou script de loop, evaluator ou convergencia.
- A Parte 3 encontrou tabelas Markdown para routing, paralelismo e delegacao, sem executor.
- A Parte 1 observou EXIT_CODE=0 para os dois gates perante a spec ficticia.

## CONTEXT

- Fonte primaria: /home/fernando/Documentos/AUDITORIA-ISSUE-011-2026-09-16.txt.
- Codigo existente: .hacker/scripts/gate-p1.sh, .hacker/scripts/gate-p2.sh e .hacker/scripts/runner.sh.
- Referencia de requisitos: .opencode/issues/ISSUE-011-agentic-graph-loop-anthropic-patterns.md.
- A mudanca nao toca scripts em ~/opsec, Docker Compose, credenciais ou rede.
- Fontes consultadas: .hacker/scripts/gate-p1.sh, .hacker/scripts/gate-p2.sh, .opencode/commands/hacker-sdd-pipeline-auto.md, .opencode/agents/orquestrador.md, https://www.anthropic.com/engineering/building-effective-agents.
- Risco analisado: comandos arbitrarios de job podem fugir do escopo, portanto o executor exige argumento explicito e usa subprocess sem shell.
- RAG externo verificado em 2026-09-17: Anthropic define routing como classificacao seguida de tarefa especializada, parallelization como subtarefas independentes com agregacao programatica, orchestrator-workers como decomposicao dinamica com sintese e evaluator-optimizer como gerador e avaliador trocando feedback em loop: https://www.anthropic.com/engineering/building-effective-agents.
- RAG complementar: o cookbook lista receitas de subagentes, avaliacoes automatizadas e modo JSON: https://github.com/anthropics/anthropic-cookbook/.
- RAG de skills: skills sao diretorios autocontidos com SKILL.md e metadados carregados sob demanda: https://github.com/anthropics/skills.
- RAG de runtime: a documentacao de ferramentas de agentes recomenda separar harness, ferramentas e workers, com limites de ambiente e sintese no coordenador: https://github.com/anthropics/skills/blob/main/skills/claude-api/shared/managed-agents-tools.md.

## REQUIREMENTS

1. Criar CLI Python local que exponha subcomandos route, delegate, parallel e loop.
2. route deve ler CATEGORY e FILES INVOLVED de uma spec e retornar JSON com rota e guardas.
3. delegate deve retornar workers derivados da rota e da complexidade fornecida.
4. parallel deve usar processos filhos, aguardar todos e retornar falha se qualquer job falhar.
5. loop deve executar evaluator, registrar loop-ciclo em arquivo de ledger explicitamente informado e parar em sucesso ou limite sem melhoria.
6. Endurecer P1 e P2 para exigir secoes estruturadas, fonte interna existente e confirmacao explicita para arquivo sensivel.
7. Criar uma suite local que prove os cinco requisitos por exit code e conteudo de saida.
8. Atualizar as instrucoes do pipeline para apontar para o executor, sem afirmar que Markdown executa o mecanismo.
9. A secao WORKERS da entrada deve prevalecer sobre defaults, permitindo decomposicao dinamica e sintese dos resultados executados.

## FILES INVOLVED

- .hacker/scripts/graph-loop.py (create)
- .hacker/scripts/gate-p1.sh (modify)
- .hacker/scripts/gate-p2.sh (modify)
- .hacker/scripts/test-graph-loop.sh (create)
- .opencode/commands/hacker-sdd-pipeline-auto.md (modify)
- .opencode/skills/hacker-tests/SKILL.md (modify)
- .opencode/agents/orquestrador.md (modify)

## RESTRICTIONS

- Sem acao de rede durante testes.
- Sem shell=True no executor Python.
- Jobs executam somente quando informados explicitamente pela linha de comando.
- Nenhuma escrita no Trust Ledger real sem argumento --ledger explicito.
- Git permanece exclusivo do Fernando.

## EXPECTED DELIVERY

- python3 -m py_compile .hacker/scripts/graph-loop.py retorna 0.
- bash -n .hacker/scripts/gate-p1.sh .hacker/scripts/gate-p2.sh .hacker/scripts/test-graph-loop.sh retorna 0.
- bash .hacker/scripts/test-graph-loop.sh retorna 0 e prova os cinco componentes.
- A spec ficticia da auditoria retorna codigo diferente de 0 em P1 e P2.
