# Formato do Ledger de Operacoes

> Adaptado de: GH05TCREW/pentestagent (ledger de conversas/operacoes).

## Regra

- **Append-only**: NUNCA deletar ou editar registros existentes.
- **Hash por entrada**: SHA-256 do conteudo (integridade, Memory Guard).
- **Sem IP real**: cite sempre IP de saida (WireGuard/Proton/Tor), nunca IP real.

## Arquivo

`.hacker/ledger/operacoes.md` (append-only, formato tabela Markdown).

## Campos obrigatorios

| Campo | Descricao | Exemplo |
|---|---|---|
| DATA | YYYY-MM-DD HH:MM | 2026-09-15 14:30 |
| OPERACAO-ID | OP-YYYYMMDD-NNN (auto-increment) | OP-20260915-001 |
| AGENTE | red-team / blue-team / pentest / scraping | red-team |
| ESCOPO | lab/ambiente autorizado | HackTheBox-MachineX |
| GATE | verificacao: GOOD / BAD / bloqueado | GOOD |
| REF-AUT | autorizacao verificavel para operacoes de rede | N/A ou tipo=referencia |
| VETOR | vetor/alvo da operacao | Enumeracao de portas 80/443 |
| RESULTADO | o que foi obtido | 3 servicos HTTP identificados |
| BASE | comando real ou referencia (F6) | `nmap -sV 10.10.x.x` + MITRE T1046 |
| HASH | SHA-256 do payload DATA..BASE (16 hex) | a3f2b1c9... |

## Exemplo de entrada

| DATA | OPERACAO-ID | AGENTE | ESCOPO | GATE | REF-AUT | VETOR | RESULTADO | BASE | HASH |
|---|---|---|---|---|---|---|---|---|---|
| 2026-09-15 14:30 | OP-20260915-001 | red-team | HTB-MachineX | GOOD | N/A | Port scan | 2 servicos | `nmap -sV 10.10.x.x` | a3f2b1c9... |
