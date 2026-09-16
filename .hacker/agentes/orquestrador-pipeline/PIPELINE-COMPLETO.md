# Pipeline Completo - Fluxo de 5 Etapas

> Skill do orquestrador-pipeline. Cada etapa le o relatorio da anterior
> e gera saida para a proxima. Modo completo: 5 etapas sequenciais.
> Modo parcial: qualquer sub-sequencia.

## Pre-Flight Obrigatorio (ANTES de qualquer etapa)

**BLOQUEADO sem verificacao primaria.** Antes de QUALQUER operacao de rede,
o agente DEVE confirmar que o `session-start-hacking-security.sh` foi executado
e retornou GOOD.

### Verificacao primaria (OBRIGATORIA, rodar ANTES de cada etapa)

```bash
# 1. Atestado existe e e GOOD?
ATESTADO=$(ls -t /home/fernando/devproj/hacker-etico-ambiente/atestado_ambiente_*.txt 2>/dev/null | head -1)
if [ -z "$ATESTADO" ]; then
  echo "BLOQUEADO: Nenhum atestado encontrado. Execute: sudo bash ~/opsec/scripts/session-start-hacking-security.sh"
  exit 1
fi
if ! grep -q "Resultado final: GOOD" "$ATESTADO"; then
  echo "BLOQUEADO: Atestado nao e GOOD. Reexecute: sudo bash ~/opsec/scripts/session-start-hacking-security.sh"
  exit 1
fi

# 2. WireGuard wg0 ativo?
if ! ip -o link show wg0 >/dev/null 2>&1; then
  echo "BLOQUEADO: WireGuard wg0 nao ativo."
  exit 1
fi

# 3. Container Docker torproxy-host rodando?
if ! docker ps --format '{{.Names}}' 2>/dev/null | grep -q torproxy-host; then
  echo "BLOQUEADO: Container torproxy-host nao esta rodando."
  exit 1
fi

# 4. Verificacao final de vazamento
bash ~/opsec/scripts/verificar-vazamento.sh
# GOOD = cadeia ativa. Pode prosseguir.
# Qualquer outro resultado = BLOQUEADO.
```

**Se QUALQUER passo falhar, o pipeline PARA e reporta. Nao prossiga.**

**IMPORTANTE:** Esta verificacao e re-executada ANTES de CADA etapa do pipeline.
Se em qualquer etapa o gate falhar, o pipeline para naquela etapa.

---

## Etapa 1: SCRAPING (Coleta Passiva)

### Entrada

- URL alvo (fornecida pelo Fernando)
- Escopo definido

### O que fazer

Usar o agente `scraping` para coletar dados publicos do alvo.

1. `curl -s --socks5-hostname 127.0.0.1:9050 --max-time 15 https://ALVO/`
2. Coletar: headers HTTP, tecnologias detectadas, endpoints, links, meta tags
3. Salvar relatorio em `.hacker/reports/OP-YYYYMMDD-NNN_scraping-ALVO.md`

### Saida (formato)

```markdown
# Relatorio de Scraping - [ALVO]

## Cabecalho
| OPERACAO-ID | OP-YYYYMMDD-NNN |
| DATA | YYYY-MM-DD HH:MM |
| AGENTE | scraping |
| ALVO | https://ALVO/ |

## Dados Coletados
- Tecnologias: [lista]
- Endpoints encontrados: [lista]
- Headers: [lista]
- Links internos: [quantidade]
- Links externos: [quantidade]

## Evidencia
[Comandos REAIS executados com saida literal]

## Nota de IP
> IP real de origem NUNCA e citado.
> IP de saida (Tor): [exit node]
```

### Transicao para Etapa 2

O relatorio de scraping e salvo em disco. A Etapa 2 (web-scanner) LE este
relatorio e usa os endpoints/tecnologias descobertos como input para o scan.

---

## Etapa 2: WEB SCANNER (Scan Automatizado)

### Entrada

- Relatorio da Etapa 1 (scraping) → `.hacker/reports/OP-YYYYMMDD-NNN_scraping-ALVO.md`
- URLs e endpoints descobertos

### O que fazer

Usar o agente `web-scanner` para scan automatizado de vulnerabilidades.

1. Ler relatorio de scraping
2. Identificar endpoints para scan: `/wp-login.php`, `/wp-json/`, `/xmlrpc.php`, etc.
3. Executar ZAP API scan e/ou Nuclei DAST nos endpoints
4. Classificar findings por CVSS/CWE
5. Salvar relatorio em `.hacker/reports/OP-YYYYMMDD-NNN_scan-ALVO.md`

### Saida (formato)

```markdown
# Relatorio de Scan de Seguranca - [ALVO]

## Cabecalho
| OPERACAO-ID | OP-YYYYMMDD-NNN |
| DATA | YYYY-MM-DD HH:MM |
| AGENTE | web-scanner |
| ALVO | https://ALVO/ |
| BASE | Relatorio de scraping: OP-YYYYMMDD-NNN |

## Findings por Severidade
| Severidade | Quantidade |
|---|---|
| Critical | N |
| High | N |
| Medium | N |
| Low | N |
| Informational | N |

## Detalhamento por Finding
[FIND-YYYYMMDD-NNN com CVSS, CWE, evidencia, impacto, recomendacao]

## Evidencia
[Comandos REAIS executados com saida literal]

## Nota de IP
> IP real de origem NUNCA e citado.
> IP de saida (Tor): [exit node]
```

### Transicao para Etapa 3

O relatorio de scan e salvo em disco. A Etapa 3 (pentest) LE este relatorio
e tenta explorar as vulnerabilidades encontradas.

---

## Etapa 3: PENTEST (Exploracao Ativa)

### Entrada

- Relatorio da Etapa 2 (web-scanner) → `.hacker/reports/OP-YYYYMMDD-NNN_scan-ALVO.md`
- Vulns encontradas pelo scanner

### O que fazer

Usar o agente `pentest` para tentar EXPLORAR as vulnerabilidades encontradas.

1. Ler relatorio de scan
2. Para CADA finding do scanner, tentar explorar:
   - **CORS wildcards**: testar com origem forjada
   - **CSP unsafe-inline**: testar XSS refletido
   - **PUT/DELETE aceitos**: testar modificacao de dados
   - **Users enumerados**: testar brute force via xmlrpc
   - **Endpoints expostos**: testar LFI, SQLi, SSRF
3. Confirmar se cada vetor e **viavel** ou **falso-positivo**
4. Salvar relatorio em `.hacker/reports/OP-YYYYMMDD-NNN_pentest-ALVO.md`

### Regra Critica

**NUNCA misturar findings do scanner no relatorio do pentest.**
O pentest gera SEUS proprios findings baseados em exploracao real.
Se o pentest confirma um finding do scanner, ele cria um finding
novo com evidencia de exploracao propria.

### Saida (formato)

```markdown
# Relatorio de Pentest - [ALVO]

## Cabecalho
| OPERACAO-ID | OP-YYYYMMDD-NNN |
| DATA | YYYY-MM-DD HH:MM |
| AGENTE | pentest |
| ALVO | https://ALVO/ |
| BASE | Relatorio de scan: OP-YYYYMMDD-NNN |

## Vetores Testados
| Vetor | Metodo | Resultado | Evidencia |
|---|---|---|---|
| [vetor] | [comando] | VIAVEL / FALSO-POSITIVO / BLOQUEADO | [saida literal] |

## Findings do Pentest
[FIND-YYYYMMDD-NNN com evidencia de exploracao propria]

## Evidencia
[Comandos REAIS executados com saida literal]

## Nota de IP
> IP real de origem NUNCA e citado.
> IP de saida (Tor): [exit node]
```

### Transicao para Etapa 4

O relatorio do pentest e salvo em disco. A Etapa 4 (web-scanner) LE este
relatorio e reconfirma as vulns que o pentest confirmou como viaveis.

---

## Etapa 4: WEB SCANNER (Reconfirmacao)

### Entrada

- Relatorio da Etapa 3 (pentest) → `.hacker/reports/OP-YYYYMMDD-NNN_pentest-ALVO.md`
- Vetores confirmados como viaveis

### O que fazer

Usar o agente `web-scanner` para RECONFIRMAR que as vulns do pentest
ainda existem e estao acessiveis.

1. Ler relatorio do pentest
2. Para CADA finding confirmado pelo pentest, re-testar com ferramentas
   automatizadas (ZAP/Nuclei) para confirmar que o vetor ainda esta aberto
3. Comparar: pentest disse "viavel" → scanner confirma "presente"?
4. Se divergencia: registrar como gap no relatorio
5. Salvar relatorio em `.hacker/reports/OP-YYYYMMDD-NNN_reconfirm-ALVO.md`

### Saida (formato)

```markdown
# Relatorio de Reconfirmacao - [ALVO]

## Cabecalho
| OPERACAO-ID | OP-YYYYMMDD-NNN |
| DATA | YYYY-MM-DD HH:MM |
| AGENTE | web-scanner (reconfirmacao) |
| ALVO | https://ALVO/ |
| BASE | Relatorio de pentest: OP-YYYYMMDD-NNN |

## Reconfirmacao
| Finding do Pentest | Status Scanner | Divergencia? |
|---|---|---|
| [finding] | CONFIRMADO / NAO ENCONTRADO | SIM / NAO |

## Evidencia
[Comandos REAIS executados com saida literal]

## Nota de IP
> IP real de origem NUNCA e citado.
> IP de saida (Tor): [exit node]
```

### Transicao para Etapa 5

O relatorio de reconfirmacao e salvo em disco. A Etapa 5 (blue-team) LE
os relatorios do pentest E da reconfirmacao e gera o plano de correcao.

---

## Etapa 5: BLUE TEAM (Plano de Correcao)

### Entrada

- Relatorio da Etapa 3 (pentest) → `.hacker/reports/OP-YYYYMMDD-NNN_pentest-ALVO.md`
- Relatorio da Etapa 4 (reconfirmacao) → `.hacker/reports/OP-YYYYMMDD-NNN_reconfirm-ALVO.md`

### O que fazer

Usar o agente `blue-team` para gerar plano de correcao baseado em tudo
que foi confirmado por TODAS as etapas.

1. Ler relatorio do pentest (vulns confirmadas com exploracao)
2. Ler relatorio de reconfirmacao (scanner confirmou que ainda existem)
3. Para CADA finding que passou por ambas as etapas:
   - Confirmar severidade (usar a MAIOR entre pentest e scanner)
   - Definir acao de correcao especifica
   - Priorizar por severidade
4. Gerar plano de hardening completo
5. Salvar relatorio em `.hacker/reports/OP-YYYYMMDD-NNN_correcao-ALVO.md`

### Saida (formato)

```markdown
# Relatorio de Correcao - [ALVO]

## Cabecalho
| OPERACAO-ID | OP-YYYYMMDD-NNN |
| DATA | YYYY-MM-DD HH:MM |
| AGENTE | blue-team |
| ALVO | https://ALVO/ |
| BASE | Pentest: OP-YYYYMMDD-NNN + Reconfirmacao: OP-YYYYMMDD-NNN |

## Resumo Executivo
| Severidade | Total Corrigido |
|---|---|
| Critical | N |
| High | N |
| Medium | N |
| Low | N |

## Plano de Correcao

### FIND-CORRECAO-001 | [Titulo] | CRITICAL
**Vulnerabilidade:** [descricao com referencia ao finding original]
**Evidencia:** [comando + saida que confirmou]
**Correcao:** [acao especifica de hardening]
**Prioridade:** IMEDIATA

### FIND-CORRECAO-002 | [Titulo] | HIGH
...

## Evidencia
[Comandos REAIS executados com saida literal]

## Nota de IP
> IP real de origem NUNCA e citado.
> IP de saida (Tor): [exit node]
```

---

## Registro no Ledger

Ao final de CADA etapa, registrar no ledger:

```bash
# Formato de registro
| DATA | OP-YYYYMMDD-NNN | [agente] | externo | GOOD | [resumo] | [ferramentas] | [hash] |
```

Ao final do pipeline completo, registrar entrada consolidada:

```bash
| DATA | OP-YYYYMMDD-NNN | pipeline | externo | GOOD | Pipeline completo: scraping→scan→pentest→reconfirm→correcao | [resumo] | [hash] |
```

---

## Tratamento de Falhas

| Falha | Acao |
|---|---|
| Gate GOOD em qualquer etapa | PARE. Reporte a Fernando. Nao prossiga. |
| Agente nao consegue gerar relatorio | PARE. Dados insuficientes para proxima etapa. |
| Nenhum finding em qualquer etapa | Prossiga. "Nenhum finding" e um resultado valido. |
| Divergencia entre etapas | Registre como gap. Nao ignore. |
| Timeout em scan/teste | Registre como "inconclusivo". Nao assuma resultado. |

---

## Disciplina de Resposta

- **Evidencia incompleta:** declare a incerteza. "O scan retornou X mas nao
  foi possivel confirmar Y porque Z."
- **Dado nao verificado:** diga "nao foi verificado" e explique por que.
- **Divergencia entre etapas:** registre AMBOS os lados. Nao descarte nenhum.
- **Nunca:** afirmar que um vetor "nao existe" so porque o scanner nao encontrou.
  O pentest pode encontrar algo que o scanner perdeu.
