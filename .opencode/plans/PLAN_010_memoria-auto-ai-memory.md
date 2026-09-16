# Memoria auto (ai-memory) para o Harness Hacker - Plano de Implementacao

> **Para agentes**: Use hacker-subagent-driven-development para executir este plano.

**Objetivo**: Implementar a camada de memoria de longo prazo / handoff para o harness hacker, cobrindo AMBOS os caminhos: (A) adotar ai-memory, (B) nao adotar mas documentar a avaliacao.

**Spec**: `.opencode/specs/SPEC_010_memoria-auto-ai-memory.md`

**Arquivos Afetados**:
- MODIFY: `~/opsec/docker-compose.yml` (adicionar servico ai-memory, CAMINHO A)
- CREATE: `.ai-memory.toml` (configuracao de captura, CAMINHO A)
- MODIFY: `.opencode/rules/hacker-opsec-canon.md` (adicionar modulo ai-memory, CAMINHO A)
- MODIFY: `.opencode/ledger/trust-ledger.md` (registrar decisao)
- MODIFY: `LEDGER.md` (registrar decisao)
- CREATE: `.opencode/specs/SPEC_010_memoria-auto-ai-memory.md` (esta spec)

**Arquitetura**: O plano cobre dois caminhos condicionais. O CAMINHO A (adoptar) requer confirmacao do Fernando (classe C). O CAMINHO B (nao adotar) e apenas documentacao. O sistema de memoria existente (MEMORIA.md, Memory Guard) e preservado.

**Stack**: bash, Docker/Compose, markdown (docs)

---

## TASK 1: Registrar decisao no Trust Ledger e LEDGER.md

**Arquivos**: MODIFY `.opencode/ledger/trust-ledger.md`, MODIFY `LEDGER.md`

**Depende de**: nenhuma

**Verificacao**:
```bash
grep -n "ISSUE-007\|ai-memory" .opencode/ledger/trust-ledger.md && echo "PASS: entrada do trust ledger presente"
grep -n "ISSUE-007\|ai-memory" LEDGER.md && echo "PASS: entrada do LEDGER.md presente"
```

**Descricao Detalhada**:
Registrar a decisao do ciclo no Trust Ledger e no LEDGER.md. A decisao e: "SPEC_010 gerada com dois caminhos (A: adotar ai-memory, B: nao adotar). Aguardando confirmacao do Fernando para CAMINHO A (classe C, docker-compose.yml)."

Adicionar entrada no trust-ledger (evento `decisao`):
- resultado: SPEC_010 gerada; aguardando decisao Fernando para CAMINHO A
- base: P1 PROSSEGUIR, rule-control PASS com ALERTA na REGRA 3 (docker-compose.yml classe C)

Adicionar entrada no LEDGER.md (secao cronologica):
- formato: [data] | ciclo=PLAN_010 | skill=hacker-specification-design | evento=decisao | resultado=... | base=...

**Implementacao**:
Append-only. Nunca editar entradas existentes. Usar `echo` para append no final dos arquivos.

---

## TASK 2: CAMINHO A, Implementar ai-memory (CONDICIONAL, requer confirmacao do Fernando)

**Arquivos**: MODIFY `~/opsec/docker-compose.yml`, CREATE `.ai-memory.toml`, MODIFY `.opencode/rules/hacker-opsec-canon.md`

**Depende de**: TASK 1 + confirmacao explicita do Fernando para modificar docker-compose.yml (classe C)

**Verificacao**:
```bash
docker compose -f ~/opsec/docker-compose.yml config && echo "PASS: docker-compose config valido"
ls -la .ai-memory.toml && echo "PASS: .ai-memory.toml existe"
grep -n "ai-memory\|akitaonrails" .opencode/rules/hacker-opsec-canon.md && echo "PASS: modulo ai-memory no canon"
```

**Descricao Detalhada**:
**ATENCAO: Este task e classe C (modifica docker-compose.yml). NAO EXECUTAR sem confirmacao explicita do Fernando.**

Se o Fernando decidir ADOTAR ai-memory:

2a. Adicionar servico ai-memory ao docker-compose.yml:
- Container: `akitaonrails/ai-memory` (ou imagem equivalente)
- Ports: `127.0.0.1:49374:49374` (bind loopback ONLY)
- Ambiente: `AI_MEMORY_LLM_PROVIDER=none` (zero-LLM default)
- Volumes: data dir montado como volume persistente
- Network: apenas loopback, sem exposicao externa

2b. Criar `.ai-memory.toml` no repo raiz:
```toml
[capture]
ignore_paths = [".hacker/ledger/**", ".env", "opsec/**", "*/reports/**"]
```
- Configurar `[capture] ignore_paths` para excluir `.hacker/ledger/**`, `.env`, `opsec/**`, relatorios com dados sensiveis.
- A captura de hooks NUNCA grava IP real, credenciais, ou PII.

2c. Adicionar modulo ai-memory ao `.opencode/rules/hacker-opsec-canon.md`:
- Registrar o modulo como canon por modulo da cadeia (Tabela canonica: `ai-memory` | `memoria longa/handoff` | container `ai-memory` up | `.ai-memory.toml` + `docker-compose.yml`)
- Dossie de risco: MCP loopback, captura de hooks, PII scan
- Vetor de teste: `curl http://127.0.0.1:49374/` responde; `[capture] ignore_paths` funciona

2d. Configurar MCP no opencode:
- Adicionar MCP server para ai-memory no `~/.config/opencode/opencode.json`
- Loopback 127.0.0.1:49374

**Implementacao**:
Modificar docker-compose.yml (append do servico). Criar .ai-memory.toml. Atualizar canon. Nao modificar arquivos existentes de memoria ou ledger.

---

## TASK 3: CAMINHO B, Documentar avaliacao (se NAO adotar)

**Arquivos**: CREATE `.opencode/specs/SPEC_010_AVALIACAO.md` (ou adicionar ao final da SPEC_010)

**Depende de**: TASK 1

**Verificacao**:
```bash
ls -la .opencode/specs/SPEC_010_AVALIACAO.md 2>/dev/null && echo "PASS: avaliacao documentada" || echo "N/A (caminho A)"
grep -n "nao adotar\|AVALIAR DEPOIS\|AVALIAR APOS" .opencode/specs/SPEC_010*.md && echo "PASS: avaliacao presente"
```

**Descricao Detalhada**:
Se o Fernando decidir NAO adotar ou AVALIAR DEPOIS:
- Criar documento de avaliacao com:
  - Pro/Contra da adocao de ai-memory
  - Razoes para nao adotar ou para adiar
  - Impacto no sistema de memoria existente (3 camadas preservadas)
  - Proximos passos recomendados
- Registrar a decisao no Trust Ledger e LEDGER.md

**Implementacao**:
Criar arquivo markdown com a avaliacao completa. Nao modificar arquivos existentes.

---

## TASK 4: Teste comportamental e verificacao final

**Arquivos**: `.opencode/rules/hacker-opsec-canon.md`, `~/opsec/docker-compose.yml`, `.ai-memory.toml` (se existentes)

**Depende de**: TASK 2 (se CAMINHO A) ou TASK 3 (se CAMINHO B)

**Verificacao**:
```bash
# Se CAMINHO A:
docker compose -f ~/opsec/docker-compose.yml config && echo "PASS: docker-compose config valido"
curl -s http://127.0.0.1:49374/ 2>&1 && echo "PASS: ai-memory acessivel" || echo "N/A ou nao iniciado"
cat .ai-memory.toml && echo "PASS: .ai-memory.toml presente"
grep -n "ai-memory\|akitaonrails" .opencode/rules/hacker-opsec-canon.md && echo "PASS: modulo no canon"

# Se CAMINHO B:
ls -la .opencode/specs/SPEC_010_AVALIACAO.md 2>/dev/null && echo "PASS: avaliacao documentada" || echo "N/A (caminho A)"

# Ambos os caminhos:
grep -rn "—\|–" .opencode/specs/SPEC_010*.md || echo "PASS: zero em-dash"
grep -rniE "\b(eu|meu|minha|meus|minhas)\b" .opencode/specs/SPEC_010*.md || echo "PASS: zero primeira pessoa"
grep -n "AI_MEMORY_LLM_PROVIDER=none\|127.0.0.1:49374\|loopback" ~/opsec/docker-compose.yml && echo "PASS: loopback configurado" || echo "N/A (caminho B)"
```

**Descricao Detalhada**:
Testar a implementacao do CAMINHO A ou verificar a documentacao do CAMINHO B. Confirmar que:
- O container ai-memory esta acessivel em loopback (se CAMINHO A)
- A configuracao `.ai-memory.toml` tem `[capture] ignore_paths` adequado
- O Memory Guard atual continua funcionando
- Nenhuma linha do ledger existente foi modificada (append-only preservado)

**Implementacao**:
Rodar os comandos de verificacao. Confirmar saida literal.

---

## CHECKLIST AUTO-REVIEW (Step 7)

- [x] Todos os paths sao exatos e confirmados no disco? (SPEC_010 gravada, MEMORIA.md confirmada)
- [x] Codigo completo em cada tarefa? (TASK 1: registrar decisao; TASK 2: docker-compose + .ai-memory.toml + canon; TASK 3: avaliacao; TASK 4: verificacao)
- [x] Cada tarefa tem o comando de verificacao do perfil? (docker compose config, grep, ls)
- [x] Ordem faz sentido? (TASK 1 primeiro, depois TASK 2 ou 3, depois TASK 4)
- [x] Toda tarefa declara DEPENDE_DE (real)? (TASK 2/3 dependem de TASK 1; TASK 4 depende de TASK 2 ou 3)
- [x] Nenhuma tarefa executa git write operations? (confirmado)
- [x] Verificacao final inclui docker compose config, grep estilo? (sim)
- [x] Pre-flight de postura: verificar-vazamento.sh GOOD? (NAO necessario | sem rede externa, classe B/C)
- [x] Classe C reconhecida para docker-compose.yml? (sim, TASK 2 requer confirmacao do Fernando)
- [x] Sem em-dash em texto novo? (sim, verificado)
- [x] Memory Guard existente preservado? (sim, nao modificado)
- [x] ISSUE-007 foi ADIADA ate ISSUE-001/002/006/003? (sim, todos concluidos)

## VERIFICATION (apos execucao de todas as tasks)

```bash
# 1. Trust Ledger atualizado:
grep -n "ISSUE-007" .opencode/ledger/trust-ledger.md | tail -3

# 2. LEDGER.md atualizado:
grep -n "ISSUE-007" LEDGER.md | tail -3

# 3. Se CAMINHO A: docker compose config:
docker compose -f ~/opsec/docker-compose.yml config && echo "PASS"

# 4. Se CAMINHO A: ai-memory acessivel:
curl -s http://127.0.0.1:49374/ 2>&1 || echo "Nao iniciado"

# 5. Se CAMINHO A: .ai-memory.toml:
cat .ai-memory.toml 2>/dev/null || echo "N/A (caminho B)"

# 6. Se CAMINHO A: canon atualizado:
grep -n "ai-memory" .opencode/rules/hacker-opsec-canon.md || echo "N/A (caminho B)"

# 7. Memory Guard preservado:
grep -n "Memory Guard\|PII\|SHA-256" .hacker/memoria/MEMORIA.md && echo "PASS: preservado"

# 8. Grep estilo:
grep -rn "—\|–" .opencode/specs/SPEC_010*.md || echo "PASS: zero em-dash"
grep -rniE "\b(eu|meu|minha|meus|minhas)\b" .opencode/specs/SPEC_010*.md || echo "PASS: zero primeira pessoa"

# 9. Append-only preservado:
tail -1 .hacker/ledger/operacoes.md && echo "PASS: ledger intacto"
```

## NOTAS IMPORTANTES

- **CLASSE C**: A modificacao de `~/opsec/docker-compose.yml` e classe C (F4). NAO EXECUTAR sem confirmacao explicita do Fernando.
- **Dois caminhos**: O plano cobre tanto adotar quanto nao adotar ai-memory. A decisao e do Fernando.
- **Sistema existente preservado**: `.hacker/memoria/MEMORIA.md` e o Memory Guard NAO sao modificados.
- **A avaliacao do ISSUE-007 ja cobriu todos os pontos**: PII, ledgers, rules vs facts, seguranca, migracao, auditoria.
- **Pre-flight F1**: Se docker-compose.yml for modificado, a confirmacao do Fernando e obrigatoria antes de qualquer execucao.
- **A ISSUE-007 foi ADIADA até ISSUE-001/002/006/003 estarem concluidas**, todos concluidos agora. A barreira de adiamento foi removida.
