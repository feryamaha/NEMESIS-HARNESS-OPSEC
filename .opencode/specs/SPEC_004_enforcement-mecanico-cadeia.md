---
ciclo: SPEC_004
skill: hacker-specification-design
status: aprovada-para-plano
fonte: ISSUE-001-enforcement-mecanismo.md
last_updated: 2026-09-12
---

# SPEC_004: Enforcement mecanico da cadeia por permissao de execucao nos binarios de rede

> Requisito funcional da ISSUE-001, com abordagem aprovada por Fernando (2026-09-12):
> controle de permissao de execucao (chmod) nos proprios binarios de rede, em vez de
> wrapper por PATH + marcador por timestamp. O enforcement passa a ser do kernel
> (execve), nao de convencao de shell.

## REQUEST

Mover o enforcement de "regra comportamental" para "mecanismo de sistema" (fail-closed)
na camada de rede/processo: binario de rede NAO executavel pelo usuario fernando fora de
uma sessao segura GOOD, independente de caminho relativo, absoluto ou subprocesso.
Compativel com o fluxo autorizado (apos GOOD, binario liberado sem sudo).

## CATEGORY

Feature (cadeia de protecao). Envolve scripts de protecao em `~/opsec/scripts/` (classe C).

## PROBLEM (sintomas observaveis)

- Incidentes 2026-09-08 (gate GOOD com IPv6 real vazando; kill-switch inativo por `$HOME`
  sob sudo; WireGuard NAO_CONFIGURADO) e 2026-09-11 (hashes fabricados OP-20260911-001/002/003,
  placeholder aprovado, teste pratico sem gate) falsificaram a dependencia de um agente
  "bem-comportado" (fontes: `.opencode/issues/ISSUE-001-enforcement-mecanismo.md`, entradas 2026-09-11
  no `.opencode/ledger/trust-ledger.md`).
- `verificar-vazamento.sh` e self-auditing: e a medida da cadeia e o objeto que ja foi burlado.
- Estado atual nao bloqueia scanner com a cadeia apagada: `kill-switch.sh` so ativa sob
  `sudo bash` (EUID check, linhas 9-12) e `verificar-vazamento.sh` nao checa kill-switch sem
  root (linhas 94-104).

## CONTEXT

Fontes consultadas (RAG, hierarquia codigo > docs > regras):

- **Codigo real lido no momento:**
  - `~/opsec/scripts/kill-switch.sh` (51 linhas): `on` = `ip6tables -P OUTPUT DROP` +
    `iptables -P OUTPUT DROP` + ACCEPT lo/VPN_IFACE/udp VPN_PORT/conntrack (linhas 19-32);
    `off` restaura ACCEPT (linhas 37-45). `EUID -ne 0` -> exit 1 "Execute como root" (linhas 9-12).
  - `~/opsec/scripts/verificar-vazamento.sh` (121 linhas): `PASS()` -> `[GOOD]`, `FAIL()` ->
    `[LEAK]` (linhas 6-7); TESTE 1 valida `IP_TOR` via `check.torproject.org/api/ip` (linha 24);
    TESTE 3 IPv6; TESTE 5: `[GOOD]` se `IP_TOR` presente, senao `[LEAK]` (linhas 109-120).
    Sem root, kill-switch nao checado (linhas 102-104).
  - `~/opsec/scripts/session-start-hacking-security.sh` (143 linhas): Etapa 1 sessao segura;
    Etapa 2 WireGuard wg0 (exige `ATIVO` para GOOD); Etapa 3 verificar-vazamento; Etapa 4
    `bash -n` dos 5 scripts; decisao de GOOD/LEAK nas linhas 80-94; grava atestado + LEDGER.md.
    Roda como `sudo bash ...` (root).
  - `~/opsec/scripts/encerrar-sessao.sh` (22 linhas): kill-switch off + restaura IPv6 via sudo.
    Roda como usuario fernando, com `sudo` interno.
- **Binarios de rede alvo (estado real verificado por stat/readlink neste instante):**

  | binario | caminho real | modo | dono |
  |---|---|---|---|
  | nmap | /usr/bin/nmap | 755 | root:root |
  | masscan | /usr/bin/masscan | 755 | root:root |
  | curl | /usr/bin/curl | 755 | root:root |
  | zap-cli | /home/fernando/.local/share/pipx/venvs/zapcli/bin/zap-cli (symlink) | 775 | fernando:fernando |
  | nuclei | /usr/bin/nuclei | 755 | root:root |
  | sqlmap | /usr/share/sqlmap/sqlmap.py (symlink) | 755 | root:root |
  | msfconsole | /opt/metasploit-framework/bin/msfconsole (symlink) | 755 | root:root |
  | ssh | /usr/bin/ssh | 755 | root:root |
  | scrapy | ausente (nao instalado) | - | - |

- **Comportamento de chmod em symlink:** chmod segue o alvo (sem `-h`); aplica-se ao arquivo
  real resolvido.
- **Permissao e kernel:** root (CAP_DAC_OVERRIDE) executa mesmo sem x-bit; o usuario fernando
  (uid 1000) NAO. Logo o requisito "agente nao precisa de sudo nem root para fluxo autorizado"
  e satisfeito por: sessao GOOD concede x-bit (root executa o chmod, fernando usa o binario
  normalmente). Caminho absoluto e subprocess nao contornam: execve exige x-bit.
- **Dono do arquivo define o bit:** para binarios root:root usa `o-x` / `o+x`; para binario
  owned por fernando (zap-cli) usa `u-x` / `u+x` (de outro modo fernando continua executando
  como owner). A spec exige salvar o modo original e restaura-lo exato na saida.
- **Interacao com o pre-flight:** `verificar-vazamento.sh` usa curl (linhas 22-24). Dentro do
  fluxo autorizado ele roda dentro de `session-start` como root (CAP_DAC_OVERRIDE) e o curl
  segue executavel. Fora de sessao, com `o-x` em curl, um pre-flight isolado pelo usuario
  retornaria `[LEAK]` com "Permission denied" (fail-closed, comportamento esperado e
  seguro; registrar na documentacao).
- **Limites honestos da camada (declarados, nao ocultados):**
  1. O x-bit marca a FRONTEIRA da sessao (concedido pelo GOOD no inicio, revogado pelo
     encerrar). A vivacidade CONTINUA dentro da sessao e papel do kill-switch (iptables
     OUTPUT DROP), que a ISSUE-001 mantem como pre-requisito fisico. Se a cadeia cair no
     meio da sessao, o x-bit so e revogado no encerrar; quem bloqueia queda ao vivo e o
     kill-switch.
  2. Reboot/abrupta nao roda o encerrar: x-bit pode permanecer concedido apos reboot.
     Mitigacao minima (sem overengineering): documentar em GATE-DE-PROTECAO.md que
     `gate-enforcement.sh off` pode ser rodado manualmente a qualquer momento (so altera
     permissao, sem tocar rede ou estado da cadeia).
- **Fronteira com ISSUE-003 (cross-ref):** esta spec cobre o bloqueio fisico da ferramenta na
  camada rede/processo, FORA do runner. Orquestracao Gate>Operacao>Relatorio>Ledger e da
  ISSUE-003 (`.opencode/issues/ISSUE-003-automacao-camada-operacional.md`). Nao duplicar aqui.

## REQUIREMENTS

- **R1 (ajustado, marcador removido do mecanismo):** sem marcador de bloqueio por timestamp
  e sem wrapper por PATH. O registro de sessao no LEDGER.md/atestado permanece apenas
  informativo (comportamento ja existente do `session-start`). Mecanismo = permissao de
  execucao nos binarios.
- **R2 (novo, kernel enforcement):** `session-start-hacking-security.sh` concede execucao
  (+x) aos binarios de rede alvo APENAS quando `RESULTADO=GOOD` (verificar GOOD + WG wg0
  ATIVO + kill-switch ativo), via `chmod`, classe C. `encerrar-sessao.sh` revoga (-x) ao
  encerrar. Sem cadeia GOOD ativa, os binarios nao sao executaveis pelo usuario fernando,
  seja qual for o caminho ou forma de chamada (execve exige x-bit).
- **R3 (novo, lista e bit relativo):** lista fixa de alvos (nmap, masscan, curl, zap-cli,
  nuclei, sqlmap, msfconsole, ssh) resolvida por caminho real (readlink) no momento da
  execucao; binarios ausentes sao ignorados com aviso; `on` aplica `chmod <bit>+x` e `off`
  aplica `chmod <bit>-x`, ambos RELATIVOS ao modo atual do binario, sem salvar/restaurar o
  modo completo e sem depender de estado salvo (auto-corretivo apos reboot ou atualizacao
  de pacote: o proximo off sempre remove o x, qualquer que seja o modo de fabrica
  reinstalado); bit selecionado por dono (root: `o`, fernando: `u`). Log informativo em
  `~/opsec/run/gate-enforcement.log` registra acao/pid/data e nao decide a restauracao.
- **R4 (mantido):** escopo protegido do gate NAO e bloqueado: edicao de markdown, leitura
  de codigo, `bash -n`, `docker compose config` (nenhum binario fora da lista de R3 e
  alterado).
- **R5 (mantido):** apos GOOD e liberacao, o agente usa os binarios de rede SEM sudo.
- **R6 (mantido):** documentar a mudanca em `.hacker/gate/GATE-DE-PROTECAO.md`, no canon
  (`.opencode/rules/hacker-opsec-canon.md`, novo modulo de enforcement) e manter a fronteira
  com ISSUE-003 nas duas issues.

## FILES INVOLVED

- NOVO `~/opsec/scripts/gate-enforcement.sh` (on/off; lista de alvos, resolve readlink,
  aplica `+x`/`-x` relativo ao modo atual, escolhe bit por dono; log informativo). Classe C.
- MODIFY `~/opsec/scripts/session-start-hacking-security.sh`: invocar `gate-enforcement.sh on`
  apos `RESULTADO=GOOD` (pos linhas 80-94, antes da gravacao do atestado). Classe C.
- MODIFY `~/opsec/scripts/encerrar-sessao.sh`: invocar `sudo bash .../gate-enforcement.sh off`
  ao encerrar. Classe C.
- MODIFY `.hacker/gate/GATE-DE-PROTECAO.md`: documentar o enforcement por permissao.
- MODIFY `.opencode/rules/hacker-opsec-canon.md`: adicionar modulo "enforcement por
  permissao de execucao" na tabela da cadeia.

## RESTRICTIONS

- Scripts de protecao = area sensivel `opsec_sensitive` (perfil secao 1) = classe C (F4):
  PARAR e confirmar com Fernando antes de qualquer aplicacao; aplicar somente com a cadeia
  validada.
- Sudo e exclusivo do Fernando; o agente nao executa `sudo` nem altera permissao de arquivos
  de sistema por conta propria. A CONCESSAO/REVOGACAO so acontece nos scripts de sessao
  (executados pelo Fernando).
- Nenhum IP real / credencial / PII em scripts, marcadores ou docs (documentation-style).
- Nao tocar `docker-compose.yml`, Tor, gluetun, Proton (fora de escopo desta spec).
- Stack: bash apenas, sem novas dependencias de terceiros.
- Mudanca minima: nao refatorar `verificar-vazamento.sh` nem `kill-switch.sh`.

## EXPECTED DELIVERY

- `~/opsec/scripts/gate-enforcement.sh` com interacao `on|off`, lista de alvos, aplicacao
  de `+x`/`-x` relativo ao modo atual (sem estado salvo decidindo a restauracao), aviso
  para ausentes, log informativo.
- `session-start-hacking-security.sh` concede x-bit apos GOOD; `encerrar-sessao.sh` revoga.
- Documentacao em GATE-DE-PROTECAO.md e no canon.
- VERIFICATION (comandos do perfil):
  - `bash -n` em gate-enforcement.sh, session-start-hacking-security.sh, encerrar-sessao.sh: PASS.
  - `shellcheck` (quando disponivel): sem error atribuivel.
  - Teste SUNSET (F7), SEM rede, executado com confirmacao do Fernando (classe C, requer sudo):
    1. `gate-enforcement.sh off`: `test -x` falso para cada alvo presente; execucao direta
       (`/usr/bin/nmap --version`) retorna Permission denied para fernando.
    2. `gate-enforcement.sh on`: `test -x` verdadeiro para cada alvo; binario executa para o
       usuario sem sudo.
    3. `test -x` em /usr/bin/bash e /usr/bin/docker inalterados (escopo protegido preservado).
  - `git diff --check`: sem whitespace error.
  - Nenhuma acao de rede durante implementacao/teste; se qualquer passagem tocar rede,
    `bash ~/opsec/scripts/verificar-vazamento.sh` deve retornar GOOD antes.
- Casos de borda declarados: curl fora de sessao retorna [LEAK] no pre-flight isolado
  (esperado); reboot pode deixar x-bit concedido (mitigacao: `gate-enforcement.sh off` manual);
  queda ao vivo no meio da sessao e coberta por kill-switch, nao pelo x-bit.