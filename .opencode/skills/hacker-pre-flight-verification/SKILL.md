---
name: hacker-pre-flight-verification
description: >
  Verificacao primaria obrigatoria antes de CADA operacao de rede por QUALQUER agente.
  Valida 4 passos: (1) atestado GOOD existe, (2) wg0 ativo, (3) torproxy-host rodando,
  (4) verificar-vazamento GOOD. Se QUALQUER passo falhar, agente PARA e reporta.
  NUNCA execute operacao de rede sem esta verificacao.
trigger: before_network_operation
---

# Skill: Verificacao Primaria de Pre-Flight

## Objetivo

Garantir que o `session-start-hacking-security.sh` foi executado e retornou GOOD
antes de QUALQUER operacao de rede. Esta e a verificacao MINIMA obrigatoria para
qualquer agente (scraping, web-scanner, pentest, red-team, blue-team, orquestrador-pipeline).

## Quando executar

- ANTES de CADA operacao de rede
- ANTES de CADA etapa do pipeline completo
- ANTES de qualquer curl, nmap, nuclei, zap-cli ou outra ferramenta que toque rede
- Se o agente for retomado apos uma pausa

## Comando de verificacao

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

## Resultado

| Criterio | Resultado | Acao |
|---|---|---|
| Todos os 4 passos GOOD | PROSSEGUIR | Executar operacao de rede |
| Qualquer passo falhar | BLOQUEADO | NAO executar nada. Reportar ao Fernando. |

## Por que 4 passos e nao so 1?

| Passo | O que verifica | Por que e necessario |
|---|---|---|
| 1 | Atestado GOOD | Confirma que `session-start-hacking-security.sh` rodou e validou TUDO |
| 2 | WireGuard wg0 | VPN oficial do pesquisador (fail-closed: se tunel cai, trafego para) |
| 3 | torproxy-host | Container Docker que fornece Tor exit para o sandbox |
| 4 | verificar-vazamento.sh | Teste final: IP de saida != IP real, DNS sem ECS, IPv6 off |

## Integracao

- **AGENTS.md** secao 11: define a verificacao como obrigatorio
- **hacker-opsec-canon.md**: modulos session-start + verificacao-primaria
- **hacker-repo-profile.md**: secao 4 define a postura de protecao
- **GATE-DE-PROTECAO.md**: gate unitario com os 4 passos
- **Todos os agentes**: bloco bash padrao no pre-requisito
- **PIPELINE-COMPLETO.md**: pre-flight antes de cada etapa
