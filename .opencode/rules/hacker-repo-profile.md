---
trigger: always_on
status: active
scope: canonical
last_updated: 2026-09-09
---

# Hacker Etico: Perfil do Repo e Validacao por fase

> Regra canonica, adaptada do Nemesis. Substitui o perfil stack do Nemesis pelas validacoes reais
> do ambiente opsec (bash/python3/docker) e fixa o pre-flight F1 de protecao.
> Destinatario: modelos de IA agenticos, nao o humano. Anti-invencao: validacao so com saida
> literal real (`.opencode/rules/hacker-epistemic-safety.md`).

## Objetivo

Definir o que e "validado" para este repo em cada fase do SDD pipeline, e a postura de protecao
obrigatoria antes de qualquer acao de rede.

## 1. Stack e areas sensiveis do repo

- **Linguagens/stack do repo:** bash (scripts), python3 (auxiliares), Docker/Compose (containers de
  protecao em `~/opsec/docker-compose.yml`), markdown (docs/ledgers). Nenhuma dessas tem toolchain
  no repo: o ambiente e `~/opsec/`.
- **Areas sensiveis (com flag `opsec_sensitive`):** qualquer mudanca em scripts de protecao
  (`~/opsec/scripts/kill-switch.sh`, `verificar-vazamento.sh`, `iniciar-sessao.sh`,
  `encerrar-sessao.sh`, `validar-dns-fix.sh`, `session-start-hacking-security.sh`) ou no `docker-compose.yml`. Mudancas que tocam a
  cadeia de protecao sao classe C (F4): PARAR e confirmar com Fernando, e so se aplicarem com a
  cadeia validada.
- **Credenciais:** `.env` nunca vai ao repo; o template e `.env.example`.

## 2. Validacao por arquivo/atributo (aplicar em toda a mudanca)

| atributo | ferramenta/comando | criterio de PASS |
|---|---|---|
| sintaxe bash | `bash -n <script>` | PASS se sem erro |
| lint bash | `shellcheck <script>` (quando disponivel) | sem erros de severidade "error" atribuiveis |
| sintaxe python3 | `python3 -m py_compile <arquivo>` | PASS se sem erro |
| compose | `docker compose -f ~/opsec/docker-compose.yml config` | PASS se sem erro de sintaxe |
| whitespace/git | `git diff --check` | sem whitespace error |
| click dados fornecidos | concorrencia de dados | sem valores vazios |

## 3. Validacao por fase (pos-changes)

| fase | o que roda |
|---|---|
| pos-spec | `bash -n` em scripts citados; conferir paths citados existem |
| pos-tarefa | validacao por atributo da mudanca (tabela acima) |
| pos-elab (Fase 4 da tests) | reavaliacao apos fix |
| pos-doc-sync | F10 (hacker-harness-integrity.md) se houve mudanca no harness; `git diff --check` |
| ante-finishing (Skill 5) | suite completa: `bash -n` em todos os scripts tocados, `docker compose config` se compose tocado, `git diff --check`, verificar-vazamento GOOD se houve acao de rede |

### 3.1 Nota de politica de processo (fast-path de baixo risco)

Decisao de Fernando (2026-09-12), incorporada sem ciclo proprio (Issue-004):
mudanca de baixo risco (1 arquivo, sem rede, sem sudo, sem area sensivel do
perfil, sem `docker-compose.yml`) pode pular gates redundantes do SDD, desde
que mantenha ao menos 1 validacao por atributo e o registro no ledger.
Classe C e area sensivel (scripts de protecao, cadeia, compose) sempre
full-process, com confirmacao explicita do Fernando.

## 4. Postura de protecao (pre-flight F1), ANTES de tocar rede, SEMPRE

**BLOQUEADO sem verificacao primaria.** Antes de QUALQUER operacao de rede,
o agente DEVE confirmar que o `session-start-hacking-security.sh` foi executado
e retornou GOOD.

### Verificacao primaria (OBRIGATORIA, rodar ANTES de cada operacao)

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

**Se QUALQUER passo falhar, o agente PARA e reporta. Nao prossiga.**

### Por que 4 passos e nao so 1?

| Passo | O que verifica | Por que e necessario |
|---|---|---|
| 1 | Atestado GOOD | Confirma que `session-start-hacking-security.sh` rodou e validou TUDO |
| 2 | WireGuard wg0 | VPN oficial do pesquisador (fail-closed: se tunel cai, trafego para) |
| 3 | torproxy-host | Container Docker que fornece Tor exit para o sandbox |
| 4 | verificar-vazamento.sh | Teste final: IP de saida != IP real, DNS sem ECS, IPv6 off |

### Script principal (pre-flight completo)

O `session-start-hacking-security.sh` ja executa TODOS estes passos internamente.
Quando o atestado e GOOD, significa que:
- Sessao segura ativa (IPv6 off, kill-switch, tunel)
- WireGuard wg0 ATIVO
- Container torproxy-host rodando
- Verificacao de vazamento GOOD
- Sintaxe dos 7 scripts validada

A verificacao primaria acima e uma **re-checagem rapida** para garantir que
o estado nao mudou desde o inicio da sessao.

Checagens pontuais quando pedido:

```bash
bash ~/opsec/scripts/validar-dns-fix.sh   # se existir suite; senao passo das dns
ip -br a                                   # wg0 presente? (WireGuard e VPN oficial)
```

## 5. O que NAO deve ser feito neste repo

Nenhuma mudanca toca arquivos fora de `~/opsec/` e de `.opencode/` deste repo sem pedido explicito
(registrar no ledger). Nenhuma action de rede sem verificar-vazamento GOOD. Nenhum dado real de IP
de origem/credencial em docs (hacker-documentation-style integração).

## 6. Leverage com o canon

O canon por modulo da cadeia: `.opencode/rules/hacker-opsec-canon.md`. Objetivo do canon: descrever o
estado esperado de cada modulo e a hierarquia de decisao (codigo > docs > regras). O perfil define
como VALIDAR; o canon define o que o sistema DEVE fazer.