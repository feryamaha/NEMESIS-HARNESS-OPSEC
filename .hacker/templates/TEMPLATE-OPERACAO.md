# Template de Operacao Autorizada

> Preenchido pelo orquestrador antes de cada operacao.
> Formato detalhado em `ledger/LEDGER-OPERACOES.md`.

## Operacao

| Campo | Valor |
|---|---|
| OPERACAO-ID | OP-YYYYMMDD-NNN (auto-increment) |
| DATA | YYYY-MM-DD HH:MM |
| AGENTE-RESPONSAVEL | red-team / blue-team / pentest / scraping |
| ESCOPO | [ lab autorizado / ambiente / pesquisas com escopo formal ] |
| VETOR | [ o que sera feito: scan, enumeracao, exploit, scraping, defesa ] |
| PRE-REQUISITO | GATE: `bash ~/opsec/scripts/verificar-vazamento.sh` |
| VEREDITO-GATE | GOOD / BAD / NAO-EXECUTADO |
| REF-AUT | autorizacao verificavel: tipo=referencia (contrato/issu/spec/aut-duravel) ou N/A para dev |
| RESULTADO | [ pos-operacao: o que foi obtido ] |
| BASE | [ ferramenta + comando + citacao (F6, OWASP/MITRE) ] |
| HASH | SHA-256 do payload DATA..BASE (16 hex) |

## Notas

- Sem IP real cite SEMPRE IP de saida (WireGuard/Proton/Tor).
- Se VEREDITO-GATE != GOOD: operacao invalida, NAO execute, reporte ao Fernando.
