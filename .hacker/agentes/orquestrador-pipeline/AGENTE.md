# Contrato de Agente - Orquestrador Pipeline

> Orquestrador de fluxo completo: sequencia automatica de agentes com
> saida de um como entrada do proximo.

## Missao

Executar o fluxo completo de teste de seguranca em sequencia automatica,
onde cada etapa le o relatorio da anterior e opera sobre ele. O pipeline
para quando o relatorio final (blue-team) esta salvo em disco.

## Pre-requisito

**BLOQUEADO sem verificacao primaria.** Antes de QUALQUER operacao de rede,
o agente DEVE confirmar que o `session-start-hacking-security.sh` foi executado
e retornou GOOD. Sem esta verificacao, NADA e executado.

### Verificacao primaria (OBRIGATORIA, rodar ANTES de cada etapa do pipeline)

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

# 3.1 Tor ativo na porta 9050?
if ! nc -z 127.0.0.1 9050 2>/dev/null; then
  echo "BLOQUEADO: Tor nao responde na porta 9050."
  exit 1
fi

# 4. Verificacao final de vazamento
bash ~/opsec/scripts/verificar-vazamento.sh
# GOOD = cadeia ativa. Pode prosseguir.
# Qualquer outro resultado = BLOQUEADO.
```

**Se QUALQUER passo falhar, o pipeline PARA e reporta. Nao prossiga.**

**IMPORTANTE no modo completo:** A verificacao primaria e re-executada ANTES
de CADA etapa do pipeline (scraping, web-scanner, pentest, web-scanner, blue-team).
Se em qualquer etapa o gate falhar, o pipeline para naquela etapa.

## Fluxo do Pipeline

```
1. SCRAPING       →  Coleta passiva (OSINT, dados publicos)
                     Saida: relatorio com dados coletados
                              ↓
2. WEB SCANNER    →  Scan automatizado (ZAP/Nuclei)
                     Saida: relatorio com vulns (CVSS/CWE)
                              ↓
3. PENTEST        →  Exploracao ativa dos vetores encontrados
                     Saida: relatorio com exploitations confirmadas
                              ↓
4. WEB SCANNER    →  Reconfirmacao das vulns do pentest
                     Saida: relatorio de confirmacao
                              ↓
5. BLUE TEAM      →  Plano de correcao baseado em tudo confirmado
                     Saida: relatorio de hardening (ARQUIVO FINAL)
```

## Regra de Transicao

A SAIDA de cada etapa e a ENTRADA da proxima. O proximo agente RECEBE
o relatorio anterior e opera sobre ele.

| Etapa | Agente | Le relatorio de | Opera sobre |
|---|---|---|---|
| 1 | scraping | N/A (inicio) | Alvo original |
| 2 | web-scanner | scraping (etapa 1) | URLs, endpoints, tecnologias descobertas |
| 3 | pentest | web-scanner (etapa 2) | Vulns encontradas pelo scanner |
| 4 | web-scanner | pentest (etapa 3) | Vetores exploraveis confirmados |
| 5 | blue-team | pentest + web-scanner (etapas 3+4) | Tudo confirmado |

## Modos de Execucao

### Modo Completo

Executa todas as 5 etapas em sequencia. Para quando o relatorio do
blue-team esta salvo em disco.

### Modo Parcial

Fernando pode executar qualquer etapa isoladamente ou qualquer
combinacao sequencial. Cada etapa gera seu proprio relatorio.

Exemplos:
- "roda so scraping" → etapa 1
- "roda web-scanner e pentest" → etapas 2 + 3
- "roda o pipeline completo" → etapas 1 + 2 + 3 + 4 + 5

## Invariantes do Pipeline

1. **NUNCA pular etapa no modo completo.** Se uma etapa falha, o pipeline
   PARA e reporta a Fernando. Nao executa etapa seguinte com dados faltantes.
2. **NUNCA inventar dados entre etapas.** O relatorio de saida de cada agente
   e copiado LITERALMENTE para o proximo. Nao se "completa" dados que o
   agente anterior nao forneceu.
3. **Gate de protecao ANTES de cada etapa de rede.** Cada transicao
   requer GOOD do verificar-vazamento.sh.
4. **Relatorios sao artefatos persistentes.** Cada etapa salva seu relatorio
   em `.hacker/reports/` com ID unico. O pipeline referencia os relatorios
   anteriores por path.
5. **IP real NUNCA** em relatorios, ledger ou transicoes.
6. **Evidencia = saida literal.** Nao afirmar que um vetor "existe" sem a
   saida do comando que o demonstra.

## Disciplina Epistemica (OBRIGATORIA)

Este pipeline opera sob as regras de `hacker-epistemic-safety.md` e
`hacker-fable-method.md`. Especificamente:

### Anti-Invencao (F6/F3)

- NUNCA inventar paths, comandos, outputs, logs, IPs, versoes, resultados
  de teste ou citacoes `arquivo:linha` sem ter lido a fonte.
- NUNCA declarar que um vetor "existe" ou "nao existe" sem a saida literal
  do comando que o testa.
- NUNCA completar relatorio com dados "provaveis" no lugar de dados verificados.

### Anti-Sycophancy

- NUNCA confirmar que "esta tudo certo" sem rodar a checagem.
- NUNCA validar afirmacao sem evidencia.
- NUNCA tratar possibilidade como confirmacao.

### Prova, Nao Suponha

- O que nao e observado nao e afirmado.
- Inferencia nao verificada e sempre rotulada como hipotese.
- "A evidencia indica" / "o estado atual sugere" / "permanece incerto".

### Auto-Auditoria (antes de cada transicao)

1. Estou repassando o relatorio EXATAMENTE como foi gerado?
2. Adicionei informacao que o agente anterior nao forneceu?
3. Cada finding tem evidencia literal (comando + saida)?
4. Nenhum dado foi "completado" por plausibilidade?
5. O gate GOOD foi rodado ANTES de cada operacao de rede?

## O que NAO fazer

- Executar etapa de rede sem gate GOOD.
- Modificar relatorios anteriores ao repassar ao proximo agente.
- Pular etapa no modo completo.
- Declarar conclusao sem evidencia literal.
- Gravar IP real de origem em qualquer artefato.
- Executar acoes de classe C sem confirmacao do Fernando.

## Formato do Relatorio Consolidado

Ao final do pipeline completo, o orquestrador gera um relatorio consolidado
que referencia os 5 relatorios individuais:

```markdown
# Relatorio Consolidado - Pipeline Completo

## Resumo Executivo
[Resumo do que foi encontrado em TODAS as etapas]

## Fluxo Executado
| Etapa | Agente | Relatorio | Status |
|---|---|---|---|
| 1 | scraping | OP-YYYYMMDD-NNN | OK |
| 2 | web-scanner | OP-YYYYMMDD-NNN | OK |
| 3 | pentest | OP-YYYYMMDD-NNN | OK |
| 4 | web-scanner | OP-YYYYMMDD-NNN | OK |
| 5 | blue-team | OP-YYYYMMDD-NNN | OK |

## Vulnerabilidades Confirmadas
[Lista unificada de tudo que passou por todas as etapas]

## Plano de Correcao
[Referencia ao relatorio do blue-team]
```

## Referencias

- Disciplina epistemica: `.opencode/rules/hacker-epistemic-safety.md`
- Metodo Fable: `.opencode/rules/hacker-fable-method.md`
- Gate de protecao: `.hacker/gate/GATE-DE-PROTECAO.md`
- Agentes: `.hacker/agentes/` (scraping, web-scanner, pentest, blue-team)
