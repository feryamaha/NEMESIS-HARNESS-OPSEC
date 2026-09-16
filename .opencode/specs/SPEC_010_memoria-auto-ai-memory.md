# SPEC_010: Memoria auto (ai-memory) para o Harness Hacker

> Origem: `.opencode/issues/ISSUE-007-memoria-ledger-ai-memory.md` (aprovada por Fernando para registro como issue, 2026-09-12. Status: ADIADA ate ISSUE-001/002/006/003 implementadas, todos concluidos).
> Base: ISSUE-007 analise detalhada (pros, contra, pontos de atencao, decisoes necessarias).

## REQUEST

Implementar a camada de memoria de longo prazo / handoff para o harness hacker. A questão é adotar `akitaonrails/ai-memory` como sistema de memoria agregado ao projeto, ou alternativamente, estender o sistema de memoria existente (3 camadas em `.hacker/memoria/MEMORIA.md`) com capacidades de handoff entre sessões.

## CATEGORY

Feature (nova funcionalidade; aditivo ao sistema de memoria existente; nao substitui ledgers existentes).

## PROBLEM

Sintomas observaveis:

- O harness possui memoria em 3 camadas (conhecimento/grafo, sessao, integridade/Memory Guard) mas nao possui mecanismo de **handoff entre sessões/IDEs**. Quando uma sessão termina, o "onde paramos" não persiste para a próxima sessão em outra IDE.
- A questão levantada (ISSUE-007) avalia `akitaonrails/ai-memory` como solução potencial: wiki markdown, MCP loopback, zero-LLM default, sanitização com `[capture] ignore_paths`.
- O status ADIADA (2026-09-12) condicionava a implementação à conclusão de ISSUE-001, ISSUE-002, ISSUE-006 e ISSUE-003, **todas concluídas**.
- O projeto já tem infraestrutura de LLM local (Ollama no opencode.json) e MCP providers configurados.

## CONTEXT

- **Memoria existente**: `.hacker/memoria/MEMORIA.md`, 3 camadas: (1) Conhecimento/grafo, (2) Sessao (`.hacker/memoria/sessoes/SESSAO_2026-09-11_01.md`), (3) Integridade (OWASP Memory Guard: SHA-256, scan de PII, rollback).
- **Ledgers existentes**: `.hacker/ledger/operacoes.md` + `LEDGER-OPERACOES.md` (append-only, SHA-256) e `.opencode/ledger/trust-ledger.md` (vereditos de gate, F11).
- **Infraestrutura LLM**: `~/.config/opencode/opencode.json`, Ollama (localhost:11434), OpenRouter, múltiplos modelos locais. MCP providers ja configurados.
- **Docker**: `~/opsec/docker-compose.yml`, serviço gluetun ativo. Pode adicionar container ai-memory.
- **ISSUE-007 source**: Leitura completa do arquivo `.opencode/issues/ISSUE-007-memoria-ledger-ai-memory.md`.
- **RAG interno (fonte #1)**:
  - `.hacker/memoria/MEMORIA.md`, arquitetura de memoria 3 camadas
  - `.hacker/ledger/LEDGER-OPERACOES.md`, formato do ledger
  - `.opencode/rules/hacker-opsec-canon.md`, canon por modulo
  - `~/.config/opencode/opencode.json`, MCP/Ollama config
  - `~/opsec/docker-compose.yml`, docker-compose atual
  - `.hacker/gate/GATE-DE-PROTECAO.md`, gate definitions
  - `.hacker/orquestrador/ORQUESTRADOR.md`, fluxo de orquestrador

**Fonte externa (ISSUE-007 já documentou):**
- `akitaonrails/ai-memory` README (25/09): memória longa para agentes, wiki markdown, MCP loopback 127.0.0.1:49374, zero-LLM default, SQLite derivado com FTS5.
- `docs/security.md`: loopback-only default sem auth é seguro para laptop single-user; auth bearer/LAN, CSP, host allowlisting, rate-limit, TLS via proxy para non-loopback.
- `docs/usage.md`: handoffs cruzados, captura sanitizada com `[capture] ignore_paths`, migração exige cura de dados antigos, regras duradouras em AGENTS.md/CLAUDE.md.

**Assumcoes:**
- A decisão de ADOTAR ai-memory é prerrogativa do Fernando. Este spec cobre AMBOS os caminhos: (A) adotar com implementacao completa, (B) nao adotar mas documentar a avaliacao.
- A camada de memoria existente (MEMORIA.md + Memory Guard) NAO sera substituida; ai-memory seria CAMADA ADICIONAL de handoff/recall.
- A regra "rules vs facts" do harness se mantem: ai-memory nao edita AGENTS.md sozinho.
- Se aprovado: instalacao via Docker local, bind loopback 127.0.0.1:49374, zero-LLM inicial.
- A captura de hooks NUNCA grava IP real, credenciais, ou PII; o Memory Guard atual continua valendo.

## REQUIREMENTS

1. **Caminho A (Adotar ai-memory, se Fernando decidir SIM):**
   - Criar container Docker para ai-memory em `~/opsec/docker-compose.yml` (bind loopback 127.0.0.1:49374, sem auth inicial, zero-LLM default).
   - Criar `.ai-memory.toml` no repo raiz com `[capture] ignore_paths` para `.hacker/ledger/**`, `.env`, `opsec/**`, relatorios com dados sensiveis.
   - Configurar MCP integration no opencode (`install-mcp --client opencode`).
   - Garantir que o Memory Guard atual continua operando (scan de PII/IP antes de gravar em qualquer nivel).
   - Registrar decisao no Trust Ledger e no LEDGER.md.

2. **Caminho B (Nao adotar, se Fernando decidir NAO ou AVALIAR DEPOIS):**
   - Documentar a avaliacao completa no `.opencode/specs/SPEC_010` (por que nao adotar ou por que avaliar depois).
   - Manter o sistema de memoria existente (3 camadas) funcionando.
   - Registrar a decisao no Trust Ledger e LEDGER.md.

3. **Regra "rules vs facts":**
   - ai-memory NÃO edita AGENTS.md ou regras do harness sozinho.
   - A emenda das regras (F1..F12) e responsabilidade exclusiva do Fernando.

4. **Seguranca:**
   - Loopback-only (127.0.0.1:49374), sem exposicao na rede.
   - Validar que nenhum processo local nao confiavel lê o data dir.
   - A captura de hooks exclui `.hacker/ledger/`, `.env`, `opsec/**` via `[capture] ignore_paths`.

5. **Migracao (se aplicavel):**
   - Nao importar historico cru.
   - O projeto ja tem arquivos bons para bootstrap (README, AGENTS, specs, plans).

## FILES INVOLVED

- MODIFY: `~/opsec/docker-compose.yml` (adicionar servico ai-memory se CAMINHO A)
- CREATE: `.ai-memory.toml` (configuracao de captura, se CAMINHO A)
- MODIFY: `.opencode/rules/hacker-opsec-canon.md` (adicionar modulo ai-memory ao canon, se CAMINHO A)
- MODIFY: `.opencode/ledger/trust-ledger.md` (registrar decisao, sempre)
- MODIFY: `LEDGER.md` (registrar decisao, sempre)
- CREATE: `.opencode/specs/SPEC_010_memoria-auto-ai-memory.md` (esta spec)
- NÃO MODIFICAR: `.hacker/memoria/MEMORIA.md` (camada existente preservada)
- NÃO MODIFICAR: `.hacker/ledger/operacoes.md` (ledger existente preservado)
- NÃO MODIFICAR: `.opencode/ledger/trust-ledger.md` (formato existente preservado)

## RESTRICTIONS

- A camada de memoria existente (MEMORIA.md, Memory Guard, 3 camadas) NAO e substituida; e complementada.
- Nenhuma modificacao em arquivos de protecao (`~/opsec/scripts/kill-switch.sh`, `verificar-vazamento.sh`, `session-start-hacking-security.sh`, `encerrar-sessao.sh`, `validar-dns-fix.sh`) sem confirmacao do Fernando (classe C).
- Docker-compose.yml e modificacoes que tocam a cadeia de protecao sao classe C.
- Nenhum IP real de origem em qualquer texto novo (regra 4 do documentation-style).
- Sem traco em dash/en dash em texto novo; usar virgula, dois-pontos, parenteses.
- Nenhuma operacao de rede externa, apenas loopback (127.0.0.1:49374).
- Se tocar docker-compose.yml: confirmacao explicita do Fernando obrigatoria.

## EXPECTED DELIVERY

**Caminho A (adoptar):**
- Container ai-memory rodando em Docker (loopback, zero-LLM).
- `.ai-memory.toml` criado com `[capture] ignore_paths` adequado.
- MCP integration configurado no opencode.
- `docker compose config` PASS.
- Memory Guard confirmado operando.
- Trust Ledger e LEDGER.md atualizados com a decisao.

**Caminho B (nao adotar/avaliar depois):**
- Avaliacao completa documentada nesta spec.
- Trust Ledger e LEDGER.md atualizados com a decisao.
- Sistema de memoria existente preservado e funcional.

**Ambos os caminhos:**
- `bash -n` em qualquer script modificado.
- `grep -rn "—\|–"` zero em-dash em texto novo.
- `grep -rniE "\b(eu|meu|minha|meus|minhas)\b"` zero primeira pessoa.
- Nenhuma linha do ledger existente modificada (append-only preservado).

## PRE-FLIGHT

- `bash ~/opsec/scripts/verificar-vazamento.sh`, verificar se a cadeia esta ativa.
- Se o docker-compose.yml for modificado: confirmacao do Fernando obrigatoria (classe C).
- O servico ai-memory e loopback-only; nao requer rede externa.

## VERIFICATION

```bash
# 1. Se CAMINHO A: verificar container rodando:
docker compose -f ~/opsec/docker-compose.yml config
docker compose -f ~/opsec/docker-compose.yml ps

# 2. Se CAMINHO A: verificar ai-memory acessivel:
curl -s http://127.0.0.1:49374/ 2>&1 || echo "Endpoint nao responde (esperado se ainda nao iniciado)"

# 3. Verificar Memory Guard funcionando:
grep -n "Memory Guard\|PII\|SHA-256\|injet" .hacker/memoria/MEMORIA.md

# 4. Verificar docker-compose config:
docker compose -f ~/opsec/docker-compose.yml config

# 5. Verificar .ai-memory.toml existe:
ls -la .ai-memory.toml 2>/dev/null && echo "PASS: existe" || echo "N/A (caminho B)"

# 6. Verificar trust ledger atualizado:
grep -n "ISSUE-007\|ai-memory" .opencode/ledger/trust-ledger.md | tail -5

# 7. Grep de estilo:
grep -rn "—\|–" .opencode/specs/SPEC_010_memoria-auto-ai-memory.md || echo "PASS: zero em-dash"
grep -rniE "\b(eu|meu|minha|meus|minhas)\b" .opencode/specs/SPEC_010_memoria-auto-ai-memory.md || echo "PASS: zero primeira pessoa"

# 8. Verificar ledgers NAO modificados:
tail -1 .hacker/ledger/operacoes.md
tail -1 .opencode/ledger/trust-ledger.md
```

## ORIGEM E IDEIAS DO FORMATO NOVO

- O projeto ja possui memoria em 3 camadas (MEMORIA.md). ISSUE-007 propoe adicionar uma camada de handoff/recall, nao substituir o existente.
- A decisao de adotar ou nao e do Fernando; este spec cobre ambos os caminhos.
- Se adotar: docker-compose.yml + .ai-memory.toml + MCP config sao os artefatos tecnicos.
- Se nao adotar: a avaliacao detalhada no spec serve como documentacao da decisao.
- O Memory Guard atual continua operando como camada de integridade (camada 3 da memoria existente).
- A regra "rules vs facts" do harness se mantem: ai-memory nao edita regras.
- A avaliacao do ISSUE-007 ja cobriu todos os pontos de atencao (PII, ledgers, rules vs facts, seguranca, migracao, auditoria).
