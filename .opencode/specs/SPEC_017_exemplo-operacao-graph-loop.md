# SPEC_017: Exemplo de Operacao de Hacking com Padroes Graph+Loop

## REQUEST

Exemplo conceitual de operacao de hacking utilizando os padroes Graph+Loop implementados no projeto. Demonstrar como routing, delegacao, paralelizacao, gates e loop evaluator-optimizer sao aplicados em um fluxo de pentest autorizado.

## CATEGORY

Feature

## PROBLEM

Nenhum arquivo de especificacao de exemplo existia para demonstrar como os padroes Graph+Loop se aplicam a operacoes de hacking reais na camada `.hacker/`.

## CONTEXT

**Executor ja implementado:**
- `.hacker/scripts/graph-loop.py` com subcomandos route, delegate, parallel, loop
- Suite de testes `.hacker/scripts/test-graph-loop.sh` com 8/8 PASS
- ORCHESTRADOR.md contem seção "Integração Graph+Loop" com diagrama de 6 nós
- 5 contratos de agentes contem seção "Padrões Graph+Loop"

**Fontes consultadas:**
- `.hacker/scripts/graph-loop.py` (executor local)
- `.hacker/orquestrador/ORQUESTRADOR.md` (integração Graph+Loop)
- `.hacker/agentes/pentest/AGENTE.md` (contrato pentest)
- `.hacker/agentes/red-team/AGENTE.md` (contrato red-team)
- `.opencode/specs/SPEC_017_integracao-graph-loop-camada-operacional-hacker.md` (spec de integração)

**Assumpções:**
- Exemplo conceitual, sem rede real, sem IP real, sem credenciais
- Cenario hipotético de pentest em lab autorizado (HTB/THM)
- Escopo formal definido pelo Fernando
- Pre-flight de proteção validado antes de qualquer etapa

## REQUIREMENTS

1. Demonstrar como ROUTING classifica uma operacao de pentest
2. Mostrar como DELEGAÇÃO seleciona agentes via WORKERS da spec
3. Mostrar como PARALELIZAÇÃO executa reconhecimento em paralelo
4. Mostrar como GATES protegem cada etapa
5. Mostrar como LOOP otimiza payloads iterativamente
6. Todos os exemplos de comando usam graph-loop.py

## FILES INVOLVED

- `.hacker/scripts/graph-loop.py` (executor)
- `.hacker/scripts/test-graph-loop.sh` (suite de testes)
- `.hacker/orquestrador/ORQUESTRADOR.md` (orquestrador)
- `.hacker/agentes/pentest/AGENTE.md` (contrato pentest)
- `.hacker/agentes/red-team/AGENTE.md` (contrato red-team)

## RESTRICTIONS

- Nenhuma rede real, nenhum IP real, nenhuma credencial
- Apenas exemplo conceitual para documentação
- Sem toque em ~/opsec/scripts/ ou docker-compose.yml
- Sem em/en dash, sem primeira pessoa
- PT-BR

## EXPECTED DELIVERY

- Spec completa com CATEGORY, FILES INVOLVED, WORKERS, REQUIREMENTS
- Exemplos de comandos graph-loop.py para cada nó do Graph
- Fluxo do pipeline 5-etapas integrado com nós do Graph
- Verificação: grep zero em/en dash, grep zero IP literal

## EXEMPLO DE OPERAÇÃO: Pentest Web Autorizado

### Entrada

```markdown
## REQUEST
Executar pentest autorizado em ALVO_WEB_APPLICATION em lab HTB.

## CATEGORY
Feature

## PROBLEM
Identificar e explorar vulnerabilidades em aplicação web autorizada.

## CONTEXT
Fontes consultadas: https://cheatsheetseries.owasp.org/
Fonte interna: .hacker/agentes/pentest/AGENTE.md
Escopo: HTB máquina "WebAdmin" (autorizada)

## REQUIREMENTS
- Reconhecimento ativo
- Exploração controlada
- Relatório com findings validados
- Loop de otimização de payloads

## FILES INVOLVED
- .hacker/agentes/pentest/AGENTE.md
- .hacker/agentes/web-scanner/AGENTE.md
## RESTRICTIONS
Sem rede fora do escopo autorizado. Sem IP real no relatório.

## EXPECTED DELIVERY
Relatório de pentest com findings validados.

## WORKERS
red-team: reconhecimento ativo
pentest: exploração e exploit
web-scanner: scan automatizado complementar
```

### Aplicacao dos 6 nos do Graph

#### ROUTING

```bash
python3 .hacker/scripts/graph-loop.py route --spec specs/SPEC_017_exemplo-operacao-graph-loop.md
```

Resultado esperado:
```json
{"category": "feature", "route": "orquestrador", "guard": "reforcado", "sensitive": true}
```

CATEGORY = "Feature" com FILES INVOLVED = `.hacker/agentes/` → rota `orquestrador`, guard `reforcado`.

#### DELEGACAO

```bash
python3 .hacker/scripts/graph-loop.py delegate --spec specs/SPEC_017_exemplo-operacao-graph-loop.md --complexidade complexa
```

Resultado esperado:
```json
{"route": {"category": "feature", "route": "orquestrador", "guard": "reforcado", "sensitive": true}, "workers": ["red-team", "pentest", "web-scanner", "preflight-checker", "documentador"]}
```

WORKERS da spec prevalecem sobre defaults. `preflight-checker` adicionado por FILES INVOLVED sensíveis. `documentador` adicionado por complexidade "complexa".

#### PARALELIZACAO

Reconhecimento ativo e scan automatizado executam em paralelo:

```bash
python3 .hacker/scripts/graph-loop.py parallel \
  --job "nmap_scan=nmap -sS -sV -p- ALVO_WEB" \
  --job "nuclei_scan=nuclei -target ALVO_WEB -templates cves,cms" \
  --job "curl_probe=curl -s --socks5-hostname 127.0.0.1:9050 ALVO_WEB"
```

Resultado esperado:
```json
{"jobs": [{"name": "curl_probe", "exit_code": 0, "stdout": "...", "stderr": ""}, {"name": "nmap_scan", "exit_code": 0, "stdout": "...", "stderr": ""}, {"name": "nuclei_scan", "exit_code": 0, "stdout": "...", "stderr": ""}]}
```

Merge point: web-scanner recebe resultados de nmap e nuclei.

#### GATES

Pre-flight executado ANTES de cada etapa:

```bash
bash ~/opsec/scripts/verificar-vazamento.sh
# GOOD = cadeia ativa. Pode prosseguir.
```

Gate P1 valida estrutura da spec:
```bash
bash .hacker/scripts/gate-p1.sh specs/SPEC_017_exemplo-operacao-graph-loop.md
# EXIT_CODE=0 = PASS
```

Gate P2 valida regras de area sensivel:
```bash
bash .hacker/scripts/gate-p2.sh specs/SPEC_017_exemplo-operacao-graph-loop.md
# EXIT_CODE=0 = PASS
```

#### EXECUCAO

Workers executam em sequence após gates:
1. **red-team**: reconhecimento ativo (nmap, masscan)
2. **web-scanner**: scan automatizado (ZAP, Nuclei)
3. **pentest**: exploracao controlada
4. **preflight-checker**: re-verifica cadeia antes de rede
5. **documentador**: atualiza relatorio em `.hacker/reports/`

#### LOOP

Otimizacao iterativa de payloads para exploração:

```bash
python3 .hacker/scripts/graph-loop.py loop \
  --evaluator "python3 validador_payload.py" \
  --generator "python3 gerador_payload.py" \
  --max-cycles 5 \
  --max-stagnant 3 \
  --ledger .hacker/ledger/loop-pentest.txt
```

Condições de parada:
- `evaluator exit=0` → payload validado
- `melhoria detectada` → continua iterando
- `max_cycles=5` atingido → para
- `max_stagnant=3` atingido → para (sem melhoria)

Feedback via EVALUATOR_* variables ao generator.

### Diagrama do Fluxo

```
SPEC (WORKERS: red-team, pentest, web-scanner)
    │
    ▼
ROUTING → CATEGORY=Feature → route=orquestrador, guard=reforcado
    │
    ▼
DELEGACAO → workers: [red-team, pentest, web-scanner, preflight-checker, documentador]
    │
    ▼
PARALELIZACAO → [nmap, nuclei, curl] em paralelo
    │
    ▼
GATES → P1 PASS + P2 PASS + pre-flight GOOD
    │
    ▼
EXECUCAO → red-team → web-scanner → pentest → documentador
    │
    ▼
LOOP → generator ↔ evaluator (max 5 ciclos)
    │
    ▼
RELATORIO → .hacker/reports/OP-YYYYMMDD-NNN_pentest-ALVO.md
```

## Integracao com o Pipeline 5-Etapas

| Etapa | No do Graph Aplicado | Agente |
|---|---|---|
| Etapa 1: Scraping | ROUTING + PARALELIZACAO | scraping |
| Etapa 2: Web Scanner | ROUTING + DELEGAÇÃO | web-scanner |
| Etapa 3: Pentest | GATES + LOOP | pentest |
| Etapa 4: Reconfirmacao | DELEGAÇÃO + EXECUÇÃO | web-scanner |
| Etapa 5: Blue Team | LOOP + EXECUÇÃO | blue-team |

## VERIFICACAO

```bash
# Verificar ausência de em/en dash
grep -rn '[—–]' .opencode/specs/SPEC_017_exemplo-operacao-graph-loop.md
# Esperado: zero ocorrencias

# Verificar ausência de IP literal
grep -rn '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' .opencode/specs/SPEC_017_exemplo-operacao-graph-loop.md | grep -v '127.0.0.1'
# Esperado: zero ocorrencias

# Verificar estrutura da spec
grep -q 'WORKERS' .opencode/specs/SPEC_017_exemplo-operacao-graph-loop.md && echo "WORKERS presente"
grep -q 'ROUTING' .opencode/specs/SPEC_017_exemplo-operacao-graph-loop.md && echo "ROUTING presente"
grep -q 'LOOP' .opencode/specs/SPEC_017_exemplo-operacao-graph-loop.md && echo "LOOP presente"
```

## Regras aplicáveis

- `AGENTS.md` seção 7 (SDD pipeline)
- `hacker-fable-method.md` leis F1-F12
- `hacker-epistemic-safety.md` (anti-invencao)
- `hacker-documentation-style.md` (estilo de documentação)
- `hacker-repo-profile.md` (validacao por fase)

## Fontes citadas (F6)

1. `.hacker/scripts/graph-loop.py` (executor local)
2. `.hacker/orquestrador/ORQUESTRADOR.md` (integração Graph+Loop)
3. `.opencode/specs/SPEC_017_integracao-graph-loop-camada-operacional-hacker.md` (spec de integração)
4. `.hacker/agentes/pentest/AGENTE.md` (contrato pentest)
5. `.hacker/agentes/red-team/AGENTE.md` (contrato red-team)
6. `.opencode/rules/hacker-opsec-canon.md` (canon da cadeia)
7. Anthropic, "Building Effective Agents", Dez 2024 — https://www.anthropic.com/engineering/building-effective-agents

## Origem

TASK 8 do PLAN_017_integracao-graph-loop-camada-operacional.md. ISSUE-013: Integração dos Padrões Graph+Loop na Camada Operacional .hacker/.
