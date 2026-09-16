# ISSUE-008: Kill-switch bloqueia o OUTPUT do host inteiro, mas só o container carrega tráfego anonimizado

> **STATUS: CORRIGIDA E FECHADA (2026-09-14).**
> Registrada em 2026-09-12 a partir de diagnóstico com evidência real (F1/F3). Decisão de
> correção: OPCAO A aprovada por Fernando (2026-09-12), emendada em 2026-09-13 para abordagem
> AUDITOR (detalhe em SPEC_005/PLAN_005). Implementação concluída e fechada via doc-sync
> em 2026-09-14. Validação de runtime com a cadeia operacional fica registrada como
> pendência declarada na SPEC_005 (não bloqueia o fechamento).

## Contexto

O kill-switch (`~/opsec/scripts/kill-switch.sh`) aplica `iptables -P OUTPUT DROP` no HOST
(namespace do kernel) quando a sessão segura é iniciada. Porém a cadeia de anonimato do
pentest (Proton/Tor/proxy) roda DENTRO do container gluetun, em namespace de rede isolado;
o host enxerga apenas as portas bindadas em `127.0.0.1:8888`/`8118` (gluetun) e `127.0.0.1:9050`
(tor-host). O trafego comum do host (OpenCode, navegador de administração) não usa gluetun:
hoje a rota default real é via `wlan0` (192.168.1.1), com wg0 carregando apenas `10.0.0.0/24`.

Resultado: ao ativar o kill-switch, o host inteiro perde conexões NOVAS (qualquer pacote que
não saia por lo/VPN_IFACE/udp-51820-LAN/ESTABLISHED é dropado), incluindo o processo do
OpenCode e do navegador, que nunca deveriam ser afetados. O Firefox "continua às vezes" apenas
por conexões ESTABLISHED anteriores ao bloqueio.

## Evidência (F1/F3, literal)

- `kill-switch.sh on` linhas 19-27: `ip6tables -P OUTPUT DROP`; `iptables -P OUTPUT DROP`;
  ACCEPT somente lo, `$VPN_IFACE`, `udp --dport 51820 -o $LAN_IFACE`, `m conntrack ESTABLISHED,RELATED`.
- `~/opsec/docker-compose.yml`: `kali` e `tor-on-vpn` usam `network_mode: service:gluetun`;
  gluetun expõe `127.0.0.1:8888`/`8118`. Host interage com a cadeia só via loopback.
- `ip route show` real (2026-09-12): `default via 192.168.1.1 dev wlan0`; `10.0.0.0/24 dev wg0`
  (APENAS a sub-rede privada no wg0; sem rota default via wg0).
- `wg0.conf` (lido com sudo pelo Fernando 2026-09-12): `[Interface]` PrivateKey/Address
  10.0.0.2/24/ListenPort 51820; **sem bloco `[Peer]`/AllowedIPs** = túnel local sem rota para
  internet geral (não é full-tunnel).
- `iptables -S OUTPUT` (sudo, 2026-09-12): `-P OUTPUT ACCEPT` (capturado fora do estado GOOD;
  apenas confirma que a captura foi feita com kill-switch desligado).

## Problema observável

- Com kill-switch ativo, o tráfego NOVO do host (OpenCode, Chrome, qualquer app do host) é
  bloqueado, mesmo sendo tráfego que não tem relação com o pentest.
- A garantia de anonimato do tráfego de ATAQUE (a razão do kill-switch existir) é satisfeita
  pelo container gluetun em namespace isolado; o DROP no OUTPUT do host bloqueia processos
  que nunca deveriam ser afetados. Defeito de escopo, não proteção intencional.
- Comunicação com o próprio Fernando (via OpenCode) pode cair exatamente no momento em que o
  ambiente fica operacional (GOOD), inclusive impedindo reportar falha ou pedir o "off".

## Defeito a corrigir (candidato)

Escopo do bloqueio: host inteiro vs tráfego de ataque. Correção NÃO decidida.

## Opções levantadas (para decisão do Fernando)

Vide seção própria no diagnóstico de 2026-09-12. Resumo:
1. Escopar o DROP ao namespace de rede do container (gluetun/kali) em vez do OUTPUT do host.
2. Full-tunnel no wg0 (AllowedIPs 0.0.0.0/0), com efeitos colaterais a considerar (rota geral
   do host via wg0, dependência da VPN de origem, queda da VPN derruba a internet do host).
3. Exceção pontual por uid/cgroup para o processo do OpenCode no OUTPUT do host.

## Critérios a preservar

- O tráfego de ATAQUE (fora da máquina, vindo do sandbox/pentest) continua 100% pela cadeia
  Protegida; o kill-switch continua sendo a última barreira física se a VPN cair.
- O host (OpenCode, navegador de administração) continua operando com rede normal durante a
  sessão segura do pentest.

## Prioridade

Alta. Bloqueia o uso real do ambiente (host sem internet durante a sessão) e pode interromper
a comunicação com o pesquisador no pior momento.

## Origem

Diagnóstico de Fernando (2026-09-12) após observar corte de internet do host durante o test
do session-start-hacking-security.sh; evidenciado e registrado como ISSUE-008 aguardando
decisão de correção (classe C).