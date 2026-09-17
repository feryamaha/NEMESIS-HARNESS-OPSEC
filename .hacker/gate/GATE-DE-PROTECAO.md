# Gate de Protecao Obrigatorio (Dark-Moon adaptado)

> REGRA UNITARIA INEGOCIÁVEL: toda operacao de rede de qualquer agente e
> INVALIDA sem esta checagem. Gate adaptado do ASCIT31/Dark-Moon.

## Verificacao Primaria (OBRIGATORIA - PRIMEIRO PASSO de QUALQUER agente)

**ANTES de qualquer comando de rede, o agente DEVE executar esta verificacao.**

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

## O que NÃO exige gate (escopo protegido)

- Edicao de arquivos markdown dentro de `.hacker/`, `.opencode/`, `~/opsec/README.md`
- Leitura/auditoria de codigo local (`cat`, `grep`, `git diff`)
- Execucao de `bash -n`, `shellcheck`, `py_compile`, `docker compose config` (validacoes locais)
- Qualquer comando que NAO faça conexão de rede

## O que EXIGE gate

- `curl`, `wget`, `requests`, `urllib` (HTTP/HTTPS)
- `nmap`, `masscan`, `zmap` (scan de rede)
- `zap-cli`, `zap-api-scan.py`, `java -jar zap.jar` (OWASP ZAP)
- `nuclei`, `httpx` (Nuclei scanner)
- `scrapy`, `playwright`, `selenium` (scraping web)
- Qualquer ferramenta de DAST que saia da maquina
- `msfconsole`, `metasploit`, `sqlmap` (exploit/autopwn)
- `ssh`, `telnet`, `ftp` (conexao remota)
- Qualquer execucao de ferramenta de pentest que saia da maquina
- Qualquer operacao dentro de containers que toque rede externa

### Enforcement físico (SPEC_004)

Alem da regra comportamental acima, o harness aplica enforcement de sistema na camada
rede/processo: os binarios de rede listados (nmap, masscan, curl, zap-cli, nuclei, sqlmap,
msfconsole, ssh) ficam nao executaveis para o usuario fernando fora de uma sessao segura GOOD.

- `session-start-hacking-security.sh` concede `+x` apos o resultado GOOD.
- `encerrar-sessao.sh` revoga (`-x`) ao encerrar.
- O enforcement e do kernel (execve exige x-bit), nao uma convencao de shell; caminho absoluto
  e subprocess nao contornam.

Limites honestos da camada:
- O x-bit marca a fronteira da sessao; a vivacidade da cadeia dentro da sessao e papel do
  kill-switch (auditoria do fail-closed do gluetun: policy OUTPUT DROP + regra ACCEPT do
  servidor VPN no netns).
- Reboot/abrupta pode deixar x-bit concedido ate o proximo `encerrar-sessao`; para reverter
  manualmente: `sudo bash ~/opsec/scripts/gate-enforcement.sh off`.
- Com curl sem execucao, um pre-flight isolado (`verificar-vazamento.sh` rodado fora da sessao)
  retorna [LEAK] por "Permission denied"; comportamento esperado e fail-closed.
- O kill-switch nao injeta regras proprias: AUDITA o firewall fail-closed do proprio gluetun
  (FIREWALL=on) no netns do container `gluetun`, onde vive o trafego de ataque; o host de
  administracao (OpenCode, navegador) nao e afetado (SPEC_005).
- Enquanto o container `gluetun` nao estiver operacional, o kill-switch emite WARN e nao
  aplica nada; a barreira do host fora de sessao e a nao-execucao dos binarios (SPEC_004).

Fonte: `.opencode/specs/SPEC_004_enforcement-mecanico-cadeia.md`.

## Segunda Leitura Independente (SPEC_006)

Alem do `verificar-vazamento.sh`, uma segunda leitura deterministica e independente
esta disponivel: `~/opsec/scripts/verificador-externo.sh`.

Comando (executar apos o atestado GOOD, com sudo):

```bash
bash ~/opsec/scripts/verificador-externo.sh
```

Resultado esperado:
- `[GOOD] VERIFICACAO INDEPENDENTE: CORROBORADO` se todos os vetores passaram.
- `[GAP] VERIFICACAO INDEPENDENTE: X vetor(es) NAO corroboraram` se houver divergencia.
  Nesse caso, reconciliar com o atestado e registrar no Trust Ledger (append-only, saida
  literal do GAP).

Fail-closed em 3 marcadores, todos checados ANTES de qualquer consulta externa:
- Tor local ouvindo na porta 9050 (`ss -ltn 'sport = :9050'`);
- `curl` localizavel e executavel (`command -v` + x-bit; fronteira da sessao via
  gate-enforcement, GATE acima);
- interface VPN `wg0`/`proton0` presente (`ip -br a`).
Sem qualquer um deles, o script emite `[GAP] Cadeia nao operacional` imediato
sem executar dig/curl (sem vazamento de IP real pela rota default).

Limitacao declarada: WebRTC real so e mensuravel dentro de navegador; o verificador
externo cobre as PRE-CONDICOES (IPv6 global ausente e proxy SOCKS5 configurado no shell)
mas nao substitui o teste manual no navegador (`https://browserleaks.com/webrtc`).

Fonte: `.opencode/specs/SPEC_006_validacao-externa-nao-self-auditing.md`.

## Privacidade (Dark-Moon)

O agente NUNCA recebe o IP real de origem. Em relatorios e registros:
- Cite SEMPRE o IP de saida (WireGuard/Proton/Tor), NUNCA o IP real.
- Nao grave o IP real em ledgers, reports ou templates.
- Se o verificar-vazamento.sh exigir citar um IP, cite o IP de saida.

## Integracao com orquestrador

O orquestrador aplica este gate ANTES de cada operacao de rede, antes de despachar ao agente.
O runner (`.hacker/scripts/runner.sh`) valida o gate comportamental antes do fechamento do ciclo. O enforcement fisico (x-bit) e responsabilidade da ISSUE-001.
A operacao e invalida se o gate nao for executado.
## HARNESS GUARDIAN (Camada Final de Protecao do Controle Humano)

O HARNESS GUARDIAN e a camada final de protecao do controle humano. Se a cadeia quebra, o Loop e o Graph sao pausados automaticamente. Nenhum mecanismo de automacao sobrepoe o gate.

- O HARNESS GUARDIAN monitora a cadeia de protecao (verificar-vazamento.sh GOOD)
- Se a cadeia muda de GOOD para LEAK durante o Loop -> HARNESS GUARDIAN pausa tudo
- O Loop itera, mas nao autoriza acoes de classe C
- O Routing direciona, mas nao altera o escopo definido pelo Fernando
- O orquestrador delega, mas nao decide escopo
- Fernando permanece como DECISOR E ARQUITETO UNICO — o Graph/Loop sao ferramentas de execucao dentro do escopo autorizado

```bash
# Verificacao do HARNESS GUARDIAN
bash .hacker/scripts/gate-preflight.sh
# 0=PASS (cadeia ativa), 1=FAIL (cadeia comprometida)
```
