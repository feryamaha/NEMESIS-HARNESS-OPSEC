---
trigger: always_on
status: active
scope: canonical
last_updated: 2026-09-11
---

# Hacker Etico: Web App Scan Report (comportamento AI)

> Regra canonica para o harness `hacker-etico-ambiente`. Define como o agente DEVE se
> comportar ao executar scan de aplicacoes web (ZAP + Nuclei) e gerar relatorio tecnico
> estruturado. Destinatario: modelos de IA agenticos, nao o humano. Anti-invencao: todo
> finding tem fonte observavel (`.opencode/rules/hacker-epistemic-safety.md`).

## Contexto

Esta regra complementa `hacker-pentest-harness-execution.md` e `hacker-epistemic-safety.md`.
Ela nao duplica regras existentes; apenas adiciona restricoes especificas para o dominio
de scan de aplicacoes web e geracao de relatorio tecnico (OWASP/PTES).

## 1.1 Escopo e autorizacao do scan

- Todo scan web requer escopo formal definido (alvo, URL, limite de tempo) pelo Fernando.
- Escopo fora de escopo formal = nunca executar (regra de seguranca, nao censura).
- Anti-censura mantida: dentro do escopo autorizado E protegido, o agente nao recusa
  analisar ou executar vetores web.

## 1.2 Protecao pré-requisito

- Antes de QUALQUER scan de rede: `bash ~/opsec/scripts/verificar-vazamento.sh` GOOD.
- Se GOOD = prossegue. Se nao = PARA e reporta.
- Scan nunca roda diretamente no host sem cadeia.

## 1.3 Formato de saida de scan

- ZAP: saida XML convertida para JSON via `zap-cli` ou parse manual.
- Nuclei: saida JSON via `-jsonl` ou `-je` (formato intermediario obrigatorio).
- Todo scan deve gerar JSON estruturado como artefato intermediario.

## 1.4 Estrutura obrigatoria do relatorio tecnico

O relatorio gerado deve seguir esta estrutura:

1. **Cabeçalho** (data, alvo, escopo, agente, ferramenta)
2. **Execução** (metodologia, ferramentas usadas, parametros)
3. **Escopo** (definicao do que foi e nao foi scaneado)
4. **Metodologia** (approach, fases)
5. **Findings** (por severidade: Critical, High, Medium, Low, Informational)
   - Cada finding: ID, titulo, severidade (CVSS v3.1), CWE, URL, evidencia, impacto,
     recomendacao
6. **Conclusão** (resumo geral, riscos residuais, proximos passos)

## 1.5 Classificação de severidade e CVSS v3.1

- Toda vulnerabilidade encontrada deve ter CVSS v3.1 score (base, temporal,
  environmental se aplicavel).
- Se o scanner nao fornecer CVSS, o agente deve consultar fonte confiavel (NVD) ou
  classificar conservadoramente.
- CWE obrigatorio para cada finding.

## 1.6 Registro no Ledger Operacional

- Cada execucao de scan gera entrada em `.hacker/ledger/operacoes.md` com: data,
  alvo, escopo, ferramentas, gate (GOOD/bloqueado), resultados resumidos.

## 1.7 Anti-invencao (F6)

- Nunca fabricar findings. Se o scan nao encontra nada, reporte "0 findings detectados"
  com evidencia literal da saida do scanner.
- Nunca inventar CVSS/CWE sem fonte. Se nao pode atribuir CVSS exato, classificar como
  "unclassified - pending verification".

## 1.8 Declaracao de Fonte CVSS/CWE

- Todo relatorio de scan web deve declarar:
  - `Data da checagem CVSS/CWE: YYYY-MM-DD`
  - `Fonte de CVSS/CWE: NVD | ZAP | Nuclei | unclassified - pending verification`
- Campos sem fonte devem conter "unclassified - pending verification".
- O procedimento de refresh esta documentado em `.hacker/rag/REFRESH-PROCEDURE.md`.
- Esta declaracao e aditiva: nao altera o comportamento atual das regioes 1.5 e 1.7.

## Integracao com o harness

- O agente `web-scanner` (contrato em `.hacker/agentes/web-scanner/AGENTE.md`) usa
  esta regra como base de comportamento.
- O orquestrador despacha o web-scanner via `templates/TEMPLATE-CONTRATO.md`.
- O gate de protecao (`GATE-DE-PROTECAO.md`) aplica `verificar-vazamento.sh` antes de
  qualquer operacao do web-scanner.
- O RAG (`rag/README-RAG.md`) fornece as fontes de conhecimento (OWASP, NVD) para
  enriquecimento de findings.
