# Template de Relatorio de Agente

> Preenchido pelo agente apos cada operacao.
> Registrado no ledger: `.hacker/ledger/operacoes.md`.

## Relatorio

### Cabecalho

| Campo | Valor |
|---|---|
| OPERACAO-ID | OP-YYYYMMDD-NNN |
| DATA | YYYY-MM-DD HH:MM |
| AGENTE | red-team / blue-team / pentest / scraping / web-scanner / orquestrador-pipeline |
| ESCOPO | [ lab autorizado ] |

### Vetor e Resultado

**Vetor**: [ descricao do vetor/alvo ]

**Resultado**: [ descricao detalhada do que foi obtido ]

### Evidencia

[ Comandos REAIS executados com saida literal ]

### Confiabilidade e Referencia

| Campo | Valor |
|---|---|
| Confiabilidade | alta / media / baixa |
| Referencia | [OWASP / MITRE / doc tecnico, com citacao, F6] |
| Hash | SHA-256 (primeiros 16 chars) |

### Findings por severidade (vulnerabilidades web)

| Campo | Conteúdo |
|---|---|
| ID | FIND-YYYYMMDD-NNN |
| Titulo | [ titulo da vulnerabilidade ] |
| Severidade | CVSS v3.1 score (base, temporal, environmental se aplicavel) |
| CWE | [ codigo CWE ] |
| URL | [ URL do alvo ] |
| Evidencia | [ descricao tecnica + referencia ao output do scanner ] |
| Impacto | [ descricao do impacto ] |
| Recomendacao | [ acao de remediacao ] |

Tabela de findings por severidade: Critical, High, Medium, Low, Informational.

### Nota de IP

> IP real de origem NUNCA e citado neste relatorio.
> IP de saida (WireGuard/Proton/Tor): [IP de saida, se aplicavel].