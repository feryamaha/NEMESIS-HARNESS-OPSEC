---
ciclo: SPEC_006
skill: hacker-specification-design
status: proposta (aguardando analise critica)
fonte: ISSUE-002-validacao-externa-nao-self-auditing.md
last_updated: 2026-09-13
---

# SPEC_006: Segundo leitor independente da cadeia (exit do self-audit)

> Requisito funcional da ISSUE-002: GOOD deixar de ser afirmacao auto-declarada de um unico
> script e passar a ser corroborada por um segundo leitor deterministico, independente do
> codigo de `verificar-vazamento.sh`, com caminho proprio de verificacao por vetor.

## REQUEST

Criar um segundo verificador `~/opsec/scripts/verificador-externo.sh` que, rodado localmente
apos o atestado GOOD, repete uma amostra dos vetores (IP de saida, DNS-ECS, IPv6, Tor,
WebRTC/DNS) por meios e fontes DISTINTOS do `verificar-vazamento.sh`, emite `[GOOD]`
corroborado ou `[GAP]` com saida literal, sem gravar dado real do operador e sem alterar a
cadeia (aditivo).

## CATEGORY

Feature (segunda leitura de verificacao da cadeia). Script novo em `~/opsec/scripts/`
(area opsec_sensitive, classe C por estar na pasta de protecao: confirmacao do Fernando na
aplicacao).

## PROBLEM (sintomas observaveis)

- `verificar-vazamento.sh` e a unica medida de verdade e ja falhou como sensor em 2026-09-08
  (GOOD com IPv6 real vazando; "Sessao ativa" com kill-switch inativo por `$HOME` sob sudo)
  e em 2026-09-11 (gate burlado por cobertura frouxa da suite).
- O que "GOOD" significa hoje depende de uma unica execucao de um unico script, sem segundo
  leitor que confirme o atestado.
- TESTE 4 do `verificar-vazamento.sh` (WebRTC) e manual e deixa de fora da automacao.

## CONTEXT

Fontes consultadas (hierarquia codigo > docs > regras):

- **Codigo real lido no momento:**
  - `~/opsec/scripts/verificar-vazamento.sh` (133 linhas): TESTE 1 IP via `curl -s4
    api.ipify.org` (direto) e `curl -s4 -x socks5h://127.0.0.1:9050` (proxy), e IP_TOR via
    `curl --socks5-hostname localhost:9050 check.torproject.org/api/ip` com parse `jq -r
    '.IP'`; TESTE 2 DNS via `nmcli`/`dig @8.8.8.8` (ECS por `o-o.myaddr.l.google.com`);
    TESTE 3 IPv6 via `curl -s6 api6.ipify.org` e checagens adicionais de interfaces
    VPN (proton0/wg0/tun0) e range Proton (2a02:6ea0/2a04:1c80); TESTE 4 WebRTC manual (navegador); TESTE 4.5
    kill-switch auditoria no netns do gluetun; TESTE 5 veredito final.
  - `~/opsec/scripts/validar-dns-fix.sh` (106 linhas): metricas locais de DNS
    (`nmcli -g ipv4.*`, `resolvectl status`, `/etc/resolv.conf`, `dig @1.1.1.1/@9.9.9.9`,
    ECS via `dig @8.8.8.8`).
  - `~/opsec/scripts/iniciar-sessao.sh` (56 linhas): desativa IPv6 via `sysctl`, sobe wg0,
    chama kill-switch on e verificar-vazamento.
  - `~/opsec/scripts/gate-enforcement.sh` (Opcao C, 2026-09-13): bloqueia x-bit dos binarios
    de rede fora da sessao (curl incluido) por `chmod <bit>-x` relativo ao modo atual.
  - Linux Kali/host: ferramentas disponiveis no PATH: `curl`, `dig`, `jq`, `nmcli`,
    `resolvectl`, `ip`, `ss`, `docker`, `python3`.
- **Comportamento observado/assumido:**
  - Dentro da sessao segura o `verificar-vazamento.sh` roda via sudo (root, CAP_DAC_OVERRIDE)
    e usa curl; fora da sessao o curl esta com x-bit removido pelo gate-enforcement (documentado
    como esperado: pre-flight isolado fora de sessao retorna [LEAK]).
  - WebRTC so existe dentro de navegador; sem navegador nao ha mensuracao direta. A automacao
    do vetor WebRTC/DNS cobre as PRE-CONDICOES auditaveis de forma deterministica (IPv6 global
    ausente na interface de saida e proxy socks5h no ambiente do shell fernando); a limitacao e
    declarada, nao inventada como capacidade.
  - Endpoints e resolvedores escolhidos para o segundo leitor sao DISTINTOS do verificador:
    saida via fonte B (ex.: `https://icanhazip.com` ou `https://ifconfig.co`) no lugar de
    api.ipify.org; ECS via `dig @9.9.9.9` (Quad9) no lugar de `@8.8.8.8`; IPv6 medido por
    estado local (`ip -6 addr show scope global`, `/proc/sys/net/ipv6/conf/all/disable_ipv6`)
    no lugar de `curl -s6`; Tor medido por porta local (`ss -ltn sport :9050`), container
    (`docker ps` torproxy) e `check.torproject.org/api/ip` sem `jq` (regex propria).
  - Parsing proprio por vetor (regex/awk distintos), para um bug compartilhado de fonte ou
    parse nao corromper as duas leituras.
- **Pre-flight de postura:** execucao com vetores de rede so em sessao segura (apos
  `session-start-hacking-security.sh` GOOD). Fora de sessao, o script e desenhado para NAO
  tocar rede e emite GAP local "cadeia nao operacional" (fail-closed); isso permite validar o
  script em desenvolvimento SEM acao de rede.
- Docs canonicas: `.opencode/rules/hacker-opsec-canon.md` (modulos da cadeia), perfil do repo
  (`hacker-repo-profile.md`: validacao bash -n/py_compile/diff; areas opsec_sensitive).
- Regras: documentacao sem travessao, sem IP real, ledger append-only (invariante 11).

## REQUIREMENTS

- **R1 (segundo leitor standalone, aditivo):** criar `~/opsec/scripts/verificador-externo.sh`
  em bash, deterministico, sem LLM, sem libs/dependencias novas (stack do perfil), que roda
  localmente e emite veredito `[GOOD]` corroborado ou `[GAP]`. Nao altera nenhum script
  existente da cadeia (verificar-vazamento.sh, session-start, encerrar, kill-switch, gate,
  iniciar).
- **R2 (caminho proprio por vetor):** cada vetor usa fonte e parsing distintos de
  `verificar-vazamento.sh`: (a) IP de saida por fonte B (`icanhazip.com`/`ifconfig.co`)
  direto e via `-x socks5h://127.0.0.1:9050`, parse com regex propria; (b) DNS-ECS por
  `dig @9.9.9.9` no lugar de `@8.8.8.8`, e config local via `nmcli -g`/`resolvectl` com
  corte proprio; (c) IPv6 por estado local (`ip -6 addr show scope global` com filtro e
  `disable_ipv6` em `/proc`) sem `curl -s6`; (d) Tor por `ss -ltn` porta 9050 + `docker ps`
  torproxy + `check.torproject.org/api/ip` com regex propria, sem `jq`.
- **R3 (WebRTC/DNS automatico, pre-condicoes):** vetor WebRTC coberto deterministicamente pelas
  pre-condicoes auditaveis: ambiente do shell fernando com `http_proxy`/`https_proxy`
  apontando para socks5h://127.0.0.1:9050, e ausencia de IPv6 global na interface de saida
  (sem isso o STUN v6 vazaria mesmo via SOCKS). Limite declarado na saida: WebRTC real so no
  navegador; o TESTE 4 manual do verificador permanece.
- **R4 (privacidade):** IP real de origem nunca aparece na saida, nunca e gravado. Comparacoes
  locais no instante da execucao; na saida, apenas marcador de igual/diferente e prefixo
  anonimo no maximo. IP de saida (Tor/VPN) pode ser exibido como no verificador (e o que ja
  e citado em relatorios).
- **R5 (fail-closed e pre-cheque):** antes de qualquer consulta de rede, pre-cheque local:
  porta 9050 (Tor) ativa via `ss`; senao nao faz nenhuma consulta externa e emite `[GAP]`
  local "cadeia nao operacional" (sem tocar rede fora de sessao). Fora de sessao GOOD o
  resultado esperado e GAP, nunca GOOD falso.
- **R6 (veredito e saida):** formato greppavel `[GOOD]`/`[GAP]`; em GAP, listar os vetores que
  falharam com a saida literal; em GOOD, listar os vetores corroborados; prefixo de log
  distinto (ex.: `[VERIF-EXT]`) para nao confundir com o verificador.
- **R7 (divergencia registrada):** se o segundo leitor divergir do atestado GOOD do verificador,
  instrucao (saida) para registrar no Trust Ledger (append-only, entrada nova com a saida
  literal do GAP) e agir como GOOD NAO confirmado (fail-closed). O script nao grava no ledger
  por conta propria.
- **R8 (ponto de uso):** standalone, rodado pelo Fernando via sudo apos o atestado GOOD;
  documentar o comando no GATE-DE-PROTECAO.md e no canon (modulo novo), sem amarrar ao
  session-start (aditivo).

## FILES INVOLVED

- CREATE `~/opsec/scripts/verificador-externo.sh` (segundo leitor, classe C por estar na
  pasta de protecao).
- MODIFY `.hacker/gate/GATE-DE-PROTECAO.md` (documentar segunda leitura, comando de uso e
  resultado GAP fora de sessao).
- MODIFY `.opencode/rules/hacker-opsec-canon.md` (modulo "verificador-externo (segunda
  leitura)" na tabela da cadeia).

## RESTRICTIONS

- Area opsec_sensitive (perfil secao 1): scripts de protecao sao classe C (F4); aplicar com
  confirmacao do Fernando. Nenhuma alteracao em scripts existentes da cadeia (aditivo).
- Sudo exclusivo do Fernando; o agente nao executa sudo nem roda o segundo leitor com vetores
  de rede por conta propria.
- Nenhuma acao de rede no desenvolvimento/validacao: a validacao de dev roda o script fora de
  sessao e o resultado esperado e GAP local sem consulta externa (fail-closed cobre isso).
- Nenhum IP real / credencial / PII na saida, no script, nas docs (documentation-style).
- Sem dependencias novas (solo binarios do perfil: bash, ip, ss, dig, nmcli, docker, curl via
  sudo; python3 apenas como alternativa documentada, sem lib).
- Sem travessao, sem primeira pessoa nos textos novos.

## EXPECTED DELIVERY

- `~/opsec/scripts/verificador-externo.sh` criado: pre-cheque fail-closed, vetores com caminho
  proprio, veredito `[GOOD]`/`[GAP]` greppavel, sem gravar IP real, com saida literal das falhas.
- GATE-DE-PROTECAO.md e canon com o modulo e o comando de uso da segunda leitura.
- VERIFICATION (comandos do perfil):
  - `bash -n ~/opsec/scripts/verificador-externo.sh`: PASS.
  - `bash ~/opsec/scripts/verificador-externo.sh` (FORA de sessao, sem rede por design): GAP
    local "cadeia nao operacional", zero consulta externa (teste SUNSET F7 sem rede; o script
    se prova por sair antes de tocar rede sem Tor listening).
  - `grep -c "VERIF-EXT\|\[GAP\]\|\[GOOD\]" ~/opsec/scripts/verificador-externo.sh`: presentes.
  - Teste real de corroboracao com cadeia viva (GOOD do atestado + GOOD do segundo leitor)
    fica pendente ate a cadeia operacional (como no SPEC_005); divergencia seria registrada no
    Trust Ledger.
  - `bash ~/opsec/scripts/verificar-vazamento.sh` GOOD antes de QUALQUER execucao com vetores
    de rede (pre-flight do perfil).