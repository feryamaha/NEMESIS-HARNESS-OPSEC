# ISSUE-007: Memória auto (ledger/auto-memória) e avaliação do ai-memory

## Contexto

O harness possui memória própria em markdown/ledger:
- `.hacker/ledger/operacoes.md` + `LEDGER-OPERACOES.md` (append-only, SHA-256)
- `.hacker/memoria/MEMORIA.md` (3 camadas: conhecimento/grafo, sessao, integridade
  com Memory Guard)
- `.hacker/memoria/sessoes/*.md`
- `.opencode/ledger/trust-ledger.md` (vereditos de gate)
- `LEDGER.md` (cronologia do ambiente)

A questão levantada fora: adotar `akitaonrails/ai-memory` como sistema de
memória de longo prazo agregado ao projeto.

## Fonte consultada (F6, oficial)

- README do akitaonrails/ai-memory (25/09): memória longa para agentes de código,
  migração entre harnesses (Claude Code, Codex, Cursor, Gemini CLI, OpenCode,
  etc.), hooks de ciclo de vida, wiki markdown como fonte de verdade, SQLite
  derivado com FTS5, zero-LLM por padrão, MCP (loopback 127.0.0.1:49374).
- docs/security.md: loopback-only default sem auth é seguro para laptop single-user;
  auth bearer/LAN, CSP, host allowlisting, rate-limit, TLS via proxy.
- docs/usage.md: handoffs cruzados, captura sanitizada com fronteira de
  privacidade, `[capture] ignore_paths`, migração exige curar dados antigos
  (não importar histórico cru), regras duradouras ficam em AGENTS.md/CLAUDE.md
  (na wiki são sugestão, nunca instrução).

## O que se avalia para o harness hacker

Pontos fortes para DESTE projeto:
- Memória entre sessões/IDEs: o harness usa opencode hoje, mas pode rodar em
  Claude/Cursor/Codex (a doc do projeto prevê múltiplas IDEs). Handoff entre
  agentes resolveria "onde paramos?" entre sessões.
- Wiki markdown = fonte legível/greppável, compatível com o estilo do projeto
  (markdown, ledgers, sem banco proprietário).
- Sanitização tipada + `[capture] ignore_paths` pode excluir `.hacker/ledger/`,
  `.env`, relatórios com dados sensíveis.
- Zero-LLM default: captura/consolidação sem chamada de API (bom para
  privacidade e para ambientes sem chave).
- MCP + loopback + auth: integrável sem expor na rede.

PONTOS DE ATENÇÃO / ONDE O HARNESS PRECISA DECIDIR:
1. **IP real / PII**: a captura de hooks grava prompts e tool calls. Para este
   projeto, `[capture] ignore_paths` deve excluir `~/opsec/.env`, credenciais,
   relatórios com IP de saída, e possivelmente `.hacker/ledger/` e os artefatos
   de scan. O Memory Guard (scan de PII/IP antes de gravar) do harness deve
   continuar valendo. Se o ai-memory sanitariza na fronteira, é complementar,
   não substituto.
2. **Coexistência com ledgers**: o harness tem Trust Ledger (vereditos de gate,
   F11) e ledger de operações. O ai-memory não substitui isso; ele adicionaria
   camada de recall/handoff. Decisão arquitetural: ledgers continuam canônicos;
   ai-memory ingere (não edita) denúncias de sessões.
3. **Regra "rules vs facts"**: o ai-memory explícito NÃO edita AGENTS.md sozinho;
   a regra do harness (leis so emendadas por Fernando) se mantém. Não usar
   ai-memory para "reescrever regras".
4. **Backlog de segurança**: expor o servidor em non-loopback exige bearer + TLS
   via proxy. Para uso single laptop, loopback-only sem auth é aceitável (o
   security.md afirma isso), mas a máquina é Kali com ferramentas de rede; deve-se
   validar que nenhum processo local não confiável lê o data dir.
5. **Migração**: se decidir usar, NÃO importar histórico cru; curar por páginas.
   O projeto já tem arquivos bons para bootstrap (README, AGENTS, specs, plans).
6. **Fila de escrita / auditoria**: ai-memory tem audit log; bom aliado do
   Memory Guard, mas não substitui o Trust Ledger append-only do harness.

## Decisão necessária (Fernando)

- Adotar ai-memory como camada de memória de longo prazo/handoff? Sim / Não /
  Avaliar depois.
- Se sim: instalar via Docker local, bind loopback 127.0.0.1:49374, sem
  provider LLM inicial (zero-LLM) ou com provider local (Ollama) para
  embeddings/summaries?
- Escopo de captura: habilitar hooks no opencode? Em quais projetos/IDEs?

## Próximos passos sugeridos (se adotar)

1. Instalar ai-memory em Docker na máquina (loopback, sem auth inicial).
2. Criar `.ai-memory.toml` no repo raiz com `[capture] ignore_paths` para
   `.hacker/ledger/**`, `.env`, `opsec/**`, relatórios com dados sensíveis.
3. Integrar MCP ao opencode (`install-mcp --client opencode`).
4. Validar sanitização de amostra de sessão antes de adotar em massa.
5. Registrar decisão no Trust Ledger e no LEDGER.md.

## Status (decisão de Fernando, 2026-09-12)

**ADIADA.** Não trabalhar nesta issue até ISSUE-001, ISSUE-002, ISSUE-006 e
ISSUE-003 estarem implementadas e validadas. A decisão de adotar
(ou não) o ai-memory permanece pendente e pode ser reaberta após esse
marco. Prioridade mantida: Média.

## Prioridade

Média. Impacto arquitetural na camada de memória; exige decisão de adoção.

## Origem

Avaliação sênior de cibersegurança (sessão 2026-09-12). Aprovada por Fernando
para registro como issue.