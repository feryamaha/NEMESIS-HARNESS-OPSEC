# Enforcement mecânico da cadeia por permissão de execução - Plano de Implementação

> **Para agentes**: Use hacker-subagent-driven-development para executar este plano.

**Objetivo**: Tornar os binários de rede não executáveis para o usuário fernando fora de uma
sessão segura GOOD, via controle de permissão de execução (chmod) concedido pelo
`session-start-hacking-security.sh` e revogado por `encerrar-sessao.sh`.

**Spec**: `.opencode/specs/SPEC_004_enforcement-mecanico-cadeia.md`

**Arquivos Afetados**:
- CREATE: `~/opsec/scripts/gate-enforcement.sh`
- MODIFY: `~/opsec/scripts/session-start-hacking-security.sh`
- MODIFY: `~/opsec/scripts/encerrar-sessao.sh`
- MODIFY: `.hacker/gate/GATE-DE-PROTECAO.md`
- MODIFY: `.opencode/rules/hacker-opsec-canon.md`

**Arquitetura**: Script novo `gate-enforcement.sh` recebe `on|off`. `on` resolve a lista fixa
de binários de rede (nmap, masscan, curl, zap-cli, nuclei, sqlmap, msfconsole, ssh) por caminho
real (readlink) e aplica `chmod <bit>+x` relativo ao modo atual; `off` aplica `chmod <bit>-x`
relativo ao modo atual (bit por dono: `o` para root, `u` para fernando). NENHUM modo é salvo
para decidir restauração: o desenho é auto-corretivo após reboot ou atualização de pacote (o
próximo off sempre remove o x, qualquer que seja o modo de fábrica), e mexe só no bit de
execução, sem apagar outros bits. Um log informativo (ação/pid/data) vai para
`~/opsec/run/gate-enforcement.log` e não decide restauração. O `session-start-hacking-security.sh`
chama `gate-enforcement.sh on` somente após `RESULTADO=GOOD`; `encerrar-sessao.sh` chama
`gate-enforcement.sh off` ao encerrar. Enforcement é do kernel (execve exige x-bit), sem
convenção de shell e sem estado stale.

**Stack**: bash (perfil do repo). Sem dependências novas.

**Autenticação**: sudo executado somente pelo Fernando; os scripts de sessão são os únicos
pontos de concessão/revogação. O agente não executa `sudo` nem altera permissões de arquivos
de sistema por conta própria.

---

## TASK 1: Criar o script de enforcement de permissões (gate-enforcement.sh)

**Arquivo**: `~/opsec/scripts/gate-enforcement.sh`

**Arquivos**:
- CREATE: `~/opsec/scripts/gate-enforcement.sh`

**Depende de**: nenhuma

**Verificação**:
```bash
bash -n ~/opsec/scripts/gate-enforcement.sh
```

**Descrição Detalhada**:
Criar o script que concede/revoga a permissão de execução dos binários de rede listados na spec,
na Opção C (decisão 2026-09-13): opera no bit de execução RELATIVO ao modo atual, sem
salvar/restaurar modo completo. Lista fixa: nmap, masscan, curl, zap-cli, nuclei, sqlmap,
msfconsole, ssh. Para cada binário:
1. Resolver o caminho real com `readlink -f` (segue symlinks de zap-cli/sqlmap/msfconsole).
2. Se o binário não existe (`command -v` vazio), emitir WARN e pular (ausente não está na lista).
3. Determinar o dono com `stat -c %U`; escolher o bit: `o` se dono != fernando, `u` se dono == fernando.
4. `on`: aplicar `chmod <bit>+x` RELATIVO ao modo atual (soma só o bit de execução; nunca
   sobrescreve o modo completo).
5. `off`: aplicar `chmod <bit>-x` RELATIVO ao modo atual (remove só o bit de execução; idem).
6. Registrar log informativo em `~/opsec/run/gate-enforcement.log` com data/hora, ação
   (on/off), PID e usuário; o log NÃO decide restauração.

Restrições: usar caminhos entre aspas; `set -uo pipefail`; caminho absoluto fixo
`/home/fernando/opsec/run/...` (sem depender de `$HOME`, que sob sudo aponta para `/root`).

**Implementação** (o código do disco, fiel):
```bash
#!/usr/bin/env bash
# gate-enforcement.sh - concede/revoga execucao de binarios de rede conforme a sessao segura.
# Opcao C (decisao 2026-09-13): opera no bit de execucao RELATIVO ao modo atual.
#   on  = chmod <bit>+x  (libera, chamado por session-start-hacking-security.sh apos GOOD)
#   off = chmod <bit>-x  (bloqueia, chamado por encerrar-sessao.sh)
# Sem salvamento/restauracao de modo completo e sem depender de estado salvo:
# auto-corretivo apos reboot ou atualizacao de pacote (o proximo off sempre
# remove o x, qualquer que seja o modo de fabrica reinstalado) e nunca
# sobrescreve outros bits do arquivo.
# Log informativo em ~/opsec/run/gate-enforcement.log (acao/pid/data), nao
# decide a restauracao.
set -uo pipefail

USUARIO="fernando"
RUN_DIR="/home/fernando/opsec/run"
LOG_FILE="$RUN_DIR/gate-enforcement.log"
BINARIOS=(nmap masscan curl zap-cli nuclei sqlmap msfconsole ssh)

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
PASS() { echo -e "${GREEN}[PASS]${NC} $*"; }
WARN() { echo -e "${YELLOW}[!]${NC} $*"; }
FAIL() { echo -e "${RED}[FAIL]${NC} $*"; }

escolher_bit() {
  local caminho="$1"
  local dono
  dono=$(stat -c %U "$caminho" 2>/dev/null)
  if [ "$dono" = "$USUARIO" ]; then echo "u"; else echo "o"; fi
}

aplicar() {
  local op="$1"
  for b in "${BINARIOS[@]}"; do
    local real alvo bit
    real=$(command -v "$b" 2>/dev/null)
    [ -z "$real" ] && { WARN "Binario ausente: $b (ignorado)"; continue; }
    alvo=$(readlink -f "$real")
    [ -e "$alvo" ] || { WARN "Alvo nao existe: $alvo"; continue; }
    bit=$(escolher_bit "$alvo")
    chmod "${bit}${op}" "$alvo"
    if [ "$op" = "+x" ]; then
      PASS "Execucao liberada: $alvo ($bit+x)"
    else
      PASS "Execucao bloqueada: $alvo ($bit-x)"
    fi
  done
}

registrar_log() {
  local acao="$1"
  mkdir -p "$RUN_DIR"
  printf '%s | acao=%s | pid=%s | usuario=%s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$acao" "$$" "${SUDO_USER:-$USER}" >> "$LOG_FILE"
}

on() {
  aplicar "+x"
  registrar_log "on"
}

off() {
  aplicar "-x"
  registrar_log "off"
}

ACTION="${1:-}"
case "$ACTION" in
  on) on ;;
  off) off ;;
  *) echo "Uso: bash $0 {on|off}"; exit 1 ;;
esac
```

---

## TASK 2: Invocar gate-enforcement.sh on no session-start após GOOD

**Arquivo**: `~/opsec/scripts/session-start-hacking-security.sh`

**Arquivos**:
- MODIFY: `~/opsec/scripts/session-start-hacking-security.sh` (linhas 84-94)

**Depende de**: TASK 1

**Verificação**:
```bash
bash -n ~/opsec/scripts/session-start-hacking-security.sh
```

**Descrição Detalhada**:
No bloco que define `RESULTADO` (linhas 80-94), quando `RESULTADO="GOOD"` (linha 85-86), invocar
`bash "$SCRIPTS_DIR/gate-enforcement.sh" on` após o PASS de ambiente seguro. Não invocar em LEAK
nem INDETERMINADO. Como o script roda via `sudo`, o chmod é aplicado com privilégio; binários
liberados para o usuário fernando. Inserir o bloco entre as linhas 86 e 87 (depois do meu PASS e
antes do `elif`).

**Implementação** (inserir após o bloco do PASS, antes do `elif`):
```bash
  else
    PASS "Ambiente seguro (GOOD). Pode iniciar hacking."
    RESULTADO="GOOD"
    bash "$SCRIPTS_DIR/gate-enforcement.sh" on
  fi
```

---

## TASK 3: Invocar gate-enforcement.sh off no encerrar-sessao

**Arquivo**: `~/opsec/scripts/encerrar-sessao.sh`

**Arquivos**:
- MODIFY: `~/opsec/scripts/encerrar-sessao.sh` (linhas 13-19)

**Depende de**: TASK 1

**Verificação**:
```bash
bash -n ~/opsec/scripts/encerrar-sessao.sh
```

**Descrição Detalhada**:
No bloco de encerramento, após desativar kill-switch e restaurar IPv6 (linha 19), adicionar a
revogação de execução dos binários via sudo (o script roda como usuário fernando; é preciso
`sudo` para chmod em binários root). Substituir o final do script para ter 3 passos:

**Implementação** (substituir o trecho após a linha 18):
```bash
echo -e "${YELLOW}[2/3]${NC} Reativando IPv6 na interface $IFACE..."
sudo sysctl -w net.ipv6.conf.all.disable_ipv6=0 >/dev/null
sudo sysctl -w net.ipv6.conf."$IFACE".disable_ipv6=0 >/dev/null
echo -e "${GREEN}[OK]${NC} IPv6 restaurado"

echo -e "${YELLOW}[3/3]${NC} Revogando execucao dos binarios de rede..."
sudo bash "/home/fernando/opsec/scripts/gate-enforcement.sh" off

echo ""
echo -e "${GREEN}Sessão segura ENCERRADA.${NC} Rede normal restaurada. Binarios de rede bloqueados."
```

---

## TASK 4: Documentar o enforcement em GATE-DE-PROTECAO.md

**Arquivo**: `.hacker/gate/GATE-DE-PROTECAO.md`

**Arquivos**:
- MODIFY: `.hacker/gate/GATE-DE-PROTECAO.md` (secao "O que EXIGE gate", apos linha 44)

**Depende de**: TASK 1

**Verificação**:
```bash
bash -n ~/opsec/scripts/gate-enforcement.sh && grep -n "Enforcement físico\|gate-enforcement" .hacker/gate/GATE-DE-PROTECAO.md
```

**Descrição Detalhada**:
Completar o gate com o enforcement físico: além da regra comportamental, os binários de rede
listados ficam não executáveis fora da sessão GOOD (x-bit revogado por encerrar-sessao). Adicionar
nota dos limites honestos (reboot pode manter x-bit; queda ao vivo é coberta por kill-switch;
curl fora de sessão torna o pre-flight isolado [LEAK], esperado). Sem travessão; sem primeira
pessoa.

**Implementação** (adicionar ao final da secao "O que EXIGE gate"):
```md
### Enforcement físico (SPEC_004)

Alem da regra comportamental acima, o harness aplica enforcement de sistema na camada
rede/processo: os binarios de rede listados (nmap, masscan, curl, zap-cli, nuclei, sqlmap,
msfconsole, ssh) ficam nao executaveis para o usuario fernando fora de uma sessao segura GOOD.

- `session-start-hacking-security.sh` concede `+x` apos o resultado GOOD.
- `encerrar-sessao.sh` revoga (`-x`) ao encerrar.
- O enforcement e do kernel (execve exige x-bit), nao uma convencao de shell; caminho absoluto
  e subprocess nao contornam.

Limites honestos da camada:
- O x-bit marca a fronteira da sessao; a vivacidade continua da cadeia dentro da sessao e papel
  do kill-switch (OUTPUT DROP).
- Reboot/abrupta pode deixar x-bit concedido ate o proximo `encerrar-sessao`; para reverter
  manualmente: `sudo bash ~/opsec/scripts/gate-enforcement.sh off`.
- Com curl sem execucao, um pre-flight isolado (`verificar-vazamento.sh` rodado fora da sessao)
  retorna [LEAK] por "Permission denied"; comportamento esperado e fail-closed.

Fonte: `.opencode/specs/SPEC_004_enforcement-mecanico-cadeia.md`.
```

---

## TASK 5: Adicionar o modulo de enforcement no canon da cadeia

**Arquivo**: `.opencode/rules/hacker-opsec-canon.md`

**Arquivos**:
- MODIFY: `.opencode/rules/hacker-opsec-canon.md` (tabela de modulos, apos linha 40)

**Depende de**: TASK 1

**Verificação**:
```bash
grep -c "gate-enforcement" .opencode/rules/hacker-opsec-canon.md
```

**Descrição Detalhada**:
Adicionar linha na tabela de cadastro canônico por módulo para o novo módulo de enforcement.
Estado esperado: x-bit concedido quanto sessão segura ativa (chamado pelo session-start após GOOD);
revogado ao encerrar (encerrar-sessao). Artefato de consulta: `~/opsec/scripts/gate-enforcement.sh`.

**Implementação** (adicionar linha na tabela, apos session-start):
```md
| gate-enforcement (permissao) | enforcement fisico de execucao dos binarios de rede (nmap, masscan, curl, zap-cli, nuclei, sqlmap, msfconsole, ssh) pelo usuario fernando, via chmod do x-bit | x-bit concedido pelo `session-start-hacking-security.sh` apos GOOD (`on` = `chmod <bit>+x`); x-bit removido por `encerrar-sessao.sh` ao encerrar (`off` = `chmod <bit>-x`); on/off operam no bit de execucao RELATIVO ao modo atual, sem estado salvo (auto-corretivo apos reboot ou atualizacao de pacote); log informativo em `~/opsec/run/gate-enforcement.log` | `~/opsec/scripts/gate-enforcement.sh` |
```

---

## TASK 6: Teste SUNSET do enforcement (F7), sem rede

**Arquivo**: comando de execucao; rodado junto com a validacao de postura

**Arquivos**:
- TEST: executar `gate-enforcement.sh` on/off com permisoes aferidas por `test -x`

**Depende de**: TASK 2, TASK 3

**Verificação**:
```bash
# Requer sudo do Fernando (classe C). Sem rede. Ordem:
sudo bash ~/opsec/scripts/gate-enforcement.sh off     # fecha a brecha: remove o x (Opcao C)
test -x /usr/bin/nmap && echo "BLOQUEIO FALHOU" || echo "OK nmap bloqueado"
sudo bash ~/opsec/scripts/gate-enforcement.sh on
test -x /usr/bin/nmap && echo "OK nmap liberado" || echo "LIBERACAO FALHOU"
test -x /usr/bin/bash && echo "OK bash intocado" || echo "BASH FOI AFETADO (FALHA)"
test -x /usr/bin/docker && echo "OK docker intocado" || echo "DOCKER FOI AFETADO (FALHA)"
sudo bash ~/opsec/scripts/gate-enforcement.sh off     # bloqueia de novo
test -x /usr/bin/nmap && echo "BLOQUEIO FALHOU" || echo "OK nmap bloqueado de novo"
```

**Descrição Detalhada**:
Executado pelo Fernando com sudo (classe C), conforme confirmacao explicita previa obrigatoria.
O primeiro `off` fecha a brecha atual: os binarios estao com x-bit ligado por causa do ultimo
`off` antigo (que restaurou 755 executavel). Testa: (1) bloqueio com `off`, relativo ao modo
atual (remove o x); (2) liberacao com `on`; (3) escopo protegido preservado (bash/docker);
(4) bloqueio de novo apos o segundo `off` (auto-corretivo, sem depender de estado salvo).
Nenhuma destas etapas toca rede. Deve ser o ultimo passo do ciclo, apos suite do perfil.

---

## Verificação final (suite do perfil, ante-finishing)

```bash
bash -n ~/opsec/scripts/gate-enforcement.sh ~/opsec/scripts/session-start-hacking-security.sh ~/opsec/scripts/encerrar-sessao.sh
grep -n "gate-enforcement" .hacker/gate/GATE-DE-PROTECAO.md .opencode/rules/hacker-opsec-canon.md ~/opsec/scripts/session-start-hacking-security.sh ~/opsec/scripts/encerrar-sessao.sh
bash ~/opsec/scripts/verificar-vazamento.sh   # GOOD antes de QUALQUER acao de rede
```