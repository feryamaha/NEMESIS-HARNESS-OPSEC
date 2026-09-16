# SPEC 001 - Arquitetura do Harness Hacker (destilacao dos 8 repos)

## REQUEST

Projetar a arquitetura do "harness hacker" dentro de `hacker-etico-ambiente`: um conjunto de
agentes especializados (red team, blue team, pentest, scraping) orquestrados por um supervisor,
com um gate de protecao OBRIGATORIO antes de qualquer acao de rede, memoria de sessoes e
conhecimento (RAG), e ledger de operacoes. A arquitetura destila os insights dos 8 repos de
pesquisa ja registrados no LEDGER.md (2026-09-05) conforme o blueprint definido. NAO inclui
implementacao de ferramentas de ataque nem execucao de rede: e artefato de arquitetura
(documentacao + estrutura de diretorios + templates de contrato).

## CATEGORY

Infra | Docs

## PROBLEM

- Atual: o harness SDD de desenvolvimento (.opencode/) existe, mas NAO ha o harness OPERACIONAL de
  hackers: nao ha como orquestrar um exercicio de pentest/scraping/red/blue com gate de protecao
  obrigatorio, memoria persistente, RAG de conhecimento e ledger de operacoes.
- Esperado: arquitetura documentada e estrutura criada em `.hacker/` com contratos de agentes,
  gate de protecao, orquestracao, memoria, RAG e ledger de operacoes.

## CONTEXT

- Fontes consultadas (RAG interno, lei F6):
  - `LEDGER.md` (2026-09-05, linhas 133-147): tabela dos 8 repos + blueprint.
    1. ScreenBog/Agentic-Pentest-AI: LangGraph + RAG (OWASP/MITRE) + Human-in-the-loop + Docker
       sandbox -> base do harness (orquestracao em grafo, RAG de conhecimento de seguranca,
       humano no loop, sandbox fixo).
    2. PurpleAILAB/Decepticon: orquestracao multi-agente (planner/supervisor -> recon ->
       exploit) -> agentes especializados + supervisor.
    3. vxcontrol/pentagi: multi-agente com sandboxing, observabilidade, knowledge graph ->
       observabilidade de operacoes.
    4. cybersharkvin/llmitm_v2: memoria em grafo (Neo4j) como memoria de longo prazo eficiente
       -> memoria de conhecimento acessada por relacionamentos.
    5. GreyDGL/PentestGPT: sessao persistente (memoria de sessao), raciocinio/geracao/parsing
       separados -> memoria de sessao.
    6. GH05TCREW/pentestagent: memoria explicita (/memory), ledger de conversas, modos
       assist/agent/crew -> memoria explicita + ledger de operacoes.
    7. ASCIT31/Dark-Moon: privacy gateway: LLM nunca ve IPs/hosts/creds reais -> gate de protecao
       (o agente nunca recebe o IP real de origem; vê apenas a saida Proton/Tor).
    8. OWASP/www-project-agent-memory-guard: defesa da memoria do agente (SHA-256, rollback,
       scan injecao/PII) -> integridade/seguranca da memoria (hashes, contaminacao).
  - Blueprint (LEDGER linha 145-147): ScreenBog (base+RAG+HITL) + Decepticon (agentes) +
    llmitm_v2 (grafo) + PentestGPT/pentestagent (sessao/ledger) + Dark-Moon (gate opsec) +
    Memory Guard (memoria segura).
  - Canon: `.opencode/rules/hacker-opsec-canon.md` (modulos da cadeia: Proton host, gluetun,
    torproxy, kali-sandbox, kill-switch, DNS fix, IPv6) e `.opencode/rules/hacker-repo-profile.md`
    (validacao por arquivo; pre-flight F1).
  - AGENTS.md invariantes: cadeia antes de agir (rede), git = Fernando, provar nao supor,
    escopo do usuario, uso etico, classe C.

## REQUIREMENTS

1. Criar estrutura `.hacker/` com subpastas: `agentes/`, `gate/`, `orquestrador/`, `memoria/`,
   `ledger/`, `templates/`, `docs/`.
2. Definir o GATE DE PROTECAO (Dark-Moon): regra obrigatoria unitaria de que QUALQUER operacao de
   rede de qualquer agente executa primeiro `bash ~/opsec/scripts/verificar-vazamento.sh`;
   GOOD = libera a operacao; qualquer outro resultado = BLOQUEIA e reporta ao Fernando. O agente
   nunca recebe o IP real de origem: toda referencia a IP em relatorio e IP de saida (Proton/Tor).
3. Definir o ORQUESTRADOR/SUPERVISOR (ScreenBog + Decepticon): recebe missao, valida escopo
   autorizado, consulta RAG, quebra em operacoes, aplica gate antes de cada operacao de rede,
   despacha ao agente certo, roda observabilidade (pentagi), apresenta relatorio consolidado.
4. Definir os AGENTES (Decepticon), cada um com contrato: red-team, blue-team, pentest, scraping.
   Cada contrato inclui: missao, escopo permitido (lab autorizado), pre-requisito de gate, o que
   NAO fazer, formato de relatorio.
5. Definir MEMORIA (llmitm_v2 + PentestGPT + pentestagent): memoria de conhecimento (grafo
   conceitual de questoes), memoria de sessao (resumo por operacao), memoria explicita indexada.
6. Definir LEDGER DE OPERACOES (pentestagent): append-only, uma entrada por operacao: data,
   agente, escopo/lab, gate (GOOD/bloqueado), vetor, resultado, base.
7. Definir RAG DE CONHECIMENTO (ScreenBog): base local de conhecimento de seguranca (OWASP/MITRE
   resumido + questoes do proprio ambiente), consulta obrigatoria antes de planejar (F6).
8. Definir MEMORY GUARD (OWASP): integridade da memoria (hash por entrada, rollback de entrada
   contaminada, scan de injecao/PII ao gravar).
9. Definir templates: OPERACAO.md (missao autorizada), CONTRATO.md (handoff de tarefa para
   agente), RELATORIO.md (saida padrao do agente), GATE-DE-PROTECAO.md (procedimento detalhado).
10. Definir a integracao com o harness SDD: as operacoes de melhoria do proprio harness hacker
    seguem o pipeline SDD (.opencode/); o harness hacker e o "produto" operado pelo Fernando.

## FILES INVOLVED

- `.hacker/README.md` (manifesto do harness hacker: o que e, como usar, mapa)
- `.hacker/gate/GATE-DE-PROTECAO.md` (regra do gate, Dark-Moon)
- `.hacker/orquestrador/ORQUESTRADOR.md` (supervisor, ScreenBog + Decepticon)
- `.hacker/agentes/red-team/AGENTE.md`
- `.hacker/agentes/blue-team/AGENTE.md`
- `.hacker/agentes/pentest/AGENTE.md`
- `.hacker/agentes/scraping/AGENTE.md`
- `.hacker/memoria/MEMORIA.md` (arquitetura de memoria: conhecimento + sessao + explicita)
- `.hacker/ledger/LEDGER-OPERACOES.md` (formato + regra append-only + exemplo)
- `.hacker/ledger/operacoes.md` (arquivo vazio de registro, uma linha de cabecalho)
- `.hacker/rag/README-RAG.md` (base de conhecimento: hierarquia de fontes, consulta obrigatoria)
- `.hacker/templates/TEMPLATE-OPERACAO.md`
- `.hacker/templates/TEMPLATE-CONTRATO.md`
- `.hacker/templates/TEMPLATE-RELATORIO.md`
- `README.md` (raiz, atualizar secao Estrutura com `.hacker/`)
- `LEDGER.md` (registrar a criacao da arquitetura)

## RESTRICTIONS

- Regras 1-6 do perfil (`hacker-repo-profile.md`): nomes, somente o solicitado, citacao literal,
  sem dados reais (IP real/credenciais/PII), sem travesao, sem placeholders.
- Sem NENHUMA acao de rede nesta fase (e artefato de arquitetura). O gate de protecao e DESIGNADO,
  nao executado agora.
- Nao implementar ferramentas de ataque; contratos e arquitetura apenas.
- Nao criar arquivos fora da lista; se precisar, nova spec/issue.
- Arquivos em PT-BR, sem em/en dash, sem primeira pessoa.

## EXPECTED DELIVERY

- Estrutura `.hacker/` criada com todos os arquivos da lista, cada um seguindo o conteudo
  especificado nos REQUIREMENTS, com base nos insights citados dos 8 repos (caixa "destilado de").
- `README.md` atualizado.
- `LEDGER.md` com entrada na secao cronologica.
- Validacoes:
  - `git diff --check`: PASS (sem whitespace)
  - conferencia de que nenhum arquivo contem em dash (en dash: —/–) exceto documentation-style
  - conferencia de que nenhum arquivo cita IP real/credencial

## VERIFICATION

```
$ git diff --check
$ grep -rln '—\|–' .hacker 2>/dev/null; echo "esperado: vazio"
$ grep -rlnE '([0-9]{1,3}\.){3}[0-9]{1,3}' .hacker 2>/dev/null; echo "esperado: vazio"
```