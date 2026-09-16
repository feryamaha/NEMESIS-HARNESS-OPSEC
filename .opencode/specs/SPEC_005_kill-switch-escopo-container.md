---
ciclo: SPEC_005
skill: hacker-specification-design
status: aprovada-para-plano
fonte: ISSUE-008-kill-switch-escopo-host-vs-container.md
last_updated: 2026-09-12
---

# SPEC_005: Escopar o kill-switch ao namespace de rede do container (Opcao A)

> Correcao da ISSUE-008, abordagem aprovada por Fernando (2026-09-12): o DROP de saida
> e aplicado no namespace de rede do container (gluetun/kali), onde o trafego de ATAQUE vive,
> e NAO no OUTPUT do host (que derruba OpenCode/Chrome/Firefox sem necessidade).

## REQUEST

Impedir que o kill-switch derrube a internet do host (processos administrativos: OpenCode,
Chrome) durante a sessao segura, mantendo a barreira fisica fail-closed para o trafego de
ataque que sai da sandbox. O firewall de OUTPUT passa a operar no netns do container, nao no
host inteiro.

## CATEGORY

Defeito (cadeia de protecao). Toca `~/opsec/scripts/kill-switch.sh` e
`~/opsec/scripts/verificar-vazamento.sh` (classe C). Envolve Docker/netns.

## PROBLEM (sintomas observaveis, evidencia literal)

- Com `kill-switch.sh on`, o `iptables -P OUTPUT DROP` derruba TODA conexao NOVA do host
  (kill-switch.sh linhas 19-27: ACCEPT somente lo, VPN_IFACE, udp/VPN_PORT por LAN_IFACE,
  ESTABLISHED/RELATED). OpenCode/Chrome saem por wlan0 (rota default real)
  e sao dropados; Firefox segue por conexoes ESTABLISHED previas.
- O trafego de ATAQUE roda DENTRO da sandbox Docker: kali e tor-on-vpn usam
  `network_mode: service:gluetun` (docker-compose.yml linhas 43-46 e 48-54), ou seja vivem
  no netns do gluetun. Esse trafego atravessa o host via chains FORWARD/POSTROUTING (NAT),
  NAO pela OUTPUT do host. O `-P OUTPUT DROP` do host portanto NAO protege o ataque (que
  passa por FORWARD) e apenas mata processos do proprio host.
- Hoje os containers da cadeia NAO estao em runtime (imagens ausentes, `.env` com
  OPENVPN_USER/OPENVPN_PASSWORD vazios, `docker ps -a` sem gluetun/kali/tor): o DROP do host
  corta a internet do host mesmo sem haver trafego de ataque ativo para proteger.
- `verificar-vazamento.sh` TESTE 4.5 (linhas 94-99) checa DROP na OUTPUT do HOST
  (`iptables -L OUTPUT`) como criterio de kill-switch ativo; mantido o escopo antigo, esse
  teste ficaria falso se o DROP sair do host.

## CONTEXT

Fontes consultadas (RAG, hierarquia codigo > docs > regras):

- `~/opsec/scripts/kill-switch.sh` (51 linhas, lido no momento): `on` aplica
  `ip6tables -P OUTPUT DROP` e `iptables -P OUTPUT DROP` no host + ACCEPTs; `off` restaura
  ACCEPT e faz flush. EUID check obriga root (linhas 9-12).
- `~/opsec/scripts/iniciar-sessao.sh` (56 linhas): passo 3 chama `kill-switch.sh on`
  (linha 47) via sudo; passo 4 roda `verificar-vazamento.sh` (linha 52).
- `~/opsec/scripts/session-start-hacking-security.sh` (143 linhas): Etapa 1 roda
  iniciar-sessao (que liga o kill-switch); Etapa 2 exige wg0 ATIVO; Etapa 3 verifica
  vazamentos; decidiu GOOD/LEAK nas linhas 80-94.
- `~/opsec/docker-compose.yml` (62 linhas): gluetun (rede propria, `cap_add NET_ADMIN`,
  `DOT=on`), tor-host (9050), tor-on-vpn (`network_mode: service:gluetun`), kali
  (`network_mode: service:gluetun`). A cadeia Proton/Tor mais os procs de ataque vivem no
  netns do gluetun; o host alcanca so via `127.0.0.1:8888/8118/9050`.
- Estado de runtime no momento (comandos reais): `docker ps -a` so mostra `zap-juice` e
  `juice-shop` (frames externos do lab), nenhum container do opsec; `docker images` sem
  gluetun/torproxy/kali; `.env` com chaves OPENVPN_USER/OPENVPN_PASSWORD vazias. Ou seja,
  a cadeia opsec nao esta operacional neste instante.
- `verificar-vazamento.sh` (121 linhas): TESTE 1 depende de Tor `127.0.0.1:9050` para
  GOOD; sem o container, `IP_TOR` vazio, resultado final LEAK (fail-closed com a cadeia
  apagada, comportamento correto).
- Ferramentas disponiveis no host: `nsenter` (/usr/bin/nsenter), `iptables` v1.8.13,
  `docker`.

## Decisao de abordagem (Opcao A) e emenda 2026-09-13 (auditoria)

Abordagem original (Opcao A, 2026-09-12): escopar o firewall de saida ao namespace de rede do
container onde o ATAQUE roda, deixando a OUTPUT do host intocada. Na pratica, aplicar DROP no
netns via iptables proprio.

EMENDA 2026-09-13 (aprovada por Fernando): a aplicacao de DROP proprio no netns foi
DESCARTADA. Evidencia no codigo-fonte do gluetun e na issue qdm12/gluetun#2038: a regra
`OUTPUT -d <servidor VPN> -o <interface fisica> -p <proto> -m <proto> --dport <porta> -j ACCEPT`
(criada por `AcceptOutputTrafficToVPN` em internal/firewall/iptables/iptables.go, chamada por
`allowVPNIP` em internal/firewall/enable.go) e a excecao que permite o handshake/reconexao da
VPN sair do netns pela interface fisica antes do tun existir (o tun so e criado no start,
internal/vpn/run.go; conntrack ESTABLISHED nao cobre fluxo NEW). Um `iptables -F OUTPUT` +
policy DROP proprio apagaria essa excecao e bloquearia o proprio handshake da VPN. Confirmado
sem override: docker-compose.yml sem FIREWALL=off (linha 17 so define FIREWALL_VPN_INPUT_PORTS),
`.env` sem variavel FIREWALL, default do gluetun FIREWALL=on.

Nova abordagem (auditoria): o kill-switch NAO toca em regras. Ele AUDITA o firewall
fail-closed do proprio gluetun (FIREWALL=on, default) no netns do container:

- `kill-switch.sh on`: resolve o PID do container `gluetun` (`docker inspect -f
  '{{.State.Pid}}' gluetun`) e verifica via `nsenter -t <PID> -n -- iptables -S OUTPUT`
  (somente leitura): policy OUTPUT DROP presente E regra ACCEPT do servidor VPN via interface
  fisica presente. PASS se ambos; FAIL caso contrario (exit 1). Nenhuma insercao, flush ou
  mudanca de policy.
- Se o container gluetun NAO estiver ativo (estado atual), `kill-switch.sh on` emite WARN e
  exit 0 ("sem trafego de ataque em runtime; auditoria nao aplicada"). `off` e informativo:
  nada proprio a restaurar (remove state legacy do desenho antigo, se existir).
- `verificar-vazamento.sh` TESTE 4.5 faz a MESMA auditoria (policy DROP + ACCEPT do endpoint
  no netns via nsenter) quando o container estiver ativo e o script rodar com privilegio; sem
  container, resultado neutro (sem falsificar GOOD nem LEAK a partir do host).
- Mantem-se inviolavel: fora de sessao GOOD, o host nao executa binarios de rede (camada
  deles e o gate-enforcement/SPEC_004).

Limites honestos da camada (declarados nesta spec):
- A barreira fail-closed REAL do netns e o firewall do proprio gluetun (FIREWALL=on, regra do
  endpoint + policy DROP, instalado antes do cliente VPN e nunca derrubado). Este script apenas
  AUDITA a presenca dessas regras; nao substitui nem adiciona barreira.
- Se o gluetun for iniciado com FIREWALL=off (nao e o caso atual), a auditoria falha (FAIL) e
  a sessao nao deve ser considerada segura ate isso ser resolvido.
- Enquanto a cadeia nao estiver operacional (containers down), nao ha trafego de ataque
  rodando; o kill-switch nao bloqueia host nem netns. O fail-closed para o HOST fora de sessao
  e garantir a nao-execucao dos binarios (SPEC_004), nao um DROP de rede.

## REQUIREMENTS

- R1: `kill-switch.sh on` NAO aplica regra alguma na OUTPUT do host (iptables/ip6tables do
  host permanecem ACCEPT/padrao).
- R2: quando `gluetun` ativo, `on` AUDITA o netns do gluetun via `nsenter` (somente leitura):
  policy OUTPUT DROP presente E regra ACCEPT do servidor VPN via interface fisica presente
  (a que o proprio gluetun cria com FIREWALL=on). PASS se ambos, FAIL (exit 1) caso contrario;
  sem inserir, sem flush, sem mudanca de policy no netns.
- R3: quando `gluetun` NAO ativo, `on` emite WARN e exit 0 (nada a proteger, nada a auditar).
- R4: `off` e informativo: remove o state file legacy do desenho antigo (se existir); nao ha
  regras proprias a restaurar; exit 0.
- R5: `verificar-vazamento.sh` TESTE 4.5 audita o mesmo criterio (policy DROP + ACCEPT do
  endpoint) no netns do gluetun (nsenter, container ativo e com privilegio) ou reporta
  neutro/nao se aplica (container ausente); nao usa a OUTPUT do host como criterio.
- R6: documentacao atualizada (canon linha do kill-switch, GATE-DE-PROTECAO e/ou README do
  opsec) refletindo a abordagem auditor, sem travessao e sem IP real.

## FILES INVOLVED

- MODIFY: `~/opsec/scripts/kill-switch.sh` (nucleo R1-R4)
- MODIFY: `~/opsec/scripts/verificar-vazamento.sh` (TESTE 4.5, R5)
- MODIFY: `.opencode/rules/hacker-opsec-canon.md` (linha do modulo kill-switch, R6)
- MODIFY: `.hacker/gate/GATE-DE-PROTECAO.md` (mencao do escopo do kill-switch, R6)
- TEST (runtime): comando com sudo do Fernando, sem rede, quando a cadeia operacional existir

## RESTRICTIONS

- Classe C: confirmacao explicita de Fernando obtida (Opcao A, 2026-09-12). Nenhuma outra
  mudanca de escopo por conta propria.
- Sudo executado somente pelo Fernando; o agente nao roda sudo nem altera firewall/host.
- Não alterar wg0.conf, Proton, Tor, gluetun, docker-compose, nem o `.env`.
- Nao tocar rede para validar; a validacao de runtime do netns fica para quando a cadeia
  estiver operacional (Fernando), com suite sem rede.
- Bash somente; seguir o perfil do repo (validacao `bash -n`);
- Registrar no Trust Ledger (invariante 11).

## EXPECTED DELIVERY

- `kill-switch.sh on`: auditoria somente-leitura do fail-closed do gluetun no netns (policy
  OUTPUT DROP + regra ACCEPT do endpoint); container ausente: WARN exit 0; host e netns nunca
  tocados. `off`: informativo (sem regras proprias a restaurar).
- `verificar-vazamento.sh` TESTE 4.5 com o mesmo criterio de auditoria; sem falso-negativo/
  acerto baseado na OUTPUT do host.
- Teste SUNSET (F7) via Fernando (sudo, sem rede): com gluetun ausente, `on` emite WARN exit 0
  e o host continua funcional; com a cadeia operacional e FIREWALL=on, `on` reporta PASS
  (policy + endpoint presentes no netns) e `off` e informativo.
- Docs (canon + GATE-DE-PROTECAO) sincronizadas com a abordagem auditor.
- Entradas no Trust Ledger: decisao (2026-09-13), validacao, doc-sync.